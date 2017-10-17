public with sharing class HNDL_FinanceRequest extends TriggerManager.TriggerHandler {
	// Constructor
    public HNDL_FinanceRequest() { super('HNDL_FinanceRequest', Finance_Request__c.sObjectType); }	

    List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();

	public override void beforeInsert(SObject so) {
		 Finance_Request__c fr = (Finance_Request__c) so;

		 GW_FinanceRequest.createFinanceRequest( new List<Finance_Request__c>{fr} );
	}

    public override void beforeUpdate(SObject oldSo, SObject so) {
        Finance_Request__c fr = (Finance_Request__c) so;
        Finance_Request__c oldFr = (Finance_Request__c) oldSo;

        checkIfRecalculatedBeforeApproval(oldFr, fr);
        
    }

	public override void afterInsert(SObject so) {
        Finance_Request__c fr = (Finance_Request__c) so;

        GW_FinanceRequest.createFinanceRequestLineItem( new List<Finance_Request__c>{fr} );
    }

    private void checkIfRecalculatedBeforeApproval(Finance_Request__c oldFr, Finance_Request__c newFr ){
        if (newFr.Status__c == 'Pending' && newFr.Status__c <> oldFr.Status__c && newFr.Needs_Recalculation__c == true)
            newFr.addError('Please recalculate before submitting for approval.', false);
    }

}