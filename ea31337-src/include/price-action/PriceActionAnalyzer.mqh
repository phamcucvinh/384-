//+------------------------------------------------------------------+
//|                                           PriceActionAnalyzer.mqh |
//|                               가격행동 분석기 - 핵심 지지/저항 구간    |
//|                                     Price Action Analysis System  |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Price Action Edition"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 지지/저항 레벨 구조체                                              |
//+------------------------------------------------------------------+
struct SupportResistanceLevel {
    double price;               // 가격 레벨
    int touches;                // 터치 횟수
    datetime first_touch;       // 첫 터치 시간
    datetime last_touch;        // 마지막 터치 시간
    double strength;            // 강도 (0.0 - 1.0)
    bool is_support;            // 지지선 여부
    bool is_resistance;         // 저항선 여부
    bool is_active;             // 활성 상태
    int timeframe_confirmed;    // 확인된 시간프레임
};

//+------------------------------------------------------------------+
//| 가격행동 신호 열거형                                               |
//+------------------------------------------------------------------+
enum ENUM_PRICE_ACTION_SIGNAL {
    PA_SIGNAL_NONE = 0,         // 신호 없음
    PA_SIGNAL_BUY_BREAKOUT,     // 저항 돌파 매수
    PA_SIGNAL_SELL_BREAKDOWN,   // 지지 이탈 매도
    PA_SIGNAL_BUY_BOUNCE,       // 지지선 바운스 매수
    PA_SIGNAL_SELL_REJECTION,   // 저항선 거부 매도
    PA_SIGNAL_CLOSE_LONG,       // 롱 포지션 청산
    PA_SIGNAL_CLOSE_SHORT       // 숏 포지션 청산
};

//+------------------------------------------------------------------+
//| 가격행동 설정 구조체                                               |
//+------------------------------------------------------------------+
struct PriceActionConfig {
    // 지지/저항 감지 설정
    int lookback_period;        // 뒤돌아볼 기간
    double level_tolerance;     // 레벨 허용 오차 (pips)
    int min_touches;            // 최소 터치 횟수
    double min_strength;        // 최소 강도
    
    // 신호 생성 설정
    bool use_breakout;          // 돌파 신호 사용
    bool use_bounce;            // 바운스 신호 사용
    double breakout_buffer;     // 돌파 확인 버퍼 (pips)
    double bounce_buffer;       // 바운스 확인 버퍼 (pips)
    
    // 필터 설정
    bool use_volume_filter;     // 거래량 필터
    bool use_momentum_filter;   // 모멘텀 필터
    bool use_time_filter;       // 시간 필터
    
    // 리스크 관리
    double risk_reward_ratio;   // 리스크 대비 수익 비율
    double max_risk_per_trade;  // 거래당 최대 리스크
    bool use_trailing_stop;     // 트레일링 스톱 사용
};

//+------------------------------------------------------------------+
//| 가격행동 분석기 클래스                                             |
//+------------------------------------------------------------------+
class PriceActionAnalyzer {
private:
    PriceActionConfig config;
    SupportResistanceLevel levels[];
    int level_count;
    double point_value;
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    
    // 내부 변수
    datetime last_analysis_time;
    double last_high, last_low;
    bool trend_direction;
    
public:
    // 생성자
    PriceActionAnalyzer(PriceActionConfig &_config, string _symbol = "", ENUM_TIMEFRAMES _tf = PERIOD_CURRENT) {
        config = _config;
        symbol = (_symbol == "") ? _Symbol : _symbol;
        timeframe = _tf;
        point_value = MarketInfo(symbol, MODE_POINT);
        level_count = 0;
        last_analysis_time = 0;
        trend_direction = true;
        
        ArrayResize(levels, 100); // 최대 100개 레벨
    }
    
    // 지지/저항 레벨 분석
    void AnalyzeSupportResistanceLevels();
    
