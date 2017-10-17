public without sharing class GW_AccountMemberUnitAssociation {

    public static Map<Id, AccountMemberUnitAssociation__c> amuaCache {
        get {
            if (amuaCache == null) {
                amuaCache = new Map<Id, AccountMemberUnitAssociation__c>();
            }
            return amuaCache;
        }
        private set;
    }
    
    public static Map<Id,List<AccountMemberUnitAssociation__c>> acc_amuaCache {
        get {
            if (acc_amuaCache == null) {
                acc_amuaCache = new Map<Id, List<AccountMemberUnitAssociation__c>>();
            }
            return acc_amuaCache;
        }
        private set;
    }

    // It's not going to make DML
    public static List<AccountMemberUnitAssociation__c> getAMUAsFromCache(Id accId) {
        if ((!acc_amuaCache.containsKey(accId) || acc_amuaCache.get(accId).isEmpty()) && !Test.isRunningTest()) {
            cacheAMUAForAccounts(new List<Account> {new Account(Id = accId)});
        }
        List<AccountMemberUnitAssociation__c> amuaList = new List<AccountMemberUnitAssociation__c>();
        for(AccountMemberUnitAssociation__c am : amuaCache.values()) {
            if(am.Account__c == accId) {
                amuaList.add(am);
            }
        }

        return amuaList;
    }

    public static void cacheAMUAForAccounts(List<Account> accountList) {
        if(accountList == null) return;
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : accountList) {
            accountIds.add(acc.Id);
        }
        amuaCache.putall(getList(accountIds));
    }
    
    public static Map<Id,AccountMemberUnitAssociation__c> getList(Set<Id> accountIds) {
        Map<Id,List<AccountMemberUnitAssociation__c>> accToAmuaMap = GW_AccountMemberUnitAssociation.getAll(accountIds);
        Map<Id,AccountMemberUnitAssociation__c> amuaMap = new Map<Id, AccountMemberUnitAssociation__c>();
        for(List<AccountMemberUnitAssociation__c> amuaList : accToAmuaMap.values()) {
            amuaMap.putAll(amuaList);
        }
        return amuaMap;
    }

    public static Map<Id,List<AccountMemberUnitAssociation__c>> getAll(Set<Id> accountIds) {
        Set<Id> accIds = new Set<Id>();
        for (Id accountId : accountIds) {
            if (acc_amuaCache.containsKey(accountId) && !acc_amuaCache.get(accountId).isEmpty()) continue;
            accIds.add(accountId);
            acc_amuaCache.put(accountId, new List<AccountMemberUnitAssociation__c>());
        }
        
        final List<String> MORE_DETAILED_FIELDS = new List<String>{
            'MemberUnit__r.BillCycleText__c', 
            'MemberUnit__r.BillingCategoryText__c',
            'MemberUnit__r.CurrencyText__c',
            'MemberUnit__r.PaymentTermText__c',
            'MemberUnit__r.MemberUnitId__c',
            'MemberUnit__r.EnableTRACT__c',
            'MemberUnit__r.Pre_Paid_Billing_Cycle__c',
            'MemberUnit__r.LineOfBusiness__c'
        };
        List<String> queryFields = GW_sObject.getAllSObjectFieldNames('AccountMemberUnitAssociation__c');
        queryFields.addAll(MORE_DETAILED_FIELDS);
        if (accIds.isEmpty()) return acc_amuaCache;
        List<AccountMemberUnitAssociation__c> amuaList = (List<AccountMemberUnitAssociation__c>)GW_sObject.queryRecords('AccountMemberUnitAssociation__c', queryFields, 'Account__c', accIds);
        for (AccountMemberUnitAssociation__c amua : amuaList) {
            acc_amuaCache.get(amua.Account__c).add(amua);
        }
        return acc_amuaCache;
    }

    public static List<AccountMemberUnitAssociation__c> getAll(Id accountId) {
        return GW_AccountMemberUnitAssociation.getAll(new Set<Id>{accountId}).get(accountId);
    }

    public static void ensureAccountMemberUnitAssociations(Set<Id> accountIds) {
        // In the future this should take all opportunities for these accounts, find all unique memberUnits and make sure these associations exist... for now we have simplified logic that will only ensure the 'Default Member Unit' on the member of account to be created
        Map<Id, Account> accountMap = new Map<Id, Account>();
        for (sObject so : UTIL.getCachedMap(accountIds).values()) {
            accountMap.put(so.Id, (Account) so);
        }
        Map<Id, Member__c> memberMap = GW_Member.memberCache;
        Map<Id, AccountMemberUnitAssociation__c> accountMemberUnitAssociationMap = getList(accountMap.keySet());
        Map<Id,Set<Id>> existingAccountToMemberUnitAssociations = new Map<Id,Set<Id>>();

        // Build map of existing associations
        for (AccountMemberUnitAssociation__c amua : accountMemberUnitAssociationMap.values()) {
            if (!existingAccountToMemberUnitAssociations.containsKey(amua.Account__c)) {
                existingAccountToMemberUnitAssociations.put(amua.Account__c, new Set<Id>());
            }
            existingAccountToMemberUnitAssociations.get(amua.Account__c).add(amua.MemberUnit__c);
        }

        List<AccountMemberUnitAssociation__c> amuaToInsert = new List<AccountMemberUnitAssociation__c>();
        // Check if we need to add any...
        for (Account a : accountMap.values()) {
            //There is an auto assigned MemberUnit from registration process if SelfService
            if (a.SelfService__c && GW_Opportunity.userAsSelfService) continue;
            if (a.Member__c != null && memberMap.containsKey(a.Member__c) ) {
                //Check if MU eixsts matching User Role
                MemberUnit__c mU = (MemberUnit__c) GW_MemberUnit.getMemberUnit2(a.SelfService__c ? UserInfo.getUserId() : a.OwnerId, a);
                Id defaultMemberUnitId = mU.Id;
                if (defaultMemberUnitId != null) {
                    Set<Id> existingMemberUnitAssociations = existingAccountToMemberUnitAssociations.get(a.Id);
                    if (existingMemberUnitAssociations == null || existingMemberUnitAssociations.contains(defaultMemberUnitId) == false) {
                        amuaToInsert.add(new AccountMemberUnitAssociation__c(
                            Account__c = a.Id,
                            MemberUnit__c = defaultMemberUnitId
                        ));
                    }
                }
            }
        }
        amuaCache.putall(amuaToInsert);
        insert amuaToInsert;
    }

    public static void ensureAccountMemberUnitAssociations(Id accountId) {
        GW_AccountMemberUnitAssociation.ensureAccountMemberUnitAssociations(new Set<Id>{accountId});
    }
}