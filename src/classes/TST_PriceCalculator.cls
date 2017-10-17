@isTest
public class TST_PriceCalculator extends TSTDF_Base {

	public static TST_PriceCalculator factory = new TST_PriceCalculator();

	@testSetup
	static void setup() {
		UTIL.isRunningTestSetup = true;
		factory.createTestSet();
		UTIL.isRunningTestSetup = false;
	}

	private static void prepareProductSetupForCalculator(String priceCalcType) {
		if (priceCalcType == 'AdSalesFixed') {
			generateAdSalesFixedProductsAndPricebooks();
		} else if (priceCalcType == 'Default') {
			generateDefaultProductsAndPricebooks();
		} else if (priceCalcType == 'IterativeTiered') {
			generateIterativeTieredProductsAndPricebooks();
		} else if (priceCalcType == 'FixedTiered') {
			generateFixedTieredProductsAndPricebooks();
		} else if (priceCalcType == 'UnlimitedFixed') {
			generateUnlimitedFixedProductsAndPricebooks();
		} else { }
	}

	@isTest static void testApplyPriceModelOliAdSalesFixed() {
		factory.queryResults(new Set<String> { 'opps' });
		prepareProductSetupForCalculator('AdSalesFixed');
		factory.queryResults(new Set<String> { 'opps', 'olis' });
		Test.startTest();
		System.runAs(factory.data.testUsers.get('testUser')) {
			// Price model will be applied automatically
			OpportunityLineItem oli = ((List<OpportunityLineItem>) LCC_ProductConfigurator.getNewOpportunityLineItem(factory.data.opps[0].Id, factory.data.olis[0].PricebookEntryId).content) [0];

			// Assert after applyging the price model
			System.assertEquals('10.00', String.valueOf(oli.ListPrice__c));
			System.assertEquals('CPM', oli.Billing_Category__c);
			System.assertEquals('DailyFixed', oli.BillingCalc__c);
			System.assertEquals('0.001', String.valueOf(oli.UPCF__c));
			System.assertEquals('1000', String.valueOf(oli.Quantity));
			System.assertEquals('10.00', String.valueOf(oli.SalesPriceNet__c));
			System.assertEquals('10.00', String.valueOf(oli.UnitPrice));
			System.assertEquals('AdSalesFixed', oli.PriceCalculator__c);
			System.assertEquals('0.00', String.valueOf(oli.ContractDiscount__c));
		}
		Test.stopTest();
	}

	@isTest static void testApplyPriceModelOliUnlimitedFixed() {
		factory.queryResults(new Set<String> { 'opps' });
		prepareProductSetupForCalculator('UnlimitedFixed');
		factory.queryResults(new Set<String> { 'opps', 'olis' });
		Test.startTest();
		System.runAs(factory.data.testUsers.get('testUser')) {
			// Price model will be applied automatically
			OpportunityLineItem oli = ((List<OpportunityLineItem>) LCC_ProductConfigurator.getNewOpportunityLineItem(factory.data.opps[0].Id, factory.data.olis[0].PricebookEntryId).content) [0];

			// Assert after applyging the price model
			System.assertEquals('99.00', String.valueOf(oli.ListPrice__c));
			System.assertEquals('Subscription', oli.Billing_Category__c);
			System.assertEquals('MonthlyProRata', oli.BillingCalc__c);
			System.assertEquals('1', String.valueOf(oli.UPCF__c));
			System.assertEquals('1', String.valueOf(oli.Quantity));
			System.assertEquals('99.00', String.valueOf(oli.SalesPriceNet__c));
			System.assertEquals('99.00', String.valueOf(oli.UnitPrice));
			System.assertEquals('UnlimitedFixed', oli.PriceCalculator__c);
			System.assertEquals('99.00', String.valueOf(oli.CustomListPrice__c));
			System.assertEquals('0.00', String.valueOf(oli.ContractDiscount__c));
		}
		Test.stopTest();
	}

