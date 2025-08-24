//+------------------------------------------------------------------+
//|                                           ScalpingInputs.mqh |
//|                            스캘핑 전용 입력 매개변수 설정           |
//|                                  Scalping Input Parameters     |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Scalping Edition"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 스캘핑 전용 입력 매개변수                                          |
//+------------------------------------------------------------------+

#ifdef __MQL4__
input static string __Scalping_Settings__ = "=== 스캘핑 전용 설정 ===";
#else
input group "스캘핑 전용 설정 (Scalping Settings)"
#endif

// ===== 기본 거래 설정 (보수적) =====
input double    Scalping_LotSize = 0.01;                    // 거래량 (Lot Size)
input int       Scalping_MaxTrades = 2;                     // 최대 동시 거래 수 (Max Simultaneous Trades) [보수적: 2]
input double    Scalping_MaxSpread = 1.5;                   // 최대 허용 스프레드 (Max Spread in Points) [보수적: 1.5]
input bool      Scalping_UseSpreadFilter = true;            // 스프레드 필터 사용 (Use Spread Filter)

// ===== 신호 지표 설정 =====
#ifdef __MQL4__
input static string __Scalping_Indicators__ = "=== 스캘핑 지표 설정 ===";
#else
input group "스캘핑 지표 설정 (Indicator Settings)"
#endif

input bool      Scalping_UsePriceSwings = true;             // Price Swings 사용 (Use Price Swings)
input bool      Scalping_UseATRMATrend = true;              // ATR MA Trend 사용 (Use ATR MA Trend)
input bool      Scalping_RequireBothSignals = true;         // 두 신호 모두 필요 (Require Both Signals) [보수적: true]

// ===== ATR MA Trend 설정 =====
#ifdef __MQL4__
input static string __ATR_MA_Settings__ = "=== ATR MA Trend 설정 ===";
#else
input group "ATR MA Trend 설정"
#endif

input int       ATR_Period = 20;                            // ATR 기간 (ATR Period) [보수적: 20]
input double    ATR_Sensitivity = 1.0;                      // ATR 민감도 (ATR Sensitivity) [보수적: 1.0]
input int       MA_Period = 30;                             // 이동평균 기간 (Moving Average Period) [보수적: 30]
input ENUM_MA_METHOD MA_Method = MODE_EMA;                  // 이동평균 방법 (MA Method)
input ENUM_APPLIED_PRICE MA_AppliedPrice = PRICE_CLOSE;     // 적용 가격 (Applied Price)

// ===== Price Swings 설정 =====
#ifdef __MQL4__
input static string __Price_Swings_Settings__ = "=== Price Swings 설정 ===";
#else
input group "Price Swings 설정"
#endif

input int       Swing_Period = 15;                          // 스윙 계산 기간 (Swing Calculation Period) [보수적: 15]
input double    Swing_Threshold = 0.35;                     // 스윙 임계값 (Swing Threshold) [보수적: 0.35]
input bool      Swing_UseHighLowFilter = true;              // 고점/저점 필터 사용 (Use High/Low Filter)

// ===== 리스크 관리 =====
#ifdef __MQL4__
input static string __Risk_Management__ = "=== 리스크 관리 ===";
#else
input group "리스크 관리 (Risk Management)"
#endif

input double    Scalping_StopLoss = 8.0;                    // 손절매 (Stop Loss in Pips) [보수적: 8]
input double    Scalping_TakeProfit = 12.0;                 // 익절 (Take Profit in Pips) [보수적: 12]
input double    Scalping_TrailingStop = 3.0;                // 트레일링 스톱 (Trailing Stop in Pips) [보수적: 3]
input bool      Scalping_UseTrailingStop = true;            // 트레일링 스톱 사용 (Use Trailing Stop)
input double    Scalping_RiskPercent = 1.5;                 // 계좌 대비 리스크 % (Risk Percent of Account) [보수적: 1.5%]

// ===== 마틴게일 설정 =====
#ifdef __MQL4__
input static string __Martingale_Settings__ = "=== 마틴게일 설정 ===";
#else
input group "마틴게일 설정 (Martingale Settings)"
#endif

