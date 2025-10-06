//+------------------------------------------------------------------+
//|                                EA Grid BTC Enhanced v5.1        |
//|  Advanced Grid EA with Multi-Timeframe + EMA Strategy           |
//+------------------------------------------------------------------+
#property copyright "qhusi + ChatGPT Enhanced"
#property link      ""
#property version   "5.10"
#property strict

//--- TIMEFRAME SELECTION
enum ENUM_EA_TIMEFRAME
{
   TF_M5,    // 5 Minutes - High Frequency
   TF_M15,   // 15 Minutes - Balanced (RECOMMENDED)
   TF_H1,    // 1 Hour - Stable
   TF_H4     // 4 Hours - Conservative
};

//--- MAIN INPUTS
input ENUM_EA_TIMEFRAME EA_Timeframe    = TF_M15;   // Select EA Timeframe Mode
input double  LotSize                   = 0.001;   
input bool    AutoLot                   = true;    
input double  AutoLotFactor_Input       = 0.00002; 
input double  MinLot                    = 0.0001;  
input int     MagicNumber               = 20250912;
input bool    UseATR                    = true;    
input int     ATR_Period_Input          = 20;      // Base ATR Period
input double  ATR_Multiplier_Step_Input = 2.0;     // Base Step Multiplier
input double  ATR_Multiplier_TP_Input   = 3.5;     // Base TP Multiplier
input int     GridStepPointsFixed_Input = 2000;    // Base Grid Step
input int     LevelsUp_Input            = 2;       // Base Levels Up
input int     LevelsDown_Input          = 2;       // Base Levels Down
input bool    TradeBuy                  = true;
input bool    TradeSell                 = true;
input bool    AutoRenewLevels           = true;
input int     MaxOrders_Input           = 8;       // Base Max Orders
input double  EquityStopPercent         = 15.0;    
input bool    UseVolatilityFilter       = true;    
input double  MaxVolatilityATR_Input    = 0.06;    // Base Volatility Filter
input bool    EnableLogging             = true;
input bool    UseTrailingStop           = true;    
input double  TrailingStopPoints_Input  = 600;     // Base Trailing Stop

//--- EMA STRATEGY INPUTS
input bool    EnableEMAStrategy         = true;    
input int     EMA_Fast_Period_Input     = 12;      // Base Fast EMA
input int     EMA_Slow_Period_Input     = 26;      // Base Slow EMA
input int     EMA_Signal_Period_Input   = 9;       // Base Signal EMA
input bool    EMA_OnlyTrendDirection    = true;    
input double  EMA_MinDistance_Input     = 50;      // Base Min Distance
input bool    EMA_RecoveryMode          = true;    

//--- RECOVERY STRATEGY INPUTS  
input bool    EnableRecoveryMode        = true;    
input double  RecoveryMultiplier_Input  = 1.5;     // Base Recovery Multiplier
input int     RecoveryMaxLevels_Input   = 3;       // Base Max Recovery Levels
input double  RecoveryStepMultiplier    = 1.2;     

//--- CUT LOSS SETTINGS
input bool    EnableCutLoss             = true;    
input double  MaxLossUSD_Input          = 0.25;    // Base Max Loss
input double  ATR_CutLossMultiplier_Input = 1.1;   // Base Cut Loss Multiplier
input bool    OnlyCutLossWhenProfit     = true;    

//--- TARGET SETTINGS
input double  DailyTargetUSD            = 5.0;     
input bool    ResetTargetDaily          = true;    
input bool    ContinuousTrading         = true;    

//--- MA FILTER (Legacy - kept for compatibility)
input bool    UseMAFilter               = false;   
input int     MA_Timeframe              = 60;      
input int     MA_Period                 = 50;
input int     MA_Method                 = 0;       
input int     MA_Price                  = 0;       

//--- WORKING VARIABLES (will be set based on timeframe)
double AutoLotFactor;
int    ATR_Period;
double ATR_Multiplier_Step;
double ATR_Multiplier_TP;
int    GridStepPointsFixed;
int    LevelsUp;
int    LevelsDown;
int    MaxOrders;
double MaxVolatilityATR;
double TrailingStopPoints;
int    EMA_Fast_Period;
int    EMA_Slow_Period;
int    EMA_Signal_Period;
double EMA_MinDistance;
double RecoveryMultiplier;
int    RecoveryMaxLevels;
double MaxLossUSD;
double ATR_CutLossMultiplier;

//--- GLOBALS
string SYMBOL;
int    DIGITS;
double POINTVAL;
double StartBalance;
double TickSize;
bool   TradingEnabled = true;
bool   AutoTradeON = true;
string lastCutLossInfo = "-";
int    lastError = 0;
double DailyStartBalance = 0;
datetime LastResetTime = 0;
int    ProcessingTimeframe = PERIOD_M15;

