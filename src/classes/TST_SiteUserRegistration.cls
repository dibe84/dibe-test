/**
 * Test class for SiteUserRegistration.cls
 * @author: Gaeasys Team
 * @createdDate: 09-Jul-2017
 */
@isTest
public class TST_SiteUserRegistration {
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

        UTIL.isRunningTestSetup = false;
    }
	
	@isTest
    static void test_SiteUserRegistration() {
    		DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
    		Account acc = dfResult.accounts.values().get(0);
    		List<Object>lstContatDetails = new List<Object>{new Map<String, Object>{ 'name' => 'LastName', 'value' => 'testCon' }};
    		lstContatDetails.add(new Map<String, Object>{ 'name' => 'FirstName', 'value' => 'testCon' });
	    	List<Object>lstAccountDetails = new List<Object>{new Map<String, Object>{ 'name' => 'Name', 'value' => 'testAcc' }};
    		
    		Member__c member = dfResult.members.get('EBAYK');
        MemberUnit__c memberUnit = dfResult.memberUnits.values().get(0);
        
	    	String contactDetail = JSON.serialize(lstContatDetails);
	    	String accountDetail = JSON.serialize(lstAccountDetails);
            
        Test.startTest();
        
	        Boolean boolResult = SiteUserRegistration.doRegisterUser( contactDetail, accountDetail, null);
	        System.assertEquals(TRUE, boolResult);
	        
	        boolResult = SiteUserRegistration.doRegisterUser( contactDetail, accountDetail, acc.Id);
	        System.assertEquals(TRUE, boolResult);
	        
	        Id leadId = SiteUserRegistration.createLead( contactDetail, member.Id, memberUnit.Id);
	        Lead lead = (Lead)GW_sObject.queryRecords('Lead', new Set<Id>{leadId})[0];
	        System.assertNotEquals(null, lead, 'A lead would be created');
	        
	        boolResult = SiteUserRegistration.deleteLead(leadId);
	        List<Lead> lstLead = (List<Lead>)GW_sObject.queryRecords('Lead', new Set<Id>{leadId});
	        System.assertEquals(TRUE, boolResult);
	        System.assertEquals(0, lstLead.size(), 'A lead would be deleted');
	        
	        boolResult = SiteUserRegistration.checkExistingUser('axu@test.com');
	        System.assertEquals(FALSE, boolResult);
	        
	        boolResult = SiteUserRegistration.checkExistingUser('ebayk.account.advertiser.fc=ebay.com@example.com');
	        System.assertEquals(TRUE, boolResult);
	        
	        Account accResult = SiteUserRegistration.getExistingInfo('Name', 'axu@test.com');
	        System.assertEquals(null, accResult.Id, 'Account not found');
	        
	        accResult = SiteUserRegistration.getExistingInfo('Name', 'ebayk.account.advertiser.fc=ebay.com@example.com');
	        System.assertNotEquals(null, accResult, 'Found an account');
	        
	        accResult = null;
	        accResult = SiteUserRegistration.createAccount('salutation','firstName','lastName','companyName','emailaddress@testacc.com','password',
	        										   'phoneNumber','street','postalCode','city','country','promotionCode',
	        										   'kvkNumber','vatNumber','countryCode','userExternalId','memberUnit'
	        										  );
	        	System.assertEquals(null, accResult, 'Exception on account country code, new account will not create');
	        	
	        	accResult = null;
	        accResult = SiteUserRegistration.createAccount('salutation','firstName','lastName','companyName','emailaddress@testacc.com','password',
	        										   'phoneNumber','street','postalCode','city','country','promotionCode',
	        										   'kvkNumber','vatNumber','US','userExternalId','memberUnit'
	        										  );
	        	System.assertNotEquals(null, accResult, 'New account would be created');
	        
	        SiteUserRegistration.doRegistrationUser('salutation','firstName','lastName','companyName','emailaddress@testacc.com','password',
	        										   'phoneNumber','street','postalCode','city','country','promotionCode',
	        										   'kvkNumber','vatNumber','US','userExternalId','memberUnit'
	        										  );
	        
	        SiteUserRegistration.createContact(); //method no content
        Test.stopTest();
    }
}