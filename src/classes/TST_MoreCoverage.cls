@isTest
public class TST_MoreCoverage {

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
                                BillingScheme__c = 'Monthly in Arrears',
                                Tract_SKU__c = 'test#test'
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

        System.runAs(result.users.get('autosRep')) {

            AsyncAccCreateTractFlow controller = new AsyncAccCreateTractFlow(opp.id);
            AsyncDraftOrderCreateTractFlow conTract = new AsyncDraftOrderCreateTractFlow(opp.id);
            AsyncGetAgreementTractFlow conArgge = new AsyncGetAgreementTractFlow(opp.id);
            AsyncOrderCreateTractFlow conOrderCreate = new AsyncOrderCreateTractFlow(opp.id);
            try {
                System.enqueueJob(controller);
                System.enqueueJob(conTract);
                System.enqueueJob(conArgge);
                System.enqueueJob(conOrderCreate);
            } catch (Exception e) {

            }

            DateTime yesterday = (DateTime) Date.today() - 1;
            List<CustomJob__c> lstBatchs = new List<CustomJob__c>();
            lstBatchs.add( new CustomJob__c(Name = 'BAT_ServiceImportFromTract', JobFrequency__c = 'Daily', JobType__c = 'Batch', LastRun__c = yesterday, LastCheck__c = yesterday, BatchSize__c = 10, Active__c = true, WhereClause__c = 'N/A', IsRunning__c = false, TimeoutPerBatch__c = 3600));
            lstBatchs.add( new CustomJob__c(Name = 'BAT_InvoicesImportFromTRACT', JobFrequency__c = 'Daily', JobType__c = 'Batch', LastRun__c = yesterday, LastCheck__c = yesterday, BatchSize__c = 10, Active__c = true, whereClause__c='StageName<>null', IsRunning__c = false, TimeoutPerBatch__c = 3600));
            lstBatchs.add( new CustomJob__c(Name = 'BAT_InvoiceItemsImportFromTRACT', JobFrequency__c = 'Daily', JobType__c = 'Batch', LastRun__c = yesterday, LastCheck__c = yesterday, BatchSize__c = 10, Active__c = true, whereClause__c='Opportunity.StageName<>null', IsRunning__c = false, TimeoutPerBatch__c = 3600));
            lstBatchs.add( new CustomJob__c(Name = 'BAT_GenerateInvoiceBatch', JobFrequency__c = 'Daily', JobType__c = 'Batch', LastRun__c = yesterday, LastCheck__c = yesterday, BatchSize__c = 10, Active__c = true, WhereClause__c = 'N/A', IsRunning__c = false, TimeoutPerBatch__c = 3600));
            lstBatchs.add( new CustomJob__c(Name = 'BAT_AccountValidationAndEnrichment', JobFrequency__c = 'Daily', JobType__c = 'Batch', LastRun__c = yesterday, LastCheck__c = yesterday, BatchSize__c = 10, Active__c = true, WhereClause__c = 'N/A', IsRunning__c = false, TimeoutPerBatch__c = 3600));
            insert lstBatchs;
            
            BAT_InvoicesImportFromTRACT batchInvoice = new BAT_InvoicesImportFromTRACT();
            Database.executeBatch(batchInvoice);

            BAT_ServiceImportFromTract batService = new BAT_ServiceImportFromTract();
            Database.executeBatch(batService);

            BAT_InvoiceItemsImportFromTRACT batchInvoiceItem = new BAT_InvoiceItemsImportFromTRACT();
            Database.executeBatch(batchInvoiceItem);
            
            InvoiceBatch__c testInvoice = new InvoiceBatch__c();
            insert testInvoice;
            
            BAT_GenerateInvoiceBatch batchGenInvoice = new BAT_GenerateInvoiceBatch(testInvoice);
            Database.executeBatch(batchGenInvoice);
            
            Account acc = new Account(BillingCountryCode ='NL',name ='test');
            insert acc;
            List<Account> lstAccs = new List<Account>();
            lstAccs.add(acc);
            
            BAT_AccountValidationAndEnrichment batchAccs = new BAT_AccountValidationAndEnrichment(lstAccs);
            Database.executeBatch(batchAccs);
            
            
            String respone = WSI_Opportunity.sendForApproval('');
            respone = WSI_Opportunity.sendForApproval(opp.id);
            
            Map<String,String> resultMap = UTIL_MapInsight.convertFusionTableResponseToRegions(new Map<String,String>{'Country'=>'test'});
            
            List<MapInsight_RegionMapping__c> allRegionMappings = new List<MapInsight_RegionMapping__c>();
            allRegionMappings.add(new MapInsight_RegionMapping__c(Country__c='test',Type__c ='test',name='test' ));
            insert allRegionMappings;
            
            resultMap = UTIL_MapInsight.convertFusionTableResponseToRegions(new Map<String,String>{'Country'=>'test'});
             
            
            Test.stopTest();

        }
    }
    
    @isTest
    static void test_AsyncLocalBookingFlow() {
        Test.startTest();
            DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers);
            System.debug('@@@ result : ' + result);
            Opportunity opp = result.oppMap.get('THBELAU-1.Opportunity[1]');
            
            AccountMemberUnitAssociation__c muass = new AccountMemberUnitAssociation__c();
            muass.Account__c = opp.AccountId;
            muass.MemberUnit__c = opp.MemberUnit__c;
            insert muass;
            
            List<Webservice_Settings__c> wss = new List<Webservice_Settings__c> {
                new Webservice_Settings__c(Name='THBELAU_WSC_API_SFECG_v2_UAT', Endpoint__c='http://testing123.test.com', Key__c='notrealyakey', User__c='notrealyausername'),
                new Webservice_Settings__c(Name='THBELAU_WSC_API_SFECG_v2_PROD', Endpoint__c='http://testing123.test.com', Key__c='notrealyakey', User__c='notrealyausername')
            };
            insert wss;
            
            System.runAs(result.users.get('autosRep')) { 
                AsyncLocalBookingFlow conBooking = new AsyncLocalBookingFlow(opp.id);
                try {
                    System.enqueueJob(conBooking);
                } catch (Exception e) {
    
                }
            }
        
        Test.stopTest();
    }

}