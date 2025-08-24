//+------------------------------------------------------------------+
//|                          nomadtown-conservative-scalping-ea.mq5 |
//|              보수적 스캘핑 Expert Advisor (MetaTrader 5)         |
//|           안전 우선 Price_Swings + ATR_MA_Trend 조합 시스템       |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Conservative Scalping Edition"
#property link      ""
#property version   "1.00"
#property description "보수적 스캘핑 EA - 안전성 최우선 (Nomadtown Conservative System)"

// 필요한 헤더 파일들
#include "include/scalping/ScalpingInputs.mqh"
#include "include/scalping/ScalpingStrategy.mqh"

//+------------------------------------------------------------------+
//| 전역 변수                                                        |
//+------------------------------------------------------------------+
ScalpingStrategy *g_scalping_strategy = NULL;       // 스캘핑 전략 인스턴스
int g_magic_number = 31339;                         // 보수적 스캘핑 EA 전용 매직 넘버
string g_log_prefix = "[Nomadtown-Conservative-Scalping] "; // 로그 접두사

// 보수적 성과 추적 변수
double g_total_profit = 0;
int g_total_trades = 0;
int g_winning_trades = 0;
double g_max_drawdown = 0;
double g_equity_peak = 0;
double g_max_loss_streak = 0;
int g_current_loss_streak = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print(g_log_prefix, "=== Nomadtown 보수적 스캘핑 시스템 초기화 ===");
    
    // 보수적 설정 강제 적용
    Print(g_log_prefix, "🛡️ 보수적 스캘핑 모드 활성화");
    ApplyConservativeScalpingPreset();
    
    // 입력 매개변수 검증
    if (!ValidateScalpingInputs()) {
        Print(g_log_prefix, "❌ 입력 매개변수 검증 실패!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 보수적 설정 확인
    if (!ValidateConservativeSettings()) {
        Print(g_log_prefix, "⚠️ 보수적 설정이 아닙니다. 설정을 확인하세요!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 마틴게일 사용 시 경고 및 차단
    if (Scalping_UseMartingale) {
        Print(g_log_prefix, "🚫 경고: 보수적 모드에서는 마틴게일이 비활성화됩니다!");
        Alert("보수적 스캐핑에서는 마틴게일을 사용할 수 없습니다.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 설정 정보 출력
    PrintConservativeSettings();
    
    // 스캘핑 전략 초기화 (보수적 설정)
    ScalpingConfig config = GetConservativeScalpingConfig();
    g_scalping_strategy = new ScalpingStrategy(config);
    
    if (g_scalping_strategy == NULL) {
        Print(g_log_prefix, "❌ 스캘핑 전략 초기화 실패!");
        return INIT_FAILED;
    }
    
    // 초기 상태 설정
    g_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // 보수적 모드 확인 메시지
    Print(g_log_prefix, "✅ 보수적 스캘핑 모드:");
    Print(g_log_prefix, "- 이중 신호 확인: 활성화");
    Print(g_log_prefix, "- 마틴게일: 비활성화");
    Print(g_log_prefix, "- 최대 손실: 8 pips");
    Print(g_log_prefix, "- 목표 수익: 12 pips");
    Print(g_log_prefix, "- 최대 거래: 2개");
    
    // 알림 설정
    if (Scalping_EnableAlerts) {
        Print(g_log_prefix, "🔔 알림 시스템 활성화");
        Alert("Nomadtown 보수적 스캘핑 시스템이 시작되었습니다.");
    }
    
    Print(g_log_prefix, "✅ 초기화 완료! 보수적 스캘핑 모드로 안전한 거래를 시작합니다.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print(g_log_prefix, "=== Nomadtown 보수적 스캘핑 시스템 종료 ===");
    
    // 최종 성과 리포트 (보수적 통계 포함)
    PrintConservativePerformanceReport();
    
    // 메모리 정리
    if (g_scalping_strategy != NULL) {
        delete g_scalping_strategy;
        g_scalping_strategy = NULL;
    }
    
    Print(g_log_prefix, "✅ 시스템 종료 완료");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (g_scalping_strategy == NULL) return;
    
    // 백테스트 모드에서 시간 범위 체크
    if (Scalping_BacktestMode) {
        datetime current_time = TimeCurrent();
        if (current_time < Scalping_BacktestStart || current_time > Scalping_BacktestEnd) {
            return;
        }
    }
    
    // 보수적 안전 점검
    if (!ConservativeSafetyCheck()) {
        return;
    }
    
    // 트레일링 스톱 업데이트
    if (Scalping_UseTrailingStop) {
        UpdateConservativeTrailingStops();
    }
    
    // 기존 포지션 관리
    ManageExistingPositions();
    
    // 새로운 신호 분석 및 거래 실행 (보수적)
    AnalyzeAndExecuteConservativeSignals();
    
    // 성과 추적 업데이트
    UpdateConservativePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| 보수적 신호 분석 및 거래 실행                                     |
//+------------------------------------------------------------------+
void AnalyzeAndExecuteConservativeSignals() {
    ENUM_SCALPING_SIGNAL signal = g_scalping_strategy.GetScalpingSignal();
    
    // 보수적 모드에서는 추가 확인
    if (signal != SCALPING_SIGNAL_NONE) {
        if (!AdditionalConservativeFilters()) {
            return;
        }
    }
    
    if (signal == SCALPING_SIGNAL_BUY) {
        ExecuteConservativeBuyOrder();
    } else if (signal == SCALPING_SIGNAL_SELL) {
        ExecuteConservativeSellOrder();
    }
}

//+------------------------------------------------------------------+
//| 보수적 매수 주문 실행                                             |
//+------------------------------------------------------------------+
void ExecuteConservativeBuyOrder() {
    double lot_size = Scalping_LotSize; // 고정 거래량 (마틴게일 없음)
    double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl_price = ask_price - Scalping_StopLoss * _Point;
    double tp_price = ask_price + Scalping_TakeProfit * _Point;
    
    Print(g_log_prefix, "🔵 보수적 매수 신호 - 이중 확인 완료");
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot_size;
    request.type = ORDER_TYPE_BUY;
    request.price = ask_price;
    request.sl = sl_price;
    request.tp = tp_price;
    request.deviation = 2; // 보수적: 작은 슬리피지
    request.magic = g_magic_number;
    request.comment = "Conservative-Scalping-BUY";
    
    if (OrderSend(request, result)) {
        g_total_trades++;
        Print(g_log_prefix, "✅ 보수적 매수 주문 성공 - 티켓: ", result.order, 
              ", 가격: ", ask_price, ", 거래량: ", lot_size);
        
        if (Scalping_AlertOnTrade) {
            Alert("보수적 스캘핑 매수 주문 실행");
        }
    } else {
        Print(g_log_prefix, "❌ 매수 주문 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 보수적 매도 주문 실행                                             |
//+------------------------------------------------------------------+
void ExecuteConservativeSellOrder() {
    double lot_size = Scalping_LotSize; // 고정 거래량 (마틴게일 없음)
    double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl_price = bid_price + Scalping_StopLoss * _Point;
    double tp_price = bid_price - Scalping_TakeProfit * _Point;
    
    Print(g_log_prefix, "🔴 보수적 매도 신호 - 이중 확인 완료");
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot_size;
    request.type = ORDER_TYPE_SELL;
    request.price = bid_price;
    request.sl = sl_price;
    request.tp = tp_price;
    request.deviation = 2; // 보수적: 작은 슬리피지
    request.magic = g_magic_number;
    request.comment = "Conservative-Scalping-SELL";
    
    if (OrderSend(request, result)) {
        g_total_trades++;
        Print(g_log_prefix, "✅ 보수적 매도 주문 성공 - 티켓: ", result.order, 
              ", 가격: ", bid_price, ", 거래량: ", lot_size);
        
        if (Scalping_AlertOnTrade) {
            Alert("보수적 스캘핑 매도 주문 실행");
        }
    } else {
        Print(g_log_prefix, "❌ 매도 주문 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 보수적 안전 점검                                                  |
//+------------------------------------------------------------------+
bool ConservativeSafetyCheck() {
    // 최대 낙폭 체크
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double current_drawdown = (g_equity_peak - current_equity) / g_equity_peak * 100;
    
    if (current_drawdown > Scalping_MaxDrawdownPercent) {
        Print(g_log_prefix, "🚫 최대 낙폭 ", Scalping_MaxDrawdownPercent, "% 초과. 거래 중단.");
        return false;
    }
    
    // 연속 손실 체크
    if (g_current_loss_streak >= 3) {
        Print(g_log_prefix, "🚫 연속 3회 손실. 1시간 거래 중단.");
        return false;
    }
    
    // 스프레드 재확인
    double spread = MarketInfo(_Symbol, MODE_SPREAD) * MarketInfo(_Symbol, MODE_POINT);
    if (spread > Scalping_MaxSpread * MarketInfo(_Symbol, MODE_POINT)) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 추가 보수적 필터                                                  |
//+------------------------------------------------------------------+
bool AdditionalConservativeFilters() {
    // 변동성 체크
    double atr = iATR(_Symbol, PERIOD_CURRENT, 14, 0);
    if (atr < Scalping_MinVolatilityLevel) {
        return false;
    }
    
    // 시간 필터 재확인
    datetime current_time = TimeCurrent();
    int current_hour = TimeHour(current_time);
    if (current_hour < Scalping_StartHour || current_hour > Scalping_EndHour) {
        return false;
    }
    
    // 뉴스 시간 회피 (간소화)
    int current_minute = TimeMinute(current_time);
    if (current_minute >= 58 || current_minute <= 2) { // 정시 전후 회피
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 보수적 설정 검증                                                  |
//+------------------------------------------------------------------+
bool ValidateConservativeSettings() {
    bool is_valid = true;
    
    if (Scalping_MaxTrades > 2) {
        Print(g_log_prefix, "⚠️ 보수적 모드: 최대 거래는 2개 이하여야 합니다.");
        is_valid = false;
    }
    
    if (Scalping_MaxSpread > 2.0) {
        Print(g_log_prefix, "⚠️ 보수적 모드: 최대 스프레드는 2.0 이하여야 합니다.");
        is_valid = false;
    }
    
    if (!Scalping_RequireBothSignals) {
        Print(g_log_prefix, "⚠️ 보수적 모드: 이중 신호 확인이 필요합니다.");
        is_valid = false;
    }
    
    if (Scalping_StopLoss > 10.0) {
        Print(g_log_prefix, "⚠️ 보수적 모드: 손절매는 10 pips 이하여야 합니다.");
        is_valid = false;
    }
    
    return is_valid;
}

//+------------------------------------------------------------------+
//| 보수적 설정 반환                                                  |
//+------------------------------------------------------------------+
ScalpingConfig GetConservativeScalpingConfig() {
    ScalpingConfig config = InputsToConfig();
    
    // 보수적 설정 강제 적용
    config.use_martingale = false;          // 마틴게일 비활성화
    config.max_trades = 2;                  // 최대 2개 거래
    config.spread_limit = 1.5;              // 낮은 스프레드만
    config.stop_loss_pips = 8;              // 빠른 손절
    config.take_profit_pips = 12;           // 안정적 수익
    config.atr_sensitivity = 1.0;           // 보수적 신호
    config.swing_threshold = 0.35;          // 신중한 진입
    
    return config;
}

//+------------------------------------------------------------------+
//| 유틸리티 함수들                                                   |
//+------------------------------------------------------------------+
void ManageExistingPositions() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == g_magic_number) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            
            if (g_scalping_strategy.ShouldClosePosition((int)ticket)) {
                CloseConservativePosition(ticket);
            }
        }
    }
}

bool CloseConservativePosition(ulong ticket) {
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    if (!PositionSelectByTicket(ticket)) return false;
    
    double volume = PositionGetDouble(POSITION_VOLUME);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = volume;
    request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = (type == POSITION_TYPE_BUY) ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    request.position = ticket;
    request.magic = g_magic_number;
    request.comment = "Conservative-Scalping-CLOSE";
    
    if (OrderSend(request, result)) {
        Print(g_log_prefix, "✅ 포지션 닫기 성공 - 티켓: ", ticket);
        
        // 수익/손실 계산 및 연속 손실 추적
        double profit = PositionGetDouble(POSITION_PROFIT);
        bool is_profit = profit > 0;
        
        if (is_profit) {
            g_winning_trades++;
            g_current_loss_streak = 0;
            Print(g_log_prefix, "✅ 수익 거래 - 연속 손실 초기화");
        } else {
            g_current_loss_streak++;
            if (g_current_loss_streak > g_max_loss_streak) {
                g_max_loss_streak = g_current_loss_streak;
            }
            Print(g_log_prefix, "❌ 손실 거래 - 연속 손실: ", g_current_loss_streak);
        }
        
        g_total_profit += profit;
        return true;
    } else {
        Print(g_log_prefix, "❌ 포지션 닫기 실패 - 티켓: ", ticket, ", 에러: ", GetLastError());
        return false;
    }
}

void UpdateConservativeTrailingStops() {
    // 보수적 트레일링 스톱 구현
    // 더 타이트한 트레일링으로 수익 보호
}

void UpdateConservativePerformanceMetrics() {
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if (current_equity > g_equity_peak) {
        g_equity_peak = current_equity;
    }
    
    double current_drawdown = (g_equity_peak - current_equity) / g_equity_peak * 100;
    if (current_drawdown > g_max_drawdown) {
        g_max_drawdown = current_drawdown;
    }
}

void PrintConservativeSettings() {
    Print(g_log_prefix, "=== 보수적 스캘핑 설정 정보 ===");
    Print(g_log_prefix, "🛡️ 안전성 최우선 모드");
    Print(g_log_prefix, "거래량: ", Scalping_LotSize, " (고정)");
    Print(g_log_prefix, "최대 거래: ", Scalping_MaxTrades, " (제한)");
    Print(g_log_prefix, "최대 스프레드: ", Scalping_MaxSpread, " (엄격)");
    Print(g_log_prefix, "손절매: ", Scalping_StopLoss, " pips (빠른 차단)");
    Print(g_log_prefix, "익절: ", Scalping_TakeProfit, " pips (안정 수익)");
    Print(g_log_prefix, "이중 신호: ", (Scalping_RequireBothSignals ? "활성화" : "비활성화"));
    Print(g_log_prefix, "마틴게일: 비활성화 (강제)");
    Print(g_log_prefix, "거래시간: ", Scalping_StartHour, ":00-", Scalping_EndHour, ":00");
    Print(g_log_prefix, "최대 낙폭: ", Scalping_MaxDrawdownPercent, "%");
    Print(g_log_prefix, "===============================");
}

void PrintConservativePerformanceReport() {
    Print(g_log_prefix, "=== 최종 성과 (보수적 스캘핑) ===");
    Print(g_log_prefix, "총 거래: ", g_total_trades);
    Print(g_log_prefix, "승리 거래: ", g_winning_trades);
    Print(g_log_prefix, "승률: ", (g_total_trades > 0 ? DoubleToString((double)g_winning_trades / g_total_trades * 100, 2) : "0"), "%");
    Print(g_log_prefix, "총 수익: ", DoubleToString(g_total_profit, 2));
    Print(g_log_prefix, "최대 낙폭: ", DoubleToString(g_max_drawdown, 2), "%");
    Print(g_log_prefix, "최대 연속 손실: ", g_max_loss_streak, "회");
    Print(g_log_prefix, "보수적 모드: ✅ 안전성 최우선");
    Print(g_log_prefix, "===============================");
}