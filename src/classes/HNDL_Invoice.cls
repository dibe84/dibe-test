public with sharing class HNDL_Invoice extends TriggerManager.TriggerHandler { 

    //private Set<Id> invoicesCheckRSS = new Set<Id>();
    private Set<Id> invoicesCheckIls = new Set<Id>();
    private Set<Id> invoicesAPISynced = new Set<Id>();

    List<WS_ScheduledCallout__c> wsscToUpsert = new List<WS_ScheduledCallout__c>();
    
    private List<InvoiceLine__c> ilsToCheckStatus = new List<InvoiceLine__c>();
    private List<InvoiceLine__c> ilsToAPISync = new List<InvoiceLine__c>();
    private List<InvoiceLine__c> ilsToUpdate = new List<InvoiceLine__c>();
    
    private List<RS__c> rssToCheckStatus = new List<RS__c>();

	private static Set<Id> rssIdSet = new Set<Id>();
	private static Set<Id> revIdSet = new Set<Id>();
    
    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        //
		// Gather rev / RS before, handle update in finally() block
		if(hndlEvent == TriggerManager.triggerEventType.BeforeDelete) {
			Map<Id,InvoiceLine__c> invLineMap = new Map<Id,InvoiceLine__c>(GW_InvoiceLine.getListFromRelated(GW_sObject.getIdSet(soLst)));
			UTIL.cache(soLst);
            UTIL.cache(invLineMap.values());
			for(InvoiceLine__c invLine : invLineMap.values()) {
				if(invLine.RS__c != null) rssIdSet.add(invLine.RS__c);
				if(invLine.Rev__c != null) revIdSet.add(invLine.Rev__c);
			}
		}
    }
    
    public override void bulkAfter(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        UTIL.cache(soLst);
        UTIL_WSC.checkForProcessing('WSC_Fiqas2.InvoiceGetPDF', soLst, wsscToUpsert);
		UTIL_WSC.checkForProcessing('WSC_API_SFECG_v1.InvoicePDFGet', soLst, wsscToUpsert);
    }
    
    public override void beforeInsert(SObject so) {
        Invoice__c inv = (Invoice__c)so;
        GW_Invoice.setStatus(inv); // leave as last method!
    }
    
    public override void beforeUpdate(SObject oldSo, SObject so) {
        Invoice__c inv = (Invoice__c)so;
        Invoice__c oldinv = (Invoice__c)oldSo;
        UTIL_RecordRestriction.checkFieldLocks(so, oldSo);
        //checkCancelledAndAllowed(inv, oldinv);
        GW_Invoice.setBillingSystemInvoiceNumberinLines( oldinv , inv );
        GW_Invoice.setStatus(inv); // leave as last method!
    }
    
    public override void beforeDelete(SObject so) {
        //UTIL_RecordRestriction.checkDeletionLock(so);
        so.addError('Invoices cannot be deleted');
    }
    
    public override void afterUpdate(SObject oldSo, SObject so) {
        Invoice__c inv = (Invoice__c)so;
        Invoice__c oldinv = (Invoice__c)oldSo;
        if (inv.UniquePlatformId__c != null
            && inv.UniquePlatformId__c != oldInv.UniquePlatformId__c ) {
                invoicesAPISynced.add(inv.Id);
        }
        else if (inv.NumStatus__c != oldinv.NumStatus__c &&
            (inv.Numstatus__c == -1 || oldinv.Numstatus__c == -1)) invoicesCheckIls.add(inv.Id);
    }
    
    public override void andFinally() {
        
        if (!invoicesCheckIls.isEmpty() ){
            ilsToCheckStatus.addAll(GW_InvoiceLine.getListFromRelated(invoicesCheckIls));
            ilsToCheckStatus = GW_InvoiceLine.checkStatusChange(ilsToCheckStatus);
            ilsToUpdate.addAll(ilsToCheckStatus);
        }
        if (!invoicesAPISynced.isEmpty()) {
            ilsToAPISync.addAll(GW_InvoiceLine.getListFromRelated(invoicesAPISynced));
            GW_InvoiceLine.markAsSynced(ilsToAPISync);
            ilsToUpdate.addAll(ilsToAPISync);
        }
        if (!ilsToUpdate.isEmpty()) {
            update ilsToUpdate;
        }
        
		if(hndlEvent == TriggerManager.triggerEventType.AfterDelete) {
			if (revIdSet!=null && !revIdSet.isEmpty()) {
        		GW_InvoiceLine.calcRollupsInvoiceLineToRev(revIdSet);   
			}   
			if (rssIdSet!=null && !rssIdSet.isEmpty()) {
        		GW_InvoiceLine.calcRollupsInvoiceLineToRS(rssIdSet);     
			}
		}
        
       	if (wsscToUpsert.size()>0){
            try{
               upsert wsscToUpsert UniqueKey__c; 
            }
            catch(Exception ex){
                UTIL.throwError('HNDL_Invoice - Error inserting WS_ScheduledCallouts',ex);
            }
        }
    } 

    // Constructor
    public HNDL_Invoice() { super('HNDL_Invoice', Invoice__c.sObjectType); }    
    
    // In new Invoicing flow, all invoices can be canceled. Eg. due to issues at Billing System.
    ///private void checkCancelledAndAllowed(Invoice__c inv, Invoice__c oldinv){
    // /   if (inv.Cancelled__c && !oldinv.PeriodComplete__c) inv.addError('Period is not complete yet, this invoice can\'t be cancelled. Adjust the campaign/opportunity or revenue instead.');
    //}
}