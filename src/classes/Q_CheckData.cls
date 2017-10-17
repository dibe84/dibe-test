global class Q_CheckData implements Schedulable, Database.AllowsCallouts {

	private static Integer CELL_WIDTH = 30;

	global static void start() {
		Datetime sysTime = System.now().addSeconds(30);
        String cron = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        Q_CheckData qcd = new Q_CheckData();
		System.schedule('Q_CheckData Scheduled Execution ' + String.valueOf(sysTime.getTime()), cron, qcd);
	}

	public static void stop() {
		List<CronTrigger> pendingJobs = [	SELECT	Id,
													CronJobDetail.Name
											FROM	CronTrigger
											WHERE	CronJobDetail.Name
											LIKE	'Q_CheckData Scheduled Execution%'];

		for(CronTrigger ct : pendingJobs) {
			System.abortJob(ct.Id);
		}
	}

    public void execute(SchedulableContext sc) {
		UTIL_Log.start();
		Map<String,String> outputInfoMap = new Map<String,String>();
		/*String objInfo = '```';
		objInfo += getOutOfSyncStatus();
		objInfo += getExceptionsStatus();
		objInfo += '```';
		outputInfoMap.put('objInfo',objInfo);*/

		String jobInfo = '```';
		jobInfo += evaluateJobStatus();
		jobInfo += '```';
		outputInfoMap.put('jobInfo',jobInfo);

		rescheduleMe();
	}

	private static String getExceptionsStatus() {
		String retMsg = '## Opportunity Exceptions ##\n';
		List<Opportunity> oppList = (List<Opportunity>) GW_sObject.queryRecords('Opportunity','DiscoveredExceptions__c != NULL');
		for(Opportunity opp : oppList) {
			retMsg += appendFixedLength('OppName: ' + opp.Name,40);
			retMsg += appendFixedLength('|| Id: ' + opp.Id);
			retMsg += appendFixedLength('|| Ex: ' + opp.DiscoveredExceptions__c);
			retMsg += '\n';
		}
		return retMsg;
	}

	private static void rescheduleMe() {
		stop();
		start();
	}

	private Map<String,CustomJob__c> getOverdueJobs(Map<String,CustomJob__c> csJobMap) {
		Map<String,CustomJob__c> overdueJobsMap = new Map<String,CustomJob__c>();
		Set<Id> lastRunIdSet = new Set<Id>();

		for(CustomJob__c csJob : csJobMap.values()) {
			lastRunIdSet.add(csJob.JobIdLastRun__c);
		}

		Map<Id,AsyncApexJob> asyncApexJobMap = new Map<Id,AsyncApexJob>((List<AsyncApexJob>) GW_sObject.queryRecords('AsyncApexJob',lastRunIdSet));
		for(CustomJob__c csJob : csJobMap.values()) {
			if(!asyncApexJobMap.containsKey(csJob.JobIdLastRun__c)) continue;
			if(asyncApexJobMap.get(csJob.JobIdLastRun__c).CompletedDate == NULL) continue;

			Integer timeSinceLastRun = getElapsedMinutes(csJob.LastRun__c,asyncApexJobMap.get(csJob.JobIdLastRun__c).CompletedDate);
			if(Math.abs(timeSinceLastRun) > 80) { // Last run in CS vs last run in ApexAsync table (min)
				overdueJobsMap.put(csJob.Name,csJob);
			}
			Integer timeSinceLastCheck = getElapsedMinutes(csJob.LastCheck__c,asyncApexJobMap.get(csJob.JobIdLastRun__c).CompletedDate);
			if(Math.abs(timeSinceLastCheck) > 120) { // Last check in CS vs last run in ApexAsync table (min)
				overdueJobsMap.put(csJob.Name,csJob);
			}
			Integer timeSinceLastRunVsNow = getElapsedMinutes(csJob.LastRun__c,System.now());
			if(Math.abs(timeSinceLastRunVsNow) > 120) { // Didnt run for the past 2 hours
				overdueJobsMap.put(csJob.Name,csJob);
			}
		}

		return overdueJobsMap;
	}

	private Map<String,CustomJob__c> getStuckJobs(Map<String,CustomJob__c> csJobMap) {
		Set<String> runningStatusesSet = new Set<String>();
		runningStatusesSet.add('Queued');
		runningStatusesSet.add('Processing');
		runningStatusesSet.add('Holding');
		Map<String,CustomJob__c> stuckJobsMap = new Map<String,CustomJob__c>();
		Set<Id> lastRunIdSet = new Set<Id>();

		for(CustomJob__c csJob : csJobMap.values()) {
			lastRunIdSet.add(csJob.JobIdLastRun__c);
		}

		Map<Id,AsyncApexJob> asyncApexJobMap = new Map<Id,AsyncApexJob>((List<AsyncApexJob>) GW_sObject.queryRecords('AsyncApexJob',lastRunIdSet));
		for(CustomJob__c csJob : csJobMap.values()) {
			if(!asyncApexJobMap.containsKey(csJob.JobIdLastRun__c)) {
				stuckJobsMap.put(csJob.Name,csJob);
				continue;
			}
			if(asyncApexJobMap.get(csJob.JobIdLastRun__c).CompletedDate == NULL) {
				stuckJobsMap.put(csJob.Name,csJob);
			}
			if(csJob.isRunning__c == TRUE && !runningStatusesSet.contains(asyncApexJobMap.get(csJob.JobIdLastRun__c).Status)) {
				stuckJobsMap.put(csJob.Name,csJob);
			}
		}

		return stuckJobsMap;
	}

	private String getDispatcherSummary() {
		List<CronTrigger> dispatcherJobs = [	SELECT	Id,
														CronJobDetail.Name,
														CronJobDetail.JobType,
														NextFireTime,
														StartTime,
														CreatedDate,
														CronExpression,
														EndTime
												FROM	CronTrigger
												WHERE	CronJobDetail.Name
												LIKE	'%SCH_CustomJobDispatcher%'];
		String retMsg = '## SCH_CustomJobDispatcher ##\n';
		for(CronTrigger ct : dispatcherJobs) {
			retMsg += appendFixedLength(ct.CronJobDetail.Name.left(CELL_WIDTH));
			retMsg += appendFixedLength('|| NFire: ' + (ct.NextFireTime == null ? '-' : ct.NextFireTime.format('dd/MM/yy HH:mm:ss')));
			retMsg += appendFixedLength('|| STime: ' + (ct.StartTime == null ? '-' : ct.StartTime.format('dd/MM/yy HH:mm:ss')));
			retMsg += appendFixedLength('|| CrDate: ' + (ct.CreatedDate == null ? '-' : ct.CreatedDate.format('dd/MM/yy HH:mm:ss')));
			retMsg += '\n';
		}
		return retMsg;
	}

	private String evaluateJobStatus() {
		Map<String,CustomJob__c> csJobMap = new Map<String,CustomJob__c>();
		for (UTIL_CustomJob.CustomJobDef jobDef : UTIL_CustomJob.loadJobsFromSettings().values()) {
			csJobMap.put(jobDef.setting.Name,jobDef.setting);
		}

		Map<String,CustomJob__c> overdueJobsMap = getOverdueJobs(csJobMap);
		Map<String,CustomJob__c> stuckJobsMap = getStuckJobs(csJobMap);

		String retMsg = buildJobsOverviewMessage('OVERDUE', overdueJobsMap);
		retMsg += buildJobsOverviewMessage('STUCK',stuckJobsMap);
		retMsg += getDispatcherSummary();
		return retMsg;
	}

	private String buildJobsOverviewMessage(String sectionTitle, Map<String, CustomJob__c> wrongJobsMap) {
		String errorMsg = '## ' + sectionTitle + ' ##\n';
		for(CustomJob__c jobDef : wrongJobsMap.values()) {
			errorMsg += appendFixedLength(jobDef.Name);
			errorMsg += appendFixedLength('|| Lrun: ' + jobDef.LastRun__c.format('dd/MM/yy HH:mm:ss'));
			errorMsg += appendFixedLength('|| Lcheck: ' + jobDef.LastCheck__c.format('dd/MM/yy HH:mm:ss'));
			errorMsg += appendFixedLength('|| Since Lrun[min]: ' + getElapsedMinutes(jobDef.LastRun__c,System.now()));
			errorMsg += appendFixedLength('|| Since Lcheck[min]: ' + getElapsedMinutes(jobDef.LastCheck__c,System.now()));
			errorMsg += '\n';
		}

		return errorMsg;
	}

	private static String appendFixedLength(String newContent) {
		return appendFixedLength(newContent, CELL_WIDTH);
	}

	private static String appendFixedLength(String newContent, Integer desiredLength) {
		for(Integer i = newContent.length(); i < desiredLength; i++) {
			newContent += ' ';
		}
		return newContent;
	}

	public static Integer getElapsedMinutes(DateTime startD, DateTime endD) {
		Time startTime = startD.time();
		Time endTime = endD.time();
	    if(startTime == null || endTime == null)
	        return -1;

		Integer dayDifference = startD.date().daysBetween(endD.date());
		if(dayDifference > 1) {
			return dayDifference * 24 * 60;
		}
	    Integer elapsedHours = endTime.hour() - startTime.hour();
	    Integer elapsedMinutes = endTime.minute() - startTime.minute();
	    Integer elapsedSeconds = endTime.second() - startTime.second();
	    Integer elapsedMiliseconds = endTime.millisecond() - startTime.millisecond();

	    return elapsedMinutes;
	}

	private String getOutOfSyncStatus() {
		String output = '## Out of sync ##\n';
		try {
			Integer revExtPending = (Integer) [Select COUNT(Id) q FROM Rev__c Where ExtensionPending__c = TRUE][0].get('q');
			Integer invoicesOOS = (Integer) [Select COUNT(Id) q FROM Invoice__c Where OutOfSync__c = TRUE][0].get('q');
			Integer invLineOOS = (Integer) [Select COUNT(Id) q FROM InvoiceLine__c Where OutOfSync__c = TRUE][0].get('q');
			Integer oppOOS = (Integer) [Select COUNT(Id) q FROM Opportunity Where OutOfSync__c = TRUE][0].get('q');
			Integer oliOOS = (Integer) [Select COUNT(Id) q FROM OpportunityLineItem Where OutOfSync__c = TRUE][0].get('q');
			Integer revOOS = (Integer) [Select COUNT(Id) q FROM Rev__c Where OutOfSync__c = TRUE][0].get('q');
			Integer rssOOS = (Integer) [Select COUNT(Id) q FROM RS__c Where OutOfSync__c = TRUE][0].get('q');

			output += (revExtPending > 0 ? (revExtPending + ' Revenue Items Pending extension\n') : '');
			output += (oppOOS > 0 ? (oppOOS + ' Opportunities Out of Sync\n') : '');
			output += (oliOOS > 0 ? (oliOOS + ' Opportunity Line Items Out of Sync\n') : '');
			output += (invoicesOOS > 0 ? (invoicesOOS + ' Invoices Out of Sync\n') : '');
			output += (invLineOOS > 0 ? (invLineOOS + ' InvoiceLines Out of Sync\n') : '');
			output += (revOOS > 0 ? (revOOS + ' Revenue Items Out of Sync\n') : '');
			output += (rssOOS > 0 ? (rssOOS + ' Revenue Schedules Out of Sync\n') : '');
		} catch(Exception ex) {
			UTIL.throwError('Q_CheckData:getOutOfSyncStatus: ',ex);
			return 'EXCEPTION WHEN GETTING STATISTICS: ' + ex.getStackTraceString();
		}
		return output;
	}
}