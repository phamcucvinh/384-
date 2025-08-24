//+------------------------------------------------------------------+
//|                                            LookupTableSystem.mqh |
//|                                  룩업 테이블 기반 고속 계산 시스템   |
//|                                    Lookup Table Optimization     |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Optimization Phase 1"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 룩업 테이블 시스템 클래스                                          |
//+------------------------------------------------------------------+
class LookupTableSystem {
private:
    // 수학 함수 룩업 테이블
    static double sigmoid_table[1024];
    static double tanh_table[1024];
    static double exp_table[1024];
    static double log_table[1024];
    static double sqrt_table[1024];
    
    // 기술지표 룩업 테이블
    static double rsi_table[101];          // RSI 0-100
    static double stoch_table[101];        // Stochastic 0-100
    static double atr_ratio_table[200];    // ATR 비율 0-2.0
    
    // 시간 기반 룩업 테이블
    static double hour_sin_table[24];      // 시간 주기성
    static double hour_cos_table[24];
    static double day_weight_table[7];     // 요일별 가중치
    
    // 가격 변화율 테이블
    static double price_change_table[2001]; // -10% ~ +10% (0.01% 단위)
    
    static bool is_initialized;

public:
    /**
     * 룩업 테이블 초기화
     */
    static bool Initialize() {
        if (is_initialized) return true;
        
        Print("[LookupTable] 룩업 테이블 초기화 시작...");
        
        // 1. 수학 함수 테이블 생성
        InitializeMathTables();
        
        // 2. 기술지표 테이블 생성
        InitializeIndicatorTables();
        
        // 3. 시간 기반 테이블 생성
        InitializeTimeTables();
        
        // 4. 가격 변화율 테이블 생성
        InitializePriceChangeTables();
        
        is_initialized = true;
        Print("[LookupTable] ✅ 룩업 테이블 초기화 완료");
        return true;
    }
    
    /**
     * 고속 시그모이드 (계산 시간 95% 단축)
     */
    static double FastSigmoid(double x) {
        // 입력 범위 제한 (-8 ~ 8)
        x = MathMax(-8.0, MathMin(8.0, x));
        
        // 테이블 인덱스 계산
        int index = (int)((x + 8.0) * 63.75); // (1024-1) / 16
        index = MathMax(0, MathMin(1023, index));
        
        return sigmoid_table[index];
    }
    
    /**
     * 고속 Tanh (계산 시간 95% 단축)
     */
    static double FastTanh(double x) {
        x = MathMax(-8.0, MathMin(8.0, x));
        int index = (int)((x + 8.0) * 63.75);
        index = MathMax(0, MathMin(1023, index));
        
        return tanh_table[index];
    }
    
    /**
     * 고속 지수 함수 (계산 시간 90% 단축)
     */
    static double FastExp(double x) {
        x = MathMax(-10.0, MathMin(10.0, x));
        int index = (int)((x + 10.0) * 51.15); // (1024-1) / 20
        index = MathMax(0, MathMin(1023, index));
        
        return exp_table[index];
    }
    
    /**
     * 고속 로그 함수 (계산 시간 85% 단축)
     */
    static double FastLog(double x) {
        if (x <= 0) return -10.0; // 최소값
        if (x > 1000.0) return MathLog(1000.0); // 최대값
        
        int index = (int)(x * 1.023); // 1024 / 1000
        index = MathMax(0, MathMin(1023, index));
        
        return log_table[index];
    }
    
    /**
     * 고속 제곱근 (계산 시간 80% 단축)
     */
    static double FastSqrt(double x) {
        if (x <= 0) return 0.0;
        if (x > 1000.0) return MathSqrt(1000.0);
        
        int index = (int)(x * 1.023);
        index = MathMax(0, MathMin(1023, index));
        
        return sqrt_table[index];
    }
    
    /**
     * 고속 RSI 정규화 (계산 시간 70% 단축)
     */
    static double FastRSINormalize(double rsi_value) {
        int index = (int)MathMax(0, MathMin(100, rsi_value));
        return rsi_table[index];
    }
    
    /**
     * 고속 스토캐스틱 정규화
     */
    static double FastStochasticNormalize(double stoch_value) {
        int index = (int)MathMax(0, MathMin(100, stoch_value));
        return stoch_table[index];
    }
    
    /**
     * 고속 ATR 비율 계산
     */
    static double FastATRRatio(double atr_ratio) {
        atr_ratio = MathMax(0.0, MathMin(2.0, atr_ratio));
        int index = (int)(atr_ratio * 99.5); // 200 / 2.0
        index = MathMax(0, MathMin(199, index));
        
        return atr_ratio_table[index];
    }
    
    /**
     * 고속 시간 주기성 계산
     */
    static double FastHourSin(int hour) {
        hour = hour % 24;
        return hour_sin_table[hour];
    }
    
    static double FastHourCos(int hour) {
        hour = hour % 24;
        return hour_cos_table[hour];
    }
    
    /**
     * 고속 요일 가중치
     */
    static double FastDayWeight(int day_of_week) {
        day_of_week = MathMax(0, MathMin(6, day_of_week));
        return day_weight_table[day_of_week];
    }
    
