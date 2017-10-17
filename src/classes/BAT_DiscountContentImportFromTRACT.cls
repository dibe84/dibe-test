/**
 * Created by rvannierop on 2/28/2017.
 */

global class BAT_DiscountContentImportFromTRACT implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {

    global Datetime executeStart;

    String whereClause;
    List<WS_ScheduledCallout__c> crsInput;

    global BAT_DiscountContentImportFromTRACT() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_DiscountContentImportFromTRACT');
        whereClause = 'Name = \'BAT_DiscountContentImportFromTRACT\' AND Active__c = true';
        this.numRecords = Database.countQuery('SELECT count() from CustomJob__c WHERE '+this.whereClause);
        if (this.numRecords>0) readyForRun = true;
    }

    global List<CustomJob__c> start(Database.BatchableContext BC) {
        List<CustomJob__c> cjs = GW_sObject.queryRecords('CustomJob__c', whereClause);
        return cjs;
    }

    global void execute(Database.BatchableContext BC, List<CustomJob__c> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();

        List<WS_ScheduledCallout__c> wsscsScope = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToUpsert = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToDelete = new List<WS_ScheduledCallout__c>();

        CustomJob__c cj = scope[0];
        Set<Id> contextRecordIds = new Set<Id>();
        contextRecordIds.add(cj.Id);

        WS_ScheduledCallout__c singleWssc = new WS_ScheduledCallout__c();
        UTIL_WSC.forceProcessing('WSC_Tract.DiscountContentSync', contextRecordIds, wsscsScope);

        // instantiate bulkhandler
        UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(contextRecordIds);
        GW_CustomAttribute.cacheCustomAttributes(contextRecordIds);

        UTIL_WS_ScheduledCalloutHandler.execute(wsscsScope, wsscsToUpsert, wsscsToDelete);


        try {
            upsert wsscsToUpsert UniqueKey__c;
        } catch(Exception ex) {
            UTIL.throwError('BAT_DiscountContentImportFromTRACT - Error updating CR Queue record(s)',ex);
        }

        try {
            delete wsscsToDelete;
        } catch(Exception ex) {
            UTIL.throwError('BAT_DiscountContentImportFromTRACT - Error deleting CR Queue record(s)',ex);
        }

        try {
            //update logsToUpdate;
            UTIL_WSC.bulkHandler.commitAll();
        } catch(Exception ex) {
            UTIL.throwError('BAT_DiscountContentImportFromTRACT - Error committing record(s)',ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_DiscountContentImportFromTRACT', BC.getJobId());
    }

    // interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }

}