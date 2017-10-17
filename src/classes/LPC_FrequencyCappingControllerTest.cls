/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 12/Sep/2016
 * @description: 
 *  - test class of LPC_FrequencyCappingController
 * @references: 
 *
 * @changeLog:
 * - 07/Apr/2017: Modified to make it runable with MemberUnit
 *
 */
@isTest
private class LPC_FrequencyCappingControllerTest {

    public static TestDataGenerator testDATA = new TestDataGenerator();
    public static TST_DataFactory fac; //Use TST_DataFactory to make sure every records contain Member Unit

    static{

        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        
        
        fac = TST_DataFactory.getInstance();

        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        UTIL.isRunningTestSetup = false;
    }
    
    /*
     *  Test LPC_FrequencyCappingController methods
     */
    @isTest static void testFrequencyCapping() {
    
        System.runAs ( fac.testUser ) {

            testDATA.createSite(new Set<String>{'US'});
            Product2 prod = new Product2( Name='Test Ad Spec', Site__c = testDATA.sites[0].Id, Available_Key_Values__c='TestKey1;TestKey2;TestKey3');
            insert prod;
            
            testDATA.getPricebook2();
            PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice = false, Product2Id = prod.Id, Pricebook2Id = testDATA.standardPbId, UnitPrice = 1.00, IsActive=true, CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY);
            insert pbe1;
            
            Targeting__c t = new Targeting__c(TempBinder__c = true); 
            insert t;
            
            //create new targeting template
            Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();
            Targeting__c targ = new Targeting__c();
            targ.Description__c = 'Tageting Template';
            targ.RecordTypeId = RecId;
            insert targ;
            
            OpportunityLineItem oppItem = new OpportunityLineItem(
                                       opportunityId = fac.opp.id,
                                       from_Date__c =  system.today(), 
                                       until_Date__c = system.today().addDays(7),
                                       Quantity = 1,
                                       TotalPrice = 0.01,
                                       PricebookEntryId = pbe1.id,
                                       Billing_category__c = 'CPM', 
                                       Description = 'item test',
                                       Targeting__c = t.id);
            OpportunityLineItem oppItem2 = new OpportunityLineItem(
                                       opportunityId = fac.opp.id,
                                       from_Date__c =  system.today(), 
                                       until_Date__c = system.today().addDays(7),
                                       Quantity = 1,
                                       TotalPrice = 0.01,
                                       PricebookEntryId = pbe1.id,
                                       Billing_category__c = 'CPM', 
                                       Description = 'item test');
            Test.startTest();                           
                insert new List<OpportunityLineItem>{oppItem, oppItem2};
    
                List<String> lstPicklist = LPC_FrequencyCappingController.getPicklistValues('Opportunity','InvoiceGrouping__c');
                System.assert(lstPicklist != null);
                        
                        
                RemoteResponse res = LPC_FrequencyCappingController.getListTarFreAssociate(oppItem.Id);
                System.assertEquals(res.statusCode, RemoteResponse.STATUSCODE_OK);
                
                
                res = LPC_FrequencyCappingController.getListTarFreAssociateTemplate(targ.Id);
                System.assertEquals(res.statusCode, RemoteResponse.STATUSCODE_OK);
                
                
                List<TargetingFrequencyAssociation__c>lstTarFre = new List<TargetingFrequencyAssociation__c>();
                lstTarFre.add(new TargetingFrequencyAssociation__c(Name='a1EN0000000mWcu', Targeting__c = t.Id));       
                                                            
                res = LPC_FrequencyCappingController.saveFrequencyCapping(oppItem2.Id, lstTarFre);
                System.assertEquals(res.statusCode, RemoteResponse.STATUSCODE_OK);
                
                
                res = LPC_FrequencyCappingController.saveFrequencyCappingTemplate(targ.Id, lstTarFre);
                System.assertEquals(res.statusCode, RemoteResponse.STATUSCODE_OK);
            Test.stopTest();                
            
        }

    }
}