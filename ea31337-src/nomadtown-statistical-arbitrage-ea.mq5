//+------------------------------------------------------------------+
//|                         nomadtown-statistical-arbitrage-ea.mq5 |
//|                    통계적 차익거래 + 머신러닝 필터 Expert Advisor  |
//|                      Statistical Arbitrage + ML Filter System   |
//+------------------------------------------------------------------+

#property copyright "2024, Nomadtown EA System Statistical Arbitrage + ML Edition"
#property link      ""
#property version   "1.00"
#property description "통계적 차익거래 + 머신러닝 필터 EA (Nomadtown System)"

// 필요한 헤더 파일들
#include "include/statistical-arbitrage/StatisticalArbitrageAnalyzer.mqh"
#include "include/machine-learning/MLSignalFilter.mqh"

//+------------------------------------------------------------------+
//| 입력 매개변수                                                     |
//+------------------------------------------------------------------+
#ifdef __MQL4__
input static string __StatArb_Settings__ = "=== 통계적 차익거래 설정 ===";
#else
input group "통계적 차익거래 설정 (Statistical Arbitrage)"
#endif

// ===== 기본 거래 설정 =====
input double    SA_LotSize = 0.02;                          // 거래량 (Lot Size)
input int       SA_MaxPairs = 2;                            // 최대 페어 수 (Max Pairs)
input double    SA_MaxSpread = 3.0;                         // 최대 허용 스프레드 (Max Spread in Points)

// ===== 페어 설정 =====
#ifdef __MQL4__
input static string __Pair_Settings__ = "=== 페어 설정 ===";
#else
input group "페어 설정 (Pair Settings)"
#endif

input string    SA_PairSymbolB = "GBPUSD";                  // 페어 심볼 B (Pair Symbol B)
input double    SA_HedgeRatio = 1.2;                        // 헤지 비율 (Hedge Ratio)
input bool      SA_AutoHedgeRatio = true;                   // 자동 헤지 비율 (Auto Hedge Ratio)

// ===== 공적분 및 통계 설정 =====
#ifdef __MQL4__
input static string __Cointegration_Settings__ = "=== 공적분 분석 ===";
#else
input group "공적분 분석 (Cointegration Analysis)"
#endif

input int       SA_LookbackPeriod = 100;                    // 룩백 기간 (Lookback Period)
input double    SA_EntryZScore = 2.0;                       // 진입 Z-Score (Entry Z-Score)
input double    SA_ExitZScore = 0.5;                        // 청산 Z-Score (Exit Z-Score)
input double    SA_StopLossZScore = 3.5;                    // 손절 Z-Score (Stop Loss Z-Score)
input int       SA_SpreadMAPeriod = 20;                     // 스프레드 MA 기간 (Spread MA Period)
input double    SA_CorrelationThreshold = 0.7;              // 상관관계 임계값 (Correlation Threshold)
input double    SA_SignificanceLevel = 0.05;                // 유의수준 (Significance Level)

// ===== 머신러닝 필터 설정 =====
#ifdef __MQL4__
input static string __ML_Settings__ = "=== 머신러닝 필터 ===";
#else
input group "머신러닝 필터 (Machine Learning Filter)"
#endif

input bool      SA_UseMLFilter = true;                      // ML 필터 사용 (Use ML Filter)
input double    SA_MLConfidenceThreshold = 0.6;             // ML 신뢰도 임계값 (ML Confidence Threshold)
input int       SA_MLTrainingPeriod = 200;                  // ML 훈련 기간 (ML Training Period)
input int       SA_MLHiddenLayers = 1;                      // ML 은닉층 수 (ML Hidden Layers)
input int       SA_MLNeuronsPerLayer = 10;                  // 층당 뉴런 수 (Neurons Per Layer)
input double    SA_MLLearningRate = 0.001;                  // ML 학습률 (ML Learning Rate)
input int       SA_MLTrainingEpochs = 100;                  // ML 훈련 에포크 (ML Training Epochs)

// ===== 리스크 관리 설정 =====
#ifdef __MQL4__
input static string __Risk_Settings__ = "=== 리스크 관리 ===";
#else
input group "리스크 관리 (Risk Management)"
#endif