	@isTest static void testApplyPriceModelOliDefault() {
		factory.queryResults(new Set<String> { 'opps' });
		prepareProductSetupForCalculator('Default');
		factory.queryResults(new Set<String> { 'opps', 'olis' });
		Test.startTest();
		System.runAs(factory.data.testUsers.get('testUser')) {
			// Price model will be applied automatically
			OpportunityLineItem oli = ((List<OpportunityLineItem>) LCC_ProductConfigurator.getNewOpportunityLineItem(factory.data.opps[0].Id, factory.data.olis[0].PricebookEntryId).content) [0];

			// Assert after applyging the price model
			System.assertEquals('10.00', String.valueOf(oli.ListPrice__c));
			System.assertEquals('CPD', oli.Billing_Category__c);
			System.assertEquals('DailyFixed', oli.BillingCalc__c);
			System.assertEquals('1', String.valueOf(oli.UPCF__c));
			System.assertEquals('1', String.valueOf(oli.Quantity));
			System.assertEquals('10.00', String.valueOf(oli.SalesPriceNet__c));
			System.assertEquals('10.00', String.valueOf(oli.UnitPrice));
			System.assertEquals('Default', oli.PriceCalculator__c);
			System.assertEquals('0.00', String.valueOf(oli.ContractDiscount__c));
		}
		Test.stopTest();
	}

	@isTest static void testApplyPriceModelOliIterativeTiered() {
		factory.queryResults(new Set<String> { 'opps' });
		prepareProductSetupForCalculator('IterativeTiered');
		factory.queryResults(new Set<String> { 'opps', 'olis' });
		Test.startTest();
		System.runAs(factory.data.testUsers.get('testUser')) {
			// Price model will be applied automatically
			OpportunityLineItem oli = ((List<OpportunityLineItem>) LCC_ProductConfigurator.getNewOpportunityLineItem(factory.data.opps[0].Id, factory.data.olis[0].PricebookEntryId).content) [0];
			oli.BundleSize__c = 10;
			upsert oli;

			// Assert after applyging the price model
			System.assertEquals('10.00', String.valueOf(oli.ListPrice__c));
			System.assertEquals('Subscription', oli.Billing_Category__c);
			System.assertEquals('MonthlyProRata', oli.BillingCalc__c);
			System.assertEquals('10', String.valueOf(oli.BundleSize__c));
			System.assertEquals('1', String.valueOf(oli.UPCF__c));
			System.assertEquals('1', String.valueOf(oli.Quantity));
			System.assertEquals('10.00', String.valueOf(oli.SalesPriceNet__c));
			System.assertEquals('10.00', String.valueOf(oli.UnitPrice));
			System.assertEquals('IterativeTiered', oli.PriceCalculator__c);
			System.assertEquals('10.00', String.valueOf(oli.CustomListPrice__c));
			System.assertEquals('0.00', String.valueOf(oli.ContractDiscount__c));
		}
		Test.stopTest();
	}

	@isTest static void testApplyPriceModelOliFixedTiered() {
		factory.queryResults(new Set<String> { 'opps' });
		prepareProductSetupForCalculator('FixedTiered');
		factory.queryResults(new Set<String> { 'opps', 'olis' });
		Test.startTest();
		System.runAs(factory.data.testUsers.get('testUser')) {
			// Price model will be applied automatically
			OpportunityLineItem oli = ((List<OpportunityLineItem>) LCC_ProductConfigurator.getNewOpportunityLineItem(factory.data.opps[0].Id, factory.data.olis[0].PricebookEntryId).content) [0];
			oli.BundleSize__c = 10;
			upsert oli;

			// Assert after applying the price model
			System.assertEquals('100', String.valueOf(oli.ListPrice__c));
			System.assertEquals('Subscription', oli.Billing_Category__c);
			System.assertEquals('MonthlyProRata', oli.BillingCalc__c);
			System.assertEquals('10', String.valueOf(oli.BundleSize__c));
			System.assertEquals('1', String.valueOf(oli.UPCF__c));
			System.assertEquals('1', String.valueOf(oli.Quantity));
			System.assertEquals('100.00', String.valueOf(oli.SalesPriceNet__c));
			System.assertEquals('100.00', String.valueOf(oli.UnitPrice));
			System.assertEquals('FixedTiered', oli.PriceCalculator__c);
			System.assertEquals('100.00', String.valueOf(oli.CustomListPrice__c));
			System.assertEquals('0.00', String.valueOf(oli.ContractDiscount__c));
		}
		Test.stopTest();
	}

