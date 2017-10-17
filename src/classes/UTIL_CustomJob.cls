public class UTIL_CustomJob {
    private static DateTime yesterday = (DateTime) Date.today()-1;
    public static final Integer DEFAULT_LIMIT = 200;
    private static List<CustomJob__c> defaultJobs = new List<CustomJob__c>{
        new CustomJob__c(Name='BAT_AccountSyncFiqas',JobFrequency__c='2min',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=2,Active__c=true,WhereClause__c='FQ_syncAccountDetails__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_InvoiceSyncFiqas',JobFrequency__c='2min',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='FQ_SyncPending__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_SyncMetricsFromRS',JobFrequency__c='2min',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=20,Active__c=true,WhereClause__c='SyncMetrics__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_AutoExtendRevItems',JobFrequency__c='2min',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=20,Active__c=true,WhereClause__c='ExtensionPending__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_SyncOliStatus',JobFrequency__c='10sec',JobType__c='Queue',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=100,Active__c=true,WhereClause__c='OutOfSync__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_SyncOppStatus',JobFrequency__c='2min',JobType__c='Queue',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=100,Active__c=true,WhereClause__c='OutOfSync__c = TRUE OR Billing_Account__c = null',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_SyncInvoices',JobFrequency__c='10sec',JobType__c='Queue',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=100,Active__c=true,WhereClause__c='OutOfSync__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_SyncRevStatus',JobFrequency__c='2min',JobType__c='Queue',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=100,Active__c=true,WhereClause__c='OutOfSync__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_SyncRsStatus',JobFrequency__c='2min',JobType__c='Queue',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=100,Active__c=true,WhereClause__c='OutOfSync__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_WS_ScheduledCalloutHandler', JobFrequency__c='2min',JobType__c='Batch',LastRun__c=system.today().addDays(-1),LastCheck__c=yesterday,BatchSize__c=100,Active__c=true,WhereClause__c='Pending__c = TRUE',IsRunning__c=false, TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_PortalOrders', JobFrequency__c='2min', JobType__c='Batch', LastRun__c=system.today().addDays(-1), LastCheck__c=system.today().addDays(-1), BatchSize__c=10, Active__c=true, WhereClause__c='Status__c = \'Ready to process\'', IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_LostOpportunityAfterDays', JobFrequency__c='Daily', JobType__c='Batch', LastRun__c=system.today().addDays(-1), LastCheck__c=system.today().addDays(-1), BatchSize__c=10, Active__c=true, WhereClause__c='StageName NOT IN ( \'Signed\' , \'Scheduled\' , \'Running\' , \'Finished\',\'Lost\' ) AND CreatedDate < LAST_N_DAYS:60', IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_RetrieveAccountLocations',JobFrequency__c='2min',JobType__c='Queue',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=5,Active__c=true,WhereClause__c='SyncLocation__c = TRUE',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_RetrieveAccountRegions',JobFrequency__c='2min',JobType__c='Queue',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=5,Active__c=true,WhereClause__c='SyncRegion__c = TRUE',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_TouchAccount',JobFrequency__c='2min',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=5,Active__c=true,WhereClause__c='LastModifiedDate < LAST_WEEK',IsRunning__c=false,TimeoutPerBatch__c = 3600),

		//Additional CustomJob for TRACT
        new CustomJob__c(Name='BAT_SyncFinanceRequestFromTRACT',JobFrequency__c='2min',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='OutOfSync__c = TRUE',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_DiscountContentImportFromTRACT',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='N/A',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_DiscountResourceImportFromTRACT',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='N/A',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_ProductDiscountImportFromTRACT',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='Tract_Id__c <> null AND Parent__c = null',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_ProductImportFromTRACT',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='N/A',IsRunning__c=false,TimeoutPerBatch__c = 3600),
		new CustomJob__c(Name='BAT_PriceBookImportFromTRACT',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='N/A',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='BAT_SyncOliStatus',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='Name <> NULL',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_SyncInvoiceLineStatus',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='Name <> NULL',IsRunning__c=false,TimeoutPerBatch__c = 3600),
        new CustomJob__c(Name='Q_CheckPermissionGroups',JobFrequency__c='Daily',JobType__c='Batch',LastRun__c=yesterday,LastCheck__c=yesterday,BatchSize__c=10,Active__c=true,WhereClause__c='Name <> NULL',IsRunning__c=false,TimeoutPerBatch__c = 3600)
	};

    public static String hourlyCronExpression = '0 0 * * * ?';
    public static String dailyCronExpression = '0 0 13 * * ?';
    public static String monthlyCronExpression = '0 0 13 1 * ?';
    public static String weeklyCronExpression = '0 0 13 ? * 1';

    public static Long hourlyPeriodSec = 60*60;
    public static Long m15PeriodSec = hourlyPeriodSec/4;
    public static Long m5PeriodSec = hourlyPeriodSec/12;
    public static Long m2PeriodSec = hourlyPeriodSec/30;
    public static Long dailyPeriodSec = hourlyPeriodSec*24;
    public static Long weeklyPeriodSec = dailyPeriodSec*7;
    public static Long monthlyPeriodSec = dailyPeriodSec*30;

    public interface ICustomJob{
        Boolean readyForRun();
        Integer getNumRecords();
    }

///////////////////////////////////////////////////////////////////////////
// Custom Job settings
///////////////////////////////////////////////////////////////////////////
    private static Map<String, CustomJobDef> jobMap {
        get {
            if (jobMap == null) jobMap = loadJobsFromSettings();
            return jobMap;
        }
        private set;
    }

    public static Map<String,CustomJobDef> loadJobsFromSettings() {
        List<CustomJob__c> allJobs = CustomJob__c.getall().values();
        Map<String,CustomJobDef> customJobMap = new Map<String,CustomJobDef>();
        for (CustomJob__c job : allJobs) {
            if (job.Active__c) {
                CustomJobDef j = new CustomJobDef(job);
                customJobMap.put(job.Name,j);
            }
        }
        return customJobMap;
    }

    public static CustomJobDef getJobDef(String jobName) {
        return jobMap.get(jobName);
    }

    public static List<CustomJobDef> getOverDueJobs() {
        List<CustomJobDef> overDueJobs = new List<CustomJobDef>();
        for (CustomJobDef job : jobMap.values() ) {
            if (job.timeOverDue > 0 && job.setting.IsRunning__c == false) {
                overDueJobs.add(job);
            }
        }
        return overDueJobs;
    }

    public static Map<String, List<CustomJobDef>> getOverDueJobsMap() {
      Map<String, List<CustomJobDef>> prioritizedJobMap = new Map<String, List<CustomJobDef>>();
      // JobMap is not sorted by queuePriority, so it might go A A B C A B B D A B
      // If B is currently running, next B will be added to the queue, which is NOT expected behavior
      // as processes should be launched in parallel for queuePriorities only, not within the queue
      Set<String> runningQueuesSet = new Set<String>();
        for (CustomJobDef job : jobMap.values() ) {
          if(job.setting.IsRunning__c) {
            runningQueuesSet.add(job.setting.QueuePriority__c);
          }
          if (job.timeOverDue > 0 && job.setting.IsRunning__c == false) {
              List<CustomJobDef> overDueJobs = prioritizedJobMap.get(job.setting.QueuePriority__c) == null ? new List<CustomJobDef>() : prioritizedJobMap.get(job.setting.QueuePriority__c);
              overDueJobs.add(job);
              prioritizedJobMap.put(job.setting.QueuePriority__c,overDueJobs);
          }
        }
        // Sort queue processes or remove running queues from map
        for(String priorityQueueKey : prioritizedJobMap.keySet()) {
          if(runningQueuesSet.contains(priorityQueueKey)) {
            prioritizedJobMap.remove(priorityQueueKey);
          }
          else {
            prioritizedJobMap.get(priorityQueueKey).sort();
          }
        }
        return prioritizedJobMap;
    }

    // The purpose of this method is to update the start time (execution start, not enqueue)
    public static void updateJobExecuteStartTime(Id jobId, Datetime executeStart) {
        try {
            Log__c jobLog = [SELECT Id, CustomJobParentId__c FROM Log__c WHERE CustomJobParentId__c =: jobId];
            jobLog.CustomJobStartTime__c = executeStart;
            update jobLog;
        } catch (Exception e) {
            UTIL.log('Exception while updating Log__c for custom job' + e);
        }
    }

    public static void startAllCustomJobs() {
        for (String jobDefName : jobMap.keySet() ) {
	    startCustomJob(jobDefName);
        }
    }

    public static void startCustomJob(String name){
        CustomJobDef jobDef = jobMap.get(name);
        UTIL_CustomJob.ICustomJob jobInstance = jobDef.instantiateClass();
        if ( jobInstance.readyForRun() ) { jobDef.execute(jobInstance); }
    }

    public static void removeExistingCustomJobs() {
        // KF 20151006: This will remove any instances of the scheduler that have run from the AsyncApexJob table and are
        // chained executions caused by calling the .start() function on SCH_CustomJobDispatcher
        List<CronTrigger> cronsToDelete = [SELECT  Id,  CronJobDetail.Name,  NextFireTime,  State
                                           FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SCH_CustomJobDispatcher Chained Execution%' AND
                                          (State='COMPLETED' OR State='DELETED')];
        if (!cronsToDelete.isEmpty()) {
            for (CronTrigger cron : cronsToDelete) {
                if (cron.Id != null) {
                    try {
                        system.abortJob(cron.Id);
                    } catch (Exception e) {
                        // KF 20151006: Possibly this can fail if multiple instances of SCH_CustomJobDispatcher are running simultaneously, nothing to
                    }
                }
            }
        }
    }

    public static void checkIsRunningStatusForJobs() {
        Set<String> runningStatuses = new Set<String>{'Holding','Queued','Preparing','Processing'};
        Map<Id,CustomJob__c> jobRunIdToCustomJobMap = new Map<Id,CustomJob__c>();
        for(CustomJob__c cJob : [SELECT Id, Name, IsRunning__c, JobIdLastRun__c FROM CustomJob__c WHERE IsRunning__c =: TRUE and Active__c =: TRUE]) {
            jobRunIdToCustomJobMap.put((Id)cJob.JobIdLastRun__c,cJob);
        }

        Map<Id,AsyncApexJob> asyncJobMap = new Map<Id,AsyncApexJob>([SELECT Status, Id FROM AsyncApexJob WHERE Id IN :jobRunIdToCustomJobMap.keySet()]);
        List<CustomJob__c> jobsToUpdate = new List<CustomJob__c>();
        for(Id jobId : jobRunIdToCustomJobMap.keySet()) {
            CustomJob__c cJob = jobRunIdToCustomJobMap.get(jobId);
            if(asyncJobMap.containsKey(jobId) && !runningStatuses.contains(asyncJobMap.get(jobId).Status) || !asyncJobMap.containsKey(jobId)) {
                cJob.IsRunning__c = FALSE;
                jobsToUpdate.add(cJob);
            }
        }

        try {
            upsert jobsToUpdate;
        } catch (Exception e) {
            UTIL.log('Exception while updating CustomJob__c with proper isRunning value' + e);
        }
    }

    public static void markJobFinished(String jobName, Id jobId) {
        // KF 20151006: this is called by all BAT_/Q_ implementations to indicate a job is finished, when this happens we set
        // the IsRunning__c checkbox to false which will allow job to be run again
        try {
            CustomJob__c customJob = [SELECT Id, Name, JobFrequency__c, IsRunning__c, LastRun__c, LastCheck__c, LastRunNumRecords__c FROM CustomJob__c WHERE Name = :jobName FOR UPDATE];
            customJob.IsRunning__c = false;
            update customJob;
            Log__c[] customJobLogs = [SELECT Id, Name, CustomJobParentId__c FROM Log__c WHERE CustomJobParentId__c =: jobId];
            if (customJobLogs.isEmpty()) return; 
            // Upadate Log__c
            Log__c customJobLog = customJobLogs[0];
            if(customJobLog != null) {
                customJobLog.CustomJobEndTime__c = DateTime.now();
                customJobLog.CustomJobNumRecords__c = customJob.LastRunNumRecords__c;
                update customJobLog;
            }
            // Purge Log__c, there's no need to keep more than 50 recent logs for given job
           List<Log__c> existingLogs = [SELECT Id, Name, CustomJobEndTime__c, CustomJobName__c FROM Log__c WHERE CustomJobName__c =: customJob.Name ORDER BY CustomJobEndTime__c DESC Limit 1000];
            if(existingLogs.size() > 50) {
                List<Log__c> logsToDelete = new List<Log__c>();
                for(Integer i = 50; i < existingLogs.size(); i++) {
                    logsToDelete.add(existingLogs[i]);
                }
                delete logsToDelete;
            }
        } catch (Exception e) {
            UTIL.throwError(e.getMessage(), e);
        }

        // Start the scheduler again
		if(!Test.isRunningTest()){
			SCH_CustomJobDispatcher.start();
		}
    }

    public class CustomJobDef implements  Comparable {
        public CustomJob__c setting;
        public Decimal timeOverDue;

        public CustomJobDef(CustomJob__c jobSetting) {
            this.setting = jobSetting;
            this.timeOverDue = getTimeOverdue(this.setting.LastCheck__c, this.setting.JobFrequency__c);
        }

        public Integer compareTo(Object compareTo){
            CustomJobDef compJobDef = (CustomJobDef) compareTo;
            if (timeOverDue == compJobDef.timeOverDue) return 0;
            if (timeOverDue > compJobDef.timeOverDue) return 1;
            return -1;
        }

        private Decimal getTimeOverDue(Datetime lastRun, String jobFrequency) {
            Decimal timeOverdue;
            Long intervalSec = getIntervalSec(jobFrequency);
            timeOverdue = ((Datetime.now().getTime()/1000) - ((lastRun.getTime()/1000) + intervalSec))/60; // in minutes
            if (timeOverdue < 0) timeOverdue = 0;
            return timeOverdue;
        }

        public Long getIntervalSec(String jobFrequency) {
            Long intervalSec;
            if (jobFrequency == '10sec')    intervalSec = 10; // just for testing purposes
            if (jobFrequency == '2min')     intervalSec = UTIL_CustomJob.m2PeriodSec;
            if (jobFrequency == '5min')     intervalSec = UTIL_CustomJob.m5PeriodSec;
            if (jobFrequency == '15min')    intervalSec = UTIL_CustomJob.m15PeriodSec;
            if (jobFrequency == 'Hourly')   intervalSec = UTIL_CustomJob.hourlyPeriodSec;
            if (jobFrequency == 'Daily')    intervalSec = UTIL_CustomJob.dailyPeriodSec;
            if (jobFrequency == 'Weekly')   intervalSec = UTIL_CustomJob.weeklyPeriodSec;
            if (jobFrequency == 'Monthly')  intervalSec = UTIL_CustomJob.monthlyPeriodSec;
            if (intervalSec == null)        intervalSec = UTIL_CustomJob.hourlyPeriodSec; // default hourly
            return intervalSec;
        }

        public void execute(ICustomJob jobInstance) {
            // KF 20151006: We select the custom setting with 'FOR UPDATE' and IsRunning__c = false to ensure that if we get instructed to execute a certain jobInstance it is not running at this point in time
            CustomJob__c jobToRun;
            List<CustomJob__c> jobsToRun = [SELECT Id, Name, JobFrequency__c, JobIdLastRun__c, IsRunning__c, LastRun__c, LastCheck__c, LastRunNumRecords__c FROM CustomJob__c WHERE Name = :this.setting.name AND IsRunning__c = false FOR UPDATE];

            if (jobsToRun.size() == 1) {
                jobToRun = jobsToRun.get(0);
            } else {
                // KF 20151006: This is triggered when the current jobInstance has already been started in another execution thread, in this case we have nothing to do anymore, the other execution instance will call the scheduler again
                return;
            }

            try {
                Id lastRunId = null;

                if (this.setting.JobType__c == 'Batch') {
                    lastRunId = Database.executeBatch((Database.Batchable<sObject>) jobInstance,(Integer)this.setting.BatchSize__c);
                }
                else if (this.setting.JobType__c == 'Queue') {
                    lastRunId = System.enqueueJob((System.Queueable) jobInstance);
                } else {
                    UTIL.throwError('No type defined for Custom Job, configuration: ' + this.setting);
                }

                jobToRun.IsRunning__c = true;
                jobToRun.LastCheck__c = jobToRun.LastRun__c = DateTime.now();
                jobToRun.JobIdLastRun__c = lastRunId;
                jobToRun.LastRunNumRecords__c = jobInstance.getNumRecords();
                update jobToRun;
                // Create additional log for performance-check purposes / check Batch Monitor
                Log__c runningJobLog = new Log__c();
                runningJobLog.CustomJobParentId__c = lastRunId;
                runningJobLog.CustomJobStartTime__c = jobToRun.LastRun__c;
                runningJobLog.CustomJobName__c = jobToRun.Name;
                runningJobLog.Short_Message__c = 'Custom job monitoring log: ' + jobToRun.Name;
                insert runningJobLog;
            } catch (Exception ex) {
                jobToRun.LastCheck__c = DateTime.now().addMinutes(15);
                update jobToRun;
                String errorMsg = 'Custom Job ERROR: '+this.setting.Name+'\r\n\r\n'+ ex.getMessage() +'\r\n\r\n'+ex.getStackTraceString();
                UTIL_Email.sendSystemAlert('Custom Job ERROR',errorMsg);
                //UTIL.throwError('Error starting Custom Job: '+this.setting.Name, ex );
                UTIL.writeLog('ERROR',errorMsg,'UTIL_CustomJob');
                UTIL.log(errorMsg);
                SCH_CustomJobDispatcher.start();
            }
        }

        public void updateLastCheckTimeStamp() {
            this.setting.LastCheck__c = Datetime.now();
            update this.setting;
        }

        public ICustomJob instantiateClass() {
            Type t = Type.forName(this.setting.Name);
            if (t != null )
                return (ICustomJob) t.newInstance();
            else return null;
        }
    }

    public static void createTestCustomJobs() {
       if (Test.IsRunningTest()) createMissingCustomJobs();
    }

    public static void createMissingCustomJobs() {
        List<CustomJob__c> jobsToInsert = new List<CustomJob__c>();
        for (CustomJob__c cj : defaultJobs ) {
            if (!jobMap.containsKey(cj.Name)) {
                jobsToInsert.add(cj);
            }
        }
        if (jobsToInsert.size()>0) insert jobsToInsert;
        jobMap = loadJobsFromSettings();
    }

    public static void recreateAllCustomJobs() {
        List<CustomJob__c> existingJobs = [SELECT Id FROM CustomJob__c];
        delete existingJobs;
        insert defaultJobs;
    }

    public static String getWhereQuery(CustomJobDef jobDef) {
        if(jobDef == null) return '';

        String whereQuery = ' ';
        String whereClause = jobDef.setting.WhereClause__c == 'N/A' || jobDef.setting.WhereClause__c == null ? '' : jobDef.setting.WhereClause__c;
        whereQuery += whereClause;
        whereQuery += jobDef.setting.OrderBy__c == null ? '' : ' ORDER BY ' + jobDef.setting.OrderBy__c;
        whereQuery += jobDef.setting.Limit__c == null ? (' LIMIT ' + UTIL_CustomJob.DEFAULT_LIMIT) : (' LIMIT ' + Integer.valueOf(jobDef.setting.Limit__c));
        // You can't have ORDER BY and FOR UPDATE in one query due to SOQL rules
        if(whereQuery.contains('ORDER BY') == FALSE) {
            whereQuery += jobDef.setting.ForUpdate__c == TRUE ? ' FOR UPDATE' : '';
        }
        UTIL.Log('XX ' + jobDef.setting.Name + ' whereQuery: ' + whereQuery);

        return whereQuery;
    }

    public static String getCountQuery(CustomJobDef jobDef, String objectName) {
        if(jobDef == null || objectName == null || objectName == '') {
            throw new UTIL.CustomException('Impossible to build count query - not enough parameters!');
        }
        String whereClause = jobDef.setting.WhereClause__c == 'N/A' || jobDef.setting.WhereClause__c == null ? '' : ' WHERE ' + jobDef.setting.WhereClause__c;
        return 'SELECT count() FROM ' + objectName + whereClause;
    }

    public static String createCronExpForFutureXSeconds( Integer seconds ){
        DateTime now = System.now().addSeconds( seconds );
        return now.second() + ' ' 
            + now.minute() + ' ' 
            + now.hour() + ' '
            + now.day() + ' '
            + now.month() + ' ? ' 
            + now.year();
    }    
}
