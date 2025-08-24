//+------------------------------------------------------------------+
//|                                       Stg_VolatilityBreakout.mqh |
//|                               변동성 돌파 거래 전략                 |
//|                                  Volatility Breakout Strategy    |
//+------------------------------------------------------------------+

/**
 * @file
 * 변동성 돌파 거래 전략 구현
 * ATR 기반 변동성 분석과 런던 세션 돌파 시스템
 */

// Prevents processing this includes file multiple times.
#ifndef STG_VOLATILITY_BREAKOUT_MQH
#define STG_VOLATILITY_BREAKOUT_MQH

// Includes.
#include <EA31337-classes/Indicators/Indi_ATR.mqh>
#include <EA31337-classes/Strategy.mqh>
#include "../../volatility-breakout/VolatilityBreakoutAnalyzer.mqh"
#include "../../risk-management/DynamicRiskManager.mqh"
#include "../../machine-learning/MLSignalFilter.mqh"

// User input params.
INPUT_GROUP("Volatility Breakout strategy: main params");
INPUT float VolBreakout_LotSize = 0.03f;               // 거래량 (Lot size)
INPUT int VolBreakout_MaxTrades = 3;                   // 최대 거래 수 (Max trades)
INPUT float VolBreakout_MaxSpread = 2.5f;              // 최대 스프레드 (Max spread)
INPUT_GROUP("Volatility Breakout strategy: ATR params");
INPUT int VolBreakout_ATRPeriod = 14;                  // ATR 기간 (ATR period)
INPUT float VolBreakout_ATRMultEntry = 1.5f;           // 진입 ATR 배수 (Entry ATR multiplier)
INPUT float VolBreakout_ATRMultExit = 2.5f;            // 청산 ATR 배수 (Exit ATR multiplier)
INPUT float VolBreakout_BreakoutThreshold = 0.5f;      // 돌파 임계값 (Breakout threshold)
INPUT_GROUP("Volatility Breakout strategy: volatility params");
INPUT float VolBreakout_LowVolThreshold = 0.7f;        // 저변동성 임계값 (Low volatility threshold)
INPUT float VolBreakout_HighVolThreshold = 1.3f;       // 고변동성 임계값 (High volatility threshold)
INPUT int VolBreakout_ConsolidationPeriod = 10;       // 횡보 기간 (Consolidation period)
INPUT_GROUP("Volatility Breakout strategy: London session");
INPUT bool VolBreakout_UseLondonSession = true;        // 런던 세션 사용 (Use London session)
INPUT int VolBreakout_LondonStartHour = 7;             // 런던 시작 시간 GMT (London start hour)
INPUT int VolBreakout_LondonEndHour = 17;              // 런던 종료 시간 GMT (London end hour)
INPUT bool VolBreakout_LondonOnly = false;             // 런던 세션만 거래 (London session only)
INPUT_GROUP("Volatility Breakout strategy: risk management");
INPUT bool VolBreakout_UseDynamicRisk = true;          // 동적 리스크 사용 (Use dynamic risk)
INPUT float VolBreakout_BaseRiskPercent = 2.0f;        // 기본 리스크 % (Base risk percent)
INPUT float VolBreakout_MaxRiskPercent = 4.0f;         // 최대 리스크 % (Max risk percent)
INPUT bool VolBreakout_UseTimeExit = true;             // 시간 청산 사용 (Use time exit)
INPUT int VolBreakout_MaxHoldingHours = 8;             // 최대 보유 시간 (Max holding hours)
INPUT_GROUP("Volatility Breakout strategy: ML filter");
INPUT bool VolBreakout_UseMLFilter = true;             // ML 필터 사용 (Use ML filter)
INPUT float VolBreakout_MLConfidenceThreshold = 0.7f;   // ML 신뢰도 임계값 (ML confidence threshold)
INPUT int VolBreakout_MLTrainingPeriod = 150;          // ML 훈련 기간 (ML training period)
INPUT_GROUP("Volatility Breakout strategy: filter params");
INPUT int VolBreakout_SignalOpenMethod = 0;            // 신호 열기 방법 (Signal open method)
INPUT float VolBreakout_SignalOpenLevel = 0;           // 신호 열기 레벨 (Signal open level)
INPUT int VolBreakout_SignalOpenFilterMethod = 32;     // 신호 열기 필터 방법 (Signal open filter method)
INPUT int VolBreakout_SignalOpenFilterTime = 3;        // 신호 열기 필터 시간 (Signal open filter time)
INPUT int VolBreakout_SignalOpenBoostMethod = 0;       // 신호 열기 부스트 방법 (Signal open boost method)
INPUT int VolBreakout_SignalCloseMethod = 0;           // 신호 닫기 방법 (Signal close method)
INPUT int VolBreakout_SignalCloseFilter = 32;          // 신호 닫기 필터 (Signal close filter)
INPUT float VolBreakout_SignalCloseLevel = 0;          // 신호 닫기 레벨 (Signal close level)
INPUT int VolBreakout_PriceStopMethod = 1;             // 가격 정지 방법 (Price stop method)
INPUT float VolBreakout_PriceStopLevel = 2;            // 가격 정지 레벨 (Price stop level)
INPUT int VolBreakout_TickFilterMethod = 32;           // 틱 필터 방법 (Tick filter method)
INPUT float VolBreakout_MaxSpreadToTrade = 2.5f;       // 거래할 최대 스프레드 (Max spread to trade)

