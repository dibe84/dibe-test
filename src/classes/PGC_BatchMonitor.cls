public without sharing class PGC_BatchMonitor {

    public Map<String, List<BatchJob>> completedBatchJobsPriorityMap {get;set;}
    public Map<String, List<BatchJob>> runningBatchJobsPriorityMap {get; set;}
    public Map<String, List<BatchJob>> failedBatchJobsPriorityMap {get; set;}
    public Map<String, List<BatchJob>> anyBatchJobsPriorityMap {get; set;}
    public List<BatchJob> anyBatchJobsPriorityList {get; set;}

    public DateTime lastRefreshTime {get;set;}
    public Set<String> runningStatusesSet;
    public Integer gmtOffset {get;set;} // workaround for datetimes to show time in user's locale
    public enum OverdueColor {GREEN, YELLOW, ORANGE, RED} // improve the job list with color and Overdue time
    public Boolean showAlert {get; set;}
    public static final String OVERDUE_SECTION_NAME = 'Overdue';
    public static final String NORMAL_SECTION_NAME = 'Behaving Normally';
    public static final String PLACEHOLDER_SECTION_NAME = 'Place Holder';
    public static final Integer PLACEHOLDER_ROWS = 14;

    public PGC_BatchMonitor() {
        runningStatusesSet = new Set<String>();
        runningStatusesSet.add('Queued');
        runningStatusesSet.add('Processing');
        runningStatusesSet.add('Holding');

        reloadBatchJobs();
        gmtOffset = (System.now().monthGmt() >= 4 &&  System.now().monthGmt() <= 10) == true ? 12 : 24;
    }

    public void reloadBatchJobs() {
        //Query the Batch apex jobs
        completedBatchJobsPriorityMap = new Map<String, List<BatchJob>>();
        runningBatchJobsPriorityMap = new Map<String, List<BatchJob>>();
        failedBatchJobsPriorityMap = new Map<String, List<BatchJob>>();
        // Get the jobs info
        Map<Id,AsyncApexJob> asyncJobMap = new Map<Id,AsyncApexJob>([SELECT
                                                                        TotalJobItems,
                                                                        Status,
                                                                        NumberOfErrors,
                                                                        MethodName,
                                                                        JobType,
                                                                        JobItemsProcessed,
                                                                        ExtendedStatus,
                                                                        Id,
                                                                        CreatedDate,
                                                                        CreatedById,
                                                                        CompletedDate,
                                                                        ApexClassId,
                                                                        ApexClass.Name
                                                                    FROM
                                                                        AsyncApexJob
                                                                    WHERE
                                                                        JobType != 'ApexToken'
                                                                    AND
                                                                        Status != 'Aborted'
                                                                    ORDER BY
                                                                        CreatedDate DESC
                                                                    LIMIT 30]);
        // Query long running jobs which didnt fit in the above set (e.g. while 1 job was still running, 30 already has completed)
        asyncJobMap.putAll([SELECT
                                TotalJobItems,
                                Status,
                                NumberOfErrors,
                                MethodName,
                                JobType,
                                JobItemsProcessed,
                                ExtendedStatus,
                                Id,
                                CreatedDate,
                                CreatedById,
                                CompletedDate,
                                ApexClassId,
                                ApexClass.Name
                            FROM
                                AsyncApexJob
                            WHERE
                                Status IN :runningStatusesSet
                            ORDER BY
                                CreatedDate DESC
                            LIMIT 10]);

        // Get last 10 failed jobs
        asyncJobMap.putAll([SELECT
                                TotalJobItems,
                                Status,
                                NumberOfErrors,
                                MethodName,
                                JobType,
                                JobItemsProcessed,
                                ExtendedStatus,
                                Id,
                                CreatedDate,
                                CreatedById,
                                CompletedDate,
                                ApexClassId,
                                ApexClass.Name
                            FROM
                                AsyncApexJob
                            WHERE
                                Status = 'Failed'
                            ORDER BY
                                CreatedDate DESC
                            LIMIT 10]);

        Map<String,CustomJob__c> customJobMap = new Map<String,CustomJob__C>();
        for(CustomJob__c customJob : CustomJob__c.getall().values()) {
            customJobMap.put(customJob.Name,customJob);
        }
        // Get related WS_Log objects for each job and populate BatchJob wrapper with more information
        List<Log__c> logList = new List<Log__c>([SELECT Id, Name, CustomJobEndTime__c, CustomJobNumRecords__c, CustomJobStartTime__c, CustomJobName__c, CustomJobParentId__c FROM Log__c WHERE CustomJobParentId__c IN :asyncJobMap.keySet() ORDER BY CustomJobEndTime__c DESC]);
        Map<String,Log__c> jobIdToLogMap = new Map<String,Log__c>();
        for(Log__c log : logList) {
            jobIdToLogMap.put(log.CustomJobParentId__c,log);
        }
        // Create wrappers
        for(Id asyncJobId : asyncJobMap.keySet()) {
            BatchJob batchJob = new BatchJob(asyncJobMap.get(asyncJobId), jobIdToLogMap.get(asyncJobId) != null ? jobIdToLogMap.get(asyncJobId) : new Log__c(),customJobMap.get(asyncJobMap.get(asyncJobId).ApexClass.Name));
            // Currently running
            if(runningStatusesSet.contains(asyncJobMap.get(asyncJobId).Status)) {
                updateJobMapContent(runningBatchJobsPriorityMap,batchJob);
            // Failed
            }  else if(asyncJobMap.get(asyncJobId).Status == 'Failed') {
                updateJobMapContent(failedBatchJobsPriorityMap,batchJob);
            // Completed
            } else {
                updateJobMapContent(completedBatchJobsPriorityMap,batchJob);
            }
        }

        lastRefreshTime = System.now();

        //Component Controller
        scanJobListStatus();
    }

    public void updateJobMapContent(Map<String, List<BatchJob>> jobMap, BatchJob incJob) {
        String qPrio = incJob.jobCustomSetting.QueuePriority__c == null ? '_' : incJob.jobCustomSetting.QueuePriority__c;
        incJob.jobCustomSetting.QueuePriority__c = qPrio;
        List<BatchJob> bJobList = new List<BatchJob>();
        if(jobMap.containsKey(qPrio)) {
            bJobList = jobMap.get(qPrio);
        }
        bJobList.add(incJob);
        jobMap.put(qPrio,bJobList);
    }

    public Class BatchJob implements Comparable {
        public AsyncApexJob job {get; set;}
        public CustomJob__c jobCustomSetting {get; set;}
        public Log__c jobLog {get;set;}
        public Long jobRunningTime;
        public Long jobEnqueueTime {get; set;}
        public Util_CustomJob.CustomJobDef customJobDef;

        public BatchJob(AsyncApexJob asyncJob, Log__c log, CustomJob__c customJob) {
            this.jobCustomSetting = (customJob == null ? new CustomJob__c() : customJob);
            this.job = asyncJob;
            this.jobLog = (log == null ? new Log__c() : log);
            // Calculate running time
            if (jobLog.CustomJobEndTime__c == null && job != null && job.Status == 'Processing') jobLog.CustomJobEndTime__c = System.now();
            if(jobLog.CustomJobEndTime__c != null && jobLog.CustomJobStartTime__c != null) {
                jobRunningTime = (jobLog.CustomJobEndTime__c.getTime() - jobLog.CustomJobStartTime__c.getTime()) / (1000 * 60);
            }
            // Calculate enqueue time
            if(job != null && job.CreatedDate != null && jobLog.CustomJobStartTime__c != null) {
                jobEnqueueTime = (jobLog.CustomJobStartTime__c.getTime() - job.CreatedDate.getTime()) / (1000 * 60);
            }
        }

        public Integer compareTo(Object compareTo){
            BatchJob batchJob = (BatchJob) compareTo;
            if (getTimeOverDue() == batchJob.getTimeOverDue()) return 0;
            if (getTimeOverDue() > batchJob.getTimeOverDue()) return 1;
            return -1;
        }

        public Boolean getIsSectionPlaceHolder() {
            return jobCustomSetting.Name == PLACEHOLDER_SECTION_NAME;
        }

        public Boolean getIsSectionTitle() {
            return jobCustomSetting.Name == NORMAL_SECTION_NAME || jobCustomSetting.Name == OVERDUE_SECTION_NAME;
        }

        public String getJobName() {
            String jName = job == null || job.ApexClass == null? jobCustomSetting.Name : job.ApexClass.Name;
            if (jName == PLACEHOLDER_SECTION_NAME) jName = '&nbsp;';
            return jName;
        }

        public String getJobRunningTime() {
            return jobRunningTime == 0 ? '' : String.valueOf(jobRunningTime);
        }

        /**
         * In days/hours/minutes
         */
        public String getTimeOverDue() {
            if (customJobDef == null) return null;
            Decimal period = customJobDef.timeOverDue;
            return formatPeriod(period);
        }

         /**
         * In minutes
         */
        public Decimal getTimeOverDueMins() {
            if (customJobDef == null) return null;
            return customJobDef.timeOverDue;
        }

        /**
         * Change seconds to days/hours/minutes
         */
        private String formatPeriod(Decimal periodMins) {
            Integer days = (periodMins / (24 * 60)).intValue();
            Integer hours = ((periodMins / 60)  - (days * 24)).intValue();
            Integer mins = (periodMins - (hours * 60) - (days * 24 * 60)).intValue();
            return days + 'd ' + hours + 'h ' + mins + 'm';
        }

        /**
         * In minutes
         */
        public DateTime getNextRunDateTime() {
            if (customJobDef == null) return null;
            Long intervalSec = customJobDef.getIntervalSec(customJobDef.setting.JobFrequency__c);
            return customJobDef.setting.LastCheck__c.addSeconds(Integer.valueOf(intervalSec));
        }

        /**
         * Time overdue per custom job, color coding the job line as follows
         * - GREEN: not overdue
         * - YELLOW: 0 - 2 min overdue
         * - ORANGE: 2-15 min overdue
         * - RED: > 15 min overdue
         * @return String, className
         */
        public String getStateOverdueClass() {
            String color = '';
            Decimal timeGape = getTimeOverDueMins();//Amount in minutes
            if ( timeGape == null) return color;
            if (timeGape <= 0) {
                color = 'state-overdue-normal';
            } else if (timeGape <= 2) {
                color = 'state-overdue-low';
            } else if (timeGape <= 15) {
                color = 'state-overdue-medium';
            } else {
                color = 'state-overdue-high';
            }
            return color;
        }

        /**
         * Job size (number of records processed/processing, number of batches, etc)
         * @return Decimal, number of records processed
         */
        public Decimal getRecNumberTotal() {
            if (customJobDef == null) return null;
            return customJobDef.setting.LastRunNumRecords__c.setScale(0);
        }

        /**
         * Job size (number of records processed/processing, number of batches, etc)
         * @return Decimal, number of records total
         */
        public Decimal getRecNumberProcessed() {
            if (customJobDef == null || job == null || job.TotalJobItems == 0) return 0;
            Decimal totalBatch = job.TotalJobItems == null ? 0 : job.TotalJobItems;
            Decimal numProcessed = 0;
            if (job.JobItemsProcessed == totalBatch) {
                //Last batch will take LastRunNumRecords
                numProcessed = ((totalBatch - 1) * customJobDef.setting.BatchSize__c) + customJobDef.setting.LastRunNumRecords__c;
            } else if (job.JobItemsProcessed != null) {
                numProcessed = job.JobItemsProcessed * customJobDef.setting.BatchSize__c;
            }
            return numProcessed.setScale(0);
        }

        public String getNotRunStatus() {
            if (jobCustomSetting.Name == NORMAL_SECTION_NAME || jobCustomSetting.Name == OVERDUE_SECTION_NAME) return '';
            return 'Not Running';
        }
    }

    /**
     * CD-1357: Batchmonitor simplified status screen
     * @lastModifiedBy: CPN
     * @lastModifiedDate: 28-Nov-2016
     * @ref: BatchMonitor.page, BatchMonitorJobStatus.component
     */
    private void scanJobListStatus() {
        anyBatchJobsPriorityMap = new Map<String, List<BatchJob>>();
        Map<String, Util_CustomJob.CustomJobDef> customJobDefByName = mapCustomJobDefByName(Util_CustomJob.loadJobsFromSettings());
        Set<String> runningJobs = new Set<String>();
        convertPriorityJobsToAnyJobs(runningBatchJobsPriorityMap, runningJobs, customJobDefByName);
        convertPriorityJobsToAnyJobs(completedBatchJobsPriorityMap, runningJobs, customJobDefByName);
        for (String jobKey : customJobDefByName.keySet()) {
            if (runningJobs.contains(jobKey)) continue;
            Util_CustomJob.CustomJobDef customJobDef = customJobDefByName.get(jobKey);
            BatchJob jobItem = new BatchJob(new AsyncApexJob(), new Log__c(), customJobDef.setting);
            jobItem.customJobDef = customJobDef;
            updateJobMapContent(anyBatchJobsPriorityMap, jobItem);
        }
        Map<String, BatchJob> anyBatchJobsList = new Map<String, BatchJob>();
        for (String jobKey : anyBatchJobsPriorityMap.keySet()) {
            for (BatchJob jobItem : anyBatchJobsPriorityMap.get(jobKey)) {
                String jobName = jobItem.job.ApexClass == null ? jobItem.jobCustomSetting.Name : jobItem.job.ApexClass.Name;
                if (anyBatchJobsList.containsKey(jobName) || !customJobDefByName.containsKey(jobName)) continue;
                anyBatchJobsList.put(jobName, jobItem);
            }
        }
        anyBatchJobsPriorityList = anyBatchJobsList.values();
        checkAlert(anyBatchJobsPriorityList);
        reverseSortedItems();
    }

    private void convertPriorityJobsToAnyJobs(Map<String, List<BatchJob>> priorityMap, Set<String> runningJobs, Map<String, Util_CustomJob.CustomJobDef> customJobDefByName) {
        String excldJob = 'SCH_CustomJobDispatcher';
        for (String jobKey : priorityMap.keySet()) {
            for (BatchJob jobItem : priorityMap.get(jobKey)) {
                String jobName = jobItem.job.ApexClass.Name != null ? jobItem.job.ApexClass.Name : jobItem.jobCustomSetting.Name;
                if (runningJobs.contains(jobName)) continue;
                jobItem.customJobDef = customJobDefByName.get(jobName);
                runningJobs.add(jobName);
                if (excldJob != jobItem.jobCustomSetting.Name && excldJob != jobItem.job.ApexClass.Name) {
                    updateJobMapContent(anyBatchJobsPriorityMap, jobItem);
                }
            }
        }
    }

    private void reverseSortedItems() {
        anyBatchJobsPriorityList.sort();
        List<BatchJob> overduedList = new List<BatchJob>();
        List<BatchJob> normalList = new List<BatchJob>();
        for (Integer i = anyBatchJobsPriorityList.size() - 1 ; i >= 0; i--) {
            BatchJob bJob = anyBatchJobsPriorityList[i];
            if (bJob.getTimeOverDueMins() > 0) overduedList.add(bJob);
            else normalList.add(bJob);
        }
        prefillSection(overduedList, OVERDUE_SECTION_NAME);
        prefillSection(normalList, NORMAL_SECTION_NAME);
        anyBatchJobsPriorityList = new List<BatchJob>();
        anyBatchJobsPriorityList.addAll(overduedList);
        anyBatchJobsPriorityList.addAll(normalList);
    }

    private void prefillSection(List<BatchJob> srclist, String sectionName) {
        for (Integer i = srclist.size(); i < PLACEHOLDER_ROWS; i++) {
            srclist.add(new BatchJob(null, new Log__c(), new CustomJob__c(Name = PLACEHOLDER_SECTION_NAME)));
        }
        srclist.add(0, new BatchJob(null, new Log__c(), new CustomJob__c(Name = sectionName)));
    }

    private void checkAlert(List<BatchJob> allJobs) {
        Set<String> sAlertStatuses = new Set<String>{'state-overdue-medium', 'state-overdue-high'};
        showAlert = false;
        for (BatchJob b : allJobs) {
            if (!sAlertStatuses.contains(b.getStateOverdueClass())) continue;
            showAlert = true;
            return;
        }
    }

    private Map<String, Util_CustomJob.CustomJobDef> mapCustomJobDefByName(Map<String, Util_CustomJob.CustomJobDef> mCusJobDef) {
        Map<String, Util_CustomJob.CustomJobDef> mCustomJobDef = new Map<String, Util_CustomJob.CustomJobDef>();
        List<Util_CustomJob.CustomJobDef> lCustomJobDef = mCusJobDef.values();
        lCustomJobDef.sort();
        for (Util_CustomJob.CustomJobDef jobItem : lCustomJobDef)  {
            mCustomJobDef.put(jobItem.setting.Name, jobItem);
        }
        return mCustomJobDef;
    }
}