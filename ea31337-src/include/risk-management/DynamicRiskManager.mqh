//+------------------------------------------------------------------+
//|                                           DynamicRiskManager.mqh |
//|                                  동적 리스크 관리 시스템            |
//|                                     Dynamic Risk Management System |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Dynamic Risk Edition"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 리스크 관리 모드 열거형                                            |
//+------------------------------------------------------------------+
enum ENUM_RISK_MODE {
    RISK_MODE_FIXED = 0,        // 고정 리스크
    RISK_MODE_VOLATILITY,       // 변동성 기반
    RISK_MODE_EQUITY_CURVE,     // 자산 곡선 기반
    RISK_MODE_ADAPTIVE,         // 적응형 리스크
    RISK_MODE_KELLY             // 켈리 공식 기반
};

//+------------------------------------------------------------------+
//| 포지션 크기 조정 방법 열거형                                        |
//+------------------------------------------------------------------+
enum ENUM_POSITION_SIZING {
    SIZE_FIXED_LOT = 0,         // 고정 로트
    SIZE_PERCENT_BALANCE,       // 잔고 비율
    SIZE_PERCENT_EQUITY,        // 자산 비율
    SIZE_ATR_BASED,             // ATR 기반
    SIZE_VOLATILITY_ADJUSTED    // 변동성 조정
};

//+------------------------------------------------------------------+
//| 리스크 관리 설정 구조체                                            |
//+------------------------------------------------------------------+
struct RiskManagementConfig {
    // 기본 리스크 설정
    ENUM_RISK_MODE risk_mode;               // 리스크 관리 모드
    double base_risk_percent;               // 기본 리스크 비율 (%)
    double max_risk_percent;                // 최대 리스크 비율 (%)
    double min_risk_percent;                // 최소 리스크 비율 (%)
    
    // 포지션 크기 조정
    ENUM_POSITION_SIZING sizing_method;     // 포지션 크기 조정 방법
    double fixed_lot_size;                  // 고정 로트 크기
    double max_lot_size;                    // 최대 로트 크기
    double min_lot_size;                    // 최소 로트 크기
    
    // 변동성 기반 설정
    int atr_period;                         // ATR 기간
    double atr_multiplier;                  // ATR 배수
    double volatility_threshold_high;       // 고변동성 임계값
    double volatility_threshold_low;        // 저변동성 임계값
    
    // 자산 곡선 기반 설정
    int equity_lookback_period;             // 자산 곡선 분석 기간
    double drawdown_reduction_factor;       // 낙폭 시 리스크 감소 계수
    double profit_scaling_factor;           // 수익 시 리스크 증가 계수
    
    // 켈리 공식 설정
    bool use_kelly_criterion;               // 켈리 공식 사용
    int kelly_lookback_trades;              // 켈리 계산용 거래 수
    double kelly_max_fraction;              // 켈리 최대 비율
    
    // 보호 설정
    double max_daily_loss_percent;          // 일일 최대 손실 %
    double max_monthly_loss_percent;        // 월별 최대 손실 %
    int max_consecutive_losses;             // 최대 연속 손실 수
    bool enable_emergency_stop;             // 응급 정지 활성화
};

//+------------------------------------------------------------------+
//| 거래 통계 구조체                                                  |
//+------------------------------------------------------------------+
struct TradingStatistics {
    int total_trades;           // 총 거래 수
    int winning_trades;         // 승리 거래 수
    int losing_trades;          // 손실 거래 수
    double total_profit;        // 총 수익
    double total_loss;          // 총 손실
    double largest_win;         // 최대 수익
    double largest_loss;        // 최대 손실
    double avg_win;             // 평균 수익
    double avg_loss;            // 평균 손실
    double win_rate;            // 승률
    double profit_factor;       // 수익 팩터
    double expectancy;          // 기댓값
    int consecutive_wins;       // 연속 승리
    int consecutive_losses;     // 연속 손실
    double max_drawdown;        // 최대 낙폭
    double current_drawdown;    // 현재 낙폭
    datetime last_trade_time;   // 마지막 거래 시간
};

