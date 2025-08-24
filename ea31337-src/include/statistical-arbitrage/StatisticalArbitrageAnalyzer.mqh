//+------------------------------------------------------------------+
//|                                   StatisticalArbitrageAnalyzer.mqh |
//|                                      통계적 차익거래 분석기           |
//|                                 Statistical Arbitrage Analyzer     |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Statistical Arbitrage Edition"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 페어 상태 열거형                                                   |
//+------------------------------------------------------------------+
enum ENUM_PAIR_STATE {
    PAIR_STATE_COINTEGRATED = 0,    // 공적분 관계
    PAIR_STATE_DIVERGING,           // 발산 중
    PAIR_STATE_CONVERGING,          // 수렴 중
    PAIR_STATE_STABLE,              // 안정 상태
    PAIR_STATE_UNSTABLE             // 불안정 상태
};

//+------------------------------------------------------------------+
//| 차익거래 신호 열거형                                               |
//+------------------------------------------------------------------+
enum ENUM_ARBITRAGE_SIGNAL {
    ARB_SIGNAL_NONE = 0,            // 신호 없음
    ARB_SIGNAL_LONG_PAIR,           // 페어 롱 (A매수, B매도)
    ARB_SIGNAL_SHORT_PAIR,          // 페어 숏 (A매도, B매수)
    ARB_SIGNAL_CLOSE_LONG,          // 롱 포지션 청산
    ARB_SIGNAL_CLOSE_SHORT,         // 숏 포지션 청산
    ARB_SIGNAL_REBALANCE            // 리밸런싱
};

//+------------------------------------------------------------------+
//| 공적분 방법 열거형                                                 |
//+------------------------------------------------------------------+
enum ENUM_COINTEGRATION_METHOD {
    COINT_METHOD_ENGLE_GRANGER = 0, // Engle-Granger 방법
    COINT_METHOD_JOHANSEN,          // Johansen 방법
    COINT_METHOD_KALMAN_FILTER,     // 칼만 필터
    COINT_METHOD_SIMPLE_SPREAD      // 단순 스프레드
};

//+------------------------------------------------------------------+
//| 통계적 차익거래 설정 구조체                                         |
//+------------------------------------------------------------------+
struct StatisticalArbitrageConfig {
    // 페어 설정
    string symbol_A;                        // 심볼 A
    string symbol_B;                        // 심볼 B
    double hedge_ratio;                     // 헤지 비율
    bool auto_hedge_ratio;                  // 자동 헤지 비율 계산
    
    // 공적분 설정
    ENUM_COINTEGRATION_METHOD coint_method; // 공적분 방법
    int lookback_period;                    // 룩백 기간
    double significance_level;              // 유의수준
    int min_cointegration_period;           // 최소 공적분 기간
    
    // 스프레드 분석
    int spread_ma_period;                   // 스프레드 이동평균 기간
    double entry_zscore_threshold;          // 진입 Z-Score 임계값
    double exit_zscore_threshold;           // 청산 Z-Score 임계값
    double stop_loss_zscore;                // 손절 Z-Score
    
    // 칼만 필터 설정
    double kalman_delta;                    // 칼만 델타
    double kalman_velo;                     // 칼만 속도
    double kalman_ve;                       // 칼만 관측 오차
    
    // 리스크 관리
    double max_position_size;               // 최대 포지션 크기
    double correlation_threshold;           // 상관관계 임계값
    int max_holding_period;                 // 최대 보유 기간
    bool enable_mean_reversion_filter;      // 평균회귀 필터
    
    // 성능 설정
    int recalibration_frequency;            // 재보정 빈도
    bool adaptive_thresholds;               // 적응형 임계값
    double volatility_adjustment;           // 변동성 조정
};

