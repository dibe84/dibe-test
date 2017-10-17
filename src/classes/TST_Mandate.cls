@isTest 
public class TST_Mandate {
    public static DF factory;

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;

        factory = new DF(scenarios, scenarioUsers);
        factory.createFieldValidationRules = false;
        factory.setup();
        UTIL.isRunningTestSetup = false;

        System.runAs(factory.userMap.get('admin')) {
            UTIL_CustomJob.createTestCustomJobs();
            UTIL_CustomJob.startAllCustomJobs();
        }
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'accounts' });
        Account acc = result.accounts.values().get(0);
        acc.BillingCountryCode = 'NL';
        acc.Language_Preference__c = 'NL';
        acc.Billing_Preference__c = 'Direct Debit';
        acc.Bank_AccountNumber__c = 'BE23776592232991';
        acc.Bank_Name__c = 'BELFIUS BANK';
        update acc;
    }

    @isTest static void testGenerateMandate(){
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });
        Account acc = result.accounts.values().get(0);
        Test.startTest();
	        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {

	            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(acc);
	            PGC_GenerateMandate pgcGenerateMandate = new PGC_GenerateMandate(stdCtrl);

	            Pagereference pageRef=Page.GenerateMandate;
	            Test.setCurrentPage(pageRef);

	            pgcGenerateMandate.load();
	            System.assertEquals('Error Message: Unknown', pgcGenerateMandate.getErrorMessage());
	            System.assert(!pgcGenerateMandate.getShowErrorMessage());
	            pgcGenerateMandate.createMandate();
	            pgcGenerateMandate.attachMandatePdf();

	        }
        Test.stopTest();
    }
    
    @isTest static void testGenerateMandateError(){
		UTIL.isRunningTestSetup = true;

        //test in case error occur
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });
        Account acc = result.accounts.values().get(0);
 		acc.Finance_contact__c=null;
        update acc;
        UTIL.isRunningTestSetup = false;

        Test.startTest();

	        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
	 			ApexPages.StandardController stdCtrl = new ApexPages.StandardController(acc);
	            PGC_GenerateMandate pgcGenerateMandate = new PGC_GenerateMandate(stdCtrl);
	 			pgcGenerateMandate.load();
	            System.assert(pgcGenerateMandate.getShowErrorMessage());
	            pgcGenerateMandate.cancel();
	        }
        Test.stopTest();
    }


    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;

    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'ECGDKAD_adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'ECGDKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'ECGDK Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'All'
            }
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('ECGDKAD-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECGDK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser'
            })
        };
    }
}