public with sharing class WSI_API_SFECG_v1 {

	private static final String APINAME = 'WSI_API_SFECG_v1';

	public static void process(String wsClassName, WSI_CTRL.APIResponse resp) {
			Type t = Type.forName(APINAME + '.' + wsClassName);
			ApiRequest apiRequest = (ApiRequest) t.newInstance();
			apiRequest.init(resp);
			apiRequest.processRequest();
	}

    public class AccountUpdate extends ApiRequest {

		//////////////////////////
		//ApiRequest overrides
		/////////////////////////
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
	            contextRecord = (GW_sObject.queryRecords('Account',whereClause).get(0));
	        } catch (Exception e) {
				contextRecordNotFound('Failed to find Account using provided Salesforce Id: ' + objectId + ' or Local Platform Id:' + uniquePlatformId);
	        }
		}

		public override void validateData() {
			// Every field, validate if value has changed, user has access to write to this field
	        objectNameToFieldNameNewFieldValueMap = new Map<String,Map<String,String>>();
	        Map<String,String> accFieldsToUpdate = new Map<String,String>();
	        Map<String,String> accountFieldMap = getAccountFieldMap();
	        try {
	            // Extract changed fields
	            for(String fieldKey : requestJSON.keySet()) {
	                if(accountFieldMap.containsKey(fieldKey)) {
	                    // Check if value has changed
	                    if(String.valueOf(contextRecord.get(accountFieldMap.get(fieldKey))) != String.valueOf(requestJSON.get(fieldKey)) && (requestJSON.get(fieldKey) != null)) {
	                        accFieldsToUpdate.put(accountFieldMap.get(fieldKey), String.valueOf(requestJSON.get(fieldKey)));
	                    }
	                }
	                if(fieldKey == 'billingAddress') {
	                    updateAccountAddress((Map<String,Object>)requestJSON.get(fieldKey),accFieldsToUpdate,'billing');
	                }
	                if(fieldKey == 'shippingAddress') {
	                    updateAccountAddress((Map<String,Object>)requestJSON.get(fieldKey),accFieldsToUpdate,'shipping');
	                }
	                if(fieldKey == 'financialContact') {
	                    updateAccountContact((Map<String,Object>)requestJSON.get(fieldKey),fieldKey);
	                }
	                if(fieldKey == 'portalUser') {
	                    updateAccountContact((Map<String,Object>)requestJSON.get(fieldKey),fieldKey);
	                }
	                if(fieldKey == 'customAttributes') {
	                    updateAccountCustomAttributes((List<Object>)requestJSON.get(fieldKey));
	                }
	            }
	        } catch(Exception e) {
	            apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Inside validateDate(): ' + e.getStackTraceString());
	            throw new WSI_CTRL.APIException();
	        }
	        // Add to save container
	        if(accFieldsToUpdate.size() > 0) {
	            objectNameToFieldNameNewFieldValueMap.put('Account',accFieldsToUpdate);
	            validateSObjectFieldsAccess('Account', accFieldsToUpdate);
	            validateContactFieldsAccess();
	        }

		}

		public override void prepareUpdate() {
			try {
				if(objectNameToFieldNameNewFieldValueMap.containsKey('Account')) {
					for(String fieldName : objectNameToFieldNameNewFieldValueMap.get('Account').keySet()) {
						putSObjectValueAsCorrectType('Account', fieldName, objectNameToFieldNameNewFieldValueMap.get('Account'));
					}
					objectsToUpdate.put('Account',contextRecord);
				}
				if(objectNameToFieldNameNewFieldValueMap.containsKey('portalUser') && objectsToUpdate.containsKey('portalUser')) {
					for(String fieldName : objectNameToFieldNameNewFieldValueMap.get('portalUser').keySet()) {
						((SObject)objectsToUpdate.get('portalUser')).put(fieldName, objectNameToFieldNameNewFieldValueMap.get('portalUser').get(fieldName));
					}
				}
				if(objectNameToFieldNameNewFieldValueMap.containsKey('financialContact') && objectsToUpdate.containsKey('financialContact')) {
					for(String fieldName : objectNameToFieldNameNewFieldValueMap.get('financialContact').keySet()) {
						((SObject)objectsToUpdate.get('financialContact')).put(fieldName, objectNameToFieldNameNewFieldValueMap.get('financialContact').get(fieldName));
					}
				}
			} catch (Exception e) {
				apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Prepare update error: ' + e.getMessage());
				throw new WSI_CTRL.APIException();
			}
		}

		public override void executeDML() {
			if(objectsToUpdate.containsKey('Account')) {
                Account accToUpdate = (Account) objectsToUpdate.get('Account');
                update accToUpdate;
            }
            if(objectsToUpdate.containsKey('portalUser')) {
                Contact portalUser = (Contact) objectsToUpdate.get('portalUser');
                update portalUser;
            }
            if(objectsToUpdate.containsKey('financialContact')) {
                Contact financialContact = (Contact) objectsToUpdate.get('financialContact');
                update financialContact;
            }
            if(objectsToUpdate.containsKey('customAttributes')) {
                List<CustomAttribute__c> caList = (List<CustomAttribute__c>) objectsToUpdate.get('customAttributes');
                update caList;
            }
		}

		public override void prepareResponse() {
			Map<String,String> responseMap = new Map<String,String>();

			Map<String,String> accountFieldMap = reverseMap(getAccountFieldMap()); // Salesforce field name to json field name map

			//Object Name -> (SF Field name : value)
			for(String objName : objectNameToFieldNameNewFieldValueMap.keySet()) {
				Map<String,String> updatedValues = new Map<String,String>();
				for(String fieldName : objectNameToFieldNameNewFieldValueMap.get(objName).keySet()) {
					if(accountFieldMap.get(fieldName) != null) {
						updatedValues.put(accountFieldMap.get(fieldName),objectNameToFieldNameNewFieldValueMap.get(objName).get(fieldName));
					} else {
						updatedValues.put(objName+'.'+fieldName,objectNameToFieldNameNewFieldValueMap.get(objName).get(fieldName));
					}
				}
				responseMap.putAll(updatedValues);
			}
			if (contextRecord != null){
				apiResp.linklog('Account', contextRecord.Id);
			}
			apiResp.setResponse(responseMap);
		}

		// END APIREQUEST OVERRIDES

	    private void updateAccountCustomAttributes(List<Object> customAttributesList) {
	        GW_CustomAttribute.cacheCustomAttributes(new List<sObject>{(SObject)contextRecord});
	        Map<String,CustomAttribute__c> existingCAMap = new Map<String,CustomAttribute__c>();
	        List<CustomAttribute__c> caForUpdateList = new List<CustomAttribute__c>();
	        if(GW_CustomAttribute.objectCustomAttributesCache != null) {
	            for(CustomAttribute__c ca : GW_CustomAttribute.objectCustomAttributesCache.get((Id)contextRecord.get('Id'))) {
	                existingCAMap.put(ca.Name,ca);
	            }
	        }
	        for(Object caObj : customAttributesList) {
	            Map<String,Object> caMap = (Map<String,Object>)caObj;
	            objectNameToFieldNameNewFieldValueMap.put('customAttributes',new Map<String,String>());
	            // Such custom attribute exists already
	            if(existingCAMap.containsKey((String)caMap.get('key'))) {
	                CustomAttribute__c ca = existingCAMap.get((String)caMap.get('key'));
	                if(String.valueOf(GW_CustomAttribute.getValue(ca)) != String.valueOf(caMap.get('value')) && (caMap.get('value') != null)) {
	                    objectNameToFieldNameNewFieldValueMap.get('customAttributes').put((String)caMap.get('key'),String.valueOf(caMap.get('value')));
	                    GW_CustomAttribute.setValue(ca,caMap.get('value'));
	                    caForUpdateList.add(ca);
	                }
	            }
	        }
	        if(caForUpdateList.size() > 0) {
	            objectsToUpdate.put('customAttributes',caForUpdateList);
	        }
	    }

	    private void validateContactFieldsAccess() {
	        Map<String, Schema.SObjectField> originAccountFieldMap = Schema.SObjectType.Account.fields.getMap();
	        List<String> errorMsgs = new List<String>();
	        if(objectNameToFieldNameNewFieldValueMap.containsKey('financialContact')) {
	            if(!originAccountFieldMap.get('Finance_contact__c').getDescribe().isUpdateable()) {
	                errorMsgs.add('Field Finance_contact__c is not updateable - cannot update financialContact');
	            }
	        }
	        if(objectNameToFieldNameNewFieldValueMap.containsKey('portalUser')) {
	            if(!originAccountFieldMap.get('Portal_User__c').getDescribe().isUpdateable()) {
	                errorMsgs.add('Field Portal_User__c is not updateable - cannot update portalUser');
	            }
	        }
	        if(errorMsgs.size() > 0) {
	            apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'',errorMsgs);
	            throw new WSI_CTRL.APIException();
	        }
	    }

	    private void updateAccountContact(Map<String,Object> contactMap, String contactType) {
	        Map<String,String> contactFieldMap = getContactFieldMap();
	        Map<String,String> contactFieldsToUpdate = new Map<String,String>();
	        SObject contactToUpdate;
	        // Query the contact
	        if(contactType == 'financialContact') {
	            contactToUpdate = GW_sObject.queryRecord('Contact',(Id)contextRecord.get('Finance_contact__c'));
	        }
	        if(contactType == 'portalUser') {
	            contactToUpdate = GW_sObject.queryRecord('Contact',(Id)contextRecord.get('Portal_User__c'));
	        }
	        // Update the fields if necessary
	        if(contactToUpdate != null) {
	            for(String contactFieldKey : contactMap.keySet()) {
	                // Validate change
	                if(String.valueOf(contactToUpdate.get(contactFieldMap.get(contactFieldKey))) != String.valueOf(contactMap.get(contactFieldKey)) && (contactMap.get(contactFieldKey) != null)) {
	                    contactFieldsToUpdate.put(contactFieldMap.get(contactFieldKey),String.valueOf(contactMap.get(contactFieldKey)));
	                }
	            }
	        }
	        if(contactFieldsToUpdate.size() > 0) {
	            objectNameToFieldNameNewFieldValueMap.put(contactType,contactFieldsToUpdate);
	            objectsToUpdate.put(contactType,contactToUpdate);
	        }
	    }

	    private void updateAccountAddress(Map<String,Object> addressMap, Map<String,String> accountFieldsToUpdate, String prefix) {
	        Map<String,String> accountFieldMap = getAccountFieldMap();
	        for(String addressKey : addressMap.keySet()) {
	            String refName = prefix + String.valueOf(addressKey);
	            if(String.valueOf(contextRecord.get(accountFieldMap.get(refName))) != String.valueOf(addressMap.get(addressKey)) && (addressMap.get(addressKey) != null)) {
	                accountFieldsToUpdate.put(accountFieldMap.get(refName), String.valueOf(addressMap.get(addressKey)));
	            }
	        }
	    }

		private Map<String,String> getAccountFieldMap() {
			Map<String,String> accountFieldMap = new Map<String,String>();

           // Fill Account mapping
           accountFieldMap.put('localId','LocalPlatformId__c');
           accountFieldMap.put('accountExtId','AccountExtId__c');
           accountFieldMap.put('localParentId','LocalPlatformId__c');
           accountFieldMap.put('status','Account_Status__c');
           accountFieldMap.put('accountName','Name');
           accountFieldMap.put('vatId','Company_VAT_No__c');
           accountFieldMap.put('BillingPref','BillingPreferenceValidFrom__c');
           accountFieldMap.put('billingstreet','BillingStreet');
           accountFieldMap.put('billingcity','BillingCity');
           accountFieldMap.put('billingstate','BillingState');
           accountFieldMap.put('billingpostalCode','BillingPostalCode');
           accountFieldMap.put('billingcountry','BillingCountry');
           accountFieldMap.put('billingcountryCode','BillingCountryCode');
           accountFieldMap.put('billingstateCode','BillingStateCode');
           accountFieldMap.put('shippingstreet','ShippingStreet');
           accountFieldMap.put('shippingcity','ShippingCity');
           accountFieldMap.put('shippingstate','ShippingState');
           accountFieldMap.put('shippingpostalCode','ShippingPostalCode');
           accountFieldMap.put('shippingcountry','ShippingCountry');
           accountFieldMap.put('shippingcountryCode','ShippingCountryCode');
           accountFieldMap.put('shippingstateCode','ShippingStateCode');

           return accountFieldMap;
		}

		private Map<String,String> getContactFieldMap() {
	        Map<String,String> contactFieldMap = new Map<String,String>();

	        contactFieldMap.put('firstName','firstName');
	        contactFieldMap.put('lastName','lastName');
	        contactFieldMap.put('salutation','salutation');
	        contactFieldMap.put('email','email');

	        return contactFieldMap;
	    }

    }

	public class InvoiceUpdate extends ApiRequest {

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

	public virtual class ApiRequest {

		public WSI_CTRL.APIResponse apiResp;
	    public Map<String,Object> requestJSON; // Incoming JSON
	    public Map<String,Map<String,String>> objectNameToFieldNameNewFieldValueMap; // contact:map<Name,NewContactName>, account:map<string,string>, etc
	    public Map<String,Object> objectsToUpdate; // Container for DML ready objects
	    public SObject contextRecord;
		List<String> pathParts;

		public virtual void init(WSI_CTRL.APIResponse apiResp) {
			this.apiResp = apiResp;
	        objectsToUpdate = new Map<String,Object>();
			pathParts = WSI_CTRL.getRequestURI(apiResp.apiRestRequest).split('/');
		}

		public virtual void processRequest() {
			try {
	            setContextRecords();
	            parseRequestJSON();
	            validateData();
	            prepareUpdate();
	            performDML();
	            prepareResponse();

	        } catch (WSI_CTRL.APIException e) {
	            return;
	        }
		}

		public virtual void validateData() {
			throw new UTIL.CustomException('WSI_CTRL.validateData() not implemented!');
		}

		public virtual void prepareUpdate() {

		}

		public void performDML() {
			Savepoint sp = Database.setSavepoint();
	        try {
	            executeDML();
	        } catch (Exception e) {
	            Database.rollback(sp);
	            apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'DML Error: ' + e.getMessage());
	            throw new WSI_CTRL.APIException();
	        }
		}

		public virtual void executeDML() {
			throw new UTIL.CustomException('WSI_CTRL.validateData() not implemented!');
		}

		public virtual void prepareResponse() {
			throw new UTIL.CustomException('WSI_CTRL.validateData() not implemented!');
	    }

		public virtual void parseRequestJSON() {
			try {
				requestJSON = (Map<String, Object>)JSON.deserializeUntyped(apiResp.apiRestRequest.requestBody.toString());
			} catch (Exception e) {
				apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),e.getMessage());
				throw new WSI_CTRL.APIException();
			}
		}

		public virtual void setContextRecords() {
			throw new UTIL.CustomException('WSI_CTRL.findContextRecord() not implemented!');
		}

		public void contextRecordNotFound(String message) {
			apiResp.addApiError(UTIL_WSC.HTTP_NOTFOUND,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_NOTFOUND),message);
			throw new WSI_CTRL.APIException();
		}

		public void putSObjectValueAsCorrectType(String sObjectName, String fieldName, Map<String,String> fieldNameToValueMap) {

			Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

			Schema.SObjectType ctype = gd.get(sObjectName);

			Schema.DisplayType fieldType = ctype.getDescribe().fields.getMap().get(fieldName).getDescribe().getType();
			if(fieldType == Schema.DisplayType.Date) {
				contextRecord.put(fieldName,Date.valueOf(fieldNameToValueMap.get(fieldName)));
			}
			else if(fieldType == Schema.DisplayType.DateTime) {
				contextRecord.put(fieldName,DateTime.valueOf(fieldNameToValueMap.get(fieldName)));
			}
			else if(fieldType == Schema.DisplayType.Double) {
				contextRecord.put(fieldName,Decimal.valueOf(fieldNameToValueMap.get(fieldName)));
			}
			else if(fieldType == Schema.DisplayType.Currency) {
				contextRecord.put(fieldName,Decimal.valueOf(fieldNameToValueMap.get(fieldName)));
			}
			else if(fieldType == Schema.DisplayType.Boolean) {
				contextRecord.put(fieldName,Boolean.valueOf(fieldNameToValueMap.get(fieldName)));
			}
			else if(fieldType == Schema.DisplayType.Integer) {
				contextRecord.put(fieldName,Integer.valueOf(fieldNameToValueMap.get(fieldName)));
			}
			else if(fieldType == Schema.DisplayType.Picklist) {
				contextRecord.put(fieldName,String.valueOf(fieldNameToValueMap.get(fieldName)));
			}
			// String's default
			else {
				contextRecord.put(fieldName,fieldNameToValueMap.get(fieldName));
			}
		}

		private void validateSObjectFieldsAccess(String sObjectName, Map<String,String> fieldsToUpdate) {
			Schema.SObjectType ctype = Schema.getGlobalDescribe().get(sObjectName);

	        Map<String, Schema.SObjectField> originSObjectFieldMap = ctype.getDescribe().fields.getMap();
	        List<String> errorMsgs = new List<String>();
	        for(String objField : fieldsToUpdate.keySet()) {
	            if(originSObjectFieldMap.containsKey(objField)) {
	                if(!originSObjectFieldMap.get(objField).getDescribe().isUpdateable()) {
	                    errorMsgs.add('Field ' + objField + ' is not updateable.');
	                }
	            }
	        }
	        if(errorMsgs.size() > 0) {
	            apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'',errorMsgs);
	            throw new WSI_CTRL.APIException();
	        }
	    }

		private Map<String,String> reverseMap(Map<String,String> mapToReverse) {
			Map<String,String> reversedMap = new Map<String,String>();
			for(String key : mapToReverse.keySet()) {
				reversedMap.put(mapToReverse.get(key),key);
			}
			return reversedMap;
		}
	}
}