//--- EMA Strategy globals
double FastEMA = 0, SlowEMA = 0, SignalEMA = 0;
int    EMA_Trend = 0; // 1=bullish, -1=bearish, 0=neutral

//--- Recovery globals
double LastRecoveryPrice = 0;
int    RecoveryLevel = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize timeframe-specific settings FIRST
   InitializeTimeframeSettings();
   
   SYMBOL = Symbol();
   DIGITS = (int)MarketInfo(SYMBOL, MODE_DIGITS);
   POINTVAL = MarketInfo(SYMBOL, MODE_POINT);
   TickSize = MarketInfo(SYMBOL, MODE_TICKSIZE);
   StartBalance = AccountBalance();
   DailyStartBalance = AccountBalance();
   LastResetTime = TimeCurrent();
   
   bool isBTC = StringFind(SYMBOL, "BTC") >= 0 || StringFind(SYMBOL, "BITCOIN") >= 0;
   
   if(EnableLogging)
   {
      Print("=== EA Enhanced v5.1 Multi-Timeframe ===");
      Print("Symbol: " + SYMBOL + ", IsBTC: " + string(isBTC));
      Print("Selected Timeframe Mode: " + GetTimeframeName());
      Print("Balance: $" + DoubleToString(StartBalance, 2));
      Print(GetRecommendedPairs());
      Print("Grid Step: " + IntegerToString(GridStepPointsFixed));
      Print("Max Orders: " + IntegerToString(MaxOrders));
      Print("ATR Period: " + IntegerToString(ATR_Period));
      Print("EMA Settings: " + IntegerToString(EMA_Fast_Period) + "/" + IntegerToString(EMA_Slow_Period) + "/" + IntegerToString(EMA_Signal_Period));
      Print("=======================================");
   }
   
   DrawPanel();
   DeployGridIfNeeded();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Initialize settings based on selected timeframe                 |
//+------------------------------------------------------------------+
void InitializeTimeframeSettings()
{
   // Start with input values as defaults
   AutoLotFactor = AutoLotFactor_Input;
   ATR_Period = ATR_Period_Input;
   ATR_Multiplier_Step = ATR_Multiplier_Step_Input;
   ATR_Multiplier_TP = ATR_Multiplier_TP_Input;
   GridStepPointsFixed = GridStepPointsFixed_Input;
   LevelsUp = LevelsUp_Input;
   LevelsDown = LevelsDown_Input;
   MaxOrders = MaxOrders_Input;
   MaxVolatilityATR = MaxVolatilityATR_Input;
   TrailingStopPoints = TrailingStopPoints_Input;
   EMA_Fast_Period = EMA_Fast_Period_Input;
   EMA_Slow_Period = EMA_Slow_Period_Input;
   EMA_Signal_Period = EMA_Signal_Period_Input;
   EMA_MinDistance = EMA_MinDistance_Input;
   RecoveryMultiplier = RecoveryMultiplier_Input;
   RecoveryMaxLevels = RecoveryMaxLevels_Input;
   MaxLossUSD = MaxLossUSD_Input;
   ATR_CutLossMultiplier = ATR_CutLossMultiplier_Input;
   
   switch(EA_Timeframe)
   {
      case TF_M5:  // High Frequency - Aggressive
         {
            GridStepPointsFixed = 1500;
            ATR_Multiplier_Step = 1.8;
            ATR_Multiplier_TP = 3.0;
            MaxLossUSD = 0.15;
            ATR_CutLossMultiplier = 0.9;
            TrailingStopPoints = 400;
            LevelsUp = 3;
            LevelsDown = 3;
            MaxOrders = 10;
            EMA_Fast_Period = 8;
            EMA_Slow_Period = 21;
            EMA_Signal_Period = 7;
            EMA_MinDistance = 30;
            RecoveryMultiplier = 1.3;
            RecoveryMaxLevels = 2;
            MaxVolatilityATR = 0.08;
            ATR_Period = 14;
            ProcessingTimeframe = PERIOD_M5;
            AutoLotFactor = AutoLotFactor_Input * 0.8;
         }
         break;
         
      case TF_M15: // Balanced - RECOMMENDED (Keep input values)
         {
            ProcessingTimeframe = PERIOD_M15;
         }
         break;
         
      case TF_H1:  // Stable - Conservative
         {
            GridStepPointsFixed = 3000;
            ATR_Multiplier_Step = 2.5;
            ATR_Multiplier_TP = 4.5;
            MaxLossUSD = 0.4;
            ATR_CutLossMultiplier = 1.5;
            TrailingStopPoints = 1000;
            LevelsUp = 2;
            LevelsDown = 2;
            MaxOrders = 6;
            EMA_Fast_Period = 21;
            EMA_Slow_Period = 50;
            EMA_Signal_Period = 14;
            EMA_MinDistance = 100;
            RecoveryMultiplier = 1.8;
            RecoveryMaxLevels = 4;
            MaxVolatilityATR = 0.04;
            ATR_Period = 24;
            ProcessingTimeframe = PERIOD_H1;
            AutoLotFactor = AutoLotFactor_Input * 1.3;
         }
         break;
         
      case TF_H4:  // Very Conservative
         {
            GridStepPointsFixed = 5000;
            ATR_Multiplier_Step = 3.0;
            ATR_Multiplier_TP = 6.0;
            MaxLossUSD = 0.6;
            ATR_CutLossMultiplier = 2.0;
            TrailingStopPoints = 1500;
            LevelsUp = 1;
            LevelsDown = 1;
            MaxOrders = 4;
            EMA_Fast_Period = 34;
            EMA_Slow_Period = 89;
            EMA_Signal_Period = 21;
            EMA_MinDistance = 200;
            RecoveryMultiplier = 2.0;
            RecoveryMaxLevels = 5;
            MaxVolatilityATR = 0.03;
            ATR_Period = 30;
            ProcessingTimeframe = PERIOD_H4;
            AutoLotFactor = AutoLotFactor_Input * 1.6;
         }
         break;
   }
}

