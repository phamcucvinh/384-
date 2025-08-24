//+------------------------------------------------------------------+
//|           nomadtown-ea-system - 다중전략 고급 자동매매 로봇     |
//|           nomadtown-ea-system - multi-strategy advanced trading robot. |
//|                                 Copyright 2016-2023, nomadtown-ea-system Ltd |
//|                                       
//+------------------------------------------------------------------+

/*
 *  본 파일은 자유 소프트웨어입니다: GNU 일반 공중 사용 허가서 조건 하에서
 *  자유 소프트웨어 재단에서 발행한 제3판 또는 그 이후 판에 따라 
 *  재배포하거나 수정할 수 있습니다.
 *
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  이 프로그램은 유용할 것이라는 희망으로 배포되지만, 어떠한 보증도 없이
 *  배포됩니다. 상품성 또는 특정 목적에의 적합성에 대한 묵시적 보증조차도 없습니다.
 *  자세한 내용은 GNU 일반 공중 사용 허가서를 참조하세요.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  이 프로그램과 함께 GNU 일반 공중 사용 허가서 사본을 받았어야 합니다.
 *  받지 못했다면 < 참조하세요.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <
 */

// 포함 파일 (Include files)
// 메인 EA 클래스와 필요한 라이브러리 파일들을 포함합니다.
#include "include/ea.h"
#include "include/includes.h"

// EA 속성 정의 (EA properties)
// MetaTrader에서 사용할 EA의 기본 정보를 설정합니다.
#ifdef __property__
#property copyright ea_copy      // 저작권 정보
#property description ea_name    // EA 이름
#property description ea_desc    // EA 설명
#property icon "resources/favicon.ico"  // EA 아이콘
#property link ea_link          // 공식 웹사이트 링크
#property version ea_version    // EA 버전 정보
#endif

// EA 지표 리소스 정의 (EA indicator resources)
// 전략에서 사용할 커스텀 지표들과 뉴스 데이터를 리소스로 포함합니다.
#ifdef __resource__
#ifdef __MQL5__
// 테스터 속성 (Tester properties)
// Strategy Tester에서 사용할 지표들을 미리 정의합니다.
#property tester_indicator "::" + INDI_ATR_MA_TREND_PATH + MQL_EXT  // ATR 이동평균 추세 지표
#property tester_indicator "::" + INDI_EWO_OSC_PATH + MQL_EXT       // 엘리어트 웨이브 오실레이터
#property tester_indicator "::" + INDI_SVEBB_PATH + MQL_EXT         // SVEBB (볼린저 밴드 변형)
#property tester_indicator "::" + INDI_TMA_CG_PATH + MQL_EXT        // TMA 무게중심 지표
#property tester_indicator "::" + INDI_TMA_TRUE_PATH + MQL_EXT      // True TMA 지표
#property tester_indicator "::" + INDI_SAWA_PATH + MQL_EXT          // SAWA 지표
#property tester_indicator "::" + INDI_SUPERTREND_PATH + MQL_EXT    // 슈퍼트렌드 지표

// 지표 리소스 (Indicator resources)
// 실제 사용할 커스텀 지표 파일들을 리소스로 포함합니다.
#resource INDI_ATR_MA_TREND_PATH + MQL_EXT  // ATR 이동평균 추세 지표 파일
#resource INDI_EWO_OSC_PATH + MQL_EXT       // 엘리어트 웨이브 오실레이터 파일
#resource INDI_SVEBB_PATH + MQL_EXT         // SVEBB 지표 파일
#resource INDI_TMA_CG_PATH + MQL_EXT        // TMA 무게중심 지표 파일
#resource INDI_TMA_TRUE_PATH + MQL_EXT      // True TMA 지표 파일
#resource INDI_SAWA_PATH + MQL_EXT          // SAWA 지표 파일
#resource INDI_SUPERTREND_PATH + MQL_EXT    // 슈퍼트렌드 지표 파일

