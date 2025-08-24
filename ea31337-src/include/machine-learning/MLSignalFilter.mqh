//+------------------------------------------------------------------+
//|                                              MLSignalFilter.mqh |
//|                                    머신러닝 신호 필터링 시스템     |
//|                                   Machine Learning Signal Filter |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System ML Edition"
#property version   "1.00"

//+------------------------------------------------------------------+
//| 머신러닝 모델 타입 열거형                                          |
//+------------------------------------------------------------------+
enum ENUM_ML_MODEL_TYPE {
    ML_MODEL_NEURAL_NETWORK = 0,    // 신경망
    ML_MODEL_SVM,                   // 서포트 벡터 머신
    ML_MODEL_DECISION_TREE,         // 의사결정 트리
    ML_MODEL_LINEAR_REGRESSION,     // 선형 회귀
    ML_MODEL_LOGISTIC_REGRESSION,   // 로지스틱 회귀
    ML_MODEL_ENSEMBLE              // 앙상블 모델
};

//+------------------------------------------------------------------+
//| 신호 강도 열거형                                                  |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_STRENGTH {
    SIGNAL_VERY_WEAK = 0,    // 매우 약함
    SIGNAL_WEAK,             // 약함
    SIGNAL_MODERATE,         // 보통
    SIGNAL_STRONG,           // 강함
    SIGNAL_VERY_STRONG       // 매우 강함
};

//+------------------------------------------------------------------+
//| 머신러닝 필터 상태                                                |
//+------------------------------------------------------------------+
enum ENUM_ML_FILTER_STATE {
    ML_FILTER_NONE = 0,      // 필터 없음
    ML_FILTER_BULL_STRONG,   // 강한 상승 신호
    ML_FILTER_BULL_WEAK,     // 약한 상승 신호
    ML_FILTER_NEUTRAL,       // 중립
    ML_FILTER_BEAR_WEAK,     // 약한 하락 신호
    ML_FILTER_BEAR_STRONG    // 강한 하락 신호
};

//+------------------------------------------------------------------+
//| 머신러닝 설정 구조체                                              |
//+------------------------------------------------------------------+
struct MLFilterConfig {
    // 모델 설정
    ENUM_ML_MODEL_TYPE primary_model;      // 주 모델 타입
    ENUM_ML_MODEL_TYPE secondary_model;    // 보조 모델 타입
    bool use_ensemble;                     // 앙상블 모델 사용
    
    // 신경망 설정
    int nn_hidden_layers;                  // 은닉층 수
    int nn_neurons_per_layer;              // 층당 뉴런 수
    double nn_learning_rate;               // 학습률
    int nn_training_epochs;                // 훈련 에포크
    
    // 데이터 설정
    int feature_window;                    // 특성 윈도우 크기
    int prediction_horizon;                // 예측 범위
    double confidence_threshold;           // 신뢰도 임계값
    int min_training_samples;              // 최소 훈련 샘플
    
    // 필터 설정
    bool enable_trend_filter;              // 트렌드 필터 활성화
    bool enable_volatility_filter;         // 변동성 필터 활성화
    bool enable_momentum_filter;           // 모멘텀 필터 활성화
    double filter_sensitivity;             // 필터 민감도
    
    // 성능 설정
    int retrain_frequency;                 // 재훈련 빈도 (시간)
    double accuracy_threshold;             // 정확도 임계값
    bool adaptive_threshold;               // 적응형 임계값
};

//+------------------------------------------------------------------+
//| 특성 벡터 구조체                                                  |
//+------------------------------------------------------------------+
struct FeatureVector {
    double features[20];                   // 특성 배열
    int feature_count;                     // 특성 개수
    datetime timestamp;                    // 타임스탬프
    double normalized_features[20];        // 정규화된 특성
};

//+------------------------------------------------------------------+
//| 예측 결과 구조체                                                  |
//+------------------------------------------------------------------+
struct MLPrediction {
    double probability_up;                 // 상승 확률
    double probability_down;               // 하락 확률
    ENUM_SIGNAL_STRENGTH signal_strength;  // 신호 강도
    ENUM_ML_FILTER_STATE filter_state;     // 필터 상태
    double confidence_score;               // 신뢰도 점수
    datetime prediction_time;              // 예측 시간
    int model_version;                     // 모델 버전
};

