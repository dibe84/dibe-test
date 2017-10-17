@isTest private class TST_WSI_TractInvoicesController {
	public static List < DF_Scenario > scenarios;
    public static Map < String, Map < String, String >> scenarioUsers;
    private static Date TODAY_THBELAU = system.Today();
    static {
        scenarioUsers = new Map < String, Map < String, String >> {
            'autoRep' => new Map < String,
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
                    'autoRep'
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
    
    public static DF factory;
    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        
        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        insert wss;
        UTIL.isRunningTestSetup = false;
    }
    @istest static void test_resendTractInvoices() {
    	DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Account acc = result.accounts.values().get(0);
        acc.Tract_AccountNumber__c = 'GTZ00001';
        update acc;
     
        TRACT_Invoice__c  ts = new TRACT_Invoice__c ();
        ts.Name = 'Test';
        ts.Billing_Account__c = acc.Id;
        //ts.External_Id__c = '1344'; 
        insert ts;
        
        List<String> invIds = new List<String>{ts.Id};
        Test.startTest();
        	String res = WSI_TractInvoicesController.resendTractInvoices(invIds);
        	System.debug('res = ' + res);
        	System.assert(res.contains('Invoice sent successfully.'));
        Test.stopTest();
    }
}