//+------------------------------------------------------------------+
//| 동적 리스크 관리자 클래스                                          |
//+------------------------------------------------------------------+
class DynamicRiskManager {
private:
    RiskManagementConfig config;
    TradingStatistics stats;
    double equity_history[];
    double balance_history[];
    double daily_pnl[];
    datetime last_update_time;
    double current_risk_percent;
    double adaptive_multiplier;
    bool emergency_stop_triggered;
    
    // 내부 계산 변수
    double last_atr_value;
    double volatility_ratio;
    double equity_momentum;
    
public:
    // 생성자
    DynamicRiskManager(RiskManagementConfig &_config) {
        config = _config;
        current_risk_percent = config.base_risk_percent;
        adaptive_multiplier = 1.0;
        emergency_stop_triggered = false;
        last_update_time = 0;
        
        // 히스토리 배열 초기화
        ArrayResize(equity_history, config.equity_lookback_period);
        ArrayResize(balance_history, config.equity_lookback_period);
        ArrayResize(daily_pnl, 30); // 30일 PnL 추적
        
        // 통계 초기화
        ResetStatistics();
    }
    
    // 핵심 메서드들
    double CalculatePositionSize(double entry_price, double stop_loss, string symbol = "");
    double CalculateDynamicRisk();
    void UpdateRiskBasedOnPerformance();
    void UpdateStatistics(double profit_loss, bool is_win);
    bool IsTradeAllowed();
    void OnNewDay();
    void OnNewMonth();
    
    // 변동성 분석
    double CalculateVolatilityRatio(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT);
    double GetATRValue(string symbol = "", int period = 14, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT);
    
    // 자산 곡선 분석
    void UpdateEquityHistory();
    double CalculateEquityMomentum();
    double CalculateCurrentDrawdown();
    
    // 켈리 공식 계산
    double CalculateKellyFraction();
    
    // 보호 메커니즘
    bool CheckDailyLossLimit();
    bool CheckMonthlyLossLimit();
    bool CheckConsecutiveLossLimit();
    void TriggerEmergencyStop(string reason);
    
    // 상태 조회
    double GetCurrentRiskPercent() { return current_risk_percent; }
    double GetAdaptiveMultiplier() { return adaptive_multiplier; }
    TradingStatistics GetStatistics() { return stats; }
    bool IsEmergencyStop() { return emergency_stop_triggered; }
    
    // 설정 업데이트
    void UpdateConfig(RiskManagementConfig &new_config) { config = new_config; }
    void ResetEmergencyStop() { emergency_stop_triggered = false; }
    void ResetStatistics();
    
    // 정보 출력
    string GetRiskStatusInfo();
    string GetStatisticsInfo();
    
private:
    // 내부 유틸리티 함수들
    double NormalizeLotSize(double lot_size, string symbol = "");
    double CalculateRiskAdjustment();
    void UpdateDailyPnL();
    double GetAccountRisk();
};

