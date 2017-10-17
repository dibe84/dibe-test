/**
 *  Helper for account chart data
 *  @author: Pheaktra Hun
 *  @date : 11-Jul-2016
 *  @ticket : Task #9533 - CD-553 - Booked & delivered revenue charts on account layout
 */
public with sharing class CHART_AccountRevenueDataHelper {
    
    // Default number of years shown on the "Account Sales, Year over Year" report
    static final Integer CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN = 5;
    
    // Default number of years shown on the "Account Sales, Month over Month" report
    static final Integer CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN = 3;
    
    public static Integer firstYear = date.today().year() - CLOSED_SALES_AMOUNT_YOY_YEARS_SHOWN + 1;
    public static Integer firstMonthYear = date.today().year() - CLOSED_SALES_AMOUNT_MOM_YEARS_SHOWN + 1;
    
    static Map<Integer, String>mMonth = new Map<Integer, String>{
        1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'May', 6 => 'Jun', 7 => 'Jul' , 8 => 'Aug', 9 => 'Sep', 10 => 'Oct', 11 => 'Nov', 12 => 'Dec'
    };
    
    public static ChartBuilder buildChartData(List<AggregateResult>lstData, Boolean isMonth){
        
        ChartBuilder builder = new ChartBuilder();
        Map<String, String>mGroup = new Map<String, String>();
        for (AggregateResult ar : lstData)  {
            
            String yearOfSale = String.valueOf(ar.get('YearOfSales'));
            
            String yDataField; 
            if(!mGroup.containsKey(yearOfSale)){ 
                yDataField = 'yData' + (mGroup.size() + 1);
                mGroup.put(yearOfSale, yDataField);
                if(yDataField == 'yData1') builder.chartTitle1 = yearOfSale;
                if(yDataField == 'yData2') builder.chartTitle2 = yearOfSale;
                if(yDataField == 'yData3') builder.chartTitle3 = yearOfSale;
            }
            
            ChartData d = new ChartData();
            Integer xData = (Integer)ar.get(isMonth ? 'MonthOfSale' : 'YearOfSales');
            d.xData = mMonth.containsKey(xData) ? mMonth.get(xData) : xData + '';
            
            if(yDataField == 'yData1') d.yData1 = (Double)ar.get('TotalAmount');
            if(yDataField == 'yData2') d.yData2 = (Double)ar.get('TotalAmount');
            if(yDataField == 'yData3') d.yData3 = (Double)ar.get('TotalAmount');
            
            builder.datas.add(d);
        }
        return builder;
    }
    
    public class ChartBuilder{
        
        public String chartTitle1{get;set;}
        public String chartTitle2{get;set;}
        public String chartTitle3{get;set;}
        public List<ChartData>datas{get;set;}
        public ChartBuilder(){
            this.datas = new List<ChartData>();
        }
    }
    
    public class ChartData{
        public String xData{get;set;}
        public Double yData1{get;set;}
        public Double yData2{get;set;}
        public Double yData3{get;set;}
        public ChartData(){
            yData1 = 0.0;
            yData2 = 0.0;
            yData3 = 0.0;
        }
    }
    
}