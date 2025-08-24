//+------------------------------------------------------------------+
//|                                      Stg_StatisticalArbitrage.mqh |
//|                                       통계적 차익거래 거래 전략     |
//|                                   Statistical Arbitrage Strategy   |
//+------------------------------------------------------------------+

/**
 * @file
 * 통계적 차익거래 거래 전략 구현
 * 페어 트레이딩과 공적분 분석 기반 시스템
 */

// Prevents processing this includes file multiple times.
#ifndef STG_STATISTICAL_ARBITRAGE_MQH
#define STG_STATISTICAL_ARBITRAGE_MQH

// Includes.
#include <EA31337-classes/Indicators/Indi_MA.mqh>
#include <EA31337-classes/Strategy.mqh>
#include "../../statistical-arbitrage/StatisticalArbitrageAnalyzer.mqh"
#include "../../machine-learning/MLSignalFilter.mqh"

// User input params.
INPUT_GROUP("Statistical Arbitrage strategy: main params");
INPUT float StatArb_LotSize = 0.02f;                    // 거래량 (Lot size)
INPUT int StatArb_MaxPairs = 2;                         // 최대 페어 수 (Max pairs)
INPUT float StatArb_MaxSpread = 3.0f;                   // 최대 스프레드 (Max spread)
INPUT_GROUP("Statistical Arbitrage strategy: pair selection");
INPUT string StatArb_PairSymbolB = "GBPUSD";             // 페어 심볼 B (Pair symbol B)
INPUT double StatArb_HedgeRatio = 1.2;                  // 헤지 비율 (Hedge ratio)
INPUT bool StatArb_AutoHedgeRatio = true;               // 자동 헤지 비율 (Auto hedge ratio)
INPUT_GROUP("Statistical Arbitrage strategy: cointegration params");
INPUT int StatArb_LookbackPeriod = 100;                 // 룩백 기간 (Lookback period)
INPUT double StatArb_EntryZScore = 2.0;                 // 진입 Z-Score (Entry Z-Score)
INPUT double StatArb_ExitZScore = 0.5;                  // 청산 Z-Score (Exit Z-Score)
INPUT double StatArb_StopLossZScore = 3.5;              // 손절 Z-Score (Stop loss Z-Score)
INPUT int StatArb_SpreadMAPeriod = 20;                  // 스프레드 MA 기간 (Spread MA period)
INPUT_GROUP("Statistical Arbitrage strategy: ML filter params");
INPUT bool StatArb_UseMLFilter = true;                  // ML 필터 사용 (Use ML filter)
INPUT double StatArb_MLConfidenceThreshold = 0.6;       // ML 신뢰도 임계값 (ML confidence threshold)
INPUT int StatArb_MLTrainingPeriod = 200;               // ML 훈련 기간 (ML training period)
INPUT_GROUP("Statistical Arbitrage strategy: risk management");
INPUT double StatArb_CorrelationThreshold = 0.7;        // 상관관계 임계값 (Correlation threshold)
INPUT double StatArb_SignificanceLevel = 0.05;          // 유의수준 (Significance level)
INPUT int StatArb_MaxHoldingHours = 24;                 // 최대 보유 시간 (Max holding hours)
INPUT bool StatArb_EnableMeanReversionFilter = true;     // 평균회귀 필터 (Mean reversion filter)
INPUT_GROUP("Statistical Arbitrage strategy: filter params");
INPUT int StatArb_SignalOpenMethod = 0;                 // 신호 열기 방법 (Signal open method)
INPUT float StatArb_SignalOpenLevel = 0;                // 신호 열기 레벨 (Signal open level)
INPUT int StatArb_SignalOpenFilterMethod = 32;          // 신호 열기 필터 방법 (Signal open filter method)
INPUT int StatArb_SignalOpenFilterTime = 3;             // 신호 열기 필터 시간 (Signal open filter time)
INPUT int StatArb_SignalOpenBoostMethod = 0;            // 신호 열기 부스트 방법 (Signal open boost method)
INPUT int StatArb_SignalCloseMethod = 0;                // 신호 닫기 방법 (Signal close method)
INPUT int StatArb_SignalCloseFilter = 32;               // 신호 닫기 필터 (Signal close filter)
INPUT float StatArb_SignalCloseLevel = 0;               // 신호 닫기 레벨 (Signal close level)
INPUT int StatArb_PriceStopMethod = 1;                  // 가격 정지 방법 (Price stop method)
INPUT float StatArb_PriceStopLevel = 2;                 // 가격 정지 레벨 (Price stop level)
INPUT int StatArb_TickFilterMethod = 32;                // 틱 필터 방법 (Tick filter method)
INPUT float StatArb_MaxSpreadToTrade = 3.0f;            // 거래할 최대 스프레드 (Max spread to trade)

