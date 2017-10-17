///////////////////////////////////////////////////////////////////////////
// Class Account Gateway  --
//
// Used as a central location to manage interactions with the Account Object
//
// Author:  Jochem van den Heuvel
// Email:   jochemvandenheuvel@screenfields.nl
//
///////////////////////////////////////////////////////////////////////////
public with sharing class GW_Account
{
    private static final Schema.sObjectType GW_BASEOBJECT = Account.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Account';
    private static final String DEFAULTFIELDSET = 'Default'; // default fieldset for this type
    public static final Set<String> availablePendingStatus = new Set<String>{'Draft','Out for Signature', 'Waiting for Counter-Signature', 'Send in Progress', 'Waiting for Counter-Approval', 'Out for Approval'};
    public static Boolean syncToFiqas = true; // can be used to prevent syncing Accounts to Fiqas
    private static Map<Id, List<sObject>> accountAgreementCache = new Map<Id, List<sObject>>();
    
     public static Boolean isGuestUser = checkIsGuestUser();
    
//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Account           getRecord(Id id)                    { return (Account) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,Account>   getMap(Set<id> ids)                 { return new Map<id,Account>( getList(ids) ); }
    public static List<Account>     getList(Set<id> ids)                { return (List<Account>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }
    public static List<Account>     getList(Set<Id> ids, List<String> additionalFields) { return (List<Account>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids, additionalFields); }
	
	//21 July 2017
	public static List<Account>     getListForUpdate(Set<id> ids)       { return (List<Account>) GW_sObject.queryRecordsForUpdate(GW_BASEOBJECTNAME, ids, new List<String>()); }
    public static List<Account>     getListForUpdate(Set<id> ids, List<String> additionalFields) { return (List<Account>) GW_sObject.queryRecordsForUpdate(GW_BASEOBJECTNAME, ids, additionalFields); }
//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of parents(base object) from a list of child objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Opportunity
    public static Map<id,Account>  getMapFromRelated(List<Opportunity> lst)        { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>          getIdSetFromRelated(List<Opportunity> lst)      { return GW_sObject.getParentIds(lst, 'AccountId'); }

    // Invoice
    public static Map<id,Account>  getMapFromRelated(List<Invoice__c> lst)        { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>          getIdSetFromRelated(List<Invoice__c> lst)      { return GW_sObject.getParentIds(lst, 'BillingAccount__c'); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of childs(base object) from a list of parent objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Opportunity
    //public static List<Opportunity>   getListFromRelated(Id parentId, String fieldSet)        { return (List<Opportunity>) GW_sObject.getChildren(parentId, 'Opportunities'); }
    //public static List<Opportunity>   getListFromRelated(Set<Id> parentIds, String fieldSet)  { return (List<Opportunity>) GW_sObject.getChildren(parentIds, 'Opportunities'); }
    //public static Set<Id>             getIdSetFromRelated(Set<Id> parentIds)                  { return GW_sObject.getChildIds(parentIds, 'Opportunities'); }
	
	public static List<echosign_dev1__SIGN_Agreement__c>		getRelatedAgreements(Id parentId) 		{ return GW_sObject.getChildren(parentId, 'echosign_dev1__Agreements__r', 'echosign_dev1__DateSigned__c desc'); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static final String DEFAULT_ACCNAME = 'ACME Inc.';

    private static User userAdmin; //for testing

    public static Account createSObject() { return createSObject(DEFAULT_ACCNAME); }
    public static Account createSObject(String accName) { return new Account(Name=accName); }
    public static Account createSObject(String accName, Account parentAcc) {
        Account acc = createSObject(accName);
        if (parentAcc != null) acc.ParentId = parentAcc.Id;
        return acc;
    }

    public static Account insertSObject() {
        Account acc = createSObject();
        insert acc;

        return acc;
    }


//////////////////////////////////////////////////////////////////////////////////////////////////////
// Custom logic
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Checks whether given account's country is applicable for VIES VAT validation
    public static Boolean isVIESValidationApplicable(Account acc) {
        // Check if VAT field has value
        if(acc.Company_VAT_No__c == NULL || acc.Company_VAT_No__c == '') {
            return FALSE;
        }

        // Check if applicable countries are defined in custom settings
        String viesCountriesString = UTIL.getConfig('VIESCountries');

        if(viesCountriesString == NULL || viesCountriesString.length() == 0) {
            return FALSE;
        }

        // Validate if the country is VIES - applicable
        Set<String> viesCountries = new Set<String>(viesCountriesString.split(','));
        String countryCode = null;
        if(acc.Company_VAT_No__c != null && acc.Company_VAT_No__c.length() >= 2) {
            countryCode = acc.Company_VAT_No__c.substring(0,2);
        }

        if(countryCode != null && viesCountries.contains(countryCode)) {
            return TRUE;
        }

        return FALSE;
    }

    // Checks whether the VAT application should be mandatory for a given account
    public static Boolean isVATApplicationMandatory(Account acc) {
        
        // Check if applicable countries are defined in custom settings
        String vatMandatoryCountriesString = UTIL.getConfig('MandatoryVATApplianceCountries');

        if( vatMandatoryCountriesString == NULL || vatMandatoryCountriesString.length() == 0) {
            return FALSE;
        }

        // Validate if the country has mandatory VAT application
        Set<String> countries = new Set<String>( vatMandatoryCountriesString.split(',') );

        String countryCode = null;
        if(acc.Company_VAT_No__c != null && acc.Company_VAT_No__c.length() >= 2) {
            countryCode = acc.Company_VAT_No__c.substring(0,2);
        }

        if( countryCode != null && countries.contains( countryCode ) ) {
            return TRUE;
        }

        return FALSE;
    }

    // checks for Accounts that needs syncing, and starts sync process
    public static void startAccountSyncFiqas() {
        string whereClause = 'FQ_syncAccountDetails__c = TRUE OR FQ_syncMandateInfo__c = TRUE OR FQ_syncPaymentMethod__c = TRUE';
        List<Account> accs = GW_sObject.queryRecords('Account', whereClause);
        GW_Account.syncBatchWithFiqas(accs);
    }

    // syncs batch to Fiqas
    public static void syncBatchWithFiqas(List<Account> accs) {
        BAT_AccountSyncFiqas syncWithFiqas = new BAT_AccountSyncFiqas(accs);
        Database.executeBatch(syncWithFiqas,4);
    }

    public static void startAccountValidation() {
        string whereClause = ' (Billing_Preference__c = \'Direct Debit\' OR Bank_AccountNumber__c <> null OR Company_Vat_No__c <> null) AND AccountExtId__c LIKE \'THBEL%\'';
        List<Account> accs = GW_sObject.queryRecords('Account', whereClause);
        GW_Account.batchAccountValidationAndEnrichment(accs);
    }

    // Account validation batch
    public static void batchAccountValidationAndEnrichment(List<Account> accs) {
        BAT_AccountValidationAndEnrichment batch = new BAT_AccountValidationAndEnrichment(accs);
        Database.executeBatch(batch,4);
    }

    public static String getAddressAsString(Account a, String addressType) {
        String result;
        if (addressType == 'Shipping') {
            String shippingCountry;
            String shippingDetail;
            if (a.ShippingCity != null && a.ShippingStreet != null) {
                result = a.ShippingStreet + ' ' + a.ShippingCity;

                if (a.ShippingCountry != null) {
                    shippingCountry = a.ShippingCountry;
                } else if (a.ShippingCountryCode != null) {
                    shippingCountry = a.ShippingCountryCode;
                }

                if (a.ShippingPostalCode != null) {
                    shippingDetail = a.ShippingPostalCode;
                } else if (a.ShippingStateCode != null) {
                    shippingDetail = a.ShippingStateCode;
                }

                if (shippingDetail != null) {
                    result += ' ' + shippingDetail;
                }
                if (shippingCountry != null) {
                    result += ' ' + shippingCountry;
                }
            }
        } else if (addressType == 'Billing') {
            String billingCountry;
            String billingDetail;
            if (a.BillingCity != null && a.BillingStreet != null) {
                result = a.BillingStreet + ' ' + a.BillingCity;

                if (a.BillingCountry != null) {
                    billingCountry = a.BillingCountry;
                } else if (a.BillingCountryCode != null) {
                    billingCountry = a.BillingCountryCode;
                }

                if (a.BillingPostalCode != null) {
                    billingDetail = a.BillingPostalCode;
                } else if (a.BillingStateCode != null) {
                    billingDetail = a.BillingStateCode;
                }

                if (billingDetail != null) {
                    result += ' ' + billingDetail;
                }
                if (billingCountry != null) {
                    result += ' ' + billingCountry;
                }
            }
        }

        return result;
    }

    public static void retrieveAccountLocations(List<Account> accs) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account a : accs) {
            Boolean error = false;
            String errorMessage = null;
            String billingAddressString = getAddressAsString(a, 'Billing');
            String shippingAddressString = getAddressAsString(a, 'Shipping');

            if (billingAddressString != null) {
                try {
                    Location billingCoordinates = WSC_GeoLocation.retrieveCoordinatesForAddress(billingAddressString);
                    if (billingCoordinates == null) {
                        error = true;
                        a.BillingLatitude = null;
                        a.BillingLongitude = null;
                    } else {
                        a.BillingLatitude = billingCoordinates.getLatitude();
                        a.BillingLongitude = billingCoordinates.getLongitude();
                    }
                } catch (Exception e) {
                    error = true;
                    errorMessage = e.getMessage();
                    a.BillingLatitude = null;
                    a.BillingLongitude = null;
                }
            }

            if (shippingAddressString != null) {
                try {
                    Location shippingCoordinates = WSC_GeoLocation.retrieveCoordinatesForAddress(shippingAddressString);
                    if (shippingCoordinates == null) {
                        error = true;
                        a.ShippingLatitude = null;
                        a.ShippingLongitude = null;
                    } else {
                        a.ShippingLatitude = shippingCoordinates.getLatitude();
                        a.ShippingLongitude = shippingCoordinates.getLongitude();
                    }
                } catch (Exception e) {
                    error = true;
                    errorMessage = e.getMessage();
                    a.ShippingLatitude = null;
                    a.ShippingLongitude = null;
                }
            }

            if (error) {
                a.SyncLocationError__c = true;
                if (errorMessage != null) {
                    a.SyncLocationErrorDetail__c = errorMessage;
                }
            } else {
                a.SyncLocationError__c = false;
            }

            a.SyncLocation__c = false;
            accountsToUpdate.add(a);
        }
        try {
            update accountsToUpdate;
        } catch (Exception e) {
            UTIL.throwError('GW_Account.retrieveAccountLocations(): Error updating Accounts: ',e);
        }
    }

    public static void retrieveAccountRegions(List<Account> accs) {
        List<Account> accountsToUpdate = new List<Account>();
        for (Account a : accs) {
            Boolean error = false;
            String errorMessage = null;


            if (a.BillingLatitude != null && a.BillingLongitude != null) {
                Map<String,String> billingRegions = null;
                Map<String,String> convertedRegions = null;
                try {
                    billingRegions = WSC_GeoLocation.retrieveRegionsForCoordinates(a.BillingLatitude, a.BillingLongitude);
                    convertedRegions = UTIL_MapInsight.convertFusionTableResponseToRegions(billingRegions);
                } catch (Exception e) {
                    error = true;
                    errorMessage = e.getMessage();
                }
                if (billingRegions == null || billingRegions.keySet().size() == 0) {
                    error = true;
                    a.BillingContinent__c = null;
                    a.BillingCountry__c = null;
                    a.BillingRegion__c = null;
                    a.BillingSubRegion__c = null;
                    a.BillingProvince__c = null;
                    a.BillingMunicipality__c = null;
                    a.BillingCity__c = null;
                    a.BillingDistrict__c = null;
                } else {
                    a.BillingContinent__c = convertedRegions.get('Continent__c');
                    a.BillingCountry__c = convertedRegions.get('Country__c');
                    a.BillingRegion__c = convertedRegions.get('Region__c');
                    a.BillingSubRegion__c = convertedRegions.get('SubRegion__c');
                    a.BillingProvince__c = convertedRegions.get('Province__c');
                    a.BillingMunicipality__c = convertedRegions.get('Municipality__c');
                    a.BillingCity__c = convertedRegions.get('City__c');
                    a.BillingDistrict__c = convertedRegions.get('District__c');
                }
            }

            if (a.ShippingLatitude != null && a.ShippingLongitude != null) {
                Map<String,String> shippingRegions = null;
                Map<String,String> convertedRegions = null;
                try {
                    shippingRegions = WSC_GeoLocation.retrieveRegionsForCoordinates(a.ShippingLatitude, a.ShippingLongitude);
                    convertedRegions = UTIL_MapInsight.convertFusionTableResponseToRegions(shippingRegions);
                } catch (Exception e) {
                    error = true;
                    errorMessage = e.getMessage();
                }
                if (shippingRegions == null || shippingRegions.keySet().size() == 0) {
                    error = true;
                    a.ShippingContinent__c = null;
                    a.ShippingCountry__c = null;
                    a.ShippingRegion__c = null;
                    a.ShippingSubRegion__c = null;
                    a.ShippingProvince__c = null;
                    a.ShippingMunicipality__c = null;
                    a.ShippingCity__c = null;
                    a.ShippingDistrict__c = null;
                } else {
                    a.ShippingContinent__c = convertedRegions.get('Continent__c');
                    a.ShippingCountry__c = convertedRegions.get('Country__c');
                    a.ShippingRegion__c = convertedRegions.get('Region__c');
                    a.ShippingSubRegion__c = convertedRegions.get('SubRegion__c');
                    a.ShippingProvince__c = convertedRegions.get('Province__c');
                    a.ShippingMunicipality__c = convertedRegions.get('Municipality__c');
                    a.ShippingCity__c = convertedRegions.get('City__c');
                    a.ShippingDistrict__c = convertedRegions.get('District__c');
                }
            }
            if (error) {
                a.SyncRegionError__c = true;
                if (errorMessage != null) {
                    a.SyncRegionErrorDetail__c = errorMessage;
                }
            } else {
                a.SyncRegionError__c = false;
            }
            a.SyncRegion__c = false;
            accountsToUpdate.add(a);
        }
        try {
            update accountsToUpdate;
        } catch (Exception e) {
		    UTIL.throwError('GW_Account.retrieveAccountRegions(): Error updating Accounts: ',e);
        }
    }

    	// status calculator
	public static Boolean setStatus(Account acc) {
        StatusCalculator.IStatusCalculator statusCalc = new AccountStatusCalculator(acc);
        Boolean statusChanged = statusCalc.setStatus(acc);

        return statusChanged; // return TRUE if status changed
	}

	public class AccountStatusCalculator extends StatusCalculator.AbstractStatusCalculator {
		// constructor
		public AccountStatusCalculator(Account acc) {
			super(acc, new Map<Integer, String> { 0 => 'Draft', 1 => 'Ready To Sell', 2 => 'Ready to Bill' });
		}

		public override Boolean passCriteria(sObject so, Integer stage) {
            Account acc = (Account) so;
			if (stage == 0) { return true; } // Draft
			if (stage == 1) { return acc.LowestStatusNumIncomplete__c > 1 && acc.LowestStatusNumSyncError__c > 1; } // Ready to Sell
//			if (stage == 2) { return acc.LowestStatusNumIncomplete__c > 2 && acc.LowestStatusNumSyncError__c > 2; } // Ready to Bill
			return false;
		}
	}

    public static void checkStatusAndUpdate(List<Account> accs) {
        List<Account> accsToUpdate = new List<Account>();
        if (!accs.isEmpty()) {
            for (Account acc : accs) {
                UTIL_FieldValidator.checkObject(acc);
                GW_Account.setStatus(acc);
                accsToUpdate.add(acc);
            }
            if (!accsToUpdate.isEmpty()) {
                try {
                    update accsToUpdate;
                } catch(Exception e) {
                    UTIL.throwError('GW_Account.checkStatusAndUpdate - Could not update the status');
                }
            }
        }
    }

    public static List<UTIL_FieldMapper.MappedElement> getAccountMapperFields(Account acc, Account parent) {
		List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();

        elements.add( new UTIL_Fieldmapper.mappedField('localId', 		acc.LocalPlatformId__c, 'String', 32, FALSE, FALSE) );
        elements.add( new UTIL_Fieldmapper.mappedField('accountExtId', 	acc.AccountExtId__c, 'String', 15, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('salesforceId', 	acc.Id, 'String', 18, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('localParentId', (parent == null ? '' : parent.LocalPlatformId__c), 'String', 50, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('status', 		acc.Account_Status__c, 'String', 50, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('accountName', 	acc.Name, 'String', 255, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('vatId', 		acc.Company_VAT_No__c, 'String', 25, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('Created', 		acc.CreatedDate, 'Datetime', 25, TRUE, FALSE) );
        elements.add( new UTIL_Fieldmapper.mappedField('Modified', 		acc.LastModifiedDate, 'Datetime', 25, TRUE, FALSE) );
        elements.add( new UTIL_Fieldmapper.mappedField('OwnerId', 		acc.OwnerId, 'Reference', 25, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('phone', 		acc.Phone, 'String', 40, FALSE, TRUE));

		return elements;
	}
	
	public static void addAgreementsToCache(Set<Id> accountIds) {
        Map<id, List<SObject>> childMap = GW_sObject.getChildrenMap(accountIds, 'echosign_dev1__Agreements__r', 'CreatedDate DESC' );
        accountAgreementCache.putAll(childMap);
	}

    //suy sreymol 04 Oct 2016 > to get list of Childrend by parent id
    public static List<sObject> getCachedAccountAgreements(Id soId) {
        if (null != soId && accountAgreementCache.containsKey(soId))  {
            return accountAgreementCache.get(soId);
        }
        return new List<sObject>();
    }
    
    public static void setMandateStatus(Account account) {

        Boolean isSubscribedToTract = UTIL_WSC_Subscription.isSubscribedToTRACT(account);

        if (account.Billing_Preference__c == 'Invoice' && !isSubscribedToTract ) {
            account.Mandate_Status__c = 'NA';
        } else {
            List<echosign_dev1__SIGN_Agreement__c> children = GW_Account.getCachedAccountAgreements(account.Id) == null ? new List<echosign_dev1__SIGN_Agreement__c>() : GW_Account.getCachedAccountAgreements(account.Id);
            if( children.isEmpty() ) {
                 account.Mandate_Status__c = '';
            } else if( children.size() == 1 ) {
                account.Mandate_Status__c = getAgmMandateStatus( children[0] , isSubscribedToTract );
            } else {
                Set<String> mandateStati = new Set<String>();
                String status, latestStatus;
                for( integer k = 0; k < children.size(); k++ ) {
                    status = getAgmMandateStatus( children[k] , isSubscribedToTract );
                    if( k == 0 ) latestStatus = status;
                    mandateStati.add( status );
                }
                
                if( mandateStati.contains( 'OK' ) ){
                    account.Mandate_Status__c = 'OK'; 
                } else {
                    account.Mandate_Status__c = latestStatus;
                }
            }
        }
    }   
    
    private static String getAgmMandateStatus( echosign_dev1__SIGN_Agreement__c agm , Boolean isSubscribedToTract ){
        
        String mandateStatus = 'Not Signed';
        Opportunity opp = agm.echosign_dev1__Opportunity__c != null ? (Opportunity) Util.getCached( agm.echosign_dev1__Opportunity__c ) : null;

        if ((!isSubscribedToTract && agm.Billing_Preference__c == 'Direct Debit') ||
                (isSubscribedToTract && ((agm.Type__c == 'IO' && agm.echosign_dev1__Opportunity__c != null && opp.Include_SEPA_mandate__c) || agm.Type__c == 'Mandate'))) {

            //if a Mandate is waiting for signature => Mandate status = Pending
            if( availablePendingStatus.contains(agm.echosign_dev1__Status__c) ) {
                mandateStatus = 'Pending';
            }
            //if one of related Mandate is validated sucessfully, Mandate Status --> OK
            else if( 'Success'.equalsIgnoreCase(agm.Mandate_Status__c) ) {
                mandateStatus = 'OK';
            }
            //if one of related Mandate is validated fail and there is no other mandate success, Mandate Status --> Failed
            else if( 'Failed'.equalsIgnoreCase(agm.Mandate_Status__c) ) {
                mandateStatus = 'Failed';
            }
        }
        return mandateStatus;
    }

	public static Account checkCreditStatus( Opportunity oldOpp , Opportunity newOpp ){
		Account ownerAccount;
		ownerAccount = (Account) UTIL.getCached( newOpp.Billing_Account__c );
		if( ownerAccount == null ){
			ownerAccount = (Account) UTIL.getCached( newOpp.AccountId );
		}
		
		// Checks the Credit Rating status only if just approved and being the first opportunity of the Account   
        if( oldOpp.numStatus__c != 1 && newOpp.numStatus__c == 1 && ownerAccount.Roll_Up_Opportunities__c == 1 ){
            // System.enqueueJob( new Q_SyncCreditRating( ownerAccount ) );
            return ownerAccount;
        }		
        
        return null;
	}
	/**
     * @createdDate: 17-11-2016
     * @createdBy: Sochanra
     * @param: mapLead - mapping of ConvertedAccountId and Lead
     * @desc: Update the converted account's field Type with lead's Type__c
	 */
	public static void convertLeadToAccount(Map<Id,Lead> mapLead){

		List<Account> lstAccTobeUpdated = new List<Account>();
		for(Account acc : (List<Account>) GW_sObject.queryRecords('Account', 'Id IN: idSet1', new Map<String, Set<id>>{'idSet1' => mapLead.keySet()})){
			if(mapLead.get(acc.Id) == null) continue;
			acc.Type = mapLead.get(acc.Id).Type__c;
			acc.AccountSource = mapLead.get(acc.Id).LeadSource;
			acc.SIC__c = mapLead.get(acc.Id).SIC__c;
			lstAccTobeUpdated.add(acc);
		}
		update lstAccTobeUpdated;
	}

    public static void validatePhoneNumber(Account acc, Set<String> phoneFields) {
        if(acc == null || phoneFields == null) return;

        for(String phoneField : phoneFields) {
            String fieldVal = (String) (acc.get(phoneField));
            fieldVal = (fieldVal == null ? '' : fieldVal.trim());

            if(fieldVal.indexOf('+') == -1 || fieldVal.lastIndexOf('+') != 0) {
                UTIL.throwError(phoneField + ' number should start with \'+\' sign, please update with correct value.');
            }else{
                Pattern isNumbers = Pattern.Compile('^[0-9]+$');
                fieldVal = fieldVal.substring(1, fieldVal.length());
                Matcher phoneMatch = isnumbers.matcher(fieldVal);

                if(!phoneMatch.Matches()){
                    UTIL.throwError(phoneField + ' number should contain only digits, please update with correct value.');
                }else if(fieldVal.length() < 8){
                    UTIL.throwError(phoneField + ' number length should be minimum of 8 characters, please update with correct value.');
                }
            }
        }
    }
	
	/**
     * @createdDate: 14-02-2017
     * @createdBy: suy sreymol
     * @param: accountId - an account ID
     * @desc: to check whether the account has mandate pending (status draft/out for signature) 
     * @update: by jeze. for ticket CD-2276. Removed Draft from penddingStatus set. It should only return true is there is a mandate with status 'Out for Signature'
	 */
	public static Boolean hasPendingMandate(String accountId) {
    	Set<String> penddingStatus = new Set<String>{'Out for Signature'};
    	List<echosign_dev1__SIGN_Agreement__c> mandates = GW_Agreement.getRelatedMandate(null, null, new Set<String>{accountId});
    	for ( echosign_dev1__SIGN_Agreement__c md : mandates ) if (penddingStatus.contains(md.echosign_dev1__Status__c+'') && 'Mandate'.equalsIgnoreCase(md.Type__c+'')) return true;
    	return false;
    }
	
	private static Boolean checkIsGuestUser() {
        return UserInfo.getUserType() == 'Guest';
    }

    public static void suspendAccountOnSubscTermination( String opportunityId ){
    	
        // Get which member units allow the account to be suspended when the subscription is terminated
        String memberUnitsStr = UTIL.getConfig('SuspendAcctOnSubscTermination');

        if( memberUnitsStr == NULL || memberUnitsStr.length() == 0) {
            return;
        }
        Set<String> memberUnits = new Set<String>( memberUnitsStr.split(',') );
        
    	Opportunity opp = (Opportunity) UTIL.getCached( opportunityId );
    	
    	if( memberUnits.contains( opp.MemberUnitId__c )  ){
    		Account acc = (Account) UTIL.getCached( opp.AccountId );
    		acc.Account_Status__c = 'Suspended - Bad Debt';
    		update acc;
    	}
    }
    
    public static Boolean isReadyForLocalPlatformPush (Account acc) {
        Set<String> accountStatus = new Set<String>{'Active', 'Pending', 'Suspended - Bad Debt', 'Collection Agency', 'Closed', 'Bankrupt'};
        Boolean isValidStatus = accountStatus.contains(acc.Account_Status__c+'');
        return isValidStatus && !Approval.isLocked(acc.Id);
    }
    
    // Account Push flow immediately account is updated, will resync all steps
    public static final List<String> STEPS_ACCOUNT_PUSH = new List<String> {
        'WSC_API_SFECG_v1.AccountPush',             //0
        'WSC_Tract.BillingAccountCreate',           //1
        'WSC_Tract.BillingAccountUpdateAddr',       //2
        'WSC_Tract.ServiceAccountUpdateAddr',       //3
        'WSC_Tract.BillingAccountUpdateResponsible',//4
        'WSC_Tract.CreateEmailAddress',             //5
        'WSC_Tract.BillingAccountUpdate',           //6
        'WSC_Tract.BillingAccountAutoPayment'       //7
    };
    
    public static void callAccountPush(Account[] accs, Map<Id, Account> oldMap, Integer currentStep, String contextInvocation) {
        //Existing Batch like "BAT_BookingPushTract" will cover this job 
        if (contextInvocation == 'ApexAsyncJob' || GW_Opportunity.userAsSelfService) return;
        BAT_AccountPushTract accountPushTract = new BAT_AccountPushTract(accs, oldMap, currentStep);
        accountPushTract.contextInvocation = contextInvocation;
        if (!UTIL.isRunningTestSetup) Database.executeBatch(accountPushTract, Test.isRunningTest() ? 200 : 1);
    }
    
    // Not support many accounts, 5 max accounts
    public static Account[] sendAccountPush(Account[] accs, Map<Id, Account> oldMap, Integer currentStep) {
        HNDL_Account.runAccountSync = false;
        Map<Id, List<Contact>> mapContacts = GW_Contact.populateConMap(accs);
        
        List<Account> nextList = new List<Account>();
        for (Account acc : accs) {
            List<Contact> cons = mapContacts.get(acc.Id) == null ? new List<Contact>() : mapContacts.get(acc.Id);
            Contact contPush = new Contact();
            for (Contact con : cons) {
                if(con.Id == acc.Finance_contact__c && String.isNotBlank(con.Role__c) && con.Role__c.contains(GW_Contact.ROLE_FINANCE_CONTACT)) contPush = con;
            }
            //Ensure all item has been rechecked
            nextList.add(acc);
            Integer todoStep = verifyStep(acc, oldMap, contPush, currentStep);
            if (todoStep == STEPS_ACCOUNT_PUSH.size()) continue;
            String methodCall = STEPS_ACCOUNT_PUSH[todoStep];
            String recordContextId = acc.Id; 
            if (methodCall.contains('CreateEmailAddress')) {
                recordContextId = contPush.Id;
            }
            UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request(methodCall);
            req.init(recordContextId); 
            UTIL_WSC.WSC_Result resp = req.call();
        }
        return nextList;
    }
    
    private static Integer verifyStep(Account acc, Map<Id, Account> oldMap, Contact contPush, Integer currentStep) {
        //Account is not ready to sell 
        if (!GW_Account.isReadyForLocalPlatformPush(acc)) return STEPS_ACCOUNT_PUSH.size();
        //Total number of minutes < 1 is account create event trigger
        Decimal minutes = (Decimal.valueOf(acc.LastModifiedDate.getTime() - acc.CreatedDate.getTime()))/1000/60;
        //Initialize request information
        Boolean isCreatedEvent = minutes < 1;
        Boolean isAccSyncOnCreationEnabled = UTIL_WSC_Subscription.isAccSyncOnCreationEnabled(acc);
        Boolean isTractEnabled = UTIL_WSC_Subscription.isSubscribedToTRACT(acc);
        Boolean isEBayKAdsale = 'EBAYK'.equalsIgnoreCase(acc.MemberId__c) && UTIL_WSC_Subscription.isAccOnlyAdsales(acc.id);
        Account oldAcc = oldMap == null ? null : (Account)oldMap.get(acc.Id);
        
        Set<String> checkPaymentFields = new Set<String>{
            'Billing_Preference__c', 
            'Mandate_Status__c'
        };
        
        //AccountPush to local platform only if Sync On Creation is enabled or Local Id is not blank
        if (
            (
                (isCreatedEvent && isAccSyncOnCreationEnabled) || 
                (!isCreatedEvent && String.isBlank(acc.UniquePlatformId__c))
            ) && 
            !GW_Opportunity.userAsSelfService && 
            !isEBayKAdsale && 
            currentStep == 0) return currentStep;
        if (isAccSyncOnCreationEnabled && !GW_Opportunity.userAsSelfService && !isEBayKAdsale && currentStep == 0) return currentStep;
        
        if (isTractEnabled) {
            if ((isEBayKAdsale || !String.isBlank(acc.UniquePlatformId__c)) && String.isBlank(acc.Tract_AccountId__c) && currentStep == 1) return currentStep;
            if (!isCreatedEvent && String.isNotBlank(acc.Tract_AccountId__c) && acc.Tract_ResponsiblePartyId__c != null) {
                if (currentStep == 2) return currentStep;
                if (currentStep == 3) return currentStep;
                if (currentStep == 4) return currentStep;
            }
            if (contPush.Id != null && currentStep == 5) return currentStep;
            if (!isCreatedEvent && contPush.Id != null && currentStep == 6) return currentStep;
            if (oldAcc != null && GW_sObject.oneOrMoreFieldsChanged(acc, oldAcc, checkPaymentFields) && 
                (
                    (acc.Billing_Preference__c == 'Direct Debit' && acc.Mandate_Status__c == 'OK') || 
                    acc.Billing_Preference__c == 'Invoice'
                ) && 
                currentStep == 7 
            ) return currentStep;
        }
        return STEPS_ACCOUNT_PUSH.size();
    }
}