	@isTest static void testApplyContractAccountDiscountOliFixedTiered() {
		UTIL.isRunningTestSetup = true;
		factory.queryResults(new Set<String> { 'opps', 'accounts' });
		prepareProductSetupForCalculator('FixedTiered');
	
		// Update account and contract level discounts
		factory.data.opps[0].ContractDiscount__c = 20;
	
		update factory.data.accounts[0];
		update factory.data.opps[0];
	
		factory.queryResults(new Set<String> { 'opps', 'olis' });
		UTIL.isRunningTestSetup = false;
		
		Test.startTest();
		System.runAs(factory.data.testUsers.get('testUser')) {
			// Price model will be applied automatically
			OpportunityLineItem oli = ((List<OpportunityLineItem>) LCC_ProductConfigurator.getNewOpportunityLineItem(factory.data.opps[0].Id, factory.data.olis[0].PricebookEntryId).content) [0];

			// Assert after applyging the price model
			System.assertEquals('100', String.valueOf(oli.ListPrice__c));
			System.assertEquals('Subscription', oli.Billing_Category__c);
			System.assertEquals('MonthlyProRata', oli.BillingCalc__c);
			System.assertEquals('1', String.valueOf(oli.UPCF__c));
			System.assertEquals('1', String.valueOf(oli.Quantity));
			System.assertEquals('80.00', String.valueOf(oli.SalesPriceNet__c));
			System.assertEquals('80.00', String.valueOf(oli.UnitPrice));
			System.assertEquals('FixedTiered', oli.PriceCalculator__c);
			System.assertEquals('80.00', String.valueOf(oli.CustomListPrice__c));
			System.assertEquals('20.00', String.valueOf(oli.ContractDiscount__c));
		}
		Test.stopTest();
	}

	// ## DATA GENERATION - RELATED ##

	public override void insertProducts() { }

	public override void insertPricebookEntries() { }

	private static void generateAdSalesFixedProductsAndPricebooks() {
		Opportunity opp = factory.data.opps[0];
		Pricebook2 pb = new Pricebook2(
		                               Name = 'EBAYKRE_2015',
		                               Description = 'Kleinanzeigen 2015',
		                               IsActive = true
		);
		insert pb;
		Product2 p1 = new Product2(
		                           Name = 'Paket S (10 Anzeigen pro Monat)',
		                           ProductCode = 'KA_RE',
		                           IsActive = true,
		                           CurrencyIsoCode = 'EUR',
		                           Product_Type__c = 'KA-RealEstate',
		                           Billing_Category__c = 'CPM_DailyFixed',
		                           CommittedPeriodInMonths__c = 6,
		                           ContractPeriodInMonths__c = 12,
		                           DefaultLineDescription__c = '{{Indirect_Prefix__c}} {{ProductName__c}}',
		                           PriceModelPriceCorrection__c = 0.00,
		                           AutoExtend__c = true,
		                           ScheduleAheadTerm__c = 12,
		                           CPM_Price__c = 10,
		                           CPD_Price__c = 10,
		                           CPC_Price__c = 10
		);
		insert p1;
		PricebookEntry spbe1 = new PricebookEntry(
		                                          Pricebook2Id = Test.getStandardPricebookId(),
		                                          Product2Id = p1.Id,
		                                          CurrencyIsoCode = 'EUR',
		                                          UnitPrice = 99,
		                                          IsActive = true
		);
		insert spbe1;
		PricebookEntry pbe1 = new PricebookEntry(
		                                         Pricebook2Id = pb.Id,
		                                         Product2Id = p1.Id,
		                                         CurrencyIsoCode = 'EUR',
		                                         UnitPrice = 99.00,
		                                         IsActive = true,
		                                         UseStandardPrice = false,
		                                         Fixed_PricePerMonth__c = 99.00,
		                                         DefaultAdjustmentFixed__c = - 50.00,
		                                         DefaultAdjustmentPercentage__c = 0,
		                                         PriceCalculator__c = 'AdSalesFixed'
		);
		insert pbe1;

		opp.Pricebook2Id = pb.Id;
		opp.CurrencyIsoCode = 'EUR';
		upsert opp;

		generateOppLineItems(opp, pbe1, TST_DataFactory.startOli1, TST_DataFactory.endOli1, TST_DataFactory.startOli2, TST_DataFactory.endOli2);
	}

