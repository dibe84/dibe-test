global class BAT_WS_ScheduledCalloutHandler implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {

	global Datetime executeStart;

    String queryString;
    List<WS_ScheduledCallout__c> crsInput;

    global BAT_WS_ScheduledCalloutHandler() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_WS_ScheduledCalloutHandler');
		this.queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'WS_ScheduledCallout__c'));
        if (this.numRecords>0) readyForRun = true;
    }

    global BAT_WS_ScheduledCalloutHandler(List<WS_ScheduledCallout__c> crs) {
        this.crsInput = crs;
    }

    global List<WS_ScheduledCallout__c> start(Database.BatchableContext BC) {
        if (crsInput == null){
        	List<WS_ScheduledCallout__c> crs = GW_sObject.queryRecords('WS_ScheduledCallout__c', this.queryString);
        	return crs;
        }
        else{
            return crsInput;
        }
    }

    global void execute(Database.BatchableContext BC, List<WS_ScheduledCallout__c> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        List<WS_ScheduledCallout__c> wsscsToUpdate = new List<WS_ScheduledCallout__c>();
        List<WS_ScheduledCallout__c> wsscsToDelete = new List<WS_ScheduledCallout__c>();
        //List<WS_Log__c> logsToUpdate = new List<WS_Log__c>();

        Set<Id> contextRecordIds = new Set<Id>();
        for (WS_ScheduledCallout__c wssc : scope) { contextRecordIds.add(wssc.RecordId__c); }

        // instantiate bulkhandler
        UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(contextRecordIds);
        GW_CustomAttribute.cacheCustomAttributes(contextRecordIds);

		// Prioritize objects in queue
		scope = UTIL_WSC.sortAccordingToPriority(scope);
        
        //Avoid multiple callouts that refer to the same record to be executed in the same batch (the second one will be ignored and considered in the next batch)
        Set<id> processedIds = new Set<id>();

        for (WS_ScheduledCallout__c wssc : scope) {
            if (!processedIds.contains(wssc.RecordId__c)) {
                processedIds.add(wssc.RecordId__c);
                UTIL_WSC.WSC_Request req;
                UTIL_WSC.WSC_Result res;

                try {
                    req = UTIL_WSC.getWSC_Request(wssc.API__c+'.'+wssc.Method__c); // instantiate request object
                    req.init(wssc.RecordId__c);         // init with context record
                    res = req.call();                   // try call and get result
                } catch(Exception e) {
                    UTIL.log('BAT_WS_ScheduledCalloutHandler execute() - Error initializing UTIL_WSC request: '+e.getMessage());
                    UTIL.log('stack: '+e.getStackTraceString() );
                    if (req.isContextRecordDeleted == true) {
                        wsscsToDelete.add(wssc);
                        continue;
                    }
                }

                req.log.ScheduledCallout__c = wssc.Id;
                // handle ScheduledCallout object changes
                wssc.LastAttempt__c = Datetime.now();

                if (wssc.Attempts__c == null) {
                    wssc.Attempts__c = 0;
                }
                wssc.Attempts__c = wssc.Attempts__c + 1;
                
                if (res == null) {
                    wssc.Status__c = 'ResIsNull';
                } else {
                    if (res.retryCallout)
                        wssc.Status__c = 'Retry';
                    else
                        wssc.Status__c = 'Done';
                }
                wsscsToUpdate.add(wssc);
            }
        }

        try {
            update wsscsToUpdate;
        } catch(Exception ex) {
            UTIL.throwError('BAT_WS_ScheduledCalloutHandler - Error updating CR Queue record(s)',ex);
        }

        try {
            delete wsscsToDelete;
        } catch(Exception ex) {
            UTIL.throwError('BAT_WS_ScheduledCalloutHandler - Error deleting CR Queue record(s)',ex);
        }

        try {
            //update logsToUpdate;
            UTIL_WSC.bulkHandler.commitAll();
        } catch(Exception ex) {
            UTIL.throwError('BAT_WS_ScheduledCalloutHandler - Error committing record(s)',ex);
        }
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_WS_ScheduledCalloutHandler', BC.getJobId());
    }

	// interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
	
	// Bunhor @07-June-17: Just for testing 
	public static void doScheduledCallout_forTest(String scid) {
		List<WS_ScheduledCallout__c> crs = GW_sObject.queryRecords('WS_ScheduledCallout__c', 'id=\'' + scid + '\'');
		
		BAT_WS_ScheduledCalloutHandler bat = new BAT_WS_ScheduledCalloutHandler();
		bat.execute(null, crs);
	}
}