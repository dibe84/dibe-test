/**
 * Task 
 * @author: GIS-DevTeam
 * @createdDate: 13/Oct/2016
 * @description: 
 *  - test class of StreamingApiHelper
 * @references: 
 *
 * @changeLog:
 *
 */
 
@isTest
public class LPC_StreamingApiHelperTest extends TSTDF_Base {
    
    public LPC_StreamingApiHelperTest(TSTDF_Dataset dataset) {
        super(dataset);
    }
    
    public static LPC_StreamingApiHelperTest factory = new LPC_StreamingApiHelperTest(new TSTDF_Dataset());
    
    public class TSTDF_Dataset extends TSTDF_BaseDataSet {
        public MemberUnit__c oppMemberUnit;
        public override List<OpportunityLineItem> constructOpportunityLineItems(List<Opportunity> opps, List<OpportunityLineItem> olis) {
            
	        PriceBookEntry pbe = ((List<PriceBookEntry>) GW_sObject.queryRecords('PriceBookEntry', '')).get(0);
	        Opportunity opp = opps.get(0);
	
	        opp = (Opportunity) GW_sObject.queryRecords(GW_sObject.getobjectNameFromId(opp.Id), new Set<Id>{opp.Id})[0]; //Get all fields information
	        createMemberUnit(opp.AccountId);
	        opp.MemberUnit__c = oppMemberUnit.Id;
	            
	        update opp;
	            
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
    
		public void createMemberUnit(String accId){
		    //create member
		    Member__c mb = new Member__c(Name='Test member', Account__c = accId);
		    insert mb;
		    //create memberUnit
		    oppMemberUnit = new MemberUnit__c(Name = 'Test member unit', Member__c=mb.Id, LineOfBusiness__c='AD', EnableTRACT__c = false);
		    insert oppMemberUnit;
		    
		}
            
    }
    @testSetup static void setup() { 
        //UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        //UTIL.isRunningTestSetup = false;
    }
    
    // Test on insert action
    @isTest static void testCreateStreamingNotificationRecordsOnInsertAction(){
        
        // Assert 'insert' case
        Test.startTest();
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('testUser')) {
            List<OpportunityLineItem> olis = LPC_ProductConfiguratorController.getOpportunityLineItems(factory.data.opps[0].Id);
            
            Streaming_Api_Support__c sas = [select Action__c, RecordId__c, SobjectType__c, ParentId__c
                from Streaming_Api_Support__c where RecordId__c = :olis[0].Id ][0];
                
            System.assertEquals(String.valueOf(olis[0].Id), sas.RecordId__c);
            System.assertEquals('insert', sas.Action__c);
            System.assertEquals('OpportunityLineItem', sas.SobjectType__c);
            System.assertEquals(String.valueOf(olis[0].OpportunityId+''), sas.ParentId__c);
           
        }
        Test.stopTest();    
    }
    
    // Test on update action
    @isTest static void testCreateStreamingNotificationRecordsOnUpdateAction(){
        
        // Assert 'update' case
        Test.startTest();
        factory.queryResults();
        System.runAs (factory.data.testUsers.get('testUser')) {
            List<OpportunityLineItem> olis = LPC_ProductConfiguratorController.getOpportunityLineItems(factory.data.opps[0].Id);
            olis[0].Description = 'Des Test1';
            olis[1].Description = 'Des Test2';
            update olis;
            
            Streaming_Api_Support__c sas1 = [select Action__c, RecordId__c, SobjectType__c, ParentId__c
                from Streaming_Api_Support__c where RecordId__c = :olis[0].Id][0];
                
            System.assertEquals(String.valueOf(olis[0].Id), sas1.RecordId__c);
            System.assertEquals('update', sas1.Action__c);
            System.assertEquals('OpportunityLineItem', sas1.SobjectType__c);
            System.assertEquals(String.valueOf(olis[0].OpportunityId+''), sas1.ParentId__c);    
        }
        Test.stopTest();     
    }
    
    // Test on delete action
    @isTest static void testCreateStreamingNotificationRecordsOnDeleteAction(){
         
         // Assert 'delete' case
         Test.startTest();
         factory.queryResults();
         System.runAs (factory.data.testUsers.get('testUser')){
            List<OpportunityLineItem> olis = LPC_ProductConfiguratorController.getOpportunityLineItems(factory.data.opps[0].Id);
           
            delete olis[0];
           
            Streaming_Api_Support__c sas2 = [select Action__c, RecordId__c, SobjectType__c, ParentId__c
                from Streaming_Api_Support__c where RecordId__c = :olis[0].Id ][0];
                
            System.assertEquals(String.valueOf(olis[0].Id), sas2.RecordId__c);
            System.assertEquals('delete', sas2.Action__c);
            System.assertEquals('OpportunityLineItem', sas2.SobjectType__c);
            System.assertEquals(String.valueOf(olis[0].OpportunityId+''), sas2.ParentId__c);
            }
        Test.stopTest();    
    }
    
}