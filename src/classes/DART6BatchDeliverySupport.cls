/**
 * Batch Delivery support
 */
global virtual class DART6BatchDeliverySupport implements Database.Batchable<sObject>, Database.AllowsCallOuts, Database.Stateful{

	public final static String CALL_TYPE_CHECK_REPORT_STATUS = 'Check Running Report';
	public final static String CALL_TYPE_REQUEST_REPORT = 'Query Report';
	private String callType;
	public String jobId;
	private DART_Delivery_Support__c dds;
	private String importType;
	
	/**
	 * constructor
	 * @param DART_Delivery_Support__c's id
	 * @param callType
	 */ 
	/*public DART6BatchDeliverySupport(String ddsId, String calltype){
		this.callType = calltype;
		dds = DeliveryController.getDeliverySupportRecord(ddsId);
	}*/
	
	/**
	 * constructor2
	 * @param DART_Delivery_Support__c's id
	 * @param callType
	 * @param importType that could be Adx or DFP Delivery
	 */
	public DART6BatchDeliverySupport(String ddsId, String calltype, String importType){
		this.callType = calltype;
		this.importType = importType;
		dds = DeliveryController.getDeliverySupportRecord(ddsId);
	}
    
    /**
     * Start batch
     */
	global virtual Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator([Select Id From DART_Delivery_Support__c Where Id =: dds.Id]);
	}
	
	/**
     * execute batch
     */ 
	global virtual void execute(Database.BatchableContext BC, List<sObject> scope){}  
	
	/**
     * Finish batch
     * Check batch status, run delivery & checking to run delivery from other adserverLogin
     */
	global virtual void finish(Database.BatchableContext BC){
		try{
			if(callType == CALL_TYPE_CHECK_REPORT_STATUS){ 
				DeliveryController.checkJobStatus(dds, importType); 
			}else if(callType == CALL_TYPE_REQUEST_REPORT){ 
				DeliveryController.doStart(dds, importType);
			}
			if(jobId != null ) System.abortJob(jobId);
		}catch(Exception e){
			dds.DART_Status__c = DeliveryController.REPORT_QUERY_FAILED;
			dds.Status__c = DeliveryController.DART_STATUS_FINISHED;
			update dds;
			DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(
								dds.Id , callType,
							    'DART6BatchDeliverySupport.finish', dds.AdServer_Login__r.RecordType.name, e)});
			DeliveryController.startNextAdServer(dds.Sobject__c, dds.Schedule_Type__c, importType);
			if(jobId != null ) System.abortJob(jobId);
		}
	}
}