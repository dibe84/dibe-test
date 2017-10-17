@isTest
public class TST_BAT_InvoiceSyncFiqas {
    
    public static DF factory;
    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'ECGDKAD_adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'ECGDKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('ECGDKAD-03', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECGDK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
                DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Opportunity per Batch',
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
                DF_Scenario.CONF_PRODUCTS =>  new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
                        DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-03-01',
                        DF_Scenario.CONF_PRODUCT_DATA  => new List<SObject> {
                            new Product2(
                                Name = 'Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPD_Delivery',
                                ScheduleAheadTerm__c = 3,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPD_Price__c = 55000
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = null,
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Fixed_PricePerMonth__c = 0.00,
                                Tiered_Tiersize__c = 0.00,
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 1.00,
                                MaxDiscountPercent__c = 55.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                },
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '2',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            })
        };
    }
    
    
    @testSetup
    static void setupData(){
        UTIL.isRunningTestSetup = true;
		UTIL_CustomJob.recreateAllCustomJobs();   
		
		factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts'});
        Account acc = result.accounts.values().get(0);
        
        Invoice__c inv = new Invoice__c( 
            UniqueKey__c='TestFQInv', 
            BillingAccount__c = acc.id, 
            FQ_InvoiceID__c='BEC1507000', 
            StartDate__c = System.today(), 
            EndDate__c = System.today(),
            FQ_SyncPending__c = TRUE
        );
            insert inv;
            
        InvoiceLine__c il = new InvoiceLine__c();
        il.Amount__c = 100;
        il.IndirectDiscountAmount__c = 0;
        il.Invoice__c = inv.Id;
        il.InvoiceLineDescription__c = 'Indirect Discount';
        il.Quantity__c = 1;
        il.UniqueKey__c = 'ID_'+inv.Id+'_';
        il.FQ_ProductCode__c = 'UK_AUS_BAN';
        il.FQ_ProductType__c = 'Banners';
        il.FQ_ProductSubType__c = '';
        il.RS__c = null;
        il.VatPercentage__c = '50';
        il.LineOfBusiness__c = 'AdSales';
        il.CurrencyIsoCode = inv.CurrencyIsoCode;
        insert il;
        
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest 
    static void testUnit(){
    		Test.startTest();
    		BAT_InvoiceSyncFiqas bat = new BAT_InvoiceSyncFiqas();
    		bat.getNumRecords();
    		bat.readyForRun();
    		UTIL_CustomJob.startCustomJob('BAT_InvoiceSyncFiqas');
    		Test.stopTest();
    		
    		List<InvoiceLine__c> lstInvLine = GW_sObject.queryRecords('InvoiceLine__c', 'InvoiceLineDescription__c = \'Indirect Discount\'');
    		system.assertEquals(lstInvLine.get(0).FQ_SyncStatus__c, 'FAILED - Missing fields for sync to Billing');
    }
    
}