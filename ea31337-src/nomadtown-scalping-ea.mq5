//+------------------------------------------------------------------+
//|                                      nomadtown-scalping-ea.mq5 |
//|                    스캘핑 전용 Expert Advisor (MetaTrader 5)      |
//|              Price_Swings + ATR_MA_Trend 조합 스캘핑 시스템        |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Scalping Edition"
#property link      ""
#property version   "1.00"
#property description "고성능 스캘핑 전용 EA - Price Swings와 ATR MA Trend 조합 (Nomadtown System)"

// 필요한 헤더 파일들
#include "include/scalping/ScalpingInputs.mqh"
#include "include/scalping/ScalpingStrategy.mqh"
#include "include/scalping/ScalpingOptimizer.mqh"

//+------------------------------------------------------------------+
//| 전역 변수                                                        |
//+------------------------------------------------------------------+
ScalpingStrategy *g_scalping_strategy = NULL;       // 스캘핑 전략 인스턴스
ScalpingOptimizer *g_optimizer = NULL;              // 최적화 모듈
datetime g_last_optimization_time = 0;              // 마지막 최적화 시간
int g_trade_count = 0;                              // 거래 카운터
int g_magic_number = 31337;                         // 매직 넘버
string g_log_prefix = "[Nomadtown-Scalping] ";     // 로그 접두사

