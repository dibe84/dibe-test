/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description:
 *  - test class of LPC_ProductConfiguratorController
 * @references:
 *
 * @changeLog:
 *
 */
@isTest
public class LPC_ProductConfiguratorControllerTest  extends TSTDF_Base {

    public LPC_ProductConfiguratorControllerTest(TSTDF_Dataset dataset) {
        super(dataset);
    }

    public static LPC_ProductConfiguratorControllerTest factory = new LPC_ProductConfiguratorControllerTest(new TSTDF_Dataset());

    public class TSTDF_Dataset extends TSTDF_BaseDataSet {
        public override List<OpportunityLineItem> constructOpportunityLineItems(List<Opportunity> opps, List<OpportunityLineItem> olis) {
            PriceBookEntry pbe = ((List<PriceBookEntry>) GW_sObject.queryRecords('PriceBookEntry', '')).get(0);
            Opportunity opp = opps.get(0);

            opp = (Opportunity) GW_sObject.queryRecords(GW_sObject.getobjectNameFromId(opp.Id), new Set<Id>{opp.Id})[0]; //Get all fields information
            
            OpportunityLineItem oli1 = GW_OpportunityLineItem.createSObject(opp, pbe, 10, 10);
            OpportunityLineItem oli2 = GW_OpportunityLineItem.createSObject(opp, pbe, 12, 15);

            Date startOli1 = Date.newInstance(2030,1,1);
            Date endOli1 = Date.newInstance(2030,6,30);
            Date startOli2 = Date.newInstance(2030,1,31);
            Date endOli2 = Date.newInstance(2030,6,1);

            oli1.from_Date__c = startOli1;
            oli1.until_Date__c= endOli1;
            oli1.Billing_Category__c = 'CPD';
            oli1.SalesPriceNet__c = oli1.UnitPrice;
            oli1.Description = 'TST Description1';
            oli1.UniqueLineDescription__c = 'TSTUniqueLineDescription1';

            oli2.from_Date__c = startOli2;
            oli2.until_Date__c= endOli2;
            oli2.Billing_Category__c = 'CPM';
            oli2.SalesPriceNet__c = oli2.UnitPrice;
            oli2.Description = 'TST Description2';
            oli2.UniqueLineDescription__c = 'TSTUniqueLineDescription2';

            olis.add(oli1);
            olis.add(oli2);
            return olis;
        }

    }