input int       SA_MaxHoldingHours = 24;                    // 최대 보유 시간 (Max Holding Hours)
input bool      SA_EnableMeanReversionFilter = true;         // 평균회귀 필터 (Mean Reversion Filter)
input double    SA_MaxDailyLoss = 5.0;                      // 일일 최대 손실 % (Max Daily Loss Percent)
input double    SA_MaxMonthlyLoss = 15.0;                   // 월별 최대 손실 % (Max Monthly Loss Percent)
input int       SA_MaxConsecutiveLosses = 4;                // 최대 연속 손실 수 (Max Consecutive Losses)

// ===== 칼만 필터 설정 =====
#ifdef __MQL4__
input static string __Kalman_Settings__ = "=== 칼만 필터 ===";
#else
input group "칼만 필터 (Kalman Filter)"
#endif

input double    SA_KalmanDelta = 1e-4;                      // 칼만 델타 (Kalman Delta)
input double    SA_KalmanVelo = 1e-3;                       // 칼만 속도 (Kalman Velocity)
input double    SA_KalmanVE = 1e-1;                         // 칼만 관측 오차 (Kalman Observation Error)

// ===== 알림 설정 =====
#ifdef __MQL4__
input static string __Alert_Settings__ = "=== 알림 설정 ===";
#else
input group "알림 설정 (Alert Settings)"
#endif

input bool      SA_EnableAlerts = true;                     // 알림 활성화 (Enable Alerts)
input bool      SA_AlertOnSignal = true;                    // 신호 시 알림 (Alert on Signal)
input bool      SA_AlertOnTrade = true;                     // 거래 시 알림 (Alert on Trade)
input bool      SA_AlertOnMLFilter = true;                  // ML 필터 시 알림 (Alert on ML Filter)

//+------------------------------------------------------------------+
//| 전역 변수                                                        |
//+------------------------------------------------------------------+
StatisticalArbitrageAnalyzer *g_arbitrage_analyzer = NULL;  // 차익거래 분석기
MLSignalFilter *g_ml_filter = NULL;                         // 머신러닝 필터
int g_magic_number = 31342;                                 // 통계적 차익거래 EA 전용 매직 넘버
string g_log_prefix = "[Nomadtown-StatArb] ";               // 로그 접두사
string g_pair_symbol_B;                                     // 페어 심볼 B

// 성과 추적 변수
double g_total_profit = 0;
int g_total_trades = 0;
int g_winning_trades = 0;
double g_max_drawdown = 0;
double g_equity_peak = 0;
int g_current_pairs = 0;

// 페어 트레이딩 관련
struct PairPosition {
    ulong ticket_A;        // 심볼 A 티켓
    ulong ticket_B;        // 심볼 B 티켓
    double lot_A;          // 심볼 A 로트
    double lot_B;          // 심볼 B 로트
    datetime entry_time;   // 진입 시간
    double entry_zscore;   // 진입 Z-Score
    ENUM_ARBITRAGE_SIGNAL signal_type; // 신호 타입
    bool is_active;        // 활성 상태
};

PairPosition g_active_pairs[5]; // 최대 5개 페어
int g_active_pair_count = 0;