//+------------------------------------------------------------------+
//| 포지션 크기 계산                                                  |
//+------------------------------------------------------------------+
double DynamicRiskManager::CalculatePositionSize(double entry_price, double stop_loss, string symbol = "") {
    if (symbol == "") symbol = _Symbol;
    
    // 거래 허용 여부 확인
    if (!IsTradeAllowed()) {
        return 0.0;
    }
    
    // 현재 동적 리스크 계산
    double risk_percent = CalculateDynamicRisk();
    
    // 계좌 정보
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double risk_amount = 0;
    
    // 리스크 금액 계산
    switch (config.sizing_method) {
        case SIZE_PERCENT_BALANCE:
            risk_amount = account_balance * risk_percent / 100.0;
            break;
        case SIZE_PERCENT_EQUITY:
            risk_amount = account_equity * risk_percent / 100.0;
            break;
        case SIZE_FIXED_LOT:
            return NormalizeLotSize(config.fixed_lot_size, symbol);
        default:
            risk_amount = account_equity * risk_percent / 100.0;
            break;
    }
    
    // 스톱로스 거리 계산
    double stop_distance = MathAbs(entry_price - stop_loss);
    if (stop_distance <= 0) {
        return NormalizeLotSize(config.min_lot_size, symbol);
    }
    
    // 포인트 값과 틱 크기
    double point_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tick_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double point_size = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // 로트 크기 계산
    double lot_size = risk_amount / (stop_distance / point_size * point_value);
    
    // ATR 기반 조정
    if (config.sizing_method == SIZE_ATR_BASED || config.sizing_method == SIZE_VOLATILITY_ADJUSTED) {
        double atr_value = GetATRValue(symbol, config.atr_period);
        double volatility_adjustment = 1.0;
        
        if (atr_value > 0) {
            volatility_adjustment = (stop_distance / atr_value) / config.atr_multiplier;
            volatility_adjustment = MathMax(0.5, MathMin(2.0, volatility_adjustment));
        }
        
        lot_size *= volatility_adjustment;
    }
    
    // 적응형 배수 적용
    lot_size *= adaptive_multiplier;
    
    return NormalizeLotSize(lot_size, symbol);
}

//+------------------------------------------------------------------+
//| 동적 리스크 계산                                                  |
//+------------------------------------------------------------------+
double DynamicRiskManager::CalculateDynamicRisk() {
    double base_risk = config.base_risk_percent;
    double final_risk = base_risk;
    
    switch (config.risk_mode) {
        case RISK_MODE_FIXED:
            final_risk = base_risk;
            break;
            
        case RISK_MODE_VOLATILITY:
            {
                double vol_ratio = CalculateVolatilityRatio();
                if (vol_ratio > config.volatility_threshold_high) {
                    // 고변동성: 리스크 감소
                    final_risk = base_risk * 0.7;
                } else if (vol_ratio < config.volatility_threshold_low) {
                    // 저변동성: 리스크 증가
                    final_risk = base_risk * 1.3;
                } else {
                    final_risk = base_risk;
                }
            }
            break;
            
        case RISK_MODE_EQUITY_CURVE:
            {
                UpdateEquityHistory();
                double equity_momentum = CalculateEquityMomentum();
                double current_dd = CalculateCurrentDrawdown();
                
                // 낙폭 시 리스크 감소
                if (current_dd > 5.0) {
                    final_risk = base_risk * (1.0 - current_dd / 100.0 * config.drawdown_reduction_factor);
                }
                // 상승 모멘텀 시 리스크 증가
                else if (equity_momentum > 0) {
                    final_risk = base_risk * (1.0 + equity_momentum * config.profit_scaling_factor);
                }
            }
            break;
            
        case RISK_MODE_ADAPTIVE:
            {
                // 성과 기반 적응형 조정
                if (stats.win_rate > 0.6 && stats.profit_factor > 1.5) {
                    final_risk = base_risk * 1.2; // 성과 좋을 때 증가
                } else if (stats.win_rate < 0.4 || stats.consecutive_losses >= 3) {
                    final_risk = base_risk * 0.6; // 성과 나쁠 때 감소
                }
                
                // 변동성 조정 추가
                double vol_adjustment = CalculateVolatilityRatio();
                final_risk *= (2.0 - vol_adjustment); // 변동성 역비례
            }
            break;
            
        case RISK_MODE_KELLY:
            if (config.use_kelly_criterion && stats.total_trades >= config.kelly_lookback_trades) {
                double kelly_fraction = CalculateKellyFraction();
                final_risk = MathMin(kelly_fraction * 100, config.kelly_max_fraction * 100);
            }
            break;
    }
    
    // 최대/최소 리스크 제한
    final_risk = MathMax(config.min_risk_percent, MathMin(config.max_risk_percent, final_risk));
    
    current_risk_percent = final_risk;
    return final_risk;
}

