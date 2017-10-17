@isTest
public class TST_AccountValidationAndEnrichment {
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
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            })
        };
    }

    @testSetup static void setup(){
        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
        Account acc = dfResult.accounts.values().get(0);
        
        echosign_dev1__SIGN_Data_Mapping__c testDataMapping = new echosign_dev1__SIGN_Data_Mapping__c(Name='Mandate_IO');
    		insert testDataMapping;
    	
    		echosign_dev1__SIGN_Agreement__c testAgreement = new echosign_dev1__SIGN_Agreement__c(name = 'Sample Test',
                                                                                                echosign_dev1__Status__c = 'Draft',
    																							echosign_dev1__Account__c = acc.id,
    																							echosign_dev1__Process_Template__c = testDataMapping.id);
        insert testAgreement;
        
        acc.Mandate__c = testAgreement.Id;
        update acc;
        
        UTIL.isRunningTestSetup = false;
    }

    @isTest static void testValidationAndEnrichment() {
		// retrieve test data
        DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
    		Account acc = dfResult.accounts.values().get(0);

        Test.startTest();
        System.runAs ( dfResult.users.get('adsalesRep') ) {
            //Set BillingCountry to 'Netherlands' and BillingCountryCode to 'NL'
            acc.BillingCountry = 'Netherlands';
            acc.BillingCountryCode = 'NL';
            update acc;

            //Simulate AccountValidationAndEnrichment VF use.
            PageReference pageRef = Page.AccountValidationAndEnrichment;
            Test.setCurrentPage(pageRef);

            ApexPages.StandardController stdAccount =  new ApexPages.StandardController(acc);
            PGC_AccountValidationAndEnrichment controller = new PGC_AccountValidationAndEnrichment(stdAccount);

            //Set bankAccountNumberInput -> 'NL67 ABNA 0628492812'
            controller.acct.Bank_AccountNumber__c = 'NL67 ABNA 0628492812';

            //Set bankNameInput -> 'testfakeBankName'
            controller.acct.Bank_Name__c = 'testfakeBankName';

            //Simulate click on Validate & Save by executing validateAndSave() method
            controller.validateAndSave();

            //Assert saved Account has now the following fields set:
            acc = (Account)GW_sObject.queryRecords('Account', new Set<Id>{acc.Id})[0];

            //acc.Bank_AccountNumber__c -> NL67ABNA0628492812
            System.assertEquals('NL67ABNA0628492812', acc.Bank_AccountNumber__c);
            
            controller.acct.Billing_Preference__c = 'Direct Debit';
            update controller.acct;
            
            String mandateStatus = controller.getMandateStatus;
            System.assertEquals('Not Signed', mandateStatus);
            
            Boolean isActive = controller.getBankDetailsActive();
            System.assertEquals(TRUE, isActive);
            
            //improve code coverage
            controller.acct.BillingCountryCode = 'ErrorCountryCode';
            controller.acct.Company_VAT_No__c = 'TestVatNo';
            controller.acct.Bank_AccountNumber__c = null;
            controller.acct.Billing_Preference__c = 'Invoice';
            controller.validateAndSave();
            controller.getActivePaymentMethods();
            controller.rerender();
        }
		Test.stopTest();
    }
}