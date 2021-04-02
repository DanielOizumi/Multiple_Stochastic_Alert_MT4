//+------------------------------------------------------------------+
//|                      Stochastic Alert for Multiple Timeframe.mq4 |
//|                                               Daniel Akio Oizumi |
//|                                        https://maisgeeks.com.br/ |
//+------------------------------------------------------------------+
#property copyright "Daniel Akio Oizumi"
#property link      "https://maisgeeks.com.br/"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
enum DAN_ALERT_ON_OFF
  {
   On,
   Off
  };
enum DAN_ALERT_OPTION
  {
   Stochastic_and_Signal,
   Stochastic,
   Signal
  };
enum DAN_PRICE_FIELD
  {
   Low_High,
   Close_Close
  };
input DAN_ALERT_ON_OFF AlertON = On; // Alert
input ENUM_TIMEFRAMES TimeFrame1 = PERIOD_M1;  // 1st Time Frame
input ENUM_TIMEFRAMES TimeFrame2 = PERIOD_M5;  // 2nd Time Frame
input int InpKPeriod=5; // K Line Period
input int InpDPeriod=3; // D Line Period
input int InpSlowing=3; // Slowing
input int InpOverbought = 80; // Overbought Level
input int InpOversold = 20; // Oversold Level
input DAN_ALERT_OPTION DisplaySto = Stochastic; // Display Lines
input DAN_ALERT_OPTION AlertType = Stochastic; // Alert on Signal, Stochastic or Both
input ENUM_MA_METHOD Dan_MA_Method = MODE_SMA; // Type of Smoothing
input ENUM_STO_PRICE Dan_Price_Field = STO_LOWHIGH; // Type of Price

//+------------------------------------------------------------------+
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_levelcolor Silver
#property indicator_levelwidth 0
#property indicator_levelstyle 2
#property indicator_buffers 4
#property indicator_color1 clrLightSeaGreen
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
#property indicator_color2 clrLightSeaGreen
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2
#property indicator_color3 clrRed
#property indicator_style3 STYLE_SOLID
#property indicator_width3 1
#property indicator_color4 clrRed
#property indicator_width4 STYLE_SOLID
#property indicator_width4 2
//---- buffers
double BUFFER_1[];
double BUFFER_2[];
double SignalBuffer1[];
double SignalBuffer2[];
double GREEN1[];
double GREEN2[];
double RED1[];
double RED2[];
ENUM_MA_METHOD MA_Method;
int Price_Field;
int per1;
int per2;
bool AlertTrigged;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   DrawLevelLines();

   ObjectCreate("on", OBJ_LABEL, 1, 0, 0);
   ObjectSet("on", OBJPROP_CORNER, 0);
   ObjectSet("on", OBJPROP_XDISTANCE, 10);
   ObjectSet("on", OBJPROP_YDISTANCE, 15);
   string ObjText;

   if(AlertType==Signal)
      ObjText = " | Type of Signal";
   else
      ObjText = " | Stochastic Type";;

   if(AlertON==On)
     {
      ObjText = "Alert ON" + ObjText;
      ObjectSetText("on",ObjText,8,"Arial",clrGreen);
     }
   else
     {
      ObjText = "Alert OFF" + ObjText;
      ObjectSetText("on",ObjText,8,"Arial",clrRed);
     }

//---- indicator lines
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0, BUFFER_1);
   SetIndexStyle(1,DRAW_LINE);
   SetIndexBuffer(1, BUFFER_2);
   SetIndexStyle(2,DRAW_LINE);
   SetIndexBuffer(2, SignalBuffer1);
   SetIndexStyle(3,DRAW_LINE);
   SetIndexBuffer(3, SignalBuffer2);

//---- name for DataWindow and indicator subwindow label
   per1 = TimeFrame1;
   per2 = TimeFrame2;


   string short_name=" Sto("+IntegerToString(InpKPeriod)+","+IntegerToString(InpDPeriod)+","+IntegerToString(InpSlowing)+")";
   IndicatorShortName(short_name);

   SetIndexLabel(0, string_пер(per1)+short_name);
   SetIndexLabel(1, string_пер(per2)+short_name);
   SetIndexLabel(2, string_пер(per1)+" Signal");
   SetIndexLabel(3, string_пер(per2)+" Signal");
   SetIndexLabel(4, string_пер(per1)+" %K");
   SetIndexLabel(5, string_пер(per2)+" %K");
   SetIndexLabel(6, string_пер(per1)+" %D");
   SetIndexLabel(7, string_пер(per2)+" %D");
   IndicatorShortName("Multiple Stochastic Alert ("+IntegerToString(InpKPeriod)+", "+IntegerToString(InpDPeriod)+", "+IntegerToString(InpSlowing)+" | "+string_пер(per1)+" & "+string_пер(per2)+")");

   AlertTrigged = false;

   return(0);
  }
