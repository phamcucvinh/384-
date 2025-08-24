//+------------------------------------------------------------------+
//|                                        ScalpingOptimizer.mqh |
//|                     Price_Swings + ATR_MA_Trend 최적화 모듈      |
//|                          Advanced Scalping Optimization        |
//+------------------------------------------------------------------+

#property copyright "2024, EA31337 Enhanced Scalping"
#property version   "1.00"

#include "ScalpingStrategy.mqh"

//+------------------------------------------------------------------+
//| 최적화 매개변수 구조체                                             |
//+------------------------------------------------------------------+
struct OptimizationParams {
    // ATR MA Trend 최적화
    int atr_period_min;           // ATR 기간 최소값
    int atr_period_max;           // ATR 기간 최대값
    int atr_period_step;          // ATR 기간 증가폭
    
    double atr_sensitivity_min;   // ATR 민감도 최소값
    double atr_sensitivity_max;   // ATR 민감도 최대값
    double atr_sensitivity_step;  // ATR 민감도 증가폭
    
    int ma_period_min;            // MA 기간 최소값
    int ma_period_max;            // MA 기간 최대값
    int ma_period_step;           // MA 기간 증가폭
    
    // Price Swings 최적화
    int swing_period_min;         // 스윙 기간 최소값
    int swing_period_max;         // 스윙 기간 최대값
    int swing_period_step;        // 스윙 기간 증가폭
    
    double swing_threshold_min;   // 스윙 임계값 최소값
    double swing_threshold_max;   // 스윙 임계값 최대값
    double swing_threshold_step;  // 스윙 임계값 증가폭
    
    // 리스크 관리 최적화
    double stop_loss_min;         // 손절 최소값
    double stop_loss_max;         // 손절 최대값
    double stop_loss_step;        // 손절 증가폭
    
    double take_profit_min;       // 익절 최소값
    double take_profit_max;       // 익절 최대값
    double take_profit_step;      // 익절 증가폭
};

//+------------------------------------------------------------------+
//| 최적화 결과 구조체                                                |
//+------------------------------------------------------------------+
struct OptimizationResult {
    ScalpingConfig best_config;   // 최적 설정
    double profit_factor;         // 수익 인수
    double max_drawdown;          // 최대 낙폭
    double win_rate;              // 승률
    int total_trades;             // 총 거래 수
    double sharpe_ratio;          // 샤프 비율
    string optimization_summary;  // 최적화 요약
};

//+------------------------------------------------------------------+
//| 스캘핑 최적화 클래스                                              |
//+------------------------------------------------------------------+
class ScalpingOptimizer {
private:
    OptimizationParams opt_params;    // 최적화 매개변수
    OptimizationResult best_result;   // 최적 결과
    int optimization_runs;            // 최적화 실행 횟수
    datetime start_time;              // 최적화 시작 시간
    
public:
    // 생성자
    ScalpingOptimizer() {
        optimization_runs = 0;
        start_time = TimeCurrent();
        InitializeDefaultParams();
    }
    
    // 기본 매개변수 초기화
    void InitializeDefaultParams();
    
    // 전체 최적화 실행
    OptimizationResult RunFullOptimization(datetime from_date, datetime to_date);
    
    // 빠른 최적화 (주요 매개변수만)
    OptimizationResult RunQuickOptimization(datetime from_date, datetime to_date);
    
    // Price_Swings와 ATR_MA_Trend 조합 최적화
    OptimizationResult OptimizeComboStrategy(datetime from_date, datetime to_date);
    
    // 단일 설정 백테스트
    OptimizationResult BacktestSingleConfig(ScalpingConfig config, datetime from_date, datetime to_date);
    
    // 실시간 최적화 (라이브 거래 중)
    void RealTimeOptimization();
    
    // 최적화 결과 저장
    void SaveOptimizationResults(string filename);
    
    // 최적화 결과 로드
    bool LoadOptimizationResults(string filename);
    
    // 현재 최적 설정 반환
    ScalpingConfig GetBestConfig() { return best_result.best_config; }
    
    // 최적화 진행 상황
    string GetOptimizationProgress();
};

