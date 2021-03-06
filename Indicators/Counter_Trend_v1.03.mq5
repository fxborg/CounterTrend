//+------------------------------------------------------------------+
//|                                                 Counter_Trend.mq5|
//| Counter Trend                             Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.03"
#include <MovingAverages.mqh>

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   2

#property indicator_chart_window
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE
#property indicator_type3 DRAW_LINE

#property indicator_color1 clrDodgerBlue
#property indicator_color2 clrRed
#property indicator_color3 clrGold

#property indicator_width1 2
#property indicator_width2 2


//--- input parameters
input  int MaPeriod=25;    // MaPeriod

input  ENUM_MA_METHOD MaMethod=MODE_SMMA; // Ma Method 
input  ENUM_APPLIED_PRICE MaPriceMode=PRICE_TYPICAL; // Ma Price Mode 
input  int InpHiLoPeriod=50;  // High & Low Period

input  int InpCalcPeriod=35;  // Line Period
input  double InpStdDev=1.2;// Angle StdDev

//+------------------------------------------------------------------+

int FlagMinPeriod=int(InpCalcPeriod*0.3);

//---
int min_rates_total;
double MaBuffer[];

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
   if(InpHiLoPeriod <InpCalcPeriod)
     {
      Alert("High & Low Period is too Small");
      return(INIT_FAILED);
     }

//--- indicator buffers   SetIndexBuffer(6,P4aBuffer,INDICATOR_DATA);

   SetIndexBuffer(0,FlagH_Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,FlagL_Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,MaBuffer,INDICATOR_DATA);

//--- calc buffers
   SetIndexBuffer(3,SigH_Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SigL_Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,HighesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,LowesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,PriceBuffer,INDICATOR_CALCULATIONS);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);

//---
   string short_name="Counter Trend v1.03";
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
   int i,j,k,first;
//--- check for bars count
   if(rates_total<=min_rates_total)
      return(0);

