//+------------------------------------------------------------------+
//|                                    VolatilityBreakoutAnalyzer.mqh |
//|                                     변동성 돌파 분석기              |
//|                                  Volatility Breakout Analyzer     |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Volatility Edition"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 변동성 돌파 신호 열거형                                            |
//+------------------------------------------------------------------+
enum ENUM_VOLATILITY_BREAKOUT_SIGNAL {
    VB_SIGNAL_NONE = 0,             // 신호 없음
    VB_SIGNAL_BUY_BREAKOUT,         // 상승 돌파 매수
    VB_SIGNAL_SELL_BREAKOUT,        // 하락 돌파 매도
    VB_SIGNAL_RANGE_BOUND,          // 레인지 상태
    VB_SIGNAL_VOLATILITY_EXPANSION, // 변동성 확장
    VB_SIGNAL_VOLATILITY_CONTRACTION // 변동성 수축
};

//+------------------------------------------------------------------+
//| 변동성 상태 열거형                                                |
//+------------------------------------------------------------------+
enum ENUM_VOLATILITY_STATE {
    VOL_STATE_LOW = 0,      // 저변동성
    VOL_STATE_NORMAL,       // 정상변동성
    VOL_STATE_HIGH,         // 고변동성
    VOL_STATE_EXTREME       // 극한변동성
};

//+------------------------------------------------------------------+
//| 돌파 확인 방법 열거형                                             |
//+------------------------------------------------------------------+
enum ENUM_BREAKOUT_CONFIRMATION {
    BREAKOUT_PRICE_ONLY = 0,    // 가격만
    BREAKOUT_VOLUME_CONFIRM,    // 볼륨 확인
    BREAKOUT_TIME_CONFIRM,      // 시간 확인
    BREAKOUT_FULL_CONFIRM       // 완전 확인
};

//+------------------------------------------------------------------+
//| 변동성 돌파 설정 구조체                                            |
//+------------------------------------------------------------------+
struct VolatilityBreakoutConfig {
    // ATR 설정
    int atr_period;                     // ATR 기간
    double atr_multiplier_entry;        // 진입용 ATR 배수
    double atr_multiplier_exit;         // 청산용 ATR 배수
    
    // 변동성 임계값
    double low_volatility_threshold;    // 저변동성 임계값
    double high_volatility_threshold;   // 고변동성 임계값
    double extreme_volatility_threshold; // 극한변동성 임계값
    
    // 돌파 설정
    int consolidation_period;           // 횡보 기간
    double breakout_threshold;          // 돌파 임계값 (ATR 배수)
    ENUM_BREAKOUT_CONFIRMATION confirm_method; // 확인 방법
    int min_breakout_bars;              // 최소 돌파 지속 봉 수
    
    // 런던 세션 설정
    bool use_london_session;            // 런던 세션 사용
    int london_start_hour;              // 런던 시작 시간 (GMT)
    int london_end_hour;                // 런던 종료 시간 (GMT)
    bool london_breakout_only;          // 런던 세션만 거래
    
    // 필터 설정
    bool use_volume_filter;             // 볼륨 필터 사용
    bool use_spread_filter;             // 스프레드 필터 사용
    bool use_time_filter;               // 시간 필터 사용
    double max_spread_points;           // 최대 스프레드
    
    // 청산 설정
    bool use_time_exit;                 // 시간 청산 사용
    int max_holding_hours;              // 최대 보유 시간
    bool use_profit_protection;         // 수익 보호 사용
    double profit_protection_level;     // 수익 보호 레벨
};

//+------------------------------------------------------------------+
//| 변동성 돌파 분석기 클래스                                          |
//+------------------------------------------------------------------+
class VolatilityBreakoutAnalyzer {
private:
    VolatilityBreakoutConfig config;
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    
    // 분석 데이터
    double current_atr;
    double avg_atr;
    double volatility_ratio;
    ENUM_VOLATILITY_STATE volatility_state;
    