input bool      Scalping_UseMartingale = false;            // 마틴게일 사용 (Use Martingale) [보수적: false]
input double    Scalping_MartingaleMultiplier = 2.0;       // 마틴게일 배수 (Martingale Multiplier)
input int       Scalping_MaxMartingaleLevels = 3;          // 최대 마틴게일 단계 (Max Martingale Levels)
input bool      Scalping_UseOscillatorMartingale = false;  // 오실레이터 마틴게일 사용 (Use Oscillator Martingale)

// ===== 시간 필터 =====
#ifdef __MQL4__
input static string __Time_Filter__ = "=== 시간 필터 ===";
#else
input group "시간 필터 (Time Filter)"
#endif

input bool      Scalping_UseTimeFilter = true;              // 시간 필터 사용 (Use Time Filter)
input int       Scalping_StartHour = 9;                     // 거래 시작 시간 (Trading Start Hour) [보수적: 9]
input int       Scalping_EndHour = 17;                      // 거래 종료 시간 (Trading End Hour) [보수적: 17]
input bool      Scalping_AvoidNews = true;                  // 뉴스 시간 회피 (Avoid News Times)
input int       Scalping_NewsBufferMinutes = 30;            // 뉴스 전후 회피 시간 (News Buffer Minutes)

// ===== 고급 설정 =====
#ifdef __MQL4__
input static string __Advanced_Settings__ = "=== 고급 설정 ===";
#else
input group "고급 설정 (Advanced Settings)"
#endif

input bool      Scalping_UseDynamicLots = false;            // 동적 거래량 사용 (Use Dynamic Lot Sizing)
input double    Scalping_MaxDrawdownPercent = 10.0;         // 최대 낙폭 % (Max Drawdown Percent) [보수적: 10%]
input int       Scalping_MinBarsSinceLastTrade = 8;         // 마지막 거래 후 최소 봉 수 (Min Bars Since Last Trade) [보수적: 8]
input bool      Scalping_UseVolatilityFilter = true;        // 변동성 필터 사용 (Use Volatility Filter)
input double    Scalping_MinVolatilityLevel = 0.0002;       // 최소 변동성 레벨 (Min Volatility Level) [보수적: 0.0002]

// ===== 최적화 설정 =====
#ifdef __MQL4__
input static string __Optimization__ = "=== 최적화 설정 ===";
#else
input group "최적화 설정 (Optimization)"
#endif

input bool      Scalping_EnableOptimization = false;        // 실시간 최적화 활성화 (Enable Real-time Optimization)
input int       Scalping_OptimizationPeriod = 100;          // 최적화 주기 (거래 수) (Optimization Period in Trades)
input bool      Scalping_SaveOptimizationResults = true;    // 최적화 결과 저장 (Save Optimization Results)

// ===== 알림 설정 =====
#ifdef __MQL4__
input static string __Notifications__ = "=== 알림 설정 ===";
#else
input group "알림 설정 (Notifications)"
#endif

input bool      Scalping_EnableAlerts = true;               // 알림 활성화 (Enable Alerts)
input bool      Scalping_AlertOnSignal = true;              // 신호 발생 시 알림 (Alert on Signal)
input bool      Scalping_AlertOnTrade = true;               // 거래 실행 시 알림 (Alert on Trade)
input bool      Scalping_SendEmail = false;                 // 이메일 발송 (Send Email)
input bool      Scalping_SendPush = false;                  // 푸시 알림 (Send Push Notification)

// ===== 백테스팅 설정 =====
#ifdef __MQL4__
input static string __Backtesting__ = "=== 백테스팅 설정 ===";
#else
input group "백테스팅 설정 (Backtesting)"
#endif

input bool      Scalping_BacktestMode = false;              // 백테스트 모드 (Backtest Mode)
input datetime  Scalping_BacktestStart = D'2024.01.01';     // 백테스트 시작일 (Backtest Start Date)
input datetime  Scalping_BacktestEnd = D'2024.12.31';       // 백테스트 종료일 (Backtest End Date)
input bool      Scalping_DetailedLogs = false;              // 상세 로그 (Detailed Logs)