//+------------------------------------------------------------------+
//| Get timeframe name for logging                                   |
//+------------------------------------------------------------------+
string GetTimeframeName()
{
   switch(EA_Timeframe)
   {
      case TF_M5:  return "M5 - High Frequency";
      case TF_M15: return "M15 - Balanced (RECOMMENDED)";
      case TF_H1:  return "H1 - Stable";
      case TF_H4:  return "H4 - Conservative";
      default:     return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Get recommended pairs info                                       |
//+------------------------------------------------------------------+
string GetRecommendedPairs()
{
   switch(EA_Timeframe)
   {
      case TF_M5:  return "M5 Mode: BTCUSD (Spread <50) | Min: $500 | Monitoring: HIGH";
      case TF_M15: return "M15 Mode: BTCUSD, BTCEUR | Min: $300 | Monitoring: MEDIUM";
      case TF_H1:  return "H1 Mode: BTCUSD, BTCEUR | Min: $200 | Monitoring: LOW";
      case TF_H4:  return "H4 Mode: BTCUSD only | Min: $150 | Monitoring: MINIMAL";
      default:     return "Unknown timeframe configuration";
   }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectsDeleteAll();
   if(EnableLogging) Print("EA Enhanced v5.1 deinitialized");
}

//+------------------------------------------------------------------+
//| Calculate EMA values and trend                                   |
//+------------------------------------------------------------------+
void CalculateEMAStrategy()
{
   if(!EnableEMAStrategy) return;
   
   FastEMA = iMA(SYMBOL, ProcessingTimeframe, EMA_Fast_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
   SlowEMA = iMA(SYMBOL, ProcessingTimeframe, EMA_Slow_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
   SignalEMA = iMA(SYMBOL, ProcessingTimeframe, EMA_Signal_Period, 0, MODE_EMA, PRICE_CLOSE, 1);
   
   double distance = MathAbs(FastEMA - SlowEMA) / POINTVAL;
   
   if(distance < EMA_MinDistance)
   {
      EMA_Trend = 0; // Neutral
   }
   else if(FastEMA > SlowEMA)
   {
      EMA_Trend = 1; // Bullish
   }
   else
   {
      EMA_Trend = -1; // Bearish
   }
   
   if(EnableLogging && EMA_Trend != 0)
   {
      Print("EMA Trend: " + string(EMA_Trend) + ", Distance: " + DoubleToString(distance, 0) + " points");
   }
}

//+------------------------------------------------------------------+
//| Check if we should trade based on EMA                           |
//+------------------------------------------------------------------+
bool EMAAllowsTrade(int orderType)
{
   if(!EnableEMAStrategy) return true;
   if(!EMA_OnlyTrendDirection) return true;
   
   if((orderType == OP_BUY || orderType == OP_BUYSTOP || orderType == OP_BUYLIMIT) && EMA_Trend < 0)
      return false;
   if((orderType == OP_SELL || orderType == OP_SELLSTOP || orderType == OP_SELLLIMIT) && EMA_Trend > 0) 
      return false;
      
   return true;
}

//+------------------------------------------------------------------+
//| Check volatility before trading                                  |
//+------------------------------------------------------------------+
bool CheckVolatility()
{
   if(!UseVolatilityFilter) return true;
   
   double atr = iATR(SYMBOL, ProcessingTimeframe, ATR_Period, 1);
   double current_price = (Ask + Bid) / 2.0;
   double atr_percent = (atr / current_price) * 100;
   
   if(atr_percent > MaxVolatilityATR)
   {
      if(EnableLogging) Print("Volatility too high: " + DoubleToString(atr_percent, 2) + "%");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check daily target and reset if needed                          |
//+------------------------------------------------------------------+
void CheckDailyTarget()
{
   datetime currentTime = TimeCurrent();
   
   // Reset daily target at start of new day
   if(ResetTargetDaily && TimeDay(currentTime) != TimeDay(LastResetTime))
   {
      DailyStartBalance = AccountBalance();
      LastResetTime = currentTime;
      if(EnableLogging) Print("Daily target reset. New start balance: " + DoubleToString(DailyStartBalance, 2));
   }
   
   double dailyProfit = AccountBalance() - DailyStartBalance;
   
   if(dailyProfit >= DailyTargetUSD)
   {
      if(EnableLogging) Print("Daily target reached: $" + DoubleToString(dailyProfit, 2));
      
      if(!ContinuousTrading)
      {
         AutoTradeON = false;
         if(EnableLogging) Print("Auto trading disabled after reaching target");
      }
      else
      {
         if(EnableLogging) Print("Continuous trading enabled, continuing...");
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function with timeframe-aware processing            |
//+------------------------------------------------------------------+
void OnTick()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(SYMBOL, ProcessingTimeframe, 0);
   
   UpdatePanel();
   CheckButtonClick();
   CheckDailyTarget();
   
   // Process only on new bar of selected timeframe
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      
      CalculateEMAStrategy();
      TradingEnabled = CheckVolatility();
      
      if(AutoTradeON && TradingEnabled)
      {
         ManageGrid();
         
         if(EnableRecoveryMode)
            CheckRecoveryPositions();
      }
      
      if(EnableCutLoss)
         CheckAndCutLoss();
         
      ManageTrailingStops();
      CheckAdvancedRiskManagement();
   }
}

//+------------------------------------------------------------------+
//| Enhanced Panel with timeframe info                               |
//+------------------------------------------------------------------+
void DrawPanel()
{
   // Button AutoTrade
   ObjectCreate("BtnAuto", OBJ_BUTTON, 0, 0, 0);
   ObjectSet("BtnAuto", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet("BtnAuto", OBJPROP_XDISTANCE, 20);
   ObjectSet("BtnAuto", OBJPROP_YDISTANCE, 20);
   ObjectSet("BtnAuto", OBJPROP_XSIZE, 120);
   ObjectSet("BtnAuto", OBJPROP_YSIZE, 24);
   ObjectSetText("BtnAuto", "AutoTrade: ON", 10, "Arial", clrWhite);
   ObjectSet("BtnAuto", OBJPROP_BGCOLOR, clrGreen);
   
   // Enhanced labels with timeframe info
   string labels[] = {"LblBalance", "LblEquity", "LblFloat", "LblDD", "LblOrders", 
                     "LblCutLoss", "LblError", "LblEMA", "LblTarget", "LblRecovery", "LblTimeframe"};
   int ypos = 50;
   for(int i = 0; i < ArraySize(labels); i++)
   {
      ObjectCreate(labels[i], OBJ_LABEL, 0, 0, 0);
      ObjectSet(labels[i], OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(labels[i], OBJPROP_XDISTANCE, 20);
      ObjectSet(labels[i], OBJPROP_YDISTANCE, ypos);
      ObjectSetText(labels[i], "-", 9, "Arial", clrLime);
      ypos += 16;
   }
   
   ObjectCreate("LblInfo", OBJ_LABEL, 0, 0, 0);
   ObjectSet("LblInfo", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet("LblInfo", OBJPROP_XDISTANCE, 20);
   ObjectSet("LblInfo", OBJPROP_YDISTANCE, ypos);
   ObjectSetText("LblInfo", "BTC Grid EA Enhanced v5.1", 8, "Arial", clrGold);
}

void UpdatePanel()
{
   double balance = AccountBalance();
   double equity = AccountEquity();
   double floating = AccountProfit();
   double ddPct = (StartBalance > 0 ? (StartBalance - equity) / StartBalance * 100.0 : 0);
   int orders = CountMyOrders();
   double dailyProfit = balance - DailyStartBalance;
   
   ObjectSetText("LblBalance", "Balance: $" + DoubleToString(balance, 2));
   ObjectSetText("LblEquity", "Equity: $" + DoubleToString(equity, 2));
   ObjectSetText("LblFloat", "Floating: $" + DoubleToString(floating, 2));
   ObjectSetText("LblDD", "Drawdown: " + DoubleToString(ddPct, 1) + "%");
   ObjectSetText("LblOrders", "Orders: " + IntegerToString(orders));
   ObjectSetText("LblCutLoss", "CutLoss: " + lastCutLossInfo);
   ObjectSetText("LblError", "LastError: " + IntegerToString(lastError));
   ObjectSetText("LblEMA", "EMA Trend: " + IntegerToString(EMA_Trend));
   ObjectSetText("LblTarget", "Daily P/L: $" + DoubleToString(dailyProfit, 2));
   ObjectSetText("LblRecovery", "Recovery Lv: " + IntegerToString(RecoveryLevel));
   ObjectSetText("LblTimeframe", "Mode: " + GetTimeframeName());
   
   // Update button
   if(AutoTradeON)
   {
      ObjectSetText("BtnAuto", "AutoTrade: ON", 10, "Arial", clrWhite);
      ObjectSet("BtnAuto", OBJPROP_BGCOLOR, clrGreen);
   }
   else
   {
      ObjectSetText("BtnAuto", "AutoTrade: OFF", 10, "Arial", clrWhite);
      ObjectSet("BtnAuto", OBJPROP_BGCOLOR, clrRed);
   }
   
   ChartRedraw();
}

void CheckButtonClick()
{
   if(ObjectGet("BtnAuto", OBJPROP_STATE) == 1)
   {
      AutoTradeON = !AutoTradeON;
      ObjectSet("BtnAuto", OBJPROP_STATE, 0);
      if(EnableLogging) Print("AutoTrade switched: " + string(AutoTradeON));
   }
}

//+------------------------------------------------------------------+
//| Enhanced Grid Functions with timeframe awareness                |
//+------------------------------------------------------------------+
int ComputeGridStepPoints()
{
   if(!UseATR) return GridStepPointsFixed;
   
   double atr = iATR(SYMBOL, ProcessingTimeframe, ATR_Period, 1);
   if(atr <= 0) return GridStepPointsFixed;
   
   int points = (int)MathMax(500.0, MathRound((atr * ATR_Multiplier_Step) / POINTVAL));
   
   // Adjust based on EMA trend strength
   if(EnableEMAStrategy && EMA_Trend != 0)
   {
      double emaDistance = MathAbs(FastEMA - SlowEMA) / POINTVAL;
      if(emaDistance > EMA_MinDistance * 2)
      {
         points = (int)(points * 0.8); // Smaller steps in strong trend
      }
   }
   
   return points;
}

int ComputeTPPoints()
{
   if(!UseATR) return (int)(GridStepPointsFixed * 2.5);
   
   double atr = iATR(SYMBOL, ProcessingTimeframe, ATR_Period, 1);
   if(atr <= 0) return (int)(GridStepPointsFixed * 2.5);
   
   int points = (int)MathMax(800.0, MathRound((atr * ATR_Multiplier_TP) / POINTVAL));
   
   // Adjust TP based on recovery level
   if(RecoveryLevel > 0)
   {
      points = (int)(points * (1.0 + RecoveryLevel * 0.2)); // Larger TP for recovery
   }
   
   return points;
}

double ComputeLot(bool isRecovery = false)
{
   double lot = LotSize;
   
   if(AutoLot)
   {
      double bal = AccountBalance();
      lot = NormalizeDouble(bal * AutoLotFactor, 4);
      
      double minlot = MarketInfo(SYMBOL, MODE_MINLOT);
      double maxlot = MarketInfo(SYMBOL, MODE_MAXLOT);
      double step = MarketInfo(SYMBOL, MODE_LOTSTEP);
      
      if(minlot <= 0) minlot = MinLot;
      if(step <= 0) step = 0.0001;
      
      // Apply recovery multiplier if needed
      if(isRecovery && RecoveryLevel > 0)
      {
         lot = lot * MathPow(RecoveryMultiplier, RecoveryLevel);
      }
      
      lot = MathMax(minlot, MathMin(maxlot, lot));
      lot = NormalizeDouble(MathRound(lot / step) * step, 4);
      
      if(lot < minlot) lot = minlot;
   }
   
   return lot;
}

void DeployGrid()
{
   if(!TradingEnabled) return;
   
   double ask = Ask;
   double bid = Bid;
   double mid = (ask + bid) / 2.0;
   int stepPts = ComputeGridStepPoints();
   int tpPts = ComputeTPPoints();
   
   if(EnableLogging) 
   {
      Print("Deploying " + GetTimeframeName() + " Grid - Mid: " + DoubleToString(mid, DIGITS) + 
            ", Step: " + IntegerToString(stepPts) + ", TP: " + IntegerToString(tpPts));
   }
   
   // Enhanced grid placement based on EMA and timeframe
   for(int level = 1; level <= LevelsUp; level++)
   {
      if(TradeBuy && EMAAllowsTrade(OP_BUYSTOP))
      {
         double buyStopPrice = NormalizeDouble(mid + (stepPts * level) * POINTVAL, DIGITS);
         PlacePendingOrder(OP_BUYSTOP, buyStopPrice, tpPts);
      }
      
      if(TradeBuy && EMAAllowsTrade(OP_BUYLIMIT))
      {
         double buyLimitPrice = NormalizeDouble(mid - (stepPts * level) * POINTVAL, DIGITS);
         PlacePendingOrder(OP_BUYLIMIT, buyLimitPrice, tpPts);
      }
   }
   
   for(int level = 1; level <= LevelsDown; level++)
   {
      if(TradeSell && EMAAllowsTrade(OP_SELLLIMIT))
      {
         double sellLimitPrice = NormalizeDouble(mid + (stepPts * level) * POINTVAL, DIGITS);
         PlacePendingOrder(OP_SELLLIMIT, sellLimitPrice, tpPts);
      }
      
      if(TradeSell && EMAAllowsTrade(OP_SELLSTOP))
      {
         double sellStopPrice = NormalizeDouble(mid - (stepPts * level) * POINTVAL, DIGITS);
         PlacePendingOrder(OP_SELLSTOP, sellStopPrice, tpPts);
      }
   }
}

//+------------------------------------------------------------------+
//| Recovery Strategy for Minus Positions                           |
//+------------------------------------------------------------------+
void CheckRecoveryPositions()
{
   if(!EnableRecoveryMode) return;
   
   double totalFloating = 0;
   int losingPositions = 0;
   double avgLosingPrice = 0;
   
   // Calculate losing positions
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() != MagicNumber || OrderSymbol() != SYMBOL) continue;
         if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
         
         double profit = OrderProfit() + OrderSwap() + OrderCommission();
         totalFloating += profit;
         
         if(profit < 0)
         {
            losingPositions++;
            avgLosingPrice += OrderOpenPrice();
         }
      }
   }
   
   if(losingPositions > 0)
   {
      avgLosingPrice /= losingPositions;
      
      // Deploy recovery orders if floating loss is significant (adjusted per timeframe)
      double recoveryThreshold = MaxLossUSD * 0.5;
      if(totalFloating < -recoveryThreshold && RecoveryLevel < RecoveryMaxLevels)
      {
         DeployRecoveryOrders(avgLosingPrice);
      }
   }
   else
   {
      RecoveryLevel = 0; // Reset recovery level when no losing positions
   }
}

void DeployRecoveryOrders(double basePrice)
{
   if(RecoveryLevel >= RecoveryMaxLevels) return;
   
   RecoveryLevel++;
   double currentPrice = (Ask + Bid) / 2.0;
   int stepPts = (int)(ComputeGridStepPoints() * RecoveryStepMultiplier);
   int tpPts = ComputeTPPoints();
   
   // Deploy recovery orders based on EMA trend
   if(EMA_Trend > 0 || !EnableEMAStrategy) // Bullish or no EMA filter
   {
      double buyPrice = NormalizeDouble(currentPrice - (stepPts * RecoveryLevel) * POINTVAL, DIGITS);
      PlacePendingOrder(OP_BUYLIMIT, buyPrice, tpPts, true);
   }
   
   if(EMA_Trend < 0 || !EnableEMAStrategy) // Bearish or no EMA filter  
   {
      double sellPrice = NormalizeDouble(currentPrice + (stepPts * RecoveryLevel) * POINTVAL, DIGITS);
      PlacePendingOrder(OP_SELLLIMIT, sellPrice, tpPts, true);
   }
   
   if(EnableLogging) 
   {
      Print("Recovery Level " + IntegerToString(RecoveryLevel) + " deployed (" + GetTimeframeName() + ")");
   }
}

//+------------------------------------------------------------------+
//| Enhanced Order Placement                                         |
//+------------------------------------------------------------------+
bool PlacePendingOrder(int type, double price, int tpPoints, bool isRecovery = false)
{
   if(CountMyOrders() >= MaxOrders) return false;
   
   double lot = ComputeLot(isRecovery);
   color arrowColor = (type == OP_BUYSTOP || type == OP_BUYLIMIT) ? clrBlue : clrRed;
   if(isRecovery) arrowColor = clrYellow;
   
   double sl = 0;
   double tp = 0;
   
   if(tpPoints > 0)
   {
      if(type == OP_BUYSTOP || type == OP_BUYLIMIT)
         tp = NormalizeDouble(price + tpPoints * POINTVAL, DIGITS);
      else
         tp = NormalizeDouble(price - tpPoints * POINTVAL, DIGITS);
   }
   
   string comment = isRecovery ? "Recovery_Lv" + IntegerToString(RecoveryLevel) : GetTimeframeName() + "_Grid";
   int ticket = OrderSend(SYMBOL, type, lot, price, 30, sl, tp, comment, MagicNumber, 0, arrowColor);
   
   if(ticket > 0)
   {
      if(EnableLogging) Print("Order placed: " + comment + " #" + IntegerToString(ticket) + 
                             ", Type: " + IntegerToString(type) + ", Lot: " + DoubleToString(lot, 4));
      return true;
   }
   else
   {
      lastError = GetLastError();
      if(EnableLogging) Print("OrderSend failed: #" + IntegerToString(lastError));
      return false;
   }
}

//+------------------------------------------------------------------+
//| Enhanced Cut Loss with Profit Protection                        |
//+------------------------------------------------------------------+
void CheckAndCutLoss()
{
   double totalFloating = AccountProfit();
   
   // Only cut loss if overall profit or disabled profit protection
   if(OnlyCutLossWhenProfit && totalFloating <= 0) return;
   
   double atr = UseATR ? iATR(SYMBOL, ProcessingTimeframe, ATR_Period, 1) : 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() != MagicNumber || OrderSymbol() != SYMBOL) continue;
         if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
         
         double loss = OrderProfit() + OrderSwap() + OrderCommission();
         double openPrice = OrderOpenPrice();
         double currentPrice = (OrderType() == OP_BUY) ? Bid : Ask;
         double priceDiff = MathAbs(currentPrice - openPrice);
         
         // Enhanced cut loss logic
         bool shouldCutLoss = false;
         string reason = "";
         
         if(loss < -MaxLossUSD)
         {
            shouldCutLoss = true;
            reason = "USD_Loss";
         }
         else if(atr > 0 && priceDiff > atr * ATR_CutLossMultiplier)
         {
            shouldCutLoss = true;
            reason = "ATR_Loss";
         }
         
         if(shouldCutLoss)
         {
            lastCutLossInfo = reason + ":" + IntegerToString(OrderTicket());
            if(EnableLogging) Print(GetTimeframeName() + " Cut Loss: " + reason + 
                                   " Ticket #" + IntegerToString(OrderTicket()) + 
                                   ", Loss: $" + DoubleToString(loss, 2));
            CloseOrder(OrderTicket());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trailing Stop Management (Enhanced)                             |
//+------------------------------------------------------------------+
void ManageTrailingStops()
{
   if(!UseTrailingStop) return;
   
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() != MagicNumber || OrderSymbol() != SYMBOL) continue;
         if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
         
         double profit = OrderProfit() + OrderSwap() + OrderCommission();
         if(profit <= 0) continue; // Only trail profitable positions
         
         double newSL = 0;
         bool modify = false;
         
         if(OrderType() == OP_BUY)
         {
            newSL = NormalizeDouble(Bid - TrailingStopPoints * POINTVAL, DIGITS);
            if(OrderStopLoss() == 0 || newSL > OrderStopLoss())
            {
               modify = true;
            }
         }
         else if(OrderType() == OP_SELL)
         {
            newSL = NormalizeDouble(Ask + TrailingStopPoints * POINTVAL, DIGITS);
            if(OrderStopLoss() == 0 || newSL < OrderStopLoss())
            {
               modify = true;
            }
         }
         
         if(modify)
         {
            bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0);
            if(result && EnableLogging)
            {
               Print("Trailing stop updated for #" + IntegerToString(OrderTicket()) + 
                     " (" + GetTimeframeName() + ")");
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Legacy MA Filter (kept for compatibility)                       |
//+------------------------------------------------------------------+
int CurrentMAFilter()
{
   if(!UseMAFilter) return 0;
   
   double ma = iMA(SYMBOL, MA_Timeframe, MA_Period, 0, MA_Method, MA_Price, 1);
   if(ma == 0) 
   {
      if(EnableLogging) Print("MA value is zero");
      return 0;
   }
   
   double price = (Ask + Bid) / 2.0;
   if(price > ma) return 1;
   if(price < ma) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| Grid Management                                                  |
//+------------------------------------------------------------------+
void ManageGrid()
{
   int myOrders = CountMyOrders();
   if(myOrders == 0 && AutoRenewLevels)
   {
      if(EnableLogging) Print("No orders found, deploying new " + GetTimeframeName() + " grid");
      DeployGrid();
   }
}

void DeployGridIfNeeded()
{
   if(CountMyOrders() == 0)
   {
      if(EnableLogging) Print("Deploying initial " + GetTimeframeName() + " grid");
      DeployGrid();
   }
}

//+------------------------------------------------------------------+
//| Utility Functions                                                |
//+------------------------------------------------------------------+
bool CloseOrder(int ticket)
{
   if(OrderSelect(ticket, SELECT_BY_TICKET))
   {
      double closePrice = (OrderType() == OP_BUY) ? Bid : Ask;
      bool result = OrderClose(ticket, OrderLots(), closePrice, 30, clrRed);
      
      if(result && EnableLogging) 
      {
         Print("Order closed: #" + IntegerToString(ticket) + " (" + GetTimeframeName() + ")");
      }
      if(!result) 
      {
         lastError = GetLastError();
         if(EnableLogging) Print("OrderClose failed: #" + IntegerToString(lastError));
      }
      
      return result;
   }
   return false;
}

void CloseAllPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == SYMBOL)
         {
            if(OrderType() == OP_BUY || OrderType() == OP_SELL)
            {
               CloseOrder(OrderTicket());
            }
         }
      }
   }
   if(EnableLogging) Print("All positions closed (" + GetTimeframeName() + ")");
}

void CancelAllMyPendings()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == SYMBOL)
         {
            if(OrderType() > OP_SELL)
            {
               bool result = OrderDelete(OrderTicket());
               if(!result)
               {
                  lastError = GetLastError();
                  if(EnableLogging) Print("OrderDelete failed: #" + IntegerToString(lastError));
               }
               else
               {
                  if(EnableLogging) Print("Pending order deleted: #" + IntegerToString(OrderTicket()));
               }
            }
         }
      }
   }
}

int CountMyOrders()
{
   int count = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == SYMBOL)
         {
            count++;
         }
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Advanced Risk Management                                         |
//+------------------------------------------------------------------+
void CheckAdvancedRiskManagement()
{
   SafetyCheck();
   
   // Check if too many recovery levels are active
   if(RecoveryLevel >= RecoveryMaxLevels)
   {
      if(EnableLogging) Print("Max recovery levels reached (" + IntegerToString(RecoveryMaxLevels) + "), monitoring closely");
   }
   
   // Check floating P&L vs daily target
   double floating = AccountProfit();
   if(floating < -DailyTargetUSD)
   {
      if(EnableLogging) Print("Warning: Floating loss exceeds daily target");
   }
   
   // Monitor order distribution
   int buyOrders = 0, sellOrders = 0;
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderMagicNumber() != MagicNumber || OrderSymbol() != SYMBOL) continue;
         
         if(OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT)
            buyOrders++;
         else if(OrderType() == OP_SELL || OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT)
            sellOrders++;
      }
   }
   
   // Warn if order distribution is heavily skewed (may indicate trending market)
   int totalOrders = buyOrders + sellOrders;
   if(totalOrders > 0)
   {
      double buyPercent = (double)buyOrders / totalOrders * 100.0;
      if(buyPercent > 80.0 || buyPercent < 20.0)
      {
         if(EnableLogging) Print("Warning: Order distribution skewed - Buy: " + 
                                DoubleToString(buyPercent, 1) + "% (" + GetTimeframeName() + ")");
      }
   }
}

