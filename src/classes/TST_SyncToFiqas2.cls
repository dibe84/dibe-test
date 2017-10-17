@isTest
public class TST_SyncToFiqas2 {
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
                },
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>>{
                    new Map<String, Object>{
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 1,
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject>{
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

    @testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
		factory = new DF(scenarios, scenarioUsers);
        factory.setup();
    		UTIL.isRunningTestSetup = false;
    }

    	@isTest static void test_CustomerInsert() {
		DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
		Account acc = dfResult.accounts.values().get(0);
		
		acc.AccountExtId__c = acc.Id; 
		acc.FQ_CmrType__c = 'Banners';
		update acc; 
		
		Test.startTest();
		WSC_Fiqas.FiqasResponse res = WSC_Fiqas.customerInsert(acc);
		Test.stopTest();
		
		System.assertEquals('OK', res.getFirstElement().status);
    }
    
    @isTest static void test_CustomerPaymentInfoChange() {
    		DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
		Account acc = dfResult.accounts.values().get(0);
		
		acc.AccountExtId__c = acc.Id; 
		acc.FQ_CmrType__c = 'Banners';
		update acc; 
		
		Test.startTest();
		WSC_Fiqas.FiqasResponse res = WSC_Fiqas.customerPaymentInfoChange(acc);
		Test.stopTest();
		
		System.assertEquals('OK', res.getFirstElement().status);
    }
    
    @isTest static void test_InvoicesGet() {
		DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
		Account acc = dfResult.accounts.values().get(0);
		
		Test.startTest();
		WSC_Fiqas.FiqasResponse res = WSC_Fiqas.invoicesGet(acc.Id);
		Test.stopTest();
		
		System.assertEquals('OK', res.getFirstElement().status);
    }
    
    @isTest static void test_InvoiceGetPDF() {
    		DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
		Account acc = dfResult.accounts.values().get(0);
	    	Invoice__c inv = new Invoice__c( 
	            UniqueKey__c='TestFQInv', 
	            BillingAccount__c = acc.Id, 
	            FQ_InvoiceID__c='BEC1507000', 
	            StartDate__c = System.today(), 
	            EndDate__c = System.today()
	        );
	    	insert inv;
		Test.startTest();
		WSC_Fiqas.FiqasResponse res = WSC_Fiqas.invoiceGetPDF(inv.FQ_InvoiceID__c);
		Test.stopTest();
		System.assertEquals('OK', res.getFirstElement().status);
    }
    
    @isTest static void test_CustomerDirectDebitDetailsInsert() {
		DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
		Account acc = dfResult.accounts.values().get(0);
		
		acc.AccountExtId__c = acc.Id; 
		acc.FQ_CmrType__c = 'Banners';
		update acc; 
		
		Test.startTest();
		WSC_Fiqas.FiqasResponse res = WSC_Fiqas.customerDirectDebitDetailsInsert(acc);
		Test.stopTest();
		
		System.assertEquals('OK', res.getFirstElement().status);
    }
    
    @isTest static void test_CustomerCmrLinkChange() {
		DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
		Account acc = dfResult.accounts.values().get(0);
		
		acc.AccountExtId__c = acc.Id; 
		acc.FQ_CmrType__c = 'Banners';
		update acc; 
		
		Test.startTest();
		WSC_Fiqas.FiqasResponse res = WSC_Fiqas.customerCmrLinkChange(acc);
		Test.stopTest();
		
		System.assertEquals('OK', res.getFirstElement().status);
    }
    
    @isTest static void test_InvoiceLineInsert() {
		DF_Scenario.Result dfResult = DF.queryResults(scenarios, scenarioUsers);
		Account acc = dfResult.accounts.values().get(0);
	    	Invoice__c inv = new Invoice__c( 
	            UniqueKey__c='TestFQInv', 
	            BillingAccount__c = acc.Id, 
	            FQ_InvoiceID__c='BEC1507000', 
	            StartDate__c = System.today(), 
	            EndDate__c = System.today()
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
    		
    		il = (InvoiceLine__c)GW_sObject.queryRecords('InvoiceLine__c', new Set<Id>{il.Id})[0];
		
		Test.startTest();
		WSC_Fiqas.FiqasResponse res = WSC_Fiqas.invoiceLineInsert(il);
		Test.stopTest();
		
		System.assertEquals('OK', res.getFirstElement().status);
    }
	
}