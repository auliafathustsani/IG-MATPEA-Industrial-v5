//+------------------------------------------------------------------+
//| IG-MATPEA Industrial v5                                          |
//| Trend + Pullback + Momentum Confirmation                         |
//| Educational / research backtesting project                       |
//| No Martingale / No Grid / Non-HFT / No normal real trading      |
//+------------------------------------------------------------------+
#property strict
#property version   "5.00"
#property description "Industrial-grade trend-pullback EA with momentum confirmation, ATR risk control and no-leverage exposure cap."

#include <Trade/Trade.mqh>
CTrade trade;

//======================== EXECUTION / BROKER ========================
input group "=== Execution / Broker ==="
input ENUM_TIMEFRAMES InpTF = PERIOD_H1;
input ulong  InpMagic = 2601005;
input bool   InpAllowLong = true;
input bool   InpAllowShort = true;
input int    InpStartHour = 0;
input int    InpEndHour = 23;
input int    InpMaxSpreadPoints = 80;
input int    InpSlippagePoints = 20;

//======================== TREND / SIGNAL ============================
input group "=== Trend / Pullback / Momentum ==="
input int    InpFastEMA = 50;
input int    InpSlowEMA = 200;
input int    InpADXPeriod = 14;
input double InpMinADX = 21.0;
input bool   InpUseADXStrengthening = true;
input bool   InpUseDIFilter = true;
input int    InpATRPeriod = 14;
input double InpPullbackATR = 0.35;

input bool   InpUseRSIFilter = true;
input int    InpRSIPeriod = 14;
input double InpBuyRSIMin = 50.0;
input double InpBuyRSIMax = 68.0;
input double InpSellRSIMin = 32.0;
input double InpSellRSIMax = 50.0;

input bool   InpUseCandleQuality = true;
input double InpMinBodyRatio = 0.45;

//======================== RISK / EXIT ================================
input group "=== Risk / Exit ==="
input double InpRiskPercent = 0.75;
input bool   InpNoLeverageMode = true;
input double InpMaxExposurePct = 100.0;
input double InpSL_ATR = 2.0;
input double InpTP_ATR = 3.0;

input bool   InpUseBreakEven = true;
input double InpBE_ATR = 1.0;
input bool   InpUseTrailing = true;
input double InpTrail_ATR = 1.5;

input bool   InpUseTrendFailureExit = true;
input bool   InpUseTimeExit = true;
input int    InpMaxBarsInTrade = 72;

input double InpMaxDailyLossPct = 3.0;
input double InpMaxDrawdownPct = 25.0;
input bool   InpAllowRealTrading = false;

//======================== INDICATOR HANDLES ==========================
int hFast = INVALID_HANDLE;
int hSlow = INVALID_HANDLE;
int hADX  = INVALID_HANDLE;
int hATR  = INVALID_HANDLE;
int hRSI  = INVALID_HANDLE;

datetime lastBar = 0;
double dayStartEquity = 0.0;
int dayKey = -1;
double peakEquity = 0.0;
bool drawdownLock = false;

