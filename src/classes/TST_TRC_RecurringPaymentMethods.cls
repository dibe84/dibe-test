@isTest
private class TST_TRC_RecurringPaymentMethods {
    
    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        wss.add(new Webservice_Settings__c(Name = WSC_Tract.APINAME + '_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        wss.add(new Webservice_Settings__c(Name = WSC_Tract.APINAME + '_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        insert wss;
            
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    
    static testMethod void test_Retrieve() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        System.runAs ( fac.testUser ) {
            
            RemoteResponse rRes = TRC_RecurringPaymentMethodsController.getRecurringPaymentByBillingAccount(fac.acc.id);
            System.assertEquals('Account is not ready', rRes.message); // no Tract_AccountId__c
            
            fac.acc.Tract_AccountId__c = '123456';
            update fac.acc;
            rRes = TRC_RecurringPaymentMethodsController.getRecurringPaymentByBillingAccount(fac.acc.id);
            System.assertEquals(RemoteResponse.STATUSCODE_OK, rRes.statusCode);
        }
        
    }
    
    static testMethod void test_createrecurringpayment_success() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
            System.runAs ( fac.testUser ) {
            fac.acc.Tract_AccountId__c = '123456';
            fac.acc.BillingCountry = 'Germany';
            update fac.acc;
            UTIL_WSC.testStatusCode = 201;
            RemoteResponse rRes = TRC_RecurringPaymentMethodsController.createRecurringPayment(fac.acc.id, '{"identifier_number":"4111111111111111","card_type":"VISA","expiration_month":"1","expiration_year":"3000","last_name":"test","payment_method_type":"credit-card","verification_number":"123","currency":"EUR"}');
            System.assertEquals(RemoteResponse.STATUSCODE_OK, rRes.statusCode);

            echosign_dev1__SIGN_Agreement__c agm = new echosign_dev1__SIGN_Agreement__c( echosign_dev1__Status__c = 'Signed' , echosign_dev1__Account__c = fac.acc.id );
            insert agm;
            
            rRes = TRC_RecurringPaymentMethodsController.createRecurringPayment(fac.acc.id, '{"payment_method_type":"sepa-dd-em","iban":"DE36444488881234567890","mandate_id":"4111111111111111","mandate_signature_date":"12/2020","owner_name":"testUser","bic":null,"mandateId":"' + agm.id + '"}');
            System.debug( rRes );
            System.assertEquals(RemoteResponse.STATUSCODE_OK, rRes.statusCode);
            
            // Test error:
            rRes = TRC_RecurringPaymentMethodsController.createRecurringPayment(fac.acc.id, '{"identifier_number":"4111111111111111","card_type":"VISA"}'); // missing required fields
            System.assertNotEquals(RemoteResponse.STATUSCODE_OK, rRes.statusCode);
        }
        
        Test.stopTest();
    }
    
    static testMethod void test_createrecurringpayment_fail() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        	System.runAs ( fac.testUser ) {
            fac.acc.Tract_AccountId__c = '123456';
            update fac.acc;
            
            UTIL_WSC.testStatusCode = 404;
            RemoteResponse rRes = TRC_RecurringPaymentMethodsController.createRecurringPayment(fac.acc.id, '{"identifier_number":"4111111111111111","card_type":"VISA","expiration_month":"1","expiration_year":"3000","last_name":"test","payment_method_type":"credit-card","verification_number":"123","currency":"EUR"}');
            System.assertEquals(RemoteResponse.STATUSCODE_ERROR, rRes.statusCode, 'Status code is 1 --> Error with callout.');
            System.assertEquals(rRes.message, 'failed to create payment method.', 'Response with Status code 404 --> No payment method is created.');
        }
        
        Test.stopTest();
    }
    
    static testMethod void test_isUserHasEncryptedData() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        	System.runAs ( fac.testUser ) {
            TRC_RecurringPaymentMethodsController cont = new TRC_RecurringPaymentMethodsController(new ApexPages.StandardController(fac.acc));
            System.assert(!cont.isUserHasEncryptedData, 'Currnent user does not have View Restrict Data permission.');
        }
        
        Test.stopTest();
    }
    
    static testMethod void test_Delete() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        System.runAs ( fac.testUser ) {
            RemoteResponse rRes = TRC_RecurringPaymentMethodsController.deleteRecurringPayment(fac.acc.id, null);
            System.assertEquals('Delete Error: No delete API found!', rRes.message);
        }
        
    }

    static testMethod void test_getAreementById() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        System.runAs ( fac.testUser ) {
            RemoteResponse rRes = TRC_RecurringPaymentMethodsController.getAreementById(null);
            System.assertEquals(RemoteResponse.STATUSCODE_ERROR, rRes.statusCode);
        }
        
    }

    static testMethod void test_CheckIban() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        System.runAs ( fac.testUser ) {
            RemoteResponse rRes = TRC_RecurringPaymentMethodsController.doCheckExistIBan('DE36444488881234567890');
            System.assertEquals(RemoteResponse.STATUSCODE_OK, rRes.statusCode);

            rRes = TRC_RecurringPaymentMethodsController.doCheckExistIBan('retyerty');
            System.assertEquals(RemoteResponse.STATUSCODE_ERROR, rRes.statusCode);
        }
        
    }
}