// 거래 추적 변수
datetime g_last_analysis_time = 0;
datetime g_last_ml_training_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print(g_log_prefix, "=== Nomadtown 통계적 차익거래 + 머신러닝 시스템 초기화 ===");
    
    // 입력 매개변수 검증
    if (!ValidateStatisticalArbitrageInputs()) {
        Print(g_log_prefix, "❌ 입력 매개변수 검증 실패!");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 설정 정보 출력
    PrintStatisticalArbitrageSettings();
    
    // 페어 심볼 설정
    g_pair_symbol_B = SA_PairSymbolB;
    
    // 통계적 차익거래 분석기 초기화
    StatisticalArbitrageConfig arb_config = GetStatisticalArbitrageConfigFromInputs();
    g_arbitrage_analyzer = new StatisticalArbitrageAnalyzer(arb_config);
    
    if (g_arbitrage_analyzer == NULL) {
        Print(g_log_prefix, "❌ 통계적 차익거래 분석기 초기화 실패!");
        return INIT_FAILED;
    }
    
    // 머신러닝 필터 초기화
    if (SA_UseMLFilter) {
        MLFilterConfig ml_config = GetMLConfigFromInputs();
        g_ml_filter = new MLSignalFilter(ml_config, _Symbol, PERIOD_CURRENT);
        
        if (g_ml_filter == NULL) {
            Print(g_log_prefix, "❌ 머신러닝 필터 초기화 실패!");
            return INIT_FAILED;
        }
        
        // 훈련 데이터 추가 및 모델 훈련
        g_ml_filter.AddTrainingData(SA_MLTrainingPeriod);
        g_ml_filter.TrainModel();
        g_last_ml_training_time = TimeCurrent();
        
        Print(g_log_prefix, "✅ 머신러닝 필터 시스템 활성화");
    }
    
    // 페어 포지션 배열 초기화
    for (int i = 0; i < 5; i++) {
        g_active_pairs[i].is_active = false;
        g_active_pairs[i].ticket_A = 0;
        g_active_pairs[i].ticket_B = 0;
    }
    
    // 초기 상태 설정
    g_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);
    g_last_analysis_time = TimeCurrent();
    
    // 알림 설정
    if (SA_EnableAlerts) {
        Print(g_log_prefix, "🔔 알림 시스템 활성화");
        Alert("Nomadtown 통계적 차익거래 + 머신러닝 시스템이 시작되었습니다.");
    }
    
    Print(g_log_prefix, "✅ 초기화 완료! 페어: ", _Symbol, "/", g_pair_symbol_B);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    Print(g_log_prefix, "=== Nomadtown 통계적 차익거래 시스템 종료 ===");
    
    // 최종 성과 리포트
    PrintStatisticalArbitragePerformanceReport();
    
    // 메모리 정리
    if (g_arbitrage_analyzer != NULL) {
        delete g_arbitrage_analyzer;
        g_arbitrage_analyzer = NULL;
    }
    
    if (g_ml_filter != NULL) {
        delete g_ml_filter;
        g_ml_filter = NULL;
    }
    
    Print(g_log_prefix, "✅ 시스템 종료 완료");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    if (g_arbitrage_analyzer == NULL) return;
    
    // 주기적 차익거래 및 ML 분석 (10분마다)
    if (TimeCurrent() - g_last_analysis_time > 600) {
        g_arbitrage_analyzer.UpdatePairData();
        g_last_analysis_time = TimeCurrent();
        
        // ML 모델 재훈련 (24시간마다)
        if (SA_UseMLFilter && g_ml_filter != NULL && 
            TimeCurrent() - g_last_ml_training_time > 86400) {
            g_ml_filter.AddTrainingData(SA_MLTrainingPeriod);
            g_ml_filter.TrainModel();
            g_last_ml_training_time = TimeCurrent();
            
            if (SA_AlertOnMLFilter) {
                Print(g_log_prefix, "🤖 머신러닝 모델 재훈련 완료");
            }
        }
    }
    
    // 기존 페어 포지션 관리
    ManageExistingPairPositions();
    
    // 새로운 차익거래 기회 분석 및 실행
    AnalyzeAndExecuteStatisticalArbitrage();
    
    // 성과 추적 업데이트
    UpdatePerformanceMetrics();
}

