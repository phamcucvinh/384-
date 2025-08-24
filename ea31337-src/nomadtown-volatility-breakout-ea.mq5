//+------------------------------------------------------------------+
//|                           nomadtown-volatility-breakout-ea.mq5 |
//|                  변동성 돌파 + 동적 리스크 관리 Expert Advisor      |
//|              ATR 기반 변동성 분석과 런던 세션 돌파 시스템            |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Volatility Breakout Edition"
#property link      ""
#property version   "1.00"
#property description "변동성 돌파 + 동적 리스크 관리 EA (Nomadtown System)"

// 필요한 헤더 파일들
#include "include/volatility-breakout/VolatilityBreakoutAnalyzer.mqh"
#include "include/risk-management/DynamicRiskManager.mqh"

//+------------------------------------------------------------------+
//| 입력 매개변수                                                     |
//+------------------------------------------------------------------+
#ifdef __MQL4__
input static string __VolBreakout_Settings__ = "=== 변동성 돌파 설정 ===";
#else
input group "변동성 돌파 설정 (Volatility Breakout)"
#endif

// ===== 기본 거래 설정 =====
input double    VB_LotSize = 0.03;                          // 거래량 (Lot Size)
input int       VB_MaxTrades = 3;                           // 최대 동시 거래 수 (Max Simultaneous Trades)
input double    VB_MaxSpread = 2.5;                         // 최대 허용 스프레드 (Max Spread in Points)

// ===== ATR 및 변동성 설정 =====
#ifdef __MQL4__
input static string __ATR_Settings__ = "=== ATR 및 변동성 ===";
#else
input group "ATR 및 변동성 (ATR & Volatility)"
#endif

input int       VB_ATRPeriod = 14;                          // ATR 기간 (ATR Period)
input double    VB_ATRMultEntry = 1.5;                      // 진입 ATR 배수 (Entry ATR Multiplier)
input double    VB_ATRMultExit = 2.5;                       // 청산 ATR 배수 (Exit ATR Multiplier)
input double    VB_LowVolThreshold = 0.7;                   // 저변동성 임계값 (Low Volatility Threshold)
input double    VB_HighVolThreshold = 1.3;                  // 고변동성 임계값 (High Volatility Threshold)
input double    VB_BreakoutThreshold = 0.5;                 // 돌파 임계값 ATR배수 (Breakout Threshold)

// ===== 횡보 및 돌파 설정 =====
#ifdef __MQL4__
input static string __Breakout_Settings__ = "=== 횡보 및 돌파 ===";
#else
input group "횡보 및 돌파 (Consolidation & Breakout)"
#endif

input int       VB_ConsolidationPeriod = 10;                // 횡보 기간 (Consolidation Period in Bars)
input bool      VB_UseVolumeConfirm = true;                 // 볼륨 확인 사용 (Use Volume Confirmation)
input bool      VB_UseTimeConfirm = true;                   // 시간 확인 사용 (Use Time Confirmation)
input int       VB_MinBreakoutBars = 2;                     // 최소 돌파 지속 봉 (Min Breakout Duration)

// ===== 런던 세션 설정 =====
#ifdef __MQL4__
input static string __London_Settings__ = "=== 런던 세션 ===";
#else
input group "런던 세션 (London Session)"
#endif

input bool      VB_UseLondonSession = true;                 // 런던 세션 사용 (Use London Session)
input int       VB_LondonStartHour = 7;                     // 런던 시작 시간 GMT (London Start Hour)
input int       VB_LondonEndHour = 17;                      // 런던 종료 시간 GMT (London End Hour)
input bool      VB_LondonBreakoutOnly = false;              // 런던 돌파만 거래 (London Breakout Only)

// ===== 동적 리스크 관리 =====
#ifdef __MQL4__
input static string __Risk_Settings__ = "=== 동적 리스크 관리 ===";
#else
input group "동적 리스크 관리 (Dynamic Risk Management)"
#endif

