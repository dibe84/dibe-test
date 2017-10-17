///////////////////////////////////////////////////////////////////////////
// Class Lead Gateway  --
//
// Used as a central location to manage interactions with the Account Object
//
// Author:  Koen Faro
// Email:   kfaro@ebay.com
//
///////////////////////////////////////////////////////////////////////////
public with sharing class GW_Lead
{
    private static final Schema.sObjectType GW_BASEOBJECT = Lead.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Lead';
    private static final String DEFAULTFIELDSET = 'Default'; // default fieldset for this type

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Lead           getRecord(Id id)           { return (Lead) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<Id,Lead>   getMap(Set<id> ids)        { return new Map<Id,Lead>( getList(ids) ); }
    public static List<Lead>     getList(Set<id> ids)       { return (List<Lead>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }


//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Case
    public static List<Case>   getRelatedCases(Set<Id> parentIds)  { return (List<Case>) GW_sObject.getChildren(parentIds, 'Cases__r'); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public functional methods
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static void handleConvertedLeads(List<Lead> leads) {
        leadConversionAttachCases(leads);
        convertLeadToAccountCustomAttributes(leads);
        convertLeadToAccount(leads);
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// private lead conversion methods
//////////////////////////////////////////////////////////////////////////////////////////////////////

    private static void leadConversionAttachCases(List<Lead> leads) {
        Map<Lead,List<Case>> leadToCases = getLeadToCases(leads);
        List<Case> casesToUpdate = new List<Case>();
        for (Lead l : leadToCases.keySet()) {
            List<Case> cases = leadToCases.get(l);
            for (Case c : cases) {
                c.ContactId = l.convertedContactId;
                c.AccountId = l.convertedAccountId;
                casesToUpdate.add(c);
            }
        }
        update casesToUpdate;
    }

    public static void convertLeadToAccountCustomAttributes(List<Lead> leads){
        Map<Id,Id> caMapping = new Map<Id,Id>();

        for(Lead l: leads){
            caMapping.put(l.Id, l.ConvertedAccountId);
        }

        GW_CustomAttribute.convertCustomAttributes(caMapping);
    }
    
    /**
     * @createdDate: 17-11-2016
     * @createdBy: Sochanra
     * @param: list of lead
     * @desc: to update account's field (Type) When convert lead to account
     */
    public static void convertLeadToAccount(List<Lead> leads){
    	Map<Id, Lead> mapLead = new Map<Id, Lead>();
    	for(lead l : leads){
    		mapLead.put(l.ConvertedAccountId, l);
    	}
    	GW_Account.convertLeadToAccount(mapLead);
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// helper methods
//////////////////////////////////////////////////////////////////////////////////////////////////////

    private static Map<Lead,List<Case>> getLeadToCases(List<Lead> leads) {
        Map<Id,Lead> idToLead = new Map<Id,Lead>();
        for (Lead l : leads) {
            idToLead.put(l.id, l);
        }

        Map<Lead,List<Case>> leadToCases = new Map<Lead,List<Case>>();
        Set<Id> leadIds = idToLead.keySet();
        List<Case> allRelatedCases = getRelatedCases(leadIds);
        for (Case c : allRelatedCases) {
            Lead l = idTolead.get(c.Lead__c);
            List<Case> caseList = leadToCases.get(l);
            if (caseList == null) {
                caseList = new List<Case>();
            }
            caseList.add(c);
            leadToCases.put(l, caseList);
        }
        return leadToCases;
    }

    // status calculator
    public static Boolean setStatus(Lead l) {
        StatusCalculator.IStatusCalculator statusCalc = new LeadStatusCalculator(l);
        Boolean statusChanged = statusCalc.setStatus(l);

        return statusChanged; // return TRUE if status changed
    }

    public class LeadStatusCalculator extends StatusCalculator.AbstractStatusCalculator {

        // constructor
        public LeadStatusCalculator(Lead l) {
            super(l, new Map<Integer, String> { 0 => 'Draft', 1 => 'Lead Qualified' });
        }

        public override Boolean passCriteria(sObject so, Integer stage) {
            Lead l = (Lead) so;
            if (stage == 0) { return true; } // Draft
            if (stage == 1) { return l.LowestStatusNumIncomplete__c > 1; } // Lead Qualified
            return false;
        }
    }
    
    public static void setDisqualifyReason(Lead l){
    	if (!'Disqualified'.equals(l.status)) {
    		l.DisqualifyReason__c = null;
    	}
    }
}