//======================== INITIALIZATION =============================
int OnInit()
{
   if(!MQLInfoInteger(MQL_TESTER) &&
      AccountInfoInteger(ACCOUNT_TRADE_MODE) == ACCOUNT_TRADE_MODE_REAL &&
      !InpAllowRealTrading)
   {
      Print("[SAFETY] Real-account execution blocked. Use Strategy Tester/demo.");
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePoints);

   hFast = iMA(_Symbol, InpTF, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA(_Symbol, InpTF, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hADX  = iADX(_Symbol, InpTF, InpADXPeriod);
   hATR  = iATR(_Symbol, InpTF, InpATRPeriod);
   hRSI  = iRSI(_Symbol, InpTF, InpRSIPeriod, PRICE_CLOSE);

   if(hFast == INVALID_HANDLE || hSlow == INVALID_HANDLE ||
      hADX == INVALID_HANDLE || hATR == INVALID_HANDLE ||
      hRSI == INVALID_HANDLE)
      return INIT_FAILED;

   ResetDailyEquity();
   peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   Print("IG-MATPEA INDUSTRIAL v5 | trend + pullback + momentum | one position | no martingale | no grid | non-HFT | no-leverage cap");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(hFast != INVALID_HANDLE) IndicatorRelease(hFast);
   if(hSlow != INVALID_HANDLE) IndicatorRelease(hSlow);
   if(hADX  != INVALID_HANDLE) IndicatorRelease(hADX);
   if(hATR  != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hRSI  != INVALID_HANDLE) IndicatorRelease(hRSI);
}

//======================== MAIN LOOP ==================================
void OnTick()
{
   UpdateDailyEquity();
   UpdateDrawdownCircuitBreaker();
   ManagePosition();

   if(!IsNewBar()) return;
   if(drawdownLock) return;
   if(!TradingAllowed()) return;
   if(HasOurPosition()) return;

   EvaluateEntry();
}

//======================== ACCOUNT / SAFETY ===========================
bool IsNewBar()
{
   datetime t[1];
   if(CopyTime(_Symbol, InpTF, 0, 1, t) != 1) return false;
   if(t[0] == lastBar) return false;
   lastBar = t[0];
   return true;
}

void ResetDailyEquity()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dayKey = dt.year * 1000 + dt.day_of_year;
   dayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
}

void UpdateDailyEquity()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int k = dt.year * 1000 + dt.day_of_year;
   if(k != dayKey) ResetDailyEquity();
}

void UpdateDrawdownCircuitBreaker()
{
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq <= 0.0) return;

   if(peakEquity <= 0.0 || eq > peakEquity)
      peakEquity = eq;

   if(InpMaxDrawdownPct > 0.0 && peakEquity > 0.0)
   {
      double dd = 100.0 * (peakEquity - eq) / peakEquity;
      if(dd >= InpMaxDrawdownPct)
         drawdownLock = true;
   }
}

bool TradingAllowed()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.hour < InpStartHour || dt.hour > InpEndHour)
      return false;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return false;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(point <= 0.0) return false;

   double spreadPts = (tick.ask - tick.bid) / point;
   if(spreadPts > InpMaxSpreadPoints)
      return false;

   if(dayStartEquity > 0.0 && InpMaxDailyLossPct > 0.0)
   {
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      double dd = 100.0 * (dayStartEquity - eq) / dayStartEquity;
      if(dd >= InpMaxDailyLossPct)
         return false;
   }

   return true;
}

bool HasOurPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagic)
         return true;
   }
   return false;
}

//======================== INDICATOR ACCESS ===========================
bool GetBufferValue(int handle, int buffer, int shift, double &value)
{
   double arr[1];
   if(CopyBuffer(handle, buffer, shift, 1, arr) != 1)
      return false;

   value = arr[0];
   return true;
}

