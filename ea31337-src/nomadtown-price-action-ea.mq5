//+------------------------------------------------------------------+
//|                                  nomadtown-price-action-ea.mq5 |
//|                     가격행동 거래 Expert Advisor (MetaTrader 5)    |
//|              핵심 지지/저항 구간 식별 후 진입/청산 시스템            |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Price Action Edition"
#property link      ""
#property version   "1.00"
#property description "가격행동 거래 EA - 지지/저항 기반 진입/청산 (Nomadtown System)"

// 필요한 헤더 파일들
#include "include/price-action/PriceActionAnalyzer.mqh"

//+------------------------------------------------------------------+
//| 입력 매개변수                                                     |
//+------------------------------------------------------------------+
#ifdef __MQL4__
input static string __PriceAction_Settings__ = "=== 가격행동 거래 설정 ===";
#else
input group "가격행동 거래 설정 (Price Action Trading)"
#endif

// ===== 기본 거래 설정 =====
input double    PA_LotSize = 0.02;                          // 거래량 (Lot Size)
input int       PA_MaxTrades = 3;                           // 최대 동시 거래 수 (Max Simultaneous Trades)
input double    PA_MaxSpread = 3.0;                         // 최대 허용 스프레드 (Max Spread in Points)

// ===== 지지/저항 감지 설정 =====
#ifdef __MQL4__
input static string __Level_Detection__ = "=== 지지/저항 감지 ===";
#else
input group "지지/저항 감지 (Level Detection)"
#endif

input int       PA_LookbackPeriod = 100;                    // 분석 기간 (Lookback Period)
input double    PA_LevelTolerance = 5.0;                    // 레벨 허용오차 pips (Level Tolerance)
input int       PA_MinTouches = 2;                          // 최소 터치 횟수 (Min Touches)
input double    PA_MinStrength = 0.4;                       // 최소 강도 (Min Strength 0.0-1.0)

// ===== 신호 생성 설정 =====
#ifdef __MQL4__
input static string __Signal_Settings__ = "=== 신호 생성 설정 ===";
#else
input group "신호 생성 설정 (Signal Settings)"
#endif

input bool      PA_UseBreakout = true;                      // 돌파 신호 사용 (Use Breakout Signals)
input bool      PA_UseBounce = true;                        // 바운스 신호 사용 (Use Bounce Signals)
input double    PA_BreakoutBuffer = 3.0;                    // 돌파 확인 버퍼 pips (Breakout Buffer)
input double    PA_BounceBuffer = 2.0;                      // 바운스 확인 버퍼 pips (Bounce Buffer)

// ===== 리스크 관리 =====
#ifdef __MQL4__
input static string __Risk_Management__ = "=== 리스크 관리 ===";
#else
input group "리스크 관리 (Risk Management)"
#endif

input double    PA_StopLoss = 20.0;                         // 손절매 (Stop Loss in Pips)
input double    PA_TakeProfit = 40.0;                       // 익절 (Take Profit in Pips)
input double    PA_RiskRewardRatio = 2.0;                   // 리스크 수익 비율 (Risk Reward Ratio)
input bool      PA_UseTrailingStop = true;                  // 트레일링 스톱 사용 (Use Trailing Stop)
input double    PA_TrailingDistance = 15.0;                 // 트레일링 거리 pips (Trailing Distance)

// ===== 필터 설정 =====
#ifdef __MQL4__
input static string __Filter_Settings__ = "=== 필터 설정 ===";
#else
input group "필터 설정 (Filter Settings)"
#endif

input bool      PA_UseVolumeFilter = true;                  // 볼륨 필터 사용 (Use Volume Filter)
input bool      PA_UseMomentumFilter = true;                // 모멘텀 필터 사용 (Use Momentum Filter)
input bool      PA_UseTimeFilter = true;                    // 시간 필터 사용 (Use Time Filter)
input int       PA_StartHour = 8;                           // 거래 시작 시간 (Trading Start Hour)
input int       PA_EndHour = 18;                            // 거래 종료 시간 (Trading End Hour)

// ===== 알림 설정 =====
#ifdef __MQL4__
input static string __Alert_Settings__ = "=== 알림 설정 ===";
#else
input group "알림 설정 (Alert Settings)"
#endif

input bool      PA_EnableAlerts = true;                     // 알림 활성화 (Enable Alerts)
input bool      PA_AlertOnSignal = true;                    // 신호 발생 시 알림 (Alert on Signal)
input bool      PA_AlertOnTrade = true;                     // 거래 실행 시 알림 (Alert on Trade)
input bool      PA_SendEmail = false;                       // 이메일 발송 (Send Email)

