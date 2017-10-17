@istest 
public class TST_BAT_LostOpportunityAfterDays {
    
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
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 2,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Dækning & Dominans - Biler [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPM_Delivery',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPC_Price__c = 1.00,
                                CPM_Price__c = 115.00,
                                Description = 'This is test.',
                                Product_SubType__c = 'RE'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = null,
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Fixed_PricePerMonth__c = 0.00,
                                Tiered_Tiersize__c = 0.00,
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 1.00,
                                MaxDiscountPercent__c = 73.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                },
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            })
        };
    }
    
    @testSetup
    static void setup() {

        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts', 'memberunits'});
        Account acc = result.accounts.values().get(0);
        MemberUnit__c mu = result.memberunits.values().get(0);
        
        //Create New Opportunity since Opportunity created in DF always signed
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today();
        opp.StageName = 'Qualication';
        opp.AccountId = acc.Id;
        opp.MemberUnit__c = mu.Id;
        insert opp;
        
        Datetime last60Days = Datetime.now().addDays(-70);
        Test.setCreatedDate(opp.Id, last60Days);

        CustomJob__c cJob = new CustomJob__c(Name='BAT_LostOpportunityAfterDays', JobFrequency__c='Daily', JobType__c='Batch', LastRun__c=system.today().addDays(-1), LastCheck__c=system.today().addDays(-1), BatchSize__c=10, Active__c=true, WhereClause__c='StageName NOT IN ( \'Signed\' , \'Scheduled\' , \'Running\' , \'Finished\',\'Lost\' ) AND CreatedDate < LAST_N_DAYS:60', IsRunning__c=false,TimeoutPerBatch__c = 3600);
        insert cJob;
        
        UTIL.isRunningTestSetup = false;
    
    }
    
    @isTest 
    static void test_BATLostOpportunityAfterDays () {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'users'});
        test.startTest();
        System.runAs(result.users.get('admin')) {
            UTIL_CustomJob.startCustomJob('BAT_LostOpportunityAfterDays');
        }
        test.StopTest();
    }
}