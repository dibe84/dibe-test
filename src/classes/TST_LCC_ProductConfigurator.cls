@isTest
public class TST_LCC_ProductConfigurator  extends TSTDF_Base {
    
    public TST_LCC_ProductConfigurator(TSTDF_Dataset dataset) {
		super(dataset);
    }
	
    public static TST_LCC_ProductConfigurator factory = new TST_LCC_ProductConfigurator(new TSTDF_Dataset());
    
    public class TSTDF_Dataset extends TSTDF_BaseDataSet {
        public override List<OpportunityLineItem> constructOpportunityLineItems(List<Opportunity> opps, List<OpportunityLineItem> olis) {
            PriceBookEntry pbe = ((List<PriceBookEntry>) GW_sObject.queryRecords('PriceBookEntry', '')).get(0);
            Opportunity opp = opps.get(0);

            opp = (Opportunity) GW_sObject.queryRecords(GW_sObject.getobjectNameFromId(opp.Id), new Set<Id>{opp.Id})[0]; //Get all fields information
            
            OpportunityLineItem oli1 = GW_OpportunityLineItem.createSObject(opp, pbe, 10, 10);
            OpportunityLineItem oli2 = GW_OpportunityLineItem.createSObject(opp, pbe, 12, 15);
            
            Date startOli1 = Date.newInstance(2030,1,1);
    		Date endOli1 = Date.newInstance(2030,6,30);
    		Date startOli2 = Date.newInstance(2030,1,31);
    		Date endOli2 = Date.newInstance(2030,6,1);
    
            oli1.from_Date__c = startOli1;
            oli1.until_Date__c= endOli1;
            oli1.Billing_Category__c = 'CPD';
            oli1.SalesPriceNet__c = oli1.UnitPrice;
            oli1.Description = 'TST Description1';
            oli1.UniqueLineDescription__c = 'TSTUniqueLineDescription1';
    
            oli2.from_Date__c = startOli2;
            oli2.until_Date__c= endOli2;
            oli2.Billing_Category__c = 'CPM';
            oli2.SalesPriceNet__c = oli2.UnitPrice;
            oli2.Description = 'TST Description2';
            oli2.UniqueLineDescription__c = 'TSTUniqueLineDescription2';
            
            olis.add(oli1);
            olis.add(oli2);
            return olis;
        }
    }
    
    public override void queryAdditionalResults() {}
	
    @testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void testGetProducts() {
		factory.queryResults();        
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            LCC_ProductConfigurator.getProducts(Test.getStandardPricebookId());
        }
        Test.stopTest();
    }
    
    @isTest static void testApplyPriceModel() {
        factory.queryResults();        
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            OpportunityLineItem oli = ((List<OpportunityLineItem>) LCC_ProductConfigurator.getNewOpportunityLineItem(factory.data.opps[0].Id, factory.data.pbes[0].Id).content)[0];
            LCC_ProductConfigurator.RemoteResponse response = LCC_ProductConfigurator.applyPriceModel(oli);
            oli = (OpportunityLineItem) response.content;
            LCC_ProductConfigurator.saveOpportunityLineItem(oli);
        }
        Test.stopTest();
    }
    
    @isTest static void testCopyOpportunityLineItem() {
        factory.queryResults(); 
        
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            LCC_ProductConfigurator.RemoteResponse response = LCC_ProductConfigurator.copyOpportunityLineItem(factory.data.olis[0]);
        }
        Test.stopTest();
    }
    
    @isTest static void testGetOpportunityLineItems() {
        factory.queryResults();
        
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            List<OpportunityLineItem> olis = LCC_ProductConfigurator.getOpportunityLineItems(factory.data.opps[0].Id);
            System.assertEquals(2, olis.size());
            LCC_ProductConfigurator.deleteOpportunityLineItem(factory.data.olis[0]);
            olis = LCC_ProductConfigurator.getOpportunityLineItems(factory.data.opps[0].Id);
            System.assertEquals(1, olis.size());
        }
        Test.stopTest();
    }
    
   	@isTest static void testGetSelectedAndMostRecentOpportunities() {
        factory.queryResults();
        
        Test.startTest();
        System.runAs (factory.data.testUsers.get('testUser')) {
            LCC_ProductConfigurator.RemoteResponse response = LCC_ProductConfigurator.getSelectedAndMostRecentOpportunities(factory.data.opps[0].Id);
            List<Opportunity> opps = (List<Opportunity>) response.content;
            System.assertEquals(1, opps.size());
        }
        Test.stopTest();
    }
    
}