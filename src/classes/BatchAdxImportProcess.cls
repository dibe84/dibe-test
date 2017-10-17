/**
 *  Batch process of Adx report
 *  Request all Report From Dart and check with relevant SObjects
 *  1.  Metric__c(Metric) (daily run)
 *  @Created Date: 07/07/2015 
 */
global class BatchAdxImportProcess implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallOuts{
	
	private final String SOBJ_FIELD_SEP = '.';
	public Map<String, String> mFieldsDartToSObj = new Map<String, String>{
		
        //Matching Metric__c
        DeliveryController.METRIC_API_NAME + SOBJ_FIELD_SEP + 'AD_Impressions__c' => DARTObject.ADX_FIELD_LEVEL_IMPRESSION,
        DeliveryController.METRIC_API_NAME + SOBJ_FIELD_SEP + 'AD_Clicks__c' => DARTObject.ADX_FIELD_LEVEL_CLICK,
        DeliveryController.METRIC_API_NAME + SOBJ_FIELD_SEP + 'AD_Amount__c' => DARTObject.ADX_FIELD_LEVEL_REVENUE
        
    };
    
    
    private  Map<String, DARTObject.IDARTGenericObject> mDartObj;
    private Integer dartSize = 0;
    private String queryString;
    private String networkId;
    private String sobj;
    private DART_Delivery_Support__c dds;
    private Set<String> ignoredFields = new Set<String>{'MetricDate__c'};
    
    private List<String> successRecords = new List<String>();
    private List<String> unupdateRecords = new List<String>();
    private List<DARTObject.IDARTGenericObject> listImport= new List<DARTObject.IDARTGenericObject>();
    private Map<String, DARTObject.IDARTGenericObject> mapUpdatedRecId = new Map<String, DARTObject.IDARTGenericObject>();
    
    /** 
     * For executing on first adlogin 
     */
    public BatchAdxImportProcess(String queryString, List<DARTObject.IDARTGenericObject> lstDartObject, String ddsId){ 
        dartSize = lstDartObject.size();
        this.dds = DeliveryController.getDeliverySupportRecord(ddsId);
        this.networkId = dds.AdServer_Login__r.Name;
        this.queryString = queryString;
        UTIL.log('QueryString: '+queryString);
        this.sobj = dds.Sobject__c;
        this.listImport = lstDartObject;
        initMapperDartObject(lstDartObject);
    }
    
    /**
     * Start batch
     */
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(queryString);
    }
     
    /**
     * Execute batch
     */ 
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        doExecute(scope);
    }
    
    /**
     * do execute import delivery
     * @param List of Sobject
     */
    global void doExecute(List<Sobject> scope){
        List<DARTLogger.LogMessage> ldartLogger = new List<DARTLogger.LogMessage>();
        List<Sobject> lsobj = new List<Sobject>();
        for(Sobject sobj : scope){
            try{
                String sobjId = sobj.get('Id') + '';
                if(submitToSFRecord(sobj)){
                    lsobj.add(sobj);
                    successRecords.add(sobjId); 
                }else{
                    unupdateRecords.add(sobjId);
                }
            }catch(Exception e){ldartLogger.add(new DARTLogger.LogMessage(sobj.Id ,'Import Adx Process Fault','BatchAdxImportProcess.execute', dds.AdServer_Login__r.RecordType.name,DARTLogger.TYPE_ERROR, dds.DART_Status__c, e + ''));
                System.debug('-------------------->>' + e.getStackTraceString() +'/n/n--------------->>'+ e);
             } 
        }
        if(!lsobj.isEmpty()){
            String sobjType = String.valueOf(lsobj[0].getSObjectType()); 
            update lsobj;
        }
        
        if(!ldartLogger.isEmpty()) DARTLogger.getInstance().log(dds.Id,ldartLogger);
    }
    
     private Boolean submitToSFRecord(SObject sobj){
        String sobjType = sobj.getSObjectType() + SOBJ_FIELD_SEP ;
        //Get Matching DartObjects
        DARTObject.DARTAdxImport dartObj= null;
		if(mDartObj.containsKey(getCombinedKeySObject(sobj)))
        {
            dartObj =  (DARTObject.DARTAdxImport)mDartObj.get(getCombinedKeySObject(sobj));
            mapUpdatedRecId.put(sobj.get('Id')+'', dartObj);
        }

        if(dartObj == null) return false;
        //Assign Values form matching DartObject to SObject
        for(String combinTypeField : mFieldsDartToSObj.keySet()){
            if(!combinTypeField.contains(sobjType)) continue;
            String sobjFieldname = combinTypeField.replace(sobjType, '');
            if(ignoredFields.contains(sobjFieldname)) continue;
            String dartObjectFieldname = mFieldsDartToSObj.get(combinTypeField);
            String dartVal = String.valueOf(dartObj.getValue(dartObjectFieldname));  
            System.debug('---------------->>dartVal::::' + dartVal);
            dartVal = dartVal.replace('%', '').replace(',', '').replace('A$', '').replace('€', '').replace('$', '');
            if(!DARTUtil.isNumber(dartVal)) continue;
            sobj.put(sobjFieldname, Decimal.valueOf(dartVal));
        }
        return true;
    }
    
    
    /**
     * For Matching Ad Id from report with Ad_Id__c
     */
    private void initMapperDartObject(List<DARTObject.IDARTGenericObject> lstDartObject){
        mDartObj = new Map<String, DARTObject.IDARTGenericObject>();
        for(DARTObject.IDARTGenericObject dObj : lstDartObject){
            DARTObject.DARTAdxImport dartObj = (DARTObject.DARTAdxImport)dObj;
            if(mDartObj.get(getCombinedKeyDart(dartObj)) == null){
            	mDartObj.put(getCombinedKeyDart(dartObj), dartObj);
            }
        }
    }
    
    private String getCombinedKeyDart(DARTObject.DARTAdxImport dartObj){

        String dateString = dartObj.getDateString();
        //ex: AU.7/6/15
        if(dateString.contains(' ')) dateString = dateString.split(' ')[0];
        return networkId + SOBJ_FIELD_SEP + dateString;
    }  
    
    /**
     * Finish batch
     */
    global void finish(Database.BatchableContext BC){
        try{
            dofinish();
            DeliveryController.startNextAdServer(sobj, dds.Schedule_Type__c, DeliveryController.ADX_IMPORT);
        }catch(Exception e){DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(dds.Id ,'Import Delivery Process Fault','BatchDeliveryProcess.finish', dds.AdServer_Login__r.RecordType.name,DARTLogger.TYPE_ERROR, dds.DART_Status__c, e + '')});
			DeliveryController.startNextAdServer(sobj, dds.Schedule_Type__c, DeliveryController.ADX_IMPORT);
            System.debug('----------------------->>' + e.getStackTraceString() +'/n/n--------------->>'+ e);
        } 
    }
	
	private String getCombinedKeySObject(SObject sobj){
        Map<String, String> mTypeField = new Map<String, String>{
            DeliveryController.METRIC_API_NAME => 'Rs__r.Rev__r.Product__r.Site__r.Country__c'
        };
        
        Map<String, String> mDateField = new Map<String, String>{
            DeliveryController.METRIC_API_NAME => 'MetricDate__c'
        }; 
         
        String sobjType = String.valueOf(sobj.getSObjectType()); 
        String valDate = mDateField.get(sobjType) == '' ? '' : sobj.get(mDateField.get(sobjType)) + '';
        if(valDate != ''){
            DateTime valDatetime = DateTime.valueOf(valDate);
            if(sobjType == DeliveryController.METRIC_API_NAME) valDate = valDatetime.format('M/d/yy');// format response from server;
        } 
        String networkfield = mTypeField.get(sobjType);
        String valNetwork = '';
        if(networkfield == 'Rs__r.Rev__r.Product__r.Site__r.Country__c'){
            valNetwork += sobj.getSObject('Rs__r').getSObject('Rev__r').getSObject('Product__r').getSObject('Site__r').get('Country__c');
        }
        else valNetwork += sobj.get(networkfield);

        return valNetwork + SOBJ_FIELD_SEP + valDate;  
    }
    
    /** 
     * do finish
     * update Dart_Delivery_Support
     * create attachement
     * add log message to Dart_Delivery_Support
     */
    global void dofinish(){
        dds.DART_Status__c = DeliveryController.REPORT_QUERY_COMPLETED;
        dds.Status__c = DeliveryController.DART_STATUS_FINISHED;
        update dds;
        Attachment attlog = createAttachedLogfile(true);
        DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(
                            dds.Id ,'Import Adx Process',
                            'BatchAdxImportProcess.finish',dds.AdServer_Login__r.RecordType.name,
                            DARTLogger.TYPE_SUCCESS, dds.DART_Status__c, 'Update size: ' + successRecords.size() + ' of '+ dartSize + ' [ Attachment Id Details ' + attlog.Id + ' ]')});
    }
    
    /**
     * @description add reponsed report/Sf's record update & unupdate record to attachment
     * @param boolean doLog
     * @return Attachment
     */ 
     private Attachment createAttachedLogfile(Boolean doLog){
        Attachment att = new Attachment();
        att.ParentId = dds.Id;
        att.Name = 'Logged Import Data';
        if(!doLog) return att;
        String messageBody = 'Updated size: ' + successRecords.size() + ' of '+ dartSize;
        messageBody += '\n\nUpdated Records:[ ';
        for(String rec : successRecords) messageBody += ' ' + rec;
        messageBody += ' ]\n\nNonUpdate Records:[ ';
        for(String rec : unupdateRecords) messageBody += ' ' + rec;
        messageBody += ' ]\n\nImported Data:[ ';
        for(String key : mapUpdatedRecId.keySet()){
        	DARTObject.IDARTGenericObject dObj= mapUpdatedRecId.get(key);
            DARTObject.DARTAdxImport dartObj = (DARTObject.DARTAdxImport)dObj;
            messageBody += '\n' + key + ' > ' + dartObj;
        }
        
        messageBody += ' ]\n\nAdx Data:['; 
        
        for(DARTObject.IDARTGenericObject dObj : listImport){
            DARTObject.DARTAdxImport dartObj = (DARTObject.DARTAdxImport)dObj;
            messageBody += '\n' + dartObj.getDateString() + ' > ' + dartObj;
        }
         messageBody += ' ]';
        //mDartObj
        att.Body = Blob.valueOf(messageBody);
        insert att;
        return att;
    }
}