//+------------------------------------------------------------------+
//|                                                 Counter_Trend.mq5|
//| Counter Trend v1.1                        Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.1"

#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   2

#property indicator_chart_window
#property indicator_type1 DRAW_LINE
#property indicator_type2 DRAW_LINE

#property indicator_color1 clrDodgerBlue
#property indicator_color2 clrRed

#property indicator_width1 1
#property indicator_width2 1



//--- input parameters
input int RangePeriod=50; // RangePeriod
input int MiniRangePeriod=7; // Mini Range Period
input int TrendPeriod=25;  //Trend Period
input  double InpStdDev=1.2;// Angle StdDev
int shift=2;
//---
int min_rates_total;

//--- indicator buffers
double ResBuffer[];
double SupBuffer[];

double UpBuffer[];
double DnBuffer[];
double UpDnBuffer[];
double TrendBuffer[];
double HighesBuffer[];
double LowesBuffer[];
double AtrBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=RangePeriod+TrendPeriod+MiniRangePeriod+shift+2;

//--- indicator buffers   SetIndexBuffer(6,P4aBuffer,INDICATOR_DATA);

   SetIndexBuffer(0,ResBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SupBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,UpBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,DnBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,UpDnBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,TrendBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,HighesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,LowesBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,AtrBuffer,INDICATOR_CALCULATIONS);


//--- calc buffers

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,0);

   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);

//---
   string short_name="Counter Trend v1.1";
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
   int begin_pos=2;
   first=begin_pos;
   if(first+1<prev_calculated)
      first=prev_calculated-2;

   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      SupBuffer[i]=EMPTY_VALUE;
      ResBuffer[i]=EMPTY_VALUE;
      double updn=CalcUpDn(open,high,low,close,i);
      UpDnBuffer[i]=updn;
      if(updn>0)
        {
         UpBuffer[i]=high[i];
         DnBuffer[i]=EMPTY_VALUE;
        }
      else if(updn<0)
        {

         UpBuffer[i]=EMPTY_VALUE;
         DnBuffer[i]=low[i];
        }
      else
        {
         UpBuffer[i]=EMPTY_VALUE;
         DnBuffer[i]=EMPTY_VALUE;
        }
      int second=begin_pos+RangePeriod+shift;
      if(i<=second)continue;
      double dmax=-9999999;
      double dmin=9999999;
      for(j=0;j<RangePeriod;j++)
        {
         if(dmax<high[i-j])dmax=high[i-j];
         if(dmin>low[i-j])dmin=low[i-j];
        }
      HighesBuffer[i]=dmax;
      LowesBuffer[i]=dmin;
      
      int third=second+TrendPeriod+MiniRangePeriod;
      if(i<third)continue;

      double atr=0;
      for(j=0;j<TrendPeriod;j++)
         atr+=MathMax(high[i],close[i-1])-MathMin(low[i],close[i-1]);
      AtrBuffer[i]=atr/TrendPeriod;
      

      //---
      double avg=0.0;
      for(j=0;j<TrendPeriod;j++)
         avg+=UpDnBuffer[i-j];
      TrendBuffer[i]=avg/TrendPeriod;
      //---
      bool is_updateH=false;
      bool is_updateL=false;
      bool rest_up=true;
      for(j=shift;j<MiniRangePeriod+shift;j++)
         if(HighesBuffer[i-j-1]<HighesBuffer[i-j])rest_up=false;

      bool rest_down=true;
      for(j=shift;j<MiniRangePeriod+shift;j++)
         if(LowesBuffer[i-j-1]>LowesBuffer[i-j])rest_down=false;

      double acl=(close[i-1]+close[i-2]+close[i-3])/3;
    

      if(TrendBuffer[i]>0 && rest_up)
        {

         dmax=high[i-shift];
         int top_pos=shift;
         for(j=shift+1;j<RangePeriod;j++)
               if(dmax<high[i-j]){top_pos=j;dmax=high[i-j];}
         if(top_pos>MiniRangePeriod &&
         (ResBuffer[i-1]==EMPTY_VALUE || 
         (ResBuffer[i-1]!=EMPTY_VALUE && ResBuffer[i-1]<acl)))
           {
            double angle=calc_high_Line(high,top_pos-1,i);

            if(angle!=EMPTY_VALUE)
              {
               is_updateH=true;
               for(j=0;j<top_pos;j++)
                  ResBuffer[i -(top_pos-j)]=high[i-top_pos]+(angle*j);

               if(MathAbs(ResBuffer[i-top_pos-1]-ResBuffer[i-top_pos])>3*_Point)
                  ResBuffer[i-top_pos]=EMPTY_VALUE;
              }
           }
        }
      if(TrendBuffer[i]<0 && rest_down)
        {

         dmin=low[i-shift];
         int btm_pos=shift;
         for(j=shift+1;j<RangePeriod;j++)
               if(dmin>low[i-j]){btm_pos=j;dmin=low[i-j];}

         if(btm_pos>MiniRangePeriod && 
            (SupBuffer[i-1]==EMPTY_VALUE ||
             (SupBuffer[i-1]!=EMPTY_VALUE && SupBuffer[i-1]>acl)))
           {
            double angle=calc_low_line(low,btm_pos-1,i);
            if(angle!=EMPTY_VALUE)
              {
               is_updateL=true;
               for(j=0;j<btm_pos;j++)
                  SupBuffer[i-(btm_pos-j)]=low[i-btm_pos]+(angle*j);

               if(MathAbs(SupBuffer[i-btm_pos-1]-SupBuffer[i-btm_pos])>3*_Point)
                  SupBuffer[i-btm_pos]=EMPTY_VALUE;

              }

           }

        }
       
      if(ResBuffer[i]==EMPTY_VALUE && ResBuffer[i-1]!=EMPTY_VALUE )
        {
         ResBuffer[i]=ResBuffer[i-1]*2-ResBuffer[i-2];
        }

      if(SupBuffer[i]==EMPTY_VALUE && SupBuffer[i-1]!=EMPTY_VALUE)
        {
         SupBuffer[i]=SupBuffer[i-1]*2-SupBuffer[i-2];
        }

      if(acl + AtrBuffer[i]*3<ResBuffer[i] ||acl - AtrBuffer[i]*3>ResBuffer[i])ResBuffer[i]=EMPTY_VALUE;
      if(acl + AtrBuffer[i]*3<SupBuffer[i] ||acl - AtrBuffer[i]*3>SupBuffer[i])SupBuffer[i]=EMPTY_VALUE;

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcUpDn(const double  &o[],const double  &h[],const double  &l[],const double  &c[],const int i)
  {

   double up= (c[i]-o[i]) + (c[i]-l[i]);
   double dn= (o[i]-c[i]) + (h[i]-c[i]);

   if(dn==0 && up>0) return +0.5;
   if(dn>0 && up==0) return -0.5;
   if(dn==0 && up==0) return 0.0;
   double dir=(up/(up+dn));

   return dir-0.5;

  }
//+------------------------------------------------------------------+
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
   for(j=0;j<cnt;j++) if(angles[j][0]<=mean+StdDev && angles[j][1]>=i-from_pos*0.5)result=angles[j][0];
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
   for(j=cnt-1;j>=0;j--) if(angles[j][0]>=mean-StdDev && angles[j][1]>=i-from_pos*0.5) result=angles[j][0];

   return result;
  }
//+------------------------------------------------------------------+