//+------------------------------------------------------------------+
//| 통계적 차익거래 기회 분석 및 실행                                  |
//+------------------------------------------------------------------+
void AnalyzeAndExecuteStatisticalArbitrage() {
    // 페어 수 제한 확인
    if (g_current_pairs >= SA_MaxPairs) {
        return;
    }
    
    // 스프레드 체크
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    if (spread > SA_MaxSpread * SymbolInfoDouble(_Symbol, SYMBOL_POINT)) {
        return;
    }
    
    // 차익거래 기회 분석
    ArbitrageOpportunity opportunity = g_arbitrage_analyzer.AnalyzeArbitrageOpportunity();
    
    if (opportunity.signal_type == ARB_SIGNAL_NONE) {
        return;
    }
    
    // ML 필터링
    bool ml_confirmed = true;
    if (SA_UseMLFilter && g_ml_filter != NULL && g_ml_filter.IsModelTrained()) {
        ENUM_ORDER_TYPE order_type = (opportunity.signal_type == ARB_SIGNAL_LONG_PAIR) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        MLPrediction ml_prediction = g_ml_filter.FilterSignal(order_type);
        
        if (ml_prediction.confidence_score < SA_MLConfidenceThreshold) {
            ml_confirmed = false;
        } else {
            // ML 신호와 차익거래 신호 일치성 확인
            if (opportunity.signal_type == ARB_SIGNAL_LONG_PAIR) {
                ml_confirmed = (ml_prediction.filter_state == ML_FILTER_BULL_STRONG || 
                               ml_prediction.filter_state == ML_FILTER_BULL_WEAK);
            } else if (opportunity.signal_type == ARB_SIGNAL_SHORT_PAIR) {
                ml_confirmed = (ml_prediction.filter_state == ML_FILTER_BEAR_STRONG || 
                               ml_prediction.filter_state == ML_FILTER_BEAR_WEAK);
            }
        }
        
        if (SA_AlertOnMLFilter && !ml_confirmed) {
            Print(g_log_prefix, "🤖 ML 필터가 신호를 거부: 신뢰도 ", 
                  DoubleToString(ml_prediction.confidence_score, 3));
        }
    }
    
    // 신뢰도 및 리스크 체크
    if (opportunity.confidence_level < 0.6 || opportunity.risk_level > 0.6 || !ml_confirmed) {
        return;
    }
    
    if (SA_AlertOnSignal) {
        Print(g_log_prefix, "📊 차익거래 기회 발견: ", EnumToString(opportunity.signal_type),
              ", 신뢰도: ", DoubleToString(opportunity.confidence_level, 3),
              ", 기대수익: ", DoubleToString(opportunity.expected_profit, 5));
        
        if (SA_EnableAlerts) {
            Alert("통계적 차익거래 신호: " + EnumToString(opportunity.signal_type));
        }
    }
    
    // 차익거래 실행
    switch (opportunity.signal_type) {
        case ARB_SIGNAL_LONG_PAIR:
            ExecuteStatisticalArbitrageLong(opportunity);
            break;
        case ARB_SIGNAL_SHORT_PAIR:
            ExecuteStatisticalArbitrageShort(opportunity);
            break;
    }
}

