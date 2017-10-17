/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: test class of LPC_TargetingTreeSelectorController
 * @references:
 *
 * @changeLog:
 *
 */
@isTest
public class LPC_TargetingTreeSelectorControllerTest {

     public static Opportunity opp;
     public static OpportunityLineItem item;
     public static Targeting__c targetting;
     public static Product2 prd;
     public static Devices__c device0, device1, device2;
     public static Connection__c conn0, conn1, conn2;
     public static Geography__c geo0, geo1, geo2;
     public static Content__c cont1, cont2;

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
         prd = [select id, Site__c from Product2 where Name='Test product0' limit 1];
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

    //@vitou 15-05-2015
    static void getConnections(){
        Connection__c[] con = [select id from Connection__c where Dart_ID__c=123456 OR Dart_ID__c=111111 OR Dart_ID__c=666666];
        conn0 = con[0];
        conn1 = con[1];
        conn2 = con[2];
    }

    //@vitou 15-05-2015
    static void getGeographies(){
        Geography__c[] geo = [select id from Geography__c where Dart_ID__c=123456 OR Dart_ID__c=888888 OR Dart_ID__c=999999];
        geo0 = geo[0];
        geo1 = geo[1];
        geo2 = geo[2];
    }
    @isTest static void testTargetingTreeSeletor() {

        getOppLineItems();
        getTargetting();
        getConnections();

        User currentUser = new User(Id = UserInfo.getUserId());
        //User userAdmin;
        User userAdmin = [ select id from User where Username='testUser1@boco.com' limit 1];

        Account acc;
        System.runAs ( currentUser ) {
            acc = new Account(name='Test Account Test class',ownerId= userAdmin.id);
            insert acc;
        }

        MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test member unit' AND LineOfBusiness__c = 'AD'];

        Opportunity  opp1 = new Opportunity(name='Test', closeDate= system.today(), stageName='test', AccountId= acc.id, MemberUnit__c=mu.Id); //Add MU information
        system.runAs(userAdmin){
            insert opp1;
        }

        testDATA.createSite(new Set<String>{'US'});
        Product2 prod = new Product2( Name='Test Ad Spec', Site__c = testDATA.sites[0].Id);
        insert prod;

        testDATA.getPricebook2();
        PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice = false, Product2Id = prod.Id, Pricebook2Id = testDATA.standardPbId, UnitPrice = 1.00, IsActive=true, CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY);
        insert pbe1;

        OpportunityLineItem oppItem = new OpportunityLineItem(
                                           opportunityId = opp1.id,
                                           from_Date__c =  system.today(),
                                           until_Date__c = system.today().addDays(7),
                                           Quantity = 1,
                                           TotalPrice = 0.01,
                                           PricebookEntryId = pbe1.id,
                                           Billing_category__c = 'CPM',
                                           Description = 'item test'
                                           );
        insert oppItem;

        //create new targeting template
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();
        Targeting__c targ = new Targeting__c();
        targ.Description__c = 'Tageting Template';
        targ.RecordTypeId = RecId;
        insert targ;

        Test.startTest();

        LPC_TargetingTreeSelectorController ttsc = new LPC_TargetingTreeSelectorController();
        ttsc.lsts = new List<LPC_TargetingTreeSelectorController.DTOTreeItem>();
        RemoteResponse getTreeDevice = LPC_TargetingTreeSelectorController.getTree('Device', oppItem.id);
        RemoteResponse getTreeContent = LPC_TargetingTreeSelectorController.getTree('Ad_Unit', oppItem.id);
        RemoteResponse getTreeDevice1 = LPC_TargetingTreeSelectorController.getTree('Device', item.id);
        RemoteResponse getTreeBrowser = LPC_TargetingTreeSelectorController.getTree('Browser', item.id);
        RemoteResponse getTreeOS = LPC_TargetingTreeSelectorController.getTree('OperatingSystem', item.id);
        RemoteResponse getTreeConnection = LPC_TargetingTreeSelectorController.getTree('Connection', item.id);
        RemoteResponse getTreeBandwidth = LPC_TargetingTreeSelectorController.getTree('Bandwidth', item.id);
        RemoteResponse getTreeGeography = LPC_TargetingTreeSelectorController.getTree('Geography', item.id);
        System.assertEquals(getTreeGeography.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(getTreeGeography.content != null);


        RemoteResponse getTreeTempDevice = LPC_TargetingTreeSelectorController.getTreeTemplate('Device', targ.id, oppItem.Id);
        System.assertEquals(getTreeTempDevice.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(getTreeTempDevice.content != null);

        list<object> lstrd = (list<object>)getTreeDevice1.content;
        String lstTobeSaved = JSON.serialize(lstrd[0]);
        RemoteResponse saveTreeDevice = LPC_TargetingTreeSelectorController.doSaveRecords('Device', item.id, lstTobeSaved);

        RemoteResponse saveTreeDeviceTemp = LPC_TargetingTreeSelectorController.doSaveRecordsTempleate('Device', targ.id, lstTobeSaved);

        list<object> lsc = (list<object>)getTreeConnection.content;
        String lstTobeSavedc = JSON.serialize(lsc[0]);
        RemoteResponse saveTreegetTreeConnection = LPC_TargetingTreeSelectorController.doSaveRecords('Connection', item.id, lstTobeSavedc);

        list<object> lstt = (list<object>)getTreeGeography.content;
        String lstTobeSavedt = JSON.serialize(lstt[0]);
        RemoteResponse saveTreeGeography = LPC_TargetingTreeSelectorController.doSaveRecords('Geography', item.id, lstTobeSavedt);
        System.assertEquals(saveTreeGeography.statusCode, RemoteResponse.STATUSCODE_OK);
        System.assert(saveTreeGeography.content != null);

        Map<String, String> mapDevSelectedMode = new Map<String, String>();
        Map<Id, String> lscd = (Map<Id, String>)lsc[1];
        for(Id ds: lscd.keySet()){
            mapDevSelectedMode.put(ds+'', lscd.get(ds));
        }

		//get childnode from Connection
        RemoteResponse getgetChildren = LPC_TargetingTreeSelectorController.getChildren('Connection', conn0.id, 1, mapDevSelectedMode);
        System.assert(getgetChildren.content != null);

        //search tree
        RemoteResponse getdoSearchTree =  LPC_TargetingTreeSelectorController.doSearchTree('Connection','Test1', item.id);
        System.assert(getdoSearchTree.content != null);

        Test.stopTest();
    }
}