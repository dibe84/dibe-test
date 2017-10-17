/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *  - test class of LPC_TargetingTemplateSelectorController
 * @references: 
 *  
 * @changeLog:
 *
 */
@isTest
public class LPC_TargetingTemplateSelectorConTest {
    
    public static Opportunity opp;
    public static OpportunityLineItem item;
    public static Targeting__c targetting;
    public static Product2 prd;
    public static TestDataGenerator testDATA = new TestDataGenerator();
    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
        UTIL.isRunningTestSetup = false;
    }
    static void getOppLineItems(){
         opp = [select id, Name, Owner.id, Owner.Name, AccountId, CampaignStart__c, CampaignEnd__c, P_O_Number__c from Opportunity limit 1];
         prd = [select Site__c, id from Product2 where Name='Test product0' limit 1];
         item = [select id, OpportunityId, from_Date__c, Until_Date__c, SalesPriceNet__c, AdOperatingSystems__c, 
                       Keywords_KeyValue_combination__c, KeyValueString__c, AdWebBrowsers__c, Ad_Id__c, AdKeywords__c, 
                       PriceBookEntry.Product2.Fixed_Site__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c, Ad_Name__c, Device_Targeting__c, AdDayOfWeek__c, AdHourOfDay__c,
                       AdBrowsersMinorVersion__c, AdBrowsersMajorVersion__c, CurrencyIsoCode, PriceBookEntry.Product2.Target_Platform__c, Billing_Category__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_Prio__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_Product_Type__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_MasterSize__c,
                       Quantity, Description, FC_Period__c, FC_Ad_served_every__c, FC_Quantity__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_CompanionSize__c, PriceBookEntry.Product2.Name
                       from OpportunityLineItem where Description='Test Desc0' and OpportunityId= :opp.Id];
    }
    static void getTargetting(){
        targetting = [select id from Targeting__c where Description__c='test' limit 1];
    }
    static Targeting__c targ;
    static{
        //create new targeting template
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();

        targ = new Targeting__c();
        targ.Description__c = 'Tageting Template';
        targ.RecordTypeId = RecId;
        insert targ;
    }

    
    @isTest static void testTargetingTemplate() {
        getOppLineItems();
        getTargetting();

        Test.startTest();
            RemoteResponse response = LPC_TargetingTemplateSelectorController.initTemplateN(prd.Site__c);
            System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(response.content != null);

            RemoteResponse checkname = LPC_TargetingTemplateSelectorController.checkTemplateNameExist(targ.Description__c, prd.Site__c, false, item.Id);
            RemoteResponse checkNcreate = LPC_TargetingTemplateSelectorController.checkTemplateNameExist('Targeting Template 1', prd.Site__c, true, item.Id);
            System.assertEquals(checkNcreate.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(checkNcreate.content != null);
            
            RemoteResponse checkdataoli = LPC_TargetingTemplateSelectorController.checkTargetingNotEmptyData(item.Id);
            System.assertEquals(checkdataoli.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(checkdataoli.content != null);

            item.DFP_Time_Wednesday__c = '0:00 - 0:59';
            update item;
            RemoteResponse checkdataoli1 = LPC_TargetingTemplateSelectorController.checkTargetingNotEmptyData(item.Id);
            System.assertEquals(checkdataoli1.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(checkdataoli1.content != null);
            
            //cover code
            RemoteResponse rr1 = new RemoteResponse('Test', 0);
            rr1 = new RemoteResponse('test');

        Test.stopTest();
    }
    
}