//+------------------------------------------------------------------+
//| 변동성 비율 계산                                                  |
//+------------------------------------------------------------------+
double DynamicRiskManager::CalculateVolatilityRatio(string symbol = "", ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
    if (symbol == "") symbol = _Symbol;
    
    double current_atr = GetATRValue(symbol, config.atr_period, timeframe);
    double long_atr = GetATRValue(symbol, config.atr_period * 3, timeframe);
    
    if (long_atr > 0) {
        volatility_ratio = current_atr / long_atr;
    } else {
        volatility_ratio = 1.0;
    }
    
    last_atr_value = current_atr;
    return volatility_ratio;
}

//+------------------------------------------------------------------+
//| ATR 값 계산                                                      |
//+------------------------------------------------------------------+
double DynamicRiskManager::GetATRValue(string symbol = "", int period = 14, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT) {
    if (symbol == "") symbol = _Symbol;
    
#ifdef __MQL4__
    return iATR(symbol, timeframe, period, 0);
#else
    int handle = iATR(symbol, timeframe, period);
    if (handle == INVALID_HANDLE) return 0.0;
    
    double atr_buffer[];
    ArraySetAsSeries(atr_buffer, true);
    
    if (CopyBuffer(handle, 0, 0, 1, atr_buffer) <= 0) return 0.0;
    
    return atr_buffer[0];
#endif
}

//+------------------------------------------------------------------+
//| 자산 히스토리 업데이트                                             |
//+------------------------------------------------------------------+
void DynamicRiskManager::UpdateEquityHistory() {
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // 배열 이동 (FIFO)
    for (int i = ArraySize(equity_history) - 1; i > 0; i--) {
        equity_history[i] = equity_history[i-1];
        balance_history[i] = balance_history[i-1];
    }
    
    equity_history[0] = current_equity;
    balance_history[0] = current_balance;
}

//+------------------------------------------------------------------+
//| 자산 모멘텀 계산                                                  |
//+------------------------------------------------------------------+
double DynamicRiskManager::CalculateEquityMomentum() {
    if (ArraySize(equity_history) < 10) return 0.0;
    
    double recent_avg = 0, old_avg = 0;
    int half_period = config.equity_lookback_period / 2;
    
    // 최근 절반 평균
    for (int i = 0; i < half_period; i++) {
        recent_avg += equity_history[i];
    }
    recent_avg /= half_period;
    
    // 과거 절반 평균
    for (int i = half_period; i < config.equity_lookback_period; i++) {
        old_avg += equity_history[i];
    }
    old_avg /= half_period;
    
    if (old_avg > 0) {
        equity_momentum = (recent_avg - old_avg) / old_avg;
    } else {
        equity_momentum = 0.0;
    }
    
    return equity_momentum;
}

//+------------------------------------------------------------------+
//| 켈리 공식 계산                                                    |
//+------------------------------------------------------------------+
double DynamicRiskManager::CalculateKellyFraction() {
    if (stats.total_trades < config.kelly_lookback_trades) return 0.0;
    
    double win_rate = stats.win_rate / 100.0;
    double avg_win_ratio = (stats.avg_win > 0) ? stats.avg_win / MathAbs(stats.avg_loss) : 0.0;
    
    if (avg_win_ratio <= 0) return 0.0;
    
    // 켈리 공식: f = (bp - q) / b
    // b = 평균수익/평균손실 비율, p = 승률, q = 패율
    double kelly_fraction = (avg_win_ratio * win_rate - (1.0 - win_rate)) / avg_win_ratio;
    
    // 음수이면 0으로, 최대값 제한
    kelly_fraction = MathMax(0.0, MathMin(kelly_fraction, config.kelly_max_fraction));
    
    return kelly_fraction;
}

