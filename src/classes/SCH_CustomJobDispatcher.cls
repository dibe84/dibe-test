global class SCH_CustomJobDispatcher implements Schedulable, Database.AllowsCallouts {

    global void execute(SchedulableContext sc) {
        UTIL_CustomJob.removeExistingCustomJobs();
        UTIL_CustomJob.checkIsRunningStatusForJobs();

        Map<String,List<Util_CustomJob.CustomJobDef>> overdueJobsPriorityMap = UTIL_CustomJob.getOverDueJobsMap(); // <-- already sorted
        // Proceed with lauch for each of the custom job list for each priority queue
        for(String priority : overdueJobsPriorityMap.keySet()) {
            for (UTIL_CustomJob.CustomJobDef jobDef : overdueJobsPriorityMap.get(priority)) {
                UTIL_CustomJob.ICustomJob jobInstance = jobDef.instantiateClass();
                if (jobInstance == null)
                    UTIL.throwError('Cannot instantiate: '+jobDef.setting.Name);
                if (jobInstance.readyForRun()) {
                    UTIL.log('Launching job: ' + jobDef.setting.Name);
                    jobDef.execute(jobInstance);
                    break;
                } else { // No processing needed for this job, update jobDefinition and try next
                    jobDef.updateLastCheckTimeStamp();
                }
            }
        }
        SCH_CustomJobDispatcher.start();
    }
    
    // Calling this function will schedule this scheduler to be started each hour, as a fallback mechanism 
    global static void schedule(){ 
        if (!Test.IsRunningTest() ) {
            System.schedule('SCH_CustomJobDispatcher_Scheduled_Fallback00', '0 0 * * * ?', new SCH_CustomJobDispatcher());
            System.schedule('SCH_CustomJobDispatcher_Scheduled_Fallback10', '0 10 * * * ?', new SCH_CustomJobDispatcher());
            System.schedule('SCH_CustomJobDispatcher_Scheduled_Fallback20', '0 20 * * * ?', new SCH_CustomJobDispatcher());
            System.schedule('SCH_CustomJobDispatcher_Scheduled_Fallback30', '0 30 * * * ?', new SCH_CustomJobDispatcher());
            System.schedule('SCH_CustomJobDispatcher_Scheduled_Fallback40', '0 40 * * * ?', new SCH_CustomJobDispatcher());
            System.schedule('SCH_CustomJobDispatcher_Scheduled_Fallback50', '0 50 * * * ?', new SCH_CustomJobDispatcher());
        } else                        
            system.schedule('SCH_CustomJobDispatcher TEST Scheduled Execution', '0 0 * * * ?', new SCH_CustomJobDispatcher()); // running test
    }
    
    global static void abortAll() {
        List<CronTrigger> runningJobs = [ SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SCH_CustomJobDispatcher%'];
        if (runningJobs.size() > 1) {
            for(CronTrigger ct : runningJobs) {
                System.abortJob(ct.Id);
            }
        }
        // Do check again, since 1 could have been in progress in latest check
        runningJobs = [ SELECT Id FROM CronTrigger WHERE CronJobDetail.Name LIKE 'SCH_CustomJobDispatcher%'];
        if (runningJobs.size() > 1) {
            for(CronTrigger ct : runningJobs) {
                System.abortJob(ct.Id);
            }
        }
    }
    
    global static void restart() {
        SCH_CustomJobDispatcher.abortAll();
        SCH_CustomJobDispatcher.schedule();
        SCH_CustomJobDispatcher.start();
    }

    // Calling this function will schedule the execute() method of this scheduler to be executed
    global static void start() {  
		// If the Scheduler is already running then there is no point in scheduling it again....
		List<CronTrigger> pendingJobs = [	SELECT	Id, 
													CronJobDetail.Name,
													CronJobDetail.JobType,
													NextFireTime, 
													StartTime, 
													CreatedDate,
													CronExpression,
													EndTime,
													OwnerId,
													PreviousFireTime,
													State,
													TimesTriggered
											FROM	CronTrigger	
											WHERE	CronJobDetail.Name 
											LIKE	'SCH_CustomJobDispatcher Chained Execution%'];
		
		if (pendingJobs.size() > 1) {
			for(CronTrigger ct : pendingJobs) {
				// If job is over 5 minutes in scheduler, it should be aborted
				if(((System.now().getTime() - ct.CreatedDate.getTime())/1000/60) > 5) {
					String errorEmailBody = 'Aborted job detailed information: \n';
					errorEmailBody += buildOverdueErrorMessage(ct);
					UTIL_Email.sendSystemAlertFromFuture('SCH_CustomJobDispatcher aborted due to timeout',errorEmailBody,'');
					System.abortJob(ct.Id);
				}
			}
			return;
		}

        Datetime sysTime = System.now().addSeconds(3);
        String cron = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        SCH_CustomJobDispatcher s = new SCH_CustomJobDispatcher();

        String jobID;
        if (!Test.IsRunningTest()) {
            jobID = system.schedule('SCH_CustomJobDispatcher Chained Execution' + String.valueOf(sysTime.getTime()), cron, s);
        } else {
        	jobID = system.schedule('SCH_CustomJobDispatcher TEST Chained Execution' + String.valueOf(sysTime.getTime()), cron, s); // running test
        }
    }

	private static String buildOverdueErrorMessage(CronTrigger ctJob) {
		String ctJobMsg = '';
		ctJobMsg += 'Job Id: ' + ctJob.Id + '\n';
		ctJobMsg += 'CronJobDetail.Name: ' + ctJob.CronJobDetail.Name + '\n';
		ctJobMsg += 'CronJobDetail.JobType: ' + ctJob.CronJobDetail.JobType + '\n';
		ctJobMsg += 'NextFireTime: ' + ctJob.NextFireTime + '\n';
		ctJobMsg += 'StartTime: ' + ctJob.StartTime + '\n';
		ctJobMsg += 'EndTime: ' + ctJob.EndTime + '\n';
		ctJobMsg += 'CreatedDate: ' + ctJob.CreatedDate + '\n';
		ctJobMsg += 'CronExpression: ' + ctJob.CronExpression + '\n';
		ctJobMsg += 'OwnerId: ' + ctJob.OwnerId + '\n';
		ctJobMsg += 'PreviousFireTime: ' + ctJob.PreviousFireTime + '\n';
		ctJobMsg += 'State:' + ctJob.State + '\n';
		ctJobMsg += 'TimesTriggered:' + ctJob.TimesTriggered + '\n';

		return ctJobMsg;
	}
}