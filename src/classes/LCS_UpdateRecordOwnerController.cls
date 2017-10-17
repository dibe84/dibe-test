public with sharing class LCS_UpdateRecordOwnerController{
 
   private static final String RESULT_STATUS='isSuccess';
   private static final String ERROR_STATUS='Error';
   
  
 
    @remoteAction
    public static Map<String,String> updateRecordOwner(Id recordId,String queueName){
    	Map<String,String> mapResult = new Map<String,String>{RESULT_STATUS=>'false'};
    	
    	try{
    		String objType = GW_sObject.getobjectNameFromId(recordId);
    		
        	String whereClause = 'Id = \''+ recordId+ '\'';
        	List<Sobject> lstRecords = GW_sObject.queryRecords(objType, new List<String>{'id','OwnerId'}, whereClause); 
        	List<QueueSobject> lstQueueRecords = [Select id,QueueId From QueueSobject  where SobjectType=: objType And Queue.DeveloperName = : queueName] ;
        	if(!lstRecords.isEmpty() && !lstQueueRecords.isEmpty()) {
        		lstRecords.get(0).put('OwnerId', lstQueueRecords.get(0).QueueId);
        		update lstRecords;
        	}
    		mapResult.put( RESULT_STATUS ,'true');   
    	} catch(Exception e) { mapResult.put(ERROR_STATUS ,e.getMessage() );}
    		
    	return mapResult;
    }
 
}