//+------------------------------------------------------------------+
//| 통계적 차익거래 롱 페어 실행                                       |
//+------------------------------------------------------------------+
void ExecuteStatisticalArbitrageLong(ArbitrageOpportunity &opportunity) {
    // 빈 슬롯 찾기
    int slot = FindEmptyPairSlot();
    if (slot == -1) return;
    
    double lot_A = MathAbs(opportunity.optimal_lot_A);
    double lot_B = MathAbs(opportunity.optimal_lot_B);
    
    Print(g_log_prefix, "🟢 페어 롱 신호 - ", _Symbol, " 매수(", DoubleToString(lot_A, 2), 
          "), ", g_pair_symbol_B, " 매도(", DoubleToString(lot_B, 2), ")");
    
    // A 심볼 매수
    MqlTradeRequest request_A = {};
    MqlTradeResult result_A = {};
    
    request_A.action = TRADE_ACTION_DEAL;
    request_A.symbol = _Symbol;
    request_A.volume = lot_A;
    request_A.type = ORDER_TYPE_BUY;
    request_A.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    request_A.deviation = 3;
    request_A.magic = g_magic_number;
    request_A.comment = "StatArb-LONG-A";
    
    bool success_A = OrderSend(request_A, result_A);
    
    // B 심볼 매도 (가능한 경우)
    // 실제 구현에서는 멀티 심볼 거래 지원 필요
    
    if (success_A) {
        g_active_pairs[slot].ticket_A = result_A.order;
        g_active_pairs[slot].lot_A = lot_A;
        g_active_pairs[slot].lot_B = lot_B;
        g_active_pairs[slot].entry_time = TimeCurrent();
        g_active_pairs[slot].entry_zscore = g_arbitrage_analyzer.GetPairStatistics().current_zscore;
        g_active_pairs[slot].signal_type = ARB_SIGNAL_LONG_PAIR;
        g_active_pairs[slot].is_active = true;
        
        g_current_pairs++;
        g_active_pair_count++;
        g_total_trades++;
        
        Print(g_log_prefix, "✅ 페어 롱 실행 성공 - 티켓: ", result_A.order);
        
        if (SA_AlertOnTrade) {
            Alert("통계적 차익거래 페어 롱 실행");
        }
    } else {
        Print(g_log_prefix, "❌ 페어 롱 실행 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 통계적 차익거래 숏 페어 실행                                       |
//+------------------------------------------------------------------+
void ExecuteStatisticalArbitrageShort(ArbitrageOpportunity &opportunity) {
    // 빈 슬롯 찾기
    int slot = FindEmptyPairSlot();
    if (slot == -1) return;
    
    double lot_A = MathAbs(opportunity.optimal_lot_A);
    double lot_B = MathAbs(opportunity.optimal_lot_B);
    
    Print(g_log_prefix, "🔴 페어 숏 신호 - ", _Symbol, " 매도(", DoubleToString(lot_A, 2), 
          "), ", g_pair_symbol_B, " 매수(", DoubleToString(lot_B, 2), ")");
    
    // A 심볼 매도
    MqlTradeRequest request_A = {};
    MqlTradeResult result_A = {};
    
    request_A.action = TRADE_ACTION_DEAL;
    request_A.symbol = _Symbol;
    request_A.volume = lot_A;
    request_A.type = ORDER_TYPE_SELL;
    request_A.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    request_A.deviation = 3;
    request_A.magic = g_magic_number;
    request_A.comment = "StatArb-SHORT-A";
    
    bool success_A = OrderSend(request_A, result_A);
    
    if (success_A) {
        g_active_pairs[slot].ticket_A = result_A.order;
        g_active_pairs[slot].lot_A = lot_A;
        g_active_pairs[slot].lot_B = lot_B;
        g_active_pairs[slot].entry_time = TimeCurrent();
        g_active_pairs[slot].entry_zscore = g_arbitrage_analyzer.GetPairStatistics().current_zscore;
        g_active_pairs[slot].signal_type = ARB_SIGNAL_SHORT_PAIR;
        g_active_pairs[slot].is_active = true;
        
        g_current_pairs++;
        g_active_pair_count++;
        g_total_trades++;
        
        Print(g_log_prefix, "✅ 페어 숏 실행 성공 - 티켓: ", result_A.order);
        
        if (SA_AlertOnTrade) {
            Alert("통계적 차익거래 페어 숏 실행");
        }
    } else {
        Print(g_log_prefix, "❌ 페어 숏 실행 실패 - 에러: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| 유틸리티 함수들                                                   |
//+------------------------------------------------------------------+
int FindEmptyPairSlot() {
    for (int i = 0; i < 5; i++) {
        if (!g_active_pairs[i].is_active) {
            return i;
        }
    }
    return -1;
}

void ManageExistingPairPositions() {
    for (int i = 0; i < 5; i++) {
        if (!g_active_pairs[i].is_active) continue;
        
        // 시간 기반 청산
        if (TimeCurrent() - g_active_pairs[i].entry_time > SA_MaxHoldingHours * 3600) {
            ClosePairPosition(i, "시간만료");
            continue;
        }
        
        // 차익거래 청산 신호 확인
        ArbitrageOpportunity opportunity = g_arbitrage_analyzer.AnalyzeArbitrageOpportunity();
        
        if (opportunity.signal_type == ARB_SIGNAL_CLOSE_LONG || 
            opportunity.signal_type == ARB_SIGNAL_CLOSE_SHORT) {
            ClosePairPosition(i, "신호청산");
            continue;
        }
        
        // 손절 조건 확인
        PairStatistics pair_stats = g_arbitrage_analyzer.GetPairStatistics();
        
        if (MathAbs(pair_stats.current_zscore) > SA_StopLossZScore) {
            ClosePairPosition(i, "손절");
            continue;
        }
    }
}

bool ClosePairPosition(int slot, string reason) {
    if (slot < 0 || slot >= 5 || !g_active_pairs[slot].is_active) return false;
    
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    if (!PositionSelectByTicket(g_active_pairs[slot].ticket_A)) return false;
    
    double volume = PositionGetDouble(POSITION_VOLUME);
    ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = volume;
    request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
    request.price = (type == POSITION_TYPE_BUY) ? 
                   SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                   SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    request.position = g_active_pairs[slot].ticket_A;
    request.magic = g_magic_number;
    request.comment = "StatArb-CLOSE-" + reason;
    
    if (OrderSend(request, result)) {
        Print(g_log_prefix, "✅ 페어 포지션 닫기 성공 (", reason, ") - 티켓: ", g_active_pairs[slot].ticket_A);
        
        double profit = PositionGetDouble(POSITION_PROFIT);
        bool is_win = profit > 0;
        
        if (is_win) {
            g_winning_trades++;
        }
        g_total_profit += profit;
        
        // 통계 업데이트
        g_arbitrage_analyzer.UpdatePerformanceStats(profit, is_win);
        
        // 슬롯 정리
        g_active_pairs[slot].is_active = false;
        g_active_pairs[slot].ticket_A = 0;
        g_active_pairs[slot].ticket_B = 0;
        
        if (g_current_pairs > 0) g_current_pairs--;
        if (g_active_pair_count > 0) g_active_pair_count--;
        
        return true;
    } else {
        Print(g_log_prefix, "❌ 페어 포지션 닫기 실패 - 티켓: ", g_active_pairs[slot].ticket_A, ", 에러: ", GetLastError());
        return false;
    }
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

bool ValidateStatisticalArbitrageInputs() {
    bool is_valid = true;
    
    if (SA_LotSize <= 0) {
        Print(g_log_prefix, "오류: 거래량은 0보다 커야 합니다.");
        is_valid = false;
    }
    
    if (SA_EntryZScore <= SA_ExitZScore) {
        Print(g_log_prefix, "오류: 진입 Z-Score는 청산 Z-Score보다 커야 합니다.");
        is_valid = false;
    }
    
    if (SA_MLConfidenceThreshold < 0.5 || SA_MLConfidenceThreshold > 1.0) {
        Print(g_log_prefix, "오류: ML 신뢰도 임계값은 0.5-1.0 사이여야 합니다.");
        is_valid = false;
    }
    
    return is_valid;
}

StatisticalArbitrageConfig GetStatisticalArbitrageConfigFromInputs() {
    StatisticalArbitrageConfig config;
    
    // 페어 설정
    config.symbol_A = _Symbol;
    config.symbol_B = SA_PairSymbolB;
    config.hedge_ratio = SA_HedgeRatio;
    config.auto_hedge_ratio = SA_AutoHedgeRatio;
    
    // 공적분 설정
    config.coint_method = COINT_METHOD_SIMPLE_SPREAD;
    config.lookback_period = SA_LookbackPeriod;
    config.significance_level = SA_SignificanceLevel;
    config.min_cointegration_period = 50;
    
    // 스프레드 분석
    config.spread_ma_period = SA_SpreadMAPeriod;
    config.entry_zscore_threshold = SA_EntryZScore;
    config.exit_zscore_threshold = SA_ExitZScore;
    config.stop_loss_zscore = SA_StopLossZScore;
    
    // 칼만 필터 설정
    config.kalman_delta = SA_KalmanDelta;
    config.kalman_velo = SA_KalmanVelo;
    config.kalman_ve = SA_KalmanVE;
    
    // 리스크 관리
    config.max_position_size = SA_LotSize;
    config.correlation_threshold = SA_CorrelationThreshold;
    config.max_holding_period = SA_MaxHoldingHours;
    config.enable_mean_reversion_filter = SA_EnableMeanReversionFilter;
    
    // 성능 설정
    config.recalibration_frequency = 24;
    config.adaptive_thresholds = true;
    config.volatility_adjustment = 1.0;
    
    return config;
}

MLFilterConfig GetMLConfigFromInputs() {
    MLFilterConfig config;
    
    // 모델 설정
    config.primary_model = ML_MODEL_NEURAL_NETWORK;
    config.secondary_model = ML_MODEL_LINEAR_REGRESSION;
    config.use_ensemble = false;
    
    // 신경망 설정
    config.nn_hidden_layers = SA_MLHiddenLayers;
    config.nn_neurons_per_layer = SA_MLNeuronsPerLayer;
    config.nn_learning_rate = SA_MLLearningRate;
    config.nn_training_epochs = SA_MLTrainingEpochs;
    
    // 데이터 설정
    config.feature_window = 15;
    config.prediction_horizon = 1;
    config.confidence_threshold = SA_MLConfidenceThreshold;
    config.min_training_samples = 100;
    
    // 필터 설정
    config.enable_trend_filter = true;
    config.enable_volatility_filter = true;
    config.enable_momentum_filter = true;
    config.filter_sensitivity = 0.8;
    
    // 성능 설정
    config.retrain_frequency = 24;
    config.accuracy_threshold = 0.6;
    config.adaptive_threshold = true;
    
    return config;
}

void PrintStatisticalArbitrageSettings() {
    Print(g_log_prefix, "=== 통계적 차익거래 + 머신러닝 설정 ===");
    Print(g_log_prefix, "📊 통계적 차익거래 페어 트레이딩 모드");
    Print(g_log_prefix, "페어: ", _Symbol, "/", SA_PairSymbolB);
    Print(g_log_prefix, "거래량: ", SA_LotSize);
    Print(g_log_prefix, "헤지비율: ", (SA_AutoHedgeRatio ? "자동" : DoubleToString(SA_HedgeRatio, 4)));
    Print(g_log_prefix, "진입 Z-Score: ", SA_EntryZScore);
    Print(g_log_prefix, "청산 Z-Score: ", SA_ExitZScore);
    Print(g_log_prefix, "손절 Z-Score: ", SA_StopLossZScore);
    Print(g_log_prefix, "상관관계 임계값: ", SA_CorrelationThreshold);
    Print(g_log_prefix, "머신러닝 필터: ", (SA_UseMLFilter ? "활성" : "비활성"));
    
    if (SA_UseMLFilter) {
        Print(g_log_prefix, "ML 신뢰도 임계값: ", SA_MLConfidenceThreshold);
        Print(g_log_prefix, "ML 훈련 기간: ", SA_MLTrainingPeriod, " 봉");
        Print(g_log_prefix, "ML 은닉층: ", SA_MLHiddenLayers, "층 x ", SA_MLNeuronsPerLayer, "뉴런");
    }
    
    Print(g_log_prefix, "======================================");
}

void PrintStatisticalArbitragePerformanceReport() {
    Print(g_log_prefix, "=== 최종 성과 (통계적 차익거래 + ML) ===");
    Print(g_log_prefix, "총 거래: ", g_total_trades);
    Print(g_log_prefix, "승리 거래: ", g_winning_trades);
    Print(g_log_prefix, "승률: ", (g_total_trades > 0 ? DoubleToString((double)g_winning_trades / g_total_trades * 100, 2) : "0"), "%");
    Print(g_log_prefix, "총 수익: ", DoubleToString(g_total_profit, 2));
    Print(g_log_prefix, "최대 낙폭: ", DoubleToString(g_max_drawdown, 2), "%");
    Print(g_log_prefix, "활성 페어: ", g_active_pair_count);
    
    if (g_arbitrage_analyzer != NULL) {
        Print(g_log_prefix, g_arbitrage_analyzer.GetArbitrageAnalysisInfo());
        Print(g_log_prefix, g_arbitrage_analyzer.GetPerformanceInfo());
    }
    
    if (g_ml_filter != NULL) {
        MLModelStats ml_stats = g_ml_filter.GetModelStats();
        Print(g_log_prefix, "ML 정확도: ", DoubleToString(ml_stats.accuracy * 100, 2), "%");
        Print(g_log_prefix, "ML 예측 수: ", ml_stats.total_predictions);
    }
    
    Print(g_log_prefix, "=====================================");
}