public class UTIL_WSC_Bulk {

    // Objects to be committed @end of execution context, handled by the commitAll() method
    public List<sObject>                    objectsToBeUpdated;
    public List<sObject>                    objectsToBeInserted;
    public List<WS_Log__c>                  logsToBeUpdated;
    public Map<WS_Log__c,List<attachment>>  logsAndAttachmentsToBeInserted;
    public Map<Id,Map<String,WS_Log__c>>    latestSuccessfulProcessedLogMap; // Context Record Id => Map<CalloutName, WS_Log record>
    private Map<String,Set<Id>>             contextRecordIdsPerType;
    private static Map<Set<Id>, List<sObject>> contextRecordCache = new Map<Set<Id>, List<sObject>>();
    private static Map<Set<Id>, List<WS_Log__c>> logCache = new Map<Set<Id>, List<WS_Log__c>>();
    public List<WS_ScheduledCallout__c>     wsscToUpsert;

    public UTIL_WSC_Bulk(Set<Id> contextRecordIds) {
        this(contextRecordIds, false);
    }

    public UTIL_WSC_Bulk(Set<Id> contextRecordIds, Boolean useCache) {
        this.objectsToBeInserted = new list<sObject>();
        this.objectsToBeUpdated = new list<sObject>();
        this.logsToBeUpdated = new List<WS_Log__c>();
        this.logsAndAttachmentsToBeInserted = new Map<WS_Log__c,List<attachment>>();
        this.latestSuccessfulProcessedLogMap = new Map<Id,Map<String,WS_Log__c>>();
        this.contextRecordIdsPerType = new map<String,Set<Id>>();
        this.wsscToUpsert = new List<WS_ScheduledCallout__c>();

        // for each contextRecordId
        for (Id soId : contextRecordIds) {
            String objectType = GW_sObject.getobjectNameFromId(soId);
            if (contextRecordIdsPerType.get(objectType) == null ) contextRecordIdsPerType.put(objectType,new Set<Id>() );
            contextRecordIdsPerType.get(objectType).add(soId);
            latestSuccessfulProcessedLogMap.put(soId, new Map<String,WS_Log__c>());
        }

        // per type query sObjects and add to cache
        for (String objectType : contextRecordIdsPerType.keySet() ) {
            Set<Id> objectIds = contextRecordIdsPerType.get(objectType);
            if (useCache && contextRecordCache.get(objectIds) != null) {

            } else {
                List<sObject> contextRecordsOfThisType = GW_sObject.queryRecords(objectType, objectIds);
                UTIL.cache(contextRecordsOfThisType);
                contextRecordCache.put(objectIds, contextRecordsOfThisType);
            }
        }

        // get all latest processed log records
        if (useCache && logCache.get(contextRecordIds) != null) {
            for (WS_Log__c log : logCache.get(contextRecordIds)) {
                this.latestSuccessfulProcessedLogMap.get(log.ParentId__c).put(log.CalloutName__c,log);
            }
        } else {
            List<WS_Log__c> latestLogs = [Select Id, ParentId__c, RelevantChangesCompareString__c, CalloutName__c From WS_Log__c Where ParentId__c IN :contextRecordIds AND IsLatestSuccessfullyFor__c <> null];
            for (WS_Log__c log : latestLogs) {
                this.latestSuccessfulProcessedLogMap.get(log.ParentId__c).put(log.CalloutName__c,log);
            }
            logCache.put(contextRecordIds, latestLogs);
        }

    }