//+------------------------------------------------------------------+
//| Emergency Functions                                              |
//+------------------------------------------------------------------+
void EmergencyStop()
{
   AutoTradeON = false;
   CloseAllPositions();
   CancelAllMyPendings();
   
   if(EnableLogging)
   {
      Print("=== EMERGENCY STOP ACTIVATED ===");
      Print("All trading stopped and positions closed");
      Print("Timeframe: " + GetTimeframeName());
      Print("Reason: Manual emergency stop");
      DisplayPerformanceMetrics();
      Print("===============================");
   }
}

void SafetyCheck()
{
   double equity = AccountEquity();
   double drawdownPct = (StartBalance > 0 ? (StartBalance - equity) / StartBalance * 100.0 : 0);
   
   // Emergency stop if drawdown exceeds safety threshold
   if(drawdownPct >= EquityStopPercent)
   {
      if(EnableLogging) 
      {
         Print("=== SAFETY STOP TRIGGERED ===");
         Print("Drawdown: " + DoubleToString(drawdownPct, 2) + "% >= " + DoubleToString(EquityStopPercent, 2) + "%");
         Print("Timeframe: " + GetTimeframeName());
      }
      EmergencyStop();
   }
}

//+------------------------------------------------------------------+
//| Performance Monitoring Functions                                 |
//+------------------------------------------------------------------+
void DisplayPerformanceMetrics()
{
   if(!EnableLogging) return;
   
   double balance = AccountBalance();
   double equity = AccountEquity();
   double dailyProfit = balance - DailyStartBalance;
   double totalProfit = balance - StartBalance;
   int totalOrders = CountMyOrders();
   
   string metrics = "\n=== " + GetTimeframeName() + " PERFORMANCE ===";
   metrics += "\nStart Balance: $" + DoubleToString(StartBalance, 2);
   metrics += "\nCurrent Balance: $" + DoubleToString(balance, 2);
   metrics += "\nCurrent Equity: $" + DoubleToString(equity, 2);
   metrics += "\nDaily Profit: $" + DoubleToString(dailyProfit, 2);
   metrics += "\nTotal Profit: $" + DoubleToString(totalProfit, 2);
   metrics += "\nActive Orders: " + IntegerToString(totalOrders);
   metrics += "\nRecovery Level: " + IntegerToString(RecoveryLevel);
   metrics += "\nEMA Trend: " + IntegerToString(EMA_Trend);
   
   // Expected performance based on timeframe
   switch(EA_Timeframe)
   {
      case TF_M5:
         metrics += "\nExpected Trades/Day: 15-25";
         metrics += "\nRisk Level: HIGH";
         break;
      case TF_M15:
         metrics += "\nExpected Trades/Day: 8-15";
         metrics += "\nRisk Level: MEDIUM";
         break;
      case TF_H1:
         metrics += "\nExpected Trades/Day: 3-8";
         metrics += "\nRisk Level: LOW-MEDIUM";
         break;
      case TF_H4:
         metrics += "\nExpected Trades/Day: 1-3";
         metrics += "\nRisk Level: LOW";
         break;
   }
   
   metrics += "\n================================";
   Print(metrics);
}

//+------------------------------------------------------------------+


