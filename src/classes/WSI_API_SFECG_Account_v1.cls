public with sharing class WSI_API_SFECG_Account_v1 {
 
	private static final String APINAME = 'WSI_API_SFECG_Account_v1';

	public WSI_API_SFECG_Account_v1 () {}

	public static void process(String wsClassName, WSI_CTRL.APIResponse resp, InboundAccount inboundAccount) {
			Type t = Type.forName(APINAME + '.' + wsClassName);
			WSI_AccountApiRequest apiRequest = (WSI_AccountApiRequest) t.newInstance();

			apiRequest.init(resp, inboundAccount);
			apiRequest.processRequest(); 
	}

	public static void process(String wsClassName, WSI_CTRL.APIResponse resp) {
	      Type t = Type.forName(APINAME + '.' + wsClassName);
	      WSI_ApiRequest WSI_ApiRequest = (WSI_ApiRequest) t.newInstance();
	      WSI_ApiRequest.init(resp);
	      WSI_ApiRequest.processRequest(); 
	}


	public class InboundAccount {

    public String member {get;set;}
		public String uniqueLocalAccountId {get;set;}
		public String localId {get;set;}
		public String accountExtId {get;set;}
		public String memberUnit {get;set;}
		public String status {get;set;}
		public String accountName {get;set;}
		public String alternativeName {get;set;}
		public String vatId {get;set;}
		public String companyRegId {get;set;}
		public String phone {get;set;}
		public String otherPhone {get;set;}
		public String email {get;set;}
		public String invoiceDeliveryMethod {get;set;}
		public String inventoryUploadMethod {get;set;}
		public Map<String, String> billingAddress {get;set;}
		public Map<String, String> shippingAddress {get;set;}
		public Map<String, String> financialContact {get;set;}
		public Map<String, String> portalUser {get; set;}

		public Account account {get; set;}
		public List<Contact> contacts {get;set;}


		public void digestRequest(Map<String,Object> requestJSON) {

      try{
          this.localId = (String) requestJSON.get('localId');
          this.accountExtId = (String) requestJSON.get('accountExtId');
          this.memberUnit = (String) requestJSON.get('memberUnit');
          this.status = (String) requestJSON.get('status');
  				this.accountName = (String) requestJSON.get('accountName');
  				this.alternativeName = (String) requestJSON.get('alternativeName');
  				this.companyRegId = (String) requestJSON.get('companyRegId');
          this.phone = (String) requestJSON.get('phone');
          this.otherPhone = (String) requestJSON.get('otherPhone');
          this.email = (String) requestJSON.get('email');
          this.vatId = (String) requestJSON.get('vatId');
	        this.invoiceDeliveryMethod = (String) requestJSON.get('invoiceDeliveryMethod');
	        this.inventoryUploadMethod = (String) requestJSON.get('inventoryUploadMethod');
          this.billingAddress = addressData( (Map<String, Object>) requestJSON.get('billingAddress') );
          this.shippingAddress = addressData( (Map<String, Object>) requestJSON.get('shippingAddress') );
          this.financialContact = contactData( (Map<String, Object>) requestJSON.get('financialContact') );
          this.portalUser = contactData( (Map<String, Object>) requestJSON.get('portalUser') );

      } catch(Exception e) {
          throw new UTIL.CustomException('Parameters in request body in incorrect format: ' + requestJSON +  e.getMessage());
      }

  }


  public void initAccount() {
    try{
        String memberUnitId = this.memberUnit != null ? this.memberUnit.subString(0, 5) : this.memberUnit;
      	this.uniqueLocalAccountId = memberUnitId + '_' + this.localId;

      	if ( this.localId != null ) {
          List<sObject> accounts = GW_sObject.queryRecords('Account', 'UniquePlatformId__c =\'' + this.uniqueLocalAccountId + '\'');
          if( accounts.size() > 0 ) {
            this.account = (Account) accounts.get(0);
          } else {
            this.account = new Account( UniquePlatformId__c = this.uniqueLocalAccountId );
          }
        } else {
          this.account = new Account();
        }


      	if ( this.account.Id == null ) {

      		populateAccountData();
      	}
      }
      catch (Exception ex) {
        throw ex;
      }

  }

    private Map<String, String> addressData( Map<String, Object> addressJSON ) {
    	if ( addressJSON == null ) return null;
    	
    	Map<String, String> addressData = new Map<String, String>();
    	
    	addressData.put('street', (String) addressJSON.get('street') );
			addressData.put('city', (String) addressJSON.get('city') );
			addressData.put('state', (String) addressJSON.get('state') );
			addressData.put('postalCode', (String) addressJSON.get('postalCode') );
			addressData.put('country', (String) addressJSON.get('country') );
			addressData.put('countryCode', (String) addressJSON.get('countryCode') );
			addressData.put('stateCode', (String) addressJSON.get('stateCode') );
	
	   return addressData;
  }

		private Map<String, String> contactData ( Map<String, Object> contactJSON ) {
			if ( contactJSON == null ) return null;

			Map<String, String> contactData = new Map<String, String>();

			contactData.put('firstName', (String) contactJSON.get('firstName'));
			contactData.put('lastName', (String) contactJSON.get('lastName'));
			contactData.put('salutation', (String) contactJSON.get('salutation'));
			contactData.put('email', (String) contactJSON.get('email'));
			contactData.put('phone', (String) contactJSON.get('phone'));

			return contactData;
		}

		private void populateAccountData () {

    		this.account.RecordTypeID = UTIL_RecordType.getRecordTypeByName('Account', 'Agency').Id;
    		this.account.Name = this.accountName;
    		this.account.AccountExtId__c = this.accountExtId;
    		this.account.Status__c = this.status;
    		this.account.Account_Status__c = this.status;
    		this.account.AlternativeName__c = this.alternativeName;
    		this.account.Company_VAT_No__c = this.vatId;
    		this.account.Company_Reg_No__c = this.companyRegId;
    		this.account.Phone = this.phone;
    		this.account.Other_Phone__c = this.otherPhone;
    		this.account.Email__c = this.email;
    		this.account.InvoiceDeliveryMethod__c = this.invoiceDeliveryMethod;
    		this.account.InventoryUploadMethod__c = this.inventoryUploadMethod;
          
    		
    		// billing address
    		if ( this.billingAddress != null ) {
	    		this.account.BillingStreet = this.billingAddress.get('street');
	    		this.account.BillingCity = this.billingAddress.get('city');
	    		this.account.BillingState = this.billingAddress.get('state');
	    		this.account.BillingPostalCode = this.billingAddress.get('postalCode');
	    		this.account.BillingCountry = this.billingAddress.get('country');
	    	}

	    	if ( this.shippingAddress != null ) {
	    		// shipping address 
	    		this.account.ShippingStreet = this.shippingAddress.get('street');
	    		this.account.ShippingCity = this.shippingAddress.get('city');
	    		this.account.ShippingState = this.shippingAddress.get('state');
	    		this.account.ShippingPostalCode = this.shippingAddress.get('postalCode');
	    		this.account.ShippingCountry = this.shippingAddress.get('country');
    		}

    		this.contacts = new List<Contact>();

    		if ( this.financialContact != null ) {
    			
    			this.contacts.add(
    				new Contact(
    					FirstName = this.financialContact.get('firstName'),
    					LastName = this.financialContact.get('lastName'),
    					Salutation = this.financialContact.get('salutation'),
    					Email = this.financialContact.get('email'),
    					Phone = this.financialContact.get('phone'),
    					Role__c = 'Finance Contact'
    				)
    			);
    		
    		}

    		if ( this.portalUser != null ) {

    			this.contacts.add(
    				new Contact(
    					FirstName = this.portalUser.get('firstName'),
    					LastName = this.portalUser.get('lastName'),
    					Salutation = this.portalUser.get('salutation'),
    					Email = this.portalUser.get('email'),
    					Phone = this.portalUser.get('phone'),
    					Role__c = 'Portal User'
    				)
    			);

    		}


		}


	}// end InboundAccount



	////////////////////////////



    public virtual class WSI_AccountApiRequest extends WSI_ApiRequest {

        private InboundAccount inboundAccount;

        public void init(WSI_CTRL.APIResponse apiResp, InboundAccount inboundAccount) {
            this.inboundAccount = inboundAccount;
            init(apiResp);
        }

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

			parseRequestJSON();
            inboundAccount.digestRequest(requestJSON);
	        inboundAccount.initAccount();

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

	            List<sObject> records = GW_sObject.queryRecords('Account',whereClause);
	            if ( records != null && records.size() > 0 )
					contextRecord = records.get(0);
				else 
					contextRecord = (sObject) inboundAccount.account;

	        } catch (Exception e) {
				contextRecordNotFound('Failed to find Account using provided Salesforce Id: ' + objectId + ' or Local Platform Id:' + uniquePlatformId);
	        }
		}

        public override void prepareResponse() {
			Map<String,String> responseMap = new Map<String,String>();

			Map<String,String> accountFieldMap = reverseMap(getAccountFieldMap()); // Salesforce field name to json field name map

			//Object Name -> (SF Field name : value)
			responseMap.put('accountExtId', inboundAccount.account.Id);
			responseMap.put('accountName', inboundAccount.account.Name);

			if (contextRecord != null){
				apiResp.linklog('Account', contextRecord.Id);
			}
			apiResp.setResponse(responseMap);
		}

        protected Map<String,String> getAccountFieldMap() {
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



    }
    //END WSI_AccountApiRequest



	////////////////////////////////




	public class AccountInsert extends WSI_AccountApiRequest {

		public override void prepareUpdate() {}

        public override void validateData() {}

		public override void executeDML() {

   			Savepoint sp = Database.setSavepoint();
				
			try {
                upsert inboundAccount.account;
                insertContact(inboundAccount.account.Id, inboundAccount.contacts);
                updateMemberUnit(inboundAccount.account.Id, inboundAccount.memberUnit != null ? inboundAccount.memberUnit.subString(0, 5) : inboundAccount.memberUnit);
            }
            catch(DmlException e) {

				Database.rollback(sp);
                String eMsg = ''+e.getMessage();
                if (!eMsg.containsIgnoreCase('DUPLICATE') && !eMsg.containsIgnoreCase('UNABLE_TO_LOCK_ROW')){
                    throw e;
                }
            }

		}

		private void insertContact(Id accountId, List<Contact> contacts ) {
			if ( accountId != null && contacts != null && !contacts.isEmpty()) {
				
				List<Contact> contactsToUpdate = new List<Contact>();
				for(Contact record: contacts) {
					record.AccountId = accountId;
					contactsToUpdate.add(record);
				}

				upsert contactsToUpdate;
			}

		}

    private void updateMemberUnit(Id accountId, String ecgMemberName) {
        Account accoutUpdate = [select Id, Member__c from Account where Id =: accountId limit 1];
        Member__c ecgMemberId = [select Id from Member__c where MemberId__c =: ecgMemberName limit 1];
        if (accoutUpdate != null && ecgMemberId != null ) accoutUpdate.Member__c = ecgMemberId.Id;
        update accoutUpdate;
    }

	}


    public class AccountUpdate extends WSI_ApiRequest {

    //////////////////////////
    //WSI_ApiRequest overrides
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
              apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Inside validateDate(): '+e.getMessage() +' - Line number:'+e.getLineNumber()+' - Stack Trace: ' + e.getStackTraceString());
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

    // END WSI_ApiRequest OVERRIDES

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
            system.debug('contactFieldKey:'+contactMap.keySet());
              for(String contactFieldKey : contactMap.keySet()) {
                system.debug('x:'+contactFieldKey);
                  // Validate change
                  if(String.valueOf(contactToUpdate.get(contactFieldMap.get(contactFieldKey))) != String.valueOf(contactMap.get(contactFieldKey)) && (contactMap.get(contactFieldKey) != null)) {
                    system.debug('here contactfieldkey:'+contactFieldKey);
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



}