//+------------------------------------------------------------------+
//| Stochastic oscillator                                            |
//+------------------------------------------------------------------+
int start()
  {
   int counted_bars = IndicatorCounted();
   int limit = Bars - counted_bars;

   for(int i=0; i<limit; i++)
     {
      if(DisplaySto==Stochastic_and_Signal || DisplaySto == Stochastic)
        {
         BUFFER_1[i] = iStochastic(NULL, per1, InpKPeriod, InpDPeriod, InpSlowing, MA_Method, Price_Field, MODE_MAIN, iBarShift(NULL, per1, Time[i], false));
         BUFFER_2[i] = iStochastic(NULL, per2, InpKPeriod, InpDPeriod, InpSlowing, MA_Method, Price_Field, MODE_MAIN, iBarShift(NULL, per2, Time[i], false));
        }
      if(DisplaySto==Stochastic_and_Signal || DisplaySto == Signal)
        {
         SignalBuffer1[i] = iStochastic(NULL, per1, InpKPeriod, InpDPeriod, InpSlowing, MA_Method, Price_Field, MODE_SIGNAL, iBarShift(NULL, per1, Time[i], false));
         SignalBuffer2[i] = iStochastic(NULL, per2, InpKPeriod, InpDPeriod, InpSlowing, MA_Method, Price_Field, MODE_SIGNAL, iBarShift(NULL, per2, Time[i], false));
        }

      if(AlertType==Stochastic_and_Signal)
        {
         if(BUFFER_1[i] > InpOverbought && BUFFER_2[i] > InpOverbought && SignalBuffer1[i] > InpOverbought && SignalBuffer2[i] > InpOverbought)
           {
            if(AlertON == On && i < 1 && AlertTrigged == false)
              {
               AlertTrigged = true;
               Alert(Symbol()+" Overbought: "+string_пер(per1)+" Sto: "+DoubleToStr(BUFFER_1[i],2)+", Signal: "+DoubleToStr(SignalBuffer1[i],2)+" | "+string_пер(per2)+" Sto: "+DoubleToStr(BUFFER_2[i],2)+", Signal: "+DoubleToStr(SignalBuffer2[i],2));
              }
           }
         if(BUFFER_1[i] < InpOversold && BUFFER_2[i] < InpOversold && SignalBuffer1[i] < InpOversold && SignalBuffer2[i] < InpOversold)
           {
            if(AlertON == On && i < 1 && AlertTrigged == false)
              {
               AlertTrigged = true;
               Alert(Symbol()+" Oversold: "+string_пер(per1)+" Sto: "+DoubleToStr(BUFFER_1[i],2)+", Signal: "+DoubleToStr(SignalBuffer1[i],2)+" | "+string_пер(per2)+" Sto: "+DoubleToStr(BUFFER_2[i],2)+", Signal: "+DoubleToStr(SignalBuffer2[i],2));
              }
           }
         if(BUFFER_1[i] < InpOverbought && BUFFER_1[i] > InpOversold)
           {
            AlertTrigged = false;
           }
         if(BUFFER_2[i] < InpOverbought && BUFFER_2[i] > InpOversold)
           {
            AlertTrigged = false;
           }
         if(SignalBuffer1[i] < InpOverbought && SignalBuffer1[i] > InpOversold)
           {
            AlertTrigged = false;
           }
         if(SignalBuffer2[i] < InpOverbought && SignalBuffer2[i] > InpOversold)
           {
            AlertTrigged = false;
           }
        }
      if(AlertType==Stochastic)
        {
         if(BUFFER_1[i] > InpOverbought && BUFFER_2[i] > InpOverbought)
           {
            if(AlertON == On && i < 1 && AlertTrigged == false)
              {
               AlertTrigged = true;
               Print(IntegerToString(i)+" ON "+IntegerToString(AlertTrigged));
               Alert(Symbol()+" Overbought: "+string_пер(per1)+" Sto: "+DoubleToStr(BUFFER_1[i],2)+" | "+string_пер(per2)+" Sto: "+DoubleToStr(BUFFER_2[i],2));
              }
           }
         if(BUFFER_1[i] < InpOversold && BUFFER_2[i] < InpOversold)
           {
            if(AlertON == On && i < 1 && AlertTrigged == false)
              {
               AlertTrigged = true;
               Print(IntegerToString(i)+" ON "+IntegerToString(AlertTrigged));
               Alert(Symbol()+" Oversold: "+string_пер(per1)+" Sto: "+DoubleToStr(BUFFER_1[i],2)+" | "+string_пер(per2)+" Sto: "+DoubleToStr(BUFFER_2[i],2));
              }
           }
         if(BUFFER_1[i] < InpOverbought && BUFFER_1[i] > InpOversold)
           {
            AlertTrigged = false;
           }
         if(BUFFER_2[i] < InpOverbought && BUFFER_2[i] > InpOversold)
           {
            AlertTrigged = false;
           }
        }
      if(AlertType==Signal)
        {
         if(SignalBuffer1[i] > InpOverbought && SignalBuffer2[i] > InpOverbought)
           {
            if(AlertON == On && i < 1 && AlertTrigged == false)
              {
               AlertTrigged = true;
               Alert(Symbol()+" Overbought: "+string_пер(per1)+" Signal: "+DoubleToStr(SignalBuffer1[i],2)+" | "+string_пер(per2)+" Signal: "+DoubleToStr(SignalBuffer2[i],2));
              }

           }
         if(SignalBuffer1[i] < InpOversold && SignalBuffer2[i] < InpOversold)
           {
            if(AlertON == On && i < 1 && AlertTrigged == false)
              {
               AlertTrigged = true;
               Alert(Symbol()+" Oversold: "+string_пер(per1)+" Signal: "+DoubleToStr(SignalBuffer1[i],2)+" | "+string_пер(per2)+" Signal: "+DoubleToStr(SignalBuffer2[i],2));
              }
           }
         if(SignalBuffer1[i] < InpOverbought && SignalBuffer1[i] > InpOversold)
           {
            AlertTrigged = false;
           }
         if(SignalBuffer2[i] < InpOverbought && SignalBuffer2[i] > InpOversold)
           {
            AlertTrigged = false;
           }
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   return(0);
  }

//+------------------------------------------------------------------+
string string_пер(int per)
  {
   if(per == 1)
      return("M1");
   if(per == 5)
      return("M5");
   if(per == 15)
      return("M15");
   if(per == 30)
      return("M30");
   if(per == 60)
      return("H1");
   if(per == 240)
      return(" H4");
   if(per == 1440)
      return("D1");
   if(per == 10080)
      return("W1");
   if(per == 43200)
      return("MN1");
   return(IntegerToString(per));
  }
//+------------------------------------------------------------------+
void DrawLevelLines()
  {
   int subwindow = ChartWindowFind();

   string line_name_1 = "Overbought Level";
   string line_name_2 = "Oversold Level";

   ObjectDelete(line_name_1);
   ObjectDelete(line_name_2);

   if(!ObjectCreate(0, line_name_1, OBJ_HLINE, subwindow, Time[0], InpOverbought))
     {
      Print("Error: #",GetLastError());
     }
   ObjectSetInteger(0, line_name_1, OBJPROP_COLOR, clrMediumSpringGreen);
   ObjectSetInteger(0, line_name_1, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, line_name_1, OBJPROP_WIDTH, 1);

   if(!ObjectCreate(0, line_name_2, OBJ_HLINE, subwindow, Time[0], InpOversold))
     {
      Print("Error: #",GetLastError());
     }
   ObjectSetInteger(0, line_name_2, OBJPROP_COLOR, clrMagenta);
   ObjectSetInteger(0, line_name_2, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, line_name_2, OBJPROP_WIDTH, 1);
  }
//+------------------------------------------------------------------+
int deinit()
  {
   ObjectDelete("on");
   return(false);
  }
//+------------------------------------------------------------------+
