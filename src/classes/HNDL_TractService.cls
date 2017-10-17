public class HNDL_TractService extends TriggerManager.TriggerHandler {
	//mapping original opp & adjustment opps
	Map<String, List<Opportunity>> mapOppty = new Map<String, List<Opportunity>>();
	
    public override void beforeInsert(SObject so) {
        TRACT_Service__c sv = (TRACT_Service__c) so;
        if('Active'.equalsignorecase(sv.Status__c)){//pululate only adjustment service to adjustment opportunity
        	linkedServiceToAdjusmentOppty(sv);
        }
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        TRACT_Service__c sv = (TRACT_Service__c)so;
        if('Active'.equalsignorecase(sv.Status__c)){//pululate only adjustment service to adjustment opportunity
        	linkedServiceToAdjusmentOppty(sv);
        }
    }

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
    	mapOppty = getMappingOpportunity(soLst);
    }

    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
    }

    public override void andFinally() {
    }
    
    ///////////////////////////
    // Adjustment Opportunity
    //////////////////////////
    private void linkedServiceToAdjusmentOppty(TRACT_Service__c sv){
    	//get related service
        if(sv.Opportunity__c != null && mapOppty.get(sv.Opportunity__c) != null){
        	for(Opportunity opp : mapOppty.get(sv.Opportunity__c)){
        		if(sv.Opportunity__c == opp.Original_Opportunity__c) sv.Opportunity__c = opp.Id; 
        		break;
        	}
        }
    }
    
    private Map<String, List<Opportunity>> getMappingOpportunity(List<TRACT_Service__c> soLst){
    	Map<String, List<Opportunity>> mapOpp = new Map<String, List<Opportunity>>();
    	Set<Id> svIds = new Set<Id>();
    	for(TRACT_Service__c sv : (List<TRACT_Service__c>)soLst){
    		svIds.add(sv.Opportunity__c);
    	}
    	List<Opportunity> opps = GW_sObject.queryRecords('Opportunity', 'NumStatus__c = 4 And Original_Opportunity__c IN: idSet1 AND Tract_Order_Confirm__c = true', new Map<String, Set<id>>{'idSet1' => svIds});
    	for(Opportunity opp : opps){
    		if(!mapOpp.containskey(opp.Original_Opportunity__c)) mapOpp.put(opp.Original_Opportunity__c, new List<Opportunity>());
    		mapOpp.get(opp.Original_Opportunity__c).add(opp);
    	}
    	return mapOpp;
    }

    // Constructor
    public HNDL_TractService() { super('HNDL_TractService', TRACT_Service__c.sObjectType); }
}