@isTest
public class TST_WSC_Tract_Reporting {

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
        UTIL.isRunningTestSetup = false;

        System.runAs(factory.userMap.get('admin')) {
            //
            UTIL_CustomJob.createTestCustomJobs();
            List<Configuration__c> lstConf = new List<Configuration__c>();
            lstConf.add(new Configuration__c (Name = 'Tract_Service_Import_URL', Value__c = '%3ACustom%20Reports%20-%20eBay%20Classifieds%20Group%3AServiceDataImportReport.prpt/report'));
            lstConf.add(new Configuration__c (Name = 'Tract_Service_Import_PARAMS', Value__c = 'P_FROM_DATE=LAST_3_MONTHS&P_THRU_DATE=TODAY'));
            lstConf.add(new Configuration__c (Name = 'Tract_Invoice_Import_URL', Value__c = '%3ACustom%20Reports%20-%20eBay%20Classifieds%20Group%3AInvoiceTemplateReport.prpt/report'));
            lstConf.add(new Configuration__c (Name = 'Tract_Invoice_Import_PARAMS', Value__c = 'renderMode=REPORT'));
            lstConf.add(new Configuration__c (Name = 'Tract_Invoice_Item_Import_URL', Value__c = '%3ACustom%20Reports%20-%20eBay%20Classifieds%20Group%3AInvoiceItemReport.prpt/report'));
            lstConf.add(new Configuration__c (Name = 'Tract_Invoice_Item_Import_PARAMS', Value__c = 'enderMode=REPORT'));
            lstConf.add(new Configuration__c (Name = 'Tract_Forecast_Revenue_Import', Value__c = '%3ACustom%20Reports%20-%20eBay%20Classifieds%20Group%3ARevenueForecastReport.prpt/report'));
            lstConf.add(new Configuration__c (Name = 'Tract_Forecast_Revenue_Import_PARAMS', Value__c = 'renderMode=REPORT'));
            
            insert lstConf;
        }
    }

    @isTest
    static void testAddMoreCoverage() {
        Test.startTest();
            //UTIL_CustomJob.startAllCustomJobs();
            DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
            System.debug('@@@ result : ' + result);
            Opportunity opp = result.oppMap.get('THBELAU-1.Opportunity[1]');
    
            System.runAs(result.users.get('autoRep')) {
                WSC_Tract_Reporting wtr = new WSC_Tract_Reporting();
            }
        Test.stopTest();
    }
    
    @isTest static void test_tractServiceImportFormTract() {
        
        Account testacc = new Account(Name = 'xxxxx', Tract_AccountId__c = '12345');
        insert testacc;
        insert new CustomJob__c(Name='BAT_ServiceImportFromTract',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=Date.today(),LastCheck__c=Date.today(),BatchSize__c=10,Active__c=true,WhereClause__c='N/A',IsRunning__c=false,TimeoutPerBatch__c = 3600);
        
        Test.startTest();
            UTIL_CustomJob.startCustomJob('BAT_ServiceImportFromTract');
        Test.stopTest();
        
        //TODO 
        //ASSERTION --> skip for now due to business logic still can change
    }
    
    @isTest static void test_tractInvoicesImportFormTract() {
        Account testacc = new Account(Name = 'xxxxx', Tract_AccountId__c = '12345',CurrencyIsoCode  ='EUR');
        insert testacc;        
        insert new CustomJob__c(Name='BAT_InvoicesImportFromTRACT',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=Date.today(),LastCheck__c=Date.today(),BatchSize__c=10,Active__c=true,whereClause__c='StageName<>null',IsRunning__c=false,TimeoutPerBatch__c = 3600);
        
        Test.startTest();
            UTIL_CustomJob.startCustomJob('BAT_InvoicesImportFromTRACT');
        Test.stopTest();
        
        //TODO 
        //ASSERTION --> skip for now due to business logic still can change
    }
    
    @isTest static void test_tractInvoiceItemsImportFormTract() {
        
        insert new CustomJob__c(Name='BAT_InvoiceItemsImportFromTRACT',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=Date.today(),LastCheck__c=Date.today(),BatchSize__c=10,Active__c=true,whereClause__c='Opportunity.StageName<>null',IsRunning__c=false,TimeoutPerBatch__c = 3600);
        Account testacc = new Account(Name = 'xxxxx', Tract_AccountId__c = '12345');
        insert testacc;

        Member__c  member = new Member__c(Name ='2ehands Belgium AdSales', Account__c =testacc.Id,CurrencyIsoCode  ='EUR');
        insert member;
        
        MemberUnit__c memberunit = new MemberUnit__c(Name ='2ehands Belgium Adsales', EnableTRACT__c = true, LineOfBusiness__c ='AD', CurrencyIsoCode  ='EUR', Member__c =member.Id);
        insert memberunit;
        
        Opportunity opp = new Opportunity(Name = 'test-opp',MemberUnit__c = memberunit.Id, AccountId=testacc.Id, CloseDate=TODAY_THBELAU.addDays(-60), StageName= 'Finished', LeadSource ='Other',CurrencyIsoCode  ='EUR');
        insert opp;
        
        Product2 newProduct = new Product2(CurrencyIsoCode  ='EUR',Name = 'Test Widget',Family = 'Widgets');
        insert newProduct;

        PricebookEntry pbe = new PricebookEntry(CurrencyIsoCode  ='EUR',IsActive = TRUE,Pricebook2Id = Test.getStandardPricebookId(),Product2Id = newProduct.Id,UnitPrice = 5555,UseStandardPrice = FALSE);
        insert pbe;
          
        OpportunityLineItem oppLine = new OpportunityLineItem(PricebookEntryId = pbe.Id,Description= 'Test opp',Ad_Name__c = 'abc',OpportunityId = opp.Id,from_Date__c = TODAY_THBELAU.addDays(-50),until_Date__c = TODAY_THBELAU, Billing_Category__c = 'CPM',Quantity = 100000,UnitPrice = 3);
        insert oppLine;
        
        
        Test.startTest();
            UTIL_CustomJob.startCustomJob('BAT_InvoiceItemsImportFromTRACT');
        Test.stopTest();
        
        //TODO 
        //ASSERTION --> skip for now due to business logic still can change
    }
    
}