@isTest
private class TST_UTIL {
    // Testing UTIL classes...

	@isTest static void testLogging() {
		UTIL.log('Writing something to log...');
        UTIL.log(UTIL.currentOrg); // log an object
		UTIL.logRaw('And some Raw logging...');
		UTIL.logLimits();
        UTIL.logLimits('This logs the limits...');
        UTIL.logErrors(UTIL.limitRow());
        try {
            UTIL.throwError('My Error message') ;
        } catch (Exception e) {
            //Assert Error Message
            System.assert( e.getMessage().contains('My Error message'));
        }
	}

   	@isTest static void testSandboxCheck() {
		Organization currentOrg = [select Id, IsSandbox, InstanceName from Organization];
        System.assertEquals(UTIL.isSandbox(),currentOrg.IsSandbox);
	}

    // TODO: test caching

	// UTIL_RecordType
	@isTest static void testRecordType() {
		List<RecordType> recordTypes 		= [SELECT Id, Name, DeveloperName, SObjectType, IsActive FROM RecordType WHERE IsActive=true LIMIT 10000];
		if (recordTypes == null ) { // no active rec.types in org
			RecordType rt = UTIL_RecordType.getRecordTypeByName('Account','recTypeName');
			System.assertEquals(null, rt);

		} else {
			RecordType rt = recordTypes[0];
			RecordType rtRes = UTIL_RecordType.getRecordTypeByName(rt.SobjectType,rt.DeveloperName);
			System.assertEquals(rt.Id, rtRes.Id);
		}
	}

    // Test Custom Logs

    @isTest static void testCustomLogs(){

        UTIL.customLog('WARN', 'CustomLog TestClass', 'TST_UTIL', NULL);

        for(Log__c  Log: UTIL.customLogsList){
            System.AssertEquals(Log.level__c, 'WARN');
        }

        UTIL.customLog('WARN', 'CustomLog TestClass', 'TST_UTIL', NULL, false);
        UTIL.insertCustomLogs();

    }

}