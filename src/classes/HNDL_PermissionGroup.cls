public class HNDL_PermissionGroup extends TriggerManager.TriggerHandler {

	public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {}
	public override void beforeInsert(SObject so) {
		PermissionGroup__c pg = (PermissionGroup__c) so;
		this.validatePermissionSets(pg);
		this.setExternalID(pg);
	}
	public override void beforeUpdate(SObject oldSo, SObject so) {
		PermissionGroup__c pg = (PermissionGroup__c) so;
		this.validatePermissionSets(pg);
		this.setExternalID(pg);
	}
	public override void beforeDelete(SObject so) {
		// todo: check if no assignment for this record or any of which this PG is a child
		this.validateDeletion((PermissionGroup__c) so);
	}
	public override void afterInsert(SObject so) {}
	public override void andFinally() {}

//////////////////////////////
// private helper methods
//////////////////////////////

	private void validatePermissionSets(PermissionGroup__c pg) {
		String validationResult = F_PermissionGroup.validatePermissionSetNames(pg.PermissionSets__c);
		if (validationResult != null) {
			pg.addError(validationResult);
		}
	}

	private void validateDeletion(PermissionGroup__c pg) {
		String result = F_PermissionGroup.validateDeletion(pg.Id);
		if (result != null) {
			pg.addError(result);
		}
	}

	private void setExternalID(PermissionGroup__c pg) {
		pg.ExternalID__c = pg.Name;
	}

	// Constructor
	public HNDL_PermissionGroup() { super('HNDL_PermissionGroup', PermissionGroup__c.sObjectType); }
}