input bool      VB_UseDynamicRisk = true;                   // 동적 리스크 사용 (Use Dynamic Risk)
input double    VB_BaseRiskPercent = 2.0;                   // 기본 리스크 % (Base Risk Percent)
input double    VB_MaxRiskPercent = 4.0;                    // 최대 리스크 % (Max Risk Percent)
input double    VB_MinRiskPercent = 0.5;                    // 최소 리스크 % (Min Risk Percent)
input bool      VB_UseVolatilityRisk = true;                // 변동성 기반 리스크 (Use Volatility Risk)

// ===== 청산 설정 =====
#ifdef __MQL4__
input static string __Exit_Settings__ = "=== 청산 설정 ===";
#else
input group "청산 설정 (Exit Settings)"
#endif

input bool      VB_UseTimeExit = true;                      // 시간 청산 사용 (Use Time Exit)
input int       VB_MaxHoldingHours = 8;                     // 최대 보유 시간 (Max Holding Hours)
input bool      VB_UseProfitProtection = true;              // 수익 보호 사용 (Use Profit Protection)
input double    VB_ProfitProtectionLevel = 1.5;             // 수익 보호 레벨 ATR배수 (Profit Protection Level)
input bool      VB_UseTrailingStop = true;                  // 트레일링 스톱 사용 (Use Trailing Stop)

// ===== 보호 설정 =====
#ifdef __MQL4__
input static string __Protection_Settings__ = "=== 보호 설정 ===";
#else
input group "보호 설정 (Protection Settings)"
#endif

input double    VB_MaxDailyLoss = 3.0;                      // 일일 최대 손실 % (Max Daily Loss Percent)
input double    VB_MaxMonthlyLoss = 10.0;                   // 월별 최대 손실 % (Max Monthly Loss Percent)
input int       VB_MaxConsecutiveLosses = 4;                // 최대 연속 손실 수 (Max Consecutive Losses)
input bool      VB_EnableEmergencyStop = true;              // 응급 정지 활성화 (Enable Emergency Stop)

// ===== 알림 설정 =====
#ifdef __MQL4__
input static string __Alert_Settings__ = "=== 알림 설정 ===";
#else
input group "알림 설정 (Alert Settings)"
#endif

input bool      VB_EnableAlerts = true;                     // 알림 활성화 (Enable Alerts)
input bool      VB_AlertOnBreakout = true;                  // 돌파 시 알림 (Alert on Breakout)
input bool      VB_AlertOnTrade = true;                     // 거래 시 알림 (Alert on Trade)
input bool      VB_AlertOnRiskChange = true;                // 리스크 변경 시 알림 (Alert on Risk Change)

//+------------------------------------------------------------------+
//| 전역 변수                                                        |
//+------------------------------------------------------------------+
VolatilityBreakoutAnalyzer *g_volatility_analyzer = NULL;   // 변동성 돌파 분석기
DynamicRiskManager *g_risk_manager = NULL;                  // 동적 리스크 관리자
int g_magic_number = 31341;                                 // 변동성 돌파 EA 전용 매직 넘버
string g_log_prefix = "[Nomadtown-VolatilityBreakout] ";    // 로그 접두사

// 성과 추적 변수
double g_total_profit = 0;
int g_total_trades = 0;
int g_winning_trades = 0;
double g_max_drawdown = 0;
double g_equity_peak = 0;
int g_current_trades = 0;

