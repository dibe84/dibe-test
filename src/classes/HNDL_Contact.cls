public with sharing class HNDL_Contact extends TriggerManager.TriggerHandler {
	

	List<Account> accsToSyncToFiqas = new List <Account>();
	Set<Id> contactIdsWithFiqasChange = new Set<Id>();
    List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();
    Map<Id, Contact> mRelatedContsOfAccount = new Map<Id, Contact>();
    List<Account> lstAccTobeUpdated = new List<Account>();
    Map<String, List<Contact>> mapContacts = new Map<String, List<Contact>>();
    Set<Id> setAccIds = new Set<Id>();
    Map<Id, Account> mapAccsTobeUpdated = new Map<Id, Account>();
    Map<Id, Account> allParentAccMap = new Map<Id, Account>();
    public static Boolean isIgnoredCheckPhoneNumber = false;
    Map<Id, Account> allNewParentAccMap = new Map<Id, Account>();

	// Constructor
    public HNDL_Contact() { super('HNDL_Contact', Contact.sObjectType); } 

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
    	if (UTIL.isRunningTestSetup == false){
	    	Set<Id> parentAccIds = GW_sObject.getParentIds(soLst, 'AccountId');
        if(parentAccIds != null){
        	mapContacts = GW_Contact.getMappingRoleAndPrimaryContact(parentAccIds);
        }
    	}
    } 
    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        UTIL.cache(soLst);
        allNewParentAccMap.putAll((List<Account>)GW_sObject.queryRecords('Account', GW_sObject.getParentIds(soLst, 'AccountId')));
		UTIL.cache(allNewParentAccMap);
        if(oldMap != null){
            Set<Id> setAccIds = GW_sObject.getParentIds(oldMap.values(), 'AccountId');
			allParentAccMap.putAll((List<Account>)GW_sObject.queryRecordsForUpdate('Account', setAccIds, new List<String>()));
        }
        if (newMap != null && UTIL.isRunningTestSetup == false) {
            Set<id> soIds = newMap.keySet();
            Set<Id> accIdsThatMayNeedAccountPush = new Set<Id>();

            Set<Id> accIds = GW_sObject.getChildIds(soIds, 'Accounts__r');
            if (accIds != null) {
                accIdsThatMayNeedAccountPush.addAll(accIds);
            }
            Set<Id> portalAccIds = GW_sObject.getChildIds(soIds, 'PortalAccounts__r');
            if (portalAccIds != null) {
                accIdsThatMayNeedAccountPush.addAll(portalAccIds);
            }
            Set<Id> parentAccIds = GW_sObject.getParentIds(soLst, 'AccountId');
            if(parentAccIds != null){
            	mapContacts = GW_Contact.getMappingRoleAndPrimaryContact(parentAccIds);
            }
			GW_AccountMemberUnitAssociation.cacheAMUAForAccounts(allNewParentAccMap.values());
            for (Id accid : accIdsThatMayNeedAccountPush) {
            	if ( UTIL_WSC_Subscription.isAccOnlyAdsales(accid) ) accIdsThatMayNeedAccountPush.remove(accid);
            }
            UTIL_WSC.checkForProcessing('WSC_API_SFECG_v1.AccountPush', accIdsThatMayNeedAccountPush, wsscToUpsert);
            
			checkForTRACTProcessing(soLst, wsscToUpsert, oldMap);
        }
    }

    public override void beforeInsert(SObject so) {
        Contact con = (Contact) so;
		
        validateInactiveReason(con, null);
        validateContactRolesOnAcc(con, null);
		checkPhoneNumbers(con,null);
		UTIL_FieldValidator.checkObject(con);
        GW_Contact.setStatus(con); // leave as last method
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Contact con = (Contact) so;
        Contact oldCon = (Contact) oldSo;
        collectContactIdsWithFiqasChange(con, oldCon);
        UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
		
        validateInactiveReason(con, oldCon);
        validateContactRolesOnAcc(con, oldCon);
        
		checkPhoneNumbers(con, oldCon);
		UTIL_FieldValidator.checkObject(con);
        GW_Contact.setStatus(con); // leave as last method
    }
    
    public override void beforeDelete(SObject so) {
        UTIL_RecordRestriction.checkDeletionLock(so);
    }

    public override void afterInsert(SObject so) {
    	Contact con = (Contact) so;
        updateRelatedContOfAccount(con, null); 
        matchingAccTobeUpdated(con, null);
    }
    
    public override void afterUpdate(SObject oldSo, SObject so) {
    	Contact con = (Contact) so;
    	Contact oldCon = (Contact) oldSo;
    	updateRelatedContOfAccount(con, oldCon);
    	matchingAccTobeUpdated(con, oldCon);
    }
    
    // public override void afterDelete(SObject so) {}
    // public override void afterUndelete(SObject so) {}*/
    
    public override void andFinally() {

        if (contactIdsWithFiqasChange.size()>0) {
            scheduleAccsForFiqasSync();
        }
        if (wsscToUpsert.size()>0){
            try{
               upsert wsscToUpsert UniqueKey__c; 
            }
            catch(Exception ex){
                UTIL.throwError('HNDL_Contact - Error inserting WS_ScheduledCallouts',ex);
            }
        }
		commitPrimaryChanges();
		updateAccount();
    }

