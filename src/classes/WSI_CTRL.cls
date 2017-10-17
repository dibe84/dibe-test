@RestResource(urlMapping='/*')
global with sharing class WSI_CTRL {

    /* Classes and vars */
    public class APIException extends Exception {}

    public class APIResponse {
        public RestRequest apiRestRequest;
        public RestResponse apiRestResponse;
        public WS_Log__c apiLog;
        public APIError apiError;

        public APIResponse(RestRequest incRequest, RestResponse outResponse) {
            this.apiRestRequest = incRequest;
            this.apiRestResponse = outResponse;
            createLog();
        }

        // Creates the log object with initial request information
        private void createLog() {
            apiLog = new WS_Log__c();
            // Fill the log fields
            apiLog.ReqTime__c = Datetime.now();
            apiLog.HttpMethod__c = apiRestRequest.httpMethod == null ? '' : apiRestRequest.httpMethod;
            apiLog.CalloutName__c = getRequestURI(apiRestRequest);
            apiLog.EndPoint__c = System.Url.getSalesforceBaseURL().toExternalForm();
            apiLog.Request__c = apiRestRequest.requestBody.toString();
        }

        // Creates API error with detailed error information
        public void addAPIError(Integer statusCode, String code, String message, List<String> details) {
            this.apiError = new APIError(statusCode, code, message, details);
        }

        public void addAPIError(Integer statusCode, String code, String message) {
            this.apiError = new APIError(statusCode, code, message, new List<String>());
        }

        public void addAPIError() {
            this.apiError = new APIError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'Default error',new List<String>());
        }

        private void updateLogContent() {
            apiLog.Response__c = apiRestResponse.responseBody.toString();
            apiLog.StatusCode__c = apiRestResponse.statusCode;
            apiLog.Status__c = UTIL_WSC.statusMsg.get(Integer.valueOf(apiRestResponse.statusCode));
    		apiLog.Success__c = (apiRestResponse.statusCode == UTIL_WSC.HTTP_OK ? TRUE : FALSE);
            apiLog.ProcessedSuccessful__c = (apiRestResponse.statusCode == UTIL_WSC.HTTP_OK ? TRUE : FALSE);
            apiLog.ResponseTime__c = (Integer) (Datetime.now().getTime() - apiLog.ReqTime__c.getTime());
            apiLog.Error__c = apiError == null ? null : apiError.message;

            update apiLog;
        }

        public void setResponse(Map<String, Object> responseBodyMap) {
            Database.insert(apiLog);
            Map<String, Object> responseMap = new Map<String, Object>();
            responseMap.put('statusCode', responseBodyMap.size() == 0 ? String.valueOf(UTIL_WSC.HTTP_NOTMODIFIED) : String.valueOf(UTIL_WSC.HTTP_OK));
            responseMap.put('message',UTIL_WSC.statusMsg.get(Integer.valueOf(responseMap.get('statusCode'))));
            responseMap.put('logref',apiLog.Id);
            responseMap.putAll(responseBodyMap);
            apiRestResponse.responseBody = Blob.valueOf( JSON.serializePretty(JSON.deserializeUntyped(JSON.serializePretty(responseMap))) );
            apiRestResponse.StatusCode = (responseBodyMap.size() == 0 ? UTIL_WSC.HTTP_NOTMODIFIED : UTIL_WSC.HTTP_OK);
            updateLogContent();
        }

		public void linkLog(String sObjectName, Id parentId) {

			String fieldName = (sObjectName.endsWith('__c')) ? sObjectName : sObjectName + '__c';
			Boolean fieldExists = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap().containsKey(fieldName);
			if (fieldExists) {
				apiLog.put(fieldName, parentId);
			}
			apiLog.parentId__c = parentId;

		}

        public void finish() {
            apiRestResponse.addHeader('Content-Type', 'application/json');
            if(apiError != NULL) {
                apiRestResponse.responseBody = Blob.valueOf(JSON.serializePretty(apiError));
                apiRestResponse.StatusCode = Integer.valueOf(apiError.statusCode);
            }
        }
    }

    public class APIError {
        public String statusCode;
        public String code;
        public String message;
        public List<String> details;

        public APIError(Integer statusCode, String code, String message, List<String> details) {
            this.statusCode = String.valueOf(statusCode);
            this.code = code;
            this.message = message;
            this.details = details;
        }
    }

    public static void launchRequestSpecificMethod(APIResponse apiResp) {
        String requestURI = getRequestURI(apiResp.apiRestRequest);
        String method = apiResp.apiRestRequest.httpMethod;

        Pattern metricsPattern = Pattern.compile('api/v1/accounts/([a-zA-Z]{5})/(.+)/bookings/([a-zA-Z]{7})/(.+)/metrics/(\\d{4}-\\d{2}-\\d{2})');
        Pattern bookingsPattern = Pattern.compile('api/v1/accounts/([a-zA-Z]{5})/(.+)/bookings/([a-zA-Z]{7})/(.+)');
        Pattern accountPattern = Pattern.compile('api/v1/accounts/([a-zA-Z]{5})/(.+)');
        Pattern accountPatternV2 = Pattern.compile('api/v2/accounts/[a-zA-Z0-9]{15,18}');
        
        UTIL.log('REQUEST URL: '+requestURI);

        Matcher metricMatch = metricsPattern.matcher(requestURI);
        Matcher bookingMatch = bookingsPattern.matcher(requestURI);
        Matcher accountMatch = accountPattern.matcher(requestURI);
        Matcher accountMatchV2 = accountPatternV2.matcher(requestURI);
        
        if (metricMatch.matches()) {
            WSI_API_SFECG_Metric_v1.Metric metric = new WSI_API_SFECG_Metric_v1.Metric();

            metric.memberId = metricMatch.group(1);
            metric.accountId = metricMatch.group(2);
            metric.memberUnitId = metricMatch.group(3);
            metric.bookingId = metricMatch.group(4);
            metric.metricDateId = metricMatch.group(5);

            if (method == 'PUT') { WSI_API_SFECG_Metric_v1.process('MetricUpdate', apiResp, metric); return; }
            if (method == 'GET') { WSI_API_SFECG_Metric_v1.process('MetricRead', apiResp, metric); return; }

        }
        else if(bookingMatch.matches()) {
            WSI_API_SFECG_Booking_v1.Booking booking = new WSI_API_SFECG_Booking_v1.Booking();

            booking.memberId = bookingMatch.group(1);
            booking.accountId = bookingMatch.group(2);
            booking.memberUnitId = bookingMatch.group(3);
            booking.bookingId = bookingMatch.group(4);

            if (method == 'POST') { WSI_API_SFECG_Booking_v1.process('BookingInsert', apiResp, booking); return; }
            if (method == 'PUT') { WSI_API_SFECG_Booking_v1.process('BookingUpdate', apiResp, booking); return; }
            
        }else if( requestURI.contains('accounts') == TRUE || accountMatch.matches() ) {
        	Boolean isV1 = requestURI.contains('v1');
        	
        	if(isV1){
        		// create account class here
                if( accountMatch.matches() ) {
                    WSI_API_SFECG_Account_v1.InboundAccount account = new WSI_API_SFECG_Account_v1.InboundAccount();
                    account.member = accountMatch.group(1);
                    account.accountExtId = accountMatch.group(2);

                    if ( method == 'POST' ) { WSI_API_SFECG_Account_v1.process('AccountInsert', apiResp, account); return; }
                }

                if ( method == 'PUT' ) { WSI_API_SFECG_Account_v1.process('AccountUpdate', apiResp); return; }
            // v2 inbound api for GTAU memberunit 
        	}else{
        		
        		WSI_API_SFECG_Account_v2.InboundAccount account = new WSI_API_SFECG_Account_v2.InboundAccount();
        		if ( method == 'POST' ) { WSI_API_SFECG_Account_v2.process('AccountInsert', apiResp, account); return; }
        		if(accountMatchV2.matches()) { 
        			if ( method == 'PUT' ) { WSI_API_SFECG_Account_v2.process('AccountUpdate', apiResp); return; }
        		}
        	}
                

        } else if (requestURI.contains('invoices') == TRUE) {

                if (method == 'PUT') { WSI_API_SFECG_Invoice_v1.process('InvoiceUpdate', apiResp); return; }

        } else if (requestURI.contains('leads') == TRUE) {

                if (method == 'PUT') { WSI_API_SFECG_Lead_v1.process('LeadOperation', apiResp); return; }

        }

        apiResp.addApiError(UTIL_WSC.HTTP_NOTFOUND,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_NOTFOUND),'Unknown execution method'); // Error - no method to be executed
    }

    @HttpPost
    global static void postRequest() {
        APIResponse apiResp = new APIResponse(RestContext.request, RestContext.response);
        try {
            launchRequestSpecificMethod(apiResp);
        } catch (Exception e) {
            apiResp.addApiError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'Unexpected exception: ' + e.getMessage() + e.getStackTraceString());
        } finally {
            apiResp.finish();
        }
    }

    @HttpPut
    global static void putRequest() {
        APIResponse apiResp = new APIResponse(RestContext.request, RestContext.response);
        try {
            launchRequestSpecificMethod(apiResp);
        } catch (Exception e) {
            apiResp.addApiError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'Unexpected exception: ' + e.getMessage() + e.getStackTraceString());
        } finally {
            apiResp.finish();
        }
    }

    @HttpGet
    global static void getRequest() {
        APIResponse apiResp = new APIResponse(RestContext.request, RestContext.response);
        try {
            launchRequestSpecificMethod(apiResp);
        } catch (Exception e) {
            apiResp.addApiError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'Unexpected exception: ' + e.getMessage() + e.getStackTraceString());
        } finally {
            apiResp.finish();
        }
    }



    // Gets request URI
    public static String getRequestURI(RestRequest request) {
        String requestURI = request.requestURI.substring(1);
        if (requestURI.right(1) == '/') {
            requestURI = requestURI.substring(0, requestURI.length()-1);
        }
        return requestURI;
    }
}