// 전략 리소스 (Strategy resources - MQL5 전용)
// 뉴스 기반 거래 전략에서 사용할 경제 뉴스 데이터 파일들입니다.
#resource "\\strategies-meta\\Meta_News\\data\\news2018.csv" as string MetaNewsData2018  // 2018년 뉴스 데이터
#resource "\\strategies-meta\\Meta_News\\data\\news2019.csv" as string MetaNewsData2019  // 2019년 뉴스 데이터
#resource "\\strategies-meta\\Meta_News\\data\\news2020.csv" as string MetaNewsData2020  // 2020년 뉴스 데이터
#resource "\\strategies-meta\\Meta_News\\data\\news2021.csv" as string MetaNewsData2021  // 2021년 뉴스 데이터
#resource "\\strategies-meta\\Meta_News\\data\\news2022.csv" as string MetaNewsData2022  // 2022년 뉴스 데이터
#resource "\\strategies-meta\\Meta_News\\data\\news2023.csv" as string MetaNewsData2023  // 2023년 뉴스 데이터
#resource "\\strategies-meta\\Meta_News\\data\\news2024.csv" as string MetaNewsData2024  // 2024년 뉴스 데이터
#endif
#endif

// 전역 변수 (Global variables)
// 메인 EA 인스턴스를 담을 전역 포인터 변수입니다.
nomadtown_ea_system *ea;

/* EA 이벤트 핸들러 함수들 (EA event handler functions) */

/**
 * Expert Advisor 초기화 함수 (Initialization function of the expert)
 * 
 * EA가 차트에 로드될 때 한 번 실행됩니다.
 * 모든 전략과 설정을 초기화하고 EA를 거래 준비 상태로 만듭니다.
 * 
 * @return INIT_SUCCEEDED (성공) 또는 INIT_FAILED (실패)
 */
int OnInit() {
  bool _initiated = true;  // 초기화 성공 여부를 추적하는 변수
  EAParams _ea_params(__FILE__, VerboseLevel);  // EA 매개변수 객체 생성
  
  // EA 기본 정보 설정 (EA basic information setup)
  _ea_params.SetDetails(ea_name, ea_desc, ea_version, StringFormat("%s (%s)", ea_author, ea_link));
  
  // 위험 관리 매개변수 설정 (Risk management parameters setup)
  _ea_params.Set(STRUCT_ENUM(EAParams, EA_PARAM_PROP_RISK_MARGIN_MAX), EA_Risk_MarginMax);  // 최대 마진 위험도 설정
  _ea_params.SetFlag(EA_PARAM_FLAG_LOTSIZE_AUTO, EA_LotSize <= 0);  // 자동 로트 크기 계산 활성화
  
  // EA 인스턴스 초기화 (Initialize EA instance)
  ea = new nomadtown_ea_system(_ea_params);
  ea.Set(STRAT_PARAM_MAX_SPREAD, EA_MaxSpread);    // 최대 스프레드 설정
  ea.Set(TRADE_PARAM_RISK_MARGIN, EA_Risk_MarginMax);  // 거래 위험 마진 설정
  
  // 자동 거래가 허용되는지 확인 (Check if automated trading is allowed)
  if (ea.Get(STRUCT_ENUM(EAState, EA_STATE_FLAG_TRADE_ALLOWED))) {
    _initiated &= InitStrategies();  // 거래 전략들 초기화
    
#ifdef __advanced__
    // 고급 버전에서 추가 작업(Task) 설정 (Advanced version task setup)
    if (_initiated && EA_Tasks_Filter != 0) {
      _initiated &= METHOD(EA_Tasks_Filter, 0) ? ea.TaskAdd(ea.GetTaskEntry(EA_Task1_If, EA_Task1_Then)) : true;  // 작업 1 추가
      _initiated &= METHOD(EA_Tasks_Filter, 1) ? ea.TaskAdd(ea.GetTaskEntry(EA_Task2_If, EA_Task2_Then)) : true;  // 작업 2 추가
      _initiated &= METHOD(EA_Tasks_Filter, 2) ? ea.TaskAdd(ea.GetTaskEntry(EA_Task3_If, EA_Task3_Then)) : true;  // 작업 3 추가
      _initiated &= METHOD(EA_Tasks_Filter, 3) ? ea.TaskAdd(ea.GetTaskEntry(EA_Task4_If, EA_Task4_Then)) : true;  // 작업 4 추가
      _initiated &= METHOD(EA_Tasks_Filter, 4) ? ea.TaskAdd(ea.GetTaskEntry(EA_Task5_If, EA_Task5_Then)) : true;  // 작업 5 추가
    }
#endif
  } else {
    // 자동 거래가 허용되지 않는 경우 오류 메시지 출력
    string _err_msg_tna =
        "Trading is not allowed for this symbol, please enable automated trading or check the settings!";
    ea.GetLogger().Error(_err_msg_tna, __FUNCTION_LINE__);
    Alert(_err_msg_tna);
    _initiated &= false;
  }
  
  // 초기화 중 오류 발생 시 로깅 (Log errors during initialization)
  if (!_initiated || _LastError > 0) {
    ea.GetLogger().Error("Error during initializing!", __FUNCTION_LINE__, Terminal::GetLastErrorText());
  }
  
  // 차트에 시작 정보 표시 (Display startup info on chart)
  if (EA_DisplayDetailsOnChart) {
    ea.PrintStartupInfo(true);
  }
  
  ea.GetLogger().Flush();  // 로그 버퍼 플러시
  Chart::WindowRedraw();   // 차트 다시 그리기
  
  // 초기화 실패 시 EA 비활성화 (Disable EA if initialization failed)
  if (!_initiated) {
    ea.Set(STRUCT_ENUM(EAState, EA_STATE_FLAG_ENABLED), false);
  }
  
  return (_initiated ? INIT_SUCCEEDED : INIT_FAILED);
}

