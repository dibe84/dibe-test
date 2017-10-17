public class HNDL_Case extends TriggerManager.TriggerHandler {
    
    public override void beforeInsert(SObject so){
    	Case ca = (Case)so;
		

        checkPhoneNumbers(ca,null);

        if(ca.MemberUnitId__c == NULL){ ca.MemberUnitId__c = getCaseMemberUnitId(ca); }
        if(ca.MemberId__c == NULL){ ca.MemberId__c = getCaseMemberId(ca); }
        
        checkForResponseErrorCase( ca );        
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so){
    	Case ca = (Case)so;
        Case oldCa = (Case)oldSo;

        checkPhoneNumbers(ca,oldCa);


        if(ca.MemberUnitId__c == NULL){ ca.MemberUnitId__c = getCaseMemberUnitId(ca); }
        if(ca.MemberId__c == NULL){ ca.MemberId__c = getCaseMemberId(ca); }
        
        checkForResponseErrorCase( ca );   
	}
	
	public override void bulkBefore(List<SObject> soLst, Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        if (hndlEvent == TriggerManager.triggerEventType.BeforeInsert) {
        	GW_Case.initialNewCases((List<Case>) soLst);
        	GW_Contact.initialMemberUnitId(soLst);
        }

        if (hndlEvent == TriggerManager.triggerEventType.BeforeUpdate) {
            GW_Case.initialNewCases((List<Case>) soLst);
            GW_Contact.initialMemberUnitId(soLst);
           
        }
    }
    
    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        
        if (hndlEvent == TriggerManager.triggerEventType.AfterUpdate) {
           GW_Case.linkSelfToLiveChatTranscript((List<Case>) soLst);
        }
        
    }

    ///public override void beforeDelete(SObject so){}

    ///public override void afterInsert(SObject so){}
    
    ///public override void afterUpdate(SObject oldSo, SObject so){}
    
    ///public override void andFinally() {} 

//////////////////////////////
// private helper methods
//////////////////////////////    
    private string getCaseMemberUnitId(case ca){
        

        if (ca.RecordTypeId == null) return '';

        if(string.valueOf(ca.OwnerId.getsobjecttype()) == 'User'){
            MemberUnit__c currentMemberUnit;
            try {
                currentMemberUnit = GW_MemberUnit.getMemberUnit(ca.ownerId);
            } catch (Exception e) {
                return '-';
            }
            
            if(currentMemberUnit == null){
            	return '-';
        	}
            
            if(currentMemberUnit.MemberUnitId__c != null || currentMemberUnit.MemberUnitId__c != ''){
            	return currentMemberUnit.MemberUnitId__c;
        	}
        }
        
        return getMemberUnitByOrigin(ca); 
    }
    
    private string getCaseMemberId(case ca){
        

        if (ca.RecordTypeId == null) return '';

        if(string.valueOf(ca.OwnerId.getsobjecttype()) == 'User'){
            Member__c currentMember = GW_Member.getMember(ca.ownerId);  
        	
            if(currentMember == null){
            	return getMemberByOrigin(ca);
        	}
            
            if(currentMember.MemberId__c != null || currentMember.MemberId__c != ''){
            	return currentMember.MemberId__c;
        	}
        }
        
        return getMemberByOrigin(ca); 
    }
    
    private string getMemberByOrigin(case ca){
        string OriginMember =  ca.Origin != null && ca.Origin.length() > 5 ?  ca.Origin.SubString(0, 5): ca.Origin;
        return OriginMember;
    }
    
    private string getMemberUnitByOrigin(case ca){
		string OriginMemberUnit = ca.Origin != null && ca.Origin.length() > 7 ? ca.Origin.SubString(0, 7): ca.Origin;
        return OriginMemberUnit;
    }
    
    private void checkPhoneNumbers(Case cas, Case oldCase) {
         Set<String> phoneFields = new Set<String>{'SuppliedPhone'};
         Set<String> fieldsToValidate = new Set<String>();
         // Insert
         if(oldCase == null) {
             for(String phoneField : phoneFields) {
                 if(cas.get(phoneField) != null) fieldsToValidate.add(phoneField);
             }
         } // Update
         else {
             for(String phoneField : phoneFields) {
                 if(oldCase.get(phoneField) != cas.get(phoneField)) fieldsToValidate.add(phoneField);
             }
         }
         try {
             GW_Case.validatePhoneNumber(cas,fieldsToValidate);
         } catch(Exception ex) {
             cas.addError(ex.getMessage());
         }
     }

    private void checkForResponseErrorCase( Case ca ){
    	
    	if( ca.Subject == 'Returned mail: response error' ){
    		ca.Reason = 'Spam';
    	    ca.Status = 'Closed';
    	}
    }

    // Constructor
    public HNDL_Case() { super('HNDL_Case', Case.sObjectType); }

}