    // 돌파 감지 데이터
    double range_high;
    double range_low;
    datetime range_start_time;
    datetime last_breakout_time;
    bool in_consolidation;
    int consolidation_bars;
    
    // 런던 세션 데이터
    datetime london_session_start;
    datetime london_session_end;
    bool is_london_session;
    
public:
    // 생성자
    VolatilityBreakoutAnalyzer(VolatilityBreakoutConfig &_config, string _symbol = "", ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
        config = _config;
        symbol = (_symbol == "") ? _Symbol : _symbol;
        timeframe = _tf;
        
        // 초기화
        current_atr = 0;
        avg_atr = 0;
        volatility_ratio = 1.0;
        volatility_state = VOL_STATE_NORMAL;
        
        range_high = 0;
        range_low = 0;
        range_start_time = 0;
        last_breakout_time = 0;
        in_consolidation = false;
        consolidation_bars = 0;
        
        is_london_session = false;
    }
    
    // 핵심 분석 메서드
    void AnalyzeVolatilityAndRange();
    ENUM_VOLATILITY_BREAKOUT_SIGNAL GetBreakoutSignal();
    ENUM_VOLATILITY_STATE GetVolatilityState();
    
    // 변동성 분석
    void UpdateVolatilityMetrics();
    double CalculateVolatilityRatio();
    bool IsLowVolatility();
    bool IsHighVolatility();
    
    // 돌파 분석
    void UpdateConsolidationRange();
    bool DetectBreakout(double &breakout_level, bool &is_upward);
    bool ConfirmBreakout(bool is_upward, double breakout_level);
    double CalculateBreakoutTarget(bool is_upward, double entry_price);
    
    // 런던 세션 분석
    void UpdateLondonSession();
    bool IsLondonSessionActive();
    bool IsLondonBreakoutTime();
    
    // 필터 확인
    bool IsVolumeConfirmed();
    bool IsSpreadAcceptable();
    bool IsTimeFilterOK();
    
    // 청산 신호
    bool ShouldClosePosition(datetime entry_time, double entry_price, bool is_buy);
    bool IsTimeExit(datetime entry_time);
    bool IsProfitProtectionTriggered(double entry_price, bool is_buy);
    
    // 유틸리티
    double GetATR(int period = 0);
    double GetCurrentRange();
    double GetAverageRange(int bars = 20);
    
    // 상태 조회
    double GetCurrentATR() { return current_atr; }
    double GetVolatilityRatio() { return volatility_ratio; }
    double GetRangeHigh() { return range_high; }
    double GetRangeLow() { return range_low; }
    bool IsInConsolidation() { return in_consolidation; }
    
    // 설정 업데이트
    void UpdateConfig(VolatilityBreakoutConfig &new_config) { config = new_config; }
    
    // 정보 출력
    string GetAnalysisInfo();
};

//+------------------------------------------------------------------+
//| 변동성 및 레인지 분석                                             |
//+------------------------------------------------------------------+
void VolatilityBreakoutAnalyzer::AnalyzeVolatilityAndRange() {
    // 변동성 메트릭 업데이트
    UpdateVolatilityMetrics();
    
    // 횡보 레인지 업데이트
    UpdateConsolidationRange();
    
    // 런던 세션 업데이트
    if (config.use_london_session) {
        UpdateLondonSession();
    }
}

//+------------------------------------------------------------------+
//| 변동성 메트릭 업데이트                                             |
//+------------------------------------------------------------------+
void VolatilityBreakoutAnalyzer::UpdateVolatilityMetrics() {
    // 현재 ATR 계산
    current_atr = GetATR(config.atr_period);
    
    // 장기 평균 ATR 계산 (3배 기간)
    avg_atr = GetATR(config.atr_period * 3);
    
    // 변동성 비율 계산
    if (avg_atr > 0) {
        volatility_ratio = current_atr / avg_atr;
    } else {
        volatility_ratio = 1.0;
    }
    
    // 변동성 상태 결정
    if (volatility_ratio <= config.low_volatility_threshold) {
        volatility_state = VOL_STATE_LOW;
    } else if (volatility_ratio <= config.high_volatility_threshold) {
        volatility_state = VOL_STATE_NORMAL;
    } else if (volatility_ratio <= config.extreme_volatility_threshold) {
        volatility_state = VOL_STATE_HIGH;
    } else {
        volatility_state = VOL_STATE_EXTREME;
    }
}