// 거래 추적 변수
datetime g_last_analysis_time = 0;
double g_last_risk_percent = 0;
ENUM_VOLATILITY_STATE g_last_vol_state = VOL_STATE_NORMAL;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print(g_log_prefix, "=== Nomadtown 변동성 돌파 + 동적 리스크 관리 시스템 초기화 ===");
    
    // 입력 매개변수 검증
    if (!ValidateVolatilityBreakoutInputs()) {
        Print(g_log_prefix, "❌ 입력 매개변수 검증 실패!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 설정 정보 출력
    PrintVolatilityBreakoutSettings();
    
    // 변동성 돌파 분석기 초기화
    VolatilityBreakoutConfig vb_config = GetVolatilityBreakoutConfigFromInputs();
    g_volatility_analyzer = new VolatilityBreakoutAnalyzer(vb_config, _Symbol, PERIOD_CURRENT);
    
    if (g_volatility_analyzer == NULL) {
        Print(g_log_prefix, "❌ 변동성 돌파 분석기 초기화 실패!");
        return INIT_FAILED;
    }
    
    // 동적 리스크 관리자 초기화
    if (VB_UseDynamicRisk) {
        RiskManagementConfig risk_config = GetRiskConfigFromInputs();
        g_risk_manager = new DynamicRiskManager(risk_config);
        
        if (g_risk_manager == NULL) {
            Print(g_log_prefix, "❌ 동적 리스크 관리자 초기화 실패!");
            return INIT_FAILED;
        }
        
        Print(g_log_prefix, "✅ 동적 리스크 관리 시스템 활성화");
    }
    
    // 초기 상태 설정
    g_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
    g_last_risk_percent = VB_BaseRiskPercent;
    
    // 초기 변동성 분석
    g_volatility_analyzer.AnalyzeVolatilityAndRange();
    g_last_analysis_time = TimeCurrent();
    
    // 알림 설정
    if (VB_EnableAlerts) {
        Print(g_log_prefix, "🔔 알림 시스템 활성화");
        Alert("Nomadtown 변동성 돌파 + 동적 리스크 관리 시스템이 시작되었습니다.");
    }
    
    Print(g_log_prefix, "✅ 초기화 완료! ATR 기반 변동성 돌파 거래를 시작합니다.");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print(g_log_prefix, "=== Nomadtown 변동성 돌파 시스템 종료 ===");
    
    // 최종 성과 리포트
    PrintVolatilityBreakoutPerformanceReport();
    
    // 메모리 정리
    if (g_volatility_analyzer != NULL) {
        delete g_volatility_analyzer;
        g_volatility_analyzer = NULL;
    }
    
    if (g_risk_manager != NULL) {
        delete g_risk_manager;
        g_risk_manager = NULL;
    }
    
    Print(g_log_prefix, "✅ 시스템 종료 완료");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (g_volatility_analyzer == NULL) return;
    
    // 주기적 변동성 및 리스크 분석 (5분마다)
    if (TimeCurrent() - g_last_analysis_time > 300) {
        g_volatility_analyzer.AnalyzeVolatilityAndRange();
        g_last_analysis_time = TimeCurrent();
        
        // 변동성 상태 변화 알림
        ENUM_VOLATILITY_STATE current_vol_state = g_volatility_analyzer.GetVolatilityState();
        if (current_vol_state != g_last_vol_state && VB_AlertOnRiskChange) {
            Print(g_log_prefix, "📊 변동성 상태 변화: ", EnumToString(g_last_vol_state), " → ", EnumToString(current_vol_state));
            g_last_vol_state = current_vol_state;
        }
        
        // 동적 리스크 업데이트
        if (g_risk_manager != NULL) {
            double new_risk = g_risk_manager.CalculateDynamicRisk();
            if (MathAbs(new_risk - g_last_risk_percent) > 0.2 && VB_AlertOnRiskChange) {
                Print(g_log_prefix, "⚖️ 리스크 조정: ", DoubleToString(g_last_risk_percent, 2), "% → ", DoubleToString(new_risk, 2), "%");
                g_last_risk_percent = new_risk;
            }
        }
    }
    
    // 트레일링 스톱 업데이트
    if (VB_UseTrailingStop) {
        UpdateTrailingStops();
    }
    
    // 기존 포지션 관리
    ManageExistingPositions();
    
    // 새로운 돌파 신호 분석 및 거래 실행
    AnalyzeAndExecuteVolatilityBreakout();
    
    // 성과 추적 업데이트
    UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| 변동성 돌파 신호 분석 및 거래 실행                                  |
//+------------------------------------------------------------------+
void AnalyzeAndExecuteVolatilityBreakout() {
    // 거래 수 제한 확인
    if (g_current_trades >= VB_MaxTrades) {
        return;
    }
    
    // 스프레드 체크
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if (spread > VB_MaxSpread * SymbolInfoDouble(_Symbol, SYMBOL_POINT)) {
        return;
    }
    
    // 동적 리스크 관리자 거래 허용 확인
    if (g_risk_manager != NULL && !g_risk_manager.IsTradeAllowed()) {
        return;
    }
    
    // 변동성 돌파 신호 분석
    ENUM_VOLATILITY_BREAKOUT_SIGNAL signal = g_volatility_analyzer.GetBreakoutSignal();
    
    if (VB_AlertOnBreakout && signal != VB_SIGNAL_NONE) {
        Print(g_log_prefix, "📈 변동성 돌파 신호 감지: ", EnumToString(signal),
              ", ATR: ", DoubleToString(g_volatility_analyzer.GetCurrentATR(), 5),
              ", 변동성비율: ", DoubleToString(g_volatility_analyzer.GetVolatilityRatio(), 2));
        
        if (VB_EnableAlerts) {
            Alert("변동성 돌파 신호: " + EnumToString(signal));
        }
    }
    
    switch (signal) {
        case VB_SIGNAL_BUY_BREAKOUT:
            ExecuteVolatilityBreakoutBuy();
            break;
        case VB_SIGNAL_SELL_BREAKOUT:
            ExecuteVolatilityBreakoutSell();
            break;
        case VB_SIGNAL_RANGE_BOUND:
            // 횡보 상태 - 돌파 대기
            if (VB_AlertOnBreakout) {
                Print(g_log_prefix, "⏳ 횡보 상태 - 돌파 대기 중");
            }
            break;
    }
}

//+------------------------------------------------------------------+
//| 변동성 돌파 매수 주문 실행                                         |
//+------------------------------------------------------------------+
void ExecuteVolatilityBreakoutBuy() {
    double ask_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double atr_value = g_volatility_analyzer.GetCurrentATR();
    
    // 동적 포지션 크기 계산
    double lot_size = VB_LotSize;
    if (g_risk_manager != NULL) {
        double stop_loss = ask_price - atr_value * VB_ATRMultEntry;
        lot_size = g_risk_manager.CalculatePositionSize(ask_price, stop_loss, _Symbol);
    }
    
    // 동적 스톱/타겟 설정
    double sl_price = ask_price - atr_value * VB_ATRMultEntry;
    double tp_price = ask_price + atr_value * VB_ATRMultExit;
    
    Print(g_log_prefix, "🟢 상승 돌파 신호 - ATR: ", DoubleToString(atr_value, 5),
          ", 변동성비율: ", DoubleToString(g_volatility_analyzer.GetVolatilityRatio(), 2),
          ", 거래량: ", DoubleToString(lot_size, 2));
    
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
    request.comment = "VolBreakout-BUY";
    
    if (OrderSend(request, result)) {
        g_total_trades++;
        g_current_trades++;
        Print(g_log_prefix, "✅ 상승 돌파 매수 주문 성공 - 티켓: ", result.order,
              ", 가격: ", ask_price, ", SL: ", sl_price, ", TP: ", tp_price);
        
        if (VB_AlertOnTrade) {
            Alert("변동성 돌파 상승 매수 주문 실행");
        }
    } else {
        Print(g_log_prefix, "❌ 상승 돌파 매수 주문 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 변동성 돌파 매도 주문 실행                                         |
//+------------------------------------------------------------------+
void ExecuteVolatilityBreakoutSell() {
    double bid_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double atr_value = g_volatility_analyzer.GetCurrentATR();
    
    // 동적 포지션 크기 계산
    double lot_size = VB_LotSize;
    if (g_risk_manager != NULL) {
        double stop_loss = bid_price + atr_value * VB_ATRMultEntry;
        lot_size = g_risk_manager.CalculatePositionSize(bid_price, stop_loss, _Symbol);
    }
    
    // 동적 스톱/타겟 설정
    double sl_price = bid_price + atr_value * VB_ATRMultEntry;
    double tp_price = bid_price - atr_value * VB_ATRMultExit;
    
    Print(g_log_prefix, "🔴 하락 돌파 신호 - ATR: ", DoubleToString(atr_value, 5),
          ", 변동성비율: ", DoubleToString(g_volatility_analyzer.GetVolatilityRatio(), 2),
          ", 거래량: ", DoubleToString(lot_size, 2));
    
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
    request.comment = "VolBreakout-SELL";
    
    if (OrderSend(request, result)) {
        g_total_trades++;
        g_current_trades++;
        Print(g_log_prefix, "✅ 하락 돌파 매도 주문 성공 - 티켓: ", result.order,
              ", 가격: ", bid_price, ", SL: ", sl_price, ", TP: ", tp_price);
        
        if (VB_AlertOnTrade) {
            Alert("변동성 돌파 하락 매도 주문 실행");
        }
    } else {
        Print(g_log_prefix, "❌ 하락 돌파 매도 주문 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 유틸리티 함수들                                                   |
//+------------------------------------------------------------------+
bool ValidateVolatilityBreakoutInputs() {
    bool is_valid = true;
    
    if (VB_LotSize <= 0) {
        Print(g_log_prefix, "오류: 거래량은 0보다 커야 합니다.");
        is_valid = false;
    }
    
    if (VB_ATRPeriod < 5 || VB_ATRPeriod > 50) {
        Print(g_log_prefix, "오류: ATR 기간은 5-50 사이여야 합니다.");
        is_valid = false;
    }
    
    if (VB_BaseRiskPercent <= 0 || VB_BaseRiskPercent > 10) {
        Print(g_log_prefix, "오류: 기본 리스크는 0-10% 사이여야 합니다.");
        is_valid = false;
    }
    
    return is_valid;
}

VolatilityBreakoutConfig GetVolatilityBreakoutConfigFromInputs() {
    VolatilityBreakoutConfig config;
    
    // ATR 설정
    config.atr_period = VB_ATRPeriod;
    config.atr_multiplier_entry = VB_ATRMultEntry;
    config.atr_multiplier_exit = VB_ATRMultExit;
    
    // 변동성 임계값
    config.low_volatility_threshold = VB_LowVolThreshold;
    config.high_volatility_threshold = VB_HighVolThreshold;
    config.extreme_volatility_threshold = 2.0;
    
    // 돌파 설정
    config.consolidation_period = VB_ConsolidationPeriod;
    config.breakout_threshold = VB_BreakoutThreshold;
    config.confirm_method = BREAKOUT_VOLUME_CONFIRM;
    config.min_breakout_bars = VB_MinBreakoutBars;
    
    // 런던 세션 설정
    config.use_london_session = VB_UseLondonSession;
    config.london_start_hour = VB_LondonStartHour;
    config.london_end_hour = VB_LondonEndHour;
    config.london_breakout_only = VB_LondonBreakoutOnly;
    
    // 필터 설정
    config.use_volume_filter = VB_UseVolumeConfirm;
    config.use_spread_filter = true;
    config.use_time_filter = VB_UseTimeConfirm;
    config.max_spread_points = VB_MaxSpread;
    
    // 청산 설정
    config.use_time_exit = VB_UseTimeExit;
    config.max_holding_hours = VB_MaxHoldingHours;
    config.use_profit_protection = VB_UseProfitProtection;
    config.profit_protection_level = VB_ProfitProtectionLevel;
    
    return config;
}

RiskManagementConfig GetRiskConfigFromInputs() {
    RiskManagementConfig config;
    
    // 기본 리스크 설정
    config.risk_mode = VB_UseVolatilityRisk ? RISK_MODE_VOLATILITY : RISK_MODE_ADAPTIVE;
    config.base_risk_percent = VB_BaseRiskPercent;
    config.max_risk_percent = VB_MaxRiskPercent;
    config.min_risk_percent = VB_MinRiskPercent;
    
    // 포지션 크기 조정
    config.sizing_method = SIZE_VOLATILITY_ADJUSTED;
    config.fixed_lot_size = VB_LotSize;
    config.max_lot_size = VB_LotSize * 3;
    config.min_lot_size = VB_LotSize * 0.5;
    
    // 변동성 기반 설정
    config.atr_period = VB_ATRPeriod;
    config.atr_multiplier = VB_ATRMultEntry;
    config.volatility_threshold_high = VB_HighVolThreshold;
    config.volatility_threshold_low = VB_LowVolThreshold;
    
    // 보호 설정
    config.max_daily_loss_percent = VB_MaxDailyLoss;
    config.max_monthly_loss_percent = VB_MaxMonthlyLoss;
    config.max_consecutive_losses = VB_MaxConsecutiveLosses;
    config.enable_emergency_stop = VB_EnableEmergencyStop;
    
    return config;
}

void ManageExistingPositions() {
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == g_magic_number) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            datetime entry_time = (datetime)PositionGetInteger(POSITION_TIME);
            double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            
            // 변동성 돌파 기반 청산 확인
            if (g_volatility_analyzer.ShouldClosePosition(entry_time, entry_price, type == POSITION_TYPE_BUY)) {
                ClosePosition(ticket);
            }
        }
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
    request.comment = "VolBreakout-CLOSE";
    
    if (OrderSend(request, result)) {
        Print(g_log_prefix, "✅ 포지션 닫기 성공 - 티켓: ", ticket);
        
        double profit = PositionGetDouble(POSITION_PROFIT);
        bool is_win = profit > 0;
        
        if (is_win) {
            g_winning_trades++;
        }
        g_total_profit += profit;
        
        // 동적 리스크 관리자에 거래 결과 업데이트
        if (g_risk_manager != NULL) {
            g_risk_manager.UpdateStatistics(profit, is_win);
        }
        
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

void PrintVolatilityBreakoutSettings() {
    Print(g_log_prefix, "=== 변동성 돌파 + 동적 리스크 관리 설정 ===");
    Print(g_log_prefix, "📊 변동성 돌파 거래 모드");
    Print(g_log_prefix, "거래량: ", VB_LotSize);
    Print(g_log_prefix, "ATR 기간: ", VB_ATRPeriod);
    Print(g_log_prefix, "진입 ATR 배수: ", VB_ATRMultEntry);
    Print(g_log_prefix, "청산 ATR 배수: ", VB_ATRMultExit);
    Print(g_log_prefix, "저변동성 임계값: ", VB_LowVolThreshold);
    Print(g_log_prefix, "고변동성 임계값: ", VB_HighVolThreshold);
    Print(g_log_prefix, "횡보 기간: ", VB_ConsolidationPeriod, " 봉");
    Print(g_log_prefix, "런던 세션: ", (VB_UseLondonSession ? "활성" : "비활성"));
    Print(g_log_prefix, "동적 리스크: ", (VB_UseDynamicRisk ? "활성" : "비활성"));
    
    if (VB_UseDynamicRisk) {
        Print(g_log_prefix, "기본 리스크: ", VB_BaseRiskPercent, "%");
        Print(g_log_prefix, "리스크 범위: ", VB_MinRiskPercent, "% - ", VB_MaxRiskPercent, "%");
    }
    
    Print(g_log_prefix, "===================================");
}

void PrintVolatilityBreakoutPerformanceReport() {
    Print(g_log_prefix, "=== 최종 성과 (변동성 돌파 + 동적 리스크) ===");
    Print(g_log_prefix, "총 거래: ", g_total_trades);
    Print(g_log_prefix, "승리 거래: ", g_winning_trades);
    Print(g_log_prefix, "승률: ", (g_total_trades > 0 ? DoubleToString((double)g_winning_trades / g_total_trades * 100, 2) : "0"), "%");
    Print(g_log_prefix, "총 수익: ", DoubleToString(g_total_profit, 2));
    Print(g_log_prefix, "최대 낙폭: ", DoubleToString(g_max_drawdown, 2), "%");
    
    if (g_risk_manager != NULL) {
        Print(g_log_prefix, "최종 리스크: ", DoubleToString(g_risk_manager.GetCurrentRiskPercent(), 2), "%");
        Print(g_log_prefix, "적응형 배수: ", DoubleToString(g_risk_manager.GetAdaptiveMultiplier(), 2));
        Print(g_log_prefix, "응급정지: ", (g_risk_manager.IsEmergencyStop() ? "활성" : "비활성"));
    }
    
    Print(g_log_prefix, "변동성 상태: ", EnumToString(g_last_vol_state));
    Print(g_log_prefix, "==================================");
}