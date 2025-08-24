//+------------------------------------------------------------------+
//|                                      nomadtown-scalping-ea.mq4 |
//|                    스캘핑 전용 Expert Advisor (MetaTrader 4)      |
//|              Price_Swings + ATR_MA_Trend 조합 스캘핑 시스템        |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Scalping Edition"
#property link      ""
#property version   "1.00"
#property description "고성능 스캘핑 전용 EA - Price Swings와 ATR MA Trend 조합 (Nomadtown System)"

// MQL4 전용 거래 상수
#define OP_BUY 0
#define OP_SELL 1

// 필요한 헤더 파일들
#include "include/scalping/ScalpingInputs.mqh"

//+------------------------------------------------------------------+
//| 전역 변수 (MQL4 버전)                                             |
//+------------------------------------------------------------------+
int g_magic_number = 31337;                         // 매직 넘버
string g_log_prefix = "[Nomadtown-Scalping-MQL4] ";  // 로그 접두사
datetime g_last_bar_time = 0;                      // 마지막 봉 시간
int g_total_trades = 0;                             // 총 거래 수
int g_winning_trades = 0;                           // 승리 거래 수
double g_total_profit = 0;                          // 총 수익
double g_max_drawdown = 0;                          // 최대 낙폭
double g_equity_peak = 0;                           // 자본 최고점