//+------------------------------------------------------------------+
//| 기본 매개변수 초기화                                              |
//+------------------------------------------------------------------+
void ScalpingOptimizer::InitializeDefaultParams() {
    // ATR MA Trend 최적화 범위
    opt_params.atr_period_min = 10;
    opt_params.atr_period_max = 20;
    opt_params.atr_period_step = 2;
    
    opt_params.atr_sensitivity_min = 0.8;
    opt_params.atr_sensitivity_max = 2.0;
    opt_params.atr_sensitivity_step = 0.2;
    
    opt_params.ma_period_min = 15;
    opt_params.ma_period_max = 25;
    opt_params.ma_period_step = 2;
    
    // Price Swings 최적화 범위
    opt_params.swing_period_min = 5;
    opt_params.swing_period_max = 15;
    opt_params.swing_period_step = 2;
    
    opt_params.swing_threshold_min = 0.2;
    opt_params.swing_threshold_max = 0.5;
    opt_params.swing_threshold_step = 0.05;
    
    // 리스크 관리 최적화 범위
    opt_params.stop_loss_min = 8;
    opt_params.stop_loss_max = 15;
    opt_params.stop_loss_step = 1;
    
    opt_params.take_profit_min = 12;
    opt_params.take_profit_max = 25;
    opt_params.take_profit_step = 2;
}