    public void commitAll() {
        try {
	        if ( !this.objectsToBeInserted.isEmpty() )              GW_sObject.upsertSeparately(this.objectsToBeInserted);
	
	        if ( !this.logsToBeUpdated.isEmpty() ) {
	            Map<Id, WS_Log__c> mlogs = new Map<Id, WS_Log__c>();
	            for (WS_Log__c l : this.logsToBeUpdated) {
	                mlogs.put(l.Id, l);
	            }
	            this.logsToBeUpdated = mlogs.values();
	            update this.logsToBeUpdated;
	        }
	
	        if ( !this.logsAndAttachmentsToBeInserted.isEmpty() ) {
	            Map<String, WS_Log__c> tmpLogs = new Map<String, WS_Log__c>();
	            Map<String, List<Attachment>> attMap = new Map<String, List<Attachment>>();
	
	            for (WS_Log__c l : this.logsAndAttachmentsToBeInserted.keySet()) {
	                tmpLogs.put(l.IsLatestSuccessfullyFor__c, l);
	                attMap.put(l.IsLatestSuccessfullyFor__c, this.logsAndAttachmentsToBeInserted.get(l));
	            }
	            insert tmpLogs.values();
	            
	            Map<WS_Log__c, List<Attachment>> newLogAttMap = new Map<WS_Log__c, List<Attachment>>();
	            for (WS_Log__c l : tmpLogs.values()) {
	                newLogAttMap.put(l, attMap.get(l.IsLatestSuccessfullyFor__c));
	            }
	            this.logsAndAttachmentsToBeInserted = newLogAttMap;
	        }
	        
	        if ( !this.objectsToBeUpdated.isEmpty() ) {
	            //UTIL.log(this.objectsToBeUpdated);
	            Database.UpsertResult[] res = GW_sObject.upsertSeparately(this.objectsToBeUpdated); // update after log insertion
	            //UTIL.log( 'id: '+res[0].getId() +' | Errors: '+ res[0].getErrors() );
	            
	            Map<Id, String> mapContextRecordErrors = new Map<Id,String>();
	            
	            for (Integer i = 0; i< res.size(); i++) {
	                if (!res[i].success) {
	                    String errorMsg;
	                    for(Database.Error err : res[i].getErrors() ) {
	                        errorMsg = 'Error saving the context record after processing response:\n';                    
	                        errorMsg += err.getStatusCode() + ': ' + err.getMessage()+ '\n';
	                        errorMsg += 'Fields: ' + err.getFields();
	                    }
	                    mapContextRecordErrors.put(this.ObjectsToBeUpdated[i].Id,errorMsg);
	                }
	            }
	            
	            if (mapContextRecordErrors.size() >0) {
	                Map<Id, WS_Log__c> mapContextRec2Log = new Map<Id,WS_Log__c>();
	                for (WS_Log__c log : this.logsAndAttachmentsToBeInserted.keySet() ) {
	                    mapContextRec2Log.put(log.ParentId__c, log);    
	                }
	                
	                for (Id recId : mapContextRecordErrors.keyset() ) {
	                    if (mapContextRec2Log.get(recId) != null) mapContextRec2Log.get(recId).Error__c = mapContextRecordErrors.get(recId);
	                }
	                update mapContextRec2Log.values();
	            }  
	        }
	        
	        Map<WS_Log__c,List<attachment>> newMap = new Map<WS_Log__c,List<attachment>>(logsAndAttachmentsToBeInserted);
	        List<Attachment> attachmentsToBeInserted = new List<Attachment>();
	
	        if (this.logsAndAttachmentsToBeInserted!=null) {
	            for (WS_Log__c log : newMap.keySet() ) {
	                if (newMap.containsKey(log) && newMap.get(log) != null ) {
	                    for (Attachment att: newMap.get(log) ) {
	                        att.ParentId = log.Id;
	                        attachmentsToBeInserted.add(att); 
	                    }
	                }
	            }
	            if ( attachmentsToBeInserted!=null && !attachmentsToBeInserted.isEmpty() )  insert attachmentsToBeInserted;
	        }
	
	        if ( !this.wsscToUpsert.isEmpty() ) upsert this.wsscToUpsert UniqueKey__c ;
        } catch (Exception ex) {
            UTIL.writeLog('-1', ex.getMessage() + ' : ' + ex.getStackTraceString(), 'UTIL_WSC_Bulk.commitAll');
        }
    }

    // commit helper methods
    public void addForUpdate(List<sObject> sobjs)   { objectsToBeUpdated.addAll(sobjs); }
    public void addForUpdate(sObject sobj)          { addForUpdate(new List<sObject>{sobj} ); }
    public void addForInsert(List<sObject> sobjs)   { objectsToBeInserted.addAll(sobjs); }
    public void addForInsert(sObject sobj)          { addForInsert(new List<sObject>{sobj} ); }


}