//+------------------------------------------------------------------+
//| 스캘핑 설정 검증 함수                                              |
//+------------------------------------------------------------------+
bool ValidateScalpingInputs() {
    bool is_valid = true;
    
    // 기본 검증
    if (Scalping_LotSize <= 0) {
        Print("오류: 거래량은 0보다 커야 합니다.");
        is_valid = false;
    }
    
    if (Scalping_MaxTrades <= 0 || Scalping_MaxTrades > 10) {
        Print("오류: 최대 거래 수는 1-10 사이여야 합니다.");
        is_valid = false;
    }
    
    if (Scalping_MaxSpread <= 0) {
        Print("오류: 최대 스프레드는 0보다 커야 합니다.");
        is_valid = false;
    }
    
    // ATR 설정 검증
    if (ATR_Period < 5 || ATR_Period > 50) {
        Print("오류: ATR 기간은 5-50 사이여야 합니다.");
        is_valid = false;
    }
    
    if (ATR_Sensitivity <= 0 || ATR_Sensitivity > 5.0) {
        Print("오류: ATR 민감도는 0-5.0 사이여야 합니다.");
        is_valid = false;
    }
    
    if (MA_Period < 5 || MA_Period > 100) {
        Print("오류: 이동평균 기간은 5-100 사이여야 합니다.");
        is_valid = false;
    }
    
    // 스윙 설정 검증
    if (Swing_Period < 3 || Swing_Period > 50) {
        Print("오류: 스윙 기간은 3-50 사이여야 합니다.");
        is_valid = false;
    }
    
    if (Swing_Threshold <= 0 || Swing_Threshold >= 1.0) {
        Print("오류: 스윙 임계값은 0-1.0 사이여야 합니다.");
        is_valid = false;
    }
    
    // 리스크 검증
    if (Scalping_StopLoss <= 0 || Scalping_StopLoss > 100) {
        Print("오류: 손절매는 0-100 pips 사이여야 합니다.");
        is_valid = false;
    }
    
    if (Scalping_TakeProfit <= 0 || Scalping_TakeProfit > 200) {
        Print("오류: 익절은 0-200 pips 사이여야 합니다.");
        is_valid = false;
    }
    
    if (Scalping_TakeProfit <= Scalping_StopLoss) {
        Print("경고: 익절이 손절보다 작거나 같습니다. 권장하지 않습니다.");
    }
    
    if (Scalping_RiskPercent <= 0 || Scalping_RiskPercent > 20) {
        Print("오류: 리스크 퍼센트는 0-20% 사이여야 합니다.");
        is_valid = false;
    }
    
    // 시간 필터 검증
    if (Scalping_UseTimeFilter) {
        if (Scalping_StartHour < 0 || Scalping_StartHour > 23) {
            Print("오류: 시작 시간은 0-23 사이여야 합니다.");
            is_valid = false;
        }
        
        if (Scalping_EndHour < 0 || Scalping_EndHour > 23) {
            Print("오류: 종료 시간은 0-23 사이여야 합니다.");
            is_valid = false;
        }
    }
    
    // 신호 설정 검증
    if (!Scalping_UsePriceSwings && !Scalping_UseATRMATrend) {
        Print("오류: 최소 하나의 신호 지표는 활성화되어야 합니다.");
        is_valid = false;
    }
    
    return is_valid;
}

//+------------------------------------------------------------------+
//| 스캘핑 설정을 ScalpingConfig 구조체로 변환                         |
//+------------------------------------------------------------------+
ScalpingConfig InputsToConfig() {
    ScalpingConfig config;
    
    // 기본 설정
    config.lot_size = Scalping_LotSize;
    config.max_trades = Scalping_MaxTrades;
    config.spread_limit = Scalping_MaxSpread;
    
    // 신호 설정
    config.use_price_swings = Scalping_UsePriceSwings;
    config.use_atr_ma_trend = Scalping_UseATRMATrend;
    config.use_spread_filter = Scalping_UseSpreadFilter;
    
    // 리스크 관리
    config.stop_loss_pips = Scalping_StopLoss;
    config.take_profit_pips = Scalping_TakeProfit;
    config.trailing_stop_pips = Scalping_TrailingStop;
    
    // 시간 필터
    config.use_time_filter = Scalping_UseTimeFilter;
    config.start_hour = Scalping_StartHour;
    config.end_hour = Scalping_EndHour;
    
    // ATR MA Trend 설정
    config.atr_period = ATR_Period;
    config.atr_sensitivity = ATR_Sensitivity;
    config.ma_period = MA_Period;
    
    // Price Swings 설정
    config.swing_period = Swing_Period;
    config.swing_threshold = Swing_Threshold;
    
    // 스프레드 설정
    config.max_spread_points = Scalping_MaxSpread;
    config.spread_multiplier_mode = Scalping_UseVolatilityFilter;
    
    // 마틴게일 설정
    config.use_martingale = Scalping_UseMartingale;
    config.martingale_multiplier = Scalping_MartingaleMultiplier;
    config.max_martingale_levels = Scalping_MaxMartingaleLevels;
    config.use_oscillator_martingale = Scalping_UseOscillatorMartingale;
    
    return config;
}

