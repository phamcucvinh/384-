//+------------------------------------------------------------------+
//|                                       Stg_PriceActionTrading.mqh |
//|                        가격행동 거래 전략 (지지/저항 기반)            |
//|                                     Price Action Trading Strategy |
//+------------------------------------------------------------------+

/**
 * @file
 * 가격행동 거래 전략 구현
 * 핵심 지지/저항 구간 식별 후 진입/청산 시스템
 */

// Prevents processing this includes file multiple times.
#ifndef STG_PRICE_ACTION_TRADING_MQH
#define STG_PRICE_ACTION_TRADING_MQH

// Includes.
#include <EA31337-classes/Indicators/Indi_ATR.mqh>
#include <EA31337-classes/Strategy.mqh>
#include "../../price-action/PriceActionAnalyzer.mqh"

// User input params.
INPUT_GROUP("Price Action Trading strategy: main params");
INPUT float PriceAction_LotSize = 0.02f;                    // 거래량 (Lot size)
INPUT int PriceAction_MaxTrades = 3;                        // 최대 거래 수 (Max trades)
INPUT float PriceAction_MaxSpread = 3.0f;                   // 최대 스프레드 (Max spread)
INPUT_GROUP("Price Action Trading strategy: level detection");
INPUT int PriceAction_LookbackPeriod = 100;                 // 분석 기간 (Lookback period)
INPUT float PriceAction_LevelTolerance = 5.0f;              // 레벨 허용오차 pips (Level tolerance)
INPUT int PriceAction_MinTouches = 2;                       // 최소 터치 횟수 (Min touches)
INPUT float PriceAction_MinStrength = 0.4f;                 // 최소 강도 (Min strength)
INPUT_GROUP("Price Action Trading strategy: signal params");
INPUT bool PriceAction_UseBreakout = true;                  // 돌파 신호 사용 (Use breakout signals)
INPUT bool PriceAction_UseBounce = true;                    // 바운스 신호 사용 (Use bounce signals)
INPUT float PriceAction_BreakoutBuffer = 3.0f;              // 돌파 확인 버퍼 pips (Breakout buffer)
INPUT float PriceAction_BounceBuffer = 2.0f;                // 바운스 확인 버퍼 pips (Bounce buffer)
INPUT_GROUP("Price Action Trading strategy: risk params");
INPUT float PriceAction_StopLoss = 20.0f;                   // 손절매 pips (Stop loss in pips)
INPUT float PriceAction_TakeProfit = 40.0f;                 // 익절 pips (Take profit in pips)
INPUT float PriceAction_RiskRewardRatio = 2.0f;             // 리스크 수익 비율 (Risk reward ratio)
INPUT bool PriceAction_UseTrailingStop = true;              // 트레일링 스톱 사용 (Use trailing stop)
INPUT_GROUP("Price Action Trading strategy: filter params");
INPUT bool PriceAction_UseVolumeFilter = true;              // 볼륨 필터 사용 (Use volume filter)
INPUT bool PriceAction_UseMomentumFilter = true;            // 모멘텀 필터 사용 (Use momentum filter)
INPUT bool PriceAction_UseTimeFilter = true;                // 시간 필터 사용 (Use time filter)
INPUT int PriceAction_SignalOpenMethod = 0;                 // 신호 열기 방법 (Signal open method)
INPUT float PriceAction_SignalOpenLevel = 0;                // 신호 열기 레벨 (Signal open level)
INPUT int PriceAction_SignalOpenFilterMethod = 32;          // 신호 열기 필터 방법 (Signal open filter method)
INPUT int PriceAction_SignalOpenFilterTime = 3;             // 신호 열기 필터 시간 (Signal open filter time)
INPUT int PriceAction_SignalOpenBoostMethod = 0;            // 신호 열기 부스트 방법 (Signal open boost method)
INPUT int PriceAction_SignalCloseMethod = 0;                // 신호 닫기 방법 (Signal close method)
INPUT int PriceAction_SignalCloseFilter = 32;               // 신호 닫기 필터 (Signal close filter)
INPUT float PriceAction_SignalCloseLevel = 0;               // 신호 닫기 레벨 (Signal close level)
INPUT int PriceAction_PriceStopMethod = 1;                  // 가격 정지 방법 (Price stop method)
INPUT float PriceAction_PriceStopLevel = 2;                 // 가격 정지 레벨 (Price stop level)
INPUT int PriceAction_TickFilterMethod = 32;                // 틱 필터 방법 (Tick filter method)
INPUT float PriceAction_MaxSpreadToTrade = 3.0f;            // 거래할 최대 스프레드 (Max spread to trade)

