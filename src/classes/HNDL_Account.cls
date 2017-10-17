public class HNDL_Account extends TriggerManager.TriggerHandler {

    List<Account> accsToUpdate = new List <Account>();
    List<Opportunity> oppsToUpdate = new List<Opportunity>();
    List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();
    public static Boolean runAccountSync = true;
    public static Boolean isIgnoredCheckVat = false;
    public static Boolean isIgnoredCheckPhoneNumber = false;
    public static Map<String, CountryStateISO__c> countryStateISO = CountryStateISO__c.getAll();
    public static Boolean isAccsPushed = false;
    private Map<Id, Account> accsPushTractMap = new Map<Id, Account>();
    private Map<Id, Account> accsOldMap = new Map<Id, Account>();
    
    public override void bulkBefore(List<SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        if (!Trigger.isInsert && !Trigger.isDelete) {
            validateCustomAttributes(oldMap, newMap);
        }

        if (Trigger.isUpdate) GW_Account.addAgreementsToCache(GW_sObject.getIdSet(soLst));
        if (Trigger.isUpdate) GW_AccountMemberUnitAssociation.cacheAMUAForAccounts((List<Account>) soLst);
    }

    public override void bulkAfter(List<SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        UTIL.cache(soLst);
        Set<Id> parentAccountIds = GW_sObject.getParentIds(soLst, 'ParentId');
        UTIL.cacheUncachedRecords(parentAccountIds);

        if (!Trigger.isDelete && UTIL.isRunningTestSetup == FALSE) {
            if (Trigger.isInsert) checkMemberUnitAssociation(newMap);
            checkCustomAttributeDefinitions(newMap);
            UTIL_MailTrigger mt = new UTIL_MailTrigger(oldMap, newMap);
        }
        GW_CustomAttribute.cacheCustomAttributes(soLst);
        
        if(runAccountSync){
            runAccountSync = false;
            //checkForTRACTProcessing(soLst, wsscToUpsert, oldMap);
            checkForVIESWSCPRocessing(soLst, wsscToUpsert);
        }
    }

    public override void beforeInsert(SObject so) {
        Account acc = (Account)so;
        setDefaultValuesTract(acc);
        setAccStatus(acc);
        checkAccountMember(acc);
        checkDefaultValuesFromMember(acc);
        checkBankAccountNumber(acc, null);
        checkVatNumber(acc, null);
        checkVatApplication(acc);
        checkBillingPreferenceFields(acc, null);
        //Populate alternative Name with the Name on insert when left blank as a default.
        checkAlternativeName(acc);
        checkVATValidationRequired(acc, null);
        checkPhoneNumbers(acc, null);
		assignAccountTypeToPro(acc);
        acc.Bank_Account_Number_Is_Filled__c = String.isNotBlank(acc.Bank_AccountNumber__c) ? TRUE : FALSE;

        if (UTIL_WSC_Subscription.isSubscribedToWS(acc.Member_Id__c, 'WSC_Fiqas', 'SyncAccount')) {
            checkFiqasSync(acc, null);
        }
        GW_Account.setMandateStatus(acc); //check Mandate Status

        UTIL_FieldValidator.checkObject(acc); // leave as second last
        GW_Account.setStatus(acc); // leave as last
		disableFiqasSync(acc); // leave as last
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Account acc = (Account)so;
        Account oldacc = (Account)oldSo;
        setAccStatus(acc);
        setDefaultValuesTract(acc);
        if (acc.OwnerId != oldacc.OwnerId || acc.Member__c == null) checkAccountMember(acc);
        if (acc.AccountExtId__c == null) checkAccountExtId(acc);
        checkDefaultValuesFromMember(acc);
        checkBankAccountNumber(acc, oldacc);
        checkVatNumber(acc, oldacc);
        checkVatApplication(acc);
        checkVATValidationRequired(acc, oldAcc);
        checkBillingPreferenceFields(acc, oldacc);
        checkPhoneNumbers(acc, oldAcc);
        acc.Bank_Account_Number_Is_Filled__c = String.isNotBlank(acc.Bank_AccountNumber__c) ? TRUE : FALSE;

        if (UTIL_WSC_Subscription.isSubscribedToWS(acc.Member_Id__c, 'WSC_Fiqas', 'SyncAccount')) {
            checkFiqasSync(acc, oldacc);
        }
        checkAddressChange(acc, oldacc);
        checkLocationChange(acc, oldacc);
        UTIL_RecordRestriction.checkFieldLocks(so, oldSo);

		GW_Account.setMandateStatus(acc); //check Mandate Status
        UTIL_FieldValidator.checkObject(acc); // leave as second last
        GW_Account.setStatus(acc); // leave as last
		disableFiqasSync(acc); // leave as last
    }

    public override void beforeDelete(SObject so) {
        UTIL_RecordRestriction.checkDeletionLock(so);
    }

    public override void afterInsert(SObject so) {
        Account acc = (Account) so;
        if (acc.AccountExtId__c == null) setAccountExtId(acc);
        
        // Push to tract when insert is done
        accsPushTractMap.put(acc.Id, acc);
    }
    
    public override void afterUpdate(SObject oldSo, SObject so) {
        Account acc = (Account) so;
        Account oldAcc = (Account)oldSo;
        
        // Push to tract when update is done
        Set<String> notPushTractFields = new Set<String>{'UniquePlatformId__c', 'Tract_AccountId__c', 'Tract_ResponsiblePartyId__c', 'tract_last_error__c', 'LastLocalPlatformSyncMessage__c', 'Tract_LastError__c'};
        if (!GW_sObject.oneOrMoreFieldsChanged(acc, oldAcc, notPushTractFields)) {
            accsPushTractMap.put(acc.Id, acc);
        }
        if (!accsOldMap.containsKey(oldSo.Id)) accsOldMap.put(oldAcc.Id, oldAcc);
    }
    
    public override void andFinally() {
        if (accsToUpdate.size() > 0) {
            try {
                update accsToUpdate;
            } catch (Exception ex) {
                UTIL.throwError('HNDL_Account - Error updating Accounts', ex);
            }
        }
        
        if (oppsToUpdate.size() > 0) {
            try {
               update oppsToUpdate;
            } catch (Exception ex) {
                UTIL.throwError('HNDL_Account - Error updating Opportunities', ex);
            }
        }

        if (wsscToUpsert.size() > 0) {
            try {
               upsert wsscToUpsert UniqueKey__c;
            } catch (Exception ex) {
                UTIL.throwError('HNDL_Account - Error inserting WS_ScheduledCallouts', ex);
            }
        }
        
        if (!accsPushTractMap.isEmpty() && !isAccsPushed) {
            isAccsPushed = true;
            GW_Account.callAccountPush(accsPushTractMap.values(), accsOldMap, 0, (System.isBatch() || System.isFuture() ? 'ApexAsyncJob' : 'ApexTrigger'));
        }
    }

//////////////////////////////
// private helper methods
//////////////////////////////
  
    // Make sure correct member is connected to Account
    private void checkAccountMember(Account acc) {
        if(GW_Account.isGuestUser) return;
        // do not check for Accounts with Recordtype 'Member'
        if (acc.RecordtypeId != UTIL_RecordType.getRecordTypeByName('Account', 'Member').Id) {
        	Member__c m = GW_Member.getMember(acc.OwnerId);
            if (m != null) {
        		acc.Member__c = m.Id;
            }
        }
    }

    private void checkAlternativeName(Account acc) {
        if (acc.AlternativeName__c == null) {
            acc.AlternativeName__c = acc.Name;
        }
    }

    private void checkAccountExtId(Account acc) {
        Member__c mb = GW_Member.memberCache.get(acc.Member__c);
        if (mb != null) acc.AccountExtId__c = mb.MemberId__c + acc.AccAutoNumber__c;
    }

    private void setAccountExtId(Account acc) {
        Member__c mb = GW_Member.memberCache.get(acc.Member__c);
        if (mb != null) {
            Account newAcc = new Account(id=acc.id);
            newAcc.AccountExtId__c = mb.MemberId__c + acc.AccAutoNumber__c;
            accsToUpdate.add(newAcc);
        }
    }

    private void checkDefaultValuesFromMember(Account acc) {
        Member__c mb = GW_Member.memberCache.get(acc.Member__c);
        RecordType agencyRt = UTIL_RecordType.getRecordTypeByName('Account', 'Agency');
        if (mb != null) {
            // VAT settings
            if (acc.VAT__c == null && mb.DefaultVAT__c != null) {
                acc.VAT__c = mb.DefaultVAT__c;
            }
            if (acc.Language_Preference__c == null && mb.DefaultLanguagePreference__c != null) {
                acc.Language_Preference__c = mb.DefaultLanguagePreference__c;
            }
            if (acc.RecordTypeId == agencyRt.Id && mb.DefaultAgencyDiscount__c != null) {
                acc.AccountDiscount__c = ( Trigger.isInsert || acc.AccountDiscount__c == null ) ? mb.DefaultAgencyDiscount__c : acc.AccountDiscount__c;
            }
            acc.FQ_CmrType__c = UTIL_StringParser.parseAndReplace(mb.FQ_CmrType__c,acc);
        }
    }

    private void checkVatApplication(Account acc) {
    	
    	if ( String.isBlank(acc.Company_VAT_No__c) || GW_Account.isVATApplicationMandatory( acc ) ) {
    		acc.Apply_VAT__c = true;
    	} else if ( !GW_Account.isVIESValidationApplicable( acc ) ){
            acc.Apply_VAT__c = false;
        }
    }

    private void checkBillingPreferenceFields(Account acc, Account oldacc) {
        Set<String> mandateField = new Set<String>{'Mandate__c'};

        if (GW_sObject.oneOrMoreFieldsChanged(acc, oldacc, mandateField)) {
            if (acc.Mandate__c != null) {
                echosign_dev1__SIGN_Agreement__c agreement = (echosign_dev1__SIGN_Agreement__c) GW_sObject.queryRecord('echosign_dev1__SIGN_Agreement__c', acc.Mandate__c);
                acc.BillingPreferenceValidFrom__c = agreement.echosign_dev1__DateSignedDate__c;
                acc.Billing_Preference__c = 'Direct Debit';
            }
        }
        acc.BillingPreferenceValidFrom__c = acc.BillingPreferenceValidFrom__c == null ? date.today() : acc.BillingPreferenceValidFrom__c;
    }

    private void checkFiqasSync(Account acc, Account oldacc) {
        Set<String> syncAccFields = new Set<String>{'AccountExtId__c', 'Finance_contact__c', 'FQ_CustomerType__c','Account_Status__c','Name','Apply_VAT__c','Company_VAT_No__c','Company_Reg_No__c','BillingStreet','BillingHouseNumber__c','BillingPostalCode','BillingCity','BillingCountryCode','Billing_Preference__c','FQ_BillingCycle__c','FQ_CmrType__c', 'Mandate__c', 'PaperInvoiceEmail__c', 'Bank_AccountNumber__c', 'Bank_Name__c'};
        Set<String> syncCMRLinkFields = new Set<String>{'FQ_CmrType__c'};
        Set<String> syncPaymentFields = new Set<String>{'Billing_Preference__c'};
		Set<String> syncMandateFields = new Set<String>{'Mandate__c', 'Billing_Preference__c'};

        Boolean resyncRequired = false;
        if (GW_sObject.oneOrMoreFieldsChanged(acc, oldacc, syncAccFields)) resyncRequired = true;
        if (GW_sObject.oneOrMoreFieldsChanged(acc, oldacc, syncPaymentFields) && 'Invoice'.equals(acc.Billing_Preference__c)) {
        	acc.FQ_syncPaymentMethod__c = true;
        	resyncRequired = true;
        }
        if (GW_sObject.oneOrMoreFieldsChanged(acc, oldacc, syncCMRLinkFields)) {
            acc.FQ_syncCmrLink__c = true;
            resyncRequired = true;
        }
        if (GW_sObject.oneOrMoreFieldsChanged(acc, oldacc, syncMandateFields) && acc.Mandate__c != null && 'Direct Debit'.equals(acc.Billing_Preference__c)) {
        	acc.FQ_syncMandateInfo__c = true;
        	resyncRequired = true;
        }
        if (resyncRequired) {
            acc.FQ_syncAccountDetails__c = true;
            acc.FQ_SyncStatus__c = 'Scheduled for Resync';
        }
    }

    private void checkBankAccountNumber(Account acc, Account oldacc) {
        if (!String.isEmpty(acc.Bank_AccountNumber__c)) {
            AccountValidator.IAccountValidator validator = AccountValidator.getValidator(acc);

            if (!validator.checkBankAccountNumber()) {
                acc.Bank_AccountNumber__c.addError('Not a valid Bank Account Number.');
            }
        }
    }

    private void checkVATValidationRequired(Account acc, Account oldAcc) {
        Set<String> companyVatField = new Set<String>{'Company_VAT_No__c'};

        // Insert
        if(oldAcc == null && acc.Company_VAT_No__c != null && GW_Account.isVIESValidationApplicable(acc)) {
            acc.VAT_Check_Result__c = -1;
            acc.VAT_Check_Status__c = 'In Progress';
        }

        // Update -> changed company VAT number field for VIES - applicable country
        if(oldAcc != null && (oldAcc.Company_VAT_No__c != acc.Company_VAT_No__c) && GW_Account.isVIESValidationApplicable(acc)) {
            acc.VAT_Check_Result__c = -1;
            acc.VAT_Check_Status__c = 'In Progress';
        }

        // Update -> changed company VAT number field for NON VIES - applicable country
        if(oldAcc != null && (oldAcc.Company_VAT_No__c != acc.Company_VAT_No__c) && !GW_Account.isVIESValidationApplicable(acc)) {
            acc.VAT_Check_Result__c = 0;
            acc.VAT_Check_Status__c = '';
        }

        // Update -> nullified Company VAT field & Apply VAT not checked
        if(oldAcc != null && (oldAcc.Company_VAT_No__c != acc.Company_VAT_No__c) && acc.Company_VAT_No__c == '' && acc.Apply_VAT__c == FALSE) {
            //Will not happen anymore as there is a new rule for VAT Application,
            //if VAT Number is empty Apply VAT will be true. See checkVatApplication in this class.
            acc.VAT_Check_Result__c = 0;
            acc.VAT_Check_Status__c = 'Invalid';
        }

        // Update -> nullified Company VAT field & Apply VAT checked
        if(oldAcc != null && (oldAcc.Company_VAT_No__c != acc.Company_VAT_No__c) && acc.Company_VAT_No__c == '' && acc.Apply_VAT__c == TRUE) {
            acc.VAT_Check_Result__c = 1;
            acc.VAT_Check_Status__c = 'Valid';
        }
    }

    private void checkForVIESWSCPRocessing(List<SObject> soLst, List<WS_ScheduledCallout__c> wsscToUpsert) {
        if(soLst == null || wsscToUpsert == null) return;

		// Check if Account from VIES-applicable country
        for(SObject so : soLst) {
            Account acc = (Account) so;
            if(GW_Account.isVIESValidationApplicable(acc) && acc.VAT_Check_Status__c == 'In Progress' && !( UserInfo.getUserType() == 'Guest' && acc.SelfService__c == true && acc.Type == 'Pro') ) {
                UTIL_WSC.WSC_Request wsRequest = UTIL_WSC.getWSC_Request('WSC_VIES.Query');
                wsRequest.init(acc.Id);
                wsscToUpsert.add(wsRequest.getScheduledCallout());
            }
        }
    }
    
    /*
    CD-3601 : Switch to BAT_AccountPushTract.cls
    private void checkForTRACTProcessing(List<SObject> soLst, List<WS_ScheduledCallout__c> wsscToUpsert, Map<Id,sObject> oldMap) {
        if(soLst == null || wsscToUpsert == null) return;
        List<SObject> soListForTractUpdate = new List<SObject>();
        List<SObject> soListForAccPush = new List<SObject>();
        List<SObject> soListForAccPayment = new List<SObject>();
		Map<Id,SObject> consForCreateEmailTract = new Map<Id,SObject>();//Used to send email address to TRACT 
		Set<String> accountStatus = new Set<String>{'Active', 'Pending', 'Suspended - Bad Debt', 'Collection Agency', 'Closed', 'Bankrupt'};
        Set<String> syncPaymentFields = new Set<String>{'Billing_Preference__c', 'Mandate_Status__c'};
        Map<Id, List<Contact>> mapContacts = GW_Contact.populateConMap(soLst);
        
        for(SObject so : soLst) {
            Account acc = (Account)so;
            Boolean isAccSyncOnCreationEnabled = UTIL_WSC_Subscription.isAccSyncOnCreationEnabled(acc);
            Boolean isTractEnabled = UTIL_WSC_Subscription.isSubscribedToTRACT(so);
            Boolean isEBayKAdsale = 'EBAYK'.equalsIgnoreCase(acc.MemberId__c) && UTIL_WSC_Subscription.isAccOnlyAdsales(acc.id);
            //AccountPush to local platform only if Sync On Creation is enabled or Local Id is not blank
            if (GW_Account.isReadyForLocalPlatformPush(acc) && isAccSyncOnCreationEnabled && !GW_Opportunity.userAsSelfService && !isEBayKAdsale) {
                soListForAccPush.add(so);
            }
            //Update callout to tract only if Tract Id not blank
            if(isTractEnabled) {
                Account oldAcc;
                if(oldMap != null && oldMap.containsKey(so.Id))
                    oldAcc = (Account)oldMap.get(so.Id);
                if(String.isNotBlank(acc.Tract_AccountId__c) && oldAcc != null && String.isNotBlank(oldAcc.Tract_AccountId__c) && acc.Tract_ResponsiblePartyId__c != null)
                    soListForTractUpdate.add(so);
				if(acc.Finance_contact__c != null && String.isNotBlank(acc.Tract_AccountId__c) && oldAcc != null && String.isBlank(oldAcc.Tract_AccountId__c) && String.isNotBlank(acc.Tract_ResponsiblePartyId__c)){
					List<Contact> cons = mapContacts.get(acc.Id);
                    if(cons != null){
                        for(Contact con : cons){
                            if(con.Id == acc.Finance_contact__c && String.isNotBlank(con.Role__c) && con.Role__c.contains(GW_Contact.ROLE_FINANCE_CONTACT))
                                consForCreateEmailTract.put(con.Id, con);
                        }
                    }
				}
                if (oldMap != null && GW_sObject.oneOrMoreFieldsChanged(acc, oldAcc, syncPaymentFields) &&
                        (( acc.Billing_Preference__c == 'Direct Debit' && acc.Mandate_Status__c == 'OK') || acc.Billing_Preference__c == 'Invoice') ) {
                    soListForAccPayment.add(so);
                }
            }
        }

        System.debug('AccPush --- ' + soListForAccPush);
        if(!soListForAccPush.isEmpty()){
            UTIL_WSC.checkForProcessing('WSC_API_SFECG_v1.AccountPush', soListForAccPush, wsscToUpsert);
        }
        if(!soListForTractUpdate.isEmpty()){
            UTIL_WSC.checkForProcessing('WSC_Tract.BillingAccountUpdateAddr', soListForTractUpdate, wsscToUpsert);
			UTIL_WSC.checkForProcessing('WSC_Tract.ServiceAccountUpdateAddr', soListForTractUpdate, wsscToUpsert);
            UTIL_WSC.checkForProcessing('WSC_Tract.BillingAccountUpdateResponsible', soListForTractUpdate, wsscToUpsert);
		}
		if(!consForCreateEmailTract.isEmpty()){
			UTIL_WSC.checkForProcessing('WSC_Tract.CreateEmailAddress', consForCreateEmailTract.values(), wsscToUpsert);
        }
        if (!soListForAccPayment.isEmpty()) {
            UTIL_WSC.checkForProcessing('WSC_Tract.BillingAccountAutoPayment', soListForAccPayment, wsscToUpsert);
        }
    }
    */

    private void checkVatNumber(Account acc, Account oldAcc) {
    	if (isIgnoredCheckVat) return;
        if (!String.isEmpty(acc.BillingCountryCode)) {
            AccountValidator.IAccountValidator validator = AccountValidator.getValidator(acc);

            if (!validator.checkAndSetCompanyTaxDetails()) {
                acc.Company_VAT_No__c.addError('Not a valid VAT number.');
            }
        }
    }

    private void checkMemberUnitAssociation(Map<Id, sObject> newMap) {
        try {
        	GW_AccountMemberUnitAssociation.ensureAccountMemberUnitAssociations(newMap.keySet());
        } catch (Exception e) {
            UTIL.throwError('checkMemberUnitAssociation Exception Thrown: ', e);
        }
    }

    private void checkCustomAttributeDefinitions(Map<Id, sObject> newMap) {
        try {
        	if (newMap != null) GW_CustomAttribute.ensureCustomAttributeDefinitions(newMap.keySet(), 'Account');
        } catch (Exception e) {
        	UTIL.throwError('Error in checkCustomAttributeDefinitions: ', e);
        }
    }

    private void validateCustomAttributes(Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        Map<Id, Map<String, String>> validationResults = GW_CustomAttribute.validateCustomAttributes(oldMap,newMap);
        for (Id accId : validationResults.keySet()) {
            Account a = (Account) newMap.get(accId);
            a.MandatoryDetailsError__c = validationResults.get(accId).get('MandatoryDetailsError__c');
            a.MandatoryDetailsFilled__c = Boolean.valueOf(validationResults.get(accId).get('MandatoryDetailsFilled__c'));
        }
    }

    private void checkPhoneNumbers(Account acc, Account oldAcc) {
    	if (isIgnoredCheckPhoneNumber)
          return;

        Set<String> phoneFields = new Set<String>{'Phone','Other_Phone__c'};
        VAL_Global.checkPhoneNumbers(acc, oldAcc, phoneFields);
    }

    private void checkAddressChange(Account acc, Account oldacc) {
        Set<String> syncLocationsFields = new Set<String>{'BillingCity','BillingCountry','BillingCountryCode','BillingPostalCode','BillingState','BillingStateCode','BillingStreet', 'ShippingCity','ShippingCountry','ShippingCountryCode','ShippingPostalCode','ShippingState','ShippingStateCode','ShippingStreet', 'SyncLocationSuspended__c'};
        if (GW_sObject.oneOrMoreFieldsChanged(acc, oldacc, syncLocationsFields) && acc.SyncLocationSuspended__c != true) {
            acc.SyncLocation__c = true;
        }
    }

    private void checkLocationChange(Account acc, Account oldacc) {
        Set<String> syncLocationsFields = new Set<String>{'BillingLatitude', 'BillingLongitude', 'ShippingLatitude', 'ShippingLongitude', 'SyncRegionSuspended__c'};
        if (GW_sObject.oneOrMoreFieldsChanged(acc, oldacc, syncLocationsFields) && acc.SyncRegionSuspended__c != true) {
            acc.SyncRegion__c = true;
        }
    }

    private void setDefaultValuesTract(Account acc){
        acc.ServiceCity__c = acc.ServiceCity__c == null ? acc.BillingCity : acc.ServiceCity__c;
        acc.ServiceStreet__c = acc.ServiceStreet__c == null ? acc.BillingStreet : acc.ServiceStreet__c;
        acc.ServicePostalCode__c = acc.ServicePostalCode__c == null ? acc.BillingPostalCode : acc.ServicePostalCode__c;
        
            
        if(acc.ServiceCountry__c == null){
            if(acc.BillingCountryCode != null){
                acc.ServiceCountry__c = HNDL_Account.getTractCountryCodes(acc.BillingCountryCode,'FullName');
            }
        }

        if(acc.ServiceState__c == null){
            if(acc.BillingCountryCode != null && acc.BillingStateCode != null){
                String s = HNDL_Account.getTractCountryCodes(acc.BillingCountryCode+':'+acc.BillingStateCode,'FullName');
                if(String.isNotBlank(s))
                acc.ServiceState__c = s.trim();
            }
        }
        
    }

    public static String getTractCountryCodes(String strCountryCode,String strLetters){
        if(String.isBlank(strCountryCode)) return '';
        String code = '';
        if(!countryStateISO.isEmpty() && countryStateISO.containsKey(strCountryCode))
            if(strLetters == '3')
                code = countryStateISO.get(strCountryCode).ThreeLetterCode__c;
            else if(strLetters == '2')
                code = countryStateISO.get(strCountryCode).TwoLetterCode__c;
            else
                code = countryStateISO.get(strCountryCode).FullName__c;
        return code; 
    }

    private void setAccStatus(Account acc) {
        if(acc.Account_Status__c != null && acc.Account_Status__c.contains('Suspended'))
            acc.DunningStatus__c =  'Suspension';
    }
	
	// Disable Account sync to Fiqas if account is subscribed to Tract
    private void disableFiqasSync(Account acc) {
        if(acc.SelfService__c == false){
	        // do not check for Accounts with Recordtype 'Member'
	        if (acc.RecordtypeId != UTIL_RecordType.getRecordTypeByName('Account', 'Member').Id) {
	            Member__c objMember;
	            if(acc.Member__c == null)
	                objMember = GW_Member.getMember(acc.OwnerId);
	            else
	                objMember = GW_Member.memberCache.get(acc.Member__c);
	            if (objMember != null) {
	                MemberUnit__c mU = (MemberUnit__c) GW_MemberUnit.getMemberUnit2(acc.OwnerId, acc);
	                if(mU != null && mU.EnableTRACT__c){
	                    acc.FQ_syncAccountDetails__c = FALSE;
	                    acc.FQ_syncPaymentMethod__c = FALSE;
	                }
	            }
	        }
		} //end user_license check
    }
	
	private void assignAccountTypeToPro(Account account){
    	if(account.SelfService__c == false && [select Id, DeveloperName from UserRole where Id =: UserInfo.getUserRoleId() and DeveloperName = 'EBAYKPR' ].size() > 0) {
    		account.Type = 'Pro';
			account.BlockFTPEmail__c = true;
    	}
    }
    // Constructor
    public HNDL_Account() { super('HNDL_Account', Account.sObjectType); }
}