//+------------------------------------------------------------------+
//| 페어 통계 구조체                                                   |
//+------------------------------------------------------------------+
struct PairStatistics {
    double correlation;                     // 상관계수
    double cointegration_pvalue;            // 공적분 p-값
    double spread_mean;                     // 스프레드 평균
    double spread_std;                      // 스프레드 표준편차
    double current_zscore;                  // 현재 Z-Score
    double hedge_ratio_estimate;            // 추정 헤지 비율
    datetime last_update;                   // 마지막 업데이트 시간
    int stable_periods;                     // 안정 기간 수
};

//+------------------------------------------------------------------+
//| 칼만 필터 상태                                                     |
//+------------------------------------------------------------------+
struct KalmanState {
    double state_mean;                      // 상태 평균
    double state_covariance;                // 상태 공분산
    double observation_covariance;          // 관측 공분산
    double process_covariance;              // 프로세스 공분산
    bool is_initialized;                    // 초기화 여부
};

//+------------------------------------------------------------------+
//| 차익거래 기회 구조체                                               |
//+------------------------------------------------------------------+
struct ArbitrageOpportunity {
    ENUM_ARBITRAGE_SIGNAL signal_type;      // 신호 타입
    double expected_profit;                 // 기대 수익
    double confidence_level;                // 신뢰도
    double risk_level;                      // 리스크 레벨
    double symbol_A_price;                  // 심볼 A 가격
    double symbol_B_price;                  // 심볼 B 가격
    double optimal_lot_A;                   // 최적 로트 A
    double optimal_lot_B;                   // 최적 로트 B
    datetime opportunity_time;              // 기회 발생 시간
    int holding_period_estimate;            // 예상 보유 기간
};

//+------------------------------------------------------------------+
//| 통계적 차익거래 분석기 클래스                                       |
//+------------------------------------------------------------------+
class StatisticalArbitrageAnalyzer {
private:
    StatisticalArbitrageConfig config;
    PairStatistics pair_stats;
    KalmanState kalman_state;
    string log_prefix;
    
    // 가격 데이터 저장
    double price_A_history[500];
    double price_B_history[500];
    double spread_history[500];
    int data_points;
    
    // 스프레드 분석
    double spread_ma_values[100];
    double zscore_history[100];
    int ma_index;
    
    // 성능 추적
    int total_signals;
    int profitable_signals;
    double total_pnl;
    datetime last_signal_time;
    
public:
    /**
     * 생성자
     */
    StatisticalArbitrageAnalyzer(StatisticalArbitrageConfig &_config) {
        config = _config;
        log_prefix = "[StatArb-" + config.symbol_A + "/" + config.symbol_B + "] ";
        
        InitializeAnalyzer();
        ResetStatistics();
        
        Print(log_prefix, "통계적 차익거래 분석기 초기화 완료");
    }
    
    /**
     * 소멸자
     */
    ~StatisticalArbitrageAnalyzer() {
        Print(log_prefix, "통계적 차익거래 분석기 정리 완료");
    }
    
    /**
     * 분석기 초기화
     */
    void InitializeAnalyzer() {
        data_points = 0;
        ma_index = 0;
        total_signals = 0;
        profitable_signals = 0;
        total_pnl = 0.0;
        last_signal_time = 0;
        
        // 배열 초기화
        ArrayInitialize(price_A_history, 0.0);
        ArrayInitialize(price_B_history, 0.0);
        ArrayInitialize(spread_history, 0.0);
        ArrayInitialize(spread_ma_values, 0.0);
        ArrayInitialize(zscore_history, 0.0);
        
        // 칼만 필터 초기화
        kalman_state.is_initialized = false;
        kalman_state.state_mean = 0.0;
        kalman_state.state_covariance = 1.0;
        kalman_state.observation_covariance = config.kalman_ve;
        kalman_state.process_covariance = config.kalman_delta;
        
        ResetPairStatistics();
    }
    