// 성과 추적 변수
double g_total_profit = 0;                          // 총 수익
int g_total_trades = 0;                             // 총 거래 수
int g_winning_trades = 0;                           // 승리 거래 수
double g_max_drawdown = 0;                          // 최대 낙폭
double g_equity_peak = 0;                           // 자본 최고점

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print(g_log_prefix, "=== Nomadtown 스캘핑 시스템 초기화 ===");
    
    // 입력 매개변수 검증
    if (!ValidateScalpingInputs()) {
        Print(g_log_prefix, "입력 매개변수 검증 실패!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 설정 정보 출력
    PrintScalpingSettings();
    
    // 스캘핑 전략 초기화
    ScalpingConfig config = InputsToConfig();
    g_scalping_strategy = new ScalpingStrategy(config);
    
    if (g_scalping_strategy == NULL) {
        Print(g_log_prefix, "스캘핑 전략 초기화 실패!");
        return INIT_FAILED;
    }
    
    // 최적화 모듈 초기화 (옵션)
    if (Scalping_EnableOptimization) {
        g_optimizer = new ScalpingOptimizer();
        if (g_optimizer == NULL) {
            Print(g_log_prefix, "최적화 모듈 초기화 실패!");
        } else {
            Print(g_log_prefix, "실시간 최적화 모듈 활성화");
        }
    }
    
    // 백테스트 모드 체크
    if (Scalping_BacktestMode) {
        Print(g_log_prefix, "백테스트 모드 활성화");
        Print(g_log_prefix, "테스트 기간: ", TimeToString(Scalping_BacktestStart), " ~ ", TimeToString(Scalping_BacktestEnd));
    }
    
    // 초기 상태 설정
    g_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
    g_last_optimization_time = TimeCurrent();
    
    // 알림 설정
    if (Scalping_EnableAlerts) {
        Print(g_log_prefix, "알림 시스템 활성화");
        SendAlert("Nomadtown 스캘핑 시스템이 시작되었습니다.");
    }
    
    Print(g_log_prefix, "초기화 완료! 스캘핑 모드로 거래를 시작합니다.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print(g_log_prefix, "=== Nomadtown 스캘핑 시스템 종료 ===");
    
    // 종료 사유 출력
    string deinit_reason = "";
    switch(reason) {
        case REASON_PROGRAM: deinit_reason = "프로그램 종료"; break;
        case REASON_REMOVE: deinit_reason = "차트에서 제거"; break;
        case REASON_RECOMPILE: deinit_reason = "재컴파일"; break;
        case REASON_CHARTCHANGE: deinit_reason = "차트 변경"; break;
        case REASON_CHARTCLOSE: deinit_reason = "차트 닫기"; break;
        case REASON_PARAMETERS: deinit_reason = "매개변수 변경"; break;
        case REASON_ACCOUNT: deinit_reason = "계좌 변경"; break;
        default: deinit_reason = "알 수 없음"; break;
    }
    Print(g_log_prefix, "종료 사유: ", deinit_reason);
    
    // 최종 성과 리포트
    PrintFinalPerformanceReport();
    
    // 최적화 결과 저장
    if (g_optimizer != NULL && Scalping_SaveOptimizationResults) {
        string filename = "Nomadtown_Scalping_Results_" + TimeToString(TimeCurrent(), TIME_DATE) + ".txt";
        g_optimizer.SaveOptimizationResults(filename);
    }
    
    // 메모리 정리
    if (g_scalping_strategy != NULL) {
        delete g_scalping_strategy;
        g_scalping_strategy = NULL;
    }
    
    if (g_optimizer != NULL) {
        delete g_optimizer;
        g_optimizer = NULL;
    }
    
    // 종료 알림
    if (Scalping_EnableAlerts) {
        SendAlert("Nomadtown 스캘핑 시스템이 종료되었습니다. 총 거래: " + IntegerToString(g_total_trades));
    }
    
    Print(g_log_prefix, "시스템 종료 완료");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // 백테스트 모드에서 시간 범위 체크
    if (Scalping_BacktestMode) {
        datetime current_time = TimeCurrent();
        if (current_time < Scalping_BacktestStart || current_time > Scalping_BacktestEnd) {
            return; // 백테스트 범위 외부
        }
    }
    
    // 전략 인스턴스 체크
    if (g_scalping_strategy == NULL) {
        return;
    }
    
    // 새로운 봉 체크 (스캘핑은 매 틱마다 실행하지만 과도한 거래 방지)
    static datetime last_bar_time = 0;
    datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    bool new_bar = (current_bar_time != last_bar_time);
    last_bar_time = current_bar_time;
    
    // 트레일링 스톱 업데이트 (매 틱마다)
    if (Scalping_UseTrailingStop) {
        UpdateTrailingStops();
    }
    
    // 기존 포지션 관리
    ManageExistingPositions();
    
    // 새로운 신호 분석 (새 봉에서만 또는 특정 조건에서)
    if (new_bar || ShouldCheckForNewSignals()) {
        AnalyzeAndExecuteSignals();
    }
    
    // 실시간 최적화 (주기적으로)
    if (Scalping_EnableOptimization && g_optimizer != NULL) {
        if (g_total_trades > 0 && g_total_trades % Scalping_OptimizationPeriod == 0) {
            if (TimeCurrent() - g_last_optimization_time > 3600) { // 1시간마다
                g_optimizer.RealTimeOptimization();
                g_last_optimization_time = TimeCurrent();
                
                // 최적화된 설정 적용
                ScalpingConfig optimized_config = g_optimizer.GetBestConfig();
                g_scalping_strategy.UpdateConfig(optimized_config);
                
                Print(g_log_prefix, "실시간 최적화 완료 및 설정 업데이트");
            }
        }
    }
    
    // 성과 추적 업데이트
    UpdatePerformanceMetrics();
    
    // 상세 로그 (백테스트 모드에서)
    if (Scalping_DetailedLogs && Scalping_BacktestMode) {
        static int log_counter = 0;
        log_counter++;
        if (log_counter % 1000 == 0) { // 1000틱마다
            Print(g_log_prefix, g_scalping_strategy.GetStatusInfo());
        }
    }
}

//+------------------------------------------------------------------+
//| 신호 분석 및 거래 실행                                             |
//+------------------------------------------------------------------+
void AnalyzeAndExecuteSignals() {
    // 신호 분석
    ENUM_SCALPING_SIGNAL signal = g_scalping_strategy.GetScalpingSignal();
    
    if (signal == SCALPING_SIGNAL_NONE) {
        return; // 신호 없음
    }
    
    // 신호별 처리
    switch(signal) {
        case SCALPING_SIGNAL_BUY:
            ExecuteBuyOrder();
            break;
            
        case SCALPING_SIGNAL_SELL:
            ExecuteSellOrder();
            break;
            
        case SCALPING_SIGNAL_CLOSE_BUY:
            CloseAllPositions(POSITION_TYPE_BUY);
            break;
            
        case SCALPING_SIGNAL_CLOSE_SELL:
            CloseAllPositions(POSITION_TYPE_SELL);
            break;
    }
}

//+------------------------------------------------------------------+
//| 매수 주문 실행                                                    |
//+------------------------------------------------------------------+
void ExecuteBuyOrder() {
    // 현재 매수 포지션 수 체크
    int buy_positions = CountPositions(POSITION_TYPE_BUY);
    if (buy_positions >= Scalping_MaxTrades) {
        return;
    }
    
    // 주문 매개변수 계산
    double lot_size = CalculateLotSize();
    double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl_price = ask_price - Scalping_StopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double tp_price = ask_price + Scalping_TakeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // 주문 요청 구조체
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot_size;
    request.type = ORDER_TYPE_BUY;
    request.price = ask_price;
    request.sl = sl_price;
    request.tp = tp_price;
    request.magic = g_magic_number;
    request.comment = "Nomadtown-Scalping-BUY";
    request.deviation = 3;
    
    // 주문 실행
    if (OrderSend(request, result)) {
        if (result.retcode == TRADE_RETCODE_DONE) {
            g_total_trades++;
            g_trade_count++;
            
            Print(g_log_prefix, "매수 주문 성공 - 티켓: ", result.order, ", 가격: ", ask_price, ", 거래량: ", lot_size);
            
            // 알림 발송
            if (Scalping_AlertOnTrade) {
                SendAlert("스캘핑 매수 주문 실행 - 가격: " + DoubleToString(ask_price, Digits()));
            }
        } else {
            Print(g_log_prefix, "매수 주문 실패 - 에러코드: ", result.retcode, ", 설명: ", GetTradeErrorDescription(result.retcode));
        }
    } else {
        Print(g_log_prefix, "매수 주문 요청 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 매도 주문 실행                                                    |
//+------------------------------------------------------------------+
void ExecuteSellOrder() {
    // 현재 매도 포지션 수 체크
    int sell_positions = CountPositions(POSITION_TYPE_SELL);
    if (sell_positions >= Scalping_MaxTrades) {
        return;
    }
    
    // 주문 매개변수 계산
    double lot_size = CalculateLotSize();
    double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl_price = bid_price + Scalping_StopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double tp_price = bid_price - Scalping_TakeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // 주문 요청 구조체
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot_size;
    request.type = ORDER_TYPE_SELL;
    request.price = bid_price;
    request.sl = sl_price;
    request.tp = tp_price;
    request.magic = g_magic_number;
    request.comment = "Nomadtown-Scalping-SELL";
    request.deviation = 3;
    
    // 주문 실행
    if (OrderSend(request, result)) {
        if (result.retcode == TRADE_RETCODE_DONE) {
            g_total_trades++;
            g_trade_count++;
            
            Print(g_log_prefix, "매도 주문 성공 - 티켓: ", result.order, ", 가격: ", bid_price, ", 거래량: ", lot_size);
            
            // 알림 발송
            if (Scalping_AlertOnTrade) {
                SendAlert("스캘핑 매도 주문 실행 - 가격: " + DoubleToString(bid_price, Digits()));
            }
        } else {
            Print(g_log_prefix, "매도 주문 실패 - 에러코드: ", result.retcode, ", 설명: ", GetTradeErrorDescription(result.retcode));
        }
    } else {
        Print(g_log_prefix, "매도 주문 요청 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 거래량 계산                                                       |
//+------------------------------------------------------------------+
double CalculateLotSize() {
    double lot_size = Scalping_LotSize;
    
    // 동적 거래량 계산
    if (Scalping_UseDynamicLots) {
        double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double risk_amount = account_balance * Scalping_RiskPercent / 100.0;
        double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        double stop_loss_points = Scalping_StopLoss;
        
        if (tick_value > 0 && stop_loss_points > 0) {
            lot_size = risk_amount / (stop_loss_points * tick_value);
        }
        
        // 최소/최대 거래량 제한
        double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        
        lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
        lot_size = MathRound(lot_size / lot_step) * lot_step;
    }
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| 포지션 수 계산                                                    |
//+------------------------------------------------------------------+
int CountPositions(ENUM_POSITION_TYPE position_type) {
    int count = 0;
    int total_positions = PositionsTotal();
    
    for (int i = 0; i < total_positions; i++) {
        if (PositionGetTicket(i) > 0) {
            if (PositionGetString(POSITION_SYMBOL) == _Symbol && 
                PositionGetInteger(POSITION_MAGIC) == g_magic_number &&
                PositionGetInteger(POSITION_TYPE) == position_type) {
                count++;
            }
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| 모든 포지션 닫기                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions(ENUM_POSITION_TYPE position_type = -1) {
    int total_positions = PositionsTotal();
    
    for (int i = total_positions - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0) {
            if (PositionGetString(POSITION_SYMBOL) == _Symbol && 
                PositionGetInteger(POSITION_MAGIC) == g_magic_number) {
                
                ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                
                if (position_type == -1 || pos_type == position_type) {
                    ClosePosition(ticket);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 개별 포지션 닫기                                                  |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket) {
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = PositionGetString(POSITION_SYMBOL);
    request.volume = PositionGetDouble(POSITION_VOLUME);
    request.magic = g_magic_number;
    request.deviation = 3;
    
    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    if (pos_type == POSITION_TYPE_BUY) {
        request.type = ORDER_TYPE_SELL;
        request.price = SymbolInfoDouble(request.symbol, SYMBOL_BID);
    } else {
        request.type = ORDER_TYPE_BUY;
        request.price = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
    }
    
    if (OrderSend(request, result)) {
        if (result.retcode == TRADE_RETCODE_DONE) {
            Print(g_log_prefix, "포지션 닫기 성공 - 티켓: ", ticket);
            return true;
        }
    }
    
    Print(g_log_prefix, "포지션 닫기 실패 - 티켓: ", ticket, ", 에러: ", result.retcode);
    return false;
}

//+------------------------------------------------------------------+
//| 기존 포지션 관리                                                  |
//+------------------------------------------------------------------+
void ManageExistingPositions() {
    int total_positions = PositionsTotal();
    
    for (int i = 0; i < total_positions; i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0) {
            if (PositionGetString(POSITION_SYMBOL) == _Symbol && 
                PositionGetInteger(POSITION_MAGIC) == g_magic_number) {
                
                // 포지션 청산 여부 체크
                if (g_scalping_strategy.ShouldClosePosition((int)ticket)) {
                    ClosePosition(ticket);
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 트레일링 스톱 업데이트                                             |
//+------------------------------------------------------------------+
void UpdateTrailingStops() {
    int total_positions = PositionsTotal();
    
    for (int i = 0; i < total_positions; i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0) {
            if (PositionGetString(POSITION_SYMBOL) == _Symbol && 
                PositionGetInteger(POSITION_MAGIC) == g_magic_number) {
                
                g_scalping_strategy.UpdateTrailingStop((int)ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 새로운 신호 체크 조건                                              |
//+------------------------------------------------------------------+
bool ShouldCheckForNewSignals() {
    // 최소 시간 간격 체크
    static datetime last_signal_time = 0;
    datetime current_time = TimeCurrent();
    
    if (current_time - last_signal_time < 60) { // 1분 간격
        return false;
    }
    
    // 최대 포지션 수 체크
    int total_positions = CountPositions(POSITION_TYPE_BUY) + CountPositions(POSITION_TYPE_SELL);
    if (total_positions >= Scalping_MaxTrades) {
        return false;
    }
    
    last_signal_time = current_time;
    return true;
}

//+------------------------------------------------------------------+
//| 성과 지표 업데이트                                                 |
//+------------------------------------------------------------------+
void UpdatePerformanceMetrics() {
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // 자본 최고점 업데이트
    if (current_equity > g_equity_peak) {
        g_equity_peak = current_equity;
    }
    
    // 최대 낙폭 계산
    double current_drawdown = (g_equity_peak - current_equity) / g_equity_peak * 100;
    if (current_drawdown > g_max_drawdown) {
        g_max_drawdown = current_drawdown;
    }
    
    // 위험 수준 체크
    if (current_drawdown > Scalping_MaxDrawdownPercent) {
        Print(g_log_prefix, "경고: 최대 낙폭 ", Scalping_MaxDrawdownPercent, "% 초과! 현재: ", DoubleToString(current_drawdown, 2), "%");
        
        if (Scalping_EnableAlerts) {
            SendAlert("위험: 최대 낙폭 초과 - " + DoubleToString(current_drawdown, 2) + "%");
        }
        
        // 모든 포지션 닫기 (선택적)
        // CloseAllPositions();
    }
}

//+------------------------------------------------------------------+
//| 최종 성과 리포트                                                  |
//+------------------------------------------------------------------+
void PrintFinalPerformanceReport() {
    Print(g_log_prefix, "=== 최종 성과 리포트 ===");
    Print(g_log_prefix, "총 거래 수: ", g_total_trades);
    Print(g_log_prefix, "승리 거래: ", g_winning_trades);
    Print(g_log_prefix, "승률: ", (g_total_trades > 0 ? DoubleToString((double)g_winning_trades / g_total_trades * 100, 2) : "0"), "%");
    Print(g_log_prefix, "총 수익: ", DoubleToString(g_total_profit, 2));
    Print(g_log_prefix, "최대 낙폭: ", DoubleToString(g_max_drawdown, 2), "%");
    Print(g_log_prefix, "최종 자본: ", DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
    Print(g_log_prefix, "====================");
}

//+------------------------------------------------------------------+
//| 알림 전송                                                        |
//+------------------------------------------------------------------+
void SendAlert(string message) {
    if (!Scalping_EnableAlerts) return;
    
    string full_message = g_log_prefix + message;
    
    if (Scalping_AlertOnSignal || Scalping_AlertOnTrade) {
        Alert(full_message);
    }
    
    if (Scalping_SendEmail) {
        SendMail("Nomadtown 스캘핑 알림", full_message);
    }
    
    if (Scalping_SendPush) {
        SendNotification(full_message);
    }
}

//+------------------------------------------------------------------+
//| 거래 에러 설명                                                    |
//+------------------------------------------------------------------+
string GetTradeErrorDescription(uint error_code) {
    switch(error_code) {
        case TRADE_RETCODE_REQUOTE: return "재견적";
        case TRADE_RETCODE_REJECT: return "요청 거부";
        case TRADE_RETCODE_CANCEL: return "요청 취소";
        case TRADE_RETCODE_PLACED: return "주문 배치됨";
        case TRADE_RETCODE_DONE: return "실행 완료";
        case TRADE_RETCODE_DONE_PARTIAL: return "부분 실행";
        case TRADE_RETCODE_ERROR: return "일반 오류";
        case TRADE_RETCODE_TIMEOUT: return "시간 초과";
        case TRADE_RETCODE_INVALID: return "유효하지 않은 요청";
        case TRADE_RETCODE_INVALID_VOLUME: return "유효하지 않은 거래량";
        case TRADE_RETCODE_INVALID_PRICE: return "유효하지 않은 가격";
        case TRADE_RETCODE_INVALID_STOPS: return "유효하지 않은 스톱";
        case TRADE_RETCODE_TRADE_DISABLED: return "거래 비활성화";
        case TRADE_RETCODE_MARKET_CLOSED: return "시장 마감";
        case TRADE_RETCODE_NO_MONEY: return "자금 부족";
        case TRADE_RETCODE_PRICE_CHANGED: return "가격 변경";
        case TRADE_RETCODE_PRICE_OFF: return "가격 벗어남";
        case TRADE_RETCODE_INVALID_EXPIRATION: return "유효하지 않은 만료";
        case TRADE_RETCODE_ORDER_CHANGED: return "주문 변경";
        case TRADE_RETCODE_TOO_MANY_REQUESTS: return "요청 과다";
        default: return "알 수 없는 오류 (" + IntegerToString(error_code) + ")";
    }
}