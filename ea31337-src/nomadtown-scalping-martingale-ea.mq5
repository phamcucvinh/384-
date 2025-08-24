//+------------------------------------------------------------------+
//|                            nomadtown-scalping-martingale-ea.mq5 |
//|              스캘핑 + 마틴게일 Expert Advisor (MetaTrader 5)       |
//|           Price_Swings + ATR_MA_Trend + Martingale 조합 시스템     |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Scalping Martingale Edition"
#property link      ""
#property version   "1.00"
#property description "고성능 스캘핑 + 마틴게일 EA - 고급 리스크 관리 (Nomadtown System)"

// 필요한 헤더 파일들
#include "include/scalping/ScalpingInputs.mqh"
#include "include/scalping/ScalpingStrategy.mqh"
#include "include/scalping/ScalpingOptimizer.mqh"

//+------------------------------------------------------------------+
//| 전역 변수                                                        |
//+------------------------------------------------------------------+
ScalpingStrategy *g_scalping_strategy = NULL;       // 스캘핑 전략 인스턴스
int g_magic_number = 31338;                         // 마틴게일 EA 전용 매직 넘버
string g_log_prefix = "[Nomadtown-Scalping-Martingale] "; // 로그 접두사

// 성과 추적 변수
double g_total_profit = 0;
int g_total_trades = 0;
int g_winning_trades = 0;
double g_max_drawdown = 0;
double g_equity_peak = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print(g_log_prefix, "=== Nomadtown 스캘핑 + 마틴게일 시스템 초기화 ===");
    
    // 입력 매개변수 검증
    if (!ValidateScalpingInputs()) {
        Print(g_log_prefix, "입력 매개변수 검증 실패!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 마틴게일 경고 메시지
    if (Scalping_UseMartingale) {
        Print(g_log_prefix, "⚠️ 경고: 마틴게일 시스템이 활성화되었습니다!");
        Print(g_log_prefix, "마틴게일 배수: ", Scalping_MartingaleMultiplier);
        Print(g_log_prefix, "최대 마틴게일 단계: ", Scalping_MaxMartingaleLevels);
        Print(g_log_prefix, "높은 리스크를 수반할 수 있습니다. 신중하게 사용하세요.");
    }
    
    // 설정 정보 출력
    PrintScalpingSettings();
    
    // 스캘핑 전략 초기화 (마틴게일 설정 포함)
    ScalpingConfig config = InputsToConfig();
    g_scalping_strategy = new ScalpingStrategy(config);
    
    if (g_scalping_strategy == NULL) {
        Print(g_log_prefix, "스캘핑 전략 초기화 실패!");
        return INIT_FAILED;
    }
    
    // 초기 상태 설정
    g_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // 마틴게일 상태 정보
    if (Scalping_UseMartingale) {
        Print(g_log_prefix, "마틴게일 초기 상태:");
        Print(g_log_prefix, "- 기본 거래량: ", config.lot_size);
        Print(g_log_prefix, "- 현재 마틴게일 레벨: ", g_scalping_strategy.GetMartingaleLevel());
    }
    
    // 알림 설정
    if (Scalping_EnableAlerts) {
        Print(g_log_prefix, "알림 시스템 활성화");
        Alert("Nomadtown 스캘핑 + 마틴게일 시스템이 시작되었습니다.");
    }
    
    Print(g_log_prefix, "초기화 완료! 스캘핑 + 마틴게일 모드로 거래를 시작합니다.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print(g_log_prefix, "=== Nomadtown 스캘핑 + 마틴게일 시스템 종료 ===");
    
    // 최종 성과 리포트 (마틴게일 통계 포함)
    PrintFinalPerformanceReport();
    
    // 메모리 정리
    if (g_scalping_strategy != NULL) {
        delete g_scalping_strategy;
        g_scalping_strategy = NULL;
    }
    
    Print(g_log_prefix, "시스템 종료 완료");
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
    
    // 트레일링 스톱 업데이트
    if (Scalping_UseTrailingStop) {
        UpdateTrailingStops();
    }
    
    // 기존 포지션 관리
    ManageExistingPositions();
    
    // 새로운 신호 분석 및 거래 실행
    AnalyzeAndExecuteSignals();
    
    // 성과 추적 업데이트
    UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| 신호 분석 및 거래 실행                                            |
//+------------------------------------------------------------------+
void AnalyzeAndExecuteSignals() {
    ENUM_SCALPING_SIGNAL signal = g_scalping_strategy.GetScalpingSignal();
    
    if (signal == SCALPING_SIGNAL_BUY) {
        ExecuteBuyOrder();
    } else if (signal == SCALPING_SIGNAL_SELL) {
        ExecuteSellOrder();
    }
}

//+------------------------------------------------------------------+
//| 매수 주문 실행 (마틴게일 적용)                                     |
//+------------------------------------------------------------------+
void ExecuteBuyOrder() {
    double lot_size = g_scalping_strategy.CalculateMartingaleLotSize(); // 마틴게일 거래량
    double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl_price = ask_price - Scalping_StopLoss * _Point;
    double tp_price = ask_price + Scalping_TakeProfit * _Point;
    
    // 마틴게일 레벨 로그
    if (Scalping_UseMartingale && g_scalping_strategy.GetMartingaleLevel() > 0) {
        Print(g_log_prefix, "마틴게일 매수 주문 - 레벨: ", g_scalping_strategy.GetMartingaleLevel(), 
              ", 거래량: ", lot_size);
    }
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot_size;
    request.type = ORDER_TYPE_BUY;
    request.price = ask_price;
    request.sl = sl_price;
    request.tp = tp_price;
    request.deviation = 3;
    request.magic = g_magic_number;
    request.comment = "Scalping+Martingale-BUY";
    
    if (OrderSend(request, result)) {
        g_total_trades++;
        Print(g_log_prefix, "매수 주문 성공 - 티켓: ", result.order, 
              ", 가격: ", ask_price, ", 거래량: ", lot_size);
        
        if (Scalping_AlertOnTrade) {
            Alert("스캘핑 + 마틴게일 매수 주문 실행");
        }
    } else {
        Print(g_log_prefix, "매수 주문 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 매도 주문 실행 (마틴게일 적용)                                     |
//+------------------------------------------------------------------+
void ExecuteSellOrder() {
    double lot_size = g_scalping_strategy.CalculateMartingaleLotSize(); // 마틴게일 거래량
    double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl_price = bid_price + Scalping_StopLoss * _Point;
    double tp_price = bid_price - Scalping_TakeProfit * _Point;
    
    // 마틴게일 레벨 로그
    if (Scalping_UseMartingale && g_scalping_strategy.GetMartingaleLevel() > 0) {
        Print(g_log_prefix, "마틴게일 매도 주문 - 레벨: ", g_scalping_strategy.GetMartingaleLevel(), 
              ", 거래량: ", lot_size);
    }
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lot_size;
    request.type = ORDER_TYPE_SELL;
    request.price = bid_price;
    request.sl = sl_price;
    request.tp = tp_price;
    request.deviation = 3;
    request.magic = g_magic_number;
    request.comment = "Scalping+Martingale-SELL";
    
    if (OrderSend(request, result)) {
        g_total_trades++;
        Print(g_log_prefix, "매도 주문 성공 - 티켓: ", result.order, 
              ", 가격: ", bid_price, ", 거래량: ", lot_size);
        
        if (Scalping_AlertOnTrade) {
            Alert("스캘핑 + 마틴게일 매도 주문 실행");
        }
    } else {
        Print(g_log_prefix, "매도 주문 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 기존 포지션 관리                                                  |
//+------------------------------------------------------------------+
void ManageExistingPositions() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == g_magic_number) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            
            if (g_scalping_strategy.ShouldClosePosition((int)ticket)) {
                ClosePosition(ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 포지션 닫기 (마틴게일 상태 업데이트)                               |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket) {
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
    request.comment = "Scalping+Martingale-CLOSE";
    
    if (OrderSend(request, result)) {
        Print(g_log_prefix, "포지션 닫기 성공 - 티켓: ", ticket);
        
        // 수익/손실 계산 및 마틴게일 상태 업데이트
        double profit = PositionGetDouble(POSITION_PROFIT);
        bool is_profit = profit > 0;
        
        if (is_profit) {
            g_winning_trades++;
            Print(g_log_prefix, "✅ 수익 거래 - 마틴게일 리셋");
        } else {
            Print(g_log_prefix, "❌ 손실 거래 - 마틴게일 레벨 증가");
        }
        
        // 마틴게일 상태 업데이트
        g_scalping_strategy.OnTradeResult(is_profit);
        
        g_total_profit += profit;
        return true;
    } else {
        Print(g_log_prefix, "포지션 닫기 실패 - 티켓: ", ticket, ", 에러: ", GetLastError());
        return false;
    }
}

//+------------------------------------------------------------------+
//| 유틸리티 함수들                                                   |
//+------------------------------------------------------------------+
void UpdateTrailingStops() {
    // 트레일링 스톱 구현 (간소화)
    // 실제 구현에서는 더 정교한 로직 필요
}

void UpdatePerformanceMetrics() {
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if (current_equity > g_equity_peak) {
        g_equity_peak = current_equity;
    }
    
    double current_drawdown = (g_equity_peak - current_equity) / g_equity_peak * 100;
    if (current_drawdown > g_max_drawdown) {
        g_max_drawdown = current_drawdown;
    }
}

void PrintFinalPerformanceReport() {
    Print(g_log_prefix, "=== 최종 성과 (스캘핑 + 마틴게일) ===");
    Print(g_log_prefix, "총 거래: ", g_total_trades);
    Print(g_log_prefix, "승리 거래: ", g_winning_trades);
    Print(g_log_prefix, "승률: ", (g_total_trades > 0 ? DoubleToString((double)g_winning_trades / g_total_trades * 100, 2) : "0"), "%");
    Print(g_log_prefix, "총 수익: ", DoubleToString(g_total_profit, 2));
    Print(g_log_prefix, "최대 낙폭: ", DoubleToString(g_max_drawdown, 2), "%");
    
    if (Scalping_UseMartingale) {
        Print(g_log_prefix, "마틴게일 최종 레벨: ", g_scalping_strategy.GetMartingaleLevel());
    }
    
    Print(g_log_prefix, "========================");
}