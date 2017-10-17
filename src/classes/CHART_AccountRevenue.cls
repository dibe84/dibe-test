/**
 *  Controller for draw chart
 *  @author: Pheaktra Hun
 *  @date : 11-Jul-2016
 *  @ticket : Task #9533 - CD-553 - Booked & delivered revenue charts on account layout 
 */
public with sharing class CHART_AccountRevenue {

    private final Account acct;
    public CHART_AccountRevenueDataHelper.ChartBuilder chartBuilder{get;set;}
    
    public CHART_AccountRevenue(ApexPages.StandardController stdController) {
        this.acct = (Account)stdController.getRecord();
    }
    
    public void getAdvertiserBookedRevenueAmountYoY() {
        String id = this.acct.Id; 
        Integer firstYear = CHART_AccountRevenueDataHelper.firstYear;
    
        AggregateResult[] groupedResults =  [SELECT FISCAL_YEAR(CloseDate) YearOfSales, SUM(TotalAmountNet__c) TotalAmount FROM Opportunity
                                                WHERE AccountId = :id AND FISCAL_YEAR(CloseDate) >= :firstYear and IsWon = TRUE
                                                GROUP BY FISCAL_YEAR(CloseDate) ORDER BY FISCAL_YEAR(CloseDate)]; 
        
        chartBuilder = CHART_AccountRevenueDataHelper.buildChartData(groupedResults, false);
    }
    
    public void getAdvertiserDeliveredRevenueAmountYoY() {
        String id = this.acct.Id; 
        Integer firstYear = CHART_AccountRevenueDataHelper.firstYear;
    
        AggregateResult[] groupedresults =  [SELECT FISCAL_YEAR(EndOfPeriod__c) YearOfSales, SUM(Revenue__c) TotalAmount FROM RS__c
                                                WHERE Opportunity__r.AccountId = :id AND FISCAL_YEAR(EndOfPeriod__c ) >= :firstYear and Opportunity__r.IsWon = TRUE
                                                GROUP BY FISCAL_YEAR(EndOfPeriod__c) ORDER BY FISCAL_YEAR(EndOfPeriod__c) ASC];  

        chartBuilder = CHART_AccountRevenueDataHelper.buildChartData(groupedResults, false);
    }

    public void getAdvertiserBookedRevenueAmountMoM() {
        String id = this.acct.Id;
        Integer firstYear = CHART_AccountRevenueDataHelper.firstMonthYear;
    
        AggregateResult[] groupedresults = [SELECT FISCAL_MONTH(CloseDate) MonthOfSale, FISCAL_YEAR(CloseDate) YearOfSales, SUM(TotalAmountNet__c) TotalAmount 
                                            FROM Opportunity WHERE AccountId = :id AND FISCAL_YEAR(CloseDate) >= :firstYear And IsWon = TRUE 
                                            GROUP BY FISCAL_MONTH(CloseDate), FISCAL_YEAR(CloseDate) ORDER BY FISCAL_MONTH(CloseDate), FISCAL_YEAR(CloseDate)]; 
        chartBuilder = CHART_AccountRevenueDataHelper.buildChartData(groupedResults, true);
    }
    
    public void getAdvertiserDeliveredRevenueAmountMoM() {
        String id = this.acct.Id;
        Integer firstYear = CHART_AccountRevenueDataHelper.firstMonthYear;
    
        AggregateResult[] groupedresults = [SELECT FISCAL_MONTH(EndOfPeriod__c) MonthOfSale, FISCAL_YEAR(EndOfPeriod__c) YearOfSales, SUM(Revenue__c) TotalAmount FROM RS__c
                                             WHERE Opportunity__r.AccountId = :id AND FISCAL_YEAR(EndOfPeriod__c) >= :firstYear And Opportunity__r.IsWon = TRUE 
                                            GROUP BY FISCAL_MONTH(EndOfPeriod__c), FISCAL_YEAR(EndOfPeriod__c) 
                                            ORDER BY FISCAL_MONTH(EndOfPeriod__c), FISCAL_YEAR(EndOfPeriod__c)];
        
        chartBuilder = CHART_AccountRevenueDataHelper.buildChartData(groupedResults, true);
    }
    
    public void getAgencyBookedRevenueAmountYoY() {
        String id = this.acct.Id; 
        Integer firstYear = CHART_AccountRevenueDataHelper.firstYear;
    
        AggregateResult[] groupedresults =  [SELECT FISCAL_YEAR(CloseDate) YearOfSales, SUM(TotalAmountNet__c) TotalAmount FROM Opportunity
                                                WHERE Agency__c = :id AND FISCAL_YEAR(CloseDate) >= :firstYear and IsWon = TRUE
                                                GROUP BY FISCAL_YEAR(CloseDate) ORDER BY FISCAL_YEAR(CloseDate) ASC]; 

        chartBuilder = CHART_AccountRevenueDataHelper.buildChartData(groupedResults, false);
    }
    
    public void getAgencyDeliveredRevenueAmountYoY() {
        String id = this.acct.Id; 
        Integer firstYear = CHART_AccountRevenueDataHelper.firstYear;
    
        AggregateResult[] groupedResults =  [SELECT FISCAL_YEAR(EndOfPeriod__c) YearOfSales, SUM(Revenue__c) TotalAmount FROM RS__c
                                            WHERE Opportunity__r.Agency__c = :id AND FISCAL_YEAR(EndOfPeriod__c) >= :firstYear and Opportunity__r.IsWon = TRUE
                                            GROUP BY FISCAL_YEAR(EndOfPeriod__c) ORDER BY FISCAL_YEAR(EndOfPeriod__c) ASC]; 

        chartBuilder = CHART_AccountRevenueDataHelper.buildChartData(groupedResults, false);
    }

    public void getAgencyBookedRevenueAmountMoM() {
        String id = this.acct.Id;
        Integer firstYear = CHART_AccountRevenueDataHelper.firstMonthYear;
    
        AggregateResult[] groupedresults =  [SELECT FISCAL_MONTH(CloseDate) MonthOfSale, FISCAL_YEAR(CloseDate) YearOfSales, 
                                                SUM(TotalAmountNet__c) TotalAmount FROM Opportunity
                                                WHERE Agency__c = :id AND FISCAL_YEAR(CloseDate) >= :firstYear and IsWon = TRUE
                                                GROUP BY FISCAL_MONTH(CloseDate), FISCAL_YEAR(CloseDate) 
                                                ORDER BY FISCAL_MONTH(CloseDate), FISCAL_YEAR(CloseDate)];  
    
        chartBuilder = CHART_AccountRevenueDataHelper.buildChartData(groupedResults, true);
    }
    
    public void getAgencyDeliveredRevenueAmountMoM() {
        String id = this.acct.Id;
        Integer firstYear = CHART_AccountRevenueDataHelper.firstMonthYear;
    
        AggregateResult[] groupedResults =  [SELECT FISCAL_MONTH(EndOfPeriod__c) MonthOfSale, FISCAL_YEAR(EndOfPeriod__c) YearOfSales, 
                                            SUM(Revenue__c) TotalAmount FROM RS__c
                                            WHERE Opportunity__r.Agency__c = :id AND FISCAL_YEAR(EndOfPeriod__c) >= :firstYear and Opportunity__r.IsWon = TRUE
                                            GROUP BY FISCAL_MONTH(EndOfPeriod__c), FISCAL_YEAR(EndOfPeriod__c) 
                                            ORDER BY FISCAL_MONTH(EndOfPeriod__c), FISCAL_YEAR(EndOfPeriod__c)];

        chartBuilder = CHART_AccountRevenueDataHelper.buildChartData(groupedResults, true);
    }
    
}