public class HNDL_CallLog extends TriggerManager.TriggerHandler {
    
    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        
        if (hndlEvent == TriggerManager.triggerEventType.AfterUpdate) {
           GW_Case.createCasesFromCallLogs((List<CallLog__c>) soLst, (Map<Id, CallLog__c>) oldMap);
        }
        
    }
    
    //////////////////////////////
    
    // Constructor
    public HNDL_CallLog() { super('HNDL_CallLog', CallLog__c.sObjectType); }
    
}