	private static void generateUnlimitedFixedProductsAndPricebooks() {
		Opportunity opp = factory.data.opps[0];
		Pricebook2 pb = new Pricebook2(
		                               Name = 'EBAYKRE_2015',
		                               Description = 'Kleinanzeigen 2015',
		                               IsActive = true
		);
		insert pb;
		Product2 p1 = new Product2(
		                           Name = 'Paket S (10 Anzeigen pro Monat)',
		                           ProductCode = 'KA_RE',
		                           IsActive = true,
		                           CurrencyIsoCode = 'EUR',
		                           Product_Type__c = 'KA-RealEstate',
		                           Billing_Category__c = 'Subscription_MonthlyProRata',
		                           CommittedPeriodInMonths__c = 6,
		                           ContractPeriodInMonths__c = 12,
		                           DefaultLineDescription__c = '{{Indirect_Prefix__c}} {{ProductName__c}}',
		                           PriceModelPriceCorrection__c = 0.00,
		                           AutoExtend__c = true,
		                           ScheduleAheadTerm__c = 12,
		                           CPM_Price__c = 10,
		                           CPD_Price__c = 10,
		                           CPC_Price__c = 10
		);
		insert p1;
		PricebookEntry spbe1 = new PricebookEntry(
		                                          Pricebook2Id = Test.getStandardPricebookId(),
		                                          Product2Id = p1.Id,
		                                          CurrencyIsoCode = 'EUR',
		                                          UnitPrice = 99,
		                                          IsActive = true
		);
		insert spbe1;
		PricebookEntry pbe1 = new PricebookEntry(
		                                         Pricebook2Id = pb.Id,
		                                         Product2Id = p1.Id,
		                                         CurrencyIsoCode = 'EUR',
		                                         UnitPrice = 99.00,
		                                         IsActive = true,
		                                         UseStandardPrice = false,
		                                         Fixed_PricePerMonth__c = 99.00,
		                                         DefaultAdjustmentFixed__c = - 50.00,
		                                         DefaultAdjustmentPercentage__c = 0,
		                                         PriceCalculator__c = 'UnlimitedFixed'
		);
		insert pbe1;

		opp.Pricebook2Id = pb.Id;
		opp.CurrencyIsoCode = 'EUR';
		upsert opp;

		generateOppLineItems(opp, pbe1, TST_DataFactory.startOli1, TST_DataFactory.endOli1, TST_DataFactory.startOli2, TST_DataFactory.endOli2);
	}