//+------------------------------------------------------------------+
//| 머신러닝 모델 통계                                                |
//+------------------------------------------------------------------+
struct MLModelStats {
    double accuracy;                       // 정확도
    double precision;                      // 정밀도
    double recall;                         // 재현율
    double f1_score;                      // F1 점수
    int total_predictions;                 // 총 예측 수
    int correct_predictions;               // 정확한 예측 수
    datetime last_training_time;           // 마지막 훈련 시간
    double training_loss;                  // 훈련 손실
};

//+------------------------------------------------------------------+
//| 머신러닝 신호 필터 클래스                                         |
//+------------------------------------------------------------------+
class MLSignalFilter {
private:
    MLFilterConfig config;
    MLModelStats model_stats;
    string symbol;
    ENUM_TIMEFRAMES timeframe;
    
    // 특성 추출 관련
    double feature_means[20];
    double feature_stds[20];
    bool is_trained;
    
    // 모델 가중치 (간단한 신경망)
    double input_weights[20][10];          // 입력-은닉층 가중치
    double hidden_weights[10][3];          // 은닉층-출력 가중치
    double hidden_bias[10];                // 은닉층 편향
    double output_bias[3];                 // 출력층 편향
    
    // 훈련 데이터
    FeatureVector training_features[1000]; // 훈련 특성
    double training_labels[1000];          // 훈련 라벨
    int training_samples;                  // 훈련 샘플 수
    
    // 성능 추적
    double recent_predictions[100];        // 최근 예측
    double recent_actual[100];             // 최근 실제값
    int prediction_index;                  // 예측 인덱스
    
public:
    /**
     * 생성자
     */
    MLSignalFilter(MLFilterConfig &_config, string _symbol, ENUM_TIMEFRAMES _tf) {
        config = _config;
        symbol = _symbol;
        timeframe = _tf;
        is_trained = false;
        training_samples = 0;
        prediction_index = 0;
        
        InitializeModel();
        ResetStatistics();
        
        Print("[MLSignalFilter] 머신러닝 신호 필터 초기화 완료 - ", symbol, " ", EnumToString(timeframe));
    }
    
    /**
     * 소멸자
     */
    ~MLSignalFilter() {
        Print("[MLSignalFilter] 머신러닝 필터 정리 완료");
    }
    
    /**
     * 모델 초기화
     */
    void InitializeModel() {
        // 가중치 랜덤 초기화
        for (int i = 0; i < 20; i++) {
            for (int j = 0; j < 10; j++) {
                input_weights[i][j] = (MathRand() / 32767.0 - 0.5) * 0.5;
            }
        }
        
        for (int i = 0; i < 10; i++) {
            for (int j = 0; j < 3; j++) {
                hidden_weights[i][j] = (MathRand() / 32767.0 - 0.5) * 0.5;
            }
            hidden_bias[i] = (MathRand() / 32767.0 - 0.5) * 0.1;
        }
        
        for (int i = 0; i < 3; i++) {
            output_bias[i] = (MathRand() / 32767.0 - 0.5) * 0.1;
        }
        
        // 특성 정규화 파라미터 초기화
        ArrayInitialize(feature_means, 0.0);
        ArrayInitialize(feature_stds, 1.0);
    }
    
    /**
     * 특성 벡터 추출
     */
    FeatureVector ExtractFeatures(int shift = 0) {
        FeatureVector features;
        features.feature_count = 15;
        features.timestamp = iTime(symbol, timeframe, shift);
        
        // 가격 관련 특성
        features.features[0] = (iClose(symbol, timeframe, shift) - iOpen(symbol, timeframe, shift)) / iClose(symbol, timeframe, shift); // 캔들 변화율
        features.features[1] = (iHigh(symbol, timeframe, shift) - iLow(symbol, timeframe, shift)) / iClose(symbol, timeframe, shift);   // 변동폭
        features.features[2] = (iClose(symbol, timeframe, shift) - iClose(symbol, timeframe, shift + 1)) / iClose(symbol, timeframe, shift + 1); // 전봉 대비 변화
        
        // 이동평균 관련 특성
        double ma5 = iMA(symbol, timeframe, 5, 0, MODE_SMA, PRICE_CLOSE, shift);
        double ma20 = iMA(symbol, timeframe, 20, 0, MODE_SMA, PRICE_CLOSE, shift);
        double ma50 = iMA(symbol, timeframe, 50, 0, MODE_SMA, PRICE_CLOSE, shift);
        
        features.features[3] = (iClose(symbol, timeframe, shift) - ma5) / ma5;     // MA5 대비 위치
        features.features[4] = (iClose(symbol, timeframe, shift) - ma20) / ma20;   // MA20 대비 위치
        features.features[5] = (ma5 - ma20) / ma20;                               // MA5-MA20 교차
        features.features[6] = (ma20 - ma50) / ma50;                              // MA20-MA50 교차
        
        // 오실레이터 특성
        features.features[7] = iRSI(symbol, timeframe, 14, PRICE_CLOSE, shift) / 100.0 - 0.5; // RSI 중심화
        features.features[8] = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, shift);   // MACD
        features.features[9] = iStochastic(symbol, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, shift) / 100.0 - 0.5; // 스토캐스틱
        
