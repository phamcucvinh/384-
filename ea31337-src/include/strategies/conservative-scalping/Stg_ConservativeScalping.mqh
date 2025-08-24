//+------------------------------------------------------------------+
//|                                      Stg_ConservativeScalping.mqh |
//|                               보수적 스캘핑 전략 (EA31337 통합용)     |
//|                                  Conservative Scalping Strategy  |
//+------------------------------------------------------------------+

/**
 * @file
 * 보수적 스캘핑 전략 구현
 * 안전성 최우선, Price_Swings + ATR_MA_Trend 이중 확인 시스템
 */

// Prevents processing this includes file multiple times.
#ifndef STG_CONSERVATIVE_SCALPING_MQH
#define STG_CONSERVATIVE_SCALPING_MQH

// Includes.
#include <EA31337-classes/Indicators/Indi_ATR.mqh>
#include <EA31337-classes/Indicators/Indi_MA.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT_GROUP("Conservative Scalping strategy: main params");
INPUT float ConservativeScalping_LotSize = 0.01f;                    // 거래량 (Lot size)
INPUT int ConservativeScalping_MaxTrades = 2;                        // 최대 거래 수 (Max trades)  
INPUT float ConservativeScalping_MaxSpread = 1.5f;                   // 최대 스프레드 (Max spread)
INPUT_GROUP("Conservative Scalping strategy: signal params");
INPUT int ConservativeScalping_ATRPeriod = 20;                       // ATR 기간 (ATR period)
INPUT float ConservativeScalping_ATRSensitivity = 1.0f;              // ATR 민감도 (ATR sensitivity) 
INPUT int ConservativeScalping_MAPeriod = 30;                        // MA 기간 (MA period)
INPUT int ConservativeScalping_SwingPeriod = 15;                     // 스윙 기간 (Swing period)
INPUT float ConservativeScalping_SwingThreshold = 0.35f;             // 스윙 임계값 (Swing threshold)
INPUT_GROUP("Conservative Scalping strategy: risk params");
INPUT float ConservativeScalping_StopLoss = 8.0f;                    // 손절매 pips (Stop loss in pips)
INPUT float ConservativeScalping_TakeProfit = 12.0f;                 // 익절 pips (Take profit in pips)
INPUT bool ConservativeScalping_RequireBothSignals = true;           // 이중 신호 필수 (Require both signals)
INPUT_GROUP("Conservative Scalping strategy: filter params");
INPUT int ConservativeScalping_SignalOpenMethod = 0;                 // 신호 열기 방법 (Signal open method)
INPUT float ConservativeScalping_SignalOpenLevel = 0;                // 신호 열기 레벨 (Signal open level)
INPUT int ConservativeScalping_SignalOpenFilterMethod = 32;          // 신호 열기 필터 방법 (Signal open filter method)
INPUT int ConservativeScalping_SignalOpenFilterTime = 3;             // 신호 열기 필터 시간 (Signal open filter time)
INPUT int ConservativeScalping_SignalOpenBoostMethod = 0;            // 신호 열기 부스트 방법 (Signal open boost method)
INPUT int ConservativeScalping_SignalCloseMethod = 0;                // 신호 닫기 방법 (Signal close method)
INPUT int ConservativeScalping_SignalCloseFilter = 32;               // 신호 닫기 필터 (Signal close filter)
INPUT float ConservativeScalping_SignalCloseLevel = 0;               // 신호 닫기 레벨 (Signal close level)
INPUT int ConservativeScalping_PriceStopMethod = 1;                  // 가격 정지 방법 (Price stop method)
INPUT float ConservativeScalping_PriceStopLevel = 2;                 // 가격 정지 레벨 (Price stop level)
INPUT int ConservativeScalping_TickFilterMethod = 32;                // 틱 필터 방법 (Tick filter method)
INPUT float ConservativeScalping_MaxSpreadToTrade = 1.5f;            // 거래할 최대 스프레드 (Max spread to trade)