	private static void generateDefaultProductsAndPricebooks() {
		Opportunity opp = factory.data.opps[0];
		Pricebook2 pb = new Pricebook2(
		                               Name = 'EBAYKRE_2015',
		                               Description = 'Kleinanzeigen 2015',
		                               IsActive = true
		);
		insert pb;

		Product2 p1 = new Product2(
		                           Name = 'Paket S (10 Anzeigen pro Monat)',
		                           ProductCode = 'KA_RE',
		                           IsActive = true,
		                           CurrencyIsoCode = 'EUR',
		                           Product_Type__c = 'KA-RealEstate',
		                           Billing_Category__c = 'CPD_DailyFixed',
		                           CommittedPeriodInMonths__c = 6,
		                           ContractPeriodInMonths__c = 12,
		                           DefaultLineDescription__c = '{{Indirect_Prefix__c}} {{ProductName__c}}',
		                           PriceModelPriceCorrection__c = 0.00,
		                           AutoExtend__c = true,
		                           ScheduleAheadTerm__c = 12,
		                           CPM_Price__c = 10,
		                           CPD_Price__c = 10,
		                           CPC_Price__c = 10
		);

		insert p1;

		PricebookEntry spbe1 = new PricebookEntry(
		                                          Pricebook2Id = Test.getStandardPricebookId(),
		                                          Product2Id = p1.Id,
		                                          CurrencyIsoCode = 'EUR',
		                                          UnitPrice = 99,
		                                          IsActive = true
		);

		insert spbe1;

		PricebookEntry pbe1 = new PricebookEntry(
		                                         Pricebook2Id = pb.Id,
		                                         Product2Id = p1.Id,
		                                         CurrencyIsoCode = 'EUR',
		                                         UnitPrice = 99.00,
		                                         IsActive = true,
		                                         UseStandardPrice = false,
		                                         Fixed_PricePerMonth__c = 99.00,
		                                         DefaultAdjustmentFixed__c = - 50.00,
		                                         DefaultAdjustmentPercentage__c = 0,
		                                         PriceCalculator__c = 'Default'
		);

		insert pbe1;

		opp.Pricebook2Id = pb.Id;
		opp.CurrencyIsoCode = 'EUR';
		upsert opp;

		generateOppLineItems(opp, pbe1, TST_DataFactory.startOli1, TST_DataFactory.endOli1, TST_DataFactory.startOli2, TST_DataFactory.endOli2);
	}

	private static void generateIterativeTieredProductsAndPricebooks() {
		Opportunity opp = factory.data.opps[0];
		Pricebook2 pb = new Pricebook2(
		                               Name = 'EBAYKRE_2015',
		                               Description = 'Kleinanzeigen 2015',
		                               IsActive = true
		);
		insert pb;
		Product2 p1 = new Product2(
		                           Name = 'Paket S (10 Anzeigen pro Monat)',
		                           ProductCode = 'KA_RE',
		                           IsActive = true,
		                           CurrencyIsoCode = 'EUR',
		                           Product_Type__c = 'KA-RealEstate',
		                           Billing_Category__c = 'Subscription_MonthlyProRata',
		                           CommittedPeriodInMonths__c = 6,
		                           ContractPeriodInMonths__c = 12,
		                           DefaultLineDescription__c = '{{Indirect_Prefix__c}} {{ProductName__c}}',
		                           PriceModelPriceCorrection__c = 0.00,
		                           AutoExtend__c = true,
		                           ScheduleAheadTerm__c = 12,
		                           CPM_Price__c = 10,
		                           CPD_Price__c = 10,
		                           CPC_Price__c = 10
		);
		insert p1;
		PricebookEntry spbe1 = new PricebookEntry(
		                                          Pricebook2Id = Test.getStandardPricebookId(),
		                                          Product2Id = p1.Id,
		                                          CurrencyIsoCode = 'EUR',
		                                          UnitPrice = 99,
		                                          IsActive = true
		);
		insert spbe1;
		PricebookEntry pbe1 = new PricebookEntry(
		                                         Pricebook2Id = pb.Id,
		                                         Product2Id = p1.Id,
		                                         CurrencyIsoCode = 'EUR',
		                                         UnitPrice = 99.00,
		                                         IsActive = true,
		                                         UseStandardPrice = false,
		                                         Fixed_PricePerMonth__c = 99.00,
		                                         DefaultAdjustmentFixed__c = - 50.00,
		                                         DefaultAdjustmentPercentage__c = 0,
		                                         PriceCalculator__c = 'IterativeTiered',
		                                         FixedTiered_JSON__c = '{ "10" : "100", "20" : "200", "30" : "300" }',
		                                         Tiered_TierCorrection__c = 10,
		                                         Tiered_OffsetPrice__c = 10
		);
		insert pbe1;

		opp.Pricebook2Id = pb.Id;
		opp.CurrencyIsoCode = 'EUR';
		upsert opp;

		generateOppLineItems(opp, pbe1, TST_DataFactory.startOli1, TST_DataFactory.endOli1, TST_DataFactory.startOli2, TST_DataFactory.endOli2);
	}