/**
 * Expert Advisor 해제 함수 (Deinitialization function of the expert)
 * 
 * EA가 차트에서 제거되거나 터미널이 종료될 때 실행됩니다.
 * 모든 리소스를 정리하고 메모리를 해제합니다.
 * 
 * @param reason 해제 이유 코드
 */
void OnDeinit(const int reason) { 
  DeinitVars();  // 전역 변수들 정리 및 메모리 해제
}

/**
 * 틱 이벤트 핸들러 함수 ("Tick" event handler function - EA 전용)
 *
 * EA가 부착된 차트의 심볼에 새로운 틱이 수신될 때마다 호출됩니다.
 * 이 함수에서 실제 거래 로직이 실행됩니다.
 * 
 * Invoked when a new tick for a symbol is received, to the chart of which the Expert Advisor is attached.
 */
void OnTick() { 
  ea.OnTick(SymbolInfoStatic::GetTick(_Symbol));  // EA의 메인 틱 처리 함수 호출
}

#ifdef __MQL5__
/**
 * 거래 이벤트 핸들러 함수 ("Trade" event handler function - MQL5 전용)
 *
 * 거래 서버에서 거래 작업이 완료될 때 호출됩니다.
 * 주문 체결, 변경, 취소 등의 이벤트를 처리할 수 있습니다.
 *
 * Invoked when a trade operation is completed on a trade server.
 */
void OnTrade() {
  // 현재 구현되지 않음 - 필요시 거래 이벤트 처리 로직 추가
}

/**
 * 거래 트랜잭션 이벤트 핸들러 함수 ("OnTradeTransaction" event handler function - MQL5 전용)
 *
 * 거래 계정에서 특정 작업을 수행하여 상태가 변경될 때 호출됩니다.
 * 주문 전송, 체결, 수정 등의 모든 거래 이벤트를 추적할 수 있습니다.
 *
 * Invoked when performing some definite actions on a trade account, its state changes.
 * 
 * @param trans 거래 트랜잭션 구조체 (Trade transaction structure)
 * @param request 요청 구조체 (Request structure) 
 * @param result 결과 구조체 (Result structure)
 */
void OnTradeTransaction(const MqlTradeTransaction &trans,  // 거래 트랜잭션 구조체
                        const MqlTradeRequest &request,    // 요청 구조체
                        const MqlTradeResult &result       // 결과 구조체
) {
  // 현재 구현되지 않음 - 필요시 트랜잭션 처리 로직 추가
}

/**
 * 타이머 이벤트 핸들러 함수 ("Timer" event handler function - MQL5 전용)
 *
 * EventSetTimer 함수로 타이머를 활성화한 EA에 의해 주기적으로 호출됩니다.
 * 일반적으로 이 함수는 OnInit에서 타이머를 설정한 후 사용됩니다.
 * 주기적인 작업(보고서 생성, 데이터 업데이트 등)에 사용할 수 있습니다.
 *
 * Invoked periodically generated by the EA that has activated the timer by the EventSetTimer function.
 * Usually, this function is called by OnInit.
 */
