public class HNDL_PermissionGroupAssignment extends TriggerManager.TriggerHandler {

	public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
		Set<Id> permissionGroupIds = new Set<Id>();
		Set<Id> userIds = new Set<Id>();
		List<PermissionGroupAssignment__c> pgaList = (List<PermissionGroupAssignment__c>) soLst;
		for (PermissionGroupAssignment__c pga : pgaList) {
			permissionGroupIds.add(pga.PermissionGroup__c);
			if (pga.User__c != null) {
				userIds.add(pga.User__c);
			}
		}
		UTIL.cacheUncachedRecords(permissionGroupIds);
		UTIL.cacheUncachedRecords(userIds);
	}
	public override void beforeInsert(SObject so) {
		this.checkAvailability((PermissionGroupAssignment__c) so);
		this.checkProfileName((PermissionGroupAssignment__c) so);
		this.checkType((PermissionGroupAssignment__c) so);
		this.setExternalId((PermissionGroupAssignment__c) so);
	}
	public override void beforeUpdate(SObject oldSo, SObject so) {
		this.checkAvailability((PermissionGroupAssignment__c) so);
		this.checkProfileName((PermissionGroupAssignment__c) so);
		this.checkType((PermissionGroupAssignment__c) so);
		this.setExternalId((PermissionGroupAssignment__c) so);
	}
	public override void beforeDelete(SObject so) {}
	public override void afterInsert(SObject so) {}
	public override void andFinally() {}

//////////////////////////////
// private helper methods
//////////////////////////////
	private void checkAvailability(PermissionGroupAssignment__c pga) {
		String validationResult = F_PermissionGroup.validateAvailability(pga.PermissionGroup__c);
		if (validationResult != null) {
			pga.addError(validationResult);
		}
	}

	private void checkType(PermissionGroupAssignment__c pga) {
		if (pga.User__c == null && pga.Profile__c == null) {
			pga.addError('Need to fill either User or Profile field');
		}
		if (pga.User__c != null && pga.Profile__c != null) {
			pga.addError('Cannot find both User and Profile fields for a single assignment');
		}
	}

	private void checkProfileName(PermissionGroupAssignment__c pga) {
		if (pga.Type__c == 'Profile') {
			if (F_PermissionGroup.isValidProfileName(pga.Profile__c) == false) {
				pga.addError('Profile name: ' + pga.Profile__c + ' is unknown');
			}
		}
	}

	private void setExternalID(PermissionGroupAssignment__c pga) {
		PermissionGroup__c pg = (PermissionGroup__c) UTIL.getCached(pga.PermissionGroup__c);
		if (pga.Type__c == 'User') {
			User u = (User) UTIL.getCached(pga.User__c);
			pga.ExternalID__c = pg.ExternalID__c + ' - ' + UTIL.getProductionUsername(u.Username);
		} else if (pga.Type__c == 'Profile') {
			pga.ExternalID__c = pg.ExternalID__c + ' - ' + pga.Profile__c;
		}
	}

	// Constructor
	public HNDL_PermissionGroupAssignment() { super('HNDL_PermissionGroupAssignment', PermissionGroupAssignment__c.sObjectType); }
}