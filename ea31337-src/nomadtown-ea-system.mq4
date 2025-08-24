//+------------------------------------------------------------------+
//|           nomadtown-ea-system - 다중 전략 고급 트레이딩 로봇     |
//|           nomadtown-ea-system - multi-strategy advanced trading robot. |
//|                                 Copyright 2016-2023, nomadtown-ea-system Ltd |
//|                                       
//+------------------------------------------------------------------+

// 메인 코드 - 실제 로직은 MQ5 파일에서 가져옴
// Main code.
#include "nomadtown-ea-system.mq5"

// EA 지표 리소스 정의
// EA indicator resources.
#ifdef __resource__
// 지표 리소스 - MT4에서 사용할 커스텀 지표들을 미리 정의
// Indicator resources.
// #resource INDI_ATR_MA_TREND_PATH + MQL_EXT // @todo: MT4에서 지원되지 않음
// #resource INDI_ATR_MA_TREND_PATH + MQL_EXT // @todo: Not supported in MT4.
#resource INDI_EWO_OSC_PATH + MQL_EXT         // 엘리어트 파동 오실레이터
#resource INDI_SVEBB_PATH + MQL_EXT           // SVEBB 볼린저 밴드
#resource INDI_TMA_CG_PATH + MQL_EXT          // TMA Center of Gravity
#resource INDI_TMA_TRUE_PATH + MQL_EXT        // True TMA 지표
#resource INDI_SAWA_PATH + MQL_EXT            // SAWA 지표
// #resource INDI_SUPERTREND_PATH + MQL_EXT // @todo: MT4에서 지원되지 않음
// #resource INDI_SUPERTREND_PATH + MQL_EXT // @todo: Not supported in MT4.

// 전략 리소스 (MQL4 호환성을 위한 우회 방법)
// Strategy resources (MQL4 workaround).
string MetaNewsData2018 = "";  // 2018년 뉴스 데이터
string MetaNewsData2019 = "";  // 2019년 뉴스 데이터
string MetaNewsData2020 = "";  // 2020년 뉴스 데이터
string MetaNewsData2021 = "";  // 2021년 뉴스 데이터
string MetaNewsData2022 = "";  // 2022년 뉴스 데이터
string MetaNewsData2023 = "";  // 2023년 뉴스 데이터
string MetaNewsData2024 = "";  // 2024년 뉴스 데이터
#endif