void OnTimer() {
  // 현재 구현되지 않음 - 필요시 주기적 작업 로직 추가
}

/**
 * 테스터 초기화 이벤트 핸들러 함수 ("TesterInit" event handler function - MQL5 전용)
 *
 * 전략 테스터에서 최적화 시작 시, 첫 번째 최적화 패스 이전에 호출됩니다.
 * 최적화를 위한 초기 설정이나 데이터 준비에 사용할 수 있습니다.
 *
 * The start of optimization in the strategy tester before the first optimization pass.
 * Invoked with the start of optimization in the strategy tester.
 *
 * @see: 
 */
void TesterInit() {
  // 현재 구현되지 않음 - 필요시 테스터 초기화 로직 추가
}

/**
 * 테스터 이벤트 핸들러 함수 ("OnTester" event handler function)
 *
 * 선택된 기간에 대한 Expert Advisor의 역사 테스트가 끝난 후 호출됩니다.
 * OnDeinit() 호출 직전에 실행됩니다.
 * 입력 매개변수의 유전자 최적화에서 Custom max 기준으로 사용될 계산된 값을 반환합니다.
 *
 * Invoked after a history testing of an Expert Advisor on the chosen interval is over.
 * It is called right before the call of OnDeinit().
 * Returns calculated value that is used as the Custom max criterion
 * in the genetic optimization of input parameters.
 *
 * @return 최적화에 사용될 커스텀 기준 값 (Custom criterion value for optimization)
 * @see: 
 */
// double OnTester() { return 1.0; }  // 필요시 활성화하여 커스텀 최적화 기준 사용

/**
 * 테스터 패스 이벤트 핸들러 함수 ("OnTesterPass" event handler function - MQL5 전용)
 *
 * 전략 테스터에서 Expert Advisor 최적화 중 프레임이 수신될 때 호출됩니다.
 * 최적화 진행 상황을 모니터링하거나 중간 결과를 처리할 때 사용합니다.
 *
 * Invoked when a frame is received during Expert Advisor optimization in the strategy tester.
 *
 * @see: 
 */
void OnTesterPass() {
  // 현재 구현되지 않음 - 필요시 최적화 패스 처리 로직 추가
}

/**
 * 테스터 해제 이벤트 핸들러 함수 ("OnTesterDeinit" event handler function - MQL5 전용)
 *
 * 전략 테스터에서 Expert Advisor 최적화가 끝난 후 호출됩니다.
 * 최적화 종료 후 정리 작업이나 결과 저장 등에 사용할 수 있습니다.
 *
 * Invoked after the end of Expert Advisor optimization in the strategy tester.
 *
 * @see: 
 */
void OnTesterDeinit() {
  // 현재 구현되지 않음 - 필요시 최적화 종료 처리 로직 추가
}

/**
 * 주문장 이벤트 핸들러 함수 ("OnBookEvent" event handler function - MQL5 전용)
 *
 * 주문장 심도(Depth of Market) 변경 시 호출됩니다.
 * 사전 구독을 위해 MarketBookAdd() 함수를 사용하고,
 * 특정 심볼의 구독을 취소하려면 MarketBookRelease()를 호출합니다.
 *
 * Invoked on Depth of Market changes.
 * To pre-subscribe use the MarketBookAdd() function.
 * In order to unsubscribe for a particular symbol, call MarketBookRelease().
 * 
 * @param symbol 주문장 변경이 발생한 심볼 이름
 */
void OnBookEvent(const string &symbol) {
  // 현재 구현되지 않음 - 필요시 주문장 이벤트 처리 로직 추가
}

/**
 * 차트 이벤트 핸들러 함수 ("OnChartEvent" event handler function - MQL5 전용)
 *
 * 사용자가 차트로 작업할 때 클라이언트 터미널에 의해 호출됩니다.
 * 마우스 클릭, 키보드 입력, 객체 이동 등의 차트 이벤트를 처리합니다.
 *
 * Invoked by the client terminal when a user is working with a chart.
 * 
 * @param id 이벤트 ID (Event ID)
 * @param lparam long 타입 이벤트 매개변수 (Parameter of type long event)
 * @param dparam double 타입 이벤트 매개변수 (Parameter of type double event)
 * @param sparam string 타입 이벤트 매개변수 (Parameter of type string events)
 */
