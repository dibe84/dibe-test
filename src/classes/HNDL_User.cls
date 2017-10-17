public with sharing class HNDL_User extends TriggerManager.TriggerHandler {

	// Constructor
    public HNDL_User() { super('HNDL_User', User.sObjectType); } // Let parent class TriggerHandler know, what handler this is...

    // Handler variables

    // public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {}
    // public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {}

    public override void beforeInsert(SObject so) {
        User u = (User)so; // Cast the SObject to a User

    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        User u = (User)so;
        User oldsp = (User)oldSo;
        //UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
    }

	public override void afterUpdate(SObject oldSo, SObject so) {
        User u = (User) so;
        User oldsp = (User)oldSo;
        if (u.IsActive) { F_PermissionGroup.process(new Set<Id>{so.Id}, null); }
        //UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
    }

    public override void beforeDelete(SObject so) {
        //UTIL_RecordRestriction.checkDeletionLock(so);
    }

    public override void afterInsert(SObject so) {
    	User u = (User) so;
        if (u.IsActive) { F_PermissionGroup.process(new Set<Id>{so.Id}, null); }
    }

    // public override void afterUpdate(SObject oldSo, SObject so) {}
    // public override void afterDelete(SObject so) {}
    // public override void afterUndelete(SObject so) {}*/
    // public override void andFinally() {}


    // private helper methods
    private void setUserEcgCode(User u) {

    }

}