    /**
     * 페어 데이터 업데이트
     */
    void UpdatePairData() {
        // 현재 가격 가져오기
        double price_A = iClose(config.symbol_A, PERIOD_CURRENT, 0);
        double price_B = iClose(config.symbol_B, PERIOD_CURRENT, 0);
        
        if (price_A <= 0 || price_B <= 0) {
            Print(log_prefix, "가격 데이터 오류: A=", price_A, ", B=", price_B);
            return;
        }
        
        // 데이터 히스토리 업데이트
        if (data_points < 500) {
            price_A_history[data_points] = price_A;
            price_B_history[data_points] = price_B;
            data_points++;
        } else {
            // 배열 시프트
            for (int i = 0; i < 499; i++) {
                price_A_history[i] = price_A_history[i + 1];
                price_B_history[i] = price_B_history[i + 1];
                spread_history[i] = spread_history[i + 1];
            }
            price_A_history[499] = price_A;
            price_B_history[499] = price_B;
        }
        
        // 헤지 비율 업데이트
        if (config.auto_hedge_ratio && data_points > 50) {
            UpdateHedgeRatio();
        }
        
        // 스프레드 계산 및 분석
        CalculateSpread();
        AnalyzeCointegration();
        UpdateKalmanFilter(price_A, price_B);
        
        pair_stats.last_update = TimeCurrent();
    }
    
    /**
     * 차익거래 기회 분석
     */
    ArbitrageOpportunity AnalyzeArbitrageOpportunity() {
        ArbitrageOpportunity opportunity;
        opportunity.signal_type = ARB_SIGNAL_NONE;
        opportunity.opportunity_time = TimeCurrent();
        
        if (data_points < config.min_cointegration_period) {
            opportunity.confidence_level = 0.0;
            return opportunity;
        }
        
        // 현재 Z-Score 확인
        double current_zscore = pair_stats.current_zscore;
        
        // 공적분 관계 확인
        if (pair_stats.cointegration_pvalue > config.significance_level) {
            opportunity.confidence_level = 0.1; // 낮은 신뢰도
            return opportunity;
        }
        
        // 상관관계 확인
        if (MathAbs(pair_stats.correlation) < config.correlation_threshold) {
            opportunity.confidence_level = 0.2; // 낮은 신뢰도
            return opportunity;
        }
        
        // 신호 생성
        if (MathAbs(current_zscore) > config.entry_zscore_threshold) {
            if (current_zscore > 0) {
                // 스프레드가 높음 -> 페어 숏 (A 매도, B 매수)
                opportunity.signal_type = ARB_SIGNAL_SHORT_PAIR;
            } else {
                // 스프레드가 낮음 -> 페어 롱 (A 매수, B 매도)
                opportunity.signal_type = ARB_SIGNAL_LONG_PAIR;
            }
            
            // 기회 평가
            EvaluateOpportunity(opportunity, current_zscore);
        }
        // 청산 신호 확인
        else if (MathAbs(current_zscore) < config.exit_zscore_threshold) {
            // 평균 회귀 신호
            opportunity.signal_type = (current_zscore > 0) ? ARB_SIGNAL_CLOSE_SHORT : ARB_SIGNAL_CLOSE_LONG;
            opportunity.confidence_level = 0.8;
        }
        
        return opportunity;
    }
    
private:
    /**
     * 헤지 비율 업데이트
     */
    void UpdateHedgeRatio() {
        if (data_points < 30) return;
        
        // 선형 회귀를 통한 헤지 비율 계산
        double sum_x = 0, sum_y = 0, sum_xy = 0, sum_xx = 0;
        int n = MathMin(data_points, 100); // 최근 100개 데이터점 사용
        
        for (int i = data_points - n; i < data_points; i++) {
            double x = price_B_history[i];
            double y = price_A_history[i];
            
            sum_x += x;
            sum_y += y;
            sum_xy += x * y;
            sum_xx += x * x;
        }
        
        double beta = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x);
        
        if (beta > 0 && beta < 10) { // 합리적인 범위 내에서
            config.hedge_ratio = beta;
            pair_stats.hedge_ratio_estimate = beta;
        }
        
