public class HNDL_SocialPost extends TriggerManager.TriggerHandler {


     public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
      	
      	 if (hndlEvent == TriggerManager.triggerEventType.AfterInsert) {
      	 	
      	 	GW_SocialPost.initialCaseMemberId(soLst);
      	 }
     }

 	// public override void beforeUpdate(SObject oldSo, SObject so){}
	//public override void beforeInsert(SObject so){ }
    ///public override void beforeDelete(SObject so){}

    ///public override void afterInsert(SObject so){}

    ///public override void afterUpdate(SObject oldSo, SObject so){}

    ///public override void andFinally() {}

//////////////////////////////
// private helper methods
//////////////////////////////
    

    // Constructor
    public HNDL_SocialPost() { super('HNDL_SocialPost', SocialPost.sObjectType); }

}