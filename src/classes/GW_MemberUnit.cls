public with sharing class GW_MemberUnit {

    private static final String GW_BASEOBJECTNAME = 'MemberUnit__c';

    public static MemberUnit__c getRecord(Id id) { return (MemberUnit__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }

    // caching
    public static Map<Id, MemberUnit__c> memberUnitCache {
        get {
            if (memberUnitCache == null) {
                memberUnitCache = new Map<Id, MemberUnit__c>();
                List<MemberUnit__c> memberUnits = GW_sObject.queryRecords('MemberUnit__c', '', 
                                                                                new List<String>{
                                                                                'Member__r.OwnerId',
                                                                                'Member__r.Account__r.BillingStreet',
                                                                                'Member__r.Account__r.BillingCity',
                                                                                'Member__r.Account__r.BillingState',
                                                                                'Member__r.Account__r.BillingPostalCode',
                                                                                'Member__r.Account__r.BillingCountry',
                                                                                'Member__r.Account__r.BillingStateCode',
                                                                                'Member__r.Account__r.BillingCountryCode',
                                                                                'Member__r.Account__r.ShippingStreet',
                                                                                'Member__r.Account__r.ShippingCity',
                                                                                'Member__r.Account__r.ShippingState',
                                                                                'Member__r.Account__r.ShippingPostalCode',
                                                                                'Member__r.Account__r.ShippingCountry',
                                                                                'Member__r.Account__r.ShippingStateCode',
                                                                                'Member__r.Account__r.ShippingCountryCode'}
                                                                                );
                for (MemberUnit__c m : memberUnits) {
                    memberUnitCache.put(m.Id, m);
                }
            }
            return memberUnitCache;
        }
        private set;
    }


    // cached memberUnits map
    private static Map<String, MemberUnit__c> memberUnitNameMap { // member Unique ID => Member__c
        get {
            if (memberUnitNameMap == null) {
                memberUnitNameMap = new Map<String, MemberUnit__c>();
                List<MemberUnit__c> memberUnits = GW_sObject.queryRecords('MemberUnit__c', '', 
                                                                                new List<String>{
                                                                                'Member__r.OwnerId',
                                                                                'Member__r.Account__r.BillingStreet',
                                                                                'Member__r.Account__r.BillingCity',
                                                                                'Member__r.Account__r.BillingState',
                                                                                'Member__r.Account__r.BillingPostalCode',
                                                                                'Member__r.Account__r.BillingCountry',
                                                                                'Member__r.Account__r.BillingStateCode',
                                                                                'Member__r.Account__r.BillingCountryCode',
                                                                                'Member__r.Account__r.ShippingStreet',
                                                                                'Member__r.Account__r.ShippingCity',
                                                                                'Member__r.Account__r.ShippingState',
                                                                                'Member__r.Account__r.ShippingPostalCode',
                                                                                'Member__r.Account__r.ShippingCountry',
                                                                                'Member__r.Account__r.ShippingStateCode',
                                                                                'Member__r.Account__r.ShippingCountryCode'}
                                                                                );
                for (MemberUnit__c m : memberUnits) {
                    memberUnitNameMap.put(m.MemberUnitId__c, m);
                }
            }
            return memberUnitNameMap;
        }
        private set;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // related methods use to retrieve a list of parents(base object) from a list of child objects
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    // Member parent
    public static List<MemberUnit__c>   getListFromRelated(Id parentId)        { return (List<MemberUnit__c>) GW_sObject.getChildren(parentId, 'MemberUnits__r'); }
    public static List<MemberUnit__c>   getListFromRelated(Set<Id> parentIds)  { return (List<MemberUnit__c>) GW_sObject.getChildren(parentIds, 'MemberUnits__r'); }
    public static Set<Id>                getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'MemberUnit__c'); }

    // Linked member for current user
    private static MemberUnit__c curUserMemberUnit {
        get {
            if (curUserMemberUnit == null) {
                UserRole ur = GW_User.getUserRole(UserInfo.getUserId());
                if (ur == null) return null;
                curUserMemberUnit = memberUnitNameMap.get(getMemberUnitName(ur.DeveloperName));
            }
            return curUserMemberUnit;
        }
        private set;
    }

    // get member for specific userid
    public static MemberUnit__c getMemberUnit(Id userId) {
        UserRole ur = GW_User.getUserRole(userId);
        if (ur == null) throw new UTIL.CustomException('No Role specified for User. Role required to retrieve Member.');
        return memberUnitNameMap.get(getMemberUnitName(ur.DeveloperName));
    }
    
    public static MemberUnit__c getMemberUnit2(Id userId, Account parent) {
        //Check if MU eixsts matching User Role
        MemberUnit__c mU = GW_MemberUnit.getMemberUnit(userId);
        system.debug('MU does not exist matching user role name!!!');
        if(mU == null){
            //When the role of the user does not specify which memberUnit to use
            //Get the default on the member of the parent account
            Member__c member = GW_Member.memberCache.get( parent.Member__c );
            if (member != null) {
               mU = GW_MemberUnit.getMemberUnitById( member.DefaultMemberUnit__c );
            }
        }
        UTIL.cache(mU);
        return mU;
    }

    //Get memberUnit for specific id
    public static MemberUnit__c getMemberUnitById(Id muId){
      MemberUnit__c mu = memberUnitCache.get(muId);
      if( mu == null ){
        mu = getRecord(muId); 
      } 
        return mu;
    }

    // get member for current running user
    public static MemberUnit__c getUserMemberUnit() {
        if (curUserMemberUnit == null) Util.log('No member for user.');
        return curUserMemberUnit;
    }

    // validate if record owner and current user belong to same memberUnit
    public static Boolean validMemberUnit(Id recordOwnerId) {
        return (GW_MemberUnit.getUserMemberUnit().Id == GW_MemberUnit.getMemberUnit(recordOwnerId).Id);
    }

    private static String getMemberUnitName(String roleDeveloperName){
        String memberUnitName = '';

        if (!String.isEmpty(roleDeveloperName)){
            memberUnitName = roleDeveloperName.left(7);
        }
        return memberUnitName;
    }

    public static List<MemberUnit__c> getMemberUnitList(String memberUnitId){
        List<MemberUnit__c> memberUnitList = new List<MemberUnit__c>();
        if (!String.isEmpty(memberUnitId) && memberUnitNameMap.containsKey(memberUnitId)){
            memberUnitList.add(memberUnitNameMap.get(memberUnitId));
        }
        return memberUnitList;
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static MemberUnit__c createObject(Id memberId, String name, String lineOfBusiness){
        return new MemberUnit__c(Member__c=memberId, Name=name, LineOfBusiness__c =lineOfBusiness);
    }

    public static MemberUnit__c insertObject(Id memberId, String name, String lineOfBusiness){
        MemberUnit__c m = createObject(memberId, name, lineOfBusiness);

        insert m;
        return m;
    }
}