// Structs.
// Defines struct with default user strategy values.
struct Stg_StatisticalArbitrage_Params_Defaults : StgParams {
  Stg_StatisticalArbitrage_Params_Defaults()
      : StgParams(::StatArb_SignalOpenMethod, ::StatArb_SignalOpenFilterMethod,
                  ::StatArb_SignalOpenLevel, ::StatArb_SignalOpenBoostMethod,
                  ::StatArb_SignalCloseMethod, ::StatArb_SignalCloseFilter,
                  ::StatArb_SignalCloseLevel, ::StatArb_PriceStopMethod,
                  ::StatArb_PriceStopLevel, ::StatArb_TickFilterMethod,
                  ::StatArb_MaxSpreadToTrade, ::StatArb_SignalOpenFilterTime) {
    Set(STRAT_PARAM_LS, ::StatArb_LotSize);
    Set(STRAT_PARAM_OCL, 0); // 동적 스톱로스 사용
    Set(STRAT_PARAM_OCP, 0); // 동적 타겟 사용
    Set(STRAT_PARAM_OCT, ::StatArb_MaxHoldingHours * 60); // 시간 청산 (분)
    Set(STRAT_PARAM_SOFT, ::StatArb_SignalOpenFilterTime);
  }
};

class Stg_StatisticalArbitrage : public Strategy {
 protected:
  StatisticalArbitrageAnalyzer *arbitrage_analyzer;
  MLSignalFilter *ml_filter;
  Indi_MA *indi_ma;
  int current_pairs;
  datetime last_trade_time;
  datetime last_analysis_time;
  string pair_symbol_B;
  
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
  
  PairPosition active_pairs[5]; // 최대 5개 페어
  int active_pair_count;

 public:
  static Stg_StatisticalArbitrage *Init(ENUM_TIMEFRAMES _tf = NULL, EA *_ea = NULL) {
    // Initialize strategy initial values.
    Stg_StatisticalArbitrage_Params_Defaults stg_stat_arb_defaults;
    StgParams _stg_params(stg_stat_arb_defaults);
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_StatisticalArbitrage(_stg_params, _tparams, _cparams, "StatisticalArbitrage");
    return _strat;
  }

