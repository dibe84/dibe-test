/**
 * Bunhor @01-Mar-17: Freespee Integration
 */
public with sharing class WSC_Freespee {
	
    public static final String APINAME = 'WSC_Freespee';
    private static final Webservice_Settings__c WS = Webservice_Settings__c.getInstance(APINAME+ '_' + (UTIL.isSandbox() ? 'UAT' : 'PROD'));
	private static final String ENDPOINT = WS == null ? null : WS.Endpoint__c;
    private static final string USER = WS == null ? null : WS.User__c;
    private static final string PASS = WS == null ? null : WS.Key__c;
    
    private static Account acc; // WSC_Freespee.acc
    
    /// ====================== LOGIC METHODS ====================== 
    public static String trackThisAccountPhone(Id accId) {
    	// ----Some variable that will be set----
    	Integer customerId;
    	Integer sourceId;
    	String trackingNumber;
    	String errors;
    	
    	// -----Caching---
    	Util.cache(GW_Account.getList(new Set<Id> {accId}, new List<String> {'Portal_User__r.Email'}));
    	WSC_Freespee.acc = (Account) Util.getCached(accId);
    	
    	// ----Some validations-----
    	if(acc.Phone == null) return 'Phone is required!';
    	else if(acc.LocalPlatformId__c == null) return 'Local Platform Id is required!';
    	
    	// Since we are callout many times, UTIL_WSC.bulkHandler must be set. And, we have to use UTIL_WSC.bulkHandler.commitAll() for creating calls Logs
    	UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(new Set<Id> {accId});
    	
    	// If the account not yet linked to a customer, link it.
    	if(Acc.CustomerId__c == null) {
    		// Callout to create a customer.
    		UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Freespee.CustomerRequest');
	    	req.init(accId); 
	        UTIL_WSC.WSC_Result resNewCust = req.call();
			
	        if(resNewCust.statusCode == 200) {
	        	Map<String,Object> custMap = WSC_Freespee.getObjectData(resNewCust.getResponseData().get('customers'));
	            customerId = custMap.get('customer_id') == null ? null : Integer.valueOf(custMap.get('customer_id'));
	        } else {
	        	errors = WSC_Freespee.getErrors(resNewCust);
	        }
    	} else {
    		customerId = Integer.valueOf(Acc.CustomerId__c); 
    	}
    	
    	// If creating new customer without any errors, create a source.
    	if(errors == null) {
	    	UTIL_WSC.WSC_Request reqSrc = UTIL_WSC.getWSC_Request('WSC_Freespee.SourceRequest');
	    	reqSrc.init(accId);
	    	reqSrc.mapper.mappingElements.add(new UTIL_Fieldmapper.mappedField('customer_id', customerId, 'Integer', 10, TRUE, TRUE));
	        UTIL_WSC.WSC_Result resNewSrc = reqSrc.call();
	        if(resNewSrc.statusCode == 200) {
	        	Map<String,Object> custMap = WSC_Freespee.getObjectData(resNewSrc.getResponseData().get('sources'));
		        sourceId = custMap.get('source_id') == null ? null : Integer.valueOf(custMap.get('source_id'));	
		        trackingNumber = String.valueOf(custMap.get('destnr'));
	        } else {
	            errors = WSC_Freespee.getErrors(resNewSrc);
	        }
    	}
    	
    	// Update account with values returned
    	Account accUpdate = new Account(id = WSC_Freespee.acc.id);
    	Boolean isUpdate = false;
    	if(customerId != null) {
    		accUpdate.CustomerId__c = customerId;
    		isUpdate = true;
    	}
    	if(sourceId != null && trackingNumber != null) {
    		accUpdate.SourceId__c = sourceId;
    		accUpdate.CallTrackingPhoneNumber__c = trackingNumber;
    		isUpdate = true;
    	}
    	if(isUpdate) update accUpdate;
    	
    	// Commit/create logs
    	UTIL_WSC.bulkHandler.commitAll();
    	return errors;
    }  
    
    
    public static String unTrackThisAccountPhone(Id accId) {
    	// -----Caching---
    	Util.cache(GW_Account.getList(new Set<Id> {accId}, new List<String> {'Portal_User__r.Email'}));
    	WSC_Freespee.acc = (Account) Util.getCached(accId);
    	
    	// ----Some validations-----
    	if(WSC_Freespee.acc.CallTrackingPhoneNumber__c == null) return 'This account has no tracking number!';
    	else if(WSC_Freespee.acc.SourceId__c == null) return 'This account does not linked to any number!';
    	
    	UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Freespee.SourceDelRequest');
    	req.init(accId);
        UTIL_WSC.WSC_Result res = req.call();
		
        if(res.statusCode == 200) {
            update new Account(Id = WSC_Freespee.acc.id, SourceId__c = null, CallTrackingPhoneNumber__c = null);
        }else{
            return WSC_Freespee.getErrors(res);
        }
        return null;// no any errors occur
    }  
    
    // ====================== GENERIC CLASSES====================== 
    
	public virtual class GenericRequest extends UTIL_WSC.WSC_Request {
		public virtual override void init(Id contextRecordId) {
            super.init(contextRecordId);
            this.setHeader('Accept','application/json');
			this.setHeader('Accept-Encoding','compress, gzip');
            this.setHeader('Content-Type', 'application/x-www-form-urlencode');
            this.setHeader('Accept-Charset','utf-8');
            this.setHeader('Date', Datetime.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z'));
            this.getWsSettings(APINAME, null); // (String)this.contextRecord.get('MemberId__c')
        }
        public virtual override Boolean readyForCallout() { return TRUE; } // override with entry criteria in specific implementation, when these apply

		public override String getBody() {
			Map<String,Object> output = this.mapper.getOutputMap();
			String body = '';
			if (output != null) {
				for(String key : output.keyset()) {
					String val = output.get(key) == null ? '' : EncodingUtil.urlEncode(String.valueOf((output.get(key))), 'UTF-8');
					body += (key + '=' + val + '&');
				}
				body = body.removeEnd('&');
			}
			return body;
		}
		
        public override String getFormattedBody() {
        	return this.getBody();
        }
        
        
	}
    
    public virtual class GenericResult extends UTIL_WSC.WSC_Result {
    	public override String getFormattedBody() {
            Map<String,Object> resp = this.getResponseData();
            if (resp != null) {
                Map<String,Object> reversedMap = new Map<String,Object>();
                List<String> keys = new List<String>(resp.keySet());
                
                for (Integer i = keys.size()-1; i >= 0; i--  ) {
                    reversedMap.put(keys[i], resp.get(keys[i]));
                }
                return JSON.serializePretty(reversedMap);
            } else return '<Empty>';

        }
        
        public override Map<String,Object> getResponseData() {
            try {
                if (resp !=null && !String.isBlank(resp.getBody()) )
                    return (Map<String,Object>) JSON.deserializeUntyped(resp.getBody());
                else
                    return null;
            } catch (Exception e) {
                String errorMsg = 'Error processing response data. ' +e.getMessage()+' '+e.getTypeName()+ '\n';
                Map<String, Object> responseData = new Map<String,Object>();
                responseData.put('ERROR', e.getMessage());
                responseData.put('BODY', resp.getBody());
                responseData.put('message', errorMsg);
                return responseData;
            }
		}
    }
    
	// ====================== REQUESTS ======================
	
	public class CustomerRequest extends WSC_Freespee.GenericRequest {
		
		public override void init(Id contextRecordId) {
			this.setCalloutDetails(WSC_Freespee.APINAME, 'CustomerRequest');
			super.init(contextRecordId);
			this.mapper.mappingElements = WSC_Freespee.getMapper_NewCustomer(contextRecordId);
			this.setResultClass('WSC_Freespee.GenericResult');
			this.setHandlerClass('UTIL_WSC.WSC_ResultHandler');
			this.mockMap.putAll(WSC_Freespee.getMocks_NewCustomer());
			String fullEnp = WSC_Freespee.ENDPOINT + 'customers';
			this.setEndpoint(fullEnp);
			this.setHttpMethod('POST');
			this.setHeader('Authorization', UTIL_WSC.getDigestAuthorization(USER, PASS, fullEnp, 'POST'));
		}
	}
	
	public class SourceRequest extends WSC_Freespee.GenericRequest {
		
		public override void init(Id contextRecordId) {
			this.setCalloutDetails(WSC_Freespee.APINAME, 'SourceRequest');
			super.init(contextRecordId);
			
			this.mapper.mappingElements = WSC_Freespee.getMapper_NewSource(contextRecordId);
			this.setResultClass('WSC_Freespee.GenericResult');
			this.setHandlerClass('UTIL_WSC.WSC_ResultHandler');
			this.mockMap.putAll(WSC_Freespee.getMocks_NewSource());
			String fullEnp = WSC_Freespee.ENDPOINT + 'sources';
			this.setEndpoint(fullEnp);
			this.setHttpMethod('POST');
			this.setHeader('Authorization', UTIL_WSC.getDigestAuthorization(USER, PASS, fullEnp, 'POST'));
		}
	}
	
	public class SourceDelRequest extends WSC_Freespee.GenericRequest {
		
		public override void init(Id contextRecordId) {
			this.setCalloutDetails(WSC_Freespee.APINAME, 'SourceDelRequest');
			super.init(contextRecordId);
			this.mapper.mappingElements = WSC_Freespee.getMapper_DelSource(contextRecordId);
			this.setResultClass('WSC_Freespee.GenericResult');
			this.setHandlerClass('UTIL_WSC.WSC_ResultHandler');
			this.mockMap.putAll(WSC_Freespee.getMocks_DelSource());
			String fullEnp = WSC_Freespee.ENDPOINT + 'sources/' + this.contextRecord.get('SourceId__c');
			this.setEndpoint(fullEnp);
			this.setHttpMethod('DELETE');
			this.setHeader('Authorization', UTIL_WSC.getDigestAuthorization(USER, PASS, fullEnp, 'DELETE'));
		}
	}

	// ====================== MAPPERS ======================
	
	private static List<UTIL_Fieldmapper.mappedElement> getMapper_NewCustomer(Id accId) {
		//Account acc = (Account) Util.getCached(accId);
		List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
		elements.add( new UTIL_Fieldmapper.mappedField('name', acc.Name, 'String', 255, TRUE, TRUE) );
		elements.add( new UTIL_Fieldmapper.mappedField('custnr', acc.LocalPlatformId__c, 'String', 4, TRUE, TRUE) );
		elements.add( new UTIL_Fieldmapper.mappedField('email', acc.Portal_User__r.Email, 'String', 255, FALSE, TRUE) );
		return elements;
	}
	
	private static List<UTIL_Fieldmapper.mappedElement> getMapper_NewSource(Id accId) {
		//Account acc = (Account) Util.getCached(accId);
		List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
		//elements.add( new UTIL_Fieldmapper.mappedField('customer_id', 806134, 'Integer', 10, TRUE, TRUE) ); // should be added at real time use
		elements.add( new UTIL_Fieldmapper.mappedField('name', 'automobile.it', 'String', 30, TRUE, TRUE) );
		elements.add( new UTIL_Fieldmapper.mappedField('phonenr', acc.Phone, 'String', 30, TRUE, TRUE) ); // Ex: '+39085593300001'
		elements.add( new UTIL_Fieldmapper.mappedField('email', acc.Portal_User__r.Email, 'String', 255, FALSE, TRUE) );
		elements.add( new UTIL_Fieldmapper.mappedField('notify_on_missed_call', 1, 'Integer', 1, FALSE, TRUE) );
		return elements;
	}
	
	private static List<UTIL_Fieldmapper.mappedElement> getMapper_DelSource(Id accId) {
		List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
		return elements;
	}
	// ====================== MOCKS ======================
	
	private static Map<String, UTIL_WSC.WSC_Mock> getMocks_NewCustomer() {
		Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
        mocks.put(UTIL_WSC.TESTMOCK,new UTIL_WSC.WSC_Mock('OK',200,'{"total":1,"page":0,"pagesize":1000,"numpages":1,"customers":[{"customer_id":"808117","name":"Test1 bueng","custnr":"2223","corporateid":null,"email":"bunhor.eng@gaea-sys.com","uuid":"0d43e633-02da-413d-a663-b10b4105deca","default_campaign_id":null,"address_street":null,"address_zip":null,"address_city":null,"address_state":null,"address_country":null,"receive_monthly_report":"0","freespee_caller_id":"0"}]}'));
		return mocks;
	}
	
	private static Map<String, UTIL_WSC.WSC_Mock> getMocks_NewSource() {
		Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
		mocks.put(UTIL_WSC.TESTMOCK,new UTIL_WSC.WSC_Mock('OK',200,'{"total":1,"page":0,"pagesize":1000,"numpages":1,"sources":[{"source_id":"501556018","name":"automobile.it","email":null,"smsnumber":null,"media":null,"customer_id":"806134","phonenr":"+39085593300001","destnr":"+390859960036","timestamp":"2017-02-26 23:00:00","expire":null,"created":"2017-02-27 10:33:29","modified":"2017-02-27 10:33:29","class":"0","status":"active","vm_greeting_id":null,"campaign_id":null,"publisher_id":null,"notify_on_missed_call":"0","notify_on_answered_call":"0","notify_on_new_voicemail":"0","vm_divert_all":"0","vm_divert_busy":"0","vm_divert_noanswer":"0","call_recording":"0","vm_disable_recording":"0","alt_numbers":[],"custom_101":null,"custom_116":null,"custom_117":null,"custom_118":null,"custom_119":null,"custom_120":null}]}'));
		return mocks;
	}
	
	private static Map<String, UTIL_WSC.WSC_Mock> getMocks_DelSource() {
		Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
        mocks.put(UTIL_WSC.TESTMOCK,new UTIL_WSC.WSC_Mock('OK',200,'{"total":1,"page":0,"pagesize":1000,"numpages":1,"sources":[{"source_id":"501556018","name":"automobile.it","email":null,"smsnumber":null,"media":null,"customer_id":"806134","phonenr":"+39085593300001","destnr":"+390859960036","timestamp":"2017-02-26 23:00:00","expire":"2017-02-27 23:00:00","created":"2017-02-27 10:33:29","modified":"2017-02-27 13:23:53","class":"0","status":"quarantined","vm_greeting_id":null,"campaign_id":null,"publisher_id":null,"notify_on_missed_call":"0","notify_on_answered_call":"0","notify_on_new_voicemail":"0","vm_divert_all":"0","vm_divert_busy":"0","vm_divert_noanswer":"0","call_recording":"0","vm_disable_recording":"0","alt_numbers":[],"custom_101":null,"custom_116":null,"custom_117":null,"custom_118":null,"custom_119":null,"custom_120":null}]}'));
		return mocks;
	}
	
	// ====================== UTILS ======================
	private static Map<String,Object> getObjectData(Object obj) {
    	try {
    		String jsonStr = JSON.serializePretty(obj);
    		return (Map<String,Object>) JSON.deserializeUntyped(jsonStr.removeStart('[').removeEnd(']'));
    	} catch (Exception e) {
    		return new Map<String,Object>();
    	}
    }
    
    public static String getErrors(UTIL_WSC.WSC_Result resl) {
    	if(resl == null) return 'Interanl errors!';
    	if( resl.getResponseData() == null ) return 'External errors!';
    	if( WSC_Freespee.getObjectData(resl.getResponseData().get('errors')) != null) {
    		String err = '';
    		for(Object ob : WSC_Freespee.getObjectData(resl.getResponseData().get('errors')).values()) {
    			err += String.valueOf(ob) + '\n';
    		}
    		return err;
    	}
    	return 'Unkown errors!';
    }
}