    // 가격행동 신호 분석
    ENUM_PRICE_ACTION_SIGNAL GetPriceActionSignal();
    
    // 핵심 레벨 식별
    void IdentifyKeyLevels();
    
    // 레벨 강도 계산
    double CalculateLevelStrength(SupportResistanceLevel &level);
    
    // 레벨 업데이트
    void UpdateLevels();
    
    // 현재 트렌드 분석
    bool AnalyzeTrend();
    
    // 볼륨 분석
    bool AnalyzeVolume(int shift = 0);
    
    // 모멘텀 분석
    bool AnalyzeMomentum(int shift = 0);
    
    // 진입 신호 확인
    bool ConfirmEntrySignal(ENUM_PRICE_ACTION_SIGNAL signal);
    
    // 청산 신호 확인
    bool ConfirmExitSignal(int ticket);
    
    // 레벨 터치 감지
    bool IsLevelTouched(double level, double price, double tolerance);
    
    // 가장 가까운 지지선 찾기
    double GetNearestSupport(double price);
    
    // 가장 가까운 저항선 찾기
    double GetNearestResistance(double price);
    
    // 현재 상태 정보 반환
    string GetStatusInfo();
    
    // 설정 업데이트
    void UpdateConfig(PriceActionConfig &new_config) {
        config = new_config;
    }
    
    // 레벨 정보 반환
    int GetLevelCount() { return level_count; }
    SupportResistanceLevel GetLevel(int index) {
        if (index >= 0 && index < level_count) {
            return levels[index];
        }
        SupportResistanceLevel empty_level = {};
        return empty_level;
    }
};

//+------------------------------------------------------------------+
//| 지지/저항 레벨 분석 함수                                           |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::AnalyzeSupportResistanceLevels() {
    // 기존 레벨 업데이트
    UpdateLevels();
    
    // 새로운 레벨 감지
    IdentifyKeyLevels();
    
    // 레벨 강도 재계산
    for (int i = 0; i < level_count; i++) {
        if (levels[i].is_active) {
            levels[i].strength = CalculateLevelStrength(levels[i]);
        }
    }
    
    last_analysis_time = TimeCurrent();
}

//+------------------------------------------------------------------+
//| 핵심 레벨 식별                                                    |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::IdentifyKeyLevels() {
    double highs[], lows[];
    ArrayResize(highs, config.lookback_period);
    ArrayResize(lows, config.lookback_period);
    
    // 최근 고점/저점 수집
    for (int i = 0; i < config.lookback_period; i++) {
        highs[i] = iHigh(symbol, timeframe, i);
        lows[i] = iLow(symbol, timeframe, i);
    }
    
    // 스윙 하이/로우 찾기
    for (int i = 2; i < config.lookback_period - 2; i++) {
        // 스윙 하이 (저항선 후보)
        if (highs[i] > highs[i-1] && highs[i] > highs[i-2] && 
            highs[i] > highs[i+1] && highs[i] > highs[i+2]) {
            AddOrUpdateLevel(highs[i], false, true, iTime(symbol, timeframe, i));
        }
        
        // 스윙 로우 (지지선 후보)
        if (lows[i] < lows[i-1] && lows[i] < lows[i-2] && 
            lows[i] < lows[i+1] && lows[i] < lows[i+2]) {
            AddOrUpdateLevel(lows[i], true, false, iTime(symbol, timeframe, i));
        }
    }
    
    // 라운드 넘버 레벨 추가 (00, 50 레벨)
    double current_price = MarketInfo(symbol, MODE_BID);
    double round_level = MathRound(current_price / (50 * point_value)) * 50 * point_value;
    AddOrUpdateLevel(round_level, true, true, TimeCurrent());
}