  /**
   * Class constructor.
   */
  Stg_StatisticalArbitrage(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {
    current_pairs = 0;
    last_trade_time = 0;
    last_analysis_time = 0;
    pair_symbol_B = ::StatArb_PairSymbolB;
    active_pair_count = 0;
    
    // 페어 포지션 배열 초기화
    for (int i = 0; i < 5; i++) {
      active_pairs[i].is_active = false;
      active_pairs[i].ticket_A = 0;
      active_pairs[i].ticket_B = 0;
    }
  }

  /**
   * Initialize strategy.
   */
  bool Init() {
    if (!Strategy::Init()) return false;
    
    // Initialize statistical arbitrage analyzer.
    StatisticalArbitrageConfig arb_config = GetStatisticalArbitrageConfig();
    arbitrage_analyzer = new StatisticalArbitrageAnalyzer(arb_config);
    
    // Initialize ML filter if enabled.
    if (::StatArb_UseMLFilter) {
      MLFilterConfig ml_config = GetMLFilterConfig();
      ml_filter = new MLSignalFilter(ml_config, _Symbol, Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
      
      // 훈련 데이터 추가 및 모델 훈련
      ml_filter.AddTrainingData(::StatArb_MLTrainingPeriod);
      ml_filter.TrainModel();
    }
    
    // Initialize MA indicator for trend analysis.
    indi_ma = new Indi_MA(IndiMAParams(::StatArb_SpreadMAPeriod), ::StatArb_SpreadMAPeriod, indi_mode);
    
    return SetIndicators(indi_ma);
  }

  /**
   * Deinitialize strategy.
   */
  void Deinit() {
    if (arbitrage_analyzer != NULL) {
      delete arbitrage_analyzer;
      arbitrage_analyzer = NULL;
    }
    if (ml_filter != NULL) {
      delete ml_filter;
      ml_filter = NULL;
    }
    Strategy::Deinit();
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    bool _result = false;
    
    // 현재 페어 수 제한
    if (current_pairs >= ::StatArb_MaxPairs) {
      return false;
    }
    
    // 스프레드 체크
    if (GetChart().GetSpreadInPts() > ::StatArb_MaxSpread) {
      return false;
    }
    
    // 주기적 차익거래 분석 (10분마다)
    if (TimeCurrent() - last_analysis_time > 600) {
      arbitrage_analyzer.UpdatePairData();
      last_analysis_time = TimeCurrent();
    }
    
    // 차익거래 기회 분석
    ArbitrageOpportunity opportunity = arbitrage_analyzer.AnalyzeArbitrageOpportunity();
    
    if (opportunity.signal_type == ARB_SIGNAL_NONE) {
      return false;
    }
    
    // ML 필터링
    if (::StatArb_UseMLFilter && ml_filter != NULL && ml_filter.IsModelTrained()) {
      MLPrediction ml_prediction = ml_filter.FilterSignal(_cmd);
      
      if (ml_prediction.confidence_score < ::StatArb_MLConfidenceThreshold) {
        return false;
      }
      
      // ML 신호와 차익거래 신호 일치성 확인
      bool ml_signal_matches = false;
      
      if (opportunity.signal_type == ARB_SIGNAL_LONG_PAIR) {
        ml_signal_matches = (ml_prediction.filter_state == ML_FILTER_BULL_STRONG || 
                           ml_prediction.filter_state == ML_FILTER_BULL_WEAK);
      } else if (opportunity.signal_type == ARB_SIGNAL_SHORT_PAIR) {
        ml_signal_matches = (ml_prediction.filter_state == ML_FILTER_BEAR_STRONG || 
                           ml_prediction.filter_state == ML_FILTER_BEAR_WEAK);
      }
      
      if (!ml_signal_matches) {
        return false;
      }
    }
    
    // 신뢰도 및 리스크 체크
    if (opportunity.confidence_level < 0.6 || opportunity.risk_level > 0.6) {
      return false;
    }
    
    // 신호 타입에 따른 처리
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = (opportunity.signal_type == ARB_SIGNAL_LONG_PAIR);
        break;
        
      case ORDER_TYPE_SELL:
        _result = (opportunity.signal_type == ARB_SIGNAL_SHORT_PAIR);
        break;
    }
    
    if (_result) {
      // 페어 트레이딩 실행
      ExecutePairTrade(opportunity);
      
      current_pairs++;
      last_trade_time = TimeCurrent();
      
      // 로그 출력
      Print(GetName(), ": 통계적 차익거래 신호 감지 - ", 
            EnumToString(opportunity.signal_type), 
            ", 신뢰도: ", DoubleToString(opportunity.confidence_level, 3),
            ", 기대수익: ", DoubleToString(opportunity.expected_profit, 5));
    }
    
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    bool _result = false;
    
    // 활성 페어들의 청산 조건 확인
    for (int i = 0; i < 5; i++) {
      if (!active_pairs[i].is_active) continue;
      
      // 시간 기반 청산
      if (TimeCurrent() - active_pairs[i].entry_time > ::StatArb_MaxHoldingHours * 3600) {
        _result = true;
        break;
      }
      
      // 차익거래 청산 신호 확인
      ArbitrageOpportunity opportunity = arbitrage_analyzer.AnalyzeArbitrageOpportunity();
      
      if (opportunity.signal_type == ARB_SIGNAL_CLOSE_LONG || 
          opportunity.signal_type == ARB_SIGNAL_CLOSE_SHORT) {
        _result = true;
        break;
      }
      
      // 손절 조건 확인
      PairStatistics pair_stats = arbitrage_analyzer.GetPairStatistics();
      
      if (MathAbs(pair_stats.current_zscore) > ::StatArb_StopLossZScore) {
        _result = true;
        break;
      }
    }
    
    if (_result && current_pairs > 0) {
      current_pairs--;
    }
    
    return _result;
  }

 protected:
  /**
   * Gets statistical arbitrage configuration.
   */
  StatisticalArbitrageConfig GetStatisticalArbitrageConfig() {
    StatisticalArbitrageConfig config;
    
    // 페어 설정
    config.symbol_A = _Symbol;
    config.symbol_B = pair_symbol_B;
    config.hedge_ratio = ::StatArb_HedgeRatio;
    config.auto_hedge_ratio = ::StatArb_AutoHedgeRatio;
    
    // 공적분 설정
    config.coint_method = COINT_METHOD_SIMPLE_SPREAD; // 단순 스프레드 방법
    config.lookback_period = ::StatArb_LookbackPeriod;
    config.significance_level = ::StatArb_SignificanceLevel;
    config.min_cointegration_period = 50;
    
    // 스프레드 분석
    config.spread_ma_period = ::StatArb_SpreadMAPeriod;
    config.entry_zscore_threshold = ::StatArb_EntryZScore;
    config.exit_zscore_threshold = ::StatArb_ExitZScore;
    config.stop_loss_zscore = ::StatArb_StopLossZScore;
    
    // 칼만 필터 설정
    config.kalman_delta = 1e-4;
    config.kalman_velo = 1e-3;
    config.kalman_ve = 1e-1;
    
    // 리스크 관리
    config.max_position_size = ::StatArb_LotSize;
    config.correlation_threshold = ::StatArb_CorrelationThreshold;
    config.max_holding_period = ::StatArb_MaxHoldingHours;
    config.enable_mean_reversion_filter = ::StatArb_EnableMeanReversionFilter;
    
    // 성능 설정
    config.recalibration_frequency = 24; // 24시간마다
    config.adaptive_thresholds = true;
    config.volatility_adjustment = 1.0;
    
    return config;
  }

  /**
   * Gets ML filter configuration.
   */
  MLFilterConfig GetMLFilterConfig() {
    MLFilterConfig config;
    
    // 모델 설정
    config.primary_model = ML_MODEL_NEURAL_NETWORK;
    config.secondary_model = ML_MODEL_LINEAR_REGRESSION;
    config.use_ensemble = false;
    
    // 신경망 설정
    config.nn_hidden_layers = 1;
    config.nn_neurons_per_layer = 10;
    config.nn_learning_rate = 0.001;
    config.nn_training_epochs = 100;
    
    // 데이터 설정
    config.feature_window = 20;
    config.prediction_horizon = 1;
    config.confidence_threshold = ::StatArb_MLConfidenceThreshold;
    config.min_training_samples = 100;
    
    // 필터 설정
    config.enable_trend_filter = true;
    config.enable_volatility_filter = true;
    config.enable_momentum_filter = true;
    config.filter_sensitivity = 0.7;
    
    // 성능 설정
    config.retrain_frequency = 24; // 24시간마다
    config.accuracy_threshold = 0.6;
    config.adaptive_threshold = true;
    
    return config;
  }

  /**
   * Execute pair trade.
   */
  void ExecutePairTrade(ArbitrageOpportunity &opportunity) {
    // 빈 슬롯 찾기
    int slot = -1;
    for (int i = 0; i < 5; i++) {
      if (!active_pairs[i].is_active) {
        slot = i;
        break;
      }
    }
    
    if (slot == -1) return; // 슬롯 없음
    
    // 페어 포지션 정보 설정
    active_pairs[slot].lot_A = MathAbs(opportunity.optimal_lot_A);
    active_pairs[slot].lot_B = MathAbs(opportunity.optimal_lot_B);
    active_pairs[slot].entry_time = TimeCurrent();
    active_pairs[slot].entry_zscore = arbitrage_analyzer.GetPairStatistics().current_zscore;
    active_pairs[slot].signal_type = opportunity.signal_type;
    active_pairs[slot].is_active = true;
    
    active_pair_count++;
    
    Print(GetName(), ": 페어 트레이딩 실행 - ", 
          _Symbol, "(", DoubleToString(active_pairs[slot].lot_A, 2), ") / ",
          pair_symbol_B, "(", DoubleToString(active_pairs[slot].lot_B, 2), ")");
  }

  /**
   * Gets price stop value.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0f) {
    float _result = 0;
    uint _shift = 0;
    
    if (_method == 0) {
      // Z-Score 기반 동적 스톱
      PairStatistics pair_stats = arbitrage_analyzer.GetPairStatistics();
      double current_zscore = pair_stats.current_zscore;
      
      switch (_mode) {
        case ORDER_TYPE_VALUE_STOP:
          // 손절: Z-Score 기반
          _result = (float)(pair_stats.spread_std * ::StatArb_StopLossZScore);
          break;
          
        case ORDER_TYPE_VALUE_LIMIT:
          // 타겟: 평균 회귀 목표
          _result = (float)(pair_stats.spread_std * ::StatArb_ExitZScore);
          break;
      }
    }
    
    return (float)_result;
  }

  /**
   * Calculate dynamic position size for pair trading.
   */
  float GetLotSize() {
    // 페어 트레이딩에서는 기본 로트 사이즈 사용
    return ::StatArb_LotSize;
  }

  /**
   * Update pair trading performance.
   */
  void OnTradeClose(double profit_loss, bool is_win) {
    arbitrage_analyzer.UpdatePerformanceStats(profit_loss, is_win);
  }

  /**
   * Gets strategy status information.
   */
  string GetStatusInfo() {
    string status = "";
    status += "=== 통계적 차익거래 전략 상태 ===\n";
    status += "현재 페어 수: " + IntegerToString(current_pairs) + "/" + IntegerToString(::StatArb_MaxPairs) + "\n";
    status += "활성 페어: " + IntegerToString(active_pair_count) + "\n";
    status += "페어 심볼: " + _Symbol + "/" + pair_symbol_B + "\n";
    
    if (arbitrage_analyzer != NULL) {
      status += arbitrage_analyzer.GetArbitrageAnalysisInfo();
      status += arbitrage_analyzer.GetPerformanceInfo();
    }
    
    if (ml_filter != NULL) {
      status += ml_filter.GetMLFilterInfo();
    }
    
    return status;
  }
};

#endif // STG_STATISTICAL_ARBITRAGE_MQH