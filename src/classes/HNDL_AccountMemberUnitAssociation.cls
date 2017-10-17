public class HNDL_AccountMemberUnitAssociation extends TriggerManager.TriggerHandler {

	public override void bulkAfter(List<SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        
        if (Trigger.isDelete && UTIL.isRunningTestSetup == FALSE) {
            deleteCustomAttributes(oldMap.values());
        }
		
		if(Trigger.isInsert && Trigger.isAfter && UTIL.isRunningTestSetup == false ){
        	ebayKblockFTPEmailAndSetTypeToProBasedOnMemberUnitAssociation( (List<AccountMemberUnitAssociation__c>) soLst);
        }
    }
	
	private static void ebayKblockFTPEmailAndSetTypeToProBasedOnMemberUnitAssociation( List<AccountMemberUnitAssociation__c> amuaList ) {
    	// get the member unit Id
    	// check if it is EBAYKPR
    	// get the linked account
    	// check if type is pro and block ftp email is checked else check it.
    	Set<Id> accountIds = new Set<Id>();
    	Set<Id> memberUnitIds = new Set<Id>();
    	Map<Id, Map<Id, Id>> accountAndMemberUnitIdMap = new Map<Id, Map<Id,Id>>();
    	for ( AccountMemberUnitAssociation__c record: amuaList ) {
    		accountIds.add(record.Account__c);
    		memberUnitIds.add(record.MemberUnit__c);
    		Map<Id, Id> accIdNmuId = new Map<Id, Id>();
    		accIdNmuId.put(record.MemberUnit__c, record.Account__c);
    		accountAndMemberUnitIdMap.put(record.Id, accIdNmuId);
    	}


    	Map<Id, MemberUnit__c> memberUnitMap = new Map<Id, MemberUnit__c>([select Id, MemberUnitId__c from MemberUnit__c where id in: memberUnitIds and MemberUnitId__c = 'EBAYKPR']);
    	if ( memberUnitMap.isEmpty() ) return;
    	Map<Id, Account> accountMap = new Map<Id, Account>([select Id, Type, BlockFTPEmail__c from Account where Id in: accountIds and (Type = 'Pro' or BlockFTPEmail__c = false) for update]);
    	if ( accountMap.isEmpty() ) return;


    	list<Account> accountsToUpdate = new List<Account>();
    	for (Map<Id, Id> amId: accountAndMemberUnitIdMap.values() ){

    		for ( Id muId : amId.keySet() ) {

    			if ( memberUnitMap.containsKey(muId) && accountMap.containsKey( amId.get(muId) ) ) {

    				Account accObj = accountMap.get( amId.get(muId) );
    				accObj.Type = 'Pro';
		    		accObj.BlockFTPEmail__c = true;
		    		accountsToUpdate.add(accObj);

    			}

    		}

    	}
    	if ( accountsToUpdate.isEmpty() ) return;
    	update accountsToUpdate;
    }

	private static void deleteCustomAttributes(List<SObject> soLst) {
		//system.assert(false,'@here');
		Set<Id> parentAccountIds = GW_sObject.getParentIds(soLst, 'Account__c');
		Set<Id> parentMemberUnitIds = GW_sObject.getParentIds(soLst, 'MemberUnit__c');
		Map<String, Set<Id>> lostOppsMap = new map<String, Set<Id>>();
		lostOppsMap.put('idSet1', parentAccountIds);
		lostOppsMap.put('idSet2', parentMemberUnitIds);
		List<CustomAttribute__c> lstCustomAttributes = (List<CustomAttribute__c>) GW_sObject.queryRecords('CustomAttribute__c', 'Account__c IN: idSet1 AND MemberUnit__c IN: idSet2', lostOppsMap);
		system.debug('======='+lstCustomAttributes.size());
		if(!lstCustomAttributes.isEmpty())
			delete lstCustomAttributes;
	}

	// Constructor
    public HNDL_AccountMemberUnitAssociation() { super('HNDL_AccountMemberUnitAssociation', AccountMemberUnitAssociation__c.sObjectType); }
}