//+------------------------------------------------------------------+
//| 스캘핑 설정 정보 출력                                              |
//+------------------------------------------------------------------+
void PrintScalpingSettings() {
    Print("=== 스캘핑 전략 설정 정보 ===");
    Print("거래량: ", Scalping_LotSize);
    Print("최대 거래 수: ", Scalping_MaxTrades);
    Print("최대 스프레드: ", Scalping_MaxSpread);
    Print("Price Swings 사용: ", (Scalping_UsePriceSwings ? "예" : "아니오"));
    Print("ATR MA Trend 사용: ", (Scalping_UseATRMATrend ? "예" : "아니오"));
    Print("ATR 기간: ", ATR_Period);
    Print("ATR 민감도: ", ATR_Sensitivity);
    Print("이동평균 기간: ", MA_Period);
    Print("스윙 기간: ", Swing_Period);
    Print("스윙 임계값: ", Swing_Threshold);
    Print("손절매: ", Scalping_StopLoss, " pips");
    Print("익절: ", Scalping_TakeProfit, " pips");
    Print("트레일링 스톱: ", Scalping_TrailingStop, " pips");
    Print("시간 필터: ", (Scalping_UseTimeFilter ? "예" : "아니오"));
    if (Scalping_UseTimeFilter) {
        Print("거래 시간: ", Scalping_StartHour, ":00 - ", Scalping_EndHour, ":00");
    }
    Print("리스크 퍼센트: ", Scalping_RiskPercent, "%");
    Print("============================");
}

//+------------------------------------------------------------------+
//| 빠른 설정 프리셋                                                  |
//+------------------------------------------------------------------+

// 보수적 스캘핑 설정 (현재 적용됨)
void ApplyConservativeScalpingPreset() {
    Print("=== 보수적 스캘핑 현재 설정 ===");
    Print("✅ 거래량: 0.01 (안전한 포지션 크기)");
    Print("✅ 최대 거래: 2 (위험 분산)");
    Print("✅ 손절: 8 pips (빠른 손절)");
    Print("✅ 익절: 12 pips (안정적 수익)");
    Print("✅ ATR 민감도: 1.0 (보수적 신호)");
    Print("✅ 스윙 임계값: 0.35 (신중한 진입)");
    Print("✅ 스프레드 한계: 1.5 pips (저비용)");
    Print("✅ 양방향 신호 필수 (이중 확인)");
    Print("✅ 마틴게일 비활성화 (리스크 제한)");
    Print("✅ 거래시간: 09:00-17:00 (안정 시간대)");
    Print("✅ 최대 낙폭: 10% (보수적 한계)");
    Print("================================");
}

// 공격적 스캘핑 설정
void ApplyAggressiveScalpingPreset() {
    Print("=== 공격적 스캘핑 권장 설정 ===");
    Print("거래량: 0.02");
    Print("최대 거래: 5");
    Print("손절: 12 pips");
    Print("익절: 20 pips");
    Print("ATR 민감도: 1.5");
    Print("스윙 임계값: 0.25");
    Print("==========================");
}

// 균형잡힌 스캘핑 설정
void ApplyBalancedScalpingPreset() {
    Print("=== 균형잡힌 스캘핑 권장 설정 ===");
    Print("거래량: 0.01");
    Print("최대 거래: 3");
    Print("손절: 10 pips");
    Print("익절: 15 pips");
    Print("ATR 민감도: 1.2");
    Print("스윙 임계값: 0.30");
    Print("==========================");
}