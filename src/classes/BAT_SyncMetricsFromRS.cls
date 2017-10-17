global class BAT_SyncMetricsFromRS implements Database.Batchable<sObject>, UTIL_CustomJob.ICustomJob, Database.Stateful {

	global Datetime executeStart;
	String queryString;
    List<RS__c> rsInput;

    global BAT_SyncMetricsFromRS() {
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_SyncMetricsFromRS');
        queryString = UTIL_CustomJob.getWhereQuery(jobDef);
        this.numRecords = Database.countQuery(UTIL_CustomJob.getCountQuery(jobDef,'RS__c'));
        if (this.numRecords>0) readyForRun = true;
    }
    global BAT_SyncMetricsFromRS(Set<Id> rsIds) {
        this.rsInput = [Select id, from_Date__c, until_Date__c, Opportunity__c, CurrencyIsoCode, Rev__c from RS__c where id in :rsIds];
    }

    global List<RS__c> start(Database.BatchableContext BC) {
		if (rsInput == null){
        	rsInput = GW_sObject.queryRecords('RS__c', this.queryString);
        	return rsInput;
        }
        else{
            return rsInput;
        }
    }

    global void execute(Database.BatchableContext BC, List<RS__c> scope) {
        if(this.executeStart == null) this.executeStart = Datetime.now();
        Map<String, Metric__c> 	metricsToUpsert = new Map<String, Metric__c>();
    	List<Metric__c> 		metricsToDelete = new List<Metric__c>();
        List<RS__c> 			rssToUpdate = new List<RS__c>();

        // cache related objects
        UTIL.cache( GW_Revenue.getMapFromRelated( scope ));
        UTIL.cache( GW_Opportunity.getMapFromRelated( scope ));

    	for (RS__c rs : scope) {
    		for (Metric__c m : GW_Metric.createAllMetricsFromRS(rs) ) {
    			metricsToUpsert.put(m.ExternalUID__c,m);
    		}
            rssToUpdate.add(new RS__c(id=rs.Id,SyncMetrics__c=false));
    	}

    	for (Metric__c m : GW_Metric.getExistingMetrics(scope) ) {
    		if ( !metricsToUpsert.containsKey(m.ExternalUID__c) ) metricsToDelete.add(m);
            else {
                m.RS__c = metricsToUpsert.get(m.ExternalUID__c).RS__c;
                metricsToUpsert.put(m.ExternalUID__c, m);
            }
    	}

        if (metricsToDelete.size()>0 ) {
	    	try {
	    		delete metricsToDelete;
	    	} catch(Exception ex) {
	    		UTIL.throwError('Error deleting Metrics',ex );
	   		}
	   	}

    	if (metricsToUpsert.values().size()>0 ) {
	    	try {
	    		upsert metricsToUpsert.values() ExternalUID__c;
	    	} catch(Exception ex) {
	    		UTIL.throwError('Error syncing Metrics',ex );
	   		}
	   	}

        if (rssToUpdate.size()>0 ) {
	    	try {
	    		update rssToUpdate;
	    	} catch(Exception ex) {
	    		UTIL.throwError('Error updating RSs',ex );
	   		}
	   	}
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_SyncMetricsFromRS', BC.getJobId());
    }

    // UTIL_CustomJob.ICustomJob interface implementation
    private Boolean readyForRun = false;
    private Integer numRecords = -1;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}