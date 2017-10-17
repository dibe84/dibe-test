@isTest
private class TST_WSC_API_SFECG_v1 extends TSTDF_Base {

    public TST_WSC_API_SFECG_v1(TSTDF_Dataset dataset) {
        super(dataset);
    }

    public static TST_WSC_API_SFECG_v1 factory = new TST_WSC_API_SFECG_v1(new TSTDF_Dataset());

    public class TSTDF_Dataset extends TSTDF_BaseDataSet {
        public override List<Webservice_Settings__c> constructWebserviceSettings(List<Webservice_Settings__c> wss){
            wss = new List<Webservice_Settings__c>();
            wss.add(new Webservice_Settings__c(Name = COUNTRYROLENAME +'_WSC_API_SFECG_v1_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
            wss.add(new Webservice_Settings__c(Name = COUNTRYROLENAME +'_WSC_API_SFECG_v1_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
            return wss;
        }
    }

    public override void queryAdditionalResults() {
        data.wsLogs = GW_sObject.queryRecords('WS_Log__c', ' Id <> null ORDER BY Id');
        data.wsScheduledCallouts = GW_sObject.queryRecords('WS_ScheduledCallout__c', ' Id <> null ORDER BY Id');
    }

    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }

    @isTest static void checkTestDataSet() {
        factory.queryResults(); // will store results in data set 'data'
        UTIL.Log('checkTestDataSet: ' + factory.data);
        system.assertNotEquals(0, factory.data.accounts.size(), 'Number of Accs should be >1' );
        UTIL.log('Acc: '+factory.data.accounts[0]);
        system.assertNotEquals(0, factory.data.contacts.size(), 'Number of Contacts should be >1' );
        system.assertNotEquals(0, factory.data.pbes.size(), 'Number of Pbe\'s should be >1' );
    }

    @isTest static void checkAccountPushSucces_Direct() {
        UTIL_WSC.TESTMOCK = 'insertSuccess';
        factory.queryResults(); // will store results in data set 'data'

        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;

        Test.startTest();
        GW_Invoice.processBatch('THBELAU');
        factory.queryResults();
        UTIL.log('STARTING: checkAccountPushSucces_Direct');
        System.runAs ( factory.data.testUsers.get( 'testUser') ) {
            UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(New Set<Id>{factory.data.accounts[0].Id});
            req = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v1.AccountPush');  // instantiate request object
            UTIL.Log('Req: ' + req);
            req.init( factory.data.accounts[0].Id );                            // init with context record
            res = req.call();                                               // try call and get result
            UTIL.Log('Res: ' + res);
            UTIL.Log('BulkHandler: ' + UTIL_WSC.bulkHandler);
            UTIL_WSC.bulkHandler.commitAll();
        }
        Test.stopTest();

        factory.queryResults();
        UTIL.logClean('Data: ' + factory.data.members);
        UTIL.logClean('Account: ' + factory.data.accounts);
        UTIL.logClean('Res: ' + res.getResponseData());
        system.assertEquals( 1, factory.data.wsLogs.size(), 'Number of WS_Logs should be 1' );
        system.assertEquals(    factory.data.accounts[0].UniquePlatformId__c ,
                                factory.data.accounts[0].MemberId__c +'_'+res.getResponseData().get('localId') ,
                                'Platform LocalId should be stored on the Account Record'
                           );
    }

    @isTest static void checkAccountPushSuccess_ScheduledCallout() {
        factory.queryResults(); // retrieve data Set
        UTIL_WSC.TESTMOCK = 'insertSuccess';

        Test.startTest();
        UTIL.log('STARTING: checkAccountPushSuccess_ScheduledCallout');
        System.runAs ( factory.data.testUsers.get( 'testUser') ) {
            Account acc = factory.data.accounts[0];
            acc.Name = acc.Name +'_changed';
            acc.BillingCity = acc.BillingCity + '_changed';
            update acc;
        }

        factory.queryResults();
        // Scheduled callout record should have been created
        //system.assertEquals( 1, factory.data.wsScheduledCallouts.size(), 'Number of Scheduled Callouts should be 1' );

        System.runAs ( factory.data.testUsers.get( 'adminUser') ) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();

        //factory.queryResults();
        //system.assertEquals( 1, factory.data.wsLogs.size(), 'Number of WS_Logs should be 1' );
        //system.assertNotEquals( factory.data.accounts[0].UniquePlatformId__c, null,   'Platform LocalId should be stored on the Account Record');
    }

    @isTest static void checkCalloutPrioritization() {
        UTIL_Log.start();
        factory.queryResults(); // retrieve data Set
        UTIL_WSC.TESTMOCK = 'insertSuccess';
        Test.startTest();
        List<Account> newAccList = new List<Account>();
        for(Integer i = 0; i < 4; i++) {
            Account acc = new Account(Name='Test Account' + i, Member__c = factory.data.accounts[0].Member__c);
            acc.AccountExtId__c = factory.data.accounts[0].Member_Id__c +  factory.data.accounts[0].AccAutoNumber__c + i;
            newAccList.add(acc);
        }
        upsert newAccList;
        factory.queryResults();
        // Scheduled callout record should have been created
        //System.assertEquals(5,factory.data.wsScheduledCallouts.size(),'Number of account Callouts should be 5');
        List<WS_ScheduledCallout__c> bookingWsscList = new List<WS_ScheduledCallout__c>();
        // Clone existing WSSC into booking ones
        for(WS_ScheduledCallout__c wssc : factory.data.wsScheduledCallouts) {
            WS_ScheduledCallout__c bookingWssc = new WS_ScheduledCallout__c();
            bookingWssc = wssc.clone(false,false);
            bookingWssc.Method__c = 'BookingPush';
            bookingWssc.UniqueKey__c = bookingWssc.UniqueKey__c.replace('AccountPush','BookingPush');
            bookingWssc.RecordId__c = 'a0dp00000028tZE';
            bookingWsscList.add(bookingWssc);
        }
        insert bookingWsscList;
        //System.assertEquals(5,bookingWsscList.size(),'Number of booking Callouts should be 5');
        Test.stopTest();

        List<WS_ScheduledCallout__c> allWsscList = GW_sObject.queryRecords('WS_ScheduledCallout__c', ' Id <> null ORDER BY Id');

        // Sort for no configuration settings and no prio fields
        UTIL_WSC.sortAccordingToPriority(allWsscList);
        // Sort by booking - rev items
        UTIL.upsertConfig('WSSCObjectPriority','Rev__c;Account');
        allWsscList = UTIL_WSC.sortAccordingToPriority(allWsscList);
        Integer i = 0;
        for(WS_ScheduledCallout__c wssc : allWsscList) {
            if(i < 5) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:BookingPush'),TRUE);
            } else {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:AccountPush'),TRUE);
            }
            i++;
        }
        // Reverse, accs then bookings
        UTIL.upsertConfig('WSSCObjectPriority','Account;Rev__c');
        allWsscList = UTIL_WSC.sortAccordingToPriority(allWsscList);
        i = 0;
        for(WS_ScheduledCallout__c wssc : allWsscList) {
            if(i < 5) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:AccountPush'),TRUE);
            } else {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:BookingPush'),TRUE);
            }
            i++;
        }
        // for(WS_ScheduledCallout__c wssc : allWsscList) { UTIL_Log.d('XX wssc after sort Acc->Rev: ',wssc.UniqueKey__c); }
        // Add priority field
        i = 0;
        for(WS_ScheduledCallout__c wssc : allWsscList) {
            if(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:AccountPush')  && i < 2) {
                wssc.Prioritized__c = TRUE;
                i++;
            }
            if(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:BookingPush')  && i < 4) {
                wssc.Prioritized__c = TRUE;
                i++;
            }
        }
        allWsscList = UTIL_WSC.sortAccordingToPriority(allWsscList);
        i = 0;
        for(WS_ScheduledCallout__c wssc : allWsscList) {
            if(i < 2) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:AccountPush'),TRUE);
                System.assertEquals(wssc.Prioritized__c,TRUE);
            }
            if(i > 1 && i < 4) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:BookingPush'),TRUE);
                System.assertEquals(wssc.Prioritized__c,TRUE);
            }
            if(i > 3 && i < 7) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:AccountPush'),TRUE);
                System.assertEquals(wssc.Prioritized__c,FALSE);
            }
            if(i > 6 && i < 10) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:BookingPush'),TRUE);
                System.assertEquals(wssc.Prioritized__c,FALSE);
            }
            i++;
        }
        // Reverse object prio
        UTIL.upsertConfig('WSSCObjectPriority','Rev__c;Account');
        allWsscList = UTIL_WSC.sortAccordingToPriority(allWsscList);
        i = 0;
        for(WS_ScheduledCallout__c wssc : allWsscList) {
            if(i < 2) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:BookingPush'),TRUE);
                System.assertEquals(wssc.Prioritized__c,TRUE);
            }
            if(i > 1 && i < 4) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:AccountPush'),TRUE);
                System.assertEquals(wssc.Prioritized__c,TRUE);
            }
            if(i > 3 && i < 7) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:BookingPush'),TRUE);
                System.assertEquals(wssc.Prioritized__c,FALSE);
            }
            if(i > 6 && i < 10) {
                System.assertEquals(wssc.UniqueKey__c.contains('WSC_API_SFECG_v1:AccountPush'),TRUE);
                System.assertEquals(wssc.Prioritized__c,FALSE);
            }
            i++;
        }
        UTIL_Log.end();
    }

    @isTest static void checkAccountPushDeleted_ScheduledCallout() {
        factory.queryResults();
        UTIL_WSC.TESTMOCK = 'insertSuccess';
        Id accountId;

        Test.startTest();
        UTIL.log('STARTING: checkAccountPushDeleted_ScheduledCallout');
        System.runAs(factory.data.testUsers.get('testUser')) {
            Account acc = factory.data.accounts[0];
            acc.Name = acc.Name +'_changed';
            acc.BillingCity = acc.BillingCity + '_changed';
            accountId = acc.Id;
            update acc;
        }


        delete factory.data.accounts[0];
        UTIL.unCache(new Set<Id>{accountId});

        factory.queryResults();
        // Scheduled callout record should have been created
        //system.assertNotEquals(0, factory.data.wsScheduledCallouts.size(), 'Number of Scheduled Callouts should be > 1' );

        System.runAs(factory.data.testUsers.get('adminUser')) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();

        factory.queryResults();
        system.assertEquals(0, factory.data.wsScheduledCallouts.size(), 'Number of WS_ScheduledCallouts should be 0' );
    }

    @isTest static void checkAccountPush_TestCustomAttributeLookup() {
        UTIL_WSC.TESTMOCK = 'insertSuccess';
        factory.queryResults(); // will store results in data set 'data'
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;

		Account mainAcc;
		System.runAs (factory.data.testUsers.get( 'adminUser')) {
			Test.startTest();
				prepareCADsForCallout();
				mainAcc = [SELECT Id FROM Account WHERE Name = 'mainAccount'];
				mainAcc = GW_Account.getRecord(mainAcc.Id);
				UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(New Set<Id>{mainAcc.Id});
				req = UTIL_WSC.getWSC_Request('WSC_API_SFECG_v1.AccountPush');  // instantiate request object
				UTIL.logClean('Req: '+req);
				req.init(mainAcc.Id);
				res = req.call();                           // try call and get result
				UTIL.logClean('Res: '+res);
				UTIL_WSC.bulkHandler.commitAll();
            Test.stopTest();
        }
        factory.queryResults();
        factory.queryAdditionalResults();
        mainAcc = GW_Account.getRecord(mainAcc.Id);
        system.assertEquals(1, factory.data.wsLogs.size(), 'Number of WS_Logs should be 1' );
        system.assertEquals(mainAcc.UniquePlatformId__c ,
                            mainAcc.MemberId__c +'_'+res.getResponseData().get('localId'),
                            'Platform LocalId should be stored on the Account Record'
                           );
        // Take response body JSON
        Map<String,Object> requestJsonMap = (Map<String,Object>)JSON.deserializeUntyped(factory.data.wsLogs[0].Request__c);
        // Validate some fields from cardinal account
        System.assertEquals('Active',String.valueOf(requestJsonMap.get('status')));
        System.assertEquals('mainAccount',String.valueOf(requestJsonMap.get('accountName')));
        // Validate if CA were included in request
        System.assertNotEquals(NULL,requestJsonMap.get('customAttributes'));
        Map<String,Object> caMap = (Map<String,Object>)((List<Object>)requestJsonMap.get('customAttributes'))[0];
        // Validate CA content
        String caKey = String.valueOf(caMap.get('key'));
        System.assertEquals('linkedAccount',caKey);
        Map<String,Object> caValueMap = (Map<String,Object>) caMap.get('value');
        // Validate if related account contains proper values
        System.assertEquals('referencedAccount',String.valueOf(caValueMap.get('accountName')));
        //System.assertEquals('Active',String.valueOf(caValueMap.get('status')));
        System.assertEquals(TRUE,String.valueOf(caValueMap.get('accountExtId')).length() > 0);
        System.assertEquals(TRUE,caValueMap.containsKey('localId'));
        UTIL_Log.end();
    }

    private static void prepareCADsForCallout() {
        Account mainAcc = new Account();
        mainAcc.AccountExtId__c     = 'GTTEST01234';
        mainAcc.Account_Status__c   = 'Status';
        mainAcc.BillingStreet       = 'Street';
        mainAcc.BillingPostalCode   = '12345';
        mainAcc.BillingCity         = 'Anothercity';
        mainAcc.BillingCountryCode  = 'NL';
        mainAcc.BillingCountry = 'Netherlands';
        mainAcc.Account_Status__c   = 'Active';
        mainAcc.Billing_Preference__c = 'Invoice';
        mainAcc.FQ_CmrType__c = 'Banners';
        mainAcc.Bank_AccountNumber__c = 'BE23776592232991';
        mainAcc.Bank_Name__c = 'BELFIUS BANK';
        mainAcc.BillingPreferenceValidFrom__c = Date.today(); //date
        mainAcc.MandateId__c = 'THBEL0000000585-00000001';
        mainAcc.Name = 'mainAccount';
        mainAcc.Member__c = factory.data.members.values()[0].Id;
        insert mainAcc;
        Account newTestAcc = new Account(Name='referencedAccount',Member__c=factory.data.members.values()[0].Id);
        insert newTestAcc;
        TST_DataFactory.createCustomAttributeDefinitionRelation(factory.data.memberunits[0].Id,'Account','Account');
        List<CustomAttributeDefinition__c> testCADList = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c];
        TST_DataFactory.createAccountMemberUnitAssociation(factory.data.memberunits[0].Id,mainAcc.Id);
        TST_DataFactory.createCustomAttributeForAccount(testCADList.get(0),'linkedAccount',mainAcc.Id);
        List<CustomAttribute__c> testCAList = [SELECT Id, Name, Account__c, ParentId__c, Lead__c, ValueType__c FROM CustomAttribute__c];
        CustomAttribute__c caToUpdate = testCAList.get(0);
        caToUpdate.RelationshipId__c = newTestAcc.Id;
        caToUpdate.RelationshipName__c = newTestAcc.Name;
        update caToUpdate;
        update mainAcc;
        update newTestAcc;
    }
}