//+------------------------------------------------------------------+
//| 횡보 레인지 업데이트                                               |
//+------------------------------------------------------------------+
void VolatilityBreakoutAnalyzer::UpdateConsolidationRange() {
    double current_high = iHigh(symbol, timeframe, 0);
    double current_low = iLow(symbol, timeframe, 0);
    
    // 저변동성 상태에서 횡보 감지
    if (volatility_state == VOL_STATE_LOW) {
        if (!in_consolidation) {
            // 새로운 횡보 시작
            in_consolidation = true;
            range_high = current_high;
            range_low = current_low;
            range_start_time = iTime(symbol, timeframe, 0);
            consolidation_bars = 1;
        } else {
            // 기존 횡보 확장
            if (current_high > range_high) {
                range_high = current_high;
            }
            if (current_low < range_low) {
                range_low = current_low;
            }
            consolidation_bars++;
        }
    } else {
        // 고변동성 상태에서 횡보 종료
        if (in_consolidation && consolidation_bars >= config.consolidation_period) {
            // 횡보 완료, 돌파 대기 상태
        } else {
            in_consolidation = false;
            consolidation_bars = 0;
        }
    }
}

//+------------------------------------------------------------------+
//| 돌파 신호 분석                                                    |
//+------------------------------------------------------------------+
ENUM_VOLATILITY_BREAKOUT_SIGNAL VolatilityBreakoutAnalyzer::GetBreakoutSignal() {
    // 기본 필터 확인
    if (!IsSpreadAcceptable()) return VB_SIGNAL_NONE;
    if (!IsTimeFilterOK()) return VB_SIGNAL_NONE;
    
    // 런던 세션 필터
    if (config.london_breakout_only && !IsLondonBreakoutTime()) {
        return VB_SIGNAL_NONE;
    }
    
    // 변동성 상태별 신호
    switch (volatility_state) {
        case VOL_STATE_LOW:
            if (in_consolidation && consolidation_bars >= config.consolidation_period) {
                return VB_SIGNAL_RANGE_BOUND; // 돌파 대기
            }
            break;
            
        case VOL_STATE_NORMAL:
        case VOL_STATE_HIGH:
            // 돌파 감지
            double breakout_level;
            bool is_upward;
            
            if (DetectBreakout(breakout_level, is_upward)) {
                if (ConfirmBreakout(is_upward, breakout_level)) {
                    return is_upward ? VB_SIGNAL_BUY_BREAKOUT : VB_SIGNAL_SELL_BREAKOUT;
                }
            }
            break;
            
        case VOL_STATE_EXTREME:
            // 극한 변동성에서는 신중하게
            return VB_SIGNAL_NONE;
    }
    
    return VB_SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| 돌파 감지                                                        |
//+------------------------------------------------------------------+
bool VolatilityBreakoutAnalyzer::DetectBreakout(double &breakout_level, bool &is_upward) {
    if (!in_consolidation || range_high == 0 || range_low == 0) {
        return false;
    }
    
    double current_price = iClose(symbol, timeframe, 0);
    double atr_buffer = current_atr * config.breakout_threshold;
    
    // 상승 돌파 확인
    if (current_price > range_high + atr_buffer) {
        breakout_level = range_high;
        is_upward = true;
        return true;
    }
    
    // 하락 돌파 확인
    if (current_price < range_low - atr_buffer) {
        breakout_level = range_low;
        is_upward = false;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| 돌파 확인                                                        |
//+------------------------------------------------------------------+
bool VolatilityBreakoutAnalyzer::ConfirmBreakout(bool is_upward, double breakout_level) {
    switch (config.confirm_method) {
        case BREAKOUT_PRICE_ONLY:
            return true; // 가격 돌파만으로 충분
            
        case BREAKOUT_VOLUME_CONFIRM:
            return IsVolumeConfirmed();
            
        case BREAKOUT_TIME_CONFIRM:
            {
                // 최소 지속 시간 확인
                datetime current_time = iTime(symbol, timeframe, 0);
                return (current_time - last_breakout_time) > config.min_breakout_bars * PeriodSeconds(timeframe);
            }
            
        case BREAKOUT_FULL_CONFIRM:
            return IsVolumeConfirmed() && IsLondonSessionActive();
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 런던 세션 업데이트                                                |
//+------------------------------------------------------------------+
void VolatilityBreakoutAnalyzer::UpdateLondonSession() {
    datetime current_time = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current_time, dt);
    
    // GMT 기준 런던 세션 시간 계산
    int current_hour_gmt = dt.hour; // 실제로는 브로커 시간대 변환 필요
    
    is_london_session = (current_hour_gmt >= config.london_start_hour && 
                        current_hour_gmt < config.london_end_hour);
}

//+------------------------------------------------------------------+
//| 런던 돌파 시간 확인                                               |
//+------------------------------------------------------------------+
bool VolatilityBreakoutAnalyzer::IsLondonBreakoutTime() {
    if (!config.use_london_session) return true;
    
    datetime current_time = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current_time, dt);
    
    // 런던 개장 직후 1시간 (GMT 7:00-8:00)
    int current_hour_gmt = dt.hour;
    return (current_hour_gmt == config.london_start_hour);
}

//+------------------------------------------------------------------+
//| 볼륨 확인                                                        |
//+------------------------------------------------------------------+
bool VolatilityBreakoutAnalyzer::IsVolumeConfirmed() {
    if (!config.use_volume_filter) return true;
    
    // 현재 틱 볼륨
    long current_volume = iVolume(symbol, timeframe, 0);
    
    // 평균 볼륨 계산 (최근 20개 봉)
    long total_volume = 0;
    for (int i = 1; i <= 20; i++) {
        total_volume += iVolume(symbol, timeframe, i);
    }
    long avg_volume = total_volume / 20;
    
    // 현재 볼륨이 평균의 150% 이상이면 확인
    return current_volume > avg_volume * 1.5;
}

//+------------------------------------------------------------------+
//| 스프레드 확인                                                    |
//+------------------------------------------------------------------+
bool VolatilityBreakoutAnalyzer::IsSpreadAcceptable() {
    if (!config.use_spread_filter) return true;
    
    double current_spread = MarketInfo(symbol, MODE_SPREAD) * MarketInfo(symbol, MODE_POINT);
    return current_spread <= config.max_spread_points * MarketInfo(symbol, MODE_POINT);
}

//+------------------------------------------------------------------+
//| 시간 필터 확인                                                   |
//+------------------------------------------------------------------+
bool VolatilityBreakoutAnalyzer::IsTimeFilterOK() {
    if (!config.use_time_filter) return true;
    
    datetime current_time = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(current_time, dt);
    
    // 주말 거래 금지
    if (dt.day_of_week == 0 || dt.day_of_week == 6) {
        return false;
    }
    
    // 뉴스 시간 회피 (정시 전후 15분)
    if (dt.min >= 45 || dt.min <= 15) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 포지션 청산 여부 확인                                             |
//+------------------------------------------------------------------+
bool VolatilityBreakoutAnalyzer::ShouldClosePosition(datetime entry_time, double entry_price, bool is_buy) {
    // 시간 청산 확인
    if (IsTimeExit(entry_time)) {
        return true;
    }
    
    // 수익 보호 확인
    if (IsProfitProtectionTriggered(entry_price, is_buy)) {
        return true;
    }
    
    // 반대 신호 확인
    ENUM_VOLATILITY_BREAKOUT_SIGNAL current_signal = GetBreakoutSignal();
    if (is_buy && current_signal == VB_SIGNAL_SELL_BREAKOUT) {
        return true;
    }
    if (!is_buy && current_signal == VB_SIGNAL_BUY_BREAKOUT) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ATR 값 계산                                                      |
//+------------------------------------------------------------------+
double VolatilityBreakoutAnalyzer::GetATR(int period = 0) {
    if (period == 0) period = config.atr_period;
    
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
//| 돌파 목표가 계산                                                  |
//+------------------------------------------------------------------+
double VolatilityBreakoutAnalyzer::CalculateBreakoutTarget(bool is_upward, double entry_price) {
    double atr_target = current_atr * config.atr_multiplier_exit;
    
    if (is_upward) {
        return entry_price + atr_target;
    } else {
        return entry_price - atr_target;
    }
}

//+------------------------------------------------------------------+
//| 시간 청산 확인                                                   |
//+------------------------------------------------------------------+
bool VolatilityBreakoutAnalyzer::IsTimeExit(datetime entry_time) {
    if (!config.use_time_exit) return false;
    
    datetime current_time = TimeCurrent();
    int holding_hours = (int)((current_time - entry_time) / 3600);
    
    return holding_hours >= config.max_holding_hours;
}

//+------------------------------------------------------------------+
//| 분석 정보 반환                                                   |
//+------------------------------------------------------------------+
string VolatilityBreakoutAnalyzer::GetAnalysisInfo() {
    string info = "";
    info += "=== 변동성 돌파 분석 ===\n";
    info += "변동성 상태: " + EnumToString(volatility_state) + "\n";
    info += "ATR 비율: " + DoubleToString(volatility_ratio, 2) + "\n";
    info += "현재 ATR: " + DoubleToString(current_atr, 5) + "\n";
    info += "횡보 상태: " + (in_consolidation ? "예" : "아니오") + "\n";
    
    if (in_consolidation) {
        info += "레인지 상단: " + DoubleToString(range_high, _Digits) + "\n";
        info += "레인지 하단: " + DoubleToString(range_low, _Digits) + "\n";
        info += "횡보 기간: " + IntegerToString(consolidation_bars) + " 봉\n";
    }
    
    if (config.use_london_session) {
        info += "런던 세션: " + (is_london_session ? "활성" : "비활성") + "\n";
    }
    
    return info;
}

//+------------------------------------------------------------------+
//| 기본 변동성 돌파 설정 반환                                         |
//+------------------------------------------------------------------+
VolatilityBreakoutConfig GetDefaultVolatilityBreakoutConfig() {
    VolatilityBreakoutConfig config;
    
    // ATR 설정
    config.atr_period = 14;
    config.atr_multiplier_entry = 1.5;
    config.atr_multiplier_exit = 2.5;
    
    // 변동성 임계값
    config.low_volatility_threshold = 0.7;
    config.high_volatility_threshold = 1.3;
    config.extreme_volatility_threshold = 2.0;
    
    // 돌파 설정
    config.consolidation_period = 10;
    config.breakout_threshold = 0.5;
    config.confirm_method = BREAKOUT_VOLUME_CONFIRM;
    config.min_breakout_bars = 2;
    
    // 런던 세션 설정
    config.use_london_session = true;
    config.london_start_hour = 7;  // GMT 7:00
    config.london_end_hour = 17;   // GMT 17:00
    config.london_breakout_only = false;
    
    // 필터 설정
    config.use_volume_filter = true;
    config.use_spread_filter = true;
    config.use_time_filter = true;
    config.max_spread_points = 2.0;
    
    // 청산 설정
    config.use_time_exit = true;
    config.max_holding_hours = 8;
    config.use_profit_protection = true;
    config.profit_protection_level = 1.5;
    
    return config;
}