//+----------------------------------------------------+
//|Set High Low Buffeer                                |
//+----------------------------------------------------+
   first=InpHiLoPeriod;
   if(first+1<prev_calculated )
      first=prev_calculated-2;
   else
      for(i=0; i<first; i++)
        {
         LowesBuffer[i]=low[i];
         HighesBuffer[i]=high[i];
        }
   

   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      ;
      //--- calculate range spread
      double dmin=10000000.0;
      double dmax=-10000000.0;
      //---      
      for(k=i-InpHiLoPeriod+1; k<=i; k++)
        {
         if(dmin>low[k]) dmin=low[k];
         if(dmax<high[k]) dmax=high[k];
        }
      //---
      LowesBuffer[i]=dmin;
      HighesBuffer[i]=dmax;
      //---
      if(i<InpHiLoPeriod+MaPeriod+1)continue;

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
      //---
      int second=min_rates_total;
      if(i<=second)continue;
      //---
      double prev_price=(MaBuffer[i-1]!=0 && MaBuffer[i-1]!=EMPTY_VALUE ) ? MaBuffer[i-1]: PriceBuffer[i-1];
      switch(MaMethod)
        {
         //---
         case MODE_SMA: MaBuffer[i]=SimpleMA(i,MaPeriod,PriceBuffer); break;
         case MODE_EMA: MaBuffer[i]=ExponentialMA(i,MaPeriod,prev_price,PriceBuffer); break;
         case MODE_LWMA: MaBuffer[i]=LinearWeightedMA(i,MaPeriod,PriceBuffer); break;
         case MODE_SMMA: MaBuffer[i]=SmoothedMA(i,MaPeriod,prev_price,PriceBuffer);  break;
         default: MaBuffer[i]=SimpleMA(i,MaPeriod,PriceBuffer); break;
         //---
        }
      //---
      if(i<=InpHiLoPeriod+MaPeriod+InpCalcPeriod+5)continue;


      FlagH_Buffer[i]=EMPTY_VALUE;
      FlagL_Buffer[i]=EMPTY_VALUE;

      //+----------------------------------------------------+
      //|trend rest ?                                        |
      //+----------------------------------------------------+
      bool is_up_rest=true;
      for(j=0;j<FlagMinPeriod;j++)
        {
         if(
            HighesBuffer[i]!=HighesBuffer[i-j])
           {
            is_up_rest=false;
           }
        }
      bool is_down_rest=true;
      for(j=0;j<FlagMinPeriod;j++)
        {
         if(
            LowesBuffer[i]!=LowesBuffer[i-j])
           {
            is_down_rest=false;
           }
        }
      double max_cl = MathMax(MathMax(close[i-1],close[i-2]),close[i]);
      double min_cl = MathMin(MathMin(close[i-1],close[i-2]),close[i]);

      //+----------------------------------------------------+
      //|up trend                                            |
      //+----------------------------------------------------+
      if(is_up_rest)
        {

         if(SigH_Buffer[i-1]!=0 && ( FlagH_Buffer[i-2]!=EMPTY_VALUE && FlagH_Buffer[i-2] >=min_cl))
           {
            //+----------------------------------------------------+
            //|exists                                              |
            //+----------------------------------------------------+
            SigH_Buffer[i]=SigH_Buffer[i-1];

            if(FlagH_Buffer[i-2]!=EMPTY_VALUE && FlagH_Buffer[i-2]>=MaBuffer[i-2])
               FlagH_Buffer[i-1]=FlagH_Buffer[i-2]*2-FlagH_Buffer[i-3];
           }

         else
          {
            //+----------------------------------------------------+
            //|detect pattern                                      |
            //+----------------------------------------------------+
            double arr_hi[];
            ArraySetAsSeries(arr_hi,true);

            int chk_h=CopyHigh(Symbol(),PERIOD_CURRENT,rates_total-i,InpCalcPeriod,arr_hi);
            if(chk_h<1)continue;
            int from_pos=ArrayMaximum(arr_hi);
            //---
            if(from_pos>=FlagMinPeriod-1 && high[i-from_pos-1]>=MaBuffer[i-from_pos-1])
              {
               double angle=calc_high_Line(high,from_pos,i);
               if(angle!=EMPTY_VALUE)
                 {
                  double tmp=high[i-from_pos-1]+(angle*(from_pos-1));
                  if(tmp>=MaBuffer[i-1])
                    {
                     SigH_Buffer[i]=high[i];
                     FlagH_Buffer[i-from_pos-2]=EMPTY_VALUE;
                     for(j=from_pos;j>=0;j--)
                        FlagH_Buffer[i-j-1]=high[i-from_pos-1]+(angle*(from_pos-j));
                    }
                 }
              }
           }
        }
      //+----------------------------------------------------+
      //|down trend                                          |
      //+----------------------------------------------------+
      if(is_down_rest)
        {
        //+----------------------------------------------------+
         //|exists                                              |
         //+----------------------------------------------------+
         if(SigL_Buffer[i-1]!=0 && ( FlagL_Buffer[i-2]!=EMPTY_VALUE &&  FlagL_Buffer[i-2] <=max_cl))
           {
            SigL_Buffer[i]=SigL_Buffer[i-1];
            if(FlagL_Buffer[i-2]!=EMPTY_VALUE && FlagL_Buffer[i-2]<=MaBuffer[i-2])
               FlagL_Buffer[i-1]=FlagL_Buffer[i-2]*2-FlagL_Buffer[i-3];
           }

         else
 
           {
            //+----------------------------------------------------+
            //| detect                                             |
            //+----------------------------------------------------+
            double arr_lo[];
            ArraySetAsSeries(arr_lo,true);
            int chk_l=CopyLow(Symbol(),PERIOD_CURRENT,rates_total-i,InpCalcPeriod,arr_lo);
            if(chk_l<1)continue;
            int from_pos=ArrayMinimum(arr_lo);
            
            //---
            if(from_pos>=FlagMinPeriod-1 && low[i-from_pos-1]<=MaBuffer[i-from_pos-1])
              {
               double angle=calc_low_line(low,from_pos,i);
               if(angle!=EMPTY_VALUE)
                 {
                  double tmp=low[i-from_pos-1]+(angle*(from_pos-1));
                  if(tmp<MaBuffer[i-1])
                    {
                     SigL_Buffer[i]=low[i];
                     FlagL_Buffer[i-from_pos-2]=EMPTY_VALUE;
                     for(j=from_pos;j>=0;j--)
                        FlagL_Buffer[i-j-1]=low[i-from_pos-1]+(angle*(from_pos-j));
                    }
                 }
              }
           }
        }
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