        // 볼륨 및 변동성 특성
        features.features[10] = iVolume(symbol, timeframe, shift) / 1000.0;       // 볼륨 (정규화)
        features.features[11] = iATR(symbol, timeframe, 14, shift) / iClose(symbol, timeframe, shift); // ATR 비율
        
        // 시간 관련 특성
        datetime current_time = iTime(symbol, timeframe, shift);
        int hour = TimeHour(current_time);
        int day_of_week = TimeDayOfWeek(current_time);
        
        features.features[12] = MathSin(2 * M_PI * hour / 24.0);                  // 시간 주기성
        features.features[13] = MathCos(2 * M_PI * hour / 24.0);                  // 시간 주기성
        features.features[14] = (day_of_week - 1) / 5.0 - 0.5;                   // 요일 정규화
        
        // 특성 정규화
        if (is_trained) {
            for (int i = 0; i < features.feature_count; i++) {
                features.normalized_features[i] = (features.features[i] - feature_means[i]) / MathMax(feature_stds[i], 0.001);
            }
        } else {
            ArrayCopy(features.normalized_features, features.features);
        }
        
        return features;
    }
    
    /**
     * 신호 필터링
     */
    MLPrediction FilterSignal(ENUM_ORDER_TYPE order_type, double base_signal_strength = 1.0) {
        MLPrediction prediction;
        prediction.prediction_time = TimeCurrent();
        prediction.model_version = 1;
        
        // 현재 특성 추출
        FeatureVector current_features = ExtractFeatures(0);
        
        if (!is_trained) {
            // 모델이 훈련되지 않은 경우 중립 반환
            prediction.probability_up = 0.5;
            prediction.probability_down = 0.5;
            prediction.signal_strength = SIGNAL_MODERATE;
            prediction.filter_state = ML_FILTER_NEUTRAL;
            prediction.confidence_score = 0.5;
            return prediction;
        }
        
        // 신경망 순전파
        double[] probabilities = ForwardPass(current_features.normalized_features);
        
        prediction.probability_up = probabilities[1];        // 상승 확률
        prediction.probability_down = probabilities[2];      // 하락 확률
        double neutral_prob = probabilities[0];              // 중립 확률
        
        // 신호 강도 계산
        double max_prob = MathMax(prediction.probability_up, prediction.probability_down);
        prediction.confidence_score = max_prob;
        
        if (max_prob > 0.8) {
            prediction.signal_strength = SIGNAL_VERY_STRONG;
        } else if (max_prob > 0.7) {
            prediction.signal_strength = SIGNAL_STRONG;
        } else if (max_prob > 0.6) {
            prediction.signal_strength = SIGNAL_MODERATE;
        } else if (max_prob > 0.55) {
            prediction.signal_strength = SIGNAL_WEAK;
        } else {
            prediction.signal_strength = SIGNAL_VERY_WEAK;
        }
        
        // 필터 상태 결정
        double signal_bias = prediction.probability_up - prediction.probability_down;
        
        if (signal_bias > 0.3) {
            prediction.filter_state = ML_FILTER_BULL_STRONG;
        } else if (signal_bias > 0.1) {
            prediction.filter_state = ML_FILTER_BULL_WEAK;
        } else if (signal_bias < -0.3) {
            prediction.filter_state = ML_FILTER_BEAR_STRONG;
        } else if (signal_bias < -0.1) {
            prediction.filter_state = ML_FILTER_BEAR_WEAK;
        } else {
            prediction.filter_state = ML_FILTER_NEUTRAL;
        }
        
        return prediction;
    }
    
    /**
     * 모델 훈련 데이터 추가
     */
    void AddTrainingData(int bars_back = 100) {
        if (training_samples >= 1000) return; // 최대 샘플 수 제한
        
        for (int i = bars_back; i > config.prediction_horizon; i--) {
            if (training_samples >= 1000) break;
            
            FeatureVector features = ExtractFeatures(i);
            
            // 라벨 생성 (미래 가격 변화)
            double current_price = iClose(symbol, timeframe, i);
            double future_price = iClose(symbol, timeframe, i - config.prediction_horizon);
            double price_change = (future_price - current_price) / current_price;
            
            // 라벨 분류 (-1: 하락, 0: 중립, 1: 상승)
            double label;
            if (price_change > 0.001) {
                label = 1.0; // 상승
            } else if (price_change < -0.001) {
                label = -1.0; // 하락
            } else {
                label = 0.0; // 중립
            }
            
            training_features[training_samples] = features;
            training_labels[training_samples] = label;
            training_samples++;
        }
        
        Print("[MLSignalFilter] 훈련 데이터 추가 완료: ", training_samples, " 샘플");
    }
    
    /**
     * 모델 훈련
     */
    bool TrainModel() {
        if (training_samples < config.min_training_samples) {
            Print("[MLSignalFilter] 훈련 데이터 부족: ", training_samples, "/", config.min_training_samples);
            return false;
        }
        
        Print("[MLSignalFilter] 모델 훈련 시작...");
        
        // 특성 정규화 파라미터 계산
        CalculateNormalizationParams();
        
        // 경사 하강법으로 훈련
        double learning_rate = config.nn_learning_rate;
        int epochs = config.nn_training_epochs;
        
        for (int epoch = 0; epoch < epochs; epoch++) {
            double total_loss = 0.0;
            
            for (int sample = 0; sample < training_samples; sample++) {
                // 순전파
                double[] outputs = ForwardPass(training_features[sample].normalized_features);
                
                // 목표값 설정
                double[] targets = {0.0, 0.0, 0.0};
                if (training_labels[sample] > 0.5) {
                    targets[1] = 1.0; // 상승
                } else if (training_labels[sample] < -0.5) {
                    targets[2] = 1.0; // 하락
                } else {
                    targets[0] = 1.0; // 중립
                }
                
                // 손실 계산
                for (int i = 0; i < 3; i++) {
                    total_loss += MathPow(outputs[i] - targets[i], 2);
                }
                
                // 역전파 (간소화된 버전)
                BackPropagation(training_features[sample].normalized_features, targets, learning_rate);
            }
            
            if (epoch % 10 == 0) {
                Print("[MLSignalFilter] 에포크 ", epoch, ", 손실: ", DoubleToString(total_loss / training_samples, 6));
            }
        }
        
        is_trained = true;
        model_stats.last_training_time = TimeCurrent();
        
        // 모델 성능 평가
        EvaluateModel();
        
        Print("[MLSignalFilter] 모델 훈련 완료. 정확도: ", DoubleToString(model_stats.accuracy * 100, 2), "%");
        return true;
    }
    