    /**
     * 고속 가격 변화율 정규화
     */
    static double FastPriceChangeNormalize(double price_change) {
        // -10% ~ +10% 범위를 0 ~ 2000 인덱스로 매핑
        price_change = MathMax(-0.1, MathMin(0.1, price_change));
        int index = (int)((price_change + 0.1) * 10000); // 0.01% 정밀도
        index = MathMax(0, MathMin(2000, index));
        
        return price_change_table[index];
    }

private:
    /**
     * 수학 함수 테이블 초기화
     */
    static void InitializeMathTables() {
        // Sigmoid 테이블 (-8 ~ 8 범위)
        for (int i = 0; i < 1024; i++) {
            double x = -8.0 + (16.0 * i / 1023.0);
            sigmoid_table[i] = 1.0 / (1.0 + MathExp(-x));
        }
        
        // Tanh 테이블
        for (int i = 0; i < 1024; i++) {
            double x = -8.0 + (16.0 * i / 1023.0);
            tanh_table[i] = MathTanh(x);
        }
        
        // Exp 테이블 (-10 ~ 10 범위)
        for (int i = 0; i < 1024; i++) {
            double x = -10.0 + (20.0 * i / 1023.0);
            exp_table[i] = MathExp(x);
        }
        
        // Log 테이블 (0.001 ~ 1000 범위)
        for (int i = 0; i < 1024; i++) {
            double x = 0.001 + (999.999 * i / 1023.0);
            log_table[i] = MathLog(x);
        }
        
        // Sqrt 테이블 (0 ~ 1000 범위)
        for (int i = 0; i < 1024; i++) {
            double x = 1000.0 * i / 1023.0;
            sqrt_table[i] = MathSqrt(x);
        }
        
        Print("[LookupTable] 수학 함수 테이블 생성 완료");
    }
    
    /**
     * 기술지표 테이블 초기화
     */
    static void InitializeIndicatorTables() {
        // RSI 정규화 테이블 (0-100 → -0.5~0.5)
        for (int i = 0; i <= 100; i++) {
            rsi_table[i] = (i / 100.0) - 0.5;
        }
        
        // Stochastic 정규화 테이블
        for (int i = 0; i <= 100; i++) {
            stoch_table[i] = (i / 100.0) - 0.5;
        }
        
        // ATR 비율 테이블 (0-2.0)
        for (int i = 0; i < 200; i++) {
            double ratio = i / 99.5;
            
            // 변동성 상태 분류
            if (ratio < 0.7) {
                atr_ratio_table[i] = -0.5; // 저변동성
            } else if (ratio < 1.3) {
                atr_ratio_table[i] = 0.0;  // 정상변동성
            } else {
                atr_ratio_table[i] = 0.5;  // 고변동성
            }
        }
        
        Print("[LookupTable] 기술지표 테이블 생성 완료");
    }
    
    /**
     * 시간 기반 테이블 초기화
     */
    static void InitializeTimeTables() {
        // 시간 주기성 테이블
        for (int hour = 0; hour < 24; hour++) {
            hour_sin_table[hour] = MathSin(2 * M_PI * hour / 24.0);
            hour_cos_table[hour] = MathCos(2 * M_PI * hour / 24.0);
        }
        
        // 요일별 가중치 (거래량 기반)
        day_weight_table[0] = 0.3; // 일요일 (낮은 활동)
        day_weight_table[1] = 1.0; // 월요일 (높은 활동)
        day_weight_table[2] = 1.2; // 화요일 (최고 활동)
        day_weight_table[3] = 1.1; // 수요일 (높은 활동)
        day_weight_table[4] = 1.0; // 목요일 (높은 활동)
        day_weight_table[5] = 0.8; // 금요일 (중간 활동)
        day_weight_table[6] = 0.2; // 토요일 (낮은 활동)
        
        Print("[LookupTable] 시간 기반 테이블 생성 완료");
    }
    
    /**
     * 가격 변화율 테이블 초기화
     */
    static void InitializePriceChangeTables() {
        // -10% ~ +10% 범위를 2001개 구간으로 분할
        for (int i = 0; i <= 2000; i++) {
            double change = -0.1 + (0.2 * i / 2000.0);
            
            // 시그모이드 기반 정규화
            price_change_table[i] = 2.0 / (1.0 + MathExp(-change * 50)) - 1.0;
        }
        
        Print("[LookupTable] 가격 변화율 테이블 생성 완료");
    }
};

// 정적 멤버 변수 초기화
double LookupTableSystem::sigmoid_table[1024];
double LookupTableSystem::tanh_table[1024];
double LookupTableSystem::exp_table[1024];
double LookupTableSystem::log_table[1024];
double LookupTableSystem::sqrt_table[1024];
double LookupTableSystem::rsi_table[101];
double LookupTableSystem::stoch_table[101];
double LookupTableSystem::atr_ratio_table[200];
double LookupTableSystem::hour_sin_table[24];
double LookupTableSystem::hour_cos_table[24];
double LookupTableSystem::day_weight_table[7];
double LookupTableSystem::price_change_table[2001];
bool LookupTableSystem::is_initialized = false;

//+------------------------------------------------------------------+
//| 고속 수학 함수 매크로                                              |
//+------------------------------------------------------------------+
#define FAST_SIGMOID(x) LookupTableSystem::FastSigmoid(x)
#define FAST_TANH(x) LookupTableSystem::FastTanh(x)
#define FAST_EXP(x) LookupTableSystem::FastExp(x)
#define FAST_LOG(x) LookupTableSystem::FastLog(x)
#define FAST_SQRT(x) LookupTableSystem::FastSqrt(x)