/**
 * Created by jeze on 5/14/2017.
 */

global class BAT_ServiceImportFromTract implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {
    global Datetime executeStart;
    String whereClause;
    
    global BAT_ServiceImportFromTract() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_ServiceImportFromTract');
        this.whereClause = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'Opportunity'));
        
        if (this.numRecords>0) readyForRun = true;
    }
    
    global List<Opportunity> start(Database.BatchableContext BC) {
        List<Opportunity> opps = GW_Opportunity.getList(this.whereClause, new List<String>());
        return opps;
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        if( this.executeStart == null ) this.executeStart = Datetime.now();
        
        List<WS_ScheduledCallout__c> wsscsScope = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToUpsert = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToDelete = new List<WS_ScheduledCallout__c>();
        
        try {
            Set<Id> contextRecordIds = new Set<Id>();
            for (Opportunity opp : scope) { contextRecordIds.add(opp.Id); }
            
            //create WS_ScheduledCallout__c instance and set to wsscsScope. 
            //WS_ScheduledCallout__c stores all request infos needed for creating a callout.
            UTIL_WSC.forceProcessing('WSC_Tract_Reporting.GetServices', contextRecordIds, wsscsScope);
    
            //instantiate bulkhandler and create log records for the context
            UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(contextRecordIds);
            //do callout
            UTIL_WS_ScheduledCalloutHandler.execute(wsscsScope, wsscsToUpsert, wsscsToDelete); 
        } catch(Exception ex) {
            UTIL.throwError('BAT_ServiceImportFromTract - Error updating CR Queue record(s)',ex);
        }
        
        try {
            upsert wsscsToUpsert UniqueKey__c;
        } catch(Exception ex) {
            UTIL.throwError('BAT_ServiceImportFromTract - Error updating CR Queue record(s)',ex);
        }

        try {
            delete wsscsToDelete;
        } catch(Exception ex) {
            UTIL.throwError('BAT_ServiceImportFromTract - Error deleting CR Queue record(s)',ex);
        }

        try {
            UTIL_WSC.bulkHandler.commitAll();
        } catch(Exception ex) {
            UTIL.throwError('BAT_ServiceImportFromTract - Error committing record(s)',ex);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_ServiceImportFromTract', BC.getJobId());
    }

    // interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}