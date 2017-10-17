/**
 * In order to run monthly revenue reports, we need to import data from TRACT using scheduled jobs.
 * @author : GAEA-SYS TEAM
 * @createddate : 18 June 2017
 */
global class BAT_RevenueScheduleImportFromTRACT implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {
    global Datetime executeStart;
    String whereClause;
    
    global BAT_RevenueScheduleImportFromTRACT () {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_RevenueScheduleImportFromTRACT');
        this.whereClause = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'TRACT_Service__c'));
        
        if ( this.numRecords > 0 ) readyForRun = true;
    }
    
    global List<TRACT_Service__c> start(Database.BatchableContext BC) {
        return (List<TRACT_Service__c>)GW_sObject.queryRecords('TRACT_Service__c', this.whereClause, new List<String>{'Billing_Account__r.Tract_AccountId__c'});
    }

    global void execute(Database.BatchableContext BC, List<TRACT_Service__c> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        
        List<WS_ScheduledCallout__c> wsscsScope = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToUpsert = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToDelete = new List<WS_ScheduledCallout__c>();
        
        try {
            Set<Id> contextRecordIds = new Set<Id>();
            for (TRACT_Service__c ts : scope) { 
            		contextRecordIds.add(ts.Id); 
            }
            
            //create WS_ScheduledCallout__c instance and set to wsscsScope. 
            //WS_ScheduledCallout__c stores all request infos needed for creating a callout.
            UTIL_WSC.forceProcessing('WSC_Tract_Reporting.GetRevenueSchedule', contextRecordIds, wsscsScope);
    
            //instantiate bulkhandler and create log records for the context
            UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(contextRecordIds); 
            //do callout
            UTIL_WS_ScheduledCalloutHandler.execute(wsscsScope, wsscsToUpsert, wsscsToDelete);
            
            UTIL_WSC_Tract.TRACTRevenueScheduleSync tractrs = new UTIL_WSC_Tract.TRACTRevenueScheduleSync();
            tractrs.commitAll();
        } catch(Exception ex) {
            UTIL.throwError('BAT_RevenueScheduleImportFromTRACT - Error updating CR Queue record(s)',ex);
        }
            
        try {
            upsert wsscsToUpsert UniqueKey__c;
        } catch(Exception ex) {
            UTIL.throwError('BAT_RevenueScheduleImportFromTRACT - Error updating CR Queue record(s)',ex);
        }

        try {
            delete wsscsToDelete;
        } catch(Exception ex) {
            UTIL.throwError('BAT_RevenueScheduleImportFromTRACT - Error deleting CR Queue record(s)',ex);
        }

        try {
            UTIL_WSC.bulkHandler.commitAll();
        } catch(Exception ex) {
            UTIL.throwError('BAT_RevenueScheduleImportFromTRACT - Error committing record(s)',ex);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_RevenueScheduleImportFromTRACT', BC.getJobId());
    }

    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}