    public override void queryAdditionalResults() {}

    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }

    @isTest static void testGetStreamingOppLineItems(){
        factory.queryResults();

        //create media_basket
        Media_Basket__c mb = new Media_Basket__c();
        mb.OpportunityId__c = factory.data.opps[0].Id;
        mb.AdPriceIdText__c = factory.data.pbes[0].Id;
        insert mb;

        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            LPC_ProductConfiguratorController.getStreamingOppLineItems(factory.data.opps[0].Id);
        }
        Test.stopTest();
    }

    @isTest static void testGetProductsByOpportunitypId() {
        factory.queryResults();
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            Object pbe = LPC_ProductConfiguratorController.getProductsByOpportunitypId(factory.data.opps[0].Id).content;
        }
        Test.stopTest();
    }

    @isTest static void testGetSelectedOpportunity() {
        factory.queryResults();
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            RemoteResponse response = LPC_ProductConfiguratorController.getSelectedOpportunity(factory.data.opps[0].Id);
        }
        Test.stopTest();
    }

    @isTest static void testGetOppStagePicklist() {
        factory.queryResults();
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            List<String> lstStr = LPC_ProductConfiguratorController.getOppStagePicklist();
        }
        Test.stopTest();
    }

    @isTest static void testGetAddedProducts() {
        factory.queryResults();

        //create media_basket
        Media_Basket__c mb = new Media_Basket__c();
        mb.OpportunityId__c = factory.data.opps[0].Id;
        mb.AdPriceIdText__c = factory.data.pbes[0].Id;
        insert mb;

        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            LPC_ProductConfiguratorController.getAddedProducts(factory.data.opps[0].Id, false);
        }
        Test.stopTest();
    }

    @isTest static void testGetInventoryList() {
        factory.queryResults();
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            LPC_ProductConfiguratorController.getInventoryList(factory.data.opps[0].Id);
        }
        Test.stopTest();
    }

    @isTest static void testGetListAdsDelivery() {
        factory.queryResults();

        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            RemoteResponse response = LPC_ProductConfiguratorController.getListAdsDelivery(factory.data.opps[0].Id);
        }
        Test.stopTest();
    }

    @isTest static void testApplyPriceModel() {
        factory.queryResults();
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            OpportunityLineItem oli = ((List<OpportunityLineItem>) LPC_ProductConfiguratorController.getNewOpportunityLineItem(factory.data.opps[0].Id, factory.data.pbes[0].Id).content)[0];
            RemoteResponse response = LPC_ProductConfiguratorController.applyPriceModel(oli);
            oli = (OpportunityLineItem) response.content;
            LPC_ProductConfiguratorController.saveOpportunityLineItem(oli);
        }
        Test.stopTest();
    }

    @isTest static void testCopyOpportunityLineItem() {
        factory.queryResults();

        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            RemoteResponse response = LPC_ProductConfiguratorController.copyOpportunityLineItem(factory.data.olis[0]);
        }
        Test.stopTest();
    }

    @isTest static void testGetOpportunityLineItems() {
        factory.queryResults();

        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            List<OpportunityLineItem> olis = LPC_ProductConfiguratorController.getOpportunityLineItems(factory.data.opps[0].Id);
            System.assertEquals(2, olis.size());
            LPC_ProductConfiguratorController.deleteOpportunityLineItem(factory.data.olis[0].Id);
            olis = LPC_ProductConfiguratorController.getOpportunityLineItems(factory.data.opps[0].Id);
            System.assertEquals(1, olis.size());
            
            // for coverage
            LPC_ProductConfiguratorController.getMapIsImpressionType(factory.data.opps[0].Id);
            LPC_ProductConfiguratorController.checkExistingTopic();
            LPC_ProductConfiguratorController.getProductsByFilter('', '', '', '', '', 1, '', '');
        }
        Test.stopTest();
    }

    @isTest static void testGetSelectedAndMostRecentOpportunities() {
        factory.queryResults();

        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            RemoteResponse response = LPC_ProductConfiguratorController.getSelectedAndMostRecentOpportunities(factory.data.opps[0].Id);
            List<Opportunity> opps = (List<Opportunity>) response.content;
            System.assertEquals(1, opps.size());
        }
        Test.stopTest();
    }

    static TestDataGenerator testDATA = new TestDataGenerator();
    public static Opportunity opty;
    public static OpportunityLineItem oppItem;
    public static Targeting__c targetting;
    public static Product2 prd;

    /**
     * Set up data befor testing
     */
    static void setupDfpData(){

        UTIL.isRunningTestSetup = true;
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id, 2, DARTUtil.DART6, testDATA.targetting[0].Id);
        UTIL.isRunningTestSetup = false;
        opty = [select id, Name, Owner.id, Owner.Name, AccountId, CampaignStart__c, CampaignEnd__c, P_O_Number__c from Opportunity where Id =: testDATA.opp.id];
        prd = [select id from Product2 where Name='Test product0' limit 1];

        testDATA.opp.StageName = 'Signed';
        update testDATA.opp;
        oppItem = [select id, OpportunityId, from_Date__c, Until_Date__c, SalesPriceNet__c, AdOperatingSystems__c,
                       Keywords_KeyValue_combination__c, KeyValueString__c, AdWebBrowsers__c, Ad_Id__c, Adserver_ID_Order_ID__c, AdKeywords__c,
                       PriceBookEntry.Product2.Fixed_Site__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c, Ad_Name__c, Device_Targeting__c, AdDayOfWeek__c, AdHourOfDay__c,
                       AdBrowsersMinorVersion__c, AdBrowsersMajorVersion__c, CurrencyIsoCode, PriceBookEntry.Product2.Target_Platform__c, Billing_Category__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_Prio__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_Product_Type__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_MasterSize__c,
                       Quantity, Description, FC_Period__c, FC_Ad_served_every__c, FC_Quantity__c, Availability__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_CompanionSize__c, PriceBookEntry.Product2.Name
                       from OpportunityLineItem where Description='Test Desc1' and OpportunityId= :opty.Id];
    }

    /**
     * test perform PerformBookingProcess
     */
    @isTest static void testPerformBookingProcess() {
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
                setupDfpData();
                //success
                RemoteResponse response = LPC_ProductConfiguratorController.performBookingProcess(oppItem);
                system.assertEquals(RemoteResponse.STATUSCODE_OK, response.statusCode);
                system.assert('Default message'.equalsIgnoreCase(response.message));
                oppItem = (OpportunityLineItem) GW_sObject.queryRecord('OpportunityLineItem', oppItem.Id);
                system.assert(String.isNotEmpty(oppItem.Adserver_ID_Order_ID__c));
                system.assert(String.isNotEmpty(oppItem.Adserver_Adv_Advertiser_ID__c));

                //No line item assign to booking process
                response = LPC_ProductConfiguratorController.performBookingProcess(new OpportunityLineItem(Id = null));
                system.assert(response.statusCode==RemoteResponse.STATUSCODE_ERROR);
            Test.stopTest();
        }
    }


    /**
     * Test method performAvailForecast
     */
    @isTest static void testPerformAvailForecast(){
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
               setupDfpData();
               RemoteResponse response = LPC_ProductConfiguratorController.performAvailForecast(oppItem, 0);
               Map<Integer, OpportunityLineItem> mItem = (Map<Integer, OpportunityLineItem>) response.content;
               system.assert(mItem.get(0).Availability__c != oppItem.Availability__c, 'Availability of Product Line Item is updated after Forecasting.');
               response = LPC_ProductConfiguratorController.performAvailForecast(new OpportunityLineItem(Id = null), 0);
               system.assert(response.statusCode == RemoteResponse.STATUSCODE_ERROR, 'Fialed as lineitem with null Id is parsed to method.');
               system.assert(String.isNotEmpty(response.message), 'Message cannot be null as lineitem with null Id is parsed to method.');
            Test.stopTest();
        }
    }
    
    /**
     * Test method getProductsByFilter
     */
    @isTest static void testGetProductsByFilter(){ 
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
               RemoteResponse response = LPC_ProductConfiguratorController.getProductsByFilter( factory.data.pbes[0].Id, '', '', '', 'test', 0, '', '');
               system.assert(response.statusCode == RemoteResponse.STATUSCODE_OK);
               Map<String, object> mContent = (Map<String, Object>) response.content;
               system.assert(mContent.get('totalProduct') == 0);
               
               List<Product2> lstProd = new List<Product2>();
               for (PricebookEntry pbe : [Select p.Product2Id From PricebookEntry p where Id IN: factory.data.pbes]) {
                    Product2 prod = new Product2();
                    prod.FilterCategory1__c = 'cate1';
                    prod.FilterCategory2__c = 'cate2';
                    prod.FilterCategory3__c = 'cate2';
                    prod.Id = pbe.Product2Id;
                    lstProd.add(prod);
               }
               update lstProd;
               
               response = LPC_ProductConfiguratorController.getProductsByFilter( factory.data.pbes[0].Id, 'cate1', 'cate2', 'cate3', 'TestProduct', 10, '', '');
               mContent = (Map<String, Object>) response.content;
            Test.stopTest();
        }
    }
    
    /**
     * Test method updateOppStage
     */
    @isTest static void testupdateOppStage(){
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
               setupDfpData();
               LPC_ProductConfiguratorController.updateOppStage(factory.data.opps[0].Id, 'Qualification');
               system.assertEquals(factory.data.opps[0].StageName, 'Qualification');
            Test.stopTest();
        }
    }
    /**
    * Test method getExistedOpli2DisplayInUI
    */
     @isTest static void testgetExistedOpli2DisplayInUI(){
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
                List<Map<String, Object>> oli2dis = LPC_ProductConfiguratorController.getExistedOpli2DisplayInUI(factory.data.opps[0].Id);
                system.assert(oli2dis.size() > 0);
            Test.stopTest();
        }
     }
     
     /**
     * Test method getAddedProductsLPC_optimize
     */
     @isTest static void testgetAddedProductsLPC_optimize(){
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
                List<Object> olis = LPC_ProductConfiguratorController.getAddedProductsLPC_optimize(factory.data.opps[0].Id);
                system.assert(olis.size() > 0);
            Test.stopTest();
        }
     }
     
     /**
     * Test method updateOppStage
     */
    @isTest static void testTractSalespath(){
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
               setupDfpData();
               LPC_ProductConfiguratorController.getAvailableDiscounts(factory.data.olis[0].Id);
               LPC_ProductConfiguratorController.getAvailableProducts(new List<String>{''}, factory.data.olis[0].Id);
               LPC_ProductConfiguratorController.doSetFilterBillCycle(new List<String>{''}, factory.data.opps[0].Id);
               LPC_ProductConfiguratorController.getAllProducts(new List<String>{''}, factory.data.opps[0].Id);
               LPC_ProductConfiguratorController.getExistedAllOpli2DisplayInUI(factory.data.opps[0].Id);
               LPC_ProductConfiguratorController.getIsOpportunityNotEditable(factory.data.opps[0].Id);
               LPC_ProductConfiguratorController.getExistedLineItem2DisplayInUI(factory.data.opps[0].Id);
               LPC_ProductConfiguratorController.updateLineItems(JSON.serialize(factory.data.olis));
               LPC_ProductConfiguratorController.getAccountDiscount(factory.data.opps[0].Id, factory.data.opps[0].AccountId);
               LPC_ProductConfiguratorController.getAddedProductsLPC(factory.data.opps[0].Id);
            Test.stopTest();
        }
    }
    
    /**
     * Test method updateOppStage
     */
    @isTest static void testTractSalespath2(){
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
               setupDfpData();
               Opportunity opp = (Opportunity) GW_Opportunity.getRecord(factory.data.opps[0].Id, new List<String>{'Account.AccountDiscount__c', 'MemberUnit__r.EnableTRACT__c'});
               OpportunityLineItem oppLine = (OpportunityLineItem) GW_sObject.queryRecords('OpportunityLineItem', 'Id = \'' + factory.data.olis[0].Id + '\'', new List<String>{'PricebookEntry.Product2.RecordType.Name'})[0];
               PricebookEntry pbe = (PricebookEntry) GW_sObject.queryRecords('PricebookEntry', 'Id = \'' + factory.data.pbes[0].Id + '\'', new List<String>{'Product2.RecordType.Name', 'Product2.Device_Category__c', 'Product2.Billing_Category__c', 'Product2.Advertising_Medium__c', 'Product2.AdServer_Keywords_Key_Values__c', 'Product2.PredifinedAdunit__c'})[0];
               LPC_ProductConfiguratorController.updateLineItem(new Map<String, Object>{'StartDate' => Date.Today()});
               LPC_ProductConfiguratorController.generateIO(opp.Id);
               LPC_ProductConfiguratorController.attachRequiredPDFs(null, 'ECG', opp.Id, 'EN', false, false);
               LPC_ProductConfiguratorController.delOppLineItem(oppLine.Id, opp.Id);
            Test.stopTest();
        }
    }
    
    @isTest static void testTractSalespath3(){
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('adminUser')) {
            Test.startTest();
               setupDfpData();
               Opportunity opp = (Opportunity) GW_Opportunity.getRecord(factory.data.opps[0].Id, new List<String>{'Account.AccountDiscount__c', 'MemberUnit__r.EnableTRACT__c'});
               OpportunityLineItem oppLine = (OpportunityLineItem) GW_sObject.queryRecords('OpportunityLineItem', 'Id = \'' + factory.data.olis[0].Id + '\'', new List<String>{'PricebookEntry.Product2.RecordType.Name'})[0];
               PricebookEntry pbe = (PricebookEntry) GW_sObject.queryRecords('PricebookEntry', 'Id = \'' + factory.data.pbes[0].Id + '\'', new List<String>{'Product2.RecordType.Name', 'Product2.Device_Category__c', 'Product2.Billing_Category__c', 'Product2.Advertising_Medium__c', 'Product2.AdServer_Keywords_Key_Values__c', 'Product2.PredifinedAdunit__c'})[0];
               
               LPC_ProductConfiguratorController.generateLineItemInstance(opp, pbe, 10 , 100);
               //LPC_ProductConfiguratorController.createOpportunityLineItem(opp.Id, new Map<String, Object>{'Name' => 'Test Opp'});
               LPC_ProductConfiguratorController.getProducts(pbe.PriceBook2Id, new Map<String, Object>{'Name' => 'Test'});
               LPC_ProductConfiguratorController.getProductRateCard(JSON.serialize(new List<Id>{pbe.Product2Id}));
               LPC_ProductConfiguratorController.recalculateFromTRACT(opp.Id, JSON.serialize(oppLine));
               LPC_ProductConfiguratorController.doGetAgreementFromTract(opp.Id);
               //LPC_ProductConfiguratorController.setOppAndOLIValues(opp.Id, JSON.serialize(oppLine));
            Test.stopTest();
        }
    }
}