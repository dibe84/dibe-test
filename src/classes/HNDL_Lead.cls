public class HNDL_Lead extends TriggerManager.TriggerHandler {

    private List<Lead> convertedleads = new List<Lead>();

    public override void beforeInsert(SObject so) {
        Lead l = (Lead) so;

        checkLeadMemberUnit(l);
        checkDisqualificationCorrect(l);
        UTIL_FieldValidator.checkObject(l); //leave second last
        GW_Lead.setStatus(l); // leave as last
        GW_Lead.setDisqualifyReason(l);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Lead l = (Lead)so;
        Lead oldL = (Lead)oldSo;

        if (l.OwnerId != oldL.OwnerId || l.MemberUnit__c == null) checkLeadMemberUnit(l);

        checkDisqualificationCorrect(l);
        UTIL_FieldValidator.checkObject(l); //leave second last
        GW_Lead.setStatus(l); // leave as last
        GW_Lead.setDisqualifyReason(l);
    }


    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        if (!Trigger.isInsert && !Trigger.isDelete) {
            validateCustomAttributes(oldMap, newMap);
        }
    }

    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        if (!Trigger.isDelete && UTIL.isRunningTestSetup == false) {
            checkCustomAttributeDefinitions(newMap);
        }
    }

    public override void afterUpdate(SObject oldSo, SObject so) {
        Lead l = (Lead) so;
        Lead oldL = (Lead) oldSo;
        if (l.IsConverted == true && oldL.IsConverted == false) {
            convertedLeads.add(l);
        }
    }

    public override void andFinally() {
        if (convertedLeads.size() > 0) {
            GW_Lead.handleConvertedLeads(convertedLeads);
        }
    }

    //////////////////////////////
    // private helper methods
    //////////////////////////////
    private void checkLeadMemberUnit(Lead l) {
            if(GW_Account.isGuestUser || l.OwnerId == null || l.OwnerId.getSobjectType() == Group.SObjectType) return;
            Member__c m = GW_Member.getMember(l.OwnerId);
            MemberUnit__c mu = GW_MemberUnit.getMemberUnit(l.ownerId);


            UTIL.log('~!@ check lead owner:' + l.OwnerId);
            UTIL.log('~!@ check lead member:' + m);
            UTIL.log('~!@ check lead member unit:' + mu);

            if (m != null) {
        	    l.Member__c = m.Id;
		        //If owner defines the member unit pick that one, otherwise take the default member unit from the member.
                if (mu != null) {
                    l.MemberUnit__c = mu.Id;
                } else {
                    l.MemberUnit__c = m.DefaultMemberUnit__c;
                }
            }

    }
    
    private void checkDisqualificationCorrect(Lead l) {
        if ( 'Disqualified'.equals(l.status)  && l.DisqualifyReason__c == null) {
            l.DisqualifyReason__c.addError('Please specify a reason for Disqualification.');
            return;
        }
    }
    
    
    
    private void checkCustomAttributeDefinitions(Map<Id, sObject> newMap) {
        try {
            if (newMap!=null) {
                GW_CustomAttribute.ensureCustomAttributeDefinitions(newMap.keySet(), 'Lead');
            }
        } catch (Exception e) {
            UTIL.throwError('Error in checkCustomAttributeDefinitions: ', e);
        }
    }

    private void validateCustomAttributes(Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        Map<Id,Map<String,String>> validationResults = GW_CustomAttribute.validateCustomAttributes(oldMap,newMap);
        for(Id accId : validationResults.keySet()) {
            Lead a = (Lead) newMap.get(accId);
            a.MandatoryDetailsError__c = validationResults.get(accId).get('MandatoryDetailsError__c');
            a.MandatoryDetailsFilled__c = Boolean.valueOf(validationResults.get(accId).get('MandatoryDetailsFilled__c'));
        }
    }

    // Constructor
    public HNDL_Lead() { super('HNDL_Lead', Account.sObjectType); }
}