//+------------------------------------------------------------------+
//| 거래 허용 여부 확인                                               |
//+------------------------------------------------------------------+
bool DynamicRiskManager::IsTradeAllowed() {
    if (emergency_stop_triggered) return false;
    if (!CheckDailyLossLimit()) return false;
    if (!CheckMonthlyLossLimit()) return false;
    if (!CheckConsecutiveLossLimit()) return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| 일일 손실 한도 확인                                               |
//+------------------------------------------------------------------+
bool DynamicRiskManager::CheckDailyLossLimit() {
    UpdateDailyPnL();
    
    double today_pnl = daily_pnl[0];
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double daily_loss_limit = account_balance * config.max_daily_loss_percent / 100.0;
    
    if (today_pnl < -daily_loss_limit) {
        TriggerEmergencyStop("일일 손실 한도 초과");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 통계 업데이트                                                    |
//+------------------------------------------------------------------+
void DynamicRiskManager::UpdateStatistics(double profit_loss, bool is_win) {
    stats.total_trades++;
    stats.last_trade_time = TimeCurrent();
    
    if (is_win) {
        stats.winning_trades++;
        stats.total_profit += profit_loss;
        stats.consecutive_wins++;
        stats.consecutive_losses = 0;
        
        if (profit_loss > stats.largest_win) {
            stats.largest_win = profit_loss;
        }
    } else {
        stats.losing_trades++;
        stats.total_loss += MathAbs(profit_loss);
        stats.consecutive_losses++;
        stats.consecutive_wins = 0;
        
        if (MathAbs(profit_loss) > stats.largest_loss) {
            stats.largest_loss = MathAbs(profit_loss);
        }
    }
    
    // 계산된 통계 업데이트
    if (stats.total_trades > 0) {
        stats.win_rate = (double)stats.winning_trades / stats.total_trades * 100.0;
    }
    
    if (stats.winning_trades > 0) {
        stats.avg_win = stats.total_profit / stats.winning_trades;
    }
    
    if (stats.losing_trades > 0) {
        stats.avg_loss = stats.total_loss / stats.losing_trades;
    }
    
    if (stats.total_loss > 0) {
        stats.profit_factor = stats.total_profit / stats.total_loss;
        stats.expectancy = (stats.avg_win * stats.win_rate / 100.0) - (stats.avg_loss * (100.0 - stats.win_rate) / 100.0);
    }
    
    // 성과 기반 적응형 조정 업데이트
    UpdateRiskBasedOnPerformance();
}

//+------------------------------------------------------------------+
//| 성과 기반 리스크 조정                                             |
//+------------------------------------------------------------------+
void DynamicRiskManager::UpdateRiskBasedOnPerformance() {
    // 최근 성과에 따른 적응형 배수 조정
    if (stats.total_trades >= 10) {
        if (stats.win_rate > 60 && stats.profit_factor > 1.5) {
            // 좋은 성과: 점진적 증가
            adaptive_multiplier = MathMin(1.5, adaptive_multiplier + 0.1);
        } else if (stats.win_rate < 40 || stats.consecutive_losses >= 3) {
            // 나쁜 성과: 점진적 감소
            adaptive_multiplier = MathMax(0.5, adaptive_multiplier - 0.1);
        } else {
            // 기본값으로 수렴
            adaptive_multiplier += (1.0 - adaptive_multiplier) * 0.1;
        }
    }
}

//+------------------------------------------------------------------+
//| 로트 크기 정규화                                                  |
//+------------------------------------------------------------------+
double DynamicRiskManager::NormalizeLotSize(double lot_size, string symbol = "") {
    if (symbol == "") symbol = _Symbol;
    
    double min_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    // 설정된 최대/최소값 적용
    lot_size = MathMax(config.min_lot_size, MathMin(config.max_lot_size, lot_size));
    
    // 브로커 제한 적용
    lot_size = MathMax(min_lot, MathMin(max_lot, lot_size));
    
    // 로트 스텝에 맞게 조정
    lot_size = MathRound(lot_size / lot_step) * lot_step;
    
    return lot_size;
}

//+------------------------------------------------------------------+
//| 응급 정지 트리거                                                  |
//+------------------------------------------------------------------+
void DynamicRiskManager::TriggerEmergencyStop(string reason) {
    if (config.enable_emergency_stop) {
        emergency_stop_triggered = true;
        Print("🚨 [DynamicRiskManager] 응급 정지 활성화: ", reason);
        Alert("거래 응급 정지: " + reason);
    }
}

//+------------------------------------------------------------------+
//| 통계 초기화                                                      |
//+------------------------------------------------------------------+
void DynamicRiskManager::ResetStatistics() {
    ZeroMemory(stats);
    stats.largest_loss = 0;
    stats.largest_win = 0;
    adaptive_multiplier = 1.0;
}

//+------------------------------------------------------------------+
//| 일일 PnL 업데이트                                                |
//+------------------------------------------------------------------+
void DynamicRiskManager::UpdateDailyPnL() {
    static datetime last_day = 0;
    datetime current_day = TimeTradeServer() / 86400 * 86400; // 일 단위로 정규화
    
    if (current_day != last_day) {
        // 새로운 날: 배열 이동
        for (int i = ArraySize(daily_pnl) - 1; i > 0; i--) {
            daily_pnl[i] = daily_pnl[i-1];
        }
        daily_pnl[0] = 0; // 새로운 날 PnL 초기화
        last_day = current_day;
    }
    
    // 오늘의 PnL 계산 (간소화)
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double starting_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    daily_pnl[0] = current_equity - starting_balance;
}

//+------------------------------------------------------------------+
//| 리스크 상태 정보 반환                                             |
//+------------------------------------------------------------------+
string DynamicRiskManager::GetRiskStatusInfo() {
    string info = "";
    info += "=== 동적 리스크 관리 상태 ===\n";
    info += "리스크 모드: " + EnumToString(config.risk_mode) + "\n";
    info += "현재 리스크: " + DoubleToString(current_risk_percent, 2) + "%\n";
    info += "적응형 배수: " + DoubleToString(adaptive_multiplier, 2) + "\n";
    info += "변동성 비율: " + DoubleToString(volatility_ratio, 2) + "\n";
    info += "응급 정지: " + (emergency_stop_triggered ? "활성" : "비활성") + "\n";
    info += "ATR 값: " + DoubleToString(last_atr_value, 5) + "\n";
    
    return info;
}

//+------------------------------------------------------------------+
//| 기본 리스크 관리 설정 반환                                         |
//+------------------------------------------------------------------+
RiskManagementConfig GetDefaultRiskConfig() {
    RiskManagementConfig config;
    
    // 기본 리스크 설정
    config.risk_mode = RISK_MODE_ADAPTIVE;
    config.base_risk_percent = 2.0;
    config.max_risk_percent = 5.0;
    config.min_risk_percent = 0.5;
    
    // 포지션 크기 조정
    config.sizing_method = SIZE_PERCENT_EQUITY;
    config.fixed_lot_size = 0.01;
    config.max_lot_size = 1.0;
    config.min_lot_size = 0.01;
    
    // 변동성 기반 설정
    config.atr_period = 14;
    config.atr_multiplier = 2.0;
    config.volatility_threshold_high = 1.5;
    config.volatility_threshold_low = 0.7;
    
    // 자산 곡선 기반 설정
    config.equity_lookback_period = 20;
    config.drawdown_reduction_factor = 0.5;
    config.profit_scaling_factor = 0.3;
    
    // 켈리 공식 설정
    config.use_kelly_criterion = false;
    config.kelly_lookback_trades = 30;
    config.kelly_max_fraction = 0.25;
    
    // 보호 설정
    config.max_daily_loss_percent = 3.0;
    config.max_monthly_loss_percent = 10.0;
    config.max_consecutive_losses = 5;
    config.enable_emergency_stop = true;
    
    return config;
}