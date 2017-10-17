/** Batch process of Delivery
 *  Request all Report From Dart and check with relevant SObjects
 *  1.  OpportunityProduct (daily run and manual run) 
 *  2.  Rev__c(Revenue Item) (monthly run) 
 *  3.  Metric__c(Metric) (daily run)
 *  @Created Date: 18/01/2013  
 *  @update: chr - replace old objects with the new objects
 *      - Revenue_Schedule_daily__c to Metric__c
 *      - Revenue_Schedule__c to Rec__c
 */  
global class BatchDeliveryProcess implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallOuts{
    public static Boolean ignoreCalNonBanner = false;
    private final String SOBJ_FIELD_SEP = '.';
    private Map<String, DARTObject.IDARTGenericObject> mWithAdId;
    private Map<String, List<DARTObject.IDARTGenericObject>> mWithOutAdId;
    private String queryString;
    private String networkId;
    private String sobj;
    private DART_Delivery_Support__c dds;
    private Integer dartSize = 0;
    private Set<String> ignoredFields = new Set<String>{'Ad_Id__c', 'Adserver_ID_Order_ID__c', 'MetricDate__c', 'From_Date__c'};
    
    private List<String> successRecords = new List<String>();
    private List<String> unupdateRecords = new List<String>();
    private List<DARTObject.IDARTGenericObject> listImport= new List<DARTObject.IDARTGenericObject>();
    //list none update delivery
    private List<DARTObject.DARTDelivery> listDeliveries = new  List<DARTObject.DARTDelivery>();
    
    /**
     * @updated: chr - 20-10-2014: Changed DFP mapping fields from 
     *           - MERGED_AD_SERVER_CLICKS to TOTAL_LINE_ITEM_LEVEL_CLICKS
     *           - MERGED_AD_SERVER_IMPRESSIONS to TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS
                 - JvdH: MERGED_AD_SERVER_DELIVERY_INDICATOR to AD_SERVER_DELIVERY_INDICATOR
     * (Resion: GT-AU never used the old version of DART)
     * D6 FieldNames:
     * mergeReservationImpressionsDelivered -> TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS   // MERGED_AD_SERVER_IMPRESSIONS
     * mergeLineItemDeliveryIndicator -> AD_SERVER_DELIVERY_INDICATOR
     * mergeReservationClicksDelivered -> TOTAL_LINE_ITEM_LEVEL_CLICKS  // MERGED_AD_SERVER_CLICKS
     * 
     * @updated: chr - 20-11-2014: Changed logic to use new Custom objects
     *     - Delivery for total period, run daily, store on Rev__c
     *          + TOTAL_LINE_ITEM_LEVEL_CLICKS(StartDate until NOW) => Rev__c.AD_Clicks__c
     *          + TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS(StartDate until NOW) => Rev__c.AD_Impressions__c
     *          + OSI => Rev__c.AD_OSI__c
     *     - Delivery per day, run daily, store on Metric__c
     *          + TOTAL_LINE_ITEM_LEVEL_CLICKS(Metric__c.MetricDate__c) => Metric__c.AD_Clicks__c
     *          + TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS(Metric__c.MetricDate__c) => Metric__c.AD_Impressions__c
     *          + OSI => Metric__c.AD_OSI__c
     */
    public Map<String, String> mFieldsDartToSObj = new Map<String, String>{
        //Matching OpportunityLineItem
        DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'Ad_Id__c' => DARTObject.DEL_FIELD_ADID, //'lineItemId',
        DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'Adserver_ID_Order_ID__c' => DARTObject.DEL_FIELD_ORDERID, //'orderId',
        //DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'delivered_AI_LT__c' => DARTObject.DEL_FIELD_ADDELIVERED, //'mergeReservationImpressionsDelivered', Delivered (Lifetime)  
        //DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'Delivered_Clicks_LT__c' => DARTObject.DEL_FIELD_ADCLICKED_LIFETIME, //'mergeReservationClicksDelivered', Clicks Recorded (Lifetime) (delivered_Clicks_LT__c)
        //DeliveryController.OPPORTUNITY_PRODUCT_API_NAME + SOBJ_FIELD_SEP + 'OSI__c' => DARTObject.DEL_FIELD_ADOSI, //'mergeLineItemDeliveryIndicator', OSI (Lifetime)
        //Matching Rev__c
        DeliveryController.REVENUE_ITEM_API_NAME + SOBJ_FIELD_SEP + 'AD_Impressions__c' => DARTObject.DEL_FIELD_IMPRESS_DELIVERED, //'mergeReservationImpressionsDelivered', Impressions Delivered
        DeliveryController.REVENUE_ITEM_API_NAME + SOBJ_FIELD_SEP + 'AD_Clicks__c' => DARTObject.DEL_FIELD_CLICKS_DELIVERED, //'mergeReservationClicksDelivered', Clicks Recorded  
        DeliveryController.REVENUE_ITEM_API_NAME + SOBJ_FIELD_SEP + 'AD_OSI__c' => DARTObject.DEL_FIELD_ADOSI, //'mergeReservationClicksDelivered', Clicks Recorded
        
        //Matching Metric__c
        DeliveryController.METRIC_API_NAME + SOBJ_FIELD_SEP + 'AD_Impressions__c' => DARTObject.DEL_FIELD_IMPRESS_DELIVERED, //'mergeReservationImpressionsDelivered', Impressions Delivered  
        DeliveryController.METRIC_API_NAME + SOBJ_FIELD_SEP + 'AD_Clicks__c' => DARTObject.DEL_FIELD_CLICKS_DELIVERED, //'mergeReservationClicksDelivered', Clicks Recorded 
        DeliveryController.METRIC_API_NAME + SOBJ_FIELD_SEP + 'AD_OSI__c' => DARTObject.DEL_FIELD_ADOSI //'mergeLineItemDeliveryIndicator'
        
    };
    
    /** 
     * For executing on first adlogin 
     */
    public BatchDeliveryProcess(String queryString, List<DARTObject.IDARTGenericObject> lstDartObject, String ddsId){ 
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
        List<Sobject> lsobjNoneUpd = new List<Sobject>();
        for(Sobject sobj : scope){
            try{
                String sobjId = sobj.get('Id') + '';
                if(submitToSFRecord(sobj)){
                    lsobj.add(sobj);
                    successRecords.add(sobjId); 
                }else{
                    unupdateRecords.add(sobjId);
                    lsobjNoneUpd.add(sobj);
                }
            }catch(Exception e){
                ldartLogger.add(new DARTLogger.LogMessage(
                    sobj.Id ,'Import Delivery Process Fault',
                    'BatchDeliveryProcess.execute', dds.AdServer_Login__r.RecordType.name,
                    DARTLogger.TYPE_ERROR, dds.DART_Status__c, e + ''));
                System.debug('-------------------->>' + e.getStackTraceString() +'/n/n--------------->>'+ e);
             } 
        }
        if(!lsobj.isEmpty()){
            String sobjType = String.valueOf(lsobj[0].getSObjectType()); 
            ignoreCalNonBanner = true;
            update lsobj;
            // dcortes 2014-06-20 error with BatchDeliveryProcess execution.
            //Revenue.calNetNetForecastRSNonBanner_trigger(lsobj); 
            // end of dcortes 2014-06-20
            //mengsrorn 2014-06-23 : update only Revenue_Schedule__c object
            if(sobjType == DeliveryController.REVENUE_ITEM_API_NAME){
                //Revenue.calNetNetForecastRSNonBanner_trigger(lsobj);
            }
            ignoreCalNonBanner = false;
        }
        
        //Chr-@updated: 24-03-2015
        //#5088: Updating DFP 0 clicks, 0 impressions on metrics to those unupdate records
        String sname = String.valueOf(dds.Sobject__c);
        if(sname == DeliveryController.SOBJECT_METRIC && !lsobjNoneUpd.isEmpty()){
        	for(Sobject sbj : lsobjNoneUpd){
        		if(sbj.get('AD_Impressions__c') == null) sbj.put('AD_Impressions__c', 0);
        		if(sbj.get('AD_Clicks__c') == null)	sbj.put('AD_Clicks__c', 0);
        	}
        	update lsobjNoneUpd;
        	generateDevObjForUnUpdatedRec(lsobjNoneUpd);
        }
        
        if(!ldartLogger.isEmpty()) DARTLogger.getInstance().log(dds.Id,ldartLogger);
    }
    
    /**
     * generate unupdated records to Devlivery object
     */
    private void generateDevObjForUnUpdatedRec(List<Sobject> lstSobj)
    {
    	for(Sobject sbj : lstSobj){
	    	listDeliveries.add(	new DARTObject.DARTDelivery(
						   		new Map<Object,Object>
						   			{
							   			DARTObject.DEL_FIELD_ADDELIVERED => 0,
							   			DARTObject.DEL_FIELD_ADCLICKED_LIFETIME => 0,
							   			DARTObject.DEL_FIELD_ADOSI => 0, 
							   			DARTObject.DEL_FIELD_ADID => sbj.getSObject('Rs__r').getSObject('Rev__r').get('ExtLineItemId__c')+'',
							   			DARTObject.DEL_FIELD_ORDERID => sbj.getSObject('Rs__r').getSObject('Rev__r').get('ExtOrderId__c')+'',
							   			DARTObject.DEL_FIELD_IMPRESS_DELIVERED => 0,
							   			DARTObject.DEL_FIELD_CLICKS_DELIVERED => 0,
						   				DARTObject.DEL_FIELD_DATE_OR_MONTH => sbj.get('MetricDate__c')
						   			}
					   			));
        	}
    }
    
     /** 
     * Clear all completed schedule
     * 
     */
    private void clearCompletedSch() {
    		Set<String> setStatus = new Set<String>{'COMPLETED', 'DELETED'};
    		for(CronTrigger cron : [SELECT Id FROM CronTrigger WHERE State In : setStatus Limit 150]) {
		  system.abortJob(cron.id);
		}
    		//delete all job records for jobs that have finished before Yesterday’s date.
    		Integer countDay = System.purgeOldAsyncJobs(Date.today().addDays(-1));
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
                            dds.Id ,'Import Delivery Process',
                            'BatchDeliveryProcess.finish',dds.AdServer_Login__r.RecordType.name,
                            DARTLogger.TYPE_SUCCESS, dds.DART_Status__c, 'Update size: ' + successRecords.size() + ' of '+ dartSize + ' [ Attachment Id Details ' + attlog.Id + ' ]')});
    }
    
    /**
     * Finish batch
     */
    global void finish(Database.BatchableContext BC){
        try{
            dofinish();
            DeliveryController.startNextAdServer(sobj, dds.Schedule_Type__c, DeliveryController.DFP_DELIVERY);
            clearCompletedSch();
        }catch(Exception e){
            DARTLogger.getInstance().log(dds.Id,new List<DARTLogger.LogMessage>{new DARTLogger.LogMessage(
                dds.Id ,'Import Delivery Process Fault','BatchDeliveryProcess.finish', dds.AdServer_Login__r.RecordType.name,
                DARTLogger.TYPE_ERROR, dds.DART_Status__c, e + '')});
                
                System.debug('----------------------->>' + e.getStackTraceString() +'/n/n--------------->>'+ e);
            DeliveryController.startNextAdServer(sobj, dds.Schedule_Type__c, DeliveryController.DFP_DELIVERY);
        } 
    }

    /**
     * For Matching Ad Id from report with Ad_Id__c
     */
    private void initMapperDartObject(List<DARTObject.IDARTGenericObject> lstDartObject){
        mWithAdId = new Map<String, DARTObject.IDARTGenericObject>();
        mWithOutAdId = new Map<String, List<DARTObject.IDARTGenericObject>>();
        for(DARTObject.IDARTGenericObject dObj : lstDartObject){
            DARTObject.DARTDelivery dartObj = (DARTObject.DARTDelivery)dObj;
            if(dartObj.getAdId() != ''){
                mWithAdId.put(getCombinedKeyDart(dartObj, false), dartObj);
            }else{
                if(!mWithOutAdId.containsKey(dartObj.getOrderId())) mWithOutAdId.put(getCombinedKeyDart(dartObj, true), new List<DARTObject.IDARTGenericObject>());
                mWithOutAdId.get(getCombinedKeyDart(dartObj, true)).add(dartObj);
            }
        }
    }
    
    private String getCombinedKeyDart(DARTObject.DARTDelivery dartObj, Boolean isAdIdNull){
        //NK:02/05/2014: disabled these original 2 lines
        //if(isAdIdNull) return dartObj.getOrderId() + SOBJ_FIELD_SEP + networkId + SOBJ_FIELD_SEP + dartObj.getDateString();
        //return dartObj.getAdId() + SOBJ_FIELD_SEP + networkId + SOBJ_FIELD_SEP + dartObj.getDateString();
        
        //NK:02/05/2014: To fix 'year' responsed in the xml report (new dfp version)
        String dateString = dartObj.getDateString();
        if(dateString.contains(' ')) dateString = dateString.split(' ')[0];
        if(isAdIdNull) return dartObj.getOrderId() + SOBJ_FIELD_SEP + networkId + SOBJ_FIELD_SEP + dateString;
        return dartObj.getAdId() + SOBJ_FIELD_SEP + networkId + SOBJ_FIELD_SEP + dateString;
    }
        
    private String getCombinedKeySObject(SObject sobj, Boolean isAdIdNull){
        Map<String, String> mTypeField = new Map<String, String>{
            DeliveryController.REVENUE_ITEM_API_NAME => 'Product__r.Site__r.Country__c', 
            DeliveryController.METRIC_API_NAME => 'Rs__r.Rev__r.Product__r.Site__r.Country__c',
            'OpportunityLineItem' => 'PricebookEntry.Product2.Site__r.Country__c'
        };
        
        Map<String, String> mDateField = new Map<String, String>{
            //DeliveryController.REVENUE_ITEM_API_NAME => 'From_Date__c',
            DeliveryController.REVENUE_ITEM_API_NAME => '', 
            DeliveryController.METRIC_API_NAME => 'MetricDate__c',
            DeliveryController.OPPORTUNITY_PRODUCT_API_NAME => ''
        }; 
         
        String sobjType = String.valueOf(sobj.getSObjectType()); 
        String valDate = mDateField.get(sobjType) == '' ? '' : sobj.get(mDateField.get(sobjType)) + '';
        if(valDate != ''){
            DateTime valDatetime = DateTime.valueOf(valDate);
            //if(sobjType == DeliveryController.REVENUE_ITEM_API_NAME) valDate = MINT_TO_MONTH.get(valDatetime.month());
            if(sobjType == DeliveryController.METRIC_API_NAME) valDate = valDatetime.format('M/d/yy');// format response from server;
        } 
        String networkfield = mTypeField.get(sobjType);
        String valNetwork = '';
        if(networkfield == 'PricebookEntry.Product2.Site__r.Country__c'){ 
            valNetwork += sobj.getSObject('PricebookEntry').getSObject('Product2').getSObject('Site__r').get('Country__c');
        }else if(networkfield == 'Rs__r.Rev__r.Product__r.Site__r.Country__c'){
            valNetwork += sobj.getSObject('Rs__r').getSObject('Rev__r').getSObject('Product__r').getSObject('Site__r').get('Country__c');
        }else if(networkfield == 'Product__r.Site__r.Country__c'){
            valNetwork += sobj.getSObject('Product__r').getSObject('Site__r').get('Country__c');
        }
        else valNetwork += sobj.get(networkfield);
        //If Ad_Id__c = ‚Äú‚Äù match Order Id from report with Order_Id__c, oppline If Ad_Id__c = ‚Äú‚Äù match Order Id from report with Adserver_ID_Order_ID__c
        if(isAdIdNull){
            String comKeyOderId = '';
            if(sobjType == DeliveryController.OPPORTUNITY_PRODUCT_API_NAME){
                comKeyOderId = sobj.get('Adserver_ID_Order_ID__c')+'';
            }else if(sobjType == DeliveryController.METRIC_API_NAME){
                comKeyOderId = sobj.getSObject('Rs__r').getSObject('Rev__r').get('ExtOrderId__c')+'';
            }else if(sobjType == DeliveryController.REVENUE_ITEM_API_NAME){
                comKeyOderId = sobj.get('ExtOrderId__c')+'';
            }
            comKeyOderId += SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate;
            return comKeyOderId;
            //return (sobjType == DeliveryController.OPPORTUNITY_PRODUCT_API_NAME ? sobj.get('Adserver_ID_Order_ID__c')  : sobj.get('Order_Id__c')) + SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate;
        }else{
            String comKeyAdId = '';
            if(sobjType == DeliveryController.OPPORTUNITY_PRODUCT_API_NAME){
            	comKeyAdId = sobj.get('Ad_Id__c')+'';
            }else if(sobjType == DeliveryController.METRIC_API_NAME){
                comKeyAdId = sobj.getSObject('Rs__r').getSObject('Rev__r').get('ExtLineItemId__c')+'';
            }else if(sobjType == DeliveryController.REVENUE_ITEM_API_NAME){
                comKeyAdId = sobj.get('ExtLineItemId__c')+'';
            }
            comKeyAdId += SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate;
            return comKeyAdId;
            //return sobj.get('Ad_Id__c') + SOBJ_FIELD_SEP + valNetwork + SOBJ_FIELD_SEP + valDate;
        }   
    }
    
    /**
     * ‚Ä¢ Match Ad Id from report with Ad_Id__c and submit values to SF according to 5.3
     * ‚Ä¢ If Ad_Id__c = ‚Äú‚Äù match Order Id from report with Order_Id__c, sum up values and submit sum to SF according to 5.3
     * ‚Ä¢ Only for daily: Select from OpportunityProducts all records according to 5.2.2 and get Adserver_ID_Order_ID__c, Ad_Id__c
     * ‚Ä¢ Match Ad Id from report with Ad_Id__c and submit values to SF according to 5.3
     * ‚Ä¢ If Ad_Id__c = ‚Äú‚Äù match Order Id from report with Adserver_ID_Order_ID__c, sum up values and submit sum to SF according to 5.3
     */
    private Boolean submitToSFRecord(SObject sobj){
        String sobjType = sobj.getSObjectType() + SOBJ_FIELD_SEP ;
        System.debug('**************sobjType:::' + sobjType);
        //Get Matching DartObjects
        DARTObject.DARTDelivery dartObject = null;
        String sobjName = String.valueOf(sobj.getSObjectType()); 

        if((sobjName == DeliveryController.OPPORTUNITY_PRODUCT_API_NAME && sobj.get('Ad_Id__c') == null) 
            || (sobjName == DeliveryController.REVENUE_ITEM_API_NAME && sobj.get('ExtOrderId__c') == null) 
            || (sobjName == DeliveryController.METRIC_API_NAME && sobj.getSObject('Rs__r').getSObject('Rev__r').get('ExtLineItemId__c') == null)){
            String val_Order = getCombinedKeySObject(sobj, true);
            //Sum List dartObjects
            if(mWithOutAdId.containsKey(val_Order)) dartObject = sumDartObjects((List<DARTObject.DARTDelivery>)mWithOutAdId.get(val_Order));
        }else if(mWithAdId.containsKey(getCombinedKeySObject(sobj, false)))
        {
            dartObject = (DARTObject.DARTDelivery)mWithAdId.get(getCombinedKeySObject(sobj, false));
        }
        /*if(sobj.get('Ad_Id__c') == null){
            String val_Order = getCombinedKeySObject(sobj, true);
            //Sum List dartObjects
            if(mWithOutAdId.containsKey(val_Order)) dartObject = sumDartObjects((List<DARTObject.DARTDelivery>)mWithOutAdId.get(val_Order)); 
        }else if(mWithAdId.containsKey(getCombinedKeySObject(sobj, false))){
            dartObject = (DARTObject.DARTDelivery)mWithAdId.get(getCombinedKeySObject(sobj, false));
        }*/
        if(dartObject == null) return false;
        //Assign Values form matching DartObject to SObject
        for(String combinTypeField : mFieldsDartToSObj.keySet()){
            if(!combinTypeField.contains(sobjType)) continue;
            String sobjFieldname = combinTypeField.replace(sobjType, '');
            if(ignoredFields.contains(sobjFieldname)) continue;
            String dartObjectFieldname = mFieldsDartToSObj.get(combinTypeField);
            String dartVal = String.valueOf(dartObject.getValue(dartObjectFieldname));  
            dartVal = dartVal.replace('%', '').replace(',', '');
            if(!DARTUtil.isNumber(dartVal)) continue;
            sobj.put(sobjFieldname, Decimal.valueOf(dartVal));
        }
        return true;
    }
    
    /**
     * Sum all dartObject with empty Ad Id 
     */
     private DARTObject.DARTDelivery sumDartObjects(List<DARTObject.DARTDelivery> ldartDelivery){
        Map<Object,Object> mapRecord = new Map<Object,Object>{
            DARTObject.DEL_FIELD_ADDELIVERED => ldartDelivery[0].getAdDelivered(),
            DARTObject.DEL_FIELD_ADCLICKED_LIFETIME => ldartDelivery[0].getAdClickedLifetime(),
            DARTObject.DEL_FIELD_ADOSI => ldartDelivery[0].getAdOSI(),
            DARTObject.DEL_FIELD_ADID => ldartDelivery[0].getOrderId(),
            DARTObject.DEL_FIELD_ORDERID => ldartDelivery[0].getOrderId(),
            DARTObject.DEL_FIELD_IMPRESS_DELIVERED => ldartDelivery[0].getImpressionsDelivered(),
            DARTObject.DEL_FIELD_CLICKS_DELIVERED => ldartDelivery[0].getClicksDelivered()
        };
        for(Integer i = 1; i<ldartDelivery.size(); i++){
            DARTObject.DARTDelivery dartDelivery = ldartDelivery[i];
            for(Object keyObject : mapRecord.keySet()){
                String fldname = (String)keyObject;
                if(fldname.equals(DARTObject.DEL_FIELD_ADID) || fldname.equals(DARTObject.DEL_FIELD_ORDERID)) continue; 
                Decimal sum = (Decimal)(mapRecord.get(fldname)) + (Decimal)(dartDelivery.getValue(fldname));
                mapRecord.put(fldname, sum);
            }
        }
        return new DARTObject.DARTDelivery(mapRecord);
     }
      public static final Map<Integer, String> MINT_TO_MONTH = new Map<Integer, String>{
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December'
    };
    
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
        for(DARTObject.IDARTGenericObject dObj : listImport){
            DARTObject.DARTDelivery dartObj = (DARTObject.DARTDelivery)dObj;
            messageBody += '\n' + dartObj.getAdId() + ' > ' + dartObj;
        }
        String sname = String.valueOf(dds.Sobject__c);
        if(sname == DeliveryController.SOBJECT_METRIC && !listDeliveries.isEmpty()){
	        messageBody += ' ]\n\nUpdated Clicks(0) and Impression(0):[ ';
	        for(DARTObject.IDARTGenericObject dObj : listDeliveries){
	            DARTObject.DARTDelivery dartObj = (DARTObject.DARTDelivery)dObj;
	            messageBody += '\n' + dartObj.getAdId() + ' > ' + dartObj;
	        }
        }
        
        messageBody += ' ]'; 
        att.Body = Blob.valueOf(messageBody);
        insert att;
        return att;
    }
}