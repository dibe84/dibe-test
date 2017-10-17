public with sharing class UTIL_WSC {

    // When multiple callouts are done in 1 context, instantiate a single (static) bulkHandler to handle DML
    // the client instantiating the bulkHandler is responsible for calling the commitAll() method after callouts have been done.
    // When no bulkHandler is created from outside, the request will create its own, then effectively not running in BulkMode
	public static UTIL_WSC_Bulk bulkHandler;
    public static Boolean bulkMode = False;
	public static Integer defaultWSSCPriority = null;
	public static Integer testStatusCode = 200; //For testing purpose, in order to get various Result based on Status Code per web service call out
	
    public virtual class WSC_Request implements iWSC_Request {
		public String baseEndpoint;
        public String wsUser;
        public String wsKeystring;
        public String endpointURLParameters;
        public sObject contextRecord;
        public UTIL_Fieldmapper mapper;
        public WSC_Result result;
        public WSC_ResultHandler handler;
        public WS_Log__c log;
        public WS_Log__c latestSuccessfulProcessedLog;
        public Map<String,WSC_Mock> mockMap;
        public String uniqueCalloutId;
        public Boolean isContextRecordDeleted;
		public Map<String, Object> mAdditionalParams;

		//public Map<String, String> headers; // header parameters
		private Set<String> reqHeaders; // keeping track of the headers set on the request object. The http request object does not support getHeaderKeys()...
        private String methodName;
        private String apiName;
        private String calloutName;
        private Http h;
		private HttpRequest req;
        private Webservice_Settings__c wss;
        private Boolean isCalled = false;
        private Boolean handleOwnDML = false;
        private Integer responseTime;
		//set default request time out
 		private Integer httpTimeout = 120000; 
        // constructor
        public WSC_Request() { // initialize objects
        	this.h = new Http();
            this.req = new HttpRequest();
            this.req.setTimeout(this.httpTimeout);
            this.mapper = new UTIL_FieldMapper();
			this.reqHeaders = new Set<String>();
            this.mockMap = new Map<String, WSC_Mock>();
            this.mockMap.put('default',new WSC_Mock('TESTMOCK Not found',404,'{"error":"no mock context selected in test class"}'));
            this.log = new WS_Log__c();
			this.mAdditionalParams = new Map<String, Object>();
        }

        // default methods
        public void setCalloutDetails(String methodName, String apiName)	{
            this.methodName = methodName;
            this.apiName = apiName;
            this.calloutName = this.apiName+':'+this.methodName;
        }
        public void setEndpoint(String endpoint) 							{ this.req.setEndpoint(endpoint); }
        public void setHttpMethod(String httpMethod) 						{ this.req.setMethod(httpMethod); }
        public String getHttpMethod() 										{ return this.req.getMethod(); }
        public void setBody(String body) 									{ if ( !String.isBlank(body) ) this.req.setBody(body); }
        public void setHeader(String key, String value)						{
            if ( !String.isBlank(key) && !String.isBlank(value)) this.req.setHeader(key,value);
            this.reqHeaders.add(key);
        }
        public void setResultClass(String className) {
            Type t = Type.forName(className);
            if (t == null) throw new UTIL_WSC_Exception('ResultClass cannot be instantiated: '+className);
            this.result = (WSC_Result) t.newInstance();
        }
        public void setHandlerClass(String classname) {
        	Type t = Type.forName(className);
            if (t == null) throw new UTIL_WSC_Exception('ResultClass cannot be instantiated: '+className);
            this.handler = (WSC_ResultHandler) t.newInstance();
        }
        public void getWsSettings(String apiName, String memberUnitId) {
        	String wsSettingInclPostfix ='';
            if (memberUnitId != null ) wsSettingInclPostfix += memberUnitId + '_';
            wsSettingInclPostfix += apiName + '_' + (UTIL.isSandbox()?'UAT':'PROD');
            this.wss = Webservice_Settings__c.getInstance(wsSettingInclPostfix);
            if (wss != null) { // callout should not be made if wss not registered....
                this.baseEndpoint	= (!Test.IsRunningTest())?(wss.UseProxy__c?wss.EndpointProxy__c:wss.Endpoint__c):'testendpoint';
                this.endpointURLParameters = (!Test.IsRunningTest())?(wss.EndpointURLParameters__c == null?'':wss.EndpointURLParameters__c):'';
                this.wsUser   		= (!Test.IsRunningTest())?wss.User__c:'testuser';
                this.wsKeystring 	= (!Test.IsRunningTest())?wss.Key__c:'testkey';
            }
        }
		
		public Boolean checkWsSettings(){
			return wss != null ;
        }
		
        public Boolean isRegistered() { // callout is allowed for the contextRecord
            if (this.wss ==null) {
                UTIL.log('WebService Settings not registered.');
                return FALSE;
            }
            return TRUE;
        }

        public WS_ScheduledCallout__c getScheduledCallout() {
            WS_ScheduledCallout__c wssc = new WS_ScheduledCallout__c();
            wssc.Status__c = 'Queued';
            wssc.API__c = this.apiName;
			wssc.Priority__c = getWSSCPriority();
            wssc.Method__c = this.methodName;
            wssc.RecordId__c = this.contextRecord.Id;
            wssc.UniqueKey__c = this.uniqueCalloutId;
            //wssc.Attempts__c = 0;
            return wssc;
        }

		public Integer getWSSCPriority() {
			Integer orgDefault = 1000;
			// If default has been already set, return it
			if(defaultWSSCPriority != null) return defaultWSSCPriority;
			// Access custom settings to get priority value
			CalloutPriority__c userCalloutPriority = CalloutPriority__c.getInstance(UserInfo.getProfileId());
			if(userCalloutPriority.Multiplier__c != null) {
				return (Integer)(orgDefault * userCalloutPriority.Multiplier__c);
			}

			return orgDefault;
		}

        public WSC_Result call() {
            if (this.isCalled) throw new UTIL_WSC_Exception('Already called, cannot call twice.');
            this.isCalled = TRUE;
            if (this.result == null) throw new UTIL_WSC_Exception('ResultClass not instantiated, please use "setResultClass" in client.');

            // check if the record is ready for a callout
            if ( !this.readyForCallout() ) {
                this.result.init(NOTREADYFORCALLOUT ,'Not ready', null, null);
            } else  {
                setBody( this.getBody() );
                initLog();

                if (this.handler == null) this.handler = new WSC_ResultHandler(); // if no handler is specified, default is used

                if (this.wss == null) {
                    this.result.init(NOTREGISTERED ,'Not registered', null, null);
                } else if ( !this.mapper.mandatoryFieldsNotNull() ) { // check mandatory fields
                    List<String> mandatoryFieldsAreNullErrors = new List<String> {'Mandatory fields in request are null: '};
                    mandatoryFieldsAreNullErrors.addAll(this.mapper.mappingErrors);
                    this.result.init(FIELDMAPPINGERROR, mandatoryFieldsAreNullErrors, null, null); // missing fields, not processed, no retry needed
                }
                else {
                    HttpResponse response;
                    try {
                        if ( !Test.IsRunningTest() && !FLAG_USEMOCK ) {
                            Datetime start = Datetime.now();
                            response = this.h.send(req); // make the callout
                            Datetime finish = Datetime.now();
                            this.responseTime = (Integer)( finish.getTime() - start.getTime() ) ;
                        }
                        else {
                            response = getMockResponse(); // running test
                            UTIL.log('TESTMODE: ' + TESTMOCK + ' : ' + response);
                        }
                        if (response == null) this.result.init(UNKNOWNERROR, 'Unknown Error - no HTTP response',response,null);  // this should not occur without throwing an exception...
						system.debug('---------- Caller: '+this.calloutName + ' > '+ response + ' > Body:\n ' + response.getBody());
                        this.result.init(response.getStatusCode(), '', response, null); // valid response is returned
                    } catch (System.CalloutException ex) {
                        String errorMsg = 'System.CalloutException: ' + ex.getMessage();

                        if (errorMsg.contains('Read timed out'))
                            this.result.init(TIMEOUT, errorMsg, response, ex);
                        else
                            this.result.init(CALLOUTEXCEPTION ,errorMsg, response, ex);
                    } catch (Exception ex) {
                        String errorMsg = 'Error in callout: '+this.calloutName+'. Message: '+ex.getMessage()+' ('+ex.getTypeName()+').';
                        this.result.init(GENERALEXCEPTION, errorMsg, response, ex);
                    }
                }

                this.handler.init(this, this.result);
                this.handler.handle();
				this.createWsLogs();
                
                return this.result;

            }

            return null;

        }
		
		public virtual void createWsLogs() {
			logCall(this.log, this, this.result);

            Attachment att1 = getAttachment(getRawRequest(this),'Request.txt', this.log.Id);
            Attachment att2 = getAttachment(getRawResponse(this.result),'Response.txt', this.log.Id);
            if(!this.log.CalloutName__c.contains('WSC_Tract:GetTractServiceCusFieldId'))
                UTIL_WSC.bulkhandler.logsAndAttachmentsToBeInserted.put(this.log, new List<attachment>{att1, att2});
			
			if(this.log.CalloutName__c.contains('WSC_Tract:ProductOperation') ||
				this.log.CalloutName__c.contains('WSC_Tract:GetAgreements')) 
			{
				return;
			}
			
			if (handleOwnDML) UTIL_WSC.bulkHandler.commitAll();
		}
        // overridable methods

        // override the init method on API or method level (or both) but make sure to call super.init() first, to always run parent level config first.
        public virtual void init(Id contextRecordId) {
          	this.contextRecord = UTIL.getCached(contextRecordId);
            if (this.contextRecord == null) {
                // Apparantly this record no longer exists, we skip this callout and add this record to a list of records to be deleted.
                this.isContextRecordDeleted = true;
                throw new UTIL_WSC_Exception('Context record is deleted or otherwise null: '+ contextRecordId);
            }
            this.uniqueCalloutId = '['+this.calloutName+']'+this.contextRecord.Id;

            // if no BulkHandler is set, create one and make sure to handle DML
            if ( UTIL_WSC.bulkHandler == null) {
                UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(new Set<Id> {contextRecord.Id} );
                handleOwnDML = TRUE;
            }

            if (UTIL_WSC.bulkhandler.latestSuccessfulProcessedLogMap.containsKey(contextRecordId)) {
				this.latestSuccessfulProcessedLog = UTIL_WSC.bulkhandler.latestSuccessfulProcessedLogMap.get(contextRecordId).get(this.calloutName);
            }
            this.setHeader('Runscope-Request-Port','5001'); // used for passthrough
        }

        public virtual Boolean 	readyForCallout() 		{ return TRUE; }// override with entry criteria in specific implementation, when these apply
        public virtual String 	getBody() 				{ return ''; } 	// override this method in specific implementation
        public virtual String 	getFormattedBody() 		{ return ''; } 	// override this method in specific implementation

		public virtual HttpResponse getMockResponse() {
            if ( this.mockMap.containsKey(UTIL_WSC.TESTMOCK) ) {
            	return this.mockMap.get(UTIL_WSC.TESTMOCK).getResponse();
            }
            return null;
	    }

        private String getLatestProcessedComparisonString() {
            if (this.latestSuccessfulProcessedLog != null) return this.latestSuccessfulProcessedLog.RelevantChangesCompareString__c;
            return null;
        }

        private void initLog() {
            if (this.contextRecord != null) this.log.ParentId__c = this.contextRecord.Id;
            this.log.ReqTime__c=Datetime.now();
            this.log.Request__c=this.getFormattedBody();
            this.log.RelevantChangesCompareString__c = this.mapper.getRelevantFieldComparisonString();
            this.log.CalloutName__c = this.calloutName;
        }

	}

    public virtual class WSC_Result implements iWSC_Result {
        public Datetime timestamp 		{get; private set;}
        public Integer statusCode 		{get; private set;}
        public String status 			{get; private set;}
        public String errorMsg 			{get; private set;}
        public String stackLog 			{get; private set;}
        public HttpResponse resp 		{get; private set;}
        public FollowUpCode followUp	{get; private set;}


        public Boolean processedSuccessful = FALSE;	// should be set TRUE when backend processed the call correctly
        public Boolean retryCallout = FALSE;		// should be set TRUE when the callout should be retried due to a problem
        public Boolean success = FALSE;				// should be set TRUE when the callout was processed OK and result was succesful
        public Boolean urlEncode = TRUE;            // should be set TRUE when response body should be URL encoded before saving it on WS Log record.

        private Map<String,Object> responseData;

        private void init(Integer statusCode, List<string> errorMsgs, HttpResponse resp, Exception ex) {
			this.resp = resp;
            this.timestamp = Datetime.now();
            this.statusCode = statusCode;
            this.errorMsg = '';
            if (ex != null) this.stackLog = ex.getStackTraceString();

            // set status messages
            if ( statusMsg.containskey(statusCode) ) {
                this.status = statusMsg.get(statusCode);
            } else {
            	if (resp != null) this.status = resp.getStatus();
            }

            // set follow up statusCode
            if (followUpMap.containsKey(statusCode)) {
            	this.followUp = followUpMap.get(this.statusCode);
            } else {
                if (Math.round(this.statusCode/100)==5) this.followUp = FollowUpCode.FAILED_RETRY; // Server side errors will be retried
            }
			// defaults are FALSE
            if (this.followUp == FollowUpCode.FAILED_RETRY) { this.retryCallout = TRUE; }
            if (this.followUp == FollowUpCode.PROCESSED_OK ) {this.processedSuccessful = TRUE; this.success = TRUE; }
            if (this.followUp == FollowUpCode.PROCESSED_NOK ) {	this.processedSuccessful = TRUE;}

            // fill error message string
            for (String s : errorMsgs) {
            	if ( !String.isBlank(s) ) this.errorMsg += s +'\n';
            }

            // Parse the response data. getResponseData is implemented in the specific API, if this fails it will fill with an error.
            if (resp != null) {
                try {
                    this.responseData = getResponseData();
                } catch (Exception e) {
                    this.errorMsg += 'Error processing response data. ' +e.getMessage()+' '+e.getTypeName()+ '\n';
                    this.responseData = new Map<String,Object>();
                    this.responseData.put('ERROR', this.errorMsg );
                    this.responseData.put('BODY', resp.getBody());
                }
            }
		}

        private void init(Integer statusCode, string errorMsg, HttpResponse resp, Exception ex) {init(statusCode, new List<string>{errorMsg}, resp, ex); } // handle single error...

        public httpResponse getResponse() { return this.resp; }

        // overridable
        public virtual String getFormattedBody() 		{ return ''; }
        public virtual Map<String,Object> getResponseData() 	{ return null; }
		public virtual Blob getBlobBody() { return null; }

    }

    public virtual class WSC_ResultHandler implements iWSC_ResultHandler {
    	public WSC_Request request;
        public WSC_Result result;
        public WS_Log__c log;

        public void init(WSC_Request request, WSC_Result result) {
			this.request = request;
            this.result = result;
            this.log = request.log;
		}

        public void logError(String errorMsg) {
        	this.result.errorMsg = errorMsg;
        }

        public virtual void handle() {}

    }

    public class WSC_Mock{
        public String status;
        public Integer statusCode;
        public String body;

        public WSC_Mock(String status, Integer statusCode, String body) {
            this.status = status;
            this.statusCode = statusCode;
            this.body = body;
        }

        HttpResponse getResponse() {
            HttpResponse resp = new HttpResponse();
            resp.setBody(this.body);
            resp.setStatus(status);
            resp.setStatusCode(statusCode);
            return resp;
        }
    }

    // helper methods
    public static void doUpdate(sObject so) {
    	UTIL_WSC.bulkHandler.addForUpdate(so);
    }

    public static void doUpdate(List<sObject> soList) {
        UTIL_WSC.bulkHandler.addForUpdate(soList);
    }

	public static void doInsert(sObject so) {
    	UTIL_WSC.bulkHandler.addForInsert(so);
    }

    public static void doInsert(List<sObject> soList) {
        UTIL_WSC.bulkHandler.addForInsert(soList);
    }

    public static WSC_Request getWSC_Request(String wsMethodClassName) {
        Type t = Type.forName(wsMethodClassName);
        if (t == null) throw new UTIL_WSC_Exception('wsMethodClassName cannot be instantiated: '+wsMethodClassName);
        WSC_Request wsRequest = (WSC_Request) t.newInstance();
        return wsRequest;
    }

    public static void checkForProcessing(String wsMethodClassName, List<sObject> contextRecords, List<WS_ScheduledCallout__c> wsscToUpsert) {
        Set<Id> contextRecordIds = (new Map<Id,sObject>(contextRecords)).keySet();
        checkForProcessing(wsMethodClassName, contextRecordIds, wsscToUpsert);
    }

    public static void checkForProcessing(String wsMethodClassName, Set<Id> contextRecordIds) {
    	List<WS_ScheduledCallout__c> wsscToUpsert  = new List<WS_ScheduledCallout__c>();
        UTIL_WSC.checkForProcessing(wsMethodClassName, contextRecordIds, wsscToUpsert);
        upsert wsscToUpsert UniqueKey__c;
    }

    public static void checkForProcessing(String wsMethodClassName, Set<Id> contextRecordIds, List<WS_ScheduledCallout__c> wsscToUpsert) {

        for (Id contextRecordId : contextRecordIds) {
            WSC_Request wsRequest = getWSC_Request( wsMethodClassName);
            wsRequest.init(contextRecordId);
            UTIL.log('Running check for: '+contextRecordId);
            if (wsRequest.wss != null ) { // only go ahead if there is a Webservice_Settings__c config setting registered for this Member(Unit)

                if ( wsRequest.readyForCallout() ) { // this check is a virtual method that can be overrided per specific API or method
                    String newFieldChangeCompareString = wsRequest.mapper.getRelevantFieldComparisonString();
                    String oldFieldChangeCompareString = wsRequest.getLatestProcessedComparisonString();

                    if (newFieldChangeCompareString != oldFieldChangeCompareString) wsscToUpsert.add( wsRequest.getScheduledCallout() );
                }
            }
        }
    }

    public static void forceProcessing(String wsMethodClassName, List<sObject> contextRecords, List<WS_ScheduledCallout__c> wsscToUpsert) {
        Set<Id> contextRecordIds = (new Map<Id,sObject>(contextRecords)).keySet();
        forceProcessing(wsMethodClassName, contextRecordIds, wsscToUpsert);
    }

    public static void forceProcessing(String wsMethodClassName, Set<Id> contextRecordIds, List<WS_ScheduledCallout__c> wsscToUpsert) {
        for (Id contextRecordId : contextRecordIds) {
            WSC_Request wsRequest = getWSC_Request( wsMethodClassName);
            wsRequest.init(contextRecordId);
            UTIL.log(wsRequest.wss);
            if (wsRequest.wss != null ) { // only go ahead if there is a Webservice_Settings__c config setting registered for this Member(Unit)
                if ( wsRequest.readyForCallout() ) { // this check is a virtual method that can be overrided per specific API or method
                    wsscToUpsert.add( wsRequest.getScheduledCallout() );
                }
            }
        }
    }

	public static string urlEncodeObject(object objectToEncode) {
        string urlEncodedString ='';
        String serializedObject = JSON.serialize(objectToEncode);
        Map<String,Object> deserializedObject = (Map<String,Object>) JSON.deserializeUntyped(serializedObject);

        for(String key : deserializedObject.keySet()) {
            if(urlEncodedString != '') urlEncodedString += '&';
            String value = string.valueOf(deserializedObject.get(key));
            value = value==null?'':EncodingUtil.urlEncode(value, 'UTF-8');
            key = EncodingUtil.urlEncode(key, 'UTF-8');

            urlEncodedString+= key+'='+value;
        }
        return urlEncodedString;
    }

    public static String getBasicAuthenticationKey(String key){
        return 'Basic ' + key;
    }

    public static String getBasicAuthenticationKey(String username, String password){
        return 'Basic ' + EncodingUtil.base64Encode(Blob.valueof(username+':'+password));
    }

	public static String processResponseBody(WSC_Result result) {
		String respBody = null;
		try {
			respBody = result.getFormattedBody();
		} catch (Exception e) {
			UTIL.log('Cannot get formatted body: ' + e.getMessage());
		}
		if(respBody == null) {
			try {
				respBody = result.resp.getBody();
			} catch(Exception e) {
				UTIL.log('Cannot get body from response: ' + e.getMessage());
			}
		}

		respBody = (respBody == null ? '' : respBody);
		respBody = respBody.length() > 125000 ? respBody.left(62500) + '\n\n=== CONTENT REMOVED PARTLY DUE TO LARGE MESSAGE ===\n\n' + respBody.right(62500) : respBody;

		// Don't return null, it might cause unwanted exceptions later on. Raw response is saved as attachment regardless.
		return respBody;
	}

    public static WS_Log__c logCall(WS_Log__c log, WSC_Request req, WSC_Result result) {
		String respBody = processResponseBody(result);

        log.HttpMethod__c = req.req.getMethod();
        log.EndPoint__c = (req.req.getEndpoint().length() > 255) ? req.req.getEndpoint().substring(0, 255) : req.req.getEndpoint();
        log.Additional_Information__c = req.req.getEndpoint();
        log.Response__c = respBody;
        log.StatusCode__c = result.statusCode;
        log.Status__c = result.status;
        log.Error__c = result.errorMsg;
        log.ResponseTime__c = req.ResponseTime;
        log.ProcessedSuccessful__c = result.processedSuccessful;
       
        log.IsLatestSuccessfullyFor__c = req.uniqueCalloutId;
        if (req.latestSuccessfulProcessedLog != null) {
            req.latestSuccessfulProcessedLog.IsLatestSuccessfullyFor__c = null;
            UTIL_WSC.bulkHandler.logsToBeUpdated.add(req.latestSuccessfulProcessedLog);
        }
        log.RetryCallout__c = result.retryCallout;
        log.Success__c = result.success;
        log.StackLog__c = result.stackLog;
        return log;
    }

    public static String getRawRequest(WSC_Request wsc_req) {
        if (wsc_req == null) UTIL.throwError('WSC_Request is null');
        if (wsc_req.req == null) return '<Empty>';
        String rawReq = wsc_req.req.toString()+'\n\n';
        for (String key : wsc_req.reqHeaders ) {
            if (key != null) rawReq += key +':'+wsc_req.req.getHeader(key)+'\n';
        }
        rawReq += '\n\n'+ wsc_req.req.getBody();
        return rawReq;
    }
    public static String getRawResponse(WSC_Result result) {
        if (result.resp == null) return '<Empty>';
        String rawResp = result.resp.toString()+'\n\n';
        for (String key : result.resp.getHeaderKeys() ) {
            if (key != null) rawResp += key +':'+result.resp.getHeader(key)+'\n';
        }
        rawResp += '\n\n'+ result.resp.getBody();
        return rawResp;
    }
    public static Attachment getAttachment(String body, String fileName, Id parentId) {
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf(body);
        attachment.Name = fileName;
        attachment.ParentId = parentId;
        return attachment;
    }

	public class UTIL_WSC_Exception extends Exception {}

    // Interfaces
    public interface iWSC_Request{
        void init(Id contextRecordId);
    }
    public interface iWSC_Result{
        HttpResponse getResponse();
        String getFormattedBody();
        Map<String,Object> getResponseData();
    }
    public interface iWSC_ResultHandler{
        void init(WSC_Request request, WSC_Result result);
        void handle();
    }

    // static properties and constants
    public static String TESTMOCK = 'default'; // Set in test method to select specific mock
    public static Boolean FLAG_USEMOCK = false; //Can be set to force mocks to be used in callouts for dev or debug purposes.

    // Status codes
    public static final Integer FIELDMAPPINGERROR = -1;
    public static final Integer TIMEOUT = -2;
    public static final Integer CALLOUTEXCEPTION = -3;
    public static final Integer NOTREGISTERED = -4;
    public static final Integer NOTREADYFORCALLOUT = -5;
    public static final Integer GENERALEXCEPTION = -9;
    public static final Integer UNKNOWNERROR = -99;
    public static final Integer HTTP_BADREQUEST = 400;
    public static final Integer HTTP_BADCREDENTIALS = 401;
    public static final Integer HTTP_FORBIDDEN = 403;
    public static final Integer HTTP_CONFLICT = 409;
    public static final Integer HTTP_NOTFOUND = 404;
    public static final Integer HTTP_SERVERERROR = 500;
    public static final Integer HTTP_OK = 200;
    public static final Integer HTTP_CREATED = 201;
    public static final Integer HTTP_NOCONTENT = 204;
    public static final Integer HTTP_NOTMODIFIED = 304;

    public enum FollowUpCode { FAILED_RETRY, PROCESSED_OK, PROCESSED_NOK }
    public static Map<Integer,FollowUpCode> followUpMap = New Map<Integer,FollowUpCode>{
        NOTREGISTERED => FollowUpCode.FAILED_RETRY,
        NOTREADYFORCALLOUT => FollowUpCode.PROCESSED_NOK,
        FIELDMAPPINGERROR => FollowUpCode.PROCESSED_NOK,
        HTTP_FORBIDDEN => FollowUpCode.FAILED_RETRY,
        HTTP_BADCREDENTIALS => FollowUpCode.FAILED_RETRY,
        HTTP_NOTFOUND => FollowUpCode.PROCESSED_NOK,
        UNKNOWNERROR => FollowUpCode.FAILED_RETRY,
        HTTP_SERVERERROR => FollowUpCode.FAILED_RETRY,
        TIMEOUT => FollowUpCode.FAILED_RETRY,
        CALLOUTEXCEPTION => FollowUpCode.FAILED_RETRY,
        GENERALEXCEPTION => FollowUpCode.FAILED_RETRY,
        HTTP_OK => FollowUpCode.PROCESSED_OK,
        HTTP_CREATED => FollowUpCode.PROCESSED_OK,
        HTTP_NOCONTENT => FollowUpCode.PROCESSED_OK,
        HTTP_BADREQUEST => FollowUpCode.PROCESSED_NOK,
        HTTP_CONFLICT => FollowUpCode.PROCESSED_NOK,
        HTTP_NOTMODIFIED => FollowUpcode.PROCESSED_OK
    };
    public static Map<Integer,String> statusMsg = New Map<Integer,String>{
        NOTREGISTERED => 'API Callout not registered for context record',
        NOTREADYFORCALLOUT => 'Callout could not be made, record not ready for callout',
        FIELDMAPPINGERROR => 'FIELDMAPPING ERROR',
        HTTP_FORBIDDEN => 'Forbidden',
        HTTP_BADCREDENTIALS => 'Bad Credentials',
        HTTP_NOTFOUND => 'Not Found',
        HTTP_SERVERERROR => 'Server Error',
        UNKNOWNERROR => 'Unknown Error',
        TIMEOUT => 'Timeout',
        CALLOUTEXCEPTION => 'Callout Exception',
        GENERALEXCEPTION => 'General Exception',
        HTTP_OK => 'OK',
        HTTP_CREATED => 'Created',
        HTTP_NOCONTENT => 'No Content',
        HTTP_BADREQUEST => 'Bad Request',
        HTTP_CONFLICT => 'Conflict',
        HTTP_NOTMODIFIED => 'Not Modified'
    };
	public static Boolean isSuccessStatusCode(Integer status_code){
		return status_code == HTTP_OK || status_code == HTTP_CREATED || status_code == HTTP_NOCONTENT;
	}
    // legacy
    public enum reqType { JSON, URLENCODED } // used in basicCallout implementation, will be deprecated
    public class basicCallout { // legacy implementation, please use WSC_Request/WSC_Response for new implementations
		// defaults
		public Integer httpTimeout;

		private Http h;
		private HttpRequest req;
		private String calloutName;
		public String mockResponseBody;
		public Boolean serveMock = false;
		public UTIL_WSC.reqType reqType;

		public Map<String, String> headers; // header parameters
		public Map<String, Object> params; // body parameters

		public basicCallout(String name, String endPoint, String httpMethod) {
			this.calloutName = name;
			this.req = new HttpRequest();
			this.req.setEndpoint(endPoint);
			this.req.setMethod(httpMethod);
			this.httpTimeout = 120000;

			this.params = new Map<String, Object>();
			this.headers = new Map<String, String>();
			h = new Http();
		}

		public HttpResponse call() {
			HttpResponse resp;

            setConfig();
			setHeaders();
            setParams();

			try {
            	if (!Test.IsRunningTest() && !serveMock ) resp = this.h.send(req);
            	else                        resp = getMockResponse(); // running test
	        } catch (Exception e) {
	            UTIL.log('Error in callout: '+this.calloutName+'. Message: '+e.getMessage());
	            throw new UTIL_WSC_Exception('Error in callout: '+this.calloutName+'. Message: '+e.getMessage());
	        }
	        return resp;
		}

        private void setConfig() {
            this.req.setTimeout(this.httpTimeout);

            if (this.reqType == UTIL_WSC.reqType.JSON) {
                this.headers.put('Content-Type', 'application/json');
            } else if (this.reqType == UTIL_WSC.reqType.URLENCODED) {
                this.headers.put('content-type', 'application/x-www-form-urlencoded');
            }
        }

        private void setHeaders() {
			for (String header : this.headers.keySet() ) this.req.setHeader(header,this.headers.get(header) ); // fill req headers from map
		}

        private void setParams() {
            if (this.params.size()>0) {

                if (this.reqType == UTIL_WSC.reqType.JSON) {
                    this.req.setBody( JSON.serialize(params) );
                } else if (this.reqType == UTIL_WSC.reqType.URLENCODED) {
                    this.req.setBody( urlEncodeObject(params) );
                }
            }
        }

		private HttpResponse getMockResponse() {
	        HttpResponse resp = new HttpResponse();
	        Map<String,String> mockResponses = new Map<String,String>();
	        if ( !String.isEmpty(this.mockResponseBody) ) resp.setBody(this.mockResponseBody);
	        resp.setStatus('OK');
	        resp.setStatusCode(200);
	        return resp;
	    }

        public void setBasicAuthentication(String key){
        	String authorizationHeader = 'Basic '+key;
        	headers.put('Authorization', authorizationHeader);
        }
	} // legacy implementation, please use WSC_Request/WSC_Response for new implementations

	// Sort - related
	public static List<WS_ScheduledCallout__c> sortAccordingToPriority(List<WS_ScheduledCallout__c> wsscList) {
		if(wsscList == null || wsscList.size() == 0) return wsscList;

		List<WS_ScheduledCallout__c> wsscListToSort = wsscList;
		// Sort by priority field on WSSC first
		wsscListToSort = sortByPriorityConfig(wsscListToSort);
		wsscListToSort = sortByPriorityField(wsscListToSort);

		return wsscListToSort;
	}

	private static List<WS_ScheduledCallout__c> sortByPriorityField(List<WS_ScheduledCallout__c> wsscList) {
		if(wsscList == null || wsscList.size() == 0) return wsscList;
		Map<Id,WS_ScheduledCallout__c> wsscPrioMap = new Map<Id,WS_ScheduledCallout__c>();
		Map<Id,WS_ScheduledCallout__c> wsscOtherMap = new Map<Id,WS_ScheduledCallout__c>();
		for(WS_ScheduledCallout__c wssc : wsscList) {
			if(wssc.Prioritized__c == TRUE) {
				wsscPrioMap.put(wssc.Id,wssc);
			} else {
				wsscOtherMap.put(wssc.Id,wssc);
			}
		}
		wsscList = wsscPrioMap.values();
		wsscList.addAll(wsscOtherMap.values());
		return wsscList;
	}

	private static List<WS_ScheduledCallout__c> sortByPriorityConfig(List<WS_ScheduledCallout__c> wsscList) {
		if(wsscList == null || wsscList.size() == 0) return wsscList;

		String wsscObjectPriorityStr = UTIL.getConfig('WSSCObjectPriority');
		List<String> objectPriorityList = (wsscObjectPriorityStr != null ? wsscObjectPriorityStr.split(';') : new List<String>());
		if(objectPriorityList == null || objectPriorityList.size() == 0) return wsscList;

		Map<Id,WS_ScheduledCallout__c> wsscPrioMap = new Map<Id,WS_ScheduledCallout__c>();
		Map<Id,WS_ScheduledCallout__c> wsscOtherMap = new Map<Id,WS_ScheduledCallout__c>();
		for(String objName : objectPriorityList) {
			for(WS_ScheduledCallout__c wssc : wsscList) {
				if(wssc.RecordId__c == null) continue;
				if(GW_sObject.getobjectNameFromId(wssc.RecordId__c) == objName) {
					wsscPrioMap.put(wssc.Id,wssc);
				}
			}
		}
		for(WS_ScheduledCallout__c wssc : wsscList) {
			if(!wsscPrioMap.containsKey(wssc.Id)) {
				wsscOtherMap.put(wssc.Id,wssc);
			}
		}
		wsscList = wsscPrioMap.values();
		wsscList.addAll(wsscOtherMap.values());
		return wsscList;
	}
	
	/**
	 Bunhor @20-Feb-17: Get Authorization header for Digest
	 Ref: https://en.wikipedia.org/wiki/Digest_access_authentication
	 */  
	public static String getDigestAuthorization(String username, String password, String fullEndpoint, String method) {
		// First call get some values
		Map<String, String> mAttrValue = UTIL_WSC.getDigestHeaderAuthenticate(fullEndpoint, method);
		
		String realm 	= mAttrValue.get('realm');
    	String qop 		= mAttrValue.get('qop');
    	String nonce 	= mAttrValue.get('nonce');
    	String opaque 	= mAttrValue.get('opaque');
    	 
    	String uri = fullEndpoint;
    	String nc = '00000001';
    	String cnonce = UTIL_WSC.computeDigest(System.now().format('EEE MMM dd HH:mm z yyyy'));
    	
    	String HA1;
    	if(mAttrValue.get('algorithm') == null || mAttrValue.get('algorithm').touppercase() == 'MD5') {
    		HA1 = UTIL_WSC.computeDigest(username + ':' + realm + ':' + password);
    	} else {
    		// HA1=MD5(MD5(username:realm:password):nonce:cnonce)
    	}
    	
    	String HA2;
    	if(qop == null || qop == 'auth') {
    		HA2 = UTIL_WSC.computeDigest(method + ':' + uri);
    	} else {
    		// HA2=MD5(method:digestURI:MD5(entityBody))
    	}
    	
    	String response;
    	if(qop == 'auth' || qop == 'auth-int') {
    		response = UTIL_WSC.computeDigest(HA1 + ':' + nonce + ':' + nc + ':' + cnonce + ':' + qop + ':' + HA2);
    	} else {
    		response = UTIL_WSC.computeDigest(HA1 + ':' + nonce + ':' + HA2);
    	}
    	
    	mAttrValue.put('username', username);
    	mAttrValue.put('uri', uri);
    	mAttrValue.put('nc', nc);
    	mAttrValue.put('cnonce', cnonce);
    	mAttrValue.put('response', response);
    	mAttrValue.put('algorithm', 'MD5');
    	
    	String auth_return = 'Digest ';
    	for(String name : mAttrValue.keySet()) {
    		String value = mAttrValue.get(name);
    		if(name != 'nc' && name != 'qop') {
    			value = '"' + value + '"';
    		}
    		auth_return += (name + '=' + value +',');
    	}
    	return auth_return.removeEnd(',');
	}
	private static Map<String, String> getDigestHeaderAuthenticate(String endpoint, String method) {
		UTIL_WSC.basicCallout co = new UTIL_WSC.basicCallout('getDigestHeaderAuthenticate', endpoint, method);
    	HttpResponse resp = co.call();
    	String res_auth = resp.getHeader('WWW-Authenticate');
    	
    	Map<String, String> mAttrValue = new Map<String, String>();
    	if(String.isNotBlank(res_auth)) {
	    	for(String attr : res_auth.replace('Digest ', '').split(',')) {
	    		String name = attr.split('=')[0];
	    		String value = attr.replace(name + '=', '').removeStart('"').removeEnd('"');
	    		mAttrValue.put(name, value);
	    	}
    	}
    	return mAttrValue;
	}
	private static String computeDigest(String paramString) {
        Blob hash = Crypto.generateDigest('MD5',Blob.valueOf(paramString));
        return EncodingUtil.convertToHex(hash); 
    }
	public static Object getResponseField(String fieldPath, Object response) {
		Map<String, Object> resMap = (Map<String, Object>) response;
		
		if(fieldPath.contains('/')) {
			String f = fieldPath.split('/')[0]; 
			Object obj = resMap.get(f);
			
			if(obj == null) return null;
			return getResponseField(fieldPath.removeStart(f+'/'), obj);
		}
		return resMap.get(fieldPath);
	}

}