//+------------------------------------------------------------------+
//|                                           ScalpingStrategy.mqh |
//|                        스캘핑 전용 전략 구현                      |
//|                                 Advanced Scalping System        |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Enhanced"
#property version   "1.00"

// 필요한 헤더 파일들
#include "../common/enum.h"

//+------------------------------------------------------------------+
//| 스캘핑 전용 설정 구조체                                            |
//+------------------------------------------------------------------+
struct ScalpingConfig {
    // 기본 설정
    double lot_size;              // 거래량
    int max_trades;               // 최대 동시 거래 수
    double spread_limit;          // 최대 허용 스프레드
    
    // 신호 설정
    bool use_price_swings;        // Price Swings 사용 여부
    bool use_atr_ma_trend;        // ATR MA Trend 사용 여부  
    bool use_spread_filter;       // 스프레드 필터 사용 여부
    
    // 리스크 관리
    double stop_loss_pips;        // 손절매 (pips)
    double take_profit_pips;      // 익절 (pips)
    double trailing_stop_pips;    // 트레일링 스톱 (pips)
    
    // 시간 필터
    bool use_time_filter;         // 시간 필터 사용
    int start_hour;               // 거래 시작 시간
    int end_hour;                 // 거래 종료 시간
    
    // ATR MA Trend 설정
    int atr_period;               // ATR 기간
    double atr_sensitivity;       // ATR 민감도
    int ma_period;                // 이동평균 기간
    
    // Price Swings 설정
    int swing_period;             // 스윙 계산 기간
    double swing_threshold;       // 스윙 임계값
    
    // 스프레드 설정
    double max_spread_points;     // 최대 스프레드 포인트
    bool spread_multiplier_mode;  // 스프레드 배수 모드
    
    // 마틴게일 설정
    bool use_martingale;          // 마틴게일 사용 여부
    double martingale_multiplier; // 마틴게일 배수
    int max_martingale_levels;    // 최대 마틴게일 단계
    bool use_oscillator_martingale; // 오실레이터 마틴게일 사용
};

//+------------------------------------------------------------------+
//| 스캘핑 신호 열거형                                                |
//+------------------------------------------------------------------+
enum ENUM_SCALPING_SIGNAL {
    SCALPING_SIGNAL_NONE = 0,     // 신호 없음
    SCALPING_SIGNAL_BUY,          // 매수 신호
    SCALPING_SIGNAL_SELL,         // 매도 신호
    SCALPING_SIGNAL_CLOSE_BUY,    // 매수 포지션 청산
    SCALPING_SIGNAL_CLOSE_SELL    // 매도 포지션 청산
};

//+------------------------------------------------------------------+
//| 스캘핑 전략 클래스                                                |
//+------------------------------------------------------------------+
class ScalpingStrategy {
private:
    ScalpingConfig config;        // 설정
    datetime last_trade_time;     // 마지막 거래 시간
    int current_trades;           // 현재 거래 수
    double last_atr_value;        // 마지막 ATR 값
    bool trend_direction;         // 트렌드 방향 (true=상승, false=하락)
    
    // 마틴게일 관련 변수
    int martingale_level;         // 현재 마틴게일 단계
    double last_lot_size;         // 마지막 거래량
    bool last_trade_was_loss;     // 마지막 거래가 손실인지
    
public:
    // 생성자
    ScalpingStrategy(ScalpingConfig &cfg) {
        config = cfg;
        last_trade_time = 0;
        current_trades = 0;
        last_atr_value = 0;
        trend_direction = true;
        
        // 마틴게일 초기화
        martingale_level = 0;
        last_lot_size = config.lot_size;
        last_trade_was_loss = false;
    }
    
    // 스캘핑 신호 분석
    ENUM_SCALPING_SIGNAL GetScalpingSignal();
    
    // ATR MA Trend 분석
    bool AnalyzeATRMATrend();
    
    // Price Swings 분석  
    bool AnalyzePriceSwings();
    
    // 스프레드 체크
    bool IsSpreadAcceptable();
    
    // 시간 필터 체크
    bool IsTimeFilterOK();
    
    // 리스크 관리
    bool IsRiskAcceptable();
    