// Structs.
// Defines struct with default user strategy values.
struct Stg_VolatilityBreakout_Params_Defaults : StgParams {
  Stg_VolatilityBreakout_Params_Defaults()
      : StgParams(::VolBreakout_SignalOpenMethod, ::VolBreakout_SignalOpenFilterMethod,
                  ::VolBreakout_SignalOpenLevel, ::VolBreakout_SignalOpenBoostMethod,
                  ::VolBreakout_SignalCloseMethod, ::VolBreakout_SignalCloseFilter,
                  ::VolBreakout_SignalCloseLevel, ::VolBreakout_PriceStopMethod,
                  ::VolBreakout_PriceStopLevel, ::VolBreakout_TickFilterMethod,
                  ::VolBreakout_MaxSpreadToTrade, ::VolBreakout_SignalOpenFilterTime) {
    Set(STRAT_PARAM_LS, ::VolBreakout_LotSize);
    Set(STRAT_PARAM_OCL, 0); // 동적 스톱로스 사용
    Set(STRAT_PARAM_OCP, 0); // 동적 타겟 사용
    Set(STRAT_PARAM_OCT, ::VolBreakout_MaxHoldingHours * 60); // 시간 청산 (분)
    Set(STRAT_PARAM_SOFT, ::VolBreakout_SignalOpenFilterTime);
  }
};

class Stg_VolatilityBreakout : public Strategy {
 protected:
  VolatilityBreakoutAnalyzer *volatility_analyzer;
  DynamicRiskManager *risk_manager;
  MLSignalFilter *ml_filter;
  Indi_ATR *indi_atr;
  int current_trades;
  datetime last_trade_time;
  datetime last_analysis_time;

 public:
  static Stg_VolatilityBreakout *Init(ENUM_TIMEFRAMES _tf = NULL, EA *_ea = NULL) {
    // Initialize strategy initial values.
    Stg_VolatilityBreakout_Params_Defaults stg_vol_breakout_defaults;
    StgParams _stg_params(stg_vol_breakout_defaults);
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_VolatilityBreakout(_stg_params, _tparams, _cparams, "VolatilityBreakout");
    return _strat;
  }

