public class HNDL_LiveChatTranscript extends TriggerManager.TriggerHandler {
    
    public override void beforeInsert(SObject so){
             
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so){
       
    }
    
 
    
    public override void bulkBefore(List<SObject> soLst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        
        if (hndlEvent == TriggerManager.triggerEventType.BeforeInsert) {
        	GW_LiveChatTranscript.initialCaseId((List<LiveChatTranscript>) soLst);
        }

        if (hndlEvent == TriggerManager.triggerEventType.BeforeUpdate) {
            GW_LiveChatTranscript.initialCaseId((List<LiveChatTranscript>) soLst);
        }
        
    }


    // Constructor
    public HNDL_LiveChatTranscript() { super('HNDL_LiveChatTranscript', LiveChatTranscript.sObjectType); }

}