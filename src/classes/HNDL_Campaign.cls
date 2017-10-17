public with sharing class HNDL_Campaign extends TriggerManager.TriggerHandler {

    public static final String MEMBER_ERR_MSG = 'There is something wrong with your Member ID assignment. Please check your Role and Member recrods';
    public static final String MEMBERUNIT_ERR_MSG = 'There is something wrong with your MemberUnit ID assignment. Please check your Role and MemberUnit recrods';

    public HNDL_Campaign() {super('HNDL_Campaign', Campaign.sObjectType);}

    public override void bulkBefore(List<sObject> lst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        for(sObject so : lst) {
            Campaign camp = (Campaign) so;
            assignMemberAndMU(camp);
        }
    }

    private void assignMemberAndMU(Campaign camp) {
        if (camp.Member__c == null) {
            if (GW_Member.getMember(camp.OwnerId) != null) {
                camp.Member__c = (GW_Member.getMember(camp.OwnerId)).Id;
            } else {
                camp.addError(MEMBER_ERR_MSG);
            }
        }
        if (camp.MemberUnit__c == null) {
            if (getMemberUnit(camp.OwnerId) != null) {
                camp.MemberUnit__c = getMemberUnit(camp.OwnerId).Id;
            } else {
                camp.addError(MEMBERUNIT_ERR_MSG);
            }
        }
    }

    private MemberUnit__c getMemberUnit(Id userId) {
        MemberUnit__c mUnit = (MemberUnit__c) GW_MemberUnit.getMemberUnit(userId);
        return mUnit;
    }

    private Member__c getMember(Id userId) {
        Member__c member = (Member__c) GW_Member.getMember(userId);
        return member;
    }
}