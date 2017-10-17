public with sharing class GW_Member {
    //  Owning user determines the ECG Member a record belongs too 
    // see architecture documentation for more info.

    // caching
    public static Map<Id, Member__c> memberCache {
        get {
            if (memberCache == null) {
                memberCache = new Map<Id, Member__c>();
                List<Member__c> members = GW_sObject.queryRecords('Member__c', '', 
																				new List<String>{
																				'Account__r.BillingStreet',
																				'Account__r.BillingCity',
																				'Account__r.BillingState',
																				'Account__r.BillingPostalCode',
																				'Account__r.BillingCountry',
																				'Account__r.BillingStateCode',
																				'Account__r.BillingCountryCode',
																				'Account__r.ShippingStreet',
																				'Account__r.ShippingCity',
																				'Account__r.ShippingState',
																				'Account__r.ShippingPostalCode',
																				'Account__r.ShippingCountry',
																				'Account__r.ShippingStateCode',
																				'Account__r.ShippingCountryCode',
																				'DefaultMemberUnit__r.EnableTRACT__c'}
																				);
                for (Member__c m : members) {
                    memberCache.put(m.Id, m);
                }
            }
            return memberCache;
        }
        private set;
    }

	// cached members map
	public static Map<String, Member__c> memberNameMap { // member Unique ID => Member__c
        get { 
        	if (memberNameMap == null) {
        		memberNameMap = new Map<String, Member__c>();
        		List<Member__c> members = GW_sObject.queryRecords('Member__c', '', 
																				new List<String>{
																				'Account__r.BillingStreet',
																				'Account__r.BillingCity',
																				'Account__r.BillingState',
																				'Account__r.BillingPostalCode',
																				'Account__r.BillingCountry',
																				'Account__r.BillingStateCode',
																				'Account__r.BillingCountryCode',
																				'Account__r.ShippingStreet',
																				'Account__r.ShippingCity',
																				'Account__r.ShippingState',
																				'Account__r.ShippingPostalCode',
																				'Account__r.ShippingCountry',
																				'Account__r.ShippingStateCode',
																				'Account__r.ShippingCountryCode',
																				'DefaultMemberUnit__r.EnableTRACT__c'}
																				);
                for (Member__c m : members) {
                    memberNameMap.put(m.MemberId__c, m);
                }
            }
            return memberNameMap;
        }
        private set;
    }

    // Linked member for current user
    public static Member__c curUserMember {
        get {
            if (curUserMember == null) {  
                UserRole ur = GW_User.getUserRole(UserInfo.getUserId());
                if (ur == null) return null;
                curUserMember = memberNameMap.get(getMemberName(ur.DeveloperName));
            }
            return curUserMember;
        }
        private set;
    }

    // get member for specific userid
    public static Member__c getMember(Id userId) {
        UserRole ur = GW_User.getUserRole(userId);
        if (ur == null) throw new UTIL.CustomException('No Role specified for User. Role required to retrieve Member.');
        
        if(memberNameMap.size() == 0){
        	return null;
        }
        else{  //@vitou 23-Apr-2015 ==> move into IF/ELSE condition
        	return memberNameMap.get(getMemberName(ur.DeveloperName));
        }
   }
       

    // get member for current running user
    public static Member__c getUserMember() {
        if (curUserMember == null) Util.log('No member for user.');
        return curUserMember;
    }

    // validate if record owner and current user belong to same member
    public static Boolean validMember(Id recordOwnerId) {
        return (GW_Member.getUserMember().Id == GW_Member.getMember(recordOwnerId).Id);
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Helper methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    
    private static String getMemberName(String roleDeveloperName){
        String memberName = '';

        if (!String.isEmpty(roleDeveloperName)){
            memberName = roleDeveloperName.left(5);
        }
        return memberName;
    }


//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////
    
    public static Member__c createSObject(String name, String memberId, Account acc) {
        Member__c m = new Member__c(Name=name, MemberId__c=memberId, Account__c=acc.Id, FQ_CmrType__c='Email template Banners');
        return m;
    }

    public static Member__c insertSObject(String name, String memberId, Account acc) {
        Member__c member = createSObject(name, memberId, acc);
        insert member;
        GW_Member.memberCache = null; // reset Cache since it is now out-of-date
        return member;
    }
}