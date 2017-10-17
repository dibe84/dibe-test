/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *  - Test class of LPC_CampaignDeliveriesController
 * @references: 
 *  
 * @changeLog:
 *
 */
@isTest
public class LPC_CampaignDeliveriesControllerTest {
    static TestDataGenerator testDATA = new TestDataGenerator();
    public static Opportunity opp;
    public static OpportunityLineItem oppItem;
    public static Targeting__c targetting;
    public static Product2 prd;
    static Rev__c rev;
    static Metric__c mtr;
    
    /**
     * Set up data befor testing
     */
    static void initData() {
                
        UTIL.isRunningTestSetup = true;
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id, 2, DARTUtil.DART6, testDATA.targetting[0].Id);
        UTIL.isRunningTestSetup = false;
        
        oppItem = [select id, OpportunityId, from_Date__c, Until_Date__c, SalesPriceNet__c, AdOperatingSystems__c,   
                       Keywords_KeyValue_combination__c, KeyValueString__c, AdWebBrowsers__c, Ad_Id__c, Adserver_ID_Order_ID__c, AdKeywords__c, 
                       PriceBookEntry.Product2.Fixed_Site__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c, Ad_Name__c, Device_Targeting__c, AdDayOfWeek__c, AdHourOfDay__c,
                       AdBrowsersMinorVersion__c, AdBrowsersMajorVersion__c, CurrencyIsoCode, PriceBookEntry.Product2.Target_Platform__c, Billing_Category__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_Prio__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_Product_Type__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_MasterSize__c,
                       Quantity, Description, FC_Period__c, FC_Ad_served_every__c, FC_Quantity__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_CompanionSize__c, PriceBookEntry.Product2.Name
                       from OpportunityLineItem where Id= :testDATA.lstLineItems[0].Id];
        
        
        targetting = [select id from Targeting__c where Description__c='test' limit 1];
        
        rev = new Rev__c();
        rev.OpportunityLineItemId__c    = oppItem.id;
        rev.Opportunity__c              = oppItem.OpportunityId;
        rev.Product__c                  = oppItem.PriceBookEntry.Product2Id;
        rev.from_Date__c                = oppItem.from_Date__c;
        rev.until_Date__c               = oppItem.until_Date__c; // default copies from items[0]
        rev.BillingCategory__c          = oppItem.Billing_Category__c;
        rev.QuantityBooked__c           = oppItem.Quantity;
        rev.ExtLineItemId__c            = oppItem.Ad_Id__c + 'test';
        rev.ExtOrderId__c               = oppItem.Adserver_ID_Order_ID__c + 'test';
        upsert rev OpportunityLineItemId__c;
       
        RS__c rs = new RS__c();
        rs.Rev__c = rev.Id;
        rs.Opportunity__c = rev.Opportunity__c;
        rs.From_Date__c = oppItem.from_Date__c;
        rs.Until_Date__c = oppItem.until_Date__c;
        rs.StartOfPeriod__c = oppItem.from_Date__c;
        rs.EndOfPeriod__c = oppItem.until_Date__c;
        rs.UniqueKey__c = ((Datetime) oppItem.from_Date__c).format('yyyyMMdd') + '_LPC_CampaignDeliveriesControllerTest' + rev.Id; // changed from using Oli.id => Rev.id, due to multiple Rev items per product...
        insert rs;
        
        List<Metric__c> lstMt = new List<Metric__c>();

        for(Date dt=oppItem.from_Date__c; dt<=oppItem.until_Date__c; dt = dt.addDays(1)){
             Metric__c m = new Metric__c();
                m.RS__c = rs.id;
                m.Opportunity__c = rev.Opportunity__c;
                m.RevenueExpected__c = 100;
                m.RevenueDelivered__c = 10;
                m.AD_Clicks__c = 100;
                m.AD_Impressions__c = 200;
                m.AD_OSI__c = 10;
                m.AD_Active_View_Viewable_Impressions__c = 10;
                m.AD_Active_View_Viewable_Impressions_Rate__c = 10;
                
                m.MetricDate__c = dt;
                m.UniqueKey__c = ((Datetime) dt).format('yyyyMMdd');
            lstMt.add(m);
        }

        insert lstMt;
    }
    
    /**
     * Test logic in LPC_CampaignDeliveriesController.cls
     */
    @isTest static void testCampaignDeliveries(){
                
        Test.startTest();
        
        initData();
                
        RemoteResponse response = LPC_CampaignDeliveriesController.performDeliveryImport(oppItem, 0);
        //request to get JobId
        response = LPC_CampaignDeliveriesController.getReportJobId(oppItem);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(response.content != null);
        String jobId = (String)response.content;
        //jobId must return 1111111 as we already set in mockup data in DARTMockup
        System.assertEquals('1111111', jobId);
        
        //request to get job status
        response = LPC_CampaignDeliveriesController.getJobStatus(oppItem, jobId);
        System.assertEquals(response.content, 'COMPLETED');
        
        //request download delivery
        response = LPC_CampaignDeliveriesController.doDownloadDelivery(oppItem, jobId);
        System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK, 'success request to download delivery');
        Rev__c revRes = (Rev__c)response.content;
        //the value expected must be same as response value assign in DARTMockup
        System.assertEquals('222', revRes.AD_Impressions__c+'');
        System.assertEquals('223', revRes.AD_Clicks__c+'');
        System.assertEquals('100.000', revRes.AD_OSI__c+'');
        System.assertEquals('14', revRes.AD_Active_View_Viewable_Impressions__c+'');
        System.assertEquals('213', revRes.AD_Active_View_Measurable_Impressions__c+'');
        System.assertEquals('74.00', revRes.AD_Active_View_Viewable_Impressions_Rate__c+'');
        
        //coverage
        LPC_CampaignDeliveriesController lccd = new LPC_CampaignDeliveriesController();
        
        RemoteResponse res = LPC_CampaignDeliveriesController.getLineItemsChart(oppItem.OpportunityId);
        System.assert(RemoteResponse.STATUSCODE_OK == res.statusCode);
        
        RemoteResponse resDCC = LPC_CampaignDeliveriesController.getDataCompareChart(new List<String>{oppItem.Id});
        System.assert(RemoteResponse.STATUSCODE_OK == resDCC.statusCode);
        
        Test.stopTest();
    }
    
}