//////////////////////////////
// private helper methods
//////////////////////////////

	private void collectContactIdsWithFiqasChange(Contact con, Contact oldcon) {
        Set<String> fiqasFields = new Set<String>{'FirstName','LastName','Title','Salutation','Sex__c','Email'};
        if ( GW_sObject.oneOrMoreFieldsChanged(con, oldcon, fiqasFields) ) 
            contactIdsWithFiqasChange.add(con.Id); 
	}

    private void scheduleAccsForFiqasSync() {
        List<Account> tmpAccsToSyncToFiqas = (List<Account>) GW_sObject.queryRecordsForUpdate('Account', new String[] {'Id', 'Touch__c', 'Finance_contact__c', 'Member_Id__c'}, 'Finance_contact__c', contactIdsWithFiqasChange);
        if (tmpAccsToSyncToFiqas != null) {
            for (Account acc : tmpAccsToSyncToFiqas) {
                if (UTIL_WSC_Subscription.isSubscribedToWS(acc.Member_Id__c, 'WSC_Fiqas', 'SyncAccount')) {
                    acc.FQ_syncAccountDetails__c = true;
                    accsToSyncToFiqas.add(acc);
                }
            }
            If (!accsToSyncToFiqas.isEmpty()) update accsToSyncToFiqas;
        }
    }
    
    /**
     * @createdDate: 28-11-2016
     * @createdBy: Sochanra
     * @desc: update related contacts of an account, only one contact of an account can be Primary
     */
    private void updateRelatedContOfAccount(Contact newCont, Contact oldCont){
     	Boolean doUpdatePrimary = oldCont != null && newCont.Primary__c != oldCont.Primary__c && newCont.Primary__c;
     	Boolean doInsertPrimary = oldCont == null && newCont.Primary__c;
     	if (doUpdatePrimary || doInsertPrimary) {
			List<Contact> relatedContacts = (newCont.AccountId != null && mapContacts.containsKey(newCont.AccountId)) ? mapContacts.get(newCont.AccountId) : new List<Contact>();
			for(Contact c : relatedContacts){
				if(newCont.Id == c.Id || c.Primary__c == false) continue;
				c.Primary__c = false;
	 			mRelatedContsOfAccount.put(c.Id, c);
			}
     	}
     }
     
     private void commitPrimaryChanges(){
     	if (!mRelatedContsOfAccount.values().isEmpty()) update mRelatedContsOfAccount.values();
     }
     
    /**
    * @createdDate: 29-11-2016
    * @Rev: 27-04-2017_Sudha : Modified logic to unlink/link account contacts based on account/role change on contact
    * @createdBy: Sochanra
    * @desc: Update Portal User/Financial of account based on contacts of account
    */
    private void matchingAccTobeUpdated(Contact newContact, Contact oldContact){
        //Do nothing if new contact inserted does not have Role
        if(oldContact == null && (String.isBlank(newContact.Role__c) || newContact.AccountId == null)) return;
        if(oldContact != null && oldContact.isActive__c == newContact.isActive__c && !newContact.isActive__c) return;

        Set<String> setNewContactRoles = (newContact.Role__c != null) ? getContRoles(newContact.Role__c) : new Set<String>();
        Set<String> setOldContactRoles = (oldContact != null && oldContact.Role__c != null) ? getContRoles(oldContact.Role__c) : new Set<String>();

        if(oldContact != null){
            if(allParentAccMap.containsKey(oldContact.AccountId)){
                Account acc = allParentAccMap.get(oldContact.AccountId);
                if(acc.Portal_User__c == newContact.Id){
                    if(!mapAccsTobeUpdated.containsKey(acc.Id))
                        mapAccsTobeUpdated.put(acc.Id, new Account(Id = acc.Id));
                    mapAccsTobeUpdated.get(acc.Id).Portal_User__c = null;
                }
                if(acc.Finance_Contact__c == newContact.Id){
                    if(!mapAccsTobeUpdated.containsKey(acc.Id))
                        mapAccsTobeUpdated.put(acc.Id, new Account(Id = acc.Id));
                    mapAccsTobeUpdated.get(acc.Id).Finance_Contact__c = null;
                }
            }
        }
        //Link
        if(setNewContactRoles.contains(GW_Contact.ROLE_PORTAL_USER) ){
            if(!mapAccsTobeUpdated.containsKey(newContact.AccountId))
                mapAccsTobeUpdated.put(newContact.AccountId, new Account(Id = newContact.AccountId));
            mapAccsTobeUpdated.get(newContact.AccountId).Portal_User__c = newContact.Id;
        }
        if(setNewContactRoles.contains(GW_Contact.ROLE_FINANCE_CONTACT)){
            if(!mapAccsTobeUpdated.containsKey(newContact.AccountId))
                mapAccsTobeUpdated.put(newContact.AccountId, new Account(Id = newContact.AccountId));
            mapAccsTobeUpdated.get(newContact.AccountId).Finance_Contact__c = newContact.Id;
        }
    }
    
    private void updateAccount(){
        if(!mapAccsTobeUpdated.isEmpty()) update mapAccsTobeUpdated.values();
    }
     
     /**
      * @createdDate: 05-12-2016
      * @createdBy: Sochanra
      * @desc: Validate if inActivate contact without a reason
      */
     private void validateInactiveReason(Contact newCont, Contact oldCont){
     	if((!newCont.isActive__c && newCont.Inactivation_Reason__c == null) || (oldCont!=null && oldCont.isActive__c != newCont.isActive__c && !newCont.isActive__c && newCont.Inactivation_Reason__c == null)){
     		newCont.Inactivation_Reason__c.addError('You must enter a value.');
     		return;
     	}
     }
     
     /**
      * @createdDate: 22-12-2016
      * @Rev: 27-04-2017_Sudha : Modified logic to unlink/link account contacts based on account/role change on contact        
      * @createdBy: Sochanra
      * @desc: Validate if user trying to set a second financialcontact/portaluser and the account has already one set
      */
      private void validateContactRolesOnAcc(Contact newCont, Contact oldCont){
        if(mapContacts.get(newCont.AccountId)==null)return;
        if(String.isBlank(newCont.Role__c)) return;
        Set<String> newContRoles = getContRoles(newCont.Role__c);
        for(Contact c :  mapContacts.get(newCont.AccountId)) {
            if( newCont.Id == c.Id || !c.isactive__c ) continue;
            Set<String> contRoles = getContRoles(c.Role__c);
            if((contRoles.contains(GW_Contact.ROLE_PORTAL_USER) && newContRoles.contains(GW_Contact.ROLE_PORTAL_USER))|| 
               (contRoles.contains(GW_Contact.ROLE_FINANCE_CONTACT) && newContRoles.contains(GW_Contact.ROLE_FINANCE_CONTACT))){
	      		newCont.Role__c.addError('Financial Contact/Portal user is already set on this account. Please update existing contact to a new role before setting a new Finance Contact/Portal User.');
               }
          } 
      }
      
      /**
      * @createdDate: 22-12-2016        
      * @createdBy: Sochanra
      * @desc: Get list role of contact
      */
      private Set<String> getContRoles(String strRole){
      	Set<String> contRoles = new Set<String>();
 		for(String st : (strRole != null?strRole.split(';'):new List<String>())){
 			contRoles.add(st);
 		}
 		return contRoles;
      }

    private void checkPhoneNumbers(Contact contact, Contact oldContact) {
        if (isIgnoredCheckPhoneNumber)
            return;

        Set<String> phoneFields = new Set<String>{'Phone','OtherPhone','HomePhone','MobilePhone'};
        VAL_Global.checkPhoneNumbers(contact, oldContact, phoneFields);  
    }
	  
	private void checkForTRACTProcessing(List<SObject> soLst, List<WS_ScheduledCallout__c> wsscToUpsert, Map<Id,sObject> oldMap) {
		List<SObject> soListForUpdate = new List<SObject>();
		List<SObject> soListForCreate = new List<SObject>();
		Set<String> peopleInfoFieldSet = new Set<String>{'Role__c','Salutation','Title','Email','Phone','FirstName','LastName','MiddleName__c'};
		Set<String> changedFieldsSet = new Set<String>();
		for(SObject so : soLst) {
			Contact newCon = (Contact)so;
			Contact oldCon = oldMap != null ? (Contact)oldMap.get(so.Id) : null;
			Account acc = (Account) allNewParentAccMap.get(newCon.AccountId);
			Boolean isTractEnabled = UTIL_WSC_Subscription.isSubscribedToTRACT(acc);
			Boolean isRoleEmailChanged = GW_sObject.oneOrMoreFieldsChanged(newCon, oldCon, new Set<String>{'Role__c','Email'});
			if(oldCon == null)
				changedFieldsSet = peopleInfoFieldSet;
			else
				changedFieldsSet = GW_sObject.getChangedFields(newCon, oldCon, peopleInfoFieldSet);
			if(!changedFieldsSet.isEmpty() && isTractEnabled && acc.Tract_AccountId__c != null && String.isNotBlank(newCon.Role__c) && 
				newCon.Role__c.contains(GW_Contact.ROLE_FINANCE_CONTACT)) {
				soListForUpdate.add(newCon);
			}

			if(isRoleEmailChanged && isTractEnabled && acc.Tract_ResponsiblePartyId__c != null && 
				String.isNotBlank(newCon.Role__c) && newCon.Role__c.contains(GW_Contact.ROLE_FINANCE_CONTACT) && String.isNotBlank(newCon.Email)) {
				soListForCreate.add(newCon);
			}
		}
		if(!soListForUpdate.isEmpty()) UTIL_WSC.checkForProcessing('WSC_Tract.BillingAccountGetFromContact', soListForUpdate, wsscToUpsert);
		if(!soListForCreate.isEmpty()) UTIL_WSC.checkForProcessing('WSC_Tract.CreateEmailAddress', soListForCreate, wsscToUpsert);
	}
}
