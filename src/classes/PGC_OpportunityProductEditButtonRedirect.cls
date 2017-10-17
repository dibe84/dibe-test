public with sharing class PGC_OpportunityProductEditButtonRedirect {
        
	public PageReference redirect() {
		Id oppLineId = ApexPages.currentPage().getParameters().get('Id');
        String noOverride = ApexPages.currentPage().getParameters().get('Id');
        OpportunityLineItem oli = [SELECT Id, Opportunity.Id, Opportunity.AccountId, Opportunity.OwnerId, Opportunity.MemberUnit__r.EnableTRACT__c, BillingCalc__c FROM OpportunityLineItem WHERE Id =: oppLineId];
        String bCalc = oli.BillingCalc__c;
        Id oppId = oli.Opportunity.Id;
        Id accId = oli.Opportunity.AccountId;
        PageReference editPage;
        if(bCalc == 'Delivery' || bCalc == 'DailyFixed') {
            Opportunity opp = oli.Opportunity;
            PGC_OpportunityNewEditButtonRedirector newEditCon = new PGC_OpportunityNewEditButtonRedirector(new ApexPages.StandardController(opp));
            newEditCon.opp = opp;
            if (newEditCon.isTractEnbale()) {
                editPage = newEditCon.goToSalesPath(opp.Id);
            } else {
            		//if User Role = ECGDKAD it should redirect to config product v2
            		UserRole ur = GW_User.getUserRole(opp.OwnerId);
            		if(ur != null && ur.DeveloperName == 'ECGDKAD'){
            			editPage = New PageReference('/c/ProductConfigurator.app');
            			editPage.getParameters().put('oppId', oppId);
            		}else{
            			editPage = Page.LPC_ProductConfigureRedirector;
	            		editPage.getParameters().put('id', oppId);
            		}
            }
        } else {
            editPage = Page.AddSubscription;
            editPage.getParameters().put('oppId', oppId);
            editPage.getParameters().put('id', oppLineId);
            editPage.getParameters().put('retURL','/' + oppId);
            editPage.setRedirect(true);
        }
        return editPage;
	}

	public PGC_OpportunityProductEditButtonRedirect(ApexPages.StandardController stdController) {}
}