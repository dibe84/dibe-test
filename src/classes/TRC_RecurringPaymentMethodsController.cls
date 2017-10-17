/**
 * Bunhor @19-Apr-2017: Controller to retrieve/create/delete TRACT's Recurring Payment Methods
 */
public with sharing class TRC_RecurringPaymentMethodsController {

	public TRC_RecurringPaymentMethodsController( ApexPages.StandardController stdController) { }
	
	/***********************************************************
     * Description: Return if user has View Encrypted Data permission.
     * @return: boolean
     * ********************************************************/
    public Boolean isUserHasEncryptedData {
    	get {
	        List<PermissionSetAssignment> psaEncrypt = [SELECT Id
	                                                   		FROM PermissionSetAssignment
	                                                   		WHERE PermissionSet.PermissionsViewEncryptedData = true
	                                                   AND AssigneeId = :UserInfo.getUserId()];
	        if(psaEncrypt.isEmpty()){
	            return false;
	        } else{
	            return true;
	        }
    	} set;
    }
    
    /**
     * Query current recurring payments. Currently there is only one per billing account
     */
    @AuraEnabled 
    public static RemoteResponse getRecurringPaymentByBillingAccount(String accid){
    	try {
			UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.RecurringPaymentGet');
	        req.init(accid);
	        UTIL_WSC.WSC_Result res = req.call();
	        return TRC_RecurringPaymentMethodsController.getRemoteResp(res, 200);
    	} catch(exception e) {
    		return new RemoteResponse(e.getMessage()+ '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
    /**
     * Create Recurring Payment
     * Ex: TRC_RecurringPaymentMethodsController.createRecurringPayment('001O0000019u4ER', 'VISA', '12/2020', 'TestFname', 'TestLname', '4111111111111111', 'credit-card', '123', 'EUR');
     * Ex: TRC_RecurringPaymentMethodsController.createRecurringPayment('001O0000019u4ER', 'sepa-dd-em', 'DE36444488881234567890', '4111111111111111', '12/2020', 'test user', null);
     */
    @AuraEnabled 
    public static RemoteResponse createRecurringPayment(String accid, String jsonCardInfo){
        
        RemoteResponse resp;
        try {
            UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.RecurringPaymentCreate');
            req.init(accid);
            Map<String, String> cardInfo = (Map<String, String>) JSON.deserialize(jsonCardInfo, Map<String, String>.class);
            Boolean isSEPAMandate = 'sepa-dd-em'.equals( cardInfo.get('payment_method_type') );
            
            Map<String, String> cardMapper;
            if( isSEPAMandate ) {
                cardMapper = new Map<String, String>{   
                                                        'payment_method_type'       => cardInfo.get('payment_method_type'), 
                                                        'iban'                      => cardInfo.get('iban'), 
                                                        'mandate_id'                => cardInfo.get('mandate_id'), 
                                                        'mandate_signature_date'    => cardInfo.get('mandate_signature_date'), 
                                                        'owner_name'                => cardInfo.get('owner_name'),  
                                                        'bic'                       => cardInfo.get('bic'),
                                                        'auto_payment'              => cardInfo.get('auto_payment')
                                                    };
            } else {
                cardMapper = new Map<String, String>{   
                                                        'card_type'                 => cardInfo.get('card_type'), 
                                                        'expiration_date'           => cardInfo.get('expiration_month') + '/' + cardInfo.get('expiration_year'), 
                                                        'first_name'                => cardInfo.get('first_name'), 
                                                        'identifier_number'         => cardInfo.get('identifier_number'), 
                                                        'last_name'                 => cardInfo.get('last_name'), 
                                                        'payment_method_type'       => cardInfo.get('payment_method_type'), 
                                                        'verification_number'       => cardInfo.get('verification_number'), 
                                                        'currency'                  => cardInfo.get('currency'),
                                                        'auto_payment'              => cardInfo.get('auto_payment')
                                                    };
            }

            req.mapper.mappingElements = WSC_Tract.getMapper_RecurringPaymentCreate(cardMapper);                                            
            UTIL_WSC.WSC_Result res = req.call();
            resp = TRC_RecurringPaymentMethodsController.getRemoteResp(res, 201);
            
            if( isSEPAMandate && resp.statusCode == RemoteResponse.STATUSCODE_OK ) updateEntitiesMandateData( accid , cardInfo );
            
        } catch(exception e) {
            resp = new RemoteResponse(e.getMessage()+ '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
        }
        return resp;    
    }

    private static void updateEntitiesMandateData( String accountId, Map<String, String> cardInfo ){
        
        Account acc = GW_Account.getRecord( accountId );
        acc.Bank_AccountNumber__c = cardInfo.get('iban');
        acc.Mandate__c = cardInfo.get('mandateId');
        
        echosign_dev1__SIGN_Agreement__c agm = GW_Agreement.getRecord( cardInfo.get('mandateId') );
        agm.Bank_Account_Holder_Name__c = acc.Name;
        agm.Bank_AccountNumber__c = cardInfo.get('iban');
        agm.Mandate_Status__c = 'Success';
        
        update agm;
        update acc;
    }

    /*
        GIS-TEAM Query Agreement By Id
    */
    @AuraEnabled
    public static RemoteResponse getAreementById(String argId){
        try{
            RemoteResponse res = new RemoteResponse();
            List<echosign_dev1__SIGN_Agreement__c> edsa = GW_sObject.queryRecords('echosign_dev1__SIGN_Agreement__c', new Set<Id>{argId});
            res.content = edsa.get(0);
            res.statusCode = RemoteResponse.STATUSCODE_OK;
            return res;
        } catch(exception e) {
            return new RemoteResponse(e.getMessage()+ '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    /*
        GIS-TEAM Validate IBAN
    */
    @AuraEnabled
    public static RemoteResponse doCheckExistIBan(String iban){
        try{
            RemoteResponse res = new RemoteResponse();
            Boolean valid = AccountValidator.checkIBAN(iban);
            
            if (valid) {
                res.content = valid;
                res.statusCode = RemoteResponse.STATUSCODE_OK;
            } else {
                res.statusCode = RemoteResponse.STATUSCODE_ERROR;
            }

            return res;
        } catch(exception e) {
            return new RemoteResponse(e.getMessage()+ '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
    
    @AuraEnabled 
    public static RemoteResponse deleteRecurringPayment(String accid, List<String> cardid){
    	try {
			return new RemoteResponse('Delete Error: No delete API found!', RemoteResponse.STATUSCODE_ERROR);
			//return new RemoteResponse('', RemoteResponse.STATUSCODE_OK);
    	} catch(exception e) {
    		return new RemoteResponse(e.getMessage()+ '\n' +e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    
    private static RemoteResponse getRemoteResp(UTIL_WSC.WSC_Result res, Integer successCode) {
    	RemoteResponse response = new RemoteResponse();
        if(res == null) {
        	response.statusCode = RemoteResponse.STATUSCODE_ERROR;
        	response.message = 'Account is not ready';
        } else if (res.statusCode == successCode) {
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            response.content = res.getResponseData().get('results');  
        } else {
            response.statusCode = RemoteResponse.STATUSCODE_ERROR;
            response.message = res.status + ': ' + res.errorMsg;
            if(res.getResponseData().get('results') != null) {
            	Map<String,Object> mapres = (Map<String,Object>) res.getResponseData().get('results');
            	response.message = String.valueOf(mapres.get('message'));
            } else if(res.getResponseData().get('catalystError') != null) {
            	response.message = String.valueOf(res.getResponseData().get('catalystError'));
            }
        }
        return response;
    }
}