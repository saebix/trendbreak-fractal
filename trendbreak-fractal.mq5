#property copyright "2009-2020, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrGray
#property indicator_label1  "Fractal Up"

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrGray
#property indicator_label2  "Fractal Down"

#property indicator_type3   DRAW_ARROW
#property indicator_color3  Red
#property indicator_label3  "sell trigger"

#property indicator_type4   DRAW_ARROW
#property indicator_color4  Green
#property indicator_label4  "buy trigger"

double ExtUpBuffer[];
double ExtLowBuffer[];
double ExtSellBuffer[];
double ExtBuyBuffer[];

int    fractalArrowShift = 10;
int    triggerArrowShift = 20;
int fractal_sign_size = 1;
int trigger_sign_size = 2;

#define OBJECT_PREFIX       "trend line"
//--- input
input int how_many = 2; //bars left and right

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit() {

   SetIndexBuffer(0, ExtUpBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ExtLowBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ExtSellBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, ExtBuyBuffer, INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

   PlotIndexSetInteger(0, PLOT_ARROW, 218);
   PlotIndexSetInteger(1, PLOT_ARROW, 217);
   PlotIndexSetInteger(2, PLOT_ARROW, 234);
   PlotIndexSetInteger(3, PLOT_ARROW, 233);

   PlotIndexSetInteger(0, PLOT_ARROW_SHIFT, -fractalArrowShift);
   PlotIndexSetInteger(1, PLOT_ARROW_SHIFT,  fractalArrowShift);
   PlotIndexSetInteger(2, PLOT_ARROW_SHIFT, -triggerArrowShift);
   PlotIndexSetInteger(3, PLOT_ARROW_SHIFT,  triggerArrowShift);

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0);

   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, fractal_sign_size);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, fractal_sign_size);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, trigger_sign_size);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, trigger_sign_size);

}
//+------------------------------------------------------------------+
//|  OnCalculate function                                            |
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
                const int &spread[]) {
                

   if(rates_total < ((how_many * 2) + 1))
      return(0);


   int start,linestart;

   if(prev_calculated < ((how_many * 2) + 3)) {
      start = how_many;
      linestart = 0;
      ArrayInitialize(ExtUpBuffer,0);
      ArrayInitialize(ExtLowBuffer,0);
   } else
   {
      start = rates_total - ((how_many * 2) + 1);
      linestart = rates_total - 100;
   }

//--- Low Fractal
   for(int i = start; i < rates_total - (how_many + 1); i++) 
   {
      bool IsFractalDn = true;
      for(int j = 1; j <= how_many && IsFractalDn == true; j++) {
         IsFractalDn = (IsFractalDn&&(low[i] < low[i + j]));
         IsFractalDn = (IsFractalDn&&(low[i] < low[i - j]));
      }
      if(IsFractalDn) 
         ExtLowBuffer[i] = low[i];
      else
         ExtLowBuffer[i] = 0;
   }
//--- Up Fractal
   for(int i = start; i < rates_total - (how_many + 1); i++) 
   {
      bool IsFractalUp = true;
      for(int j = 1; j <= how_many && IsFractalUp == true; j++) {
         IsFractalUp = (IsFractalUp&&(high[i] > high[i + j]));
         IsFractalUp = ((IsFractalUp&&high[i] > high[i - j]));
      }
      if(IsFractalUp) 
         ExtUpBuffer[i] = high[i];
      else
         ExtUpBuffer[i] = 0;
   }


   for(int i = 0; i < rates_total - (how_many + 1); i++)
   {

        if(ExtLowBuffer[i] > 0)
        {
            bool deadbull       = false;
            bool thirdbullfound = false;
            bool bullbreakfound = false;
            int i1,i2,i3;

            for(int j = i+1; j < rates_total - (how_many + 1) && !thirdbullfound && !deadbull; j++)
            {
                if(low[j]<low[i])
                {
                    deadbull = true;
                }

                else if(ExtLowBuffer[j] > 0 )
                {
                    thirdbullfound = true;
                    i3 = j;
                }
                
            }
            
            for(int k = i3+1; k < rates_total - (how_many + 1) && thirdbullfound && !bullbreakfound && (k < i3+10); k++)
            {
                if (close[k]<low[i3])
                {
                    bullbreakfound = true;
                    ExtSellBuffer[k] = high[k];
                    DrawTrendLine(time[i],time[i3],low[i],low[i3],Green,STYLE_SOLID);
                    break;
                }
                
            }
        }

        else if(ExtUpBuffer[i] > 0)
        {
            bool deadbear       = false;
            bool thirdbearfound = false;
            bool bearbreakfound = false;
            int i1,i2,i3;

            for(int j = i+1; j < rates_total - (how_many + 1) && !thirdbearfound && !deadbear; j++)
            {
                if(high[j]>high[i])
                {
                    deadbear = true;
                }

                else if(ExtUpBuffer[j] > 0 )
                {
                    thirdbearfound = true;
                    i3 = j;
                }
                
            }
            
            for(int k = i3+1; k < rates_total - (how_many + 1) && thirdbearfound && !bearbreakfound && (k < i3+10); k++)
            {
                if (close[k]>high[i3])
                {
                    bearbreakfound = true;
                    ExtBuyBuffer[k] = low[k];
                    DrawTrendLine(time[i],time[i3],high[i],high[i3],Red,STYLE_SOLID);
                    break;
                }
                
            }
        }

   }

   return(rates_total);
}
//+------------------------------------------------------------------+
//| Draw a trend line on main chart or on indicator                  |
//+------------------------------------------------------------------+
void DrawTrendLine(datetime x1,datetime x2,double y1,double y2,color lineColor,
                     ENUM_LINE_STYLE style)
  {
   string label=OBJECT_PREFIX+"#"+DoubleToString(x1,0)+"#"+DoubleToString(x2,0);
   int subwindow=0 ;
   ObjectDelete(0,label);
   ObjectCreate(0,label,OBJ_TREND,subwindow,x1,y1,x2,y2,0,0);
   //ObjectSetInteger(0,label,OBJPROP_RAY_RIGHT,true);
   ObjectSetInteger(0,label,OBJPROP_COLOR,lineColor);
   ObjectSetInteger(0,label,OBJPROP_STYLE,style);
   ObjectSetInteger(0,label,OBJPROP_WIDTH,2);
  }
