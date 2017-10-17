public with sharing class WSI_API_SFECG_Metric_v1 {

    private static final String APINAME = 'WSI_API_SFECG_Metric_v1';

    public static Map<String, String> metricFieldMap = new Map<String,String> {
                                                        'CLICKS' => 'AD_Clicks__c',
                                                        'IMPRESSIONS' => 'AD_Impressions__c',
                                                        'REVENUE' => 'AD_Amount__c',
                                                        'QUANTITY' => 'AD_Quantity__c'
                                                    };

    public static void process(String wsClassName, WSI_CTRL.APIResponse resp, Metric metric) {
            Type t = Type.forName(APINAME + '.' + wsClassName);
            WSI_MetricApiRequest apiRequest = (WSI_MetricApiRequest) t.newInstance();

            apiRequest.init(resp, metric);
			apiRequest.processRequest();
	}

    public class Metric {
            public String memberId {get; set;}
            public String accountId {get; set;}
            public String memberUnitId {get;set;}
            public String bookingId {get; set;}
            public String metricDateId {get; set;}
            public Map<String,String> keyValues = new Map<String,String>();

            public override String toString() {
                return '{ '
                        + 'MemberId : \'' + memberId +'\', '
                        + 'accountId : \'' + accountId +'\', '
                        + 'memberUnitId : \'' + memberUnitId +'\', '
                        + 'bookingId : \'' + bookingId +'\', '
                        + 'metricDateId : \'' + metricDateId +'\', '
                        + 'keyValues : ' + keyValues + ' }';
            }
    }

	public WSI_API_SFECG_Metric_v1() {

	}

    public virtual class WSI_MetricApiRequest extends WSI_ApiRequest {
        private Metric metric;

        public void init(WSI_CTRL.APIResponse apiResp, Metric metric) {
            this.metric = metric;
            init(apiResp);
        }

        public override void init(WSI_CTRL.APIResponse apiResp) {
            super.init(apiResp);
        }

        public override void setContextRecords() {
            //Contextrecord is the metric that needs updating.
            //First find Rev based on UniqueLocalBookingId.
            //Use that rev's master rev id to lookup the metric based on requested input.
            //Return response with error message when the metric couldn't be found.

            try {

                Date metricDate = Date.valueOf(metric.metricDateId + ' 13:00:00');
                String metricDateString = ((Datetime) Datetime.valueOf(metric.metricDateId + ' 13:00:00')).format('yyyyMMdd');
                String uniqueLocalBookingId = metric.memberUnitId + '_' + metric.bookingId;
                String uniqueLocalAccountId = metric.memberId + '_' + metric.accountId;

                String whereClause = 'UniqueLocalBookingId__c = \'' + uniqueLocalBookingId + '\' AND Opportunity__r.Account.UniquePlatformId__c = \''+uniqueLocalAccountId+'\'';

                Rev__c rev = (Rev__c) GW_sObject.queryRecords('Rev__c', whereClause).get(0);


                String metricdateUnderscoreMasterRevId = metricDateString + '_' + rev.MasterIdForm__c;

                whereClause = 'ExternalUID__c = \'' + metricdateUnderscoreMasterRevId + '\'';

                //Check until date and from date to check if metric date makes sense.
                List<Sobject> contextRecords = GW_sObject.queryRecordsForUpdate('Metric__c',whereClause);


                if ( contextRecords.size() >= 1 ) {
                    contextRecord = contextRecords.get(0);
                }
                else{

                    if ( !(metricDate >= rev.From_Date__c && metricDate <= rev.SubscriptionEndDate__c) ) {
                        throw new WSI_CTRL.APIException('No metrics expected on this date: '+metricDate);
                    }
                    else {
                        String metricDateSOQLFormat = DateTime.newInstance(metricDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
                        whereClause = 'MasterIdForm__c = \'' + rev.MasterIdForm__c + '\'' + ' AND From_Date__c <= ' + metricDateSOQLFormat + ' AND Until_Date__c >= '+ metricDateSOQLFormat;
                        UTIL.log('WHERECLAUSE: '+ whereClause);
                        List<RS__c> rss = (List<RS__c>) GW_sObject.queryRecords('RS__c', whereClause);
                        RS__C rs;
                        for (RS__c r : rss ){
                            if (rev.MasterIdForm__c.equals(r.MasterIdForm__c)){
                                rs = r;
                            }
                        }
                        contextRecord = GW_Metric.createMetricFromRS(rs, metricDate);
                    }
                }

            } catch (WSI_CTRL.APIException wsiE) {
                contextRecordNotFound(wsiE.getMessage());
            }
            catch (Exception e) {
                contextRecordNotFound('Unexpected error, no Metric container found: ' + e.getMessage());
            }
        }

        public virtual override void prepareResponse() {

            Map<String,List<Object>> responseMap = new Map<String,List<Object>>(); //All updated values
            Map<String,String> reverseMetricFieldMap = reverseMap(metricFieldMap); // Salesforce field name to json field name map

            for(String objName : objectNameToFieldNameNewFieldValueMap.keySet()) {
                List<Object> metrics = new List<Object>();
                for (String fieldName : objectNameToFieldNameNewFieldValueMap.get(objName).keySet()) {
                    Map<String,Object> updatedValues = new Map<String, Object>();

                    if (reverseMetricFieldMap.get(fieldName) != null) {
                        updatedValues.put('metricKey', reverseMetricFieldMap.get(fieldName));
                    } else {
                        updatedValues.put('metricKey', objName+'.'+fieldName);
                    }
                    updatedValues.put('metricValue', contextRecord.get(fieldName));

                    metrics.add(updatedValues);
                }
                if (metrics.size()>0) {
                    responseMap.put('metrics', metrics);
                }
            }

            if (contextRecord != null){
                apiResp.linklog('Metric__c', contextRecord.Id);
            }

            apiResp.setResponse(responseMap);

        }
    }

    public class MetricUpdate extends WSI_MetricApiRequest {

        public override void validateData() {

            Map<String,String> metricFieldsToUpdate = new Map<String,String>();
            objectNameToFieldNameNewFieldValueMap = new Map<String,Map<String,String>>();

            List<Object> metricList = (List<Object>)requestJSON.get('metrics');


            for (Object metricMapObject : metricList) {
                Map<String, Object> metricMap = (Map<String, Object>) metricMapObject;

                String metricKey = (String) metricMap.get('metricKey');
                String metricValue = ''+metricMap.get('metricValue');

                String fieldName = metricFieldMap.get(metricKey.toUpperCase());


                if (fieldName == null) {
                    apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Data validation error: metricKey not supported,' + metricKey);
    	            throw new WSI_CTRL.APIException();
                }

                metric.keyValues.put(fieldName, metricValue);
            }

            // Add to save container
            if (metricList.size() > 0){
                objectNameToFieldNameNewFieldValueMap.put('Metric__c',metric.keyValues);
                validateSObjectFieldsAccess('Metric__c', metric.keyValues);
            }

        }

        public override void prepareUpdate() {
            try {
	            if(objectNameToFieldNameNewFieldValueMap.containsKey('Metric__c')) {
	                for(String fieldName : objectNameToFieldNameNewFieldValueMap.get('Metric__c').keySet()) {
	                    putSObjectValueAsCorrectType('Metric__c', fieldName, objectNameToFieldNameNewFieldValueMap.get('Metric__c'));
	                }
	                objectsToUpdate.put('Metric__c',contextRecord);
	            }
	        } catch (Exception e) {
	            apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Prepare update error: ' + e.getMessage());
	            throw new WSI_CTRL.APIException();
	        }
        }

        public override void executeDML() {
            if(objectsToUpdate.containsKey('Metric__c')) {
	            Metric__c metToUpdate = (Metric__c) objectsToUpdate.get('Metric__c');
	            upsert metToUpdate;
	        }
        }

        public override void prepareResponse() {
            super.prepareResponse();
        }

    }

    public class MetricRead extends WSI_MetricApiRequest {

        public override void prepareUpdate() {
            //Nothing to update
        }

        public override void validateData() {
            //Nothing to validate
        }

        public override void executeDML() {
            //Nothing to update
        }

        public override void prepareResponse() {

            objectNameToFieldNameNewFieldValueMap = new Map<String,Map<String,String>>();

            for (String metricKey : metricFieldMap.keySet()) {

                String fieldName = metricFieldMap.get(metricKey);
                Object fieldValue = contextRecord.get(fieldName);
                String fieldValueString  = ''+fieldValue;

                if (fieldValue != null) {
                    if (objectNameToFieldNameNewFieldValueMap.get('Metric__c') == null) {
                        objectNameToFieldNameNewFieldValueMap.put('Metric__c', new Map<String, String>());
                    }
                    objectNameToFieldNameNewFieldValueMap.get('Metric__c').put(fieldName, fieldValueString);
                }
            }

            super.prepareResponse();
        }

    }

    public class MetricCreate extends WSI_MetricApiRequest {

    }
}