// Structs.
// Defines struct with default user strategy values.
struct Stg_PriceActionTrading_Params_Defaults : StgParams {
  Stg_PriceActionTrading_Params_Defaults()
      : StgParams(::PriceAction_SignalOpenMethod, ::PriceAction_SignalOpenFilterMethod,
                  ::PriceAction_SignalOpenLevel, ::PriceAction_SignalOpenBoostMethod,
                  ::PriceAction_SignalCloseMethod, ::PriceAction_SignalCloseFilter,
                  ::PriceAction_SignalCloseLevel, ::PriceAction_PriceStopMethod,
                  ::PriceAction_PriceStopLevel, ::PriceAction_TickFilterMethod,
                  ::PriceAction_MaxSpreadToTrade, ::PriceAction_SignalOpenFilterTime) {
    Set(STRAT_PARAM_LS, ::PriceAction_LotSize);
    Set(STRAT_PARAM_OCL, ::PriceAction_StopLoss);
    Set(STRAT_PARAM_OCP, ::PriceAction_TakeProfit);
    Set(STRAT_PARAM_OCT, 0);
    Set(STRAT_PARAM_SOFT, ::PriceAction_SignalOpenFilterTime);
  }
};

class Stg_PriceActionTrading : public Strategy {
 protected:
  PriceActionAnalyzer *price_action_analyzer;
  Indi_ATR *indi_atr;
  int current_trades;
  datetime last_trade_time;
  datetime last_analysis_time;
  double last_support_level;
  double last_resistance_level;

 public:
  static Stg_PriceActionTrading *Init(ENUM_TIMEFRAMES _tf = NULL, EA *_ea = NULL) {
    // Initialize strategy initial values.
    Stg_PriceActionTrading_Params_Defaults stg_price_action_defaults;
    StgParams _stg_params(stg_price_action_defaults);
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_PriceActionTrading(_stg_params, _tparams, _cparams, "PriceActionTrading");
    return _strat;
  }

  /**
   * Class constructor.
   */
  Stg_PriceActionTrading(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {
    current_trades = 0;
    last_trade_time = 0;
    last_analysis_time = 0;
    last_support_level = 0;
    last_resistance_level = 0;
  }

  /**
   * Initialize strategy.
   */
  bool Init() {
    if (!Strategy::Init()) return false;
    
    // Initialize price action analyzer.
    PriceActionConfig pa_config = GetPriceActionConfig();
    price_action_analyzer = new PriceActionAnalyzer(pa_config, _Symbol, Get<ENUM_TIMEFRAMES>(STRAT_PARAM_TF));
    
    // Initialize ATR indicator for volatility measurement.
    indi_atr = new Indi_ATR(IndiATRParams(14), 14, indi_mode);
    
    return SetIndicators(indi_atr);
  }

  /**
   * Deinitialize strategy.
   */
  void Deinit() {
    if (price_action_analyzer != NULL) {
      delete price_action_analyzer;
      price_action_analyzer = NULL;
    }
    Strategy::Deinit();
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    bool _result = false;
    
    // 현재 거래 수 제한
    if (current_trades >= ::PriceAction_MaxTrades) {
      return false;
    }
    
    // 스프레드 체크
    if (GetChart().GetSpreadInPts() > ::PriceAction_MaxSpread) {
      return false;
    }
    
    // 주기적 지지/저항 레벨 분석 (5분마다)
    if (TimeCurrent() - last_analysis_time > 300) {
      price_action_analyzer.AnalyzeSupportResistanceLevels();
      last_analysis_time = TimeCurrent();
    }
    
    // 가격행동 신호 분석
    ENUM_PRICE_ACTION_SIGNAL pa_signal = price_action_analyzer.GetPriceActionSignal();
    
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // 매수 신호: 지지선 바운스 또는 저항 돌파
        _result = (pa_signal == PA_SIGNAL_BUY_BOUNCE || pa_signal == PA_SIGNAL_BUY_BREAKOUT);
        break;
        
      case ORDER_TYPE_SELL:
        // 매도 신호: 저항선 거부 또는 지지 이탈
        _result = (pa_signal == PA_SIGNAL_SELL_REJECTION || pa_signal == PA_SIGNAL_SELL_BREAKDOWN);
        break;
    }
    
    if (_result) {
      current_trades++;
      last_trade_time = TimeCurrent();
      
      // 현재 레벨 업데이트
      double current_price = GetChart().GetPrice(PRICE_BID);
      last_support_level = price_action_analyzer.GetNearestSupport(current_price);
      last_resistance_level = price_action_analyzer.GetNearestResistance(current_price);
      
      // 로그 출력
      Print(GetName(), ": 가격행동 신호 감지 - ", 
            (_cmd == ORDER_TYPE_BUY ? "매수" : "매도"), 
            ", 신호타입: ", EnumToString(pa_signal));
    }
    
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    bool _result = false;
    
    double current_price = GetChart().GetPrice(PRICE_BID);
    
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // 매수 포지션 청산: 저항선 도달 또는 지지선 붕괴
        if (last_resistance_level > 0) {
          _result = current_price >= last_resistance_level - 5 * GetChart().GetPointValue();
        }
        // 또는 새로운 저항선 거부 신호
        if (!_result) {
          ENUM_PRICE_ACTION_SIGNAL pa_signal = price_action_analyzer.GetPriceActionSignal();
          _result = (pa_signal == PA_SIGNAL_SELL_REJECTION);
        }
        break;
        
      case ORDER_TYPE_SELL:
        // 매도 포지션 청산: 지지선 도달 또는 저항선 돌파
        if (last_support_level > 0) {
          _result = current_price <= last_support_level + 5 * GetChart().GetPointValue();
        }
        // 또는 새로운 지지선 바운스 신호
        if (!_result) {
          ENUM_PRICE_ACTION_SIGNAL pa_signal = price_action_analyzer.GetPriceActionSignal();
          _result = (pa_signal == PA_SIGNAL_BUY_BOUNCE);
        }
        break;
    }
    