        Print(log_prefix, "헤지 비율 업데이트: ", DoubleToString(config.hedge_ratio, 4));
    }
    
    /**
     * 스프레드 계산
     */
    void CalculateSpread() {
        if (data_points < 2) return;
        
        int index = data_points - 1;
        double spread = price_A_history[index] - config.hedge_ratio * price_B_history[index];
        
        if (data_points < 500) {
            spread_history[index] = spread;
        } else {
            spread_history[499] = spread;
        }
        
        // 스프레드 이동평균 계산
        CalculateSpreadMovingAverage();
        
        // Z-Score 계산
        CalculateZScore();
    }
    
    /**
     * 스프레드 이동평균 계산
     */
    void CalculateSpreadMovingAverage() {
        if (data_points < config.spread_ma_period) return;
        
        double sum = 0.0;
        int start_index = MathMax(0, data_points - config.spread_ma_period);
        int count = 0;
        
        for (int i = start_index; i < data_points; i++) {
            sum += spread_history[i];
            count++;
        }
        
        if (count > 0) {
            pair_stats.spread_mean = sum / count;
        }
        
        // 표준편차 계산
        double sum_sq = 0.0;
        for (int i = start_index; i < data_points; i++) {
            double diff = spread_history[i] - pair_stats.spread_mean;
            sum_sq += diff * diff;
        }
        
        if (count > 1) {
            pair_stats.spread_std = MathSqrt(sum_sq / (count - 1));
        }
    }
    
    /**
     * Z-Score 계산
     */
    void CalculateZScore() {
        if (data_points < 1 || pair_stats.spread_std <= 0) return;
        
        int current_index = data_points - 1;
        double current_spread = spread_history[current_index];
        
        pair_stats.current_zscore = (current_spread - pair_stats.spread_mean) / pair_stats.spread_std;
        
        // Z-Score 히스토리 업데이트
        if (ma_index < 100) {
            zscore_history[ma_index] = pair_stats.current_zscore;
            ma_index++;
        } else {
            for (int i = 0; i < 99; i++) {
                zscore_history[i] = zscore_history[i + 1];
            }
            zscore_history[99] = pair_stats.current_zscore;
        }
    }
    
    /**
     * 공적분 분석
     */
    void AnalyzeCointegration() {
        if (data_points < config.min_cointegration_period) return;
        
        // 상관계수 계산
        CalculateCorrelation();
        
        // 간단한 공적분 테스트 (ADF 테스트 간소화 버전)
        pair_stats.cointegration_pvalue = PerformSimpleCointegrationTest();
        
        // 페어 상태 업데이트
        UpdatePairState();
    }
    
    /**
     * 상관계수 계산
     */
    void CalculateCorrelation() {
        if (data_points < 30) return;
        
        int n = MathMin(data_points, config.lookback_period);
        double sum_x = 0, sum_y = 0, sum_xy = 0, sum_xx = 0, sum_yy = 0;
        
        for (int i = data_points - n; i < data_points; i++) {
            double x = price_A_history[i];
            double y = price_B_history[i];
            
            sum_x += x;
            sum_y += y;
            sum_xy += x * y;
            sum_xx += x * x;
            sum_yy += y * y;
        }
        
        double mean_x = sum_x / n;
        double mean_y = sum_y / n;
        
        double numerator = sum_xy - n * mean_x * mean_y;
        double denominator = MathSqrt((sum_xx - n * mean_x * mean_x) * (sum_yy - n * mean_y * mean_y));
        
        if (denominator > 0) {
            pair_stats.correlation = numerator / denominator;
        }
    }
    
    /**
     * 간단한 공적분 테스트
     */
    double PerformSimpleCointegrationTest() {
        if (data_points < 50) return 1.0;
        
        // 스프레드의 평균 회귀 정도를 측정
        double autocorr = CalculateSpreadAutocorrelation(1);
        
        // 간소화된 p-value 계산 (실제 ADF 테스트보다 단순함)
        double pvalue = 1.0 - MathAbs(autocorr);
        
        return MathMax(0.0, MathMin(1.0, pvalue));
    }
    
    /**
     * 스프레드 자기상관 계산
     */
    double CalculateSpreadAutocorrelation(int lag) {
        if (data_points < lag + 20) return 0.0;
        
        int n = data_points - lag;
        double sum_x = 0, sum_y = 0, sum_xy = 0, sum_xx = 0, sum_yy = 0;
        
        for (int i = lag; i < data_points; i++) {
            double x = spread_history[i - lag];
            double y = spread_history[i];
            
            sum_x += x;
            sum_y += y;
            sum_xy += x * y;
            sum_xx += x * x;
            sum_yy += y * y;
        }
        
        double mean_x = sum_x / n;
        double mean_y = sum_y / n;
        
        double numerator = sum_xy - n * mean_x * mean_y;
        double denominator = MathSqrt((sum_xx - n * mean_x * mean_x) * (sum_yy - n * mean_y * mean_y));
        
        return (denominator > 0) ? numerator / denominator : 0.0;
    }
    
    /**
     * 칼만 필터 업데이트
     */
    void UpdateKalmanFilter(double price_A, double price_B) {
        if (config.coint_method != COINT_METHOD_KALMAN_FILTER) return;
        
        if (!kalman_state.is_initialized) {
            kalman_state.state_mean = price_A / price_B;
            kalman_state.is_initialized = true;
            return;
        }
        
        // 예측 단계
        double predicted_state = kalman_state.state_mean;
        double predicted_covariance = kalman_state.state_covariance + kalman_state.process_covariance;
        
        // 업데이트 단계
        double observation = price_A / price_B;
        double innovation = observation - predicted_state;
        double innovation_covariance = predicted_covariance + kalman_state.observation_covariance;
        double kalman_gain = predicted_covariance / innovation_covariance;
        
        kalman_state.state_mean = predicted_state + kalman_gain * innovation;
        kalman_state.state_covariance = (1 - kalman_gain) * predicted_covariance;
        
        // 헤지 비율 업데이트 (칼만 필터 방식)
        if (config.auto_hedge_ratio) {
            config.hedge_ratio = kalman_state.state_mean;
        }
    }
    
    /**
     * 페어 상태 업데이트
     */
    void UpdatePairState() {
        if (pair_stats.cointegration_pvalue < config.significance_level) {
            if (MathAbs(pair_stats.current_zscore) > config.entry_zscore_threshold) {
                // 발산 상태
            } else {
                // 안정 상태
                pair_stats.stable_periods++;
            }
        } else {
            pair_stats.stable_periods = 0;
        }
    }
    
    /**
     * 기회 평가
     */
    void EvaluateOpportunity(ArbitrageOpportunity &opportunity, double zscore) {
        // 기대 수익 계산
        double mean_reversion_potential = MathAbs(zscore) * pair_stats.spread_std;
        opportunity.expected_profit = mean_reversion_potential * 0.5; // 50% 수렴 가정
        
        // 신뢰도 계산
        double zscore_strength = MathMin(MathAbs(zscore) / 3.0, 1.0); // 3시그마 기준
        double correlation_strength = MathAbs(pair_stats.correlation);
        double cointegration_strength = 1.0 - pair_stats.cointegration_pvalue;
        
        opportunity.confidence_level = (zscore_strength + correlation_strength + cointegration_strength) / 3.0;
        
        // 리스크 레벨
        opportunity.risk_level = 1.0 - opportunity.confidence_level;
        
        // 최적 포지션 크기 계산
        CalculateOptimalPositionSize(opportunity);
        
        // 예상 보유 기간
        opportunity.holding_period_estimate = EstimateHoldingPeriod(zscore);
    }
    
    /**
     * 최적 포지션 크기 계산
     */
    void CalculateOptimalPositionSize(ArbitrageOpportunity &opportunity) {
        double price_A = iClose(config.symbol_A, PERIOD_CURRENT, 0);
        double price_B = iClose(config.symbol_B, PERIOD_CURRENT, 0);
        
        opportunity.symbol_A_price = price_A;
        opportunity.symbol_B_price = price_B;
        
        // 기본 포지션 크기
        double base_lot = config.max_position_size * opportunity.confidence_level;
        
        if (opportunity.signal_type == ARB_SIGNAL_LONG_PAIR) {
            opportunity.optimal_lot_A = base_lot;
            opportunity.optimal_lot_B = -base_lot * config.hedge_ratio;
        } else if (opportunity.signal_type == ARB_SIGNAL_SHORT_PAIR) {
            opportunity.optimal_lot_A = -base_lot;
            opportunity.optimal_lot_B = base_lot * config.hedge_ratio;
        }
    }
    
    /**
     * 보유 기간 추정
     */
    int EstimateHoldingPeriod(double zscore) {
        // 평균 회귀 속도 기반 추정
        double reversion_speed = MathAbs(CalculateSpreadAutocorrelation(1));
        
        if (reversion_speed > 0) {
            return (int)(MathAbs(zscore) / reversion_speed * 10); // 단위: 봉
        }
        
        return config.max_holding_period / 2; // 기본값
    }
    
    /**
     * 통계 초기화
     */
    void ResetStatistics() {
        total_signals = 0;
        profitable_signals = 0;
        total_pnl = 0.0;
        last_signal_time = 0;
    }
    
    /**
     * 페어 통계 초기화
     */
    void ResetPairStatistics() {
        pair_stats.correlation = 0.0;
        pair_stats.cointegration_pvalue = 1.0;
        pair_stats.spread_mean = 0.0;
        pair_stats.spread_std = 0.0;
        pair_stats.current_zscore = 0.0;
        pair_stats.hedge_ratio_estimate = config.hedge_ratio;
        pair_stats.last_update = 0;
        pair_stats.stable_periods = 0;
    }