  /**
   * Class constructor.
   */
  Stg_VolatilityBreakout(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {
    current_trades = 0;
    last_trade_time = 0;
    last_analysis_time = 0;
    ml_filter = NULL;
  }

  /**
   * Initialize strategy.
   */
  bool Init() {
    if (!Strategy::Init()) return false;
    
    // Initialize volatility breakout analyzer.
    VolatilityBreakoutConfig vb_config = GetVolatilityBreakoutConfig();
    volatility_analyzer = new VolatilityBreakoutAnalyzer(vb_config, _Symbol, Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
    
    // Initialize dynamic risk manager if enabled.
    if (::VolBreakout_UseDynamicRisk) {
      RiskManagementConfig risk_config = GetRiskManagementConfig();
      risk_manager = new DynamicRiskManager(risk_config);
    }
    
    // Initialize ML filter if enabled.
    if (::VolBreakout_UseMLFilter) {
      MLFilterConfig ml_config = GetMLFilterConfig();
      ml_filter = new MLSignalFilter(ml_config, _Symbol, Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
      
      // 훈련 데이터 추가 및 모델 훈련
      ml_filter.AddTrainingData(::VolBreakout_MLTrainingPeriod);
      ml_filter.TrainModel();
    }
    
    // Initialize ATR indicator.
    indi_atr = new Indi_ATR(IndiATRParams(::VolBreakout_ATRPeriod), ::VolBreakout_ATRPeriod, indi_mode);
    
    return SetIndicators(indi_atr);
  }

  /**
   * Deinitialize strategy.
   */
  void Deinit() {
    if (volatility_analyzer != NULL) {
      delete volatility_analyzer;
      volatility_analyzer = NULL;
    }
    if (risk_manager != NULL) {
      delete risk_manager;
      risk_manager = NULL;
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
    
    // 현재 거래 수 제한
    if (current_trades >= ::VolBreakout_MaxTrades) {
      return false;
    }
    
    // 스프레드 체크
    if (GetChart().GetSpreadInPts() > ::VolBreakout_MaxSpread) {
      return false;
    }
    
    // 동적 리스크 관리자 거래 허용 확인
    if (risk_manager != NULL && !risk_manager.IsTradeAllowed()) {
      return false;
    }
    
    // 주기적 변동성 분석 (5분마다)
    if (TimeCurrent() - last_analysis_time > 300) {
      volatility_analyzer.AnalyzeVolatilityAndRange();
      last_analysis_time = TimeCurrent();
    }
    
    // 변동성 돌파 신호 분석
    ENUM_VOLATILITY_BREAKOUT_SIGNAL vb_signal = volatility_analyzer.GetBreakoutSignal();
    
    // ML 필터링
    bool ml_confirmed = true;
    if (::VolBreakout_UseMLFilter && ml_filter != NULL && ml_filter.IsModelTrained()) {
      MLPrediction ml_prediction = ml_filter.FilterSignal(_cmd);
      
      if (ml_prediction.confidence_score < ::VolBreakout_MLConfidenceThreshold) {
        ml_confirmed = false;
      } else {
        // ML 신호와 변동성 돌파 신호 일치성 확인
        if (_cmd == ORDER_TYPE_BUY) {
          ml_confirmed = (ml_prediction.filter_state == ML_FILTER_BULL_STRONG || 
                         ml_prediction.filter_state == ML_FILTER_BULL_WEAK);
        } else if (_cmd == ORDER_TYPE_SELL) {
          ml_confirmed = (ml_prediction.filter_state == ML_FILTER_BEAR_STRONG || 
                         ml_prediction.filter_state == ML_FILTER_BEAR_WEAK);
        }
      }
    }
    
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = (vb_signal == VB_SIGNAL_BUY_BREAKOUT) && ml_confirmed;
        break;
        
      case ORDER_TYPE_SELL:
        _result = (vb_signal == VB_SIGNAL_SELL_BREAKOUT) && ml_confirmed;
        break;
    }
    
    if (_result) {
      current_trades++;
      last_trade_time = TimeCurrent();
      
      // 로그 출력
      Print(GetName(), ": 변동성 돌파 신호 감지 - ", 
            (_cmd == ORDER_TYPE_BUY ? "상승돌파매수" : "하락돌파매도"), 
            ", ATR: ", DoubleToString(volatility_analyzer.GetCurrentATR(), 5),
            ", 변동성비율: ", DoubleToString(volatility_analyzer.GetVolatilityRatio(), 2));
    }
    
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    bool _result = false;
    
    // 시간 기반 청산은 전략에서 처리하지 않고 별도 로직에서 처리
    // 여기서는 반대 신호에 의한 청산만 처리
    
    ENUM_VOLATILITY_BREAKOUT_SIGNAL vb_signal = volatility_analyzer.GetBreakoutSignal();
    
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // 매수 포지션: 하락 돌파 신호 시 청산
        _result = (vb_signal == VB_SIGNAL_SELL_BREAKOUT);
        break;
        
      case ORDER_TYPE_SELL:
        // 매도 포지션: 상승 돌파 신호 시 청산
        _result = (vb_signal == VB_SIGNAL_BUY_BREAKOUT);
        break;
    }
    
    if (_result && current_trades > 0) {
      current_trades--;
    }
    
    return _result;
  }

 protected:
  /**
   * Gets volatility breakout configuration.
   */
  VolatilityBreakoutConfig GetVolatilityBreakoutConfig() {
    VolatilityBreakoutConfig config;
    
    // ATR 설정
    config.atr_period = ::VolBreakout_ATRPeriod;
    config.atr_multiplier_entry = ::VolBreakout_ATRMultEntry;
    config.atr_multiplier_exit = ::VolBreakout_ATRMultExit;
    
    // 변동성 임계값
    config.low_volatility_threshold = ::VolBreakout_LowVolThreshold;
    config.high_volatility_threshold = ::VolBreakout_HighVolThreshold;
    config.extreme_volatility_threshold = 2.0; // 고정값
    
    // 돌파 설정
    config.consolidation_period = ::VolBreakout_ConsolidationPeriod;
    config.breakout_threshold = ::VolBreakout_BreakoutThreshold;
    config.confirm_method = BREAKOUT_VOLUME_CONFIRM;
    config.min_breakout_bars = 2;
    
    // 런던 세션 설정
    config.use_london_session = ::VolBreakout_UseLondonSession;
    config.london_start_hour = ::VolBreakout_LondonStartHour;
    config.london_end_hour = ::VolBreakout_LondonEndHour;
    config.london_breakout_only = ::VolBreakout_LondonOnly;
    
    // 필터 설정
    config.use_volume_filter = true;
    config.use_spread_filter = true;
    config.use_time_filter = true;
    config.max_spread_points = ::VolBreakout_MaxSpread;
    
    // 청산 설정
    config.use_time_exit = ::VolBreakout_UseTimeExit;
    config.max_holding_hours = ::VolBreakout_MaxHoldingHours;
    config.use_profit_protection = true;
    config.profit_protection_level = 1.5;
    
    return config;
  }

  /**
   * Gets risk management configuration.
   */
  RiskManagementConfig GetRiskManagementConfig() {
    RiskManagementConfig config;
    
    // 기본 리스크 설정
    config.risk_mode = RISK_MODE_VOLATILITY; // 변동성 기반 리스크
    config.base_risk_percent = ::VolBreakout_BaseRiskPercent;
    config.max_risk_percent = ::VolBreakout_MaxRiskPercent;
    config.min_risk_percent = 0.5;
    
    // 포지션 크기 조정
    config.sizing_method = SIZE_VOLATILITY_ADJUSTED;
    config.fixed_lot_size = ::VolBreakout_LotSize;
    config.max_lot_size = ::VolBreakout_LotSize * 3;
    config.min_lot_size = ::VolBreakout_LotSize * 0.5;
    
    // 변동성 기반 설정
    config.atr_period = ::VolBreakout_ATRPeriod;
    config.atr_multiplier = 2.0;
    config.volatility_threshold_high = ::VolBreakout_HighVolThreshold;
    config.volatility_threshold_low = ::VolBreakout_LowVolThreshold;
    
    // 보호 설정
    config.max_daily_loss_percent = 5.0;
    config.max_monthly_loss_percent = 15.0;
    config.max_consecutive_losses = 4;
    config.enable_emergency_stop = true;
    
    return config;
  }

  /**
   * Gets ML filter configuration.
   */
  MLFilterConfig GetMLFilterConfig() {
    MLFilterConfig config;
    
    // 모델 설정
    config.primary_model = ML_MODEL_NEURAL_NETWORK;
    config.secondary_model = ML_MODEL_SVM;
    config.use_ensemble = false;
    
    // 신경망 설정
    config.nn_hidden_layers = 1;
    config.nn_neurons_per_layer = 10;
    config.nn_learning_rate = 0.001;
    config.nn_training_epochs = 50;
    
    // 데이터 설정
    config.feature_window = 15;
    config.prediction_horizon = 1;
    config.confidence_threshold = ::VolBreakout_MLConfidenceThreshold;
    config.min_training_samples = 100;
    
    // 필터 설정
    config.enable_trend_filter = true;
    config.enable_volatility_filter = true;
    config.enable_momentum_filter = true;
    config.filter_sensitivity = 0.8;
    
    // 성능 설정
    config.retrain_frequency = 12; // 12시간마다
    config.accuracy_threshold = 0.65;
    config.adaptive_threshold = true;
    
    return config;
  }

  /**
   * Gets price stop value.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0f) {
    float _result = 0;
    uint _shift = 0;
    
    if (_method == 0) {
      // ATR 기반 동적 스톱
      double atr_value = indi_atr[_shift][0];
      
      switch (_mode) {
        case ORDER_TYPE_VALUE_STOP:
          // 스톱로스: ATR * 진입 배수
          _result = (float)(atr_value * ::VolBreakout_ATRMultEntry);
          break;
          
        case ORDER_TYPE_VALUE_LIMIT:
          // 타겟: ATR * 청산 배수
          _result = (float)(atr_value * ::VolBreakout_ATRMultExit);
          break;
      }
    }
    
    return (float)_result;
  }

  /**
   * Calculate dynamic position size using risk manager.
   */
  float GetLotSize() {
    if (risk_manager != NULL) {
      double entry_price = GetChart().GetPrice(PRICE_ASK);
      double stop_loss = entry_price - indi_atr[0][0] * ::VolBreakout_ATRMultEntry;
      return (float)risk_manager.CalculatePositionSize(entry_price, stop_loss, _Symbol);
    }
    
    return ::VolBreakout_LotSize;
  }

  /**
   * Update risk statistics after trade close.
   */
  void OnTradeClose(double profit_loss, bool is_win) {
    if (risk_manager != NULL) {
      risk_manager.UpdateStatistics(profit_loss, is_win);
    }
  }

  /**
   * Gets strategy status information.
   */
  string GetStatusInfo() {
    string status = "";
    status += "=== 변동성 돌파 거래 전략 상태 ===\n";
    status += "현재 거래 수: " + IntegerToString(current_trades) + "/" + IntegerToString(::VolBreakout_MaxTrades) + "\n";
    
    if (volatility_analyzer != NULL) {
      status += volatility_analyzer.GetAnalysisInfo();
    }
    
    if (risk_manager != NULL) {
      status += risk_manager.GetRiskStatusInfo();
    }
    
    if (ml_filter != NULL) {
      status += ml_filter.GetMLFilterInfo();
    }
    
    return status;
  }
};

#endif // STG_VOLATILITY_BREAKOUT_MQH