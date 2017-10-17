public class HNDL_EmailMessage extends TriggerManager.TriggerHandler {
    
    public override void beforeInsert(SObject so){
        EmailMessage emailMsg = (EmailMessage)so;      
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so){
        EmailMessage emailMsg = (EmailMessage)so;      
        EmailMessage oldEmailMsg = (EmailMessage)so;
    }
  
    public override void bulkBefore(List<SObject> soLst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        if (hndlEvent == TriggerManager.triggerEventType.BeforeInsert) {
            GW_EmailMessage.reOpenCases(soLst);
        }
        
        if (hndlEvent == TriggerManager.triggerEventType.BeforeUpdate) {
            
        }
    }
    
    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        if (hndlEvent == TriggerManager.triggerEventType.AfterInsert) {
            GW_EmailMessage.commitParentCases();
        }
        
        if (hndlEvent == TriggerManager.triggerEventType.AfterUpdate) {
        
        }
    }

    // Constructor
    public HNDL_EmailMessage() { super('HNDL_EmailMessage', EmailMessage.sObjectType); }

}