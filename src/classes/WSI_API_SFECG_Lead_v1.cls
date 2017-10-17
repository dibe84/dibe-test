/**
 *	Rest Api class for handle insert, update & convert Lead process
 *	@author : Pheaktra Hun
 *	@date : 11/Aug/2016
 *	@reference : Task #9661
 */
public with sharing class WSI_API_SFECG_Lead_v1 {
    private static final String APINAME = 'WSI_API_SFECG_Lead_v1';

	public static void process(String wsClassName, WSI_CTRL.APIResponse resp) {
			Type t = Type.forName(APINAME + '.' + wsClassName);
			WSI_ApiRequest WSI_ApiRequest = (WSI_ApiRequest) t.newInstance();
			WSI_ApiRequest.init(resp);
			WSI_ApiRequest.processRequest();  
	}

    public class LeadOperation extends WSI_ApiRequest {

		private String operation = '';
		Map<String,String> responseMap = new Map<String,String>();

		//////////////////////////
		//WSI_ApiRequest overrides
		/////////////////////////
		public override void init(WSI_CTRL.APIResponse apiResp) {
			super.init(apiResp);
		}

		public override void setContextRecords() {
			
			String objectId;
			String uniquePlatformId;
			
			// update & covert operation
			if (!pathParts.isEmpty()) {
				
				// insert operation
				if(pathParts.get(pathParts.size()-1) == 'leads'){
					contextRecord = new Lead();
					operation = 'insert';
					return;
				}
				
				objectId = pathParts.get(pathParts.size()-1); 
			}
			if (pathParts.size() > 1) {
				String memberId = pathParts.get(pathParts.size()-2);
				if (memberId.length() == 5 && memberId != 'leads'){
					uniquePlatformId = memberId + '_' + objectId;
				}
			}
			
			Set<String>sParts = new Set<String>(pathParts);
			operation = sParts.contains('convert') ? 'convert' : 'update'; 
			
	        String whereClause = null;
			if (uniquePlatformId != null) {
				whereClause = 'ExtId__c = \'' + uniquePlatformId + '\'';
			}
			else if (objectId != null && objectId != '' && (objectId.length() == 15 || objectId.length() == 18)) {
	            whereClause = 'Id = \'' + objectId + '\'';
	        }

			if (whereClause == null){
				contextRecordNotFound('No Salesforce Id or Local Platform Id supplied.');
			}

	        try {
	            contextRecord = (GW_sObject.queryRecords('Lead', whereClause).get(0));
	        } catch (Exception e) {
				contextRecordNotFound('Failed to find Lead using provided Salesforce Id: ' + objectId + ' or Local Platform Id: ' + uniquePlatformId);
	        }
		}
		
		public override void validateData() {
			
			// Every field, validate if value has changed, user has access to write to this field
	        objectNameToFieldNameNewFieldValueMap = new Map<String, Map<String, String>>();
	        
	        // bypass validate field when no fields request lead convert only
			if(operation == 'convert' && requestJSON.isEmpty()){
				objectsToUpdate.put('Lead', contextRecord);
				return;
			}
	        
	        Map<String, String> leadFieldsToUpdate = new Map<String, String>();
	        Map<String, String> leadFieldMap = getLeadFieldMap();
	        try {
	            // Extract changed fields
	            for(String fieldKey : requestJSON.keySet()) {
	                if(!leadFieldMap.containsKey(fieldKey)) continue;
	                
                    // Check if value has changed
                    String apiField = leadFieldMap.get(fieldKey);
                    String reqFieldValue = String.valueOf(requestJSON.get(fieldKey));
                    Boolean isValueChanged = reqFieldValue != null && String.valueOf(contextRecord.get(apiField)) != reqFieldValue;
                    
                    if(isValueChanged) leadFieldsToUpdate.put(apiField, reqFieldValue);
                    
	            }
	        } catch(Exception e) {
	            apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST, UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST), 'Inside validateDate(): '+e.getMessage() +' - Line number:'+e.getLineNumber()+' - Stack Trace: ' + e.getStackTraceString());
	            throw new WSI_CTRL.APIException();
	        } 
	        // Add to save container
	        if(leadFieldsToUpdate.size() > 0) {
	            objectNameToFieldNameNewFieldValueMap.put('Lead', leadFieldsToUpdate);
	            validateSObjectFieldsAccess('Lead', leadFieldsToUpdate);
	        }

		}
		
		public override void prepareUpdate() {
			try {
				
				if(objectNameToFieldNameNewFieldValueMap.containsKey('Lead')) {
					for(String fieldName : objectNameToFieldNameNewFieldValueMap.get('Lead').keySet()) {
						putSObjectValueAsCorrectType('Lead', fieldName, objectNameToFieldNameNewFieldValueMap.get('Lead'));
					}
					objectsToUpdate.put('Lead', contextRecord);
				}
			} catch (Exception e) {
				apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Prepare update error: ' + e.getMessage());
				throw new WSI_CTRL.APIException();
			}
		}

		public override void executeDML() {
			if(objectsToUpdate.containsKey('Lead')) {
                Lead le = (Lead) objectsToUpdate.get('Lead');
                upsert le;
                
                // convert lead after update lead fields
                if(operation == 'convert') convertLead();
            }
		}

		public override void prepareResponse() {
			Map<String,String> leadFieldMap = reverseMap(getLeadFieldMap()); // Salesforce field name to json field name map
			
			if(operation == 'insert'){
				responseMap.put('message', 'Success insert Lead');
				Lead le = (Lead) objectsToUpdate.get('Lead');
				responseMap.put('id', le.Id);
			}else if(operation == 'update'){
				//Object Name -> (SF Field name : value)
				for(String objName : objectNameToFieldNameNewFieldValueMap.keySet()) {
					Map<String,String> updatedValues = new Map<String,String>();
					for(String fieldName : objectNameToFieldNameNewFieldValueMap.get(objName).keySet()) {
						if(leadFieldMap.get(fieldName) != null) {
							updatedValues.put(leadFieldMap.get(fieldName), objectNameToFieldNameNewFieldValueMap.get(objName).get(fieldName));
						} else {
							updatedValues.put(objName+'.'+fieldName, objectNameToFieldNameNewFieldValueMap.get(objName).get(fieldName));
						}
					}
					responseMap.putAll(updatedValues);
				}
			}
			
			
			if (contextRecord != null){
				apiResp.linklog('Lead', contextRecord.Id);
			}
			apiResp.setResponse(responseMap);
		}
		
		// END WSI_ApiRequest OVERRIDES
		
		private void convertLead(){
			
			Lead le = (Lead)contextRecord;
			
			Database.LeadConvert lc = new Database.LeadConvert();
			lc.setLeadId(le.id);
			
			LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
			lc.setConvertedStatus(convertStatus.MasterLabel);
			
			Database.LeadConvertResult lcr = Database.convertLead(lc);
			if(lcr.isSuccess()){
				responseMap.put('message', 'Success converted Lead');
				responseMap.put('accountId', lcr.getAccountId());
				responseMap.put('contactId', lcr.getContactId());
				responseMap.put('opportunityId', lcr.getOpportunityId());
			}else{
				apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST, UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST), 'Convert Lead failed : ' + lcr.getErrors().get(0).getMessage());
	            throw new WSI_CTRL.APIException();
			}
			
		}
		
	    private Map<String, String> getLeadFieldMap(){
			return new Map<String, String>{
				'salutation' 	=> 'Salutation',
				'firstName' 	=> 'FirstName',
				'lastName' 		=> 'LastName',
				'member' 		=> 'Member__c',
				'memberUnit' 	=> 'MemberUnit__c',
				'email' 		=> 'Email',
				'externalInfo' 	=> 'External_Info__c',
				'touch' 		=> 'Touch__c',
				'street' 		=> 'Street',
				'city' 			=> 'City',
				'postalCode' 	=> 'PostalCode',
				'state' 		=> 'State',
				'country' 		=> 'Country',
				'leadSource' 	=> 'LeadSource',
				'status' 		=> 'Status',
				'title' 		=> 'Title',
				'annualRevenue' => 'AnnualRevenue',
				'company' 		=> 'Company',
				'description' 	=> 'Description',
				'industry' 		=> 'Industry',
				'mobilePhone' 	=> 'MobilePhone',
				'phone' 		=> 'Phone',
				'website' 		=> 'Website'
			};
			           
	    }

    }
}