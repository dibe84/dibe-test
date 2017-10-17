public with sharing class PGC_MandateExtension {
    
    public echosign_dev1__SIGN_Agreement__c agreement {get;set;}

    public PGC_MandateExtension(ApexPages.StandardController stdController) {
        agreement = (echosign_dev1__SIGN_Agreement__c) stdController.getRecord();
        agreement = GW_Agreement.getrecord(agreement.Id);
        opportunity = GW_Opportunity.getrecord(agreement.echosign_dev1__Opportunity__c);
        memberUnit = GW_MemberUnit.getMemberUnitById(agreement.MemberUnit__c);
    }
    
    public MemberUnit__c memberUnit {
        get;
        private set;
    }
    
    public Opportunity opportunity {
        get;
        private set;
    }    
}