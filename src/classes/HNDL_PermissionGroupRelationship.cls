public class HNDL_PermissionGroupRelationship extends TriggerManager.TriggerHandler {

	public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
		Set<Id> permissionGroupIds = new Set<Id>();
		List<PermissionGroupRelationship__c> pgrList = (List<PermissionGroupRelationship__c>) soLst;
		for (PermissionGroupRelationship__c pgr : pgrList) {
			permissionGroupIds.add(pgr.Parent__c);
			permissionGroupIds.add(pgr.Child__c);
		}
		UTIL.cacheUncachedRecords(permissionGroupIds);
	}
	public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {}
	public override void beforeInsert(SObject so) {
		this.setExternalId((PermissionGroupRelationship__c) so);
	}
	public override void beforeUpdate(SObject oldSo, SObject so) {
		this.setExternalId((PermissionGroupRelationship__c) so);
	}
	public override void beforeDelete(SObject so) {
		this.validateDeletion((PermissionGroupRelationship__c) so);
	}
	public override void afterInsert(SObject so) {}
	public override void andFinally() {
		F_PermissionGroup.validateNonRecursive();
	}

//////////////////////////////
// private helper methods
//////////////////////////////
	private void validateDeletion(PermissionGroupRelationship__c pgr) {
		String parentResult = F_PermissionGroup.validateDeletion(pgr.Parent__c);
		if (parentResult != null) {
			pgr.addError(parentResult);
		}

		String childResult = F_PermissionGroup.validateDeletion(pgr.Child__c);
		if (childResult != null) {
			pgr.addError(childResult);
		}
	}

	private void validateNonRecursiveSo(PermissionGroupRelationship__c pgr) {
		if (pgr.Child__c == pgr.Parent__c) {
			pgr.addError('Child and Parent cannot be the same');
		}
	}

	private void setExternalID(PermissionGroupRelationship__c pgr) {
		PermissionGroup__c child = (PermissionGroup__c) UTIL.getCached(pgr.Child__c);
		PermissionGroup__c parent = (PermissionGroup__c) UTIL.getCached(pgr.Parent__c);
		pgr.ExternalID__c = child.Name + ' - ' + parent.Name;
	}


	// Constructor
	public HNDL_PermissionGroupRelationship() { super('HNDL_PermissionGroupRelationship', PermissionGroupRelationship__c.sObjectType); }
}