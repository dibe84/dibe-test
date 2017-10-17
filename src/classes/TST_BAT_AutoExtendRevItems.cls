/**
 * Test logic for BAT_AutoExtendRevItems.cls
 */
@isTest
private class TST_BAT_AutoExtendRevItems {
	
	public static List < DF_Scenario > scenarios;
    public static Map < String, Map < String, String >> scenarioUsers;


    private static Date TODAY_THBELAU = system.Today();

    static {
        scenarioUsers = new Map < String, Map < String, String >> {
            'autosRep' => new Map < String,
            String > {
                DF_Scenario.CONF_USER_ROLE => 'THBELAU_Rep',
                DF_Scenario.CONF_USER_PROFILE => 'Automotive Sales Rep External',
                DF_Scenario.CONF_USER_USE_FOR => 'Opportunity'
            }
        };

        scenarios = new List < DF_Scenario > {
            new DF_Scenario('THBELAU-1', new Map < String, Object > {
                DF_Scenario.CONF_MEMBER => 'THBEL',
                DF_Scenario.CONF_MEMBER_UNIT => 'AU',
                DF_Scenario.CONF_USERS => new List < String > {
                    'autosRep'
                },
                DF_Scenario.CONF_INVOICE_GROUPING => '1 Invoice per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK => '2016',
                DF_Scenario.CONF_OPPORTUNITY => new Map < String,
                String > {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT => '1',
                    DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION => 'true',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(TODAY_THBELAU.addMonths(-12))
                },
                DF_Scenario.CONF_PRODUCTS => new List < Map < String,
                Object >> {
                    new Map < String,
                    Object > {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List < SObject > {
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

	@testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        System.runAs(factory.userMap.get('admin')) {
            insert new CustomJob__c(Name='BAT_AutoExtendRevItems',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=Date.today(),LastCheck__c=Date.today(),BatchSize__c=10,Active__c=true,WhereClause__c='Id <> null',IsRunning__c=false,TimeoutPerBatch__c = 3600);
        }
    }
	
    public static DF factory;
    
    @isTest static void testAutoExtendRecItems() {
        Test.startTest();
            UTIL_CustomJob.startCustomJob('BAT_AutoExtendRevItems');
        Test.stopTest();
        List<Rev__c> lstRevs = [Select Until_Date__c, ScheduleAhead_EndDate__c From Rev__c];
        System.assertEquals(lstRevs[0].Until_Date__c, lstRevs[0].ScheduleAhead_EndDate__c);
    }
}