	private static void generateFixedTieredProductsAndPricebooks() {
		Opportunity opp = factory.data.opps[0];
		Pricebook2 pb = new Pricebook2(
		                               Name = 'EBAYKRE_2015',
		                               Description = 'Kleinanzeigen 2015',
		                               IsActive = true
		);
		insert pb;
		Product2 p1 = new Product2(
		                           Name = 'Paket S (10 Anzeigen pro Monat)',
		                           ProductCode = 'KA_RE',
		                           IsActive = true,
		                           CurrencyIsoCode = 'EUR',
		                           Product_Type__c = 'KA-RealEstate',
		                           Billing_Category__c = 'Subscription_MonthlyProRata',
		                           CommittedPeriodInMonths__c = 6,
		                           ContractPeriodInMonths__c = 12,
		                           DefaultLineDescription__c = '{{Indirect_Prefix__c}} {{ProductName__c}}',
		                           PriceModelPriceCorrection__c = 0.00,
		                           AutoExtend__c = true,
		                           ScheduleAheadTerm__c = 12,
		                           CPM_Price__c = 10,
		                           CPD_Price__c = 10,
		                           CPC_Price__c = 10
		);
		insert p1;
		PricebookEntry spbe1 = new PricebookEntry(
		                                          Pricebook2Id = Test.getStandardPricebookId(),
		                                          Product2Id = p1.Id,
		                                          CurrencyIsoCode = 'EUR',
		                                          UnitPrice = 99,
		                                          IsActive = true
		);
		insert spbe1;
		PricebookEntry pbe1 = new PricebookEntry(
		                                         Pricebook2Id = pb.Id,
		                                         Product2Id = p1.Id,
		                                         CurrencyIsoCode = 'EUR',
		                                         UnitPrice = 99.00,
		                                         IsActive = true,
		                                         UseStandardPrice = false,
		                                         Fixed_PricePerMonth__c = 99.00,
		                                         DefaultAdjustmentFixed__c = - 50.00,
		                                         DefaultAdjustmentPercentage__c = 0,
		                                         PriceCalculator__c = 'FixedTiered',
		                                         FixedTiered_JSON__c = '{ "10" : "100", "20" : "200", "30" : "300" }',
		                                         Tiered_TierCorrection__c = 10,
		                                         Tiered_OffsetPrice__c = 10
		);
		insert pbe1;

		opp.Pricebook2Id = pb.Id;
		opp.CurrencyIsoCode = 'EUR';
		upsert opp;

		generateOppLineItems(opp, pbe1, TST_DataFactory.startOli1, TST_DataFactory.endOli1, TST_DataFactory.startOli2, TST_DataFactory.endOli2);
	}

	private static void generateOppLineItems(Opportunity opp, PriceBookEntry pbe, Date period1Start, Date period1End, Date period2Start, Date period2End) {
		OpportunityLineItem oli1 = GW_OpportunityLineItem.createSObject(opp, pbe, 1, 10);
		OpportunityLineItem oli2 = GW_OpportunityLineItem.createSObject(opp, pbe, 1, 10);

		oli1.from_Date__c = period1Start;
		oli1.until_Date__c = period1End;
		oli1.Description = 'TST Description1';
		oli1.UniqueLineDescription__c = 'TSTUniqueLineDescription1';

		oli2.from_Date__c = period2Start;
		oli2.until_Date__c = period2End;
		oli2.Description = 'TST Description2';
		oli2.UniqueLineDescription__c = 'TSTUniqueLineDescription2';

		insert new List<OpportunityLineItem> { oli1, oli2 };
	}

}