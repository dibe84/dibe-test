@isTest
public class TST_AsyncGetTractRevenueScheduleFlow {
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

        insert new CustomJob__c(Name='BAT_RevenueScheduleImportFromTRACT',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=Date.today(),LastCheck__c=Date.today(),BatchSize__c=10,Active__c=true,WhereClause__c='Opportunity__r.StageName = \'Running\'',IsRunning__c=false,TimeoutPerBatch__c = 3600);

        insert new Webservice_Settings__c(Name = 'WSC_Tract_Reporting_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user');
        insert new Webservice_Settings__c(Name = 'WSC_Tract_Reporting_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user');
        
        List<Configuration__c> lstConf = new List<Configuration__c>();
        lstConf.add(new Configuration__c (Name = 'Tract_Service_Import_URL', Value__c = '%3ACustom%20Reports%20-%20eBay%20Classifieds%20Group%3AServiceDataImportReport.prpt/report'));
        lstConf.add(new Configuration__c (Name = 'Tract_Service_Import_PARAMS', Value__c = 'P_FROM_DATE=LAST_3_MONTHS&P_THRU_DATE=TODAY'));
        lstConf.add(new Configuration__c (Name = 'Tract_Invoice_Import_URL', Value__c = '%3ACustom%20Reports%20-%20eBay%20Classifieds%20Group%3AInvoiceTemplateReport.prpt/report'));
        lstConf.add(new Configuration__c (Name = 'Tract_Invoice_Import_PARAMS', Value__c = 'renderMode=REPORT'));
        lstConf.add(new Configuration__c (Name = 'Tract_Invoice_Item_Import_URL', Value__c = '%3ACustom%20Reports%20-%20eBay%20Classifieds%20Group%3AInvoiceItemReport.prpt/report'));
        lstConf.add(new Configuration__c (Name = 'Tract_Invoice_Item_Import_PARAMS', Value__c = 'enderMode=REPORT'));
        lstConf.add(new Configuration__c (Name = 'Tract_Forecast_Revenue_Import', Value__c = '%3ACustom%20Reports%20-%20eBay%20Classifieds%20Group%3ARevenueForecastReport.prpt/report'));
        lstConf.add(new Configuration__c (Name = 'Tract_Forecast_Revenue_Import_PARAMS', Value__c = 'renderMode=REPORT&P_ACCOUNT_NUMBER=TRACT_ACCOUNT_NUMBER'));
        
        insert lstConf;

        UTIL.isRunningTestSetup = false;
    
    }
    
    @isTest static void test_execute_TractRevenueScheduleSync() {
		
		DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
        Account acc = result.accounts.values().get(0);
        acc.Tract_AccountNumber__c = 'GTZ00001';
        update acc;
        
        Opportunity opp = result.oppMap.get('THBELAU-1.Opportunity[1]');
        opp.Tract_OrderId__c = 2604;
        update opp;
        
        TRACT_Service__c ts = new TRACT_Service__c();
        ts.Name = 'Test';
        ts.Billing_Account__c = acc.Id;
        ts.Opportunity__c = opp.Id;
        insert ts;

        Test.startTest();

        AsyncGetTractRevenueScheduleFlow aactf = new AsyncGetTractRevenueScheduleFlow(opp.Id);

        ID jobID = System.enqueueJob(aactf);

        Test.stopTest();


	}
}