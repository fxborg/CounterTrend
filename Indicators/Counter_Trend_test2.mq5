//+------------------------------------------------------------------+
//|                                           Counter_Trend_test2.mq5|
//| Counter Trend test2                       Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.0"
#include <MovingAverages.mqh>
#define PIP      ((_Digits <= 3) ? 0.01 : 0.0001)
#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   2

#property indicator_chart_window
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_type3 DRAW_LINE
#property indicator_type4 DRAW_LINE
#property indicator_type5 DRAW_LINE

#property indicator_color1 clrDodgerBlue
#property indicator_color2 clrRed
#property indicator_color3 clrDodgerBlue
#property indicator_color4 clrRed
#property indicator_color5 clrLimeGreen

#property indicator_width1 1
#property indicator_width2 1


//--- input parameters
input  int SlowPeriod=25;    // MaPeriod
input  int FastPeriod=8;     // MaPeriod

int MiniPeriod=4;     // MaPeriod

input  ENUM_MA_METHOD MaMethod=MODE_SMMA; // Ma Method 
input  ENUM_APPLIED_PRICE MaPriceMode=PRICE_TYPICAL; // Ma Price Mode 
input  int InpHiLoPeriod=25;  // High & Low Period

input  double InpStdDev=1.2;// Angle StdDev
double JointPip=3*PIP;
//+------------------------------------------------------------------+

int CalcMinPeriod=int(InpHiLoPeriod*0.3);

//---
int min_rates_total;
double MiniMaBuffer[];
double FastMaBuffer[];
double SlowMaBuffer[];

//--- indicator buffers
double FlagH_Buffer[];
double FlagL_Buffer[];

//---- for calc 
double HighesBuffer[];
double LowesBuffer[];
double SigH_Buffer[];
double SigL_Buffer[];
double PriceBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=InpHiLoPeriod+5;

   if(MiniPeriod>=FastPeriod)
     {
      Alert("Fast Period is too Small");
      return(INIT_FAILED);
     }
   if(FastPeriod>=SlowPeriod)
     {
      Alert("Slow Period is too Small");
      return(INIT_FAILED);
     }

//--- indicator buffers   SetIndexBuffer(6,P4aBuffer,INDICATOR_DATA);

   SetIndexBuffer(0,FlagH_Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,FlagL_Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,MiniMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,FastMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,SlowMaBuffer,INDICATOR_DATA);

//--- calc buffers
   SetIndexBuffer(5,SigH_Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,SigL_Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,HighesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,LowesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,PriceBuffer,INDICATOR_CALCULATIONS);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,0);

//---
   string short_name="Counter Trend test2";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int i,j,first;
//--- check for bars count
   if(rates_total<=min_rates_total)
      return(0);

