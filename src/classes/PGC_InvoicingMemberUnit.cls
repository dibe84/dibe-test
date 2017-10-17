public with sharing class PGC_InvoicingMemberUnit {

    public Static String selMemberUnitId; 

    public String memberUnitId { get; set; }
    
    private Boolean allowMUSelect;
    
    private List<MemberUnit__c> memberUnits = new List<MemberUnit__c>();
    
    
    public PGC_InvoicingMemberUnit() {
        allowMUSelect = false;
        prepareMembers();
    }

    public void prepareMembers(){
        // If the User is an Admin, allow the Member to be selected
        if( UserInfo.getProfileId().contains(GW_User.ADMINPROFILEID) ){
        	allowMUSelect = true;
            Map<Id, MemberUnit__c> memberUnitsMap = GW_MemberUnit.memberUnitCache;
            memberUnits = new List<MemberUnit__c>( memberUnitsMap.values() );
            memberUnitId = memberUnits[0].Id;
        } else {
        	memberUnitId = (GW_MemberUnit.getUserMemberUnit()).Id;
        }
    }

    public List<SelectOption> getMemberUnitItems() {
        List<SelectOption> options = new List<SelectOption>();
        for (MemberUnit__c me : memberUnits){
            options.add(new SelectOption(me.Id, me.Name));
        }
        return options;
    }
    
    public Boolean getAllowMUSelect(){
    	return allowMUSelect;
    }
    
    public void refreshInvoicingComps(){
        selMemberUnitId = memberUnitId;
    }
}