//+------------------------------------------------------------------+
//| 레벨 추가 또는 업데이트                                            |
//+------------------------------------------------------------------+
void AddOrUpdateLevel(double price, bool is_support, bool is_resistance, datetime touch_time) {
    // 기존 레벨과 유사한지 확인
    for (int i = 0; i < level_count; i++) {
        if (IsLevelTouched(levels[i].price, price, config.level_tolerance)) {
            // 기존 레벨 업데이트
            levels[i].touches++;
            levels[i].last_touch = touch_time;
            levels[i].is_support = levels[i].is_support || is_support;
            levels[i].is_resistance = levels[i].is_resistance || is_resistance;
            return;
        }
    }
    
    // 새 레벨 추가
    if (level_count < ArraySize(levels)) {
        levels[level_count].price = price;
        levels[level_count].touches = 1;
        levels[level_count].first_touch = touch_time;
        levels[level_count].last_touch = touch_time;
        levels[level_count].is_support = is_support;
        levels[level_count].is_resistance = is_resistance;
        levels[level_count].is_active = true;
        levels[level_count].strength = 0.5; // 초기 강도
        level_count++;
    }
}

//+------------------------------------------------------------------+
//| 레벨 강도 계산                                                    |
//+------------------------------------------------------------------+
double PriceActionAnalyzer::CalculateLevelStrength(SupportResistanceLevel &level) {
    double strength = 0.0;
    
    // 터치 횟수 기반 강도 (최대 0.4)
    strength += MathMin(level.touches * 0.1, 0.4);
    
    // 시간 기반 강도 (오래된 레벨일수록 강함, 최대 0.3)
    int age_hours = (int)((TimeCurrent() - level.first_touch) / 3600);
    strength += MathMin(age_hours * 0.001, 0.3);
    
    // 라운드 넘버 보너스 (최대 0.2)
    double mod_50 = MathMod(level.price, 50 * point_value);
    double mod_100 = MathMod(level.price, 100 * point_value);
    if (mod_100 < point_value || mod_100 > 99 * point_value) {
        strength += 0.2; // 100의 배수
    } else if (mod_50 < point_value || mod_50 > 49 * point_value) {
        strength += 0.1; // 50의 배수
    }
    
    // 최근 활성도 보너스 (최대 0.1)
    int last_touch_hours = (int)((TimeCurrent() - level.last_touch) / 3600);
    if (last_touch_hours < 24) {
        strength += 0.1;
    }
    
    return MathMin(strength, 1.0);
}

