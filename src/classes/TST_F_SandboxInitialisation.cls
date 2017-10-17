/**
 * Test class for F_SandboxInitialisation.cls
 * @author: Gaeasys Team
 * @createdDate: 24-Jul-2017
 */
@isTest
public class TST_F_SandboxInitialisation {
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
                }
            })
        };
    }

    @testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
    		factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void test_InsertAndClearData(){
    		Test.startTest();
    		F_SandboxInitialisation.DefaultDataContainer = 'SBDC_Latest';
    		F_SandboxInitialisation.DataContainer dc = F_SandboxInitialisation.retrieveDataFromOrg();
    		System.assertNotEquals(null, dc);
    		
    		F_SandboxInitialisation.cleanOrg('testOrg');
    		List<Account> lstAcc = (List<Account>) GW_sObject.queryRecords('Account','');
    		System.assertEquals(0, lstAcc.size());
    		
    		F_SandboxInitialisation.insertData(dc);
    		lstAcc = (List<Account>) GW_sObject.queryRecords('Account','');
    		System.assertNotEquals(0, lstAcc.size());
    		
    		F_SandboxInitialisation.exportCurrentStatus('SBDC_Latest');
    		F_SandboxInitialisation.applyPostInsertActions();
    		List<StaticResource> lstSr = F_SandboxInitialisation.getAvailableStaticResources();
    		System.assertNotEquals(0, lstSr.size());
    		
    		Test.stopTest();
    		
    		
    }
}