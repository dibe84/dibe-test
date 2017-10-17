public with sharing class GW_Contact {


    private static final Schema.sObjectType GW_BASEOBJECT = Contact.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Contact';
	public Static String ROLE_PORTAL_USER = 'Portal User';
    public Static String ROLE_FINANCE_CONTACT = 'Finance Contact';

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Contact           getRecord(Id id)           { return (Contact) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,Contact>   getMap(Set<id> ids)        { return new Map<id,Contact>( getList(ids) ); }
    public static List<Contact>     getList(Set<id> ids)       { return (List<Contact>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list related records
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Account parent
    public static List<Contact>   getListFromRelated(Id parentId)        { return (List<Contact>) GW_sObject.getChildren(parentId, 'Contacts'); }
    public static List<Contact>   getListFromRelated(Set<Id> parentIds)  { return (List<Contact>) GW_sObject.getChildren(parentIds, 'Contacts'); }
    public static Set<Id>         getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'Contacts'); }

    // Account child
    public static Map<id,Contact>  	getMapFromRelated(List<Account> lst)   { return getMap(getIdSetFromRelated(lst)); }
    public static Set<Id>          	getIdSetFromRelated(List<Account> lst) { return GW_sObject.getParentIds(lst, 'PortalUser__c'); }


    // get list of FinanceContacts and PortalUsers
    public static Map<id,Contact> getAllParentContacts(List<Account> accs) {
        Set<Id> allContactIds = new Set<Id>();
        Set<Id> portalUserContactIds = GW_sObject.getParentIds(accs, 'Portal_User__c');
        Set<Id> financeContactIds = GW_sObject.getParentIds(accs, 'Finance_contact__c');
        allContactIds.addAll(portalUserContactIds);
        allContactIds.addAll(financeContactIds);

        Map<id,Contact> allContactsMap = getMap(allContactIds);
        return allContactsMap;
    }

    public static Set<Id> getAllParentContactIds(List<Account> accs) {
        Set<Id> allContactIds = new Set<Id>();
        allContactIds.addAll(GW_sObject.getParentIds(accs, 'Portal_User__c'));
        allContactIds.addAll(GW_sObject.getParentIds(accs, 'Finance_contact__c'));
        return allContactIds;
    }
	
	public static Map<Id, List<Contact>> populateConMap(List<Account> accs) {
        Map<Id,Contact> conMap = GW_Contact.getAllParentContacts(accs);
        if(conMap == null || conMap.isEmpty()) return new Map<Id, List<Contact>>();
        UTIL.cache(conMap);
        Map<Id, List<Contact>> mapContacts = new Map<Id, List<Contact>>();
        for(Contact con : conMap.values()){
            if(!mapContacts.containsKey(con.AccountId))
                mapContacts.put(con.AccountId, new List<Contact>());
            mapContacts.get(con.AccountId).add(con);
        }
        return mapContacts;
    }

    // status calculator
    public static Boolean setStatus(Contact c) {

        StatusCalculator.IStatusCalculator statusCalc = new ContactStatusCalculator(c);
        Boolean statusChanged = statusCalc.setStatus(c);

        return statusChanged; // return TRUE if status changed
    }

    public class ContactStatusCalculator extends StatusCalculator.AbstractStatusCalculator {
        // constructor
        public ContactStatusCalculator(Contact c) {
            super(c, new Map<Integer, String> { 0 => 'Draft', 1 => 'Valid' });
        }

        public override Boolean passCriteria(sObject so, Integer stage) {
            Contact con = (Contact) so;
            if (stage == 0) { return true; } // Draft
            if (stage == 1) { return con.LowestStatusNumIncomplete__c > 1 && con.LowestStatusNumSyncError__c > 1; } // Valid
//            if (stage == 2) { return con.LowestStatusNumIncomplete__c > 2 && con.LowestStatusNumSyncError__c > 2; } // Ready to Bill
            return false;
        }
    }

    /**
     * @createdDate: 03 Mar 2017
     * @createdBy: suy sreymol
     * @desc:  	get mapping account & related finance/portal/primary contacts > Optimize code
     *		 	https://jira.corp.ebay.com/browse/CD-1924
     */
    public static Map<String, List<Contact>> getMappingRoleAndPrimaryContact(Set<Id> accIds){
     	//get contacts of account
     	Map<String, List<Contact>> mapAcc = new Map<String, List<Contact>>();
        for(Contact c : (List<Contact>)GW_sObject.queryRecords('Contact', 'AccountId IN: idSet1 AND ( Role__c includes (\'Portal User\',\'Finance Contact\') OR Primary__c = TRUE ) Order By CreatedDate ASC', new Map<String, Set<id>>{'idSet1' => accIds})){
            if (c.AccountId != null) {
                if(!mapAcc.containsKey(c.AccountId)) mapAcc.put(c.AccountId, new List<Contact>());
     			mapAcc.get(c.AccountId).add(c);
            }
     	}
     	
     	return mapAcc;
    }

    /**
     * @createdDate: 16-02-2017
     * @createdBy: HCS
     * @desc: add Member Unit ID to the contacts at the creation  not at the edition of case.
     */
     public static void initialMemberUnitId(List<Case> lstCases) {
         Map<Id,String> mapMeberUnitIds = new Map<Id,String>();
         List<RecordType> lstRecords = GW_sObject.queryRecords('RecordType',' SobjectType=\'Case\' And Name =\'ECGDKCS\'');
         Id recordTypeId = lstRecords.isEmpty() ? null : lstRecords.get(0).id;
         for(Case c:lstCases) {
            if( c.contactId != null &&
                String.isNotEmpty(c.MemberUnitId__c) &&
                recordTypeId == c.recordTypeId ) {
                mapMeberUnitIds.put(c.contactId,c.MemberUnitId__c);
            }
         }
         if( !mapMeberUnitIds.isEmpty()) {
            List<Contact> lstUpdateContacts = new List<Contact>();
            List<Contact> lcontact = GW_sObject.queryRecords('Contact', new List<String> {'id','MemberUnitId__c'}, mapMeberUnitIds.keySet() );
            for(Contact contact : lcontact){
                Id key = contact.id;
                if(mapMeberUnitIds.containskey(key) && String.isEmpty(contact.MemberUnitId__c)) {
                    contact.MemberUnitId__c = mapMeberUnitIds.get(key);
                    lstUpdateContacts.add(contact);
                }
            }
             if( !lstUpdateContacts.isEmpty()) {
                update  lstUpdateContacts;
             }
         }
     }

//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static final String DEFAULT_LASTNAME = 'Doe';

    //public static Contact createSObject() { return createSObject(DEFAULT_LASTNAME); }
    //public static Contact createSObject(String lastName) { return new Contact(LastName=lastName); }
    public static Contact createSObject(String lastName, Account acc) {
        return new Contact(LastName=lastName,
                           AccountId=acc.Id,
                           Email='testemail@test.org',
                           Salutation='Mr.',
						   Phone='+0624261744'
                          );
    }

    public static Contact insertSObject(String lastName, Account acc) {
        Contact con = createSObject(lastName, acc);
        insert con;
        return con;
    }

     public static void validatePhoneNumber(Contact contact, Set<String> phoneFields) {
         if(contact == null || phoneFields == null || contact.MemberUnitId__c == 'ECGDKCS') return;

         for(String phoneField : phoneFields) {
             String fieldVal = (String) (contact.get(phoneField));
             fieldVal = (fieldVal == null ? '' : fieldVal.trim());
             if(fieldVal.indexOf('+') == -1 || fieldVal.lastIndexOf('+') != 0) {
                 UTIL.throwError(phoneField + ' number should start with \'+\' sign, please update with correct value.');
             }
         }
     }
}