// 신호 상태 변수
bool g_last_atr_signal = false;                     // 마지막 ATR 신호
bool g_last_swing_signal = false;                   // 마지막 스윙 신호
bool g_current_trend_up = true;                     // 현재 트렌드 방향

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print(g_log_prefix, "=== Nomadtown 스캘핑 시스템 초기화 (MQL4) ===");
    
    // 입력 매개변수 검증
    if (!ValidateScalpingInputsMQL4()) {
        Print(g_log_prefix, "입력 매개변수 검증 실패!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 설정 정보 출력
    PrintScalpingSettingsMQL4();
    
    // 초기 상태 설정
    g_equity_peak = AccountEquity();
    g_last_bar_time = Time[0];
    
    // 알림 설정
    if (Scalping_EnableAlerts) {
        Print(g_log_prefix, "알림 시스템 활성화");
        SendAlertMQL4("Nomadtown 스캘핑 시스템이 시작되었습니다.");
    }
    
    Print(g_log_prefix, "초기화 완료! 스캘핑 모드로 거래를 시작합니다.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print(g_log_prefix, "=== Nomadtown 스캘핑 시스템 종료 (MQL4) ===");
    
    // 종료 사유 출력
    string deinit_reason = GetDeinitReasonMQL4(reason);
    Print(g_log_prefix, "종료 사유: ", deinit_reason);
    
    // 최종 성과 리포트
    PrintFinalPerformanceReportMQL4();
    
    // 종료 알림
    if (Scalping_EnableAlerts) {
        SendAlertMQL4("Nomadtown 스캘핑 시스템이 종료되었습니다. 총 거래: " + IntegerToString(g_total_trades));
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
    
    // 새로운 봉 체크
    bool new_bar = (Time[0] != g_last_bar_time);
    if (new_bar) {
        g_last_bar_time = Time[0];
    }
    
    // 트레일링 스톱 업데이트 (매 틱마다)
    if (Scalping_UseTrailingStop) {
        UpdateTrailingStopsMQL4();
    }
    
    // 기존 포지션 관리
    ManageExistingPositionsMQL4();
    
    // 새로운 신호 분석 (새 봉에서만 또는 특정 조건에서)
    if (new_bar || ShouldCheckForNewSignalsMQL4()) {
        AnalyzeAndExecuteSignalsMQL4();
    }
    
    // 성과 추적 업데이트
    UpdatePerformanceMetricsMQL4();
    
    // 상세 로그 (백테스트 모드에서)
    if (Scalping_DetailedLogs && Scalping_BacktestMode) {
        static int log_counter = 0;
        log_counter++;
        if (log_counter % 1000 == 0) { // 1000틱마다
            Print(g_log_prefix, GetStatusInfoMQL4());
        }
    }
}

//+------------------------------------------------------------------+
//| MQL4 신호 분석 및 거래 실행                                        |
//+------------------------------------------------------------------+
void AnalyzeAndExecuteSignalsMQL4() {
    // 기본 조건 체크
    if (!IsSpreadAcceptableMQL4()) return;
    if (!IsTimeFilterOKMQL4()) return;
    if (!IsRiskAcceptableMQL4()) return;
    
    bool atr_signal = false;
    bool swing_signal = false;
    bool buy_condition = false;
    bool sell_condition = false;
    
    // ATR MA Trend 분석
    if (Scalping_UseATRMATrend) {
        atr_signal = AnalyzeATRMATrendMQL4();
    }
    
    // Price Swings 분석
    if (Scalping_UsePriceSwings) {
        swing_signal = AnalyzePriceSwingsMQL4();
    }
    
    // 복합 신호 생성
    if (Scalping_RequireBothSignals) {
        // 두 신호 모두 필요
        buy_condition = atr_signal && swing_signal && g_current_trend_up;
        sell_condition = atr_signal && swing_signal && !g_current_trend_up;
    } else {
        // 하나의 신호만으로도 거래
        if (Scalping_UseATRMATrend && Scalping_UsePriceSwings) {
            buy_condition = (atr_signal || swing_signal) && g_current_trend_up;
            sell_condition = (atr_signal || swing_signal) && !g_current_trend_up;
        } else if (Scalping_UseATRMATrend) {
            buy_condition = atr_signal && g_current_trend_up;
            sell_condition = atr_signal && !g_current_trend_up;
        } else if (Scalping_UsePriceSwings) {
            buy_condition = swing_signal && g_current_trend_up;
            sell_condition = swing_signal && !g_current_trend_up;
        }
    }
    
    // 신호 실행
    if (buy_condition && CountPositionsMQL4(OP_BUY) < Scalping_MaxTrades) {
        ExecuteBuyOrderMQL4();
    }
    
    if (sell_condition && CountPositionsMQL4(OP_SELL) < Scalping_MaxTrades) {
        ExecuteSellOrderMQL4();
    }
}

//+------------------------------------------------------------------+
//| MQL4 ATR MA Trend 분석                                          |
//+------------------------------------------------------------------+
bool AnalyzeATRMATrendMQL4() {
    // ATR 값 계산
    double atr_current = iATR(Symbol(), Period(), ATR_Period, 0);
    double atr_prev = iATR(Symbol(), Period(), ATR_Period, 1);
    
    // 이동평균 계산
    double ma_current = iMA(Symbol(), Period(), MA_Period, 0, MA_Method, MA_AppliedPrice, 0);
    double ma_prev = iMA(Symbol(), Period(), MA_Period, 0, MA_Method, MA_AppliedPrice, 1);
    
    // 현재 가격
    double price_current = Close[0];
    double price_prev = Close[1];
    
    // 변동성 기반 임계값
    double threshold = atr_current * ATR_Sensitivity;
    
    // 트렌드 방향 결정 및 신호 생성
    if (price_current > ma_current + threshold && price_prev <= ma_prev + threshold) {
        g_current_trend_up = true;  // 상승 트렌드 시작
        if (Scalping_AlertOnSignal) {
            SendAlertMQL4("ATR MA Trend 상승 신호 - 가격: " + DoubleToString(price_current, Digits));
        }
        return true;
    }
    
    if (price_current < ma_current - threshold && price_prev >= ma_prev - threshold) {
        g_current_trend_up = false; // 하락 트렌드 시작
        if (Scalping_AlertOnSignal) {
            SendAlertMQL4("ATR MA Trend 하락 신호 - 가격: " + DoubleToString(price_current, Digits));
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| MQL4 Price Swings 분석                                          |
//+------------------------------------------------------------------+
bool AnalyzePriceSwingsMQL4() {
    if (Swing_Period >= Bars) return false;
    
    // 최근 고점/저점 수집
    double swing_high = High[iHighest(Symbol(), Period(), MODE_HIGH, Swing_Period, 0)];
    double swing_low = Low[iLowest(Symbol(), Period(), MODE_LOW, Swing_Period, 0)];
    
    // 현재 가격과 스윙 포인트 비교
    double current_price = Close[0];
    double prev_price = Close[1];
    
    // 스윙 신호 생성
    double swing_range = swing_high - swing_low;
    double threshold = swing_range * Swing_Threshold;
    
    // 상승 스윙 신호
    if (current_price > prev_price && 
        current_price > swing_low + threshold &&
        prev_price <= swing_low + threshold) {
        g_current_trend_up = true;
        if (Scalping_AlertOnSignal) {
            SendAlertMQL4("Price Swings 상승 신호 - 스윙 돌파");
        }
        return true;
    }
    
    // 하락 스윙 신호
    if (current_price < prev_price && 
        current_price < swing_high - threshold &&
        prev_price >= swing_high - threshold) {
        g_current_trend_up = false;
        if (Scalping_AlertOnSignal) {
            SendAlertMQL4("Price Swings 하락 신호 - 스윙 돌파");
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| MQL4 매수 주문 실행                                               |
//+------------------------------------------------------------------+
void ExecuteBuyOrderMQL4() {
    double lot_size = CalculateLotSizeMQL4();
    double ask_price = Ask;
    double sl_price = ask_price - Scalping_StopLoss * Point;
    double tp_price = ask_price + Scalping_TakeProfit * Point;
    
    // 주문 실행
    int ticket = OrderSend(Symbol(), OP_BUY, lot_size, ask_price, 3, sl_price, tp_price, 
                          "Nomadtown-Scalping-BUY", g_magic_number, 0, clrGreen);
    
    if (ticket > 0) {
        g_total_trades++;
        Print(g_log_prefix, "매수 주문 성공 - 티켓: ", ticket, ", 가격: ", ask_price, ", 거래량: ", lot_size);
        
        if (Scalping_AlertOnTrade) {
            SendAlertMQL4("스캘핑 매수 주문 실행 - 가격: " + DoubleToString(ask_price, Digits));
        }
    } else {
        Print(g_log_prefix, "매수 주문 실패 - 에러: ", GetLastError(), " (", ErrorDescription(GetLastError()), ")");
    }
}

//+------------------------------------------------------------------+
//| MQL4 매도 주문 실행                                               |
//+------------------------------------------------------------------+
void ExecuteSellOrderMQL4() {
    double lot_size = CalculateLotSizeMQL4();
    double bid_price = Bid;
    double sl_price = bid_price + Scalping_StopLoss * Point;
    double tp_price = bid_price - Scalping_TakeProfit * Point;
    
    // 주문 실행
    int ticket = OrderSend(Symbol(), OP_SELL, lot_size, bid_price, 3, sl_price, tp_price, 
                          "Nomadtown-Scalping-SELL", g_magic_number, 0, clrRed);
    
    if (ticket > 0) {
        g_total_trades++;
        Print(g_log_prefix, "매도 주문 성공 - 티켓: ", ticket, ", 가격: ", bid_price, ", 거래량: ", lot_size);
        
        if (Scalping_AlertOnTrade) {
            SendAlertMQL4("스캘핑 매도 주문 실행 - 가격: " + DoubleToString(bid_price, Digits));
        }
    } else {
        Print(g_log_prefix, "매도 주문 실패 - 에러: ", GetLastError(), " (", ErrorDescription(GetLastError()), ")");
    }
}

//+------------------------------------------------------------------+
//| MQL4 거래량 계산                                                  |
//+------------------------------------------------------------------+
double CalculateLotSizeMQL4() {
    double lot_size = Scalping_LotSize;
    
    // 동적 거래량 계산
    if (Scalping_UseDynamicLots) {
        double account_balance = AccountBalance();
        double risk_amount = account_balance * Scalping_RiskPercent / 100.0;
        double tick_value = MarketInfo(Symbol(), MODE_TICKVALUE);
        double stop_loss_points = Scalping_StopLoss;
        
        if (tick_value > 0 && stop_loss_points > 0) {
            lot_size = risk_amount / (stop_loss_points * tick_value);
        }
        
        // 최소/최대 거래량 제한
        double min_lot = MarketInfo(Symbol(), MODE_MINLOT);
        double max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
        double lot_step = MarketInfo(Symbol(), MODE_LOTSTEP);
        
        lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
        lot_size = MathRound(lot_size / lot_step) * lot_step;
    }
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| MQL4 포지션 수 계산                                               |
//+------------------------------------------------------------------+
int CountPositionsMQL4(int order_type) {
    int count = 0;
    int total_orders = OrdersTotal();
    
    for (int i = 0; i < total_orders; i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() == Symbol() && 
                OrderMagicNumber() == g_magic_number &&
                OrderType() == order_type) {
                count++;
            }
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| MQL4 기존 포지션 관리                                             |
//+------------------------------------------------------------------+
void ManageExistingPositionsMQL4() {
    int total_orders = OrdersTotal();
    
    for (int i = total_orders - 1; i >= 0; i--) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == g_magic_number) {
                
                // 반대 신호 발생 시 포지션 닫기
                bool should_close = false;
                
                if (OrderType() == OP_BUY && !g_current_trend_up) {
                    should_close = true;
                }
                if (OrderType() == OP_SELL && g_current_trend_up) {
                    should_close = true;
                }
                
                if (should_close) {
                    ClosePositionMQL4(OrderTicket());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| MQL4 포지션 닫기                                                  |
//+------------------------------------------------------------------+
bool ClosePositionMQL4(int ticket) {
    if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
        return false;
    }
    
    double close_price = (OrderType() == OP_BUY) ? Bid : Ask;
    
    if (OrderClose(ticket, OrderLots(), close_price, 3, clrYellow)) {
        Print(g_log_prefix, "포지션 닫기 성공 - 티켓: ", ticket);
        
        // 수익 계산
        double profit = OrderProfit() + OrderSwap() + OrderCommission();
        g_total_profit += profit;
        
        if (profit > 0) {
            g_winning_trades++;
        }
        
        return true;
    } else {
        Print(g_log_prefix, "포지션 닫기 실패 - 티켓: ", ticket, ", 에러: ", GetLastError());
        return false;
    }
}

//+------------------------------------------------------------------+
//| MQL4 트레일링 스톱 업데이트                                        |
//+------------------------------------------------------------------+
void UpdateTrailingStopsMQL4() {
    int total_orders = OrdersTotal();
    
    for (int i = 0; i < total_orders; i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if (OrderSymbol() == Symbol() && OrderMagicNumber() == g_magic_number) {
                
                double new_sl = 0;
                bool should_modify = false;
                
                if (OrderType() == OP_BUY) {
                    new_sl = Bid - Scalping_TrailingStop * Point;
                    if (new_sl > OrderStopLoss() && new_sl < Bid) {
                        should_modify = true;
                    }
                } else if (OrderType() == OP_SELL) {
                    new_sl = Ask + Scalping_TrailingStop * Point;
                    if ((new_sl < OrderStopLoss() || OrderStopLoss() == 0) && new_sl > Ask) {
                        should_modify = true;
                    }
                }
                
                if (should_modify) {
                    if (OrderModify(OrderTicket(), OrderOpenPrice(), new_sl, OrderTakeProfit(), 0, clrBlue)) {
                        Print(g_log_prefix, "트레일링 스톱 업데이트 - 티켓: ", OrderTicket(), ", 새 SL: ", new_sl);
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| MQL4 유틸리티 함수들                                              |
//+------------------------------------------------------------------+

bool ValidateScalpingInputsMQL4() {
    // 기본 검증 로직 (간소화)
    if (Scalping_LotSize <= 0) return false;
    if (Scalping_MaxTrades <= 0) return false;
    if (ATR_Period < 5) return false;
    if (Swing_Period < 3) return false;
    return true;
}

void PrintScalpingSettingsMQL4() {
    Print(g_log_prefix, "=== 스캘핑 설정 (MQL4) ===");
    Print(g_log_prefix, "거래량: ", Scalping_LotSize);
    Print(g_log_prefix, "최대 거래: ", Scalping_MaxTrades);
    Print(g_log_prefix, "ATR 기간: ", ATR_Period);
    Print(g_log_prefix, "스윙 기간: ", Swing_Period);
    Print(g_log_prefix, "========================");
}

bool IsSpreadAcceptableMQL4() {
    if (!Scalping_UseSpreadFilter) return true;
    double spread = MarketInfo(Symbol(), MODE_SPREAD) * Point;
    return spread <= Scalping_MaxSpread * Point;
}

bool IsTimeFilterOKMQL4() {
    if (!Scalping_UseTimeFilter) return true;
    int hour = TimeHour(TimeCurrent());
    if (Scalping_StartHour <= Scalping_EndHour) {
        return hour >= Scalping_StartHour && hour <= Scalping_EndHour;
    } else {
        return hour >= Scalping_StartHour || hour <= Scalping_EndHour;
    }
}

bool IsRiskAcceptableMQL4() {
    static datetime last_trade_time = 0;
    if (TimeCurrent() - last_trade_time < 60) return false; // 1분 간격
    
    int total_positions = CountPositionsMQL4(OP_BUY) + CountPositionsMQL4(OP_SELL);
    if (total_positions >= Scalping_MaxTrades) return false;
    
    last_trade_time = TimeCurrent();
    return true;
}

bool ShouldCheckForNewSignalsMQL4() {
    static datetime last_signal_time = 0;
    if (TimeCurrent() - last_signal_time < 60) return false;
    
    int total_positions = CountPositionsMQL4(OP_BUY) + CountPositionsMQL4(OP_SELL);
    if (total_positions >= Scalping_MaxTrades) return false;
    
    last_signal_time = TimeCurrent();
    return true;
}

void UpdatePerformanceMetricsMQL4() {
    double current_equity = AccountEquity();
    
    if (current_equity > g_equity_peak) {
        g_equity_peak = current_equity;
    }
    
    double current_drawdown = (g_equity_peak - current_equity) / g_equity_peak * 100;
    if (current_drawdown > g_max_drawdown) {
        g_max_drawdown = current_drawdown;
    }
    
    if (current_drawdown > Scalping_MaxDrawdownPercent) {
        Print(g_log_prefix, "경고: 최대 낙폭 초과! 현재: ", DoubleToString(current_drawdown, 2), "%");
    }
}

void PrintFinalPerformanceReportMQL4() {
    Print(g_log_prefix, "=== 최종 성과 (MQL4) ===");
    Print(g_log_prefix, "총 거래: ", g_total_trades);
    Print(g_log_prefix, "승리 거래: ", g_winning_trades);
    Print(g_log_prefix, "승률: ", (g_total_trades > 0 ? DoubleToString((double)g_winning_trades / g_total_trades * 100, 2) : "0"), "%");
    Print(g_log_prefix, "총 수익: ", DoubleToString(g_total_profit, 2));
    Print(g_log_prefix, "최대 낙폭: ", DoubleToString(g_max_drawdown, 2), "%");
    Print(g_log_prefix, "==================");
}

string GetStatusInfoMQL4() {
    string status = "스캘핑 상태: ";
    status += "거래수=" + IntegerToString(CountPositionsMQL4(OP_BUY) + CountPositionsMQL4(OP_SELL));
    status += ", 트렌드=" + (g_current_trend_up ? "상승" : "하락");
    status += ", 스프레드=" + DoubleToString(MarketInfo(Symbol(), MODE_SPREAD), 1);
    return status;
}

void SendAlertMQL4(string message) {
    if (!Scalping_EnableAlerts) return;
    
    string full_message = g_log_prefix + message;
    Alert(full_message);
    
    if (Scalping_SendEmail) {
        SendMail("Nomadtown 스캘핑 알림", full_message);
    }
}

string GetDeinitReasonMQL4(int reason) {
    switch(reason) {
        case REASON_PROGRAM: return "프로그램 종료";
        case REASON_REMOVE: return "차트에서 제거";
        case REASON_RECOMPILE: return "재컴파일";
        case REASON_CHARTCHANGE: return "차트 변경";
        case REASON_CHARTCLOSE: return "차트 닫기";
        case REASON_PARAMETERS: return "매개변수 변경";
        case REASON_ACCOUNT: return "계좌 변경";
        default: return "알 수 없음";
    }
}