//+----------------------------------------------------+
//|Set High Low Buffeer                                |
//+----------------------------------------------------+
   first=SlowPeriod+1;
   if(first+1<prev_calculated)
      first=prev_calculated-2;

   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      //---
      switch(MaPriceMode)
        {
         //---
         case PRICE_CLOSE: PriceBuffer[i]=close[i]; break;
         case PRICE_HIGH: PriceBuffer[i]=high[i]; break;
         case PRICE_LOW: PriceBuffer[i]=low[i]; break;
         case PRICE_MEDIAN: PriceBuffer[i]=(high[i]+low[i])/2; break;
         case PRICE_OPEN: PriceBuffer[i]=open[i]; break;
         case PRICE_TYPICAL: PriceBuffer[i]=(high[i]+low[i]+close[i])/3; break;
         case PRICE_WEIGHTED: PriceBuffer[i]=(high[i]+low[i]+close[i]*2)/4; break;
         default : PriceBuffer[i]=close[i]; break;
         //---
        }
      double prev_price;
      //---
      switch(MaMethod)
        {
         //---
         case MODE_EMA:
            prev_price=(MiniMaBuffer[i-1]!=0) ? MiniMaBuffer[i-1]: PriceBuffer[i-1];
            MiniMaBuffer[i]=ExponentialMA(i,MiniPeriod,prev_price,PriceBuffer);
            prev_price=(FastMaBuffer[i-1]!=0) ? FastMaBuffer[i-1]: PriceBuffer[i-1];
            FastMaBuffer[i]=ExponentialMA(i,FastPeriod,prev_price,PriceBuffer);
            prev_price=(SlowMaBuffer[i-1]!=0) ? SlowMaBuffer[i-1]: PriceBuffer[i-1];
            SlowMaBuffer[i]=ExponentialMA(i,SlowPeriod,prev_price,PriceBuffer);
            break;
         case MODE_LWMA:
            MiniMaBuffer[i]=LinearWeightedMA(i,MiniPeriod,PriceBuffer);
            FastMaBuffer[i]=LinearWeightedMA(i,FastPeriod,PriceBuffer);
            SlowMaBuffer[i]=LinearWeightedMA(i,SlowPeriod,PriceBuffer);

            break;
         case MODE_SMMA:
            prev_price=(MiniMaBuffer[i-1]!=0) ? MiniMaBuffer[i-1]: PriceBuffer[i-1];
            MiniMaBuffer[i]=SmoothedMA(i,MiniPeriod,prev_price,PriceBuffer);
            prev_price=(FastMaBuffer[i-1]!=0) ? FastMaBuffer[i-1]: PriceBuffer[i-1];
            FastMaBuffer[i]=SmoothedMA(i,FastPeriod,prev_price,PriceBuffer);
            prev_price=(SlowMaBuffer[i-1]!=0) ? SlowMaBuffer[i-1]: PriceBuffer[i-1];
            SlowMaBuffer[i]=SmoothedMA(i,SlowPeriod,prev_price,PriceBuffer);

            break;
         default:
            MiniMaBuffer[i]=SimpleMA(i,MiniPeriod,PriceBuffer);
            FastMaBuffer[i]=SimpleMA(i,FastPeriod,PriceBuffer);
            SlowMaBuffer[i]=SimpleMA(i,SlowPeriod,PriceBuffer);
            break;
            //---
        }
      int second=min_rates_total+SlowPeriod;
      if(i<=second)continue;
      //---
      //---
      bool isUp=(MathMin(MiniMaBuffer[i],FastMaBuffer[i])>SlowMaBuffer[i]);
      bool isDown=(MathMax(MiniMaBuffer[i],FastMaBuffer[i])<SlowMaBuffer[i]);

      FlagH_Buffer[i]=EMPTY_VALUE;
      if(isUp && FastMaBuffer[i]>MiniMaBuffer[i])
        {
         SigH_Buffer[i]=high[i];
        }
      FlagL_Buffer[i]=EMPTY_VALUE;
      if(isDown && FastMaBuffer[i]<MiniMaBuffer[i])
        {
         SigL_Buffer[i]=low[i];
        }
      double dev=0;
      for(j=0;j<SlowPeriod;j++)  
         
      if(i<=1+SlowPeriod+InpHiLoPeriod)continue;
      
      double stddev=0.0;
      for(j=0;j<InpHiLoPeriod;j++)
         stddev+=MathPow(close[i-j]-SlowMaBuffer[i-j],2);
      stddev =MathSqrt(stddev/InpHiLoPeriod);
      
      
      double is_updateH=false;
      double is_updateL=false;
      if(SigH_Buffer[i]!=EMPTY_VALUE || SigL_Buffer[i]!=EMPTY_VALUE)
        {
         //---
         int top_pos=0;
         double dmax=high[i];
         for(j=0;j<InpHiLoPeriod;j++)
               if(dmax<high[i-j]){ dmax=high[i-j]; top_pos=j;}
         //---

         //---
         int btm_pos=0;
         double dmin=low[i];
         for(j=0;j<InpHiLoPeriod;j++)
               if(dmin>low[i-j]){ dmin=low[i-j];btm_pos=j;}
         //---
         double max_cl = MathMax(MathMax(close[i-1],close[i-2]),close[i-3]);
         double min_cl = MathMin(MathMin(close[i-1],close[i-2]),close[i-3]);
         if(top_pos>CalcMinPeriod)
           {

            if(FlagH_Buffer[i-1]==EMPTY_VALUE || (FlagH_Buffer[i-1]!=EMPTY_VALUE &&FlagH_Buffer[i-1]<min_cl))
              {
               double angle=calc_high_Line(high,top_pos-1,i);
               if(angle!=EMPTY_VALUE)
                 {
                  is_updateH=true;
                  for(j=0;j<=top_pos;j++)
                     FlagH_Buffer[i-(top_pos-j)]=high[i-top_pos]+(angle*j);
                  if(MathAbs(FlagH_Buffer[i-top_pos-1]-FlagH_Buffer[i-top_pos])>JointPip)
                     FlagH_Buffer[i-top_pos]=EMPTY_VALUE;

                 }
              }
           }
         if(btm_pos>CalcMinPeriod)
           {
            if(FlagL_Buffer[i-1]==EMPTY_VALUE || (FlagL_Buffer[i-1]!=EMPTY_VALUE &&FlagL_Buffer[i-1]>max_cl))
              {
               double angle=calc_low_line(low,btm_pos-1,i);
               if(angle!=EMPTY_VALUE)
                 {
                  is_updateL=true;
                  for(j=0;j<=btm_pos;j++)
                     FlagL_Buffer[i-(btm_pos-j)]=low[i-btm_pos]+(angle*j);

                  if(MathAbs(FlagL_Buffer[i-btm_pos-1]-FlagL_Buffer[i-btm_pos])>JointPip)
                     FlagL_Buffer[i-btm_pos]=EMPTY_VALUE;

                 }
              }
           }

        }

      if(!is_updateH && FlagH_Buffer[i-1]!=EMPTY_VALUE)
        {
         FlagH_Buffer[i]=FlagH_Buffer[i-1]*2-FlagH_Buffer[i-2];
        }

      if(!is_updateL && FlagL_Buffer[i-1]!=EMPTY_VALUE)
        {
         FlagL_Buffer[i]=FlagL_Buffer[i-1]*2-FlagL_Buffer[i-2];
        }

      if((SlowMaBuffer[i-3]<FastMaBuffer[i-3] && SlowMaBuffer[i-2]>FastMaBuffer[i-2])
         || (SlowMaBuffer[i-3]>FastMaBuffer[i-3] && SlowMaBuffer[i-2]<FastMaBuffer[i-2]))
        {
         FlagL_Buffer[i]=EMPTY_VALUE;
         FlagH_Buffer[i]=EMPTY_VALUE;
        }
      if(SlowMaBuffer[i] + stddev*2<FlagH_Buffer[i])FlagH_Buffer[i]=EMPTY_VALUE;
      if(SlowMaBuffer[i] - stddev*2>FlagL_Buffer[i])FlagL_Buffer[i]=EMPTY_VALUE;
       
      
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
double calc_high_Line(const double  &high[],const int from_pos,const int i)
  {
//---
   double result=EMPTY_VALUE;
   int j;
   int cnt=from_pos;
   double angles[][2];
   ArrayResize(angles,cnt);
   int n=0;
   for(j=from_pos-1;j>=0;j--)
     {
      int pos=i-j-1;
      angles[n][0]=(high[i-from_pos-1]-high[pos])/((i-from_pos-1)-pos);
      angles[n][1]=pos;
      n++;
     }
//---
   ArraySort(angles);
//--- calc mean
   double sum=0.0;
   for(j=0; j<cnt; j++)sum+=angles[j][0];
   double mean=sum/cnt;
//--- calc deviation
   sum=0.0;
   for(j=0; j<cnt; j++)sum+=MathPow(angles[j][0]-mean,2);
   double StdDev=MathSqrt(sum/cnt)*InpStdDev;
//---
   for(j=0;j<cnt;j++) if(angles[j][0]<=mean+StdDev)result=angles[j][0];
   return result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calc_low_line(const double  &low[],const int from_pos,const int i)
  {
   double result=EMPTY_VALUE;
   int j;
//---
   int cnt=from_pos;
   double angles[][2];
   ArrayResize(angles,cnt);

   int n=0;
   for(j=from_pos-1;j>=0;j--)
     {
      int pos=i-j-1;
      angles[n][0]=(low[i-from_pos-1]-low[pos])/((i-from_pos-1)-pos);
      angles[n][1]=pos;
      n++;
     }

//---
   ArraySort(angles);
//--- calc mean
   double sum=0.0;
   for(j=0; j<cnt; j++)sum+=angles[j][0];
   double mean=sum/cnt;
//--- calc deviation
   sum=0.0;
   for(j=0; j<cnt; j++)sum+=MathPow(angles[j][0]-mean,2);
   double StdDev=MathSqrt(sum/cnt)*InpStdDev;
//---
   for(j=cnt-1;j>=0;j--) if(angles[j][0]>=mean-StdDev) result=angles[j][0];

   return result;
  }
//+------------------------------------------------------------------+
