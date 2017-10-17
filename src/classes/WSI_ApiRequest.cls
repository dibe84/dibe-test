public virtual class WSI_ApiRequest {

		public WSI_CTRL.APIResponse apiResp;
	    public Map<String,Object> requestJSON; // Incoming JSON
	    public Map<String,Map<String,String>> objectNameToFieldNameNewFieldValueMap; // contact:map<Name,NewContactName>, account:map<string,string>, etc
	    public Map<String,Object> objectsToUpdate; // Container for DML ready objects
	    public SObject contextRecord;
		public List<String> pathParts; 

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
	            apiResp.addApiError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'DML Error: ' + e.getMessage());
	            throw new WSI_CTRL.APIException();
	        }
		}

		public virtual void executeDML() {
			throw new UTIL.CustomException('WSI_CTRL.executeDML() not implemented!');
		}

		public virtual void prepareResponse() {
			throw new UTIL.CustomException('WSI_CTRL.prepareResponse() not implemented!');
	    }

		public virtual void parseRequestJSON() {
			try {
                requestJSON = new Map<String, Object>();
                if (apiResp.apiRestRequest.httpMethod != 'GET'){
                    requestJSON = (Map<String, Object>)JSON.deserializeUntyped(apiResp.apiRestRequest.requestBody.toString());
                }
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
		
		public void contextRecordNotModified(String message) {
			apiResp.addApiError(UTIL_WSC.HTTP_NOTMODIFIED,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_NOTMODIFIED),message);
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

		public void validateSObjectFieldsAccess(String sObjectName, Map<String,String> fieldsToUpdate) {
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

		public Map<String,String> reverseMap(Map<String,String> mapToReverse) {
			Map<String,String> reversedMap = new Map<String,String>();
			for(String key : mapToReverse.keySet()) {
				reversedMap.put(mapToReverse.get(key),key);
			}
			return reversedMap;
		}
	}