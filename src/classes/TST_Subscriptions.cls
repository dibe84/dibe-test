@isTest
public class TST_Subscriptions extends TSTDF_Base {

    public static TST_Subscriptions factory = new TST_Subscriptions();

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }

    @isTest
    static void testPC() {
        factory.queryResults();

        system.runAs(factory.data.testUsers.get('testUser')){

            Id pricebookId = Test.getStandardPricebookId();
            PriceBook2 pb = new PriceBook2(name='Test');
            insert pb;

            Opportunity tOpp = new Opportunity(name='Testopp', Accountid = factory.data.accounts[0].id, CloseDate = system.today(), PriceBook2id = pricebookId, StageName='Draft');
            insert tOpp;
            Opportunity tOpp2 = new Opportunity(name='Testopp2', Accountid = factory.data.accounts[0].id, CloseDate = system.today(), PriceBook2id = NULL, StageName='Draft');
            insert tOpp2;

            list<Product2> prodList = new list<Product2>();
            prodList.add(new Product2(Name='Test Product1', ContractPeriodInMonths__c=6,Billing_Category__c='Subscription_MonthlyProRata', IsActive = TRUE));
            prodList.add(new Product2(Name='Test Product2', ContractPeriodInMonths__c=6,Billing_Category__c='Subscription_MonthlyProRata', IsActive = TRUE));
            prodList.add(new Product2(Name='Test Product3', ContractPeriodInMonths__c=6,Billing_Category__c='Subscription_MonthlyProRata', IsActive = TRUE));
            insert prodList;

            PricebookEntry pbeIterativeTiered = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(0).id, isActive = true, UnitPrice = 1000, UseStandardPrice=False, PriceCalculator__c = 'IterativeTiered', Tiered_OffsetPrice__c = 10, Tiered_AdditionalPrice__c = 5, Tiered_TierSize__c = 10);
            PricebookEntry pbeFixedTiered = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(1).id, isActive = true, UnitPrice = 1000, UseStandardPrice=False, PriceCalculator__c = 'FixedTiered', FixedTiered_JSON__c = '{"10":37,"20":70}');
            PricebookEntry pbeUnlimitedFixed = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(2).id, isActive = true, UnitPrice = 1000, UseStandardPrice=False, PriceCalculator__c = 'UnlimitedFixed', Fixed_PricePerMonth__c = 75);
            insert pbeFixedTiered;
            insert pbeIterativeTiered;
            insert pbeUnlimitedFixed;

            Test.startTest();
            PageReference ref = new PageReference('/apex/addsubscription?oppid=' + tOpp.id);
            Test.setCurrentPage(ref);
            OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = tOpp.Id, Quantity = 1.0);
            oli.PricebookEntryId = pbeIterativeTiered.Id;
            ApexPages.StandardController addsubscription = new ApexPages.StandardController(oli);
            PGC_Addsubscription addSubscriptionCon = new PGC_Addsubscription(addsubscription);

            /// Needs extra review! Is this correctly tested?
            addSubscriptionCon.redirect();
            addSubscriptionCon.getPBItems();
            addSubscriptionCon.getPBEItems();

            /// Test IterativeTiered
            addSubscriptionCon.oli.PricebookEntryId = pbeIterativeTiered.id;
            addSubscriptionCon.oli.BundleSize__c = 14;
            addSubscriptionCon.calculate();
            addSubscriptionCon.oli.BundleSize__c = 27;
            addSubscriptionCon.calculate();
            system.assertEquals(30, addSubscriptionCon.oli.BundleSize__c);
            system.assertEquals(20, addSubscriptionCon.oli.ListPrice__c);
            system.assertEquals('IterativeTiered', addSubscriptionCon.oli.PriceCalculator__c);

            addSubscriptionCon.save();
            list<ApexPages.Message> msg = ApexPages.getMessages();

            /// Test UnlimitedFix
            addSubscriptionCon.oli.BundleSize__c = 35;
            addSubscriptionCon.calculate();
            system.assertEquals(40, addSubscriptionCon.oli.BundleSize__c);
            system.assertEquals(25.00, addSubscriptionCon.oli.ListPrice__c);
            system.assertEquals('IterativeTiered', addSubscriptionCon.oli.PriceCalculator__c);

            addSubscriptionCon.save();
            msg = ApexPages.getMessages();

            /// Test FixedTiered
            addSubscriptionCon.oli.BundleSize__c = 10;
            addSubscriptionCon.calculate();
            addSubscriptionCon.oli.BundleSize__c = 20;
            addSubscriptionCon.calculate();
            system.assertEquals(20, addSubscriptionCon.oli.BundleSize__c);
            system.assertEquals(15.00, addSubscriptionCon.oli.ListPrice__c);
            system.assertEquals('IterativeTiered', addSubscriptionCon.oli.PriceCalculator__c);

            addSubscriptionCon.save();
            msg = ApexPages.getMessages();

            /// Save subscription
            addSubscriptionCon.oli.from_Date__c = system.today();
            addSubscriptionCon.calculateEndDate();
            addSubscriptionCon.save();

            // Recall page with saved oli
            list<OpportunityLineItem> olis = [SELECT id FROM OpportunityLineItem WHERE OpportunityId =: tOpp.id];
            system.assertEquals(1, olis.size());
            addsubscription = new ApexPages.StandardController(olis.get(0));
            addSubscriptionCon = new PGC_Addsubscription(addsubscription);

            Test.stopTest();
        }
    }

    @isTest
    static void testMultiMonthSubscription() {
        UTIL_Log.start();
        factory.queryResults();

        system.runAs(factory.data.testUsers.get('testUser')){

            Id pricebookId = Test.getStandardPricebookId();
            PriceBook2 pb = new PriceBook2(name='Test');
            insert pb;

            Opportunity tOpp = new Opportunity(name='Testopp', Accountid = factory.data.accounts[0].id, CloseDate = system.today(), PriceBook2id = pricebookId, StageName='Draft');
            insert tOpp;

            list<Product2> prodList = new list<Product2>();
            prodList.add(new Product2(Name='Test Product1', ContractPeriodInMonths__c=12, IsActive = TRUE, Billing_Category__c = 'Subscription_MultiMonth'));
            insert prodList;

            PricebookEntry pbeIterativeTiered = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodList.get(0).id, isActive = true, UnitPrice = 1000, UseStandardPrice=False, PriceCalculator__c = 'UnlimitedFixed', Fixed_PricePerMonth__c = 515.73);
            insert pbeIterativeTiered;

            Test.startTest();
            PageReference ref = new PageReference('/apex/addsubscription?oppid=' + tOpp.id);
            Test.setCurrentPage(ref);
            OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = tOpp.Id, Quantity = 1.0);
            oli.PricebookEntryId = pbeIterativeTiered.Id;
            ApexPages.StandardController addsubscription = new ApexPages.StandardController(oli);
            PGC_Addsubscription addSubscriptionCon = new PGC_Addsubscription(addsubscription);

            addSubscriptionCon.redirect();
            addSubscriptionCon.getPBItems();
            addSubscriptionCon.getPBEItems();

            /// Test IterativeTiered
            addSubscriptionCon.oli.PricebookEntryId = pbeIterativeTiered.id;
            addSubscriptionCon.oli.BundleSize__c = 27;
            addSubscriptionCon.calculate();
            system.assertEquals(27, addSubscriptionCon.oli.BundleSize__c);
            system.assertEquals(515.73, addSubscriptionCon.oli.ListPrice__c);
            system.assertEquals('UnlimitedFixed', addSubscriptionCon.oli.PriceCalculator__c);

            addSubscriptionCon.save();

            // Recall page with saved oli
            List<OpportunityLineItem> olis = [SELECT id FROM OpportunityLineItem WHERE OpportunityId =: tOpp.id];
            system.assertEquals(1, olis.size());

            tOpp = ((List<Opportunity>) GW_sObject.queryRecords('Opportunity','Id =\'' + tOpp.id + '\'')).get(0);
            tOpp.ContractStatus__c = 'Signed';
            tOpp.ApprovalStatus__c = 'Previously Approved';
            upsert tOpp;

            // Trigger rev item & rev schedule creation
            oli = olis.get(0);
            oli.ServiceDate = System.today();
            upsert oli;

            tOpp = ((List<Opportunity>) GW_sObject.queryRecords('Opportunity','Id =\'' + tOpp.id + '\'')).get(0);
            Map<Id,Rev__c> revMap = new Map<Id, Rev__c>((List<Rev__c>) GW_sObject.queryRecords('Rev__c', ' Id <> null ORDER BY Id'));
            Map<Id,RS__c> rsMap = new Map<Id, RS__c>((List<RS__c>) GW_sObject.queryRecords('RS__c', ' Id <> null ORDER BY Id'));

            System.assertEquals(TRUE,revMap.size() > 0);
            System.assertEquals(TRUE,rsMap.size() > 0);

            Decimal revAmount = revMap.values().get(0).UnitPrice__c;
            Decimal revAmountFromRS = 0.0;
            for(RS__c rs : rsMap.values()) {
                revAmountFromRS += rs.Revenue__c;
            }
            System.assertEquals(revAmount,revAmountFromRS,'Sum amount on RS != sum amount on Rev');
            Test.stopTest();
        }
        UTIL_Log.end();
    }
    
     @isTest static void testSubscription() {
     	Test.startTest();
     	factory.queryResults();
     	
     	// create Rev__c record
     	Rev__c newRevPro = new Rev__c();
		newRevPro.Opportunity__c = factory.data.opps[0].Id;
		newRevPro.From_Date__c = system.today();
		insert newRevPro;
		
		Rev__c newRev = new Rev__c();
		newRev.Opportunity__c = factory.data.opps[0].Id;
		newRev.From_Date__c = system.today();
		newRev.Predecessor__c = newRevPro.Id;
		newRev.Type__c = 'Adjusted';
		insert newRev;
		
        system.runAs(factory.data.testUsers.get('testUser')){
	     	Subscription sub = new Subscription(newRevPro.Id);
	     	Boolean bolRes = sub.getIsAdjustable();
	     	System.assertEquals(false, bolRes);
	     	
	     	OpportunityLineItem opplin = Subscription.createSubscriptionOLI(factory.data.opps[0], factory.data.pbes[0]);
	     	System.assertNotEquals(null, opplin);
	     	
	     	Rev__c rv = sub.createNewAdjustment();
	     	System.assertNotEquals(null, rv);
	     	
	     	//sub.saveRev(newRev);
	     	//System.assertNotEquals(null, rv.Id);
	     	
	     	sub.deleteAdjustment(newRev.Id);
	     	List<Rev__c> lstRev = GW_sObject.queryRecords('Rev__c', new Set<Id>{newRev.Id});
	     	System.assertEquals(0, lstRev.size());
	     	
	     	//sub.terminate(system.today(), 'test' );
	     	//lstRev = sub.recalcRevChain();
	     	Rev__c revItem = sub.getRevenueItemByFromDate(System.today());
	     		
     	}
     	Test.stopTest();
     }
}