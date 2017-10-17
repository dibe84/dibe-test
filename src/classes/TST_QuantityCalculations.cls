@isTest
public class TST_QuantityCalculations {

	public static List<DF_Scenario> adSalesScenarios;
	public static Map<String, Map<String, String>> usersAdsales;
	public static DF factory;

	public static final Integer DAILY_IMPRESSION_COUNT = 1000;
	public static final Integer DAILY_CLICK_COUNT = 2500;
	public static final Integer REVENUE_BUDGET_IN_DAYS = 45;
	public static final Integer REVENUE_CPM_MULTIPLICATION_FACTOR = 10;
	public static final Integer REVENUE_CPD_MULTIPLICATION_FACTOR = 1000;

	static {
		usersAdsales = new Map<String, Map<String, String>> {
			'ECGDKAD_adsalesRep' => new Map<String, String> {
				DF_Scenario.CONF_USER_ROLE      => 'ECGDKAD',
				DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep', // should be ECGDK Ad Sales Rep but does not exist on JC1 box
				DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
			}
		};
		adSalesScenarios = new List<DF_Scenario> {
			new DF_Scenario('ECGDKAD-01', new Map<String, Object> {
				DF_Scenario.CONF_MEMBER              => 'ECGDK',
				DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
				DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
				DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
				DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
				DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
				DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
					new Map<String, Object> {
						DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
						DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-01-01',
						DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
							new Product2(
								Name = 'Desktop: DBA Dækning & Dominans - Biler [Vertical]',
								ProductCode = 'DBA_BAN',
								Billing_Category__c = 'CPM_Delivery',
								ScheduleAheadTerm__c = 6,
								ContractPeriodInMonths__c = 6,
								BillingScheme__c = 'Monthly in Arrears',
								CPC_Price__c = 0.00,
								CPM_Price__c = 10.00
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
					DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-4).toStartOfMonth())
				}
			}),
			new DF_Scenario('ECGDKAD-02', new Map<String, Object> {
				DF_Scenario.CONF_MEMBER              => 'ECGDK',
				DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
				DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
				DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
				DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
				DF_Scenario.CONF_PRICEBOOK           => 'ECGDKAD_DBA_2016',
				DF_Scenario.CONF_PRODUCTS =>  new List<Map<String, Object>> {
					new Map<String, Object> {
						DF_Scenario.CONF_PRODUCT_QUANTITY => 10,
						DF_Scenario.CONF_PRODUCT_AD_ID => 'ECGDKAD-02-01',
						DF_Scenario.CONF_PRODUCT_DATA  => new List<SObject> {
							new Product2(
								Name = 'Desktop: DBA Curtain / Open Door-Til Boligen [Vertical]',
								ProductCode = 'DBA_BAN',
								Billing_Category__c = 'CPD_Delivery',
								ScheduleAheadTerm__c = 3,
								ContractPeriodInMonths__c = 6,
								BillingScheme__c = 'Monthly in Arrears',
								CPD_Price__c = 1000
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
					DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
					DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-4).toStartOfMonth())
				}
			}),
			new DF_Scenario('ECGDKAD-03', new Map<String, Object> {
				DF_Scenario.CONF_MEMBER              => 'ECGDK',
				DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
				DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
				DF_Scenario.CONF_INVOICE_GROUPING    => '1 Invoice per Batch',
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
								Billing_Category__c = 'CPC_Delivery',
								ScheduleAheadTerm__c = 3,
								ContractPeriodInMonths__c = 6,
								BillingScheme__c = 'Monthly in Arrears',
								CPC_Price__c = 2000
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
					DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
					DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-4).toStartOfMonth())
				}
			})
		};
	}

	@testSetup
	static void setupAdsales() {
		UTIL.isRunningTestSetup = true;
		factory = new DF(adSalesScenarios, usersAdsales);
		factory.setup();
		UTIL.isRunningTestSetup = false;
		UTIL_CustomJob.createTestCustomJobs();
	}

	private static void addMetrics(RS__c rs) {
		List<Metric__c> metricsToUpsert = new List<Metric__c>();
		for (Metric__c m : GW_Metric.createAllMetricsFromRS(rs) ) {
			m.AD_Amount__c = 0;
			m.AD_Clicks__c = 0;
			m.AD_Impressions__c = DAILY_IMPRESSION_COUNT;
			m.AD_OSI__c = 0;
			metricsToUpsert.add(m);
		}
		insert metricsToUpsert;
	}

	private static void addMetricsCPC(RS__c rs) {
		List<Metric__c> metricsToUpsert = new List<Metric__c>();
		for (Metric__c m : GW_Metric.createAllMetricsFromRS(rs) ) {
			m.AD_Amount__c = 0;
			m.AD_Clicks__c = DAILY_CLICK_COUNT;
			m.AD_Impressions__c = 0;
			m.AD_OSI__c = 0;
			metricsToUpsert.add(m);
		}
		insert metricsToUpsert;
	}

	@isTest
    static void testQuantityCalcCPM() {
		UTIL_Log.start();
        Test.startTest();
		DF_Scenario.Result result = DF.queryResults(adSalesScenarios, usersAdsales, new Set<String> { 'oppMap' });

		// Opp below will be tested in next test method, deleting it simplifies this test A LOT
		List<Opportunity> opps = new List<Opportunity> { result.oppMap.get('ECGDKAD-02.Opportunity[1]'), result.oppMap.get('ECGDKAD-03.Opportunity[1]') };
		delete opps;

		DF.requeryResults(result,new Set<String>{'rss','revs'});
		// Set up budget for Revenue item
		Rev__c rev = result.revs.values()[0];
		rev.QuantityBooked__c = DAILY_IMPRESSION_COUNT * REVENUE_BUDGET_IN_DAYS;
		update rev;

		// Set up metrics for first RS
		RS__c rs1 = result.rss.values()[0];
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c < rs1.from_Date__c ? rs : rs1;
		addMetrics(rs1);

		// Assert if quantities & revenue calculated correctly
		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c <= rs1.from_Date__c ? rs : rs1;
		Integer numDaysInMonth = Date.daysInMonth(rs1.from_Date__c.year(),rs1.from_Date__c.month());

		// Quantities (RS): No overdelivery for first month, so billed = delivered
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs1.QuantityBilled__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs1.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs1.QuantityExpected__c);
		System.assertEquals(0, rs1.QuantityOverdelivered__c);

		// Revenues (RS): No overdelivery for first month, so billed = delivered
		System.assertEquals(0, rs1.RevenueOverdelivered__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPM_MULTIPLICATION_FACTOR, rs1.Revenue__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPM_MULTIPLICATION_FACTOR, rs1.InvoicingBalance__c); // CPM
		System.assertEquals('Invoicing Required', rs1.InvoicingStatus__c);

		// Revenue on Rev:
		rev = result.revs.values()[0];
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityBooked__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rev.QuantityDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityExpected__c);
		System.assertEquals(0, rev.QuantityOverdelivered__c);
		System.assertEquals(0, rev.RevenueOverdelivered__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Budget__c);

		// Generate invoice
		GW_Invoice.processBatch('ECGDKAD');
		Test.stopTest();

		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c <= rs1.from_Date__c ? rs : rs1;
		// Check RS
		System.assertEquals(0, rs1.InvoicingBalance__c); // CPM
		System.assertEquals('No Action Needed', rs1.InvoicingStatus__c); // CPM
		rev = result.revs.values()[0];
		System.assertEquals(numDaysInMonth * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.BilledTotal__c); // CPM

		// Get next RS & add metrics
		RS__c rs2;
		Integer rs2fromMonth = rs1.from_Date__c.addMonths(1).month();
		for(RS__c rs : result.rss.values()) rs2 = rs.from_Date__c.month() == rs2fromMonth ? rs : rs2;
		addMetrics(rs2);

		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs2 = rs.from_Date__c.month() == rs2fromMonth ? rs : rs2;
		numDaysInMonth = Date.daysInMonth(rs2.from_Date__c.year(),rs2.from_Date__c.month());

		// Validate RS2 - quantities
		System.assertNotEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs2.QuantityBilled__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs2.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs2.QuantityExpected__c);
		System.assertEquals(rs2.QuantityDelivered__c - rs2.QuantityBilled__c, rs2.QuantityOverdelivered__c);

		// Validate RS2 - revenues
		System.assertNotEquals(0,rs2.RevenueOverdelivered__c);
		System.assertNotEquals(0,rs2.Revenue__c);
		System.assertEquals(rs2.TotalDays__c*REVENUE_CPM_MULTIPLICATION_FACTOR - rs2.Revenue__c, rs2.RevenueOverdelivered__c);
		System.assertEquals(rs2.TotalDays__c*REVENUE_CPM_MULTIPLICATION_FACTOR - rs2.RevenueOverdelivered__c, rs2.Revenue__c);
		System.assertEquals(rs2.Revenue__c, rs2.InvoicingBalance__c); // CPM
		System.assertEquals('Invoicing Required', rs2.InvoicingStatus__c);

		// Validate revenue item changes
		rev = result.revs.values()[0];
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityBooked__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT + rs2.QuantityOverdelivered__c, rev.QuantityDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityExpected__c);
		System.assertEquals(rs2.QuantityOverdelivered__c, rev.QuantityOverdelivered__c); // CPM
		System.assertEquals(rs2.RevenueOverdelivered__c, rev.RevenueOverdelivered__c); // CPM
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Budget__c);
		UTIL_Log.end();
	}

	@isTest
	static void testQuantityCalcCPD() {
		UTIL_Log.start();
        Test.startTest();
		DF_Scenario.Result result = DF.queryResults(adSalesScenarios, usersAdsales, new Set<String> { 'oppMap' });

		// Opp below will be tested in next test method, deleting it simplifies this test A LOT
		List<Opportunity> opps = new List<Opportunity> { result.oppMap.get('ECGDKAD-01.Opportunity[1]'), result.oppMap.get('ECGDKAD-03.Opportunity[1]') };
		delete opps;

		DF.requeryResults(result,new Set<String>{'rss','revs'});

		// Set up budget for Revenue item
		Rev__c rev = result.revs.values()[0];
		rev.QuantityBooked__c = REVENUE_BUDGET_IN_DAYS;
		update rev;

		// Set up metrics for first RS
		RS__c rs1 = result.rss.values()[0];
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c < rs1.from_Date__c ? rs : rs1;
		addMetrics(rs1);

		// Assert if quantities & revenue calculated correctly
		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c <= rs1.from_Date__c ? rs : rs1;
		Integer numDaysInMonth = Date.daysInMonth(rs1.from_Date__c.year(),rs1.from_Date__c.month());

		// Quantities (RS): No overdelivery for first month, so billed = delivered
		System.assertEquals(numDaysInMonth, rs1.QuantityBilled__c);
		System.assertEquals(numDaysInMonth, rs1.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth, rs1.QuantityExpected__c);
		System.assertEquals(0, rs1.QuantityOverdelivered__c);

		// Revenues (RS): No overdelivery for first month, so billed = delivered
		System.assertEquals(0, rs1.RevenueOverdelivered__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPD_MULTIPLICATION_FACTOR, rs1.Revenue__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPD_MULTIPLICATION_FACTOR, rs1.InvoicingBalance__c); // CPM
		System.assertEquals('Invoicing Required', rs1.InvoicingStatus__c);

		// Revenue on Rev:
		rev = result.revs.values()[0];
		System.assertEquals(numDaysInMonth, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS, rev.QuantityBooked__c);
		System.assertEquals(numDaysInMonth, rev.QuantityDelivered__c);
		System.assertEquals(0, rev.QuantityOverdelivered__c);
		System.assertEquals(0, rev.RevenueOverdelivered__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPD_MULTIPLICATION_FACTOR, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPD_MULTIPLICATION_FACTOR, rev.Budget__c);

		// Generate invoice
		GW_Invoice.processBatch('ECGDKAD');
		Test.stopTest();

		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c <= rs1.from_Date__c ? rs : rs1;
		// Check RS
		System.assertEquals(0, rs1.InvoicingBalance__c); // CPM
		System.assertEquals('No Action Needed', rs1.InvoicingStatus__c); // CPM
		rev = result.revs.values()[0];
		System.assertEquals(numDaysInMonth * REVENUE_CPD_MULTIPLICATION_FACTOR, rev.BilledTotal__c); // CPM

		// Get next RS & add metrics
		RS__c rs2;
		Integer rs2fromMonth = rs1.from_Date__c.addMonths(1).month();
		for(RS__c rs : result.rss.values()) rs2 = rs.from_Date__c.month() == rs2fromMonth ? rs : rs2;
		addMetrics(rs2);

		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs2 = rs.from_Date__c.month() == rs2fromMonth ? rs : rs2;
		numDaysInMonth = Date.daysInMonth(rs2.from_Date__c.year(),rs2.from_Date__c.month());

		// Validate RS2 - quantities
		System.assertNotEquals(numDaysInMonth, rs2.QuantityBilled__c);
		System.assertEquals(numDaysInMonth, rs2.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth, rs2.QuantityExpected__c);
		System.assertEquals(rs2.QuantityDelivered__c - rs2.QuantityBilled__c, rs2.QuantityOverdelivered__c);

		// Validate RS2 - revenues
		System.assertNotEquals(0,rs2.RevenueOverdelivered__c);
		System.assertNotEquals(0,rs2.Revenue__c);
		System.assertEquals(rs2.TotalDays__c * REVENUE_CPD_MULTIPLICATION_FACTOR - rs2.Revenue__c, rs2.RevenueOverdelivered__c);
		System.assertEquals(rs2.TotalDays__c * REVENUE_CPD_MULTIPLICATION_FACTOR - rs2.RevenueOverdelivered__c, rs2.Revenue__c);
		System.assertEquals(rs2.Revenue__c, rs2.InvoicingBalance__c); // CPM
		System.assertEquals('Invoicing Required', rs2.InvoicingStatus__c);

		// Validate revenue item changes
		rev = result.revs.values()[0];
		System.assertEquals(REVENUE_BUDGET_IN_DAYS, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS, rev.QuantityBooked__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS + rs2.QuantityOverdelivered__c, rev.QuantityDelivered__c);
		System.assertEquals(rs2.QuantityOverdelivered__c, rev.QuantityOverdelivered__c); // CPD
		System.assertEquals(rs2.RevenueOverdelivered__c, rev.RevenueOverdelivered__c); // CPD
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPD_MULTIPLICATION_FACTOR, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPD_MULTIPLICATION_FACTOR, rev.Budget__c);
		UTIL_Log.end();
	}

	@isTest
	static void testQuantityCalcCPC() {
		UTIL_Log.start();
        Test.startTest();
		DF_Scenario.Result result = DF.queryResults(adSalesScenarios, usersAdsales, new Set<String> { 'oppMap' });

		// Opp below will be tested in next test method, deleting it simplifies this test A LOT
		List<Opportunity> opps = new List<Opportunity> { result.oppMap.get('ECGDKAD-01.Opportunity[1]'), result.oppMap.get('ECGDKAD-02.Opportunity[1]') };
		delete opps;

		DF.requeryResults(result,new Set<String>{'rss','revs'});

		// Set up budget for Revenue item
		Rev__c rev = result.revs.values()[0];
		rev.QuantityBooked__c = REVENUE_BUDGET_IN_DAYS * DAILY_CLICK_COUNT;
		update rev;

		// Set up metrics for first RS
		RS__c rs1 = result.rss.values()[0];
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c < rs1.from_Date__c ? rs : rs1;
		addMetricsCPC(rs1);

		// Assert if quantities & revenue calculated correctly
		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c <= rs1.from_Date__c ? rs : rs1;
		Integer numDaysInMonth = Date.daysInMonth(rs1.from_Date__c.year(),rs1.from_Date__c.month());

		// Quantities (RS): No overdelivery for first month, so billed = delivered
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT, rs1.QuantityBilled__c);
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT, rs1.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT, rs1.QuantityExpected__c);
		System.assertEquals(0, rs1.QuantityOverdelivered__c);

		// Revenues (RS): No overdelivery for first month, so billed = delivered
		System.assertEquals(0, rs1.RevenueOverdelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT * rs1.UnitPrice__c, rs1.Revenue__c);
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT * rs1.UnitPrice__c, rs1.InvoicingBalance__c); // CPM
		System.assertEquals('Invoicing Required', rs1.InvoicingStatus__c);

		// Revenue on Rev:
		rev = result.revs.values()[0];
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_CLICK_COUNT, rev.QuantityBooked__c);
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT, rev.QuantityDelivered__c);
		System.assertEquals(0, rev.QuantityOverdelivered__c);
		System.assertEquals(0, rev.RevenueOverdelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT * rev.UnitPrice__c, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_CLICK_COUNT * rev.UnitPrice__c, rev.Budget__c);

		// Generate invoice
		GW_Invoice.processBatch('ECGDKAD');
		Test.stopTest();

		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c <= rs1.from_Date__c ? rs : rs1;
		// Check RS
		System.assertEquals(0, rs1.InvoicingBalance__c); // CPM
		System.assertEquals('No Action Needed', rs1.InvoicingStatus__c); // CPM
		rev = result.revs.values()[0];
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT * rev.UnitPrice__c, rev.BilledTotal__c); // CPM

		// Get next RS & add metrics
		RS__c rs2;
		Integer rs2fromMonth = rs1.from_Date__c.addMonths(1).month();
		for(RS__c rs : result.rss.values()) rs2 = rs.from_Date__c.month() == rs2fromMonth ? rs : rs2;
		addMetricsCPC(rs2);

		DF.requeryResults(result,new Set<String>{'rss','revs','metrics'});
		for(RS__c rs : result.rss.values()) rs2 = rs.from_Date__c.month() == rs2fromMonth ? rs : rs2;
		numDaysInMonth = Date.daysInMonth(rs2.from_Date__c.year(),rs2.from_Date__c.month());

		// Validate RS2 - quantities
		System.assertNotEquals(numDaysInMonth * DAILY_CLICK_COUNT, rs2.QuantityBilled__c);
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT, rs2.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_CLICK_COUNT, rs2.QuantityExpected__c);
		System.assertEquals(rs2.QuantityDelivered__c - rs2.QuantityBilled__c, rs2.QuantityOverdelivered__c);

		// Validate RS2 - revenues
		System.assertNotEquals(0,rs2.RevenueOverdelivered__c);
		System.assertNotEquals(0,rs2.Revenue__c);
		System.assertEquals(rs2.TotalDays__c * DAILY_CLICK_COUNT * rev.UnitPrice__c - rs2.Revenue__c, rs2.RevenueOverdelivered__c);
		System.assertEquals(rs2.TotalDays__c * DAILY_CLICK_COUNT * rev.UnitPrice__c - rs2.RevenueOverdelivered__c, rs2.Revenue__c);
		System.assertEquals(rs2.Revenue__c, rs2.InvoicingBalance__c); // CPC
		System.assertEquals('Invoicing Required', rs2.InvoicingStatus__c);

		// Validate revenue item changes
		rev = result.revs.values()[0];
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_CLICK_COUNT, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_CLICK_COUNT, rev.QuantityBooked__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_CLICK_COUNT + rs2.QuantityOverdelivered__c, rev.QuantityDelivered__c);
		System.assertEquals(rs2.QuantityOverdelivered__c, rev.QuantityOverdelivered__c); // CPC
		System.assertEquals(rs2.RevenueOverdelivered__c, rev.RevenueOverdelivered__c); // CPC
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_CLICK_COUNT * rev.UnitPrice__c, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_CLICK_COUNT * rev.UnitPrice__c, rev.Budget__c);

		UTIL_Log.end();
	}

	@isTest
    static void testOverdelivery() {
		UTIL_Log.start();
        Test.startTest();
		DF_Scenario.Result result = DF.queryResults(adSalesScenarios, usersAdsales, new Set<String> { 'users', 'oppMap' });

		// Opp below will be tested in next test method, deleting it simplifies this test A LOT
		List<Opportunity> opps = new List<Opportunity> { result.oppMap.get('ECGDKAD-02.Opportunity[1]'), result.oppMap.get('ECGDKAD-03.Opportunity[1]') };
		delete opps;
		DF.requeryResults(result,new Set<String>{'rss','revs'});
		// Set up budget for Revenue item
		Rev__c rev = result.revs.values()[0];
		rev.QuantityBooked__c = DAILY_IMPRESSION_COUNT * REVENUE_BUDGET_IN_DAYS;
		update rev;

		// Set up metrics for first RS
		RS__c rs1 = result.rss.values()[0];
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c < rs1.from_Date__c ? rs : rs1;
		addMetrics(rs1);

		// Assert if quantities & revenue calculated correctly
		DF.requeryResults(result,new Set<String>{'rss','revs'});
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c <= rs1.from_Date__c ? rs : rs1;
		Integer numDaysInMonth = Date.daysInMonth(rs1.from_Date__c.year(),rs1.from_Date__c.month());

		// Quantities (RS): No overdelivery for first month, so billed = delivered
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs1.QuantityBilled__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs1.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs1.QuantityExpected__c);
		System.assertEquals(0, rs1.QuantityOverdelivered__c);

		// Revenues (RS): No overdelivery for first month, so billed = delivered
		System.assertEquals(0, rs1.RevenueOverdelivered__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPM_MULTIPLICATION_FACTOR, rs1.Revenue__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPM_MULTIPLICATION_FACTOR, rs1.InvoicingBalance__c); // CPM
		System.assertEquals('Invoicing Required', rs1.InvoicingStatus__c);

		// Revenue on Rev:
		rev = result.revs.values()[0];
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityBooked__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rev.QuantityDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityExpected__c);
		System.assertEquals(0, rev.QuantityOverdelivered__c);
		System.assertEquals(0, rev.RevenueOverdelivered__c);
		System.assertEquals(numDaysInMonth * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Budget__c);

		// Generate invoice

		GW_Invoice.processBatch('ECGDKAD');
		Test.stopTest();

		DF.requeryResults(result,new Set<String>{'rss','revs'});
		for(RS__c rs : result.rss.values()) rs1 = rs.from_Date__c <= rs1.from_Date__c ? rs : rs1;
		// Check RS
		System.assertEquals(0, rs1.InvoicingBalance__c); // CPM
		System.assertEquals('No Action Needed', rs1.InvoicingStatus__c); // CPM
		rev = result.revs.values()[0];
		System.assertEquals(numDaysInMonth * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.BilledTotal__c); // CPM

		// Get next RS & add metrics
		RS__c rs2;
		Integer rs2fromMonth = rs1.from_Date__c.addMonths(1).month();
		for(RS__c rs : result.rss.values()) rs2 = rs.from_Date__c.month() == rs2fromMonth ? rs : rs2;
		addMetrics(rs2);

		DF.requeryResults(result,new Set<String>{'rss','revs'});
		for(RS__c rs : result.rss.values()) rs2 = rs.from_Date__c.month() == rs2fromMonth ? rs : rs2;
		numDaysInMonth = Date.daysInMonth(rs2.from_Date__c.year(),rs2.from_Date__c.month());

		// Validate RS2 - quantities
		System.assertNotEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs2.QuantityBilled__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs2.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs2.QuantityExpected__c);
		System.assertEquals(rs2.QuantityDelivered__c - rs2.QuantityBilled__c, rs2.QuantityOverdelivered__c);

		// Validate RS2 - revenues
		System.assertNotEquals(0,rs2.RevenueOverdelivered__c);
		System.assertNotEquals(0,rs2.Revenue__c);
		System.assertEquals(rs2.TotalDays__c*REVENUE_CPM_MULTIPLICATION_FACTOR - rs2.Revenue__c, rs2.RevenueOverdelivered__c);
		System.assertEquals(rs2.TotalDays__c*REVENUE_CPM_MULTIPLICATION_FACTOR - rs2.RevenueOverdelivered__c, rs2.Revenue__c);
		System.assertEquals(rs2.Revenue__c, rs2.InvoicingBalance__c); // CPM
		System.assertEquals('Invoicing Required', rs2.InvoicingStatus__c);

		// Validate revenue item changes
		rev = result.revs.values()[0];
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityBooked__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT + rs2.QuantityOverdelivered__c, rev.QuantityDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityExpected__c);
		System.assertEquals(rs2.QuantityOverdelivered__c, rev.QuantityOverdelivered__c); // CPM
		System.assertEquals(rs2.RevenueOverdelivered__c, rev.RevenueOverdelivered__c); // CPM
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Budget__c);

		RS__c rs3;
		Integer rs3fromMonth = rs1.from_Date__c.addMonths(2).month();
		for(RS__c rs : result.rss.values()) rs3 = rs.from_Date__c.month() == rs3fromMonth ? rs : rs3;
		numDaysInMonth = Date.daysInMonth(rs3.from_Date__c.year(),rs3.from_Date__c.month());
		addMetrics(rs3);

		DF.requeryResults(result,new Set<String>{'rss','revs'});
		for(RS__c rs : result.rss.values()) rs3 = rs.from_Date__c.month() == rs3fromMonth ? rs : rs3;

		// Validate RS3 - quantities
		System.assertEquals(0, rs3.QuantityBilled__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs3.QuantityDelivered__c);
		System.assertEquals(numDaysInMonth * DAILY_IMPRESSION_COUNT, rs3.QuantityExpected__c);
		System.assertEquals(rs3.QuantityDelivered__c - rs3.QuantityBilled__c, rs3.QuantityOverdelivered__c);
		System.assertEquals(rs3.QuantityDelivered__c, rs3.QuantityOverdelivered__c);

		// Validate RS3 - revenues
		System.assertEquals(rs3.TotalDays__c * REVENUE_CPM_MULTIPLICATION_FACTOR, rs3.RevenueOverdelivered__c);
		System.assertEquals(0,rs3.Revenue__c);
		System.assertEquals(rs3.Revenue__c, rs3.InvoicingBalance__c);
		System.assertEquals('No Action Needed', rs3.InvoicingStatus__c);

		// Validate revenue item changes
		rev = result.revs.values()[0];
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityBilled__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityBooked__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT + rs2.QuantityOverdelivered__c + rs3.QuantityOverdelivered__c, rev.QuantityDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * DAILY_IMPRESSION_COUNT, rev.QuantityExpected__c);
		System.assertEquals(rs2.QuantityOverdelivered__c + rs3.QuantityOverdelivered__c, rev.QuantityOverdelivered__c); // CPM
		System.assertEquals(rs2.RevenueOverdelivered__c + rs3.RevenueOverdelivered__c, rev.RevenueOverdelivered__c); // CPM
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Revenue__c);
		System.assertEquals(rev.Budget__c - rev.Revenue__c, rev.RevenueToBeDelivered__c);
		System.assertEquals(0, rev.RevenueToBeDelivered__c);
		System.assertEquals(REVENUE_BUDGET_IN_DAYS * REVENUE_CPM_MULTIPLICATION_FACTOR, rev.Budget__c);

		UTIL_Log.end();
	}
}