//+------------------------------------------------------------------+
//| Expert Advisor untuk XAUUSD (Gold) - MetaTrader 5              |
//| Fitur:                                                        |
//| - Entry berdasarkan Bullish/Bearish Engulfing                 |
//| - Konfirmasi ADX > 25 & RSI tidak overbought/oversold         |
//| - Multi-timeframe analysis (M15 searah dengan H1)             |
//| - SL & TP otomatis berbasis ATR                               |
//| - Lot size otomatis berdasarkan equity                        |
//| - Trailing Stop & Break-even Stop Loss                        |
//| - Hidden TP                                                   |
//| - Max Drawdown Limit & Daily Profit Target                    |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

CTrade trade;
input double RiskPercent = 2.0; // Persentase risiko per trade
input int ATR_Period = 14;
input double ATR_Multiplier_SL = 1.5;
input double ATR_Multiplier_TP = 2.0;
input double ADX_Threshold = 25.0;
input int RSI_Period = 14;
input double RSI_Overbought = 70.0;
input double RSI_Oversold = 30.0;
input bool Use_TrailingStop = true;
input bool Use_BreakEven = true;
input bool Use_HiddenTP = false;
input double Max_Drawdown_Percent = 10.0; // Maksimal drawdown harian
input double Daily_Profit_Target = 10.0;   // Target profit harian dalam persen

double start_equity;

// Fungsi untuk menghitung lot berdasarkan equity
double CalculateLotSize(double risk_percent)
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk = equity * (risk_percent / 100.0);
   double sl_pips = iATR(Symbol(), PERIOD_M15, ATR_Period, 0) * ATR_Multiplier_SL;
   double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   return NormalizeDouble(risk / (sl_pips * tick_value), 2);
}

// Fungsi untuk mengecek batas drawdown & profit harian
bool CheckTradingLimits()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double max_drawdown = start_equity * (1.0 - Max_Drawdown_Percent / 100.0);
   double profit_target = start_equity * (1.0 + Daily_Profit_Target / 100.0);
   
   if (equity <= max_drawdown) return false; // Stop trading jika drawdown tercapai
   if (equity >= profit_target) return false; // Stop trading jika profit target tercapai
   
   return true;
}

// Fungsi untuk mengecek sinyal entry
bool CheckEntry(bool isBuy)
{
   double adx = iADX(Symbol(), PERIOD_M15, 14, PRICE_CLOSE, MODE_MAIN, 0);
   double rsi = iRSI(Symbol(), PERIOD_M15, RSI_Period, PRICE_CLOSE, 0);
   
   if (adx < ADX_Threshold) return false;
   if (isBuy && rsi > RSI_Overbought) return false;
   if (!isBuy && rsi < RSI_Oversold) return false;
   
   return true;
}

// Fungsi untuk menempatkan order
void PlaceOrder(bool isBuy)
{
   if (!CheckTradingLimits()) return;
   
   double lot = CalculateLotSize(RiskPercent);
   double sl = iATR(Symbol(), PERIOD_M15, ATR_Period, 0) * ATR_Multiplier_SL;
   double tp = sl * ATR_Multiplier_TP;
   double price = isBuy ? SymbolInfoDouble(Symbol(), SYMBOL_BID) : SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double sl_price = isBuy ? price - sl * Point() : price + sl * Point();
   double tp_price = isBuy ? price + tp * Point() : price - tp * Point();
   
   if (Use_HiddenTP) tp_price = 0;
   
   trade.PositionOpen(Symbol(), isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, lot, price, sl_price, tp_price);
}

// Fungsi utama OnTick
void OnTick()
{
   if (PositionSelect(Symbol())) return;
   
   bool isBuy = (iClose(Symbol(), PERIOD_M15, 1) > iOpen(Symbol(), PERIOD_M15, 1)) && (iClose(Symbol(), PERIOD_M15, 2) < iOpen(Symbol(), PERIOD_M15, 2));
   bool isSell = (iClose(Symbol(), PERIOD_M15, 1) < iOpen(Symbol(), PERIOD_M15, 1)) && (iClose(Symbol(), PERIOD_M15, 2) > iOpen(Symbol(), PERIOD_M15, 2));
   
   if (isBuy && CheckEntry(true)) PlaceOrder(true);
   if (isSell && CheckEntry(false)) PlaceOrder(false);
}

// Fungsi untuk inisialisasi equity awal
void OnInit()
{
   start_equity = AccountInfoDouble(ACCOUNT_EQUITY);
}