    // 포지션 관리
    bool ShouldClosePosition(int ticket);
    
    // 트레일링 스톱 업데이트
    void UpdateTrailingStop(int ticket);
    
    // 설정 업데이트
    void UpdateConfig(ScalpingConfig &new_config) {
        config = new_config;
    }
    
    // 마틴게일 관련 메서드
    double CalculateMartingaleLotSize();         // 마틴게일 거래량 계산
    void OnTradeResult(bool is_profit);          // 거래 결과 처리
    void ResetMartingale();                      // 마틴게일 리셋
    int GetMartingaleLevel() { return martingale_level; }
    
    // 현재 상태 반환
    string GetStatusInfo();
};

//+------------------------------------------------------------------+
//| 스캘핑 신호 분석 함수                                              |
//+------------------------------------------------------------------+
ENUM_SCALPING_SIGNAL ScalpingStrategy::GetScalpingSignal() {
    // 기본 조건 체크
    if (!IsSpreadAcceptable()) return SCALPING_SIGNAL_NONE;
    if (!IsTimeFilterOK()) return SCALPING_SIGNAL_NONE;
    if (!IsRiskAcceptable()) return SCALPING_SIGNAL_NONE;
    
    bool atr_signal = false;
    bool swing_signal = false;
    bool buy_condition = false;
    bool sell_condition = false;
    
    // ATR MA Trend 분석
    if (config.use_atr_ma_trend) {
        atr_signal = AnalyzeATRMATrend();
    }
    
    // Price Swings 분석
    if (config.use_price_swings) {
        swing_signal = AnalyzePriceSwings();
    }
    
    // 복합 신호 생성
    if (config.use_atr_ma_trend && config.use_price_swings) {
        // 두 신호 모두 사용하는 경우 - 더 보수적
        buy_condition = atr_signal && swing_signal && trend_direction;
        sell_condition = atr_signal && swing_signal && !trend_direction;
    } else if (config.use_atr_ma_trend) {
        // ATR MA Trend만 사용
        buy_condition = atr_signal && trend_direction;
        sell_condition = atr_signal && !trend_direction;
    } else if (config.use_price_swings) {
        // Price Swings만 사용
        buy_condition = swing_signal && trend_direction;
        sell_condition = swing_signal && !trend_direction;
    }
    
    // 최종 신호 결정
    if (buy_condition && current_trades < config.max_trades) {
        return SCALPING_SIGNAL_BUY;
    }
    if (sell_condition && current_trades < config.max_trades) {
        return SCALPING_SIGNAL_SELL;
    }
    
    return SCALPING_SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| ATR MA Trend 분석                                               |
//+------------------------------------------------------------------+
bool ScalpingStrategy::AnalyzeATRMATrend() {
    // ATR 값 계산
    double atr_current = iATR(_Symbol, PERIOD_CURRENT, config.atr_period, 0);
    double atr_prev = iATR(_Symbol, PERIOD_CURRENT, config.atr_period, 1);
    
    // 이동평균 계산
    double ma_current = iMA(_Symbol, PERIOD_CURRENT, config.ma_period, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ma_prev = iMA(_Symbol, PERIOD_CURRENT, config.ma_period, 0, MODE_EMA, PRICE_CLOSE, 1);
    
    // 현재 가격
    double price_current = iClose(_Symbol, PERIOD_CURRENT, 0);
    double price_prev = iClose(_Symbol, PERIOD_CURRENT, 1);
    
    // 변동성 기반 임계값
    double threshold = atr_current * config.atr_sensitivity;
    
    // 트렌드 방향 결정
    if (price_current > ma_current + threshold && price_prev <= ma_prev + threshold) {
        trend_direction = true;  // 상승 트렌드 시작
        last_atr_value = atr_current;
        return true;
    }
    
    if (price_current < ma_current - threshold && price_prev >= ma_prev - threshold) {
        trend_direction = false; // 하락 트렌드 시작
        last_atr_value = atr_current;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Price Swings 분석                                               |
//+------------------------------------------------------------------+
bool ScalpingStrategy::AnalyzePriceSwings() {
    double high_values[];
    double low_values[];
    ArrayResize(high_values, config.swing_period);
    ArrayResize(low_values, config.swing_period);
    
    // 최근 고점/저점 수집
    for (int i = 0; i < config.swing_period; i++) {
        high_values[i] = iHigh(_Symbol, PERIOD_CURRENT, i);
        low_values[i] = iLow(_Symbol, PERIOD_CURRENT, i);
    }
    
    // 현재 가격과 스윙 포인트 비교
    double current_price = iClose(_Symbol, PERIOD_CURRENT, 0);
    double prev_price = iClose(_Symbol, PERIOD_CURRENT, 1);
    
    // 최고점과 최저점 찾기
    double swing_high = high_values[ArrayMaximum(high_values)];
    double swing_low = low_values[ArrayMinimum(low_values)];
    
    // 스윙 신호 생성
    double swing_range = swing_high - swing_low;
    double threshold = swing_range * config.swing_threshold;
    
    // 상승 스윙 신호
    if (current_price > prev_price && 
        current_price > swing_low + threshold &&
        prev_price <= swing_low + threshold) {
        trend_direction = true;
        return true;
    }
    
    // 하락 스윙 신호
    if (current_price < prev_price && 
        current_price < swing_high - threshold &&
        prev_price >= swing_high - threshold) {
        trend_direction = false;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| 스프레드 체크                                                    |
//+------------------------------------------------------------------+
bool ScalpingStrategy::IsSpreadAcceptable() {
    if (!config.use_spread_filter) return true;
    
    double spread = MarketInfo(_Symbol, MODE_SPREAD) * MarketInfo(_Symbol, MODE_POINT);
    
    if (config.spread_multiplier_mode) {
        // ATR 기반 동적 스프레드 제한
        double atr = iATR(_Symbol, PERIOD_CURRENT, config.atr_period, 0);
        return spread <= atr * config.max_spread_points;
    } else {
        // 고정 스프레드 제한
        return spread <= config.max_spread_points * MarketInfo(_Symbol, MODE_POINT);
    }
}

//+------------------------------------------------------------------+
//| 시간 필터 체크                                                   |
//+------------------------------------------------------------------+
bool ScalpingStrategy::IsTimeFilterOK() {
    if (!config.use_time_filter) return true;
    
    datetime current_time = TimeCurrent();
    int current_hour = TimeHour(current_time);
    
    if (config.start_hour <= config.end_hour) {
        return current_hour >= config.start_hour && current_hour <= config.end_hour;
    } else {
        // 시간이 자정을 넘어가는 경우
        return current_hour >= config.start_hour || current_hour <= config.end_hour;
    }
}

//+------------------------------------------------------------------+
//| 리스크 체크                                                      |
//+------------------------------------------------------------------+
bool ScalpingStrategy::IsRiskAcceptable() {
    // 최대 거래 수 체크
    if (current_trades >= config.max_trades) return false;
    
    // 마지막 거래와의 시간 간격 체크 (최소 1분)
    if (TimeCurrent() - last_trade_time < 60) return false;
    
    // 계좌 잔고 대비 거래량 체크
    double balance = AccountBalance();
    double margin_required = MarketInfo(_Symbol, MODE_MARGINREQUIRED) * config.lot_size;
    
    if (margin_required > balance * 0.1) return false; // 잔고의 10% 이상 마진 사용 금지
    
    return true;
}

//+------------------------------------------------------------------+
//| 포지션 청산 여부 결정                                              |
//+------------------------------------------------------------------+
bool ScalpingStrategy::ShouldClosePosition(int ticket) {
    if (!OrderSelect(ticket, SELECT_BY_TICKET)) return false;
    
    double open_price = OrderOpenPrice();
    double current_price = (OrderType() == OP_BUY) ? MarketInfo(_Symbol, MODE_BID) : MarketInfo(_Symbol, MODE_ASK);
    double profit_pips = 0;
    
    if (OrderType() == OP_BUY) {
        profit_pips = (current_price - open_price) / MarketInfo(_Symbol, MODE_POINT);
    } else {
        profit_pips = (open_price - current_price) / MarketInfo(_Symbol, MODE_POINT);
    }
    
    // 익절 조건
    if (profit_pips >= config.take_profit_pips) return true;
    
    // 손절 조건
    if (profit_pips <= -config.stop_loss_pips) return true;
    
    // 반대 신호 발생 시 청산
    ENUM_SCALPING_SIGNAL current_signal = GetScalpingSignal();
    if ((OrderType() == OP_BUY && current_signal == SCALPING_SIGNAL_SELL) ||
        (OrderType() == OP_SELL && current_signal == SCALPING_SIGNAL_BUY)) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| 상태 정보 반환                                                    |
//+------------------------------------------------------------------+
string ScalpingStrategy::GetStatusInfo() {
    string status = "";
    status += "=== 스캘핑 전략 상태 ===\n";
    status += "현재 거래 수: " + IntegerToString(current_trades) + "/" + IntegerToString(config.max_trades) + "\n";
    status += "트렌드 방향: " + (trend_direction ? "상승" : "하락") + "\n";
    status += "마지막 ATR: " + DoubleToString(last_atr_value, 5) + "\n";
    status += "스프레드 상태: " + (IsSpreadAcceptable() ? "양호" : "높음") + "\n";
    status += "시간 필터: " + (IsTimeFilterOK() ? "활성" : "비활성") + "\n";
    status += "리스크 상태: " + (IsRiskAcceptable() ? "안전" : "위험") + "\n";
    
    return status;
}

//+------------------------------------------------------------------+
//| 기본 스캘핑 설정 반환                                              |
//+------------------------------------------------------------------+
ScalpingConfig GetDefaultScalpingConfig() {
    ScalpingConfig config;
    
    // 기본 설정
    config.lot_size = 0.01;
    config.max_trades = 3;
    config.spread_limit = 2.0;
    
    // 신호 설정
    config.use_price_swings = true;
    config.use_atr_ma_trend = true;
    config.use_spread_filter = true;
    
    // 리스크 관리
    config.stop_loss_pips = 10;
    config.take_profit_pips = 15;
    config.trailing_stop_pips = 5;
    
    // 시간 필터
    config.use_time_filter = true;
    config.start_hour = 8;   // 오전 8시
    config.end_hour = 18;    // 오후 6시
    
    // ATR MA Trend 설정
    config.atr_period = 14;
    config.atr_sensitivity = 1.2;
    config.ma_period = 21;
    
    // Price Swings 설정
    config.swing_period = 10;
    config.swing_threshold = 0.3;
    
    // 스프레드 설정
    config.max_spread_points = 2.0;
    config.spread_multiplier_mode = true;
    
    // 마틴게일 설정
    config.use_martingale = false;
    config.martingale_multiplier = 2.0;
    config.max_martingale_levels = 3;
    config.use_oscillator_martingale = false;
    
    return config;
}

//+------------------------------------------------------------------+
//| 마틴게일 거래량 계산                                               |
//+------------------------------------------------------------------+
double ScalpingStrategy::CalculateMartingaleLotSize() {
    if (!config.use_martingale || martingale_level == 0) {
        return config.lot_size;
    }
    
    double martingale_lot = config.lot_size;
    for (int i = 0; i < martingale_level; i++) {
        martingale_lot *= config.martingale_multiplier;
    }
    
    // 최대 거래량 제한
    double max_lot = MarketInfo(_Symbol, MODE_MAXLOT);
    if (martingale_lot > max_lot) {
        martingale_lot = max_lot;
    }
    
    return martingale_lot;
}

//+------------------------------------------------------------------+
//| 거래 결과 처리                                                   |
//+------------------------------------------------------------------+
void ScalpingStrategy::OnTradeResult(bool is_profit) {
    if (!config.use_martingale) return;
    
    if (is_profit) {
        // 수익시 마틴게일 리셋
        ResetMartingale();
        last_trade_was_loss = false;
    } else {
        // 손실시 마틴게일 레벨 증가
        if (martingale_level < config.max_martingale_levels) {
            martingale_level++;
        }
        last_trade_was_loss = true;
    }
}

//+------------------------------------------------------------------+
//| 마틴게일 리셋                                                    |
//+------------------------------------------------------------------+
void ScalpingStrategy::ResetMartingale() {
    martingale_level = 0;
    last_lot_size = config.lot_size;
    last_trade_was_loss = false;
}