//+------------------------------------------------------------------+
//| 가격행동 신호 분석                                                |
//+------------------------------------------------------------------+
ENUM_PRICE_ACTION_SIGNAL PriceActionAnalyzer::GetPriceActionSignal() {
    double current_price = MarketInfo(symbol, MODE_BID);
    double current_ask = MarketInfo(symbol, MODE_ASK);
    
    // 가장 가까운 지지/저항 레벨 찾기
    double nearest_support = GetNearestSupport(current_price);
    double nearest_resistance = GetNearestResistance(current_price);
    
    // 돌파 신호 확인
    if (config.use_breakout) {
        // 저항 돌파 매수
        if (nearest_resistance > 0 && current_ask > nearest_resistance + config.breakout_buffer * point_value) {
            if (ConfirmEntrySignal(PA_SIGNAL_BUY_BREAKOUT)) {
                return PA_SIGNAL_BUY_BREAKOUT;
            }
        }
        
        // 지지 이탈 매도
        if (nearest_support > 0 && current_price < nearest_support - config.breakout_buffer * point_value) {
            if (ConfirmEntrySignal(PA_SIGNAL_SELL_BREAKDOWN)) {
                return PA_SIGNAL_SELL_BREAKDOWN;
            }
        }
    }
    
    // 바운스 신호 확인
    if (config.use_bounce) {
        // 지지선 바운스 매수
        if (nearest_support > 0 && 
            current_price >= nearest_support - config.bounce_buffer * point_value &&
            current_price <= nearest_support + config.bounce_buffer * point_value) {
            
            // 바운스 확인 (이전 캔들이 지지선 아래였다가 현재 위로)
            double prev_close = iClose(symbol, timeframe, 1);
            if (prev_close < nearest_support && current_price > nearest_support) {
                if (ConfirmEntrySignal(PA_SIGNAL_BUY_BOUNCE)) {
                    return PA_SIGNAL_BUY_BOUNCE;
                }
            }
        }
        
        // 저항선 거부 매도
        if (nearest_resistance > 0 && 
            current_price >= nearest_resistance - config.bounce_buffer * point_value &&
            current_price <= nearest_resistance + config.bounce_buffer * point_value) {
            
            // 거부 확인 (이전 캔들이 저항선 위였다가 현재 아래로)
            double prev_close = iClose(symbol, timeframe, 1);
            if (prev_close > nearest_resistance && current_price < nearest_resistance) {
                if (ConfirmEntrySignal(PA_SIGNAL_SELL_REJECTION)) {
                    return PA_SIGNAL_SELL_REJECTION;
                }
            }
        }
    }
    
    return PA_SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| 진입 신호 확인                                                    |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::ConfirmEntrySignal(ENUM_PRICE_ACTION_SIGNAL signal) {
    // 볼륨 필터
    if (config.use_volume_filter && !AnalyzeVolume()) {
        return false;
    }
    
    // 모멘텀 필터
    if (config.use_momentum_filter && !AnalyzeMomentum()) {
        return false;
    }
    
    // 시간 필터 (뉴스 시간 등 회피)
    if (config.use_time_filter) {
        datetime current_time = TimeCurrent();
        int current_hour = TimeHour(current_time);
        int current_minute = TimeMinute(current_time);
        
        // 정시 전후 5분 회피
        if (current_minute >= 55 || current_minute <= 5) {
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| 볼륨 분석 (간단한 구현)                                            |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::AnalyzeVolume(int shift = 0) {
    // MQL4에서는 실제 거래량이 없으므로 틱 볼륨 사용
    long current_volume = iVolume(symbol, timeframe, shift);
    long avg_volume = 0;
    
    // 평균 볼륨 계산 (최근 20 캔들)
    for (int i = shift + 1; i <= shift + 20; i++) {
        avg_volume += iVolume(symbol, timeframe, i);
    }
    avg_volume /= 20;
    
    // 현재 볼륨이 평균의 120% 이상이면 충분한 볼륨으로 판단
    return current_volume > avg_volume * 1.2;
}

//+------------------------------------------------------------------+
//| 모멘텀 분석                                                       |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::AnalyzeMomentum(int shift = 0) {
    // 간단한 가격 모멘텀 (현재 가격과 5캔들 전 가격 비교)
    double current_close = iClose(symbol, timeframe, shift);
    double prev_close = iClose(symbol, timeframe, shift + 5);
    
    // 1% 이상의 움직임이 있으면 충분한 모멘텀으로 판단
    double momentum = MathAbs((current_close - prev_close) / prev_close);
    return momentum > 0.01;
}

//+------------------------------------------------------------------+
//| 레벨 터치 감지                                                    |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::IsLevelTouched(double level, double price, double tolerance) {
    double tolerance_value = tolerance * point_value;
    return MathAbs(price - level) <= tolerance_value;
}

//+------------------------------------------------------------------+
//| 가장 가까운 지지선 찾기                                            |
//+------------------------------------------------------------------+
double PriceActionAnalyzer::GetNearestSupport(double price) {
    double nearest_support = 0;
    double min_distance = DBL_MAX;
    
    for (int i = 0; i < level_count; i++) {
        if (levels[i].is_active && levels[i].is_support && 
            levels[i].price < price && levels[i].strength >= config.min_strength) {
            
            double distance = price - levels[i].price;
            if (distance < min_distance) {
                min_distance = distance;
                nearest_support = levels[i].price;
            }
        }
    }
    
    return nearest_support;
}

//+------------------------------------------------------------------+
//| 가장 가까운 저항선 찾기                                            |
//+------------------------------------------------------------------+
double PriceActionAnalyzer::GetNearestResistance(double price) {
    double nearest_resistance = 0;
    double min_distance = DBL_MAX;
    
    for (int i = 0; i < level_count; i++) {
        if (levels[i].is_active && levels[i].is_resistance && 
            levels[i].price > price && levels[i].strength >= config.min_strength) {
            
            double distance = levels[i].price - price;
            if (distance < min_distance) {
                min_distance = distance;
                nearest_resistance = levels[i].price;
            }
        }
    }
    
    return nearest_resistance;
}

//+------------------------------------------------------------------+
//| 레벨 업데이트 (오래된 레벨 제거)                                   |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::UpdateLevels() {
    for (int i = level_count - 1; i >= 0; i--) {
        // 24시간 이상 터치되지 않은 약한 레벨 제거
        if (levels[i].strength < 0.5 && 
            TimeCurrent() - levels[i].last_touch > 86400) {
            levels[i].is_active = false;
        }
        
        // 너무 멀리 떨어진 레벨 제거
        double current_price = MarketInfo(symbol, MODE_BID);
        double distance = MathAbs(current_price - levels[i].price);
        if (distance > 500 * point_value) { // 500 pips 이상
            levels[i].is_active = false;
        }
    }
}

//+------------------------------------------------------------------+
//| 현재 상태 정보 반환                                               |
//+------------------------------------------------------------------+
string PriceActionAnalyzer::GetStatusInfo() {
    double current_price = MarketInfo(symbol, MODE_BID);
    double nearest_support = GetNearestSupport(current_price);
    double nearest_resistance = GetNearestResistance(current_price);
    
    string status = "";
    status += "=== 가격행동 분석 상태 ===\n";
    status += "활성 레벨 수: " + IntegerToString(level_count) + "\n";
    status += "현재 가격: " + DoubleToString(current_price, _Digits) + "\n";
    
    if (nearest_support > 0) {
        status += "가장 가까운 지지: " + DoubleToString(nearest_support, _Digits);
        status += " (거리: " + DoubleToString((current_price - nearest_support) / point_value, 1) + " pips)\n";
    }
    
    if (nearest_resistance > 0) {
        status += "가장 가까운 저항: " + DoubleToString(nearest_resistance, _Digits);
        status += " (거리: " + DoubleToString((nearest_resistance - current_price) / point_value, 1) + " pips)\n";
    }
    
    status += "트렌드 방향: " + (trend_direction ? "상승" : "하락") + "\n";
    
    return status;
}

//+------------------------------------------------------------------+
//| 기본 가격행동 설정 반환                                            |
//+------------------------------------------------------------------+
PriceActionConfig GetDefaultPriceActionConfig() {
    PriceActionConfig config;
    
    // 지지/저항 감지 설정
    config.lookback_period = 100;       // 100 캔들 뒤돌아봄
    config.level_tolerance = 5.0;       // 5 pips 허용 오차
    config.min_touches = 2;             // 최소 2회 터치
    config.min_strength = 0.4;          // 최소 강도 40%
    
    // 신호 생성 설정
    config.use_breakout = true;         // 돌파 신호 사용
    config.use_bounce = true;           // 바운스 신호 사용
    config.breakout_buffer = 3.0;       // 3 pips 돌파 버퍼
    config.bounce_buffer = 2.0;         // 2 pips 바운스 버퍼
    
    // 필터 설정
    config.use_volume_filter = true;    // 볼륨 필터 사용
    config.use_momentum_filter = true;  // 모멘텀 필터 사용
    config.use_time_filter = true;      // 시간 필터 사용
    
    // 리스크 관리
    config.risk_reward_ratio = 2.0;     // 1:2 리스크 수익 비율
    config.max_risk_per_trade = 2.0;    // 거래당 최대 2% 리스크
    config.use_trailing_stop = true;    // 트레일링 스톱 사용
    
    return config;
}