//+------------------------------------------------------------------+
//| 전역 변수                                                        |
//+------------------------------------------------------------------+
PriceActionAnalyzer *g_price_action_analyzer = NULL;        // 가격행동 분석기
int g_magic_number = 31340;                                 // 가격행동 EA 전용 매직 넘버
string g_log_prefix = "[Nomadtown-PriceAction] ";           // 로그 접두사

// 성과 추적 변수
double g_total_profit = 0;
int g_total_trades = 0;
int g_winning_trades = 0;
double g_max_drawdown = 0;
double g_equity_peak = 0;
int g_current_trades = 0;

// 거래 추적 변수
datetime g_last_analysis_time = 0;
double g_last_support_level = 0;
double g_last_resistance_level = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print(g_log_prefix, "=== Nomadtown 가격행동 거래 시스템 초기화 ===");
    
    // 입력 매개변수 검증
    if (!ValidatePriceActionInputs()) {
        Print(g_log_prefix, "❌ 입력 매개변수 검증 실패!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 설정 정보 출력
    PrintPriceActionSettings();
    
    // 가격행동 분석기 초기화
    PriceActionConfig config = GetPriceActionConfigFromInputs();
    g_price_action_analyzer = new PriceActionAnalyzer(config, _Symbol, PERIOD_CURRENT);
    
    if (g_price_action_analyzer == NULL) {
        Print(g_log_prefix, "❌ 가격행동 분석기 초기화 실패!");
        return INIT_FAILED;
    }
    
    // 초기 상태 설정
    g_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // 초기 지지/저항 분석
    g_price_action_analyzer.AnalyzeSupportResistanceLevels();
    g_last_analysis_time = TimeCurrent();
    
    // 알림 설정
    if (PA_EnableAlerts) {
        Print(g_log_prefix, "🔔 알림 시스템 활성화");
        Alert("Nomadtown 가격행동 거래 시스템이 시작되었습니다.");
    }
    
    Print(g_log_prefix, "✅ 초기화 완료! 지지/저항 기반 가격행동 거래를 시작합니다.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print(g_log_prefix, "=== Nomadtown 가격행동 거래 시스템 종료 ===");
    
    // 최종 성과 리포트
    PrintPriceActionPerformanceReport();
    
    // 메모리 정리
    if (g_price_action_analyzer != NULL) {
        delete g_price_action_analyzer;
        g_price_action_analyzer = NULL;
    }
    
    Print(g_log_prefix, "✅ 시스템 종료 완료");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (g_price_action_analyzer == NULL) return;
    
    // 주기적 지지/저항 레벨 분석 (5분마다)
    if (TimeCurrent() - g_last_analysis_time > 300) {
        g_price_action_analyzer.AnalyzeSupportResistanceLevels();
        g_last_analysis_time = TimeCurrent();
        
        // 현재 레벨 업데이트
        double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        g_last_support_level = g_price_action_analyzer.GetNearestSupport(current_price);
        g_last_resistance_level = g_price_action_analyzer.GetNearestResistance(current_price);
    }
    
    // 트레일링 스톱 업데이트
    if (PA_UseTrailingStop) {
        UpdateTrailingStops();
    }
    
    // 기존 포지션 관리
    ManageExistingPositions();
    
    // 새로운 신호 분석 및 거래 실행
    AnalyzeAndExecutePriceActionSignals();
    
    // 성과 추적 업데이트
    UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| 가격행동 신호 분석 및 거래 실행                                     |
//+------------------------------------------------------------------+
void AnalyzeAndExecutePriceActionSignals() {
    // 거래 수 제한 확인
    if (g_current_trades >= PA_MaxTrades) {
        return;
    }
    
    // 스프레드 체크
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if (spread > PA_MaxSpread * SymbolInfoDouble(_Symbol, SYMBOL_POINT)) {
        return;
    }
    
    // 시간 필터 체크
    if (PA_UseTimeFilter) {
        datetime current_time = TimeCurrent();
        int current_hour = TimeHour(current_time);
        if (current_hour < PA_StartHour || current_hour > PA_EndHour) {
            return;
        }
    }
    
    // 가격행동 신호 분석
    ENUM_PRICE_ACTION_SIGNAL signal = g_price_action_analyzer.GetPriceActionSignal();
    
    if (PA_AlertOnSignal && signal != PA_SIGNAL_NONE) {
        Print(g_log_prefix, "📊 가격행동 신호 감지: ", EnumToString(signal));
        if (PA_EnableAlerts) {
            Alert("가격행동 신호: " + EnumToString(signal));
        }
    }
    
    switch (signal) {
        case PA_SIGNAL_BUY_BREAKOUT:
            ExecutePriceActionBuy("저항돌파매수");
            break;
        case PA_SIGNAL_BUY_BOUNCE:
            ExecutePriceActionBuy("지지바운스매수");
            break;
        case PA_SIGNAL_SELL_BREAKDOWN:
            ExecutePriceActionSell("지지이탈매도");
            break;
        case PA_SIGNAL_SELL_REJECTION:
            ExecutePriceActionSell("저항거부매도");
            break;
    }
}

//+------------------------------------------------------------------+
//| 가격행동 매수 주문 실행                                            |
//+------------------------------------------------------------------+
void ExecutePriceActionBuy(string signal_type) {
    double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double sl_price = 0, tp_price = 0;
    
    // 동적 스톱/타겟 설정
    if (g_last_support_level > 0) {
        // 지지선 기반 스톱로스
        sl_price = g_last_support_level - 10 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    } else {
        // 기본 스톱로스
        sl_price = ask_price - PA_StopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    }
    
    if (g_last_resistance_level > 0) {
        // 저항선 기반 타겟
        tp_price = g_last_resistance_level - 5 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    } else {
        // 기본 타겟
        tp_price = ask_price + PA_TakeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    }
    
    Print(g_log_prefix, "🟢 ", signal_type, " 신호 - 지지: ", DoubleToString(g_last_support_level, _Digits), 
          ", 저항: ", DoubleToString(g_last_resistance_level, _Digits));
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = PA_LotSize;
    request.type = ORDER_TYPE_BUY;
    request.price = ask_price;
    request.sl = sl_price;
    request.tp = tp_price;
    request.deviation = 3;
    request.magic = g_magic_number;
    request.comment = "PriceAction-" + signal_type;
    
    if (OrderSend(request, result)) {
        g_total_trades++;
        g_current_trades++;
        Print(g_log_prefix, "✅ ", signal_type, " 주문 성공 - 티켓: ", result.order, 
              ", 가격: ", ask_price, ", SL: ", sl_price, ", TP: ", tp_price);
        
        if (PA_AlertOnTrade) {
            Alert("가격행동 " + signal_type + " 주문 실행");
        }
    } else {
        Print(g_log_prefix, "❌ ", signal_type, " 주문 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 가격행동 매도 주문 실행                                            |
//+------------------------------------------------------------------+
void ExecutePriceActionSell(string signal_type) {
    double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sl_price = 0, tp_price = 0;
    
    // 동적 스톱/타겟 설정
    if (g_last_resistance_level > 0) {
        // 저항선 기반 스톱로스
        sl_price = g_last_resistance_level + 10 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    } else {
        // 기본 스톱로스
        sl_price = bid_price + PA_StopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    }
    
    if (g_last_support_level > 0) {
        // 지지선 기반 타겟
        tp_price = g_last_support_level + 5 * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    } else {
        // 기본 타겟
        tp_price = bid_price - PA_TakeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    }
    
    Print(g_log_prefix, "🔴 ", signal_type, " 신호 - 지지: ", DoubleToString(g_last_support_level, _Digits), 
          ", 저항: ", DoubleToString(g_last_resistance_level, _Digits));
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = PA_LotSize;
    request.type = ORDER_TYPE_SELL;
    request.price = bid_price;
    request.sl = sl_price;
    request.tp = tp_price;
    request.deviation = 3;
    request.magic = g_magic_number;
    request.comment = "PriceAction-" + signal_type;
    
    if (OrderSend(request, result)) {
        g_total_trades++;
        g_current_trades++;
        Print(g_log_prefix, "✅ ", signal_type, " 주문 성공 - 티켓: ", result.order, 
              ", 가격: ", bid_price, ", SL: ", sl_price, ", TP: ", tp_price);
        
        if (PA_AlertOnTrade) {
            Alert("가격행동 " + signal_type + " 주문 실행");
        }
    } else {
        Print(g_log_prefix, "❌ ", signal_type, " 주문 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 유틸리티 함수들                                                   |
//+------------------------------------------------------------------+
bool ValidatePriceActionInputs() {
    bool is_valid = true;
    
    if (PA_LotSize <= 0) {
        Print(g_log_prefix, "오류: 거래량은 0보다 커야 합니다.");
        is_valid = false;
    }
    
    if (PA_LookbackPeriod < 20 || PA_LookbackPeriod > 500) {
        Print(g_log_prefix, "오류: 분석 기간은 20-500 사이여야 합니다.");
        is_valid = false;
    }
    
    if (PA_MinStrength < 0.1 || PA_MinStrength > 1.0) {
        Print(g_log_prefix, "오류: 최소 강도는 0.1-1.0 사이여야 합니다.");
        is_valid = false;
    }
    
    return is_valid;
}

PriceActionConfig GetPriceActionConfigFromInputs() {
    PriceActionConfig config;
    
    // 지지/저항 감지 설정
    config.lookback_period = PA_LookbackPeriod;
    config.level_tolerance = PA_LevelTolerance;
    config.min_touches = PA_MinTouches;
    config.min_strength = PA_MinStrength;
    
    // 신호 생성 설정
    config.use_breakout = PA_UseBreakout;
    config.use_bounce = PA_UseBounce;
    config.breakout_buffer = PA_BreakoutBuffer;
    config.bounce_buffer = PA_BounceBuffer;
    
    // 필터 설정
    config.use_volume_filter = PA_UseVolumeFilter;
    config.use_momentum_filter = PA_UseMomentumFilter;
    config.use_time_filter = PA_UseTimeFilter;
    
    // 리스크 관리
    config.risk_reward_ratio = PA_RiskRewardRatio;
    config.max_risk_per_trade = 2.0;
    config.use_trailing_stop = PA_UseTrailingStop;
    
    return config;
}

void ManageExistingPositions() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == g_magic_number) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            
            // 가격행동 기반 청산 신호 확인
            if (ShouldClosePriceActionPosition(ticket)) {
                ClosePosition(ticket);
            }
        }
    }
}

bool ShouldClosePriceActionPosition(ulong ticket) {
    if (!PositionSelectByTicket(ticket)) return false;
    
    double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    // 반대 신호 확인
    ENUM_PRICE_ACTION_SIGNAL signal = g_price_action_analyzer.GetPriceActionSignal();
    
    if (type == POSITION_TYPE_BUY) {
        // 매수 포지션: 저항선 거부 신호시 청산
        return (signal == PA_SIGNAL_SELL_REJECTION);
    } else {
        // 매도 포지션: 지지선 바운스 신호시 청산  
        return (signal == PA_SIGNAL_BUY_BOUNCE);
    }
}

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
    request.comment = "PriceAction-CLOSE";
    
    if (OrderSend(request, result)) {
        Print(g_log_prefix, "✅ 포지션 닫기 성공 - 티켓: ", ticket);
        
        double profit = PositionGetDouble(POSITION_PROFIT);
        if (profit > 0) {
            g_winning_trades++;
        }
        g_total_profit += profit;
        
        if (g_current_trades > 0) {
            g_current_trades--;
        }
        
        return true;
    } else {
        Print(g_log_prefix, "❌ 포지션 닫기 실패 - 티켓: ", ticket, ", 에러: ", GetLastError());
        return false;
    }
}

void UpdateTrailingStops() {
    // 트레일링 스톱 구현 (간소화)
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

void PrintPriceActionSettings() {
    Print(g_log_prefix, "=== 가격행동 거래 설정 정보 ===");
    Print(g_log_prefix, "📊 지지/저항 분석 모드");
    Print(g_log_prefix, "거래량: ", PA_LotSize);
    Print(g_log_prefix, "최대 거래: ", PA_MaxTrades);
    Print(g_log_prefix, "분석 기간: ", PA_LookbackPeriod, " 캔들");
    Print(g_log_prefix, "레벨 허용오차: ", PA_LevelTolerance, " pips");
    Print(g_log_prefix, "최소 터치: ", PA_MinTouches, "회");
    Print(g_log_prefix, "최소 강도: ", PA_MinStrength);
    Print(g_log_prefix, "돌파 신호: ", (PA_UseBreakout ? "활성" : "비활성"));
    Print(g_log_prefix, "바운스 신호: ", (PA_UseBounce ? "활성" : "비활성"));
    Print(g_log_prefix, "손절매: ", PA_StopLoss, " pips");
    Print(g_log_prefix, "익절: ", PA_TakeProfit, " pips");
    Print(g_log_prefix, "리스크 수익 비율: 1:", PA_RiskRewardRatio);
    Print(g_log_prefix, "===========================");
}

void PrintPriceActionPerformanceReport() {
    Print(g_log_prefix, "=== 최종 성과 (가격행동 거래) ===");
    Print(g_log_prefix, "총 거래: ", g_total_trades);
    Print(g_log_prefix, "승리 거래: ", g_winning_trades);
    Print(g_log_prefix, "승률: ", (g_total_trades > 0 ? DoubleToString((double)g_winning_trades / g_total_trades * 100, 2) : "0"), "%");
    Print(g_log_prefix, "총 수익: ", DoubleToString(g_total_profit, 2));
    Print(g_log_prefix, "최대 낙폭: ", DoubleToString(g_max_drawdown, 2), "%");
    Print(g_log_prefix, "활성 레벨: ", g_price_action_analyzer.GetLevelCount(), "개");
    Print(g_log_prefix, "현재 지지: ", DoubleToString(g_last_support_level, _Digits));
    Print(g_log_prefix, "현재 저항: ", DoubleToString(g_last_resistance_level, _Digits));
    Print(g_log_prefix, "===============================");
}