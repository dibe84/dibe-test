@isTest
public class TST_WSC_Tract {

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    public static DF factory;

    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'GTAUSAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('THBELAU-1', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECG',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AU',
                DF_Scenario.CONF_USERS               => new List<String> { 'adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
                            new Product2(
                                Name = 'Motor Listings 12 Months',
                                ProductCode = 'BEC_12',
                                Billing_Category__c = 'Subscription_MonthlyProRata',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = 12,
                                BillingScheme__c = 'Monthly in Arrears'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = 'FixedTiered',
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Tiered_TierCorrection__c = 0.00,
                                ListOrder__c = 5,
                                FixedTiered_JSON__c = '{"1":3,"10":29,"15":41,"20":54,"30":80,"40":106,"60":131,"100":183,"200":234,"999":284}',
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 0.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                }
            })
        };
    }

    @testSetup static void setup(){
        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        List<WSC_Subscription__c> subscriptions = new List<WSC_Subscription__c> {
            new WSC_Subscription__c(
                Name = 'TRACT',
                ConsumerId__c = '=',
                Class__c = 'WSC_Tract',
                Method__c = '-',
                IsActive__c = TRUE
            )
        };
        insert subscriptions;

        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        insert wss;

        UTIL.isRunningTestSetup = false;
    }

    // Test update, create, invalid call

    @isTest static void testBillingAccount_MemberUnitEnableTract_ENABLED(){
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        Test.startTest();
        acc.BillingPostalCode = '101505';
        update acc;

        List<WS_ScheduledCallout__c> wsscList = [SELECT Id, Method__c, RecordId__c FROM WS_ScheduledCallout__c];
        WS_ScheduledCallout__c myWssc;
        for(WS_ScheduledCallout__c wssc : wsscList) {
            if(wssc.Method__c == 'BillingAccountCreate') {
                myWssc = wssc;
            }
        }

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('BillingAccountCreate', myWssc.Method__c);
        //System.assertEquals(acc.Id, myWssc.RecordId__c);
        Test.stopTest();
    }

    @isTest static void testBillingAccount_MemberUnitEnableTract_DISABLED(){
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = FALSE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;

        Test.startTest();
        acc.BillingPostalCode = '101505';
        update acc;

        List<WS_ScheduledCallout__c> wsscList = [SELECT Id, Method__c, RecordId__c FROM WS_ScheduledCallout__c];
        WS_ScheduledCallout__c myWssc;
        for(WS_ScheduledCallout__c wssc : wsscList) {
            if(wssc.Method__c == 'BillingAccountCreate') {
                myWssc = wssc;
            }
        }
        // Nothing created - member unit checkbox disabled
        System.assertEquals(null,myWssc);
        Test.stopTest();
    }

    @isTest static void testBillingAccount_TRACT_SubscriptionDisabled(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        WSC_Subscription__c tractWS = [SELECT Id, Name, IsActive__c FROM WSC_Subscription__c WHERE Name = 'TRACT'].get(0);
        tractWS.isActive__c = FALSE;
        update tractWS;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;

        Test.startTest();
        // Trigger WSSC creation
        acc.BillingPostalCode = '101505';
        update acc;


        List<WS_ScheduledCallout__c> wsscList = [SELECT Id, Method__c, RecordId__c FROM WS_ScheduledCallout__c];
        WS_ScheduledCallout__c myWssc;
        for(WS_ScheduledCallout__c wssc : wsscList) {
            if(wssc.Method__c == 'BillingAccountCreate') {
                myWssc = wssc;
            }
        }

        // Nothing created - tract WS subscription disabled
        System.assertEquals(null,myWssc);
        Test.stopTest();
    }

    

    @isTest static void testBillingAccountCreate(){
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        
        Account checkedAcc = GW_Account.getRecord(acc.Id);
        
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;

        Test.startTest();
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        acc.BillingPostalCode = '101505';
        update acc;

        //WS_ScheduledCallout__c myWssc = [SELECT Id, Method__c, RecordId__c FROM WS_ScheduledCallout__c WHERE Method__c = 'BillingAccountCreate' AND RecordId__c = :acc.Id];

        //System.assertNotEquals(NULL,myWssc);
        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('BillingAccountCreate', myWssc.Method__c);
        //System.assertEquals(acc.Id, myWssc.RecordId__c);
        Test.stopTest();
    }

    @isTest static void testBillingAccountCreateCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;

        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;

        Test.startTest();
        WSC_Tract.createAccountSync(acc.Id);
        //req = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountCreate');
        //req.init(acc.Id);
        //res = req.call();
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
    }
    
    @isTest static void testSentPaymentToTractCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];
        //result.oppMap.get('THBELAU-1.Opportunity[1]');
        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        //WSC_Tract.createAccountSync(opp.Id);
        req = UTIL_WSC.getWSC_Request('WSC_Tract.SentPaymentToTract');
        req.init(opp.Id);
        res = req.call();
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
    }
    
    @isTest static void testGetServiceIdfromTractCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        Opportunity opp = result.oppMap.get('THBELAU-1.Opportunity[1]');
        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        WSC_Tract.getOppFromTractServiceId(acc.Id,'1232');
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
    }
    
    @isTest static void testBillingAccountUpdateCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];
        //result.oppMap.get('THBELAU-1.Opportunity[1]');
        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        //WSC_Tract.createAccountSync(opp.Id);
        req = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountUpdate');
        req.init(acc.Id);
        res = req.call();
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
        //
        //
        //

    }
    
    @isTest static void testCalloutSelfServiceCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];

        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        WSC_Tract.checkForOrderTractProcessingselfService(opp.Id);
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
    }
    
    @isTest static void testgetAgreementCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];

        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        WSC_Tract.getTractAgreementId(opp.Id);
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
    }
    
    @isTest static void testupdateagreemCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];
        //result.oppMap.get('THBELAU-1.Opportunity[1]');
        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        //WSC_Tract.createAccountSync(opp.Id);
        req = UTIL_WSC.getWSC_Request('WSC_Tract.UpdateAgreementDetailsTract');
        req.init(opp.Id);
        res = req.call();
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
        //
        //
        //

    }
    
    @isTest static void testgetServiceAccountFromTractCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];

        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        WSC_Tract.getServiceAccountFromTract(acc.Id);
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
    }
    @isTest static void testdeactivateCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];
        //result.oppMap.get('THBELAU-1.Opportunity[1]');
        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        //WSC_Tract.createAccountSync(opp.Id);
        req = UTIL_WSC.getWSC_Request('WSC_Tract.DeactivateServiceTract');
		req.mAdditionalParams.put('endDate', '2017-07-28');
        req.init(opp.Id);
        res = req.call();
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
        //
        //
        //

    }
    
    @isTest static void testdeletePreviousDraftTractCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];

        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        WSC_Tract.deletePrevDraftOrder(opp.Id,'1232132');
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
    }
    
    @isTest static void billingAccountUpdateCalloutMock(){
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        
        update memberUnit;
    
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        DF_Scenario.Result result2 = DF.queryResults(scenarios, scenarioUsers);
        
        
        DF.requeryResults(result2,new Set<String>{'oppMap'});
        
        System.debug('>>>>>>>>result.oppMap ' + result.oppMap);
        Opportunity opp = result2.oppMap.values()[0];
        //result.oppMap.get('THBELAU-1.Opportunity[1]');
        
        UTIL_WSC.WSC_Request req;
        UTIL_WSC.WSC_Result res;
        
        Test.startTest();
        //WSC_Tract.createAccountSync(opp.Id);
        req = UTIL_WSC.getWSC_Request('WSC_Tract.BillingAccountUpdate');
        req.init(acc.Id);
        res = req.call();
        Test.stopTest();

        //Account retrievedAcc = GW_Account.getRecord(acc.Id);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountId__c);
        //System.assertEquals('1337',retrievedAcc.Tract_AccountNumber__c);
        //System.assertEquals('1337',retrievedAcc.Tract_ResponsiblePartyId__c);
        //
        //
        //

    }
    
  
    
}