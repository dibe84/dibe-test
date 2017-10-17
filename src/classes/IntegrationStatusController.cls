public without sharing class IntegrationStatusController {
	
	private static final String OPPORTUNITY = 'Opprtunity';
    
     @AuraEnabled
    public static Object getListWSScheduledCallOuts(String recordId, String objType) {
       
        String whereClause = '';
        if(objType == OPPORTUNITY) {
        	whereClause = 'id =\'' + recordId + '\'';
            List<Opportunity> lstOpp =  GW_sObject.queryRecords( 'Opportunity' , new List<String>{'id','AccountId'} , whereClause);
            if(!lstOpp.isEmpty()) {
                recordId = lstOpp.get(0).AccountId;
            }
        }
        String query = 'SELECT Id,Status__c,Attempts__c,Name,Method__c, (SELECT Id,Error__c,Success__c FROM WS_Logs__r order by LastModifiedDate DESC Limit 1) FROM WS_ScheduledCallout__c WHERE RecordId__c like \'%' + recordId + '%\'';
        List<WS_ScheduledCallout__c> lstResults =   Database.query(query);
        List<RemoteResponse> results = new List<RemoteResponse>();
        List<Object> resObj = new List<Object>();
        for(WS_ScheduledCallout__c wsSd: lstResults) {
        	  String msg = '';
        	  if(!wsSd.WS_Logs__r.isEmpty()) {
        	  	WS_Log__c wslg = wsSd.WS_Logs__r.get(0);
        	  	msg = wslg.Success__c ? 'OK'   : 'Error: '+ wslg.Error__c;
        	  }
         	  RemoteResponse response = new RemoteResponse( msg, 1);
			  response.setContent(wsSd);
			  results.add(response);
        }
       resObj.add(results);
       return resObj;
        
    }
    
    /**
     * Check if doesn't exist PushTopic it will auto create the PushTopic
     * @param jsonPushTopic is a string JSON as list of PushTopic
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse checkExistingTopic(String wsSheduledName,String wsLogName) {
       
        try {
        	
        	String whereClause = 'Name In (\'' + wsSheduledName + '\',\''+wsLogName+'\')';
            List<PushTopic> lstExistTopics = GW_sObject.queryRecords( 'PushTopic' , new List<String>{'id','NotifyForOperationUpdate','Name'} , whereClause);
            PushTopic pshTops;
            if(lstExistTopics.isEmpty()) {
               String query = 'Select Id,Status__c From WS_ScheduledCallout__c';
               String queryLog = 'Select ScheduledCallout__c, Id From WS_Log__c ';
               lstExistTopics.add( new PushTopic(Name = wsSheduledName , Query = query , ApiVersion = 37.0, NotifyForOperationUpdate = true, NotifyForFields = 'All'));
               lstExistTopics.add( new PushTopic(Name = wsLogName , Query = queryLog , ApiVersion = 37.0, NotifyForOperationUpdate = true, NotifyForFields = 'All'));
               insert lstExistTopics;
            } 
            
            pshTops = lstExistTopics.get(0);
            
            RemoteResponse response = new RemoteResponse();
            response.content = pshTops;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

}