//======================== ENTRY ENGINE ===============================
void EvaluateEntry()
{
   double fast1, fast2, slow1;
   double adx1, adx2, diPlus1, diMinus1;
   double atr1, rsi1;

   if(!GetBufferValue(hFast, 0, 1, fast1)) return;
   if(!GetBufferValue(hFast, 0, 2, fast2)) return;
   if(!GetBufferValue(hSlow, 0, 1, slow1)) return;

   if(!GetBufferValue(hADX, 0, 1, adx1)) return;
   if(!GetBufferValue(hADX, 0, 2, adx2)) return;
   if(!GetBufferValue(hADX, 1, 1, diPlus1)) return;
   if(!GetBufferValue(hADX, 2, 1, diMinus1)) return;

   if(!GetBufferValue(hATR, 0, 1, atr1)) return;
   if(!GetBufferValue(hRSI, 0, 1, rsi1)) return;

   if(atr1 <= 0.0 || adx1 < InpMinADX)
      return;

   if(InpUseADXStrengthening && adx1 < adx2)
      return;

   MqlRates r[3];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, InpTF, 0, 3, r) < 3)
      return;

   double body = MathAbs(r[1].close - r[1].open);
   double range = r[1].high - r[1].low;
   double bodyRatio = (range > 0.0 ? body / range : 0.0);

   if(InpUseCandleQuality && bodyRatio < InpMinBodyRatio)
      return;

   bool bullTrend = (fast1 > slow1 && fast1 > fast2);
   bool bearTrend = (fast1 < slow1 && fast1 < fast2);

   bool bullPullback =
      (r[1].low <= fast1 + InpPullbackATR * atr1 &&
       r[1].close > fast1 &&
       r[1].close > r[1].open);

   bool bearPullback =
      (r[1].high >= fast1 - InpPullbackATR * atr1 &&
       r[1].close < fast1 &&
       r[1].close < r[1].open);

   bool bullDI = (!InpUseDIFilter || diPlus1 > diMinus1);
   bool bearDI = (!InpUseDIFilter || diMinus1 > diPlus1);

   bool bullRSI = (!InpUseRSIFilter || (rsi1 >= InpBuyRSIMin && rsi1 <= InpBuyRSIMax));
   bool bearRSI = (!InpUseRSIFilter || (rsi1 >= InpSellRSIMin && rsi1 <= InpSellRSIMax));

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;

   if(InpAllowLong && bullTrend && bullPullback && bullDI && bullRSI)
   {
      double sl = NormalizePrice(tick.ask - InpSL_ATR * atr1);
      double tp = NormalizePrice(tick.ask + InpTP_ATR * atr1);
      double lot = CalculateRiskVolume(tick.ask, sl);

      if(lot > 0.0)
         trade.Buy(lot, _Symbol, 0.0, sl, tp, "IG-MATPEA v5 BUY");
   }
   else if(InpAllowShort && bearTrend && bearPullback && bearDI && bearRSI)
   {
      double sl = NormalizePrice(tick.bid + InpSL_ATR * atr1);
      double tp = NormalizePrice(tick.bid - InpTP_ATR * atr1);
      double lot = CalculateRiskVolume(tick.bid, sl);

      if(lot > 0.0)
         trade.Sell(lot, _Symbol, 0.0, sl, tp, "IG-MATPEA v5 SELL");
   }
}

//======================== POSITION SIZING ============================
double CalculateRiskVolume(double entry, double stop)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney = equity * InpRiskPercent / 100.0;

   if(equity <= 0.0 || riskMoney <= 0.0)
      return 0.0;

   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);

   if(tickValue <= 0.0)
      tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   double distance = MathAbs(entry - stop);

   if(tickSize <= 0.0 || tickValue <= 0.0 || distance <= 0.0)
      return 0.0;

   double lossPerLot = (distance / tickSize) * tickValue;
   if(lossPerLot <= 0.0)
      return 0.0;

   double riskVol = riskMoney / lossPerLot;
   double finalVol = riskVol;

   // No-leverage exposure cap: economic notional is capped by equity.
   if(InpNoLeverageMode)
   {
      double exposureBudget = equity * MathMax(0.0, InpMaxExposurePct) / 100.0;
      double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      double notionalPerLot = contractSize * entry;

      if(exposureBudget <= 0.0 || notionalPerLot <= 0.0)
         return 0.0;

      double exposureVol = exposureBudget / notionalPerLot;
      finalVol = MathMin(riskVol, exposureVol);
   }

   return NormalizeVolumeDown(finalVol);
}

double NormalizeVolumeDown(double vol)
{
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(step <= 0.0 || vmax <= 0.0 || vol <= 0.0)
      return 0.0;

   // Never round UP above the no-leverage exposure cap.
   if(vol + 1e-12 < vmin)
      return 0.0;

   vol = MathMin(vmax, vol);
   vol = MathFloor((vol + 1e-12) / step) * step;

   if(vol < vmin)
      return 0.0;

   int digits = 0;
   double s = step;
   while(s < 1.0 && digits < 8)
   {
      s *= 10.0;
      digits++;
   }

   return NormalizeDouble(vol, digits);
}

double NormalizePrice(double price)
{
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   return NormalizeDouble(price, digits);
}

