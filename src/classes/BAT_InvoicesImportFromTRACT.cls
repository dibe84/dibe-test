/**
 * In order to run monthly revenue reports, we need to import data from TRACT using scheduled jobs.
 * @author : GAEA-SYS TEAM
 * @createddate : 14 June 2017
 */
global class BAT_InvoicesImportFromTRACT implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {
    global Datetime executeStart;
    String query;
    String whereClause;
    Set<Id> doneContextRecordIds = new Set<Id>(); 
    
    //Name  BAT_InvoicesImportFromTRACT
    //MemberUnit__r.EnableTRACT__c = true AND ((CampaignStart__c < LAST_MONTH AND CampaignEnd__c > LAST_MONTH) OR CampaignStart__c = LAST_MONTH OR CampaignEnd__c = LAST_MONTH OR CampaignStart__c = THIS_MONTH OR CampaignEnd__c = THIS_MONTH)
    //Name    Tract_Invoice_Import_PARAMS
    //renderMode=REPORT&P_ACCOUNT_ID=CONTEXT_RECORD_ID&P_OCCURRED_ON_FROM_DATE=LAST_MONTH&P_OCCURRED_ON_THRU_DATE=TODAY
    public BAT_InvoicesImportFromTRACT() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_InvoicesImportFromTRACT');
        this.whereClause = jobDef.setting.WhereClause__c;
        this.numRecords = Database.countQuery('SELECT count() FROM Opportunity WHERE '+this.whereClause);
        if (this.numRecords>0) readyForRun = true;
    }
    
    global List<Opportunity> start(Database.BatchableContext BC) {
        return GW_sObject.queryRecords('Opportunity', whereClause, new List<String>{'Billing_Account__r.Tract_AccountId__c'});
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        
        Map<Id, String> mCurrencyCode = new Map<Id, String>();
        List<WS_ScheduledCallout__c> wsscsScope = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToUpsert = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToDelete = new List<WS_ScheduledCallout__c>();
        Set<Id> contextRecordIds = new Set<Id>();
        for (Opportunity opp : scope) {
            if (opp.Billing_Account__c == null) continue;
            if (doneContextRecordIds.contains(opp.Billing_Account__c)) continue;
            doneContextRecordIds.add(opp.Billing_Account__c);
            mCurrencyCode.put(opp.Billing_Account__c, opp.CurrencyIsoCode);
            if (opp.Billing_Account__r.Tract_AccountId__c == null) continue;
            contextRecordIds.add(opp.Billing_Account__c);
        }
        if (contextRecordIds.isEmpty()) {
            return;
        }
        //create WS_ScheduledCallout__c instance and set to wsscsScope. 
        //WS_ScheduledCallout__c stores all request infos needed for creating a callout.
        UTIL_WSC.forceProcessing('WSC_Tract_Reporting.GetInvoices', contextRecordIds, wsscsScope);

        //instantiate bulkhandler and create log records for the context
        UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(contextRecordIds);
        //do callout
        UTIL_WS_ScheduledCalloutHandler.execute(wsscsScope, wsscsToUpsert, wsscsToDelete);
        try {
            WSC_Tract_Reporting.commitAllInvoices(contextRecordIds, mCurrencyCode);
            upsert wsscsToUpsert UniqueKey__c;
        } catch(Exception ex) {
            UTIL.throwError('BAT_InvoicesImportFromTRACT - Error updating CR Queue record(s)',ex);
        }

        try {
            delete wsscsToDelete;
        } catch(Exception ex) {
            UTIL.throwError('BAT_InvoicesImportFromTRACT - Error deleting CR Queue record(s)',ex);
        }

        try {
            UTIL_WSC.bulkHandler.commitAll();
        } catch(Exception ex) {
            UTIL.throwError('BAT_InvoicesImportFromTRACT - Error committing record(s)',ex);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if( Test.isRunningTest() ) return;
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_InvoicesImportFromTRACT', BC.getJobId());
    }

    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}