public:
    /**
     * 페어 통계 반환
     */
    PairStatistics GetPairStatistics() {
        return pair_stats;
    }
    
    /**
     * 차익거래 분석 정보
     */
    string GetArbitrageAnalysisInfo() {
        string info = "";
        info += "=== 통계적 차익거래 분석 ===\n";
        info += "페어: " + config.symbol_A + "/" + config.symbol_B + "\n";
        info += "헤지비율: " + DoubleToString(config.hedge_ratio, 4) + "\n";
        info += "상관계수: " + DoubleToString(pair_stats.correlation, 3) + "\n";
        info += "공적분 p값: " + DoubleToString(pair_stats.cointegration_pvalue, 4) + "\n";
        info += "현재 Z-Score: " + DoubleToString(pair_stats.current_zscore, 3) + "\n";
        info += "스프레드 평균: " + DoubleToString(pair_stats.spread_mean, 5) + "\n";
        info += "스프레드 표준편차: " + DoubleToString(pair_stats.spread_std, 5) + "\n";
        info += "데이터 포인트: " + IntegerToString(data_points) + "\n";
        info += "안정 기간: " + IntegerToString(pair_stats.stable_periods) + "\n";
        info += "=====================================\n";
        return info;
    }
    
    /**
     * 성과 통계 업데이트
     */
    void UpdatePerformanceStats(double pnl, bool is_profitable) {
        total_signals++;
        total_pnl += pnl;
        
        if (is_profitable) {
            profitable_signals++;
        }
        
        last_signal_time = TimeCurrent();
    }
    
    /**
     * 성과 정보 반환
     */
    string GetPerformanceInfo() {
        double win_rate = (total_signals > 0) ? (double)profitable_signals / total_signals * 100 : 0;
        
        string info = "";
        info += "=== 차익거래 성과 ===\n";
        info += "총 신호: " + IntegerToString(total_signals) + "\n";
        info += "승률: " + DoubleToString(win_rate, 1) + "%\n";
        info += "총 손익: " + DoubleToString(total_pnl, 2) + "\n";
        info += "마지막 신호: " + TimeToString(last_signal_time) + "\n";
        info += "========================\n";
        return info;
    }
};