//======================== EXIT ENGINE ================================
void ManagePosition()
{
   double atr0;
   if(!GetBufferValue(hATR, 0, 0, atr0) || atr0 <= 0.0)
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return;

   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;

      ENUM_POSITION_TYPE type =
         (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      double open = PositionGetDouble(POSITION_PRICE_OPEN);
      double sl   = PositionGetDouble(POSITION_SL);
      double tp   = PositionGetDouble(POSITION_TP);
      double newSL = sl;

      datetime openTime =
         (datetime)PositionGetInteger(POSITION_TIME);

      // Time-based exit: close stale trades that have not reached profit.
      if(InpUseTimeExit && InpMaxBarsInTrade > 0)
      {
         int barsHeld = iBarShift(_Symbol, InpTF, openTime, false);
         double currentProfit = PositionGetDouble(POSITION_PROFIT);

         if(barsHeld >= InpMaxBarsInTrade && currentProfit <= 0.0)
         {
            trade.PositionClose(ticket);
            continue;
         }
      }

      if(type == POSITION_TYPE_BUY)
      {
         double profitDistance = tick.bid - open;

         if(InpUseTrendFailureExit)
         {
            double fast0, slow0;
            if(GetBufferValue(hFast, 0, 0, fast0) &&
               GetBufferValue(hSlow, 0, 0, slow0))
            {
               if(tick.bid < fast0 && fast0 < slow0)
               {
                  trade.PositionClose(ticket);
                  continue;
               }
            }
         }

         if(InpUseBreakEven &&
            profitDistance >= InpBE_ATR * atr0 &&
            (sl < open || sl == 0.0))
         {
            newSL = open;
         }

         if(InpUseTrailing &&
            profitDistance >= InpTrail_ATR * atr0)
         {
            double trail = tick.bid - InpTrail_ATR * atr0;
            if(trail > newSL)
               newSL = trail;
         }

         newSL = NormalizePrice(newSL);

         if(newSL > 0.0 && (sl == 0.0 || newSL > sl))
            trade.PositionModify(ticket, newSL, tp);
      }
      else if(type == POSITION_TYPE_SELL)
      {
         double profitDistance = open - tick.ask;

         if(InpUseTrendFailureExit)
         {
            double fast0, slow0;
            if(GetBufferValue(hFast, 0, 0, fast0) &&
               GetBufferValue(hSlow, 0, 0, slow0))
            {
               if(tick.ask > fast0 && fast0 > slow0)
               {
                  trade.PositionClose(ticket);
                  continue;
               }
            }
         }

         if(InpUseBreakEven &&
            profitDistance >= InpBE_ATR * atr0 &&
            (sl > open || sl == 0.0))
         {
            newSL = open;
         }

         if(InpUseTrailing &&
            profitDistance >= InpTrail_ATR * atr0)
         {
            double trail = tick.ask + InpTrail_ATR * atr0;
            if(newSL == 0.0 || trail < newSL)
               newSL = trail;
         }

         newSL = NormalizePrice(newSL);

         if(newSL > 0.0 && (sl == 0.0 || newSL < sl))
            trade.PositionModify(ticket, newSL, tp);
      }
   }
}

//======================== OPTIMIZATION SCORE =========================
double OnTester()
{
   double profit = TesterStatistics(STAT_PROFIT);
   double ddPct  = TesterStatistics(STAT_EQUITY_DDREL_PERCENT);
   double pf     = TesterStatistics(STAT_PROFIT_FACTOR);
   double trades = TesterStatistics(STAT_TRADES);
   double sharpe = TesterStatistics(STAT_SHARPE_RATIO);

   if(trades < 50 || profit <= 0.0 || ddPct <= 0.0 ||
      ddPct > 30.0 || pf < 1.0)
      return -1000000.0;

   // Prefer profitable systems with PF and Sharpe, while penalizing DD.
   return (profit * pf * MathMax(0.1, sharpe + 1.0)) / (1.0 + ddPct);
}
//+------------------------------------------------------------------+