// Structs.
// Defines struct with default user strategy values.
struct Stg_ConservativeScalping_Params_Defaults : StgParams {
  Stg_ConservativeScalping_Params_Defaults()
      : StgParams(::ConservativeScalping_SignalOpenMethod, ::ConservativeScalping_SignalOpenFilterMethod,
                  ::ConservativeScalping_SignalOpenLevel, ::ConservativeScalping_SignalOpenBoostMethod,
                  ::ConservativeScalping_SignalCloseMethod, ::ConservativeScalping_SignalCloseFilter,
                  ::ConservativeScalping_SignalCloseLevel, ::ConservativeScalping_PriceStopMethod,
                  ::ConservativeScalping_PriceStopLevel, ::ConservativeScalping_TickFilterMethod,
                  ::ConservativeScalping_MaxSpreadToTrade, ::ConservativeScalping_SignalOpenFilterTime) {
    Set(STRAT_PARAM_LS, ::ConservativeScalping_LotSize);
    Set(STRAT_PARAM_OCL, ::ConservativeScalping_StopLoss);
    Set(STRAT_PARAM_OCP, ::ConservativeScalping_TakeProfit);
    Set(STRAT_PARAM_OCT, 0);
    Set(STRAT_PARAM_SOFT, ::ConservativeScalping_SignalOpenFilterTime);
  }
};

class Stg_ConservativeScalping : public Strategy {
 protected:
  Indi_ATR *indi_atr;
  Indi_MA *indi_ma;
  int current_trades;
  bool trend_direction;
  double last_atr_value;
  datetime last_trade_time;
  bool last_trade_was_loss;
  int loss_streak_count;

 public:
  static Stg_ConservativeScalping *Init(ENUM_TIMEFRAMES _tf = NULL, EA *_ea = NULL) {
    // Initialize strategy initial values.
    Stg_ConservativeScalping_Params_Defaults stg_conservative_scalping_defaults;
    StgParams _stg_params(stg_conservative_scalping_defaults);
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_ConservativeScalping(_stg_params, _tparams, _cparams, "ConservativeScalping");
    return _strat;
  }

  /**
   * Class constructor.
   */
  Stg_ConservativeScalping(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {
    current_trades = 0;
    trend_direction = true;
    last_atr_value = 0;
    last_trade_time = 0;
    last_trade_was_loss = false;
    loss_streak_count = 0;
  }

  /**
   * Initialize strategy.
   */
  bool Init() {
    if (!Strategy::Init()) return false;
    
    // Initialize indicators.
    indi_atr = new Indi_ATR(IndiATRParams(::ConservativeScalping_ATRPeriod), ::ConservativeScalping_ATRPeriod, indi_mode);
    indi_ma = new Indi_MA(IndiMAParams(::ConservativeScalping_MAPeriod, 0, MODE_EMA, PRICE_CLOSE), ::ConservativeScalping_MAPeriod, indi_mode);
    
    return SetIndicators(indi_atr, indi_ma);
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    bool _result = false;
    
    // 보수적 안전 검사
    if (!ConservativeSafetyCheck()) {
      return false;
    }
    
    // 현재 거래 수 제한
    if (current_trades >= ::ConservativeScalping_MaxTrades) {
      return false;
    }
    
    // 스프레드 체크
    if (!IsSpreadAcceptable()) {
      return false;
    }
    
    // ATR MA Trend 신호
    bool atr_signal = AnalyzeATRMATrend(_shift);
    
    // Price Swings 신호
    bool swing_signal = AnalyzePriceSwings(_shift);
    
    // 이중 신호 확인 필수
    if (::ConservativeScalping_RequireBothSignals) {
      if (!atr_signal || !swing_signal) {
        return false;
      }
    } else {
      if (!atr_signal && !swing_signal) {
        return false;
      }
    }
    
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = trend_direction && (atr_signal && swing_signal);
        break;
      case ORDER_TYPE_SELL:
        _result = !trend_direction && (atr_signal && swing_signal);
        break;
    }
    
    if (_result) {
      current_trades++;
      last_trade_time = TimeCurrent();
    }
    
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    bool _result = false;
    
    // 반대 신호 발생 시 청산
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        // 매수 포지션 - 매도 신호 시 청산
        _result = !trend_direction && AnalyzeATRMATrend(_shift);
        break;
      case ORDER_TYPE_SELL:
        // 매도 포지션 - 매수 신호 시 청산
        _result = trend_direction && AnalyzeATRMATrend(_shift);
        break;
    }
    