void OnChartEvent(const int id,          // 이벤트 ID
                  const long &lparam,    // long 타입 매개변수
                  const double &dparam,  // double 타입 매개변수
                  const string &sparam   // string 타입 매개변수
) {
  // 현재 구현되지 않음 - 필요시 차트 이벤트 처리 로직 추가
}

// @todo: OnTradeTransaction (
#endif  // end: __MQL5__

/* 커스텀 EA 함수들 (Custom EA functions) */
// EA의 고유 기능을 구현하는 커스텀 함수들입니다.

/**
 * 전략 초기화 함수 (Initialize strategies)
 * 
 * EA에서 사용할 모든 거래 전략들을 초기화합니다.
 * 시간프레임별로 다른 전략을 설정하고, 위험 관리 매개변수를 적용합니다.
 * 
 * @return true: 초기화 성공, false: 초기화 실패
 */
bool InitStrategies() {
  bool _res = ea_exists;  // 초기화 결과를 추적하는 변수
  int _magic_step = FINAL_ENUM_TIMEFRAMES_INDEX;  // 매직 넘버 단계
  long _magic_no = EA_MagicNumber;  // EA 매직 넘버
  ResetLastError();  // 이전 오류 코드 초기화
#ifdef __elite__
  // 엘리트 전략 초기화 (Initialize Elite strategy)
  // 엘리트 버전에서는 단일 고급 전략을 사용합니다.
  _res &= ea.StrategyAddToTfs(EA_Strategy1_Main, EA_Strategy1_Tfs);
  
  // 메인 전략 1 - 신호 필터 설정 (Main Strategy 1 - Signal filters)
  ea.Set(STRAT_PARAM_SOFM, EA_Strategy1_SignalOpenFilterMethod);   // 매수 신호 열기 필터 방법
  ea.Set(STRAT_PARAM_SCFM, EA_Strategy1_SignalCloseFilterMethod);  // 매수 신호 닫기 필터 방법
  ea.Set(STRAT_PARAM_SOFT, EA_Strategy1_SignalOpenFilterTime);     // 매수 신호 열기 필터 시간
  ea.Set(STRAT_PARAM_TFM, EA_Strategy1_TickFilterMethod);          // 틱 필터 방법
  
  // 메인 전략 1 - 주문 제한 설정 (Main Strategy 1 - Orders' limits)
  ea.Set(STRAT_PARAM_OCL, EA_Strategy1_OrderCloseLoss);    // 주문 손실 마감 설정
  ea.Set(STRAT_PARAM_OCP, EA_Strategy1_OrderCloseProfit);  // 주문 이익 마감 설정
  ea.Set(STRAT_PARAM_OCT, EA_Strategy1_OrderCloseTime);    // 주문 시간 마감 설정
#else
  // 시간프레임별 전략 초기화 (Initialize strategies per timeframe)
  // 각 시간프레임에 다른 전략을 할당하여 다각화된 거래를 수행합니다.
  _res &= METHOD(EA_Strategy_Filter, 0) ? ea.StrategyAddToTfs(Strategy_M1, 1 << M1) : true;    // 1분 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 1) ? ea.StrategyAddToTfs(Strategy_M5, 1 << M5) : true;    // 5분 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 2) ? ea.StrategyAddToTfs(Strategy_M15, 1 << M15) : true;  // 15분 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 3) ? ea.StrategyAddToTfs(Strategy_M30, 1 << M30) : true;  // 30분 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 4) ? ea.StrategyAddToTfs(Strategy_H1, 1 << H1) : true;    // 1시간 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 5) ? ea.StrategyAddToTfs(Strategy_H2, 1 << H2) : true;    // 2시간 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 6) ? ea.StrategyAddToTfs(Strategy_H3, 1 << H3) : true;    // 3시간 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 7) ? ea.StrategyAddToTfs(Strategy_H4, 1 << H4) : true;    // 4시간 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 8) ? ea.StrategyAddToTfs(Strategy_H6, 1 << H6) : true;    // 6시간 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 9) ? ea.StrategyAddToTfs(Strategy_H8, 1 << H8) : true;    // 8시간 차트 전략
  _res &= METHOD(EA_Strategy_Filter, 10) ? ea.StrategyAddToTfs(Strategy_H12, 1 << H12) : true; // 12시간 차트 전략
#endif
  // 로트 크기 업데이트 (Update lot size)
  ea.Set(STRAT_PARAM_LS, EA_LotSize);
  
  // 최대 스프레드 값 설정 (Override max spread values)
  ea.Set(STRAT_PARAM_MAX_SPREAD, EA_MaxSpread);
  // ea.Set(TRADE_PARAM_MAX_SPREAD, EA_MaxSpread);
  
#ifdef __advanced__
  // 고급 버전 신호 필터 설정 (Advanced version signal filter setup)
  ea.Set(STRAT_PARAM_SOFM, EA_SignalOpenFilterMethod);   // 신호 열기 필터 방법
  ea.Set(STRAT_PARAM_SCFM, EA_SignalCloseFilterMethod);  // 신호 닫기 필터 방법
  ea.Set(STRAT_PARAM_SOFT, EA_SignalOpenFilterTime);     // 신호 열기 필터 시간
  ea.Set(STRAT_PARAM_TFM, EA_TickFilterMethod);          // 틱 필터 방법
  // ea.Set(STRUCT_ENUM(EAParams, EA_PARAM_PROP_SIGNAL_FILTER), EA_SignalOpenStrategyFilter); // @fixme
  
#ifdef __rider__
  // 라이더 버전을 위한 전략 정의 주문 마감 비활성화 (Disables strategy defined order closures for Rider)
  ea.Set(STRAT_PARAM_OCL, 0);  // 주문 손실 마감 비활성화
  ea.Set(STRAT_PARAM_OCP, 0);  // 주문 이익 마감 비활성화
  ea.Set(STRAT_PARAM_OCT, 0);  // 주문 시간 마감 비활성화
  
  // 모든 시간프레임에 대한 가격 정지 방법 초기화 (Init price stop methods for all timeframes)
  ea.StrategyAddStops(NULL, EA_Stops_Strat, EA_Stops_Tf);
#else
  // 표준 버전 주문 마감 설정 (Standard version order closure settings)
  ea.Set(STRAT_PARAM_OCL, EA_OrderCloseLoss);    // 주문 손실 마감 설정
  ea.Set(STRAT_PARAM_OCP, EA_OrderCloseProfit);  // 주문 이익 마감 설정
  ea.Set(STRAT_PARAM_OCT, EA_OrderCloseTime);    // 주문 시간 마감 설정
  
  // 각 시간프레임에 대한 가격 정지 방법 초기화 (Init price stop methods for each timeframe)
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_M1), EA_Stops_M1, PERIOD_M1);    // 1분 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_M5), EA_Stops_M5, PERIOD_M5);    // 5분 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_M15), EA_Stops_M15, PERIOD_M15); // 15분 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_M30), EA_Stops_M30, PERIOD_M30); // 30분 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H1), EA_Stops_H1, PERIOD_H1);    // 1시간 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H2), EA_Stops_H2, PERIOD_H2);    // 2시간 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H3), EA_Stops_H3, PERIOD_H3);    // 3시간 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H4), EA_Stops_H4, PERIOD_H4);    // 4시간 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H6), EA_Stops_H6, PERIOD_H6);    // 6시간 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H8), EA_Stops_H8, PERIOD_H8);    // 8시간 정지
  _res &= ea.StrategyAddStops(ea.GetStrategyViaProp<int>(STRAT_PARAM_TF, PERIOD_H12), EA_Stops_H12, PERIOD_H12); // 12시간 정지
#endif                                                    // __rider__
#endif                                                    // __advanced__
  
  // 오류 확인 및 처리 (Error checking and handling)
  _res &= GetLastError() == 0 || GetLastError() == 5053;  // @fixme: error 5053?
  ResetLastError();  // 오류 코드 재설정
  
  return _res && ea_configured;  // 초기화 결과와 EA 구성 상태 반환
}

/**
 * 전역 클래스 변수 해제 함수 (Deinitialize global class variables)
 * 
 * EA 종료 시 동적으로 할당된 메모리를 정리하고 리소스를 해제합니다.
 * 메모리 누수를 방지하기 위해 모든 객체를 안전하게 삭제합니다.
 */
void DeinitVars() { 
  Object::Delete(ea);  // EA 객체 삭제 및 메모리 해제
}
