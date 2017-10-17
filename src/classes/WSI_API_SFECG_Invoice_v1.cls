public with sharing class WSI_API_SFECG_Invoice_v1 {
 
 	private static final String APINAME = 'WSI_API_SFECG_Invoice_v1';

	public static void process(String wsClassName, WSI_CTRL.APIResponse resp) {
			Type t = Type.forName(APINAME + '.' + wsClassName);
			WSI_ApiRequest WSI_ApiRequest = (WSI_ApiRequest) t.newInstance();
			WSI_ApiRequest.init(resp);
			WSI_ApiRequest.processRequest(); 
	}
 
 
	public class InvoiceUpdate extends WSI_ApiRequest {

		public override void init(WSI_CTRL.APIResponse apiResp) {
			super.init(apiResp);
		}

		public override void setContextRecords() {

			String objectId;
			String uniquePlatformId;
 
			if (!pathParts.isEmpty()) { 
				objectId = pathParts.get(pathParts.size()-1);
			}
			if (pathParts.size() > 1) {
				String memberId = pathParts.get(pathParts.size()-2);
				if (memberId.length() == 5){
					uniquePlatformId = memberId + '_' + objectId;
				}
			} 


	        String whereClause = null;
			if (uniquePlatformId != null) {
				whereClause = 'UniquePlatformId__c = \'' + uniquePlatformId + '\'';
			}
			else if (objectId != null && objectId != '' && (objectId.length() == 15 || objectId.length() == 18)) {
	            whereClause = 'Id = \'' + objectId + '\'';
	        }

			if (whereClause == null){
				contextRecordNotFound('No Salesforce Id or Local Platform Id supplied.');
			}

	        try {
	            contextRecord = (GW_sObject.queryRecords('Invoice__c',whereClause).get(0));

	        } catch (Exception e) {
				contextRecordNotFound('Failed to find Invoice using provided Salesforce Id: ' + objectId + ' or Local Platform Id:' + uniquePlatformId);
	        }
		}

		public override void validateData() {
			// Every field, validate if value has changed, user has access to write to this field
	        objectNameToFieldNameNewFieldValueMap = new Map<String,Map<String,String>>();

	        Map<String,String> invoiceFieldsToUpdate = new Map<String,String>();
	        Map<String,String> invoiceFieldMap = getInvoiceFieldMap();

	        try {
	            // Extract changed fields
	            for(String fieldKey : requestJSON.keySet()) {
	                if(invoiceFieldMap.containsKey(fieldKey)) {
	                    // Check if value has changed
	                    if(String.valueOf(contextRecord.get(invoiceFieldMap.get(fieldKey))) != String.valueOf(requestJSON.get(fieldKey)) && (requestJSON.get(fieldKey) != null)) {
	                        invoiceFieldsToUpdate.put(invoiceFieldMap.get(fieldKey), String.valueOf(requestJSON.get(fieldKey)));
	                    }
	                }
	            }
	        } catch(Exception e) {
	            apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Inside validateDate(): ' + e.getStackTraceString());
	            throw new WSI_CTRL.APIException();
	        }
	        // Add to save container
	        if(invoiceFieldsToUpdate.size() > 0) {
	            objectNameToFieldNameNewFieldValueMap.put('Invoice__c', invoiceFieldsToUpdate);
				validateSObjectFieldsAccess('Invoice__c', invoiceFieldsToUpdate);
	        }
		}

		public override void prepareUpdate() {
			try {
	            if(objectNameToFieldNameNewFieldValueMap.containsKey('Invoice__c')) {
	                for(String fieldName : objectNameToFieldNameNewFieldValueMap.get('Invoice__c').keySet()) {
	                    putSObjectValueAsCorrectType('Invoice__c', fieldName, objectNameToFieldNameNewFieldValueMap.get('Invoice__c'));
	                }
	                objectsToUpdate.put('Invoice__c',contextRecord);
	            }
	        } catch (Exception e) {
	            apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Prepare update error: ' + e.getMessage());
	            throw new WSI_CTRL.APIException();
	        }
		}

		public override void executeDML() {
			if(objectsToUpdate.containsKey('Invoice__c')) {
	            Invoice__c invToUpdate = (Invoice__c) objectsToUpdate.get('Invoice__c');
	            update invToUpdate;
	        }
		}

		public override void prepareResponse() {

			Map<String,String> responseMap = new Map<String,String>();
	        Map<String,String> invoiceFieldMap = reverseMap(getInvoiceFieldMap()); // Salesforce field name to json field name map
	        for(String objName : objectNameToFieldNameNewFieldValueMap.keySet()) {
	            Map<String,String> updatedValues = new Map<String,String>();
	            for(String fieldName : objectNameToFieldNameNewFieldValueMap.get(objName).keySet()) {
	                if(invoiceFieldMap.get(fieldName) != null) {
	                    updatedValues.put(invoiceFieldMap.get(fieldName),objectNameToFieldNameNewFieldValueMap.get(objName).get(fieldName));
	                } else {
	                    updatedValues.put(objName+'.'+fieldName,objectNameToFieldNameNewFieldValueMap.get(objName).get(fieldName));
	                }
	            }
	            responseMap.putAll(updatedValues);
	        }
			if (contextRecord != null){
				apiResp.linklog('Invoice__c', contextRecord.Id);
			}

	        apiResp.setResponse(responseMap);

		}

		private Map<String,String> getInvoiceFieldMap() {
			Map<String,String> invoiceFieldMap = new Map<String,String>();

		   // Fill Invoice mapping
		   invoiceFieldMap.put('status','FQ_InvoiceStatus__c');
		   invoiceFieldMap.put('invoiceDate','FQ_InvoiceDate__c');
		   invoiceFieldMap.put('amountPaid', 'FQ_InvoicePaidAmount__c');
		   invoiceFieldMap.put('amountToBePaid', 'FQ_InvoiceAmount__c');
		   invoiceFieldMap.put('invoiceDocumentURL', 'InvoiceDocumentURL__c');
		   invoiceFieldMap.put('billingSystemInvoiceNumber', 'BillingSystemInvoiceNumber__c');

		   return invoiceFieldMap;
		}



	}
    
}