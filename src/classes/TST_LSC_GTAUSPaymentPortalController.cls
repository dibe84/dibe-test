/**
 * Test coverage of LSC_GTAUSPaymentPortalController.cls
 * @author : GAEA-SYS TEAM
 * @created date : 1 July 2017
 * 
 */
@isTest private class TST_LSC_GTAUSPaymentPortalController {
	
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
            new DF_Scenario('EBAYK', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'DK',
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
                DF_Scenario.CONF_PRICEBOOK           => '2016',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_USERS               => new List<String> { 'adsalesRep' },
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(1))
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
	        //insert subscriptions;
	
	        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
	        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
	        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
	        insert wss;

        UTIL.isRunningTestSetup = false;
    }

    @isTest static void test_initPage() {

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        acc.Tract_AccountNumber__c = '1791';
        acc.Tract_AccountId__c = '1791';
        update acc;

        Test.startTest();

        System.currentPageReference().getParameters().put('id', acc.Tract_AccountId__c);
        LSC_GTAUSPaymentPortalController lc = new LSC_GTAUSPaymentPortalController();

        Test.stopTest();

        System.debug('### accountJSON :: ' + lc.accountJSON);

        System.assert( String.isNotBlank(lc.accountJSON) && lc.accountJSON.contains(acc.Id), 'There should be a Account which Tract_AccountId__c or Tract_AccountNumber__c = 1791 in SF.' );

    }

    @isTest static void test_getInvoices() {
        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
		
		String getinvoicesResult;
        Test.startTest();
	        acc.Tract_AccountNumber__c = '1234';
	        getinvoicesResult = LSC_GTAUSPaymentPortalController.getInvoices(JSON.serialize(acc)); 
        Test.stopTest();

        LSC_GTAUSPaymentPortalController.ResponseResult results = (LSC_GTAUSPaymentPortalController.ResponseResult) JSON.deserialize(getinvoicesResult, LSC_GTAUSPaymentPortalController.ResponseResult.class);

        List<LSC_GTAUSPaymentPortalController.Invoice> invoices = (List<LSC_GTAUSPaymentPortalController.Invoice>) JSON.deserialize(results.result, List<LSC_GTAUSPaymentPortalController.Invoice>.class);
        System.debug('#### invoices :: ' + invoices);
        system.assertEquals(results.status, 'success');
        system.assert(invoices.size() > 0);
    }

    @isTest static void test_getBillingAccount_success () {

        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        
        String respResult;

        Test.startTest();

            acc.Tract_AccountNumber__c = '1791';
            acc.Tract_AccountId__c = '1791';
            respResult = LSC_GTAUSPaymentPortalController.getBillingAccount(JSON.serialize(acc)); 
        
        Test.stopTest();

        Map<String, Object>  results = (Map<String, Object> ) JSON.deserializeUntyped(respResult);
        Map<String, Object> additionResults = (Map<String, Object> ) results.get('additional_result');
        
        
        System.assertEquals('success', results.get('status'), 'It should be successfully get Billing Account Information.');
        System.assertEquals('Bielska 29, Warszaw, Mazowsze, 02-394, POL', results.get('result'), 'The Billing Address should be "Bielska 29, Warszaw, Mazowsze, 02-394, POL".');
        System.assertEquals('Test Account', additionResults.get('organization_name'), 'The Billing Account Name should be "Test Account".');
        
    }

    @isTest static void test_getBillingAccount_failed_404 () {

        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        
        String respResult;

        Test.startTest();

            LSC_GTAUSPaymentPortalController lc = new LSC_GTAUSPaymentPortalController();
            acc.Tract_AccountNumber__c = '1791';
            acc.Tract_AccountId__c = '1791';

            UTIL_WSC.testStatusCode = 404;
            
            respResult = LSC_GTAUSPaymentPortalController.getBillingAccount(JSON.serialize(acc)); 
        
        Test.stopTest();

        Map<String, Object>  results = (Map<String, Object> ) JSON.deserializeUntyped(respResult);
        Map<String, Object> additionResults = (Map<String, Object> ) results.get('additional_result');
        
        
        System.assertEquals('error', results.get('status'), 'It should be failed to get Billing Account Information.');
        
        
    }

    @isTest static void test_getBillingAccount_failed () {

        UTIL_WSC.TESTMOCK = 'callCreateValid';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        
        String respResult;

        Test.startTest();

            //Test error 404
            acc.Tract_AccountNumber__c = '1791';
            acc.Tract_AccountId__c = '1791';

            UTIL_WSC.testStatusCode = 400;
            
            respResult = LSC_GTAUSPaymentPortalController.getBillingAccount(JSON.serialize(acc)); 

            Map<String, Object>  results = (Map<String, Object> ) JSON.deserializeUntyped(respResult);
            System.assertEquals('error', results.get('status'), 'It should be failed to get Billing Account Information.');

            //Test error when Tract_AccountNumber__c is blank
            acc.Tract_AccountNumber__c = null;
            acc.Tract_AccountId__c = null;

            respResult = LSC_GTAUSPaymentPortalController.getBillingAccount(JSON.serialize(acc)); 

            results = (Map<String, Object> ) JSON.deserializeUntyped(respResult);
            System.assertEquals('error', results.get('status'), 'It should be failed to get Billing Account Information.');
        
        Test.stopTest();

        
        
        
    }

    @isTest static void test_createRecurringPaymentMethod_success () {

        String jsonPaymentDetail = '{"verification_number":"123","payment_method":"credit-card","payment_currency":"ZAR","last_name":"test","identifier_number":"4111111111111111","first_name":"test","expiration_date":"2/2018","card_type":"VISA"}';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        acc.Tract_AccountNumber__c = '1791';
        acc.Tract_AccountId__c = '1791';
        update acc;

        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;

        RemoteResponse respResult;

        Test.startTest();

            UTIL_WSC.testStatusCode = 201;
            respResult = LSC_GTAUSPaymentPortalController.createRecurringPaymentMethod(acc.Id, jsonPaymentDetail); 
        
        Test.stopTest();

        System.debug('#### respResult :: ' + respResult);

        System.assertEquals(RemoteResponse.STATUSCODE_OK, respResult.statusCode, 'Payment method should created successfully with Status Code = 0.');
        System.assertEquals('Payment method is created.', respResult.message, 'Payment method should created successfully with Message = "Payment method is created.".');

        
    }

    @isTest static void test_createRecurringPaymentMethod_failed_account_not_ready () {

        String jsonPaymentDetail = '{"verification_number":"123","payment_method":"credit-card","payment_currency":"ZAR","last_name":"test","identifier_number":"4111111111111111","first_name":"test","expiration_date":"2/2018","card_type":"VISA"}';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        
        RemoteResponse respResult;

        Test.startTest();

            respResult = LSC_GTAUSPaymentPortalController.createRecurringPaymentMethod(acc.Id, jsonPaymentDetail); 
        
        Test.stopTest();

        System.debug('#### respResult :: ' + respResult);

        System.assertEquals(RemoteResponse.STATUSCODE_ERROR, respResult.statusCode, 'Payment method should failed to create with Status Code = 1.');
        System.assertEquals('Account is not ready.', respResult.message, 'Payment method should failed to create with Message = "Account is not ready.".');

    }

    @isTest static void test_createRecurringPaymentMethod_failed () {

        String jsonPaymentDetail = '{"verification_number":"123","payment_method":"credit-card","payment_currency":"ZAR","last_name":"test","identifier_number":"4111111111111111","first_name":"test","expiration_date":"2/2018","card_type":"VISA"}';

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        acc.Tract_AccountNumber__c = '1791';
        acc.Tract_AccountId__c = '1791';
        update acc;

        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;
        
        RemoteResponse respResult;

        Test.startTest();

            UTIL_WSC.testStatusCode = 404;
            respResult = LSC_GTAUSPaymentPortalController.createRecurringPaymentMethod(acc.Id, jsonPaymentDetail); 
        
        Test.stopTest();

        System.debug('#### respResult :: ' + respResult);

        System.assertEquals(RemoteResponse.STATUSCODE_ERROR, respResult.statusCode, 'Payment method should failed to create with Status Code = 1.');
        System.assertEquals('failed to create payment method.', respResult.message, 'Payment method should failed to create with Message = "failed to create payment method.".');

    }

    @isTest static void test_doFetchInvoicePDFFromTract_success() {

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        
        String respResult;

        Test.startTest();

            respResult = LSC_GTAUSPaymentPortalController.doFetchInvoicePDFFromTract('1344', acc.Id); 

        Test.stopTest();

        System.debug('#### respResult :: ' + respResult);
        Map<String, Object> results = (Map<String,Object>) JSON.deserializeUntyped(respResult);

        String url = String.valueOf(results.get('result'));
        List<Document> docs = [SELECT Id FROM Document WHERE DeveloperName = 'TEST_INVOICE'];
        System.debug('#### docs :: ' + docs);

        System.assertEquals('success', results.get('status'), 'PDF should retrieved successfully.');
        System.assert( !docs.isEmpty() && url.contains(docs.get(0).Id) , 'There should be valid SF Attachment ID for download link.');
    }

    @isTest static void test_doFetchInvoicePDFFromTract_fail () {

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        Account acc = result.accounts.values().get(0);

        String respResult;

        Test.startTest();
            
            //Test error 404
            UTIL_WSC.testStatusCode = 404;
            respResult = LSC_GTAUSPaymentPortalController.doFetchInvoicePDFFromTract('1344', acc.Id); 
            System.debug('#### respResult :: ' + respResult);
            Map<String, Object> results = (Map<String,Object>) JSON.deserializeUntyped(respResult);
            String url = String.valueOf(results.get('result'));

            System.assertEquals('error', results.get('status'), 'PDF should failed to retrieved.');
            System.assert( url.contains('Invoice document not found! Refresh the page and try again.') , 'There should be error message of "Invoice document not found! Refresh the page and try again.".');

            //Test blank invoice
            respResult = LSC_GTAUSPaymentPortalController.doFetchInvoicePDFFromTract('', acc.Id); 
            System.debug('#### respResult :: ' + respResult);
            results = (Map<String,Object>) JSON.deserializeUntyped(respResult);
            url = String.valueOf(results.get('result'));

            System.assertEquals('error', results.get('status'), 'PDF should failed to retrieved.');
            System.assert( url.contains('Cannot fetch Invoice PDF from this Invoice. Please contact System Administrator.') , 'There should be error message of "Cannot fetch Invoice PDF from this Invoice. Please contact System Administrator.".');
        
        Test.stopTest();

    }

    @isTest static void test_initPaymentMethodForm () {

        List<String> respResult;

        Test.startTest();
            
            //Get Expire MM
            respResult = LSC_GTAUSPaymentPortalController.getExpiredMM();
            System.assert( !respResult.isEmpty() && respResult.size() >= 12, 'Expired MM picklist should contain all Months.');

            //Get Expire YY
            respResult = LSC_GTAUSPaymentPortalController.getExpiredYY();
            System.assert( !respResult.isEmpty() && respResult.size() >= 10, 'Expired YY picklist should contain from current year to the next 10 years.');

            //Get init card
            LSC_GTAUSPaymentPortalController.Card card = LSC_GTAUSPaymentPortalController.getInitCard();
            System.debug('#### card :: ' + card);
            System.assert( card != null, 'There should be a valid card created.');

        Test.stopTest();

    }

    @isTest static void test_createPaymentMethod_fail() {
        String respResult;

        Test.startTest();
			String jsoncard = '{"account_id":"0010k000008kWEiAAM","card_number":"4111111111111111","card_type":"visa","expires_mm":"2","expires_yy":"2018","name_on_card":"xxx test","payment_currency":"ZAR","payment_type":"credit-card","security_code":"123"}';
            respResult = LSC_GTAUSPaymentPortalController.createPaymentMethod(jsoncard); 
        Test.stopTest();
        
        Map<String,Object> mresults = (Map<String,Object>) JSON.deserializeUntyped(respResult);
        system.assertEquals(mresults.get('status'), 'error', 'Billing Account Id is incorrect.');
    }
    
    @isTest static void test_createPaymentMethod_success() {
		 DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        acc.Tract_AccountNumber__c = '1791';
        acc.Tract_AccountId__c = '1791';
        update acc;

        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        memberUnit.EnableTRACT__c = TRUE;
        update memberUnit;

        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c(Account__c = acc.Id, MemberUnit__c = memberUnit.Id);
        insert amua;

        
        String respResult;

        Test.startTest();
        	UTIL_WSC.testStatusCode = 201;
			String jsoncard = '{"account_id":"'+acc.Id+'","card_number":"4111111111111111","card_type":"visa","expires_mm":"2","expires_yy":"2018","name_on_card":"xxx test","payment_currency":"ZAR","payment_type":"credit-card","security_code":"123"}';
            respResult = LSC_GTAUSPaymentPortalController.createPaymentMethod(jsoncard); 
        Test.stopTest();
        
        Map<String,Object> mresults = (Map<String,Object>) JSON.deserializeUntyped(respResult);
        system.assertEquals(mresults.get('status'), 'success');
    }

}