private:
    /**
     * 정규화 파라미터 계산
     */
    void CalculateNormalizationParams() {
        // 평균 계산
        for (int feature = 0; feature < 15; feature++) {
            double sum = 0.0;
            for (int sample = 0; sample < training_samples; sample++) {
                sum += training_features[sample].features[feature];
            }
            feature_means[feature] = sum / training_samples;
        }
        
        // 표준편차 계산
        for (int feature = 0; feature < 15; feature++) {
            double sum_sq = 0.0;
            for (int sample = 0; sample < training_samples; sample++) {
                double diff = training_features[sample].features[feature] - feature_means[feature];
                sum_sq += diff * diff;
            }
            feature_stds[feature] = MathSqrt(sum_sq / training_samples);
        }
        
        // 정규화된 특성 계산
        for (int sample = 0; sample < training_samples; sample++) {
            for (int feature = 0; feature < 15; feature++) {
                training_features[sample].normalized_features[feature] = 
                    (training_features[sample].features[feature] - feature_means[feature]) / MathMax(feature_stds[feature], 0.001);
            }
        }
    }
    
    /**
     * 순전파
     */
    double[] ForwardPass(double &inputs[]) {
        double hidden[10];
        double outputs[3];
        
        // 입력층 -> 은닉층
        for (int h = 0; h < 10; h++) {
            hidden[h] = hidden_bias[h];
            for (int i = 0; i < 15; i++) {
                hidden[h] += inputs[i] * input_weights[i][h];
            }
            hidden[h] = Sigmoid(hidden[h]);
        }
        
        // 은닉층 -> 출력층
        for (int o = 0; o < 3; o++) {
            outputs[o] = output_bias[o];
            for (int h = 0; h < 10; h++) {
                outputs[o] += hidden[h] * hidden_weights[h][o];
            }
        }
        
        // 소프트맥스 활성화
        return Softmax(outputs);
    }
    
    /**
     * 역전파 (간소화)
     */
    void BackPropagation(double &inputs[], double &targets[], double learning_rate) {
        // 순전파로 현재 출력 계산
        double[] outputs = ForwardPass(inputs);
        
        // 출력층 오차 계산
        double output_errors[3];
        for (int o = 0; o < 3; o++) {
            output_errors[o] = targets[o] - outputs[o];
        }
        
        // 가중치 업데이트 (간소화된 버전)
        for (int h = 0; h < 10; h++) {
            for (int o = 0; o < 3; o++) {
                hidden_weights[h][o] += learning_rate * output_errors[o] * 0.1; // 간소화
            }
        }
        
        for (int i = 0; i < 15; i++) {
            for (int h = 0; h < 10; h++) {
                input_weights[i][h] += learning_rate * inputs[i] * 0.01; // 간소화
            }
        }
    }
    
    /**
     * 시그모이드 활성화 함수
     */
    double Sigmoid(double x) {
        return 1.0 / (1.0 + MathExp(-MathMax(MathMin(x, 500), -500)));
    }
    
    /**
     * 소프트맥스 활성화 함수
     */
    double[] Softmax(double &inputs[]) {
        double outputs[3];
        double sum = 0.0;
        
        for (int i = 0; i < 3; i++) {
            outputs[i] = MathExp(MathMax(MathMin(inputs[i], 500), -500));
            sum += outputs[i];
        }
        
        for (int i = 0; i < 3; i++) {
            outputs[i] /= sum;
        }
        
        return outputs;
    }
    
    /**
     * 모델 성능 평가
     */
    void EvaluateModel() {
        int correct = 0;
        int total = 0;
        
        for (int sample = 0; sample < training_samples; sample++) {
            double[] outputs = ForwardPass(training_features[sample].normalized_features);
            
            int predicted_class = 0;
            double max_prob = outputs[0];
            for (int i = 1; i < 3; i++) {
                if (outputs[i] > max_prob) {
                    max_prob = outputs[i];
                    predicted_class = i;
                }
            }
            
            int actual_class = 0;
            if (training_labels[sample] > 0.5) actual_class = 1;
            else if (training_labels[sample] < -0.5) actual_class = 2;
            
            if (predicted_class == actual_class) correct++;
            total++;
        }
        
        model_stats.accuracy = (double)correct / total;
        model_stats.total_predictions = total;
        model_stats.correct_predictions = correct;
    }
    
    /**
     * 통계 초기화
     */
    void ResetStatistics() {
        model_stats.accuracy = 0.0;
        model_stats.precision = 0.0;
        model_stats.recall = 0.0;
        model_stats.f1_score = 0.0;
        model_stats.total_predictions = 0;
        model_stats.correct_predictions = 0;
        model_stats.last_training_time = 0;
        model_stats.training_loss = 0.0;
    }

public:
    /**
     * 모델 성능 정보 반환
     */
    MLModelStats GetModelStats() {
        return model_stats;
    }
    
    /**
     * 신호 필터 상태 정보
     */
    string GetMLFilterInfo() {
        string info = "";
        info += "=== 머신러닝 신호 필터 ===\n";
        info += "모델 상태: " + (is_trained ? "훈련완료" : "미훈련") + "\n";
        info += "훈련 샘플: " + IntegerToString(training_samples) + "\n";
        info += "정확도: " + DoubleToString(model_stats.accuracy * 100, 2) + "%\n";
        info += "최근 훈련: " + TimeToString(model_stats.last_training_time) + "\n";
        info += "=====================================\n";
        return info;
    }
    
    /**
     * 훈련 상태 확인
     */
    bool IsModelTrained() {
        return is_trained;
    }
};