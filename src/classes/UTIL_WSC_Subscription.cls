public class UTIL_WSC_Subscription {

    public static List<WSC_Subscription__c> subscriptions;
    public Static Map<Id, MemberUnit__c> memberUnitCache = GW_MemberUnit.memberUnitCache;
    static {
        subscriptions = WSC_Subscription__c.getAll().values();

        if (Test.isRunningTest()) {
            subscriptions.add(new WSC_Subscription__c(Name = 'TTCLG.WSC_Fiqas.SyncAccount', IsActive__c = true));
        }
    }

    public static Boolean isSubscribedToWS(string consumer, string apiName, string methodName) {
        String checkSubscription = consumer + '.' + apiName + '.' + methodName;

        for (WSC_Subscription__c subscription : subscriptions) {
            if (subscription.IsActive__c && subscription.Name == checkSubscription) {
                return true;
            }
        }
        return false;
    }

    public static Boolean isSubscribedToTRACT(SObject so) {
        // Initial checks
        if(so == null) return FALSE;
        if(!UTIL_WSC_Subscription.isTractSubscriptionActive()) return FALSE;

        // Account
        if(so.getSObjectType() == Schema.Account.sObjectType) {
            return isAccountSubscribedToTract((Account) so);
        } // Opportunity
        else if(so.getSObjectType() == Schema.Opportunity.sObjectType) {
            return isOpportunitySubscribedToTract((Opportunity) so);
        }
        else
            return FALSE;
    }

    private static Boolean isOpportunitySubscribedToTract(Opportunity opp) {
        // Check if account is subscribed to Tract
        return isAccountSubscribedToTract(GW_Account.getRecord(opp.AccountId));
    }

    private static Boolean isAccountSubscribedToTract(Account acc) {
        if(acc == null) return FALSE;

        if(!UTIL_WSC_Subscription.isTractSubscriptionActive()) return FALSE;
        
        List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAMUAsFromCache(acc.Id);
        
        for(AccountMemberUnitAssociation__c amua : amuaList) {
            if(memberUnitCache.containsKey(amua.MemberUnit__c))
                return memberUnitCache.get(amua.MemberUnit__c).EnableTRACT__c;
        }
        return FALSE;
    }

    public static Boolean isAccSyncOnCreationEnabled(Account acc) {
        if(acc == null) return FALSE;
        
        List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAMUAsFromCache(acc.Id);
        
        for(AccountMemberUnitAssociation__c amua : amuaList) {
            if(memberUnitCache.containsKey(amua.MemberUnit__c))
                return memberUnitCache.get(amua.MemberUnit__c).SyncAccountOnCreationLocalPlatform__c;
        }
        return FALSE;
    }

    private static Boolean isTractSubscriptionActive() {
        for (WSC_Subscription__c subscription : subscriptions) {
            if (subscription.IsActive__c && subscription.Name == 'TRACT') {
                return TRUE;
            }
        }
        return FALSE;
    }
	
	public static Boolean isAccOnlyAdsales(Id accid) {
    	List<AccountMemberUnitAssociation__c> amuas = GW_AccountMemberUnitAssociation.getAMUAsFromCache(accid);
    	if( amuas.isEmpty() ) {
    		GW_AccountMemberUnitAssociation.cacheAMUAForAccounts(new List<Account> {new Account(Id=accid)});
    		amuas = GW_AccountMemberUnitAssociation.getAMUAsFromCache(accid);
    	}
    	
    	Set<String> sLOB = new Set<String>();
    	for(AccountMemberUnitAssociation__c amua : amuas){
    		String lob = memberUnitCache.containsKey(amua.MemberUnit__c) ? memberUnitCache.get(amua.MemberUnit__c).LineOfBusiness__c : amua.MemberUnit__r.LineOfBusiness__c;
    		sLOB.add(lob);
    	}
    	if(sLOB.contains('AD')) return true;
    	
    	return false;
    }

}