    if (_result && current_trades > 0) {
      current_trades--;
    }
    
    return _result;
  }

 protected:
  /**
   * Gets price action configuration.
   */
  PriceActionConfig GetPriceActionConfig() {
    PriceActionConfig config;
    
    // 지지/저항 감지 설정
    config.lookback_period = ::PriceAction_LookbackPeriod;
    config.level_tolerance = ::PriceAction_LevelTolerance;
    config.min_touches = ::PriceAction_MinTouches;
    config.min_strength = ::PriceAction_MinStrength;
    
    // 신호 생성 설정
    config.use_breakout = ::PriceAction_UseBreakout;
    config.use_bounce = ::PriceAction_UseBounce;
    config.breakout_buffer = ::PriceAction_BreakoutBuffer;
    config.bounce_buffer = ::PriceAction_BounceBuffer;
    
    // 필터 설정
    config.use_volume_filter = ::PriceAction_UseVolumeFilter;
    config.use_momentum_filter = ::PriceAction_UseMomentumFilter;
    config.use_time_filter = ::PriceAction_UseTimeFilter;
    
    // 리스크 관리
    config.risk_reward_ratio = ::PriceAction_RiskRewardRatio;
    config.max_risk_per_trade = 2.0; // 2% 고정
    config.use_trailing_stop = ::PriceAction_UseTrailingStop;
    
    return config;
  }

  /**
   * Gets price stop value.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0f) {
    float _result = 0;
    uint _shift = 0;
    
    if (_method == 0) {
      // 지지/저항 기반 스톱
      double current_price = GetChart().GetPrice(PRICE_BID);
      
      switch (_mode) {
        case ORDER_TYPE_VALUE_STOP:
          if (_cmd == ORDER_TYPE_BUY && last_support_level > 0) {
            // 매수 포지션: 지지선 아래 스톱
            double stop_distance = current_price - last_support_level + 10 * GetChart().GetPointValue();
            _result = (float)stop_distance;
          } else if (_cmd == ORDER_TYPE_SELL && last_resistance_level > 0) {
            // 매도 포지션: 저항선 위 스톱
            double stop_distance = last_resistance_level - current_price + 10 * GetChart().GetPointValue();
            _result = (float)stop_distance;
          } else {
            // 기본값: ATR 기반
            _result = (float)(indi_atr[_shift][0] * 2.0);
          }
          break;
          
        case ORDER_TYPE_VALUE_LIMIT:
          if (_cmd == ORDER_TYPE_BUY && last_resistance_level > 0) {
            // 매수 포지션: 저항선에서 이익실현
            double profit_distance = last_resistance_level - current_price;
            _result = (float)profit_distance;
          } else if (_cmd == ORDER_TYPE_SELL && last_support_level > 0) {
            // 매도 포지션: 지지선에서 이익실현
            double profit_distance = current_price - last_support_level;
            _result = (float)profit_distance;
          } else {
            // 기본값: ATR 기반
            _result = (float)(indi_atr[_shift][0] * ::PriceAction_RiskRewardRatio);
          }
          break;
      }
    }
    
    return (float)_result;
  }

  /**
   * Gets strategy status information.
   */
  string GetStatusInfo() {
    string status = "";
    status += "=== 가격행동 거래 전략 상태 ===\n";
    status += "현재 거래 수: " + IntegerToString(current_trades) + "/" + IntegerToString(::PriceAction_MaxTrades) + "\n";
    
    if (price_action_analyzer != NULL) {
      status += price_action_analyzer.GetStatusInfo();
    }
    
    if (last_support_level > 0) {
      status += "현재 지지선: " + DoubleToString(last_support_level, _Digits) + "\n";
    }
    
    if (last_resistance_level > 0) {
      status += "현재 저항선: " + DoubleToString(last_resistance_level, _Digits) + "\n";
    }
    
    return status;
  }
};

#endif // STG_PRICE_ACTION_TRADING_MQH