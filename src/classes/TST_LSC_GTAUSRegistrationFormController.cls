@isTest
private class TST_LSC_GTAUSRegistrationFormController {
	
	public static DF factory;

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'GTAUSAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
            
        };

        scenarios = new List<DF_Scenario> {
            
            new DF_Scenario('EBAYKRE-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'GTAUS',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'adsalesRep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser'
            })
        };
    }

    @testSetup
    static void setup() {

        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();

        

        UTIL.isRunningTestSetup = false;
    
    }

	@isTest static void test_getFieldSet() {
		
		List< List<LSC_Helper.FieldSetMember> > leadFieldSets = new List<List<LSC_Helper.FieldSetMember>>();

        Test.startTest();

        Set<String> lstLeadFieldSet = Schema.SObjectType.Lead.fieldSets.getMap().keyset();
        if(!lstLeadFieldSet.isEmpty()){
            for(String fieldsetName: lstLeadFieldSet){
                String result = LSC_GTAUSRegistrationFormController.getFieldSet( 'Lead', fieldsetName);
                

                List<LSC_Helper.FieldSetMember> fieldSets = (List<LSC_Helper.FieldSetMember>) JSON.deserialize(result, List<LSC_Helper.FieldSetMember>.class);
                System.debug('### LSC fieldSets :: ' + fieldSets);

                leadFieldSets.add(fieldSets);
            }
        }

        Test.stopTest();

        //There should be 2 Field Sets for Lead in SF {GTAUS_Autos, GTAUS_Jobs}
        System.assert( leadFieldSets.size() >= 2 , 'There should be 2 Fieldsets for Lead in SF such as {GTAUS_Autos, GTAUS_Jobs} ');
	}
	
	@isTest static void test_submitRegistration_success() {
		
		DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        
        insert new Configuration__c(Name='GTAUS_RegistrationMemberUnitId', Value__c=memberUnit.MemberUnitId__c);
        insert new Configuration__c(Name='GTAUS_RegistrationLead', Value__c='{"jobs":{"Type__c":"Jobs","LeadSource":"Web","Status":"Open"},"autos":{"Type__c":"Car Dealer","LeadSource":"Web","Status":"Open"}}');

        Map<String, Object> res = new Map<String, Object>();

        Test.startTest();

        String formDetail = '[{"name":"FirstName","value":"GTAUS-TST-NAME","type":"STRING","required":true},{"name":"LastName","value":"test","type":"STRING","required":true},{"name":"Company","value":"test","type":"STRING","required":true},{"name":"Street","value":"test","type":"TEXTAREA","required":true},{"name":"Company_Reg_No__c","value":"123","type":"STRING","required":true},{"name":"Email","value":"test@test.com","type":"EMAIL","required":true},{"name":"Phone","value":"123456789","type":"PHONE","required":true},{"name":"External_Info__c","value":"test","type":"TEXTAREA","required":true}]';
        String formType = 'autos';

        res = LSC_GTAUSRegistrationFormController.submitRegistration(formDetail, formType);

        Test.stopTest();

        
        System.assertEquals(true, res.get('isSuccess'), 'It should be successfully Submition.');
        
        List<Lead> lead = [SELECT Name FROM Lead WHERE FirstName = 'GTAUS-TST-NAME'];
        System.assert( lead.size() >= 1, 'There should be one new Lead created.');

	}

	@isTest static void test_submitRegistration_failed() {

		DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
        
        insert new Configuration__c(Name='GTAUS_RegistrationMemberUnitId', Value__c=memberUnit.MemberUnitId__c);
        insert new Configuration__c(Name='GTAUS_RegistrationLead', Value__c='{"jobs":{"Type__c":"Jobs","LeadSource":"Web","Status":"Open"},"autos":{"Type__c":"Car Dealer","LeadSource":"Web","Status":"Open"}}');

        Map<String, Object> res = new Map<String, Object>();

        Test.startTest();

        String formDetail = '[{"name":"FirstName","value":"GTAUS-TST-NAME","type":"STRING","required":true},{"name":"LastName","value":"test","type":"STRING","required":true},{"name":"Company","value":"test","type":"STRING","required":true},{"name":"Street","value":"test","type":"TEXTAREA","required":true},{"name":"Company_Reg_No__c","value":"123","type":"STRING","required":true},{"name":"Email","value":"test","type":"EMAIL","required":true},{"name":"Phone","value":"123456789","type":"PHONE","required":true},{"name":"External_Info__c","value":"test","type":"TEXTAREA","required":true}]';
        String formType = 'autos';

        res = LSC_GTAUSRegistrationFormController.submitRegistration(formDetail, formType);

        Test.stopTest();

		System.debug('### res :: ' + res);        
        System.assertEquals(false, res.get('isSuccess'), 'It should be failing to submit register form.');
        System.assertEquals('Sorry, an error has occurred.', res.get('errMsg'), 'There should be error message of the following "Sorry, an error has occurred.".');
	}

	@isTest static void test_submitRegistration_failed_missingMU() {

		DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits'});
        
        Account acc = result.accounts.values().get(0);
        MemberUnit__c memberUnit = result.memberunits.values().get(0);
     
        Map<String, Object> res = new Map<String, Object>();

        Test.startTest();

        String formDetail = '[{"name":"FirstName","value":"GTAUS-TST-NAME","type":"STRING","required":true},{"name":"LastName","value":"test","type":"STRING","required":true},{"name":"Company","value":"test","type":"STRING","required":true},{"name":"Street","value":"test","type":"TEXTAREA","required":true},{"name":"Company_Reg_No__c","value":"123","type":"STRING","required":true},{"name":"Email","value":"test@test.com","type":"EMAIL","required":true},{"name":"Phone","value":"123456789","type":"PHONE","required":true},{"name":"External_Info__c","value":"test","type":"TEXTAREA","required":true}]';
        String formType = 'autos';

        res = LSC_GTAUSRegistrationFormController.submitRegistration(formDetail, formType);

        Test.stopTest();

		System.debug('### res :: ' + res);        
        System.assertEquals(false, res.get('isSuccess'), 'It should be failing to submit register form.');
        System.assertEquals('Sorry, an error has occurred.', res.get('errMsg'), 'There should be error message of the following "Sorry, an error has occurred.".');
        System.assert( String.isNotBlank(String.valueOf(res.get('rawMsg'))), 'There should be error message showing that Member Unit is missing.');

	}
	
}