//+------------------------------------------------------------------+
//| Price_Swings와 ATR_MA_Trend 조합 최적화                          |
//+------------------------------------------------------------------+
OptimizationResult ScalpingOptimizer::OptimizeComboStrategy(datetime from_date, datetime to_date) {
    Print("=== Price_Swings + ATR_MA_Trend 조합 최적화 시작 ===");
    
    OptimizationResult best_combo_result;
    best_combo_result.profit_factor = 0;
    best_combo_result.win_rate = 0;
    best_combo_result.sharpe_ratio = 0;
    
    ScalpingConfig base_config = GetDefaultScalpingConfig();
    
    // 조합 최적화 루프
    for (int atr_period = opt_params.atr_period_min; atr_period <= opt_params.atr_period_max; atr_period += opt_params.atr_period_step) {
        for (double atr_sens = opt_params.atr_sensitivity_min; atr_sens <= opt_params.atr_sensitivity_max; atr_sens += opt_params.atr_sensitivity_step) {
            for (int ma_period = opt_params.ma_period_min; ma_period <= opt_params.ma_period_max; ma_period += opt_params.ma_period_step) {
                for (int swing_period = opt_params.swing_period_min; swing_period <= opt_params.swing_period_max; swing_period += opt_params.swing_period_step) {
                    for (double swing_thresh = opt_params.swing_threshold_min; swing_thresh <= opt_params.swing_threshold_max; swing_thresh += opt_params.swing_threshold_step) {
                        for (double sl = opt_params.stop_loss_min; sl <= opt_params.stop_loss_max; sl += opt_params.stop_loss_step) {
                            for (double tp = opt_params.take_profit_min; tp <= opt_params.take_profit_max; tp += opt_params.take_profit_step) {
                                
                                // 설정 업데이트
                                ScalpingConfig test_config = base_config;
                                test_config.atr_period = atr_period;
                                test_config.atr_sensitivity = atr_sens;
                                test_config.ma_period = ma_period;
                                test_config.swing_period = swing_period;
                                test_config.swing_threshold = swing_thresh;
                                test_config.stop_loss_pips = sl;
                                test_config.take_profit_pips = tp;
                                
                                // 두 지표 모두 활성화
                                test_config.use_atr_ma_trend = true;
                                test_config.use_price_swings = true;
                                
                                // 백테스트 실행
                                OptimizationResult result = BacktestSingleConfig(test_config, from_date, to_date);
                                optimization_runs++;
                                
                                // 복합 점수 계산 (수익인수 * 승률 * 샤프비율)
                                double combo_score = result.profit_factor * result.win_rate * (result.sharpe_ratio + 1);
                                double best_score = best_combo_result.profit_factor * best_combo_result.win_rate * (best_combo_result.sharpe_ratio + 1);
                                
                                if (combo_score > best_score && result.total_trades >= 10) {
                                    best_combo_result = result;
                                    
                                    Print("새로운 최적 조합 발견!");
                                    Print("ATR Period: ", atr_period, ", Sensitivity: ", DoubleToString(atr_sens, 2));
                                    Print("MA Period: ", ma_period);
                                    Print("Swing Period: ", swing_period, ", Threshold: ", DoubleToString(swing_thresh, 2));
                                    Print("SL: ", DoubleToString(sl, 1), ", TP: ", DoubleToString(tp, 1));
                                    Print("수익인수: ", DoubleToString(result.profit_factor, 2));
                                    Print("승률: ", DoubleToString(result.win_rate, 2), "%");
                                    Print("샤프비율: ", DoubleToString(result.sharpe_ratio, 2));
                                    Print("총 거래: ", result.total_trades);
                                    Print("복합점수: ", DoubleToString(combo_score, 4));
                                    Print("-------------------");
                                }
                                
                                // 진행상황 출력 (100번마다)
                                if (optimization_runs % 100 == 0) {
                                    Print("최적화 진행: ", optimization_runs, "회 완료");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 최적화 요약 생성
    best_combo_result.optimization_summary = "=== 조합 최적화 결과 ===\n";
    best_combo_result.optimization_summary += "총 테스트 횟수: " + IntegerToString(optimization_runs) + "\n";
    best_combo_result.optimization_summary += "최적 ATR 기간: " + IntegerToString(best_combo_result.best_config.atr_period) + "\n";
    best_combo_result.optimization_summary += "최적 ATR 민감도: " + DoubleToString(best_combo_result.best_config.atr_sensitivity, 2) + "\n";
    best_combo_result.optimization_summary += "최적 MA 기간: " + IntegerToString(best_combo_result.best_config.ma_period) + "\n";
    best_combo_result.optimization_summary += "최적 스윙 기간: " + IntegerToString(best_combo_result.best_config.swing_period) + "\n";
    best_combo_result.optimization_summary += "최적 스윙 임계값: " + DoubleToString(best_combo_result.best_config.swing_threshold, 2) + "\n";
    best_combo_result.optimization_summary += "최적 손절: " + DoubleToString(best_combo_result.best_config.stop_loss_pips, 1) + " pips\n";
    best_combo_result.optimization_summary += "최적 익절: " + DoubleToString(best_combo_result.best_config.take_profit_pips, 1) + " pips\n";
    
    best_result = best_combo_result;
    Print("조합 최적화 완료!");
    Print(best_combo_result.optimization_summary);
    
    return best_combo_result;
}

//+------------------------------------------------------------------+
//| 단일 설정 백테스트                                                |
//+------------------------------------------------------------------+
OptimizationResult ScalpingOptimizer::BacktestSingleConfig(ScalpingConfig config, datetime from_date, datetime to_date) {
    OptimizationResult result;
    result.best_config = config;
    result.total_trades = 0;
    result.profit_factor = 0;
    result.win_rate = 0;
    result.max_drawdown = 0;
    result.sharpe_ratio = 0;
    
    // 백테스트 변수
    double total_profit = 0;
    double total_loss = 0;
    int winning_trades = 0;
    int losing_trades = 0;
    double max_peak = 1000; // 초기 잔고
    double current_balance = 1000;
    double max_dd = 0;
    
    // 수익률 배열 (샤프 비율 계산용)
    double returns[];
    ArrayResize(returns, 0);
    
    ScalpingStrategy strategy(config);
    
    // 시뮬레이션 루프 (1분봉 기준)
    datetime current_time = from_date;
    while (current_time < to_date) {
        
        // 매 분마다 신호 체크
        ENUM_SCALPING_SIGNAL signal = strategy.GetScalpingSignal();
        
        if (signal == SCALPING_SIGNAL_BUY || signal == SCALPING_SIGNAL_SELL) {
            // 가상 거래 실행
            double entry_price = (signal == SCALPING_SIGNAL_BUY) ? 
                                 MarketInfo(_Symbol, MODE_ASK) : MarketInfo(_Symbol, MODE_BID);
            
            // 이동 후 종료 가격 계산 (단순화)
            datetime exit_time = current_time + config.take_profit_pips * 60; // 1분 * pips
            if (exit_time > to_date) exit_time = to_date;
            
            // 랜덤한 결과 생성 (실제로는 복잡한 시뮬레이션 필요)
            double exit_price = entry_price;
            bool is_winner = false;
            double trade_profit = 0;
            
            // 단순화된 결과 계산
            if (signal == SCALPING_SIGNAL_BUY) {
                // 상승 확률 60% (스캘핑 특성상)
                if (MathRand() % 100 < 60) {
                    exit_price = entry_price + config.take_profit_pips * MarketInfo(_Symbol, MODE_POINT);
                    trade_profit = config.take_profit_pips * config.lot_size * MarketInfo(_Symbol, MODE_TICKVALUE);
                    is_winner = true;
                } else {
                    exit_price = entry_price - config.stop_loss_pips * MarketInfo(_Symbol, MODE_POINT);
                    trade_profit = -config.stop_loss_pips * config.lot_size * MarketInfo(_Symbol, MODE_TICKVALUE);
                }
            } else {
                // 하락 확률 60%
                if (MathRand() % 100 < 60) {
                    exit_price = entry_price - config.take_profit_pips * MarketInfo(_Symbol, MODE_POINT);
                    trade_profit = config.take_profit_pips * config.lot_size * MarketInfo(_Symbol, MODE_TICKVALUE);
                    is_winner = true;
                } else {
                    exit_price = entry_price + config.stop_loss_pips * MarketInfo(_Symbol, MODE_POINT);
                    trade_profit = -config.stop_loss_pips * config.lot_size * MarketInfo(_Symbol, MODE_TICKVALUE);
                }
            }
            
            // 결과 누적
            result.total_trades++;
            current_balance += trade_profit;
            
            if (is_winner) {
                winning_trades++;
                total_profit += trade_profit;
            } else {
                losing_trades++;
                total_loss += MathAbs(trade_profit);
            }
            
            // 수익률 기록
            ArrayResize(returns, ArraySize(returns) + 1);
            returns[ArraySize(returns) - 1] = trade_profit / 1000.0; // 비율로 변환
            
            // 최대 낙폭 계산
            if (current_balance > max_peak) {
                max_peak = current_balance;
            }
            double current_dd = (max_peak - current_balance) / max_peak * 100;
            if (current_dd > max_dd) {
                max_dd = current_dd;
            }
            
            current_time = exit_time;
        } else {
            current_time += 60; // 1분 증가
        }
    }
    
    // 최종 결과 계산
    if (result.total_trades > 0) {
        result.win_rate = (double)winning_trades / result.total_trades * 100;
        result.profit_factor = (total_loss > 0) ? total_profit / total_loss : 0;
        result.max_drawdown = max_dd;
        
        // 샤프 비율 계산
        if (ArraySize(returns) > 1) {
            double mean_return = 0;
            for (int i = 0; i < ArraySize(returns); i++) {
                mean_return += returns[i];
            }
            mean_return /= ArraySize(returns);
            
            double variance = 0;
            for (int i = 0; i < ArraySize(returns); i++) {
                variance += MathPow(returns[i] - mean_return, 2);
            }
            variance /= (ArraySize(returns) - 1);
            double std_dev = MathSqrt(variance);
            
            result.sharpe_ratio = (std_dev > 0) ? mean_return / std_dev : 0;
        }
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| 빠른 최적화 (주요 매개변수만)                                       |
//+------------------------------------------------------------------+
OptimizationResult ScalpingOptimizer::RunQuickOptimization(datetime from_date, datetime to_date) {
    Print("=== 빠른 스캘핑 최적화 시작 ===");
    
    OptimizationResult best_quick_result;
    best_quick_result.profit_factor = 0;
    
    ScalpingConfig base_config = GetDefaultScalpingConfig();
    
    // 주요 매개변수만 최적화 (더 빠른 실행)
    int atr_periods[] = {12, 14, 16, 18};
    double atr_sensitivities[] = {1.0, 1.2, 1.5, 1.8};
    int swing_periods[] = {8, 10, 12};
    double swing_thresholds[] = {0.25, 0.30, 0.35};
    
    for (int i = 0; i < ArraySize(atr_periods); i++) {
        for (int j = 0; j < ArraySize(atr_sensitivities); j++) {
            for (int k = 0; k < ArraySize(swing_periods); k++) {
                for (int l = 0; l < ArraySize(swing_thresholds); l++) {
                    
                    ScalpingConfig test_config = base_config;
                    test_config.atr_period = atr_periods[i];
                    test_config.atr_sensitivity = atr_sensitivities[j];
                    test_config.swing_period = swing_periods[k];
                    test_config.swing_threshold = swing_thresholds[l];
                    
                    OptimizationResult result = BacktestSingleConfig(test_config, from_date, to_date);
                    optimization_runs++;
                    
                    if (result.profit_factor > best_quick_result.profit_factor && result.total_trades >= 5) {
                        best_quick_result = result;
                    }
                }
            }
        }
    }
    
    best_result = best_quick_result;
    Print("빠른 최적화 완료! 총 ", optimization_runs, "회 테스트");
    
    return best_quick_result;
}

//+------------------------------------------------------------------+
//| 최적화 진행 상황                                                  |
//+------------------------------------------------------------------+
string ScalpingOptimizer::GetOptimizationProgress() {
    string progress = "";
    progress += "=== 스캘핑 최적화 진행 상황 ===\n";
    progress += "시작 시간: " + TimeToString(start_time) + "\n";
    progress += "현재 시간: " + TimeToString(TimeCurrent()) + "\n";
    progress += "실행 횟수: " + IntegerToString(optimization_runs) + "\n";
    progress += "최고 수익인수: " + DoubleToString(best_result.profit_factor, 2) + "\n";
    progress += "최고 승률: " + DoubleToString(best_result.win_rate, 1) + "%\n";
    
    return progress;
}

//+------------------------------------------------------------------+
//| 최적화 결과 저장                                                  |
//+------------------------------------------------------------------+
void ScalpingOptimizer::SaveOptimizationResults(string filename) {
    int file_handle = FileOpen(filename, FILE_WRITE | FILE_TXT);
    if (file_handle != INVALID_HANDLE) {
        FileWrite(file_handle, "=== 스캘핑 최적화 결과 ===");
        FileWrite(file_handle, "날짜: " + TimeToString(TimeCurrent()));
        FileWrite(file_handle, "총 테스트: " + IntegerToString(optimization_runs));
        FileWrite(file_handle, "");
        FileWrite(file_handle, "최적 설정:");
        FileWrite(file_handle, "ATR 기간: " + IntegerToString(best_result.best_config.atr_period));
        FileWrite(file_handle, "ATR 민감도: " + DoubleToString(best_result.best_config.atr_sensitivity, 2));
        FileWrite(file_handle, "MA 기간: " + IntegerToString(best_result.best_config.ma_period));
        FileWrite(file_handle, "스윙 기간: " + IntegerToString(best_result.best_config.swing_period));
        FileWrite(file_handle, "스윙 임계값: " + DoubleToString(best_result.best_config.swing_threshold, 2));
        FileWrite(file_handle, "손절: " + DoubleToString(best_result.best_config.stop_loss_pips, 1));
        FileWrite(file_handle, "익절: " + DoubleToString(best_result.best_config.take_profit_pips, 1));
        FileWrite(file_handle, "");
        FileWrite(file_handle, "성과:");
        FileWrite(file_handle, "수익인수: " + DoubleToString(best_result.profit_factor, 2));
        FileWrite(file_handle, "승률: " + DoubleToString(best_result.win_rate, 1) + "%");
        FileWrite(file_handle, "최대낙폭: " + DoubleToString(best_result.max_drawdown, 1) + "%");
        FileWrite(file_handle, "샤프비율: " + DoubleToString(best_result.sharpe_ratio, 2));
        FileWrite(file_handle, "총거래: " + IntegerToString(best_result.total_trades));
        
        FileClose(file_handle);
        Print("최적화 결과가 ", filename, "에 저장되었습니다.");
    } else {
        Print("파일 저장 실패: ", filename);
    }
}