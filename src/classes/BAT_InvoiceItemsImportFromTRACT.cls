/**
 * In order to run monthly revenue reports, we need to import data from TRACT using scheduled jobs.
 * @author : GAEA-SYS TEAM
 * @createddate : 18 June 2017
 */
global class BAT_InvoiceItemsImportFromTRACT implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {
 global Datetime executeStart;
    String query;
    String whereClause;
    Set<Id> doneContextRecordIds = new Set<Id>(); 
    
    //Name  Tract_Invoice_Item_Import_PARAMS
    //renderMode=REPORT&P_Opportunity_Line_Item_ID=CONTEXT_RECORD_ID
    //Name    BAT_InvoiceItemsImportFromTRACT
    //Opportunity.MemberUnit__r.EnableTRACT__c = true AND ((from_Date__c < LAST_MONTH AND until_Date__c > LAST_MONTH) OR from_Date__c = LAST_MONTH OR until_Date__c = LAST_MONTH OR from_Date__c = THIS_MONTH OR until_Date__c = THIS_MONTH)
    public BAT_InvoiceItemsImportFromTRACT() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_InvoiceItemsImportFromTRACT');
        this.whereClause = jobDef.setting.WhereClause__c;
        this.numRecords = Database.countQuery('SELECT count() FROM OpportunityLineItem WHERE '+this.whereClause);
        if (this.numRecords>0) readyForRun = true;
    }
    
    global List<OpportunityLineItem> start(Database.BatchableContext BC) {
        return GW_sObject.queryRecords('OpportunityLineItem', whereClause);
    }

    global void execute(Database.BatchableContext BC, List<OpportunityLineItem> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        
        List<WS_ScheduledCallout__c> wsscsScope = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToUpsert = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToDelete = new List<WS_ScheduledCallout__c>();
        
        Set<Id> contextRecordIds = new Set<Id>();
        for (OpportunityLineItem oppLine : scope) {
            if (doneContextRecordIds.contains(oppLine.Id)) continue;
            contextRecordIds.add(oppLine.Id);
            doneContextRecordIds.add(oppLine.Id);
        }
        if (contextRecordIds.isEmpty()) {
            return;
        }
        //create WS_ScheduledCallout__c instance and set to wsscsScope. 
        //WS_ScheduledCallout__c stores all request infos needed for creating a callout.
        UTIL_WSC.forceProcessing('WSC_Tract_Reporting.GetInvoiceItems', contextRecordIds, wsscsScope);
        
        //instantiate bulkhandler and create log records for the context
        UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(contextRecordIds);
        //do callout
        UTIL_WS_ScheduledCalloutHandler.execute(wsscsScope, wsscsToUpsert, wsscsToDelete);
        try {
            WSC_Tract_Reporting.commitAllInvoiceItems();
            upsert wsscsToUpsert UniqueKey__c;
        } catch(Exception ex) {
            UTIL.throwError('BAT_InvoiceItemsImportFromTRACT - Error updating CR Queue record(s)',ex);
        }

        try {
            delete wsscsToDelete;
        } catch(Exception ex) {
            UTIL.throwError('BAT_InvoiceItemsImportFromTRACT - Error deleting CR Queue record(s)',ex);
        }

        try {
            UTIL_WSC.bulkHandler.commitAll();
        } catch(Exception ex) {
            UTIL.throwError('BAT_InvoiceItemsImportFromTRACT - Error committing record(s)',ex);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if( Test.isRunningTest() ) return;
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_InvoiceItemsImportFromTRACT', BC.getJobId());
    }

    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}