    return _result;
  }

 protected:
  /**
   * ATR MA Trend 분석
   */
  bool AnalyzeATRMATrend(int _shift = 0) {
    double atr_current = indi_atr[_shift][0];
    double atr_prev = indi_atr[_shift + 1][0];
    
    double ma_current = indi_ma[_shift][0];
    double ma_prev = indi_ma[_shift + 1][0];
    
    double price_current = GetChart().GetPrice(PRICE_CLOSE, _shift);
    double price_prev = GetChart().GetPrice(PRICE_CLOSE, _shift + 1);
    
    // 변동성 기반 임계값
    double threshold = atr_current * ::ConservativeScalping_ATRSensitivity;
    
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

  /**
   * Price Swings 분석
   */
  bool AnalyzePriceSwings(int _shift = 0) {
    Chart *_chart = GetChart();
    
    // 최근 고점/저점 수집
    double swing_high = 0;
    double swing_low = DBL_MAX;
    
    for (int i = _shift; i < _shift + ::ConservativeScalping_SwingPeriod; i++) {
      double high = _chart.GetPrice(PRICE_HIGH, i);
      double low = _chart.GetPrice(PRICE_LOW, i);
      
      if (high > swing_high) swing_high = high;
      if (low < swing_low) swing_low = low;
    }
    
    // 현재 가격과 스윙 포인트 비교
    double current_price = _chart.GetPrice(PRICE_CLOSE, _shift);
    double prev_price = _chart.GetPrice(PRICE_CLOSE, _shift + 1);
    
    // 스윙 신호 생성
    double swing_range = swing_high - swing_low;
    double threshold = swing_range * ::ConservativeScalping_SwingThreshold;
    
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

  /**
   * 스프레드 체크
   */
  bool IsSpreadAcceptable() {
    double spread = GetChart().GetSpreadInPts();
    return spread <= ::ConservativeScalping_MaxSpread;
  }

  /**
   * 보수적 안전 검사
   */
  bool ConservativeSafetyCheck() {
    // 연속 손실 체크
    if (loss_streak_count >= 3) {
      // 3회 연속 손실 시 1시간 대기
      if (TimeCurrent() - last_trade_time < 3600) {
        return false;
      } else {
        loss_streak_count = 0; // 시간이 지났으면 리셋
      }
    }
    
    // 마지막 거래와의 시간 간격 체크 (최소 2분)
    if (TimeCurrent() - last_trade_time < 120) {
      return false;
    }
    
    // 변동성 체크
    if (indi_atr[0][0] < 0.0002) {
      return false;
    }
    
    return true;
  }

  /**
   * 거래 결과 처리
   */
  void OnTradeResult(bool is_profit) {
    if (is_profit) {
      loss_streak_count = 0;
      last_trade_was_loss = false;
    } else {
      loss_streak_count++;
      last_trade_was_loss = true;
    }
    
    if (current_trades > 0) {
      current_trades--;
    }
  }

  /**
   * Gets price stop value.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0f) {
    float _result = 0;
    uint _shift = 0;
    
    if (_method == 0) {
      // ATR 기반 스톱
      double atr_value = indi_atr[_shift][0];
      
      switch (_mode) {
        case ORDER_TYPE_VALUE_STOP:
          _result = (float)(atr_value * 2.0); // 보수적: ATR의 2배
          break;
        case ORDER_TYPE_VALUE_LIMIT:
          _result = (float)(atr_value * 1.5); // 보수적: ATR의 1.5배
          break;
      }
    }
    
    return (float)_result;
  }
};

#endif // STG_CONSERVATIVE_SCALPING_MQH