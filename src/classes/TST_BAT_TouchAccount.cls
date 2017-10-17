@isTest 
public class TST_BAT_TouchAccount {
    
    public static DF factory;

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'EBAYKRE_Rep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'EBAYKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
            
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('EBAYKRE-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'RE',
                DF_Scenario.CONF_USERS               => new List<String> { 'EBAYKRE_Rep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'EBAYKRE_DBA_2017',
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            })
        };
    }
    
     @testSetup 
    private static void setup() {  
        
        UTIL.isRunningTestSetup = true;
        
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();

        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts'});
        Account acc = result.accounts.values().get(0);
        
        DateTime currentDT = DateTime.now(); 
        Test.setCreatedDate(acc.Id, currentDT.addDays(-10)); 

        UTIL.isRunningTestSetup = false;
    }
    
     @isTest 
     static void testBATTouchAccountSuccess() {
        
        DateTime todayDT = DateTime.now();
        DateTime lasWeekDT = todayDT.addDays(-7);
        string lastWeekStr = lasWeekDT.formatGMT('yyyy-MM-dd') + 'T' + lasWeekDT.formatGMT('HH:mm:ss.SSS') + 'Z';
        
        //Real logic is WhereClause__c='LastModifiedDate < LAST_WEEK'
        // In test class we cant set LastModifiedDate to past, so we used CreatedDate instead
        CustomJob__c CJ = new CustomJob__c(Name='BAT_TouchAccount',JobFrequency__c='2min',JobType__c='Batch',LastRun__c=system.today().addDays(-1),LastCheck__c=system.today().addDays(-1),BatchSize__c=5,Active__c=true,WhereClause__c='CreatedDate < ' + lastWeekStr,IsRunning__c=false,TimeoutPerBatch__c = 600);
        insert CJ;
        
        test.startTest();
        UTIL_CustomJob.startCustomJob('BAT_TouchAccount');
        test.stopTest();
        
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts'});
        Account accAfterRun = result.accounts.values().get(0);
        system.assert(accAfterRun.Touch__c.contains('Touched by API batch job'));
       
        
     }
}