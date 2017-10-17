@isTest(SeeAllData=TRUE)
private class TST_PGC_BatchMonitor {

	@isTest static void testBatchMonitor() {
	    Test.startTest();
		PGC_BatchMonitor uBM = new PGC_BatchMonitor();
		uBM.anyBatchJobsPriorityList[0].getNotRunStatus();
		uBM.anyBatchJobsPriorityList[0].getRecNumberProcessed();
		uBM.anyBatchJobsPriorityList[0].getRecNumberTotal();
		uBM.anyBatchJobsPriorityList[0].getNextRunDateTime();
		uBM.anyBatchJobsPriorityList[0].getIsSectionPlaceHolder();
		uBM.anyBatchJobsPriorityList[0].getIsSectionTitle();
		uBM.anyBatchJobsPriorityList[0].getJobName();
		uBM.anyBatchJobsPriorityList[0].getJobRunningTime();
		// Test job statuses container
		System.assertNotEquals(NULL, uBM.runningStatusesSet);
		System.assertNotEquals(NULL, uBM.completedBatchJobsPriorityMap);
		System.assertNotEquals(NULL, uBM.runningBatchJobsPriorityMap);
		System.assertNotEquals(NULL, uBM.lastRefreshTime);
		System.assertNotEquals(NULL, uBM.anyBatchJobsPriorityMap);
		System.assertNotEquals(NULL, uBM.anyBatchJobsPriorityList);
		Test.stopTest();
	}
}