/**
 * Created by GIS-DEV on 09/07/2017.
 */
public with sharing class WSI_API_SFECG_Account_v2 {

	private static final String APINAME = 'WSI_API_SFECG_Account_v2';

	public WSI_API_SFECG_Account_v2() {}

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

		private MapFieldValueHelper helper = new MapFieldValueHelper();

    	public String member {get;set;}
		public String uniqueLocalAccountId {get;set;}
		
		//JSON param
		public String localId {get;set;}
		public String localParentId {get;set;}
		public String accountExtId {get;set;}
		public String memberUnit {get;set;}
		public String accountName {get;set;}
		public String companyRegId {get;set;}
		public String phone {get;set;}
		public String otherPhone {get;set;}
		public String email {get;set;}
		public String type {get;set;}
		public String syncError {get;set;}
		
		public List<Map<String, String>> attributeData {get;set;}
		public List<Map<String, String>> addresseData {get;set;}
		public List<Map<String, String>> contactData {get;set;}
		
		public Account account {get; set;}
		public List<CustomAttribute__c> attributes {get;set;}
		public List<Contact> contacts {get;set;}
		
		// for created CustomAttributeDefinition__c that not exist
		public Map<String, CustomAttributeDefinition__c>attributesDefinition{get;set;}
		public void digestRequest(Map < String, Object > requestJSON) {
			try {
				this.localId = (String) requestJSON.get('localId');
				this.localParentId = (String) requestJSON.get('localParentId');
				this.accountExtId = (String) requestJSON.get('accountExtId');
				this.memberUnit = (String) requestJSON.get('memberUnit');
				this.memberUnit = this.memberUnit != null ? this.memberUnit.subString(0, 5) : this.memberUnit;
				this.accountName = (String) requestJSON.get('accountName');
				this.companyRegId = (String) requestJSON.get('companyRegId');
				this.phone = (String) requestJSON.get('phone');
				this.otherPhone = (String) requestJSON.get('otherPhone');
				this.email = (String) requestJSON.get('email');
				this.type = (String) requestJSON.get('type');
				this.syncError = (String) requestJSON.get('syncError');

				this.attributeData = attributeData((List < Object > ) requestJSON.get('attributes'));
				this.addresseData = addressData((List < Object > ) requestJSON.get('addresses'));
				this.contactData = contactData((List < Object > ) requestJSON.get('contacts'));

			} catch (Exception e) {
				throw new UTIL.CustomException('Parameters in request body in incorrect format: ' + requestJSON + e.getMessage());
			}

		}

		private List < Map < String, String >> attributeData(List < Object > attributeJSON) {
			List < Map < String, String >> attributeData = new List < Map < String, String >> ();
			
			if (attributeJSON == null) return attributeData;
			
			for (Object obj: attributeJSON) {
				Map < String, String > attr = new Map < String, String > ();
				Map < String, Object > mCA = (Map < String, Object > ) obj;
				attr.put('value', String.valueOf(mCA.get('value')));
				attr.put('name', String.valueOf(mCA.get('name')));
				attributeData.add(attr);
			}
			return attributeData;
		}

		private List < Map < String, String >> addressData(List < Object > addressJSON) {

			List < Map < String, String >> addressData = new List < Map < String, String >> ();
			
			if (addressJSON == null) return addressData;
			
			for (Object obj: addressJSON) {
				Map < String, Object > mAddr = (Map < String, Object > ) obj;
				Map < String, String > addr = new Map < String, String > ();
				addr.put('type', String.valueOf(mAddr.get('type')));
				addr.put('street', String.valueOf(mAddr.get('street')));
				addr.put('city', String.valueOf(mAddr.get('city')));
				addr.put('state', String.valueOf(mAddr.get('state')));
				addr.put('postalCode', String.valueOf(mAddr.get('postalCode')));
				addr.put('countryCode', String.valueOf(mAddr.get('countryCode')));
				addr.put('latitude', String.valueOf(mAddr.get('latitude')));
				addr.put('longitude', String.valueOf(mAddr.get('longitude')));

				addressData.add(addr);
			}
			return addressData;
		}

		private List < Map < String, String >> contactData(List < Object > contactJSON) {
			List < Map < String, String >> contactData = new List < Map < String, String >> ();
			if (contactJSON == null) return contactData;

			for (Object obj: contactJSON) {
				Map < String, Object > mCon = (Map < String, Object > ) obj;
				Map < String, String > con = new Map < String, String > ();
				con.put('type', String.valueOf(mCon.get('type')));
				con.put('firstName', String.valueOf(mCon.get('firstName')));
				con.put('lastName', String.valueOf(mCon.get('lastName')));
				con.put('salutation', String.valueOf(mCon.get('salutation')));
				con.put('email', String.valueOf(mCon.get('email')));
				con.put('phone', String.valueOf(mCon.get('phone')));
				con.put('localPlatformId', String.valueOf(mCon.get('localPlatformId')));
				con.put('subscriptions', String.valueOf(mCon.get('subscriptions')));

				contactData.add(con);
			}
			return contactData;
		}

		public void initAccount() {
			try {
				String memberUnitId = this.memberUnit;
				this.uniqueLocalAccountId = memberUnitId + '_' + this.localId;

				this.account = new Account();
				if (this.localId != null) {
					this.account = new Account(UniquePlatformId__c = this.uniqueLocalAccountId);
					for (sObject account: GW_sObject.queryRecords('Account', 'UniquePlatformId__c =\'' + this.uniqueLocalAccountId + '\'')) {
						this.account = (Account) account;
						break;
					}
				}

				if (this.account.Id == null) {
					populateAccountData();
				}

			} catch (Exception ex) {
				throw ex;
			}
		}

		private void populateAccountData() {

			this.account.RecordTypeID = UTIL_RecordType.getRecordTypeByName('Account', 'Agency').Id;
			this.account.Name = this.accountName;
			this.account.AccountExtId__c = this.accountExtId;
			this.account.Company_Reg_No__c = this.companyRegId;
			this.account.Phone = this.phone;
			this.account.Other_Phone__c = this.otherPhone;
			this.account.Email__c = this.email;

			this.account.type = helper.getAccountTypeMappingValue(this.type);
			this.account.Sync_Error__c = this.syncError;
			this.account.Email__c = this.email;
			
			this.attributes = new List < CustomAttribute__c > ();
			this.attributesDefinition = new Map < String, CustomAttributeDefinition__c > ();
			
			for (Map < String, String > attrData: this.attributeData) {
				CustomAttribute__c ca = GW_CustomAttribute.createSObject(attrData.get('name'), attrData.get('value'));
				this.attributes.add(ca);

				// mapped missing CustomAttributeDefinition__c for CustomAttribute__c valueType
				if (!this.attributesDefinition.containsKey(ca.ValueType__c)) {
					this.attributesDefinition.put(ca.ValueType__c, new CustomAttributeDefinition__c(AttributeType__c = ca.ValueType__c, Object__c = 'Account', AttributeKey__c = ca.Name));
				}
			}

			//populate address
			for (Map < String, String > mAddr: this.addresseData) {

				String addrType = mAddr.get('type');
				String street = mAddr.get('street');
				String city = mAddr.get('city');
				String state = mAddr.get('state');
				String postalCode = mAddr.get('postalCode');
				String countryCode = mAddr.get('countryCode');
				Double latitude = mAddr.get('latitude') == null ? 0 : Double.valueOf(mAddr.get('latitude'));
				Double longitude = mAddr.get('longitude') == null ? 0 : Double.valueOf(mAddr.get('longitude'));
				
				if (addrType.equalsIgnoreCase('BILLING')) {
					this.account.BillingStreet = street;
					this.account.BillingCity = city;
					this.account.BillingState = state;
					this.account.BillingPostalCode = postalCode;
					this.account.BillingCountryCode = countryCode;
					this.account.BillingLatitude = latitude;
					this.account.BillingLongitude = longitude;
				} else if (addrType.equalsIgnoreCase('SHIPPING')) {
					this.account.ShippingStreet = street;
					this.account.ShippingCity = city;
					this.account.ShippingState = state;
					this.account.ShippingPostalCode = postalCode;
					this.account.ShippingCountryCode = countryCode;
					this.account.ShippingLatitude = latitude;
					this.account.ShippingLongitude = longitude;
				} else if (addrType.equalsIgnoreCase('TRADING')) {
					this.account.ServiceStreet__c = street;
					this.account.ServiceCity__c = city;
					this.account.ServiceState__c = state;
					this.account.ServicePostalCode__c = postalCode;
					this.account.ServiceCountry__c = helper.getServiceCountryCodeMappingValue(countryCode);
					//this.account.ShippingLatitude 	= Double.valueOf(latitude);
					//this.account.ShippingLongitude 	= Double.valueOf(longitude);
				}
			}

			//populate contact
			this.contacts = new List < Contact > ();
			for (Map < String, String > mCon: this.contactData) {
				Contact con = new Contact();
				con.FirstName = mCon.get('firstName');
				con.LastName = mCon.get('lastName');
				con.Salutation = mCon.get('salutation');
				con.Email = mCon.get('email');
				con.Phone = mCon.get('phone');
				con.Local_Platform_Id__c = mCon.get('localPlatformId');
				con.Subscriptions__c = helper.getContactSubscriptionsMappingValue(mCon.get('subscriptions'));
				con.Role__c = helper.getContactTypeMappingValue(mCon.get('type'));
				this.contacts.add(con);
			}
		}

	} // end InboundAccount

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
				objectId = pathParts.get(pathParts.size() - 1);
			}
			if (pathParts.size() > 1) {
				String memberId = pathParts.get(pathParts.size() - 2);
				if (memberId.length() == 5) {
					uniquePlatformId = memberId + '_' + objectId;
				}
			}

			parseRequestJSON();
			inboundAccount.digestRequest(requestJSON);
			inboundAccount.initAccount();

			UTIL.log('inboundAccount ' + inboundAccount);

			uniquePlatformId = inboundAccount.memberUnit + '_' + inboundAccount.localId;

			String whereClause = null;
			if (uniquePlatformId != null) {
				whereClause = 'UniquePlatformId__c = \'' + uniquePlatformId + '\'';
			} else if (String.isNotBlank(objectId) && (objectId.length() == 15 || objectId.length() == 18)) {
				whereClause = 'Id = \'' + objectId + '\'';
			}

			if (whereClause == null) {
				contextRecordNotFound('No Salesforce Id or Local Platform Id supplied.');
			}

			try {
				contextRecord = (sObject) inboundAccount.account;
				for (sObject obj: GW_sObject.queryRecords('Account', whereClause)) {
					contextRecord = obj;
					break;
				}
			} catch (Exception e) {
				contextRecordNotFound('Failed to find Account using provided Salesforce Id: ' + objectId + ' or Local Platform Id:' + uniquePlatformId);
			}
		}

		public override void prepareResponse() {
			Map < String, String > responseMap = new Map < String, String > ();

			responseMap.put('accountExId', inboundAccount.account.Id);
			responseMap.put('accountName', inboundAccount.account.Name);

			if (contextRecord != null) {
				apiResp.linklog('Account', contextRecord.Id);
			}
			apiResp.setResponse(responseMap);
		}

	}
	//END WSI_AccountApiRequest


	public class AccountInsert extends WSI_AccountApiRequest {

		public override void prepareUpdate() {}

		public override void validateData() {
			
			if (String.isEmpty(inboundAccount.type)) {
				contextRecordNotFound('Failed to Insert Account, type is required');
			}
			
			if (String.isEmpty(inboundAccount.memberUnit)) {
				contextRecordNotFound('Failed to Insert Account, memberUnit is required');
			}
			
			Member__c member = getMemberUnit(inboundAccount.memberUnit);
			if(member == null) contextRecordNotFound('Failed to Insert Account, invalid memberUnit : ' + inboundAccount.memberUnit);
			
			// check all required field
			String errorMessage;
			for (String fieldKey: requestJSON.keySet()) {
				if (fieldKey == 'addresses') {
					List<Object>addresses = (List < Object > ) requestJSON.get(fieldKey);
					for(Object addr : addresses){
						Map<String, Object>addressFields = (Map<String, Object>)addr;
						if(!addressFields.containsKey('type')) { errorMessage = 'Failed to Insert Account with addresses, type of address is required'; break; }
					}
				}
				if (fieldKey == 'contacts') {
					List<Object>contacts = (List < Object > ) requestJSON.get(fieldKey);
					for(Object contact : contacts){
						Map<String, Object>contactFields = (Map<String, Object>)contact;
						if(!contactFields.containsKey('type')) { errorMessage = 'Failed to Insert Account with contacts, type of contact is required'; break; }
						if(!contactFields.containsKey('lastName')) { errorMessage = 'Failed to Insert Account with contacts, lastName of contact is required'; break; }
						if(!contactFields.containsKey('localPlatformId')) { errorMessage = 'Failed to Insert Account with contacts, localPlatformId of contact is required'; break; }
						if(!contactFields.containsKey('email')) { errorMessage = 'Failed to Insert Account with contacts, email of contact is required'; break; }
					}
				}
				
				if(errorMessage != null) { contextRecordNotFound(errorMessage); break; }
			}			
			
		}

		public override void executeDML() {
			Savepoint sp = Database.setSavepoint();
			try {
				upsert inboundAccount.account;
				
				Member__c member = getMemberUnit(inboundAccount.memberUnit);
				insertCustomAttributeDefinition(member.DefaultMemberUnit__c, inboundAccount.attributesDefinition);
				insertCustomAttribute(inboundAccount.account.Id, member.DefaultMemberUnit__c, inboundAccount.attributes, inboundAccount.attributesDefinition);
				updateMemberUnit(inboundAccount.account.Id, member.Id);
				insertContact(inboundAccount.account.Id, inboundAccount.contacts);
			} catch (DmlException e) {
				Database.rollback(sp);
				throw e;
			}

		}

		private void insertCustomAttributeDefinition(String memberUnitId, Map < String, CustomAttributeDefinition__c > attributesDefinition) {
			if (attributesDefinition == null) return;
			
			// check existing CustomAttributeDefinition__c
			Map<String, CustomAttributeDefinition__c>existingCAD = new Map<String, CustomAttributeDefinition__c>();
			for(sObject sobj: GW_sObject.queryRecords('CustomAttributeDefinition__c', 'Object__c=\'Account\' AND MemberUnit__c = \'' + memberUnitId + '\'')){
				CustomAttributeDefinition__c cad = (CustomAttributeDefinition__c)sobj;
				String key = cad.AttributeType__c + cad.AttributeKey__c;
				existingCAD.put(key, cad);
			}	
					
			for (CustomAttributeDefinition__c cad: attributesDefinition.values()) {
				String key = cad.AttributeType__c + cad.AttributeKey__c;
				cad.MemberUnit__c = memberUnitId;
				if(existingCAD.containsKey(key)) cad.Id = existingCAD.get(key).Id;
			}
			upsert attributesDefinition.values();
		}

		private void insertCustomAttribute(Id accountId, String memberUnitId, List < CustomAttribute__c > atrributes, Map < String, CustomAttributeDefinition__c > attributesDefinition) {

			if (String.isNotBlank(accountId) && atrributes != null && !atrributes.isEmpty()) {
				
				List < CustomAttribute__c > caToUpdate = new List < CustomAttribute__c > ();
				for (CustomAttribute__c record: atrributes) {
					record.Account__c = accountId;
					record.MemberUnit__c = memberUnitId;
					record.ParentId__c = accountId;
					record.Record_UniqueKey__c = accountId + '_' + record.Name;
					record.CustomAttributeDefinition__c = attributesDefinition.get(record.ValueType__c).Id;
					caToUpdate.add(record);
					
				}
				upsert caToUpdate;
			}
		}

		private void insertContact(Id accountId, List < Contact > contacts) {
			if (String.isNotBlank(accountId) && contacts != null && !contacts.isEmpty()) {
				List < Contact > contactsToUpdate = new List < Contact > ();
				for (Contact record: contacts) {
					record.AccountId = accountId;
					contactsToUpdate.add(record);
				}
				upsert contactsToUpdate;
			}
		}

		private void updateMemberUnit(Id accountId, Id memberUnitId) {
			List < Account > accoutUpdate = [select Id, Member__c from Account where Id =: accountId limit 1];
			if (!accoutUpdate.isEmpty()) accoutUpdate.get(0).Member__c = memberUnitId;
			update accoutUpdate;
		}
		
		private Member__c getMemberUnit(String ecgMemberName){
			List < Member__c > ecgMemberId = [select Id, DefaultMemberUnit__c from Member__c where MemberId__c =: ecgMemberName limit 1];
			return !ecgMemberId.isEmpty() ? ecgMemberId.get(0) : null;
		}

	}

	public class AccountUpdate extends WSI_ApiRequest {
		private MapFieldValueHelper helper = new MapFieldValueHelper();

		public override void init(WSI_CTRL.APIResponse apiResp) {
			super.init(apiResp);
		}

		public override void setContextRecords() {
			String objectId;
			String whereClause = null;

			if (!pathParts.isEmpty()) {
				objectId = pathParts.get(pathParts.size() - 1);
			}

			if (String.isNotBlank(objectId) && (objectId.length() == 15 || objectId.length() == 18)) {
				whereClause = 'Id = \'' + objectId + '\'';
			}

			if (whereClause == null) {
				contextRecordNotFound('No Salesforce Id or Local Platform Id supplied.');
			}

			try {
				contextRecord = (GW_sObject.queryRecords('Account', whereClause).get(0));
			} catch (Exception e) {
				contextRecordNotFound('Failed to find Account using provided Salesforce Id: ' + objectId);
			}
		}

		public override void validateData() {
			// Every field, validate if value has changed, user has access to write to this field
			objectNameToFieldNameNewFieldValueMap = new Map < String, Map < String, String >> ();
			Map < String, String > accFieldsToUpdate = new Map < String, String > ();
			Map < String, String > accountFieldMap = helper.getAccountFieldMap();
			String errorMessage;
			
			try {
				
				// Extract changed fields
				for (String fieldKey: requestJSON.keySet()) {
					if (accountFieldMap.containsKey(fieldKey)) {
						// Check if value has changed
						if (String.valueOf(contextRecord.get(accountFieldMap.get(fieldKey))) != String.valueOf(requestJSON.get(fieldKey)) && (requestJSON.get(fieldKey) != null)) {
							accFieldsToUpdate.put(accountFieldMap.get(fieldKey), String.valueOf(requestJSON.get(fieldKey)));
							if (fieldKey == 'type') accFieldsToUpdate.put(accountFieldMap.get(fieldKey), helper.getAccountTypeMappingValue(String.valueOf(requestJSON.get(fieldKey))));
						}
					}

					if (fieldKey == 'attributes') {
						updateAccountCustomAttributes((List < Object > ) requestJSON.get(fieldKey));
					}
					if (fieldKey == 'addresses') {
						updateAccountAddresses((List < Object > ) requestJSON.get(fieldKey), accFieldsToUpdate);
					}
					if (fieldKey == 'contacts') {
						updateAccountContact((List < Object > ) requestJSON.get(fieldKey), fieldKey);
					}
				}
			} catch (Exception e) {
				apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST, UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST), 'Inside validateDate(): ' + e.getMessage() + ' - Line number:' + e.getLineNumber() + ' - Stack Trace: ' + e.getStackTraceString());
				throw new WSI_CTRL.APIException();
			}
			
			// Add to save container
			if (accFieldsToUpdate.size() > 0) {
				objectNameToFieldNameNewFieldValueMap.put('Account', accFieldsToUpdate);
				validateSObjectFieldsAccess('Account', accFieldsToUpdate);
				if(objectNameToFieldNameNewFieldValueMap.containsKey('Contacts'))
					validateSObjectFieldsAccess('Contact', objectNameToFieldNameNewFieldValueMap.get('Contacts'));
			} else {
				contextRecordNotModified('There are no fields changed.');
			}
		}

		public override void prepareUpdate() {
			try {
				if (objectNameToFieldNameNewFieldValueMap.containsKey('Account')) {
					for (String fieldName: objectNameToFieldNameNewFieldValueMap.get('Account').keySet()) {
						putSObjectValueAsCorrectType('Account', fieldName, objectNameToFieldNameNewFieldValueMap.get('Account'));
					}
					objectsToUpdate.put('account', contextRecord);
				}
			} catch (Exception e) {
				apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST, UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST), 'Prepare update error: ' + e.getMessage());
				throw new WSI_CTRL.APIException();
			}
		}

		public override void executeDML() {

			if (objectsToUpdate.containsKey('account')) {
				Account accToUpdate = (Account) objectsToUpdate.get('account');
				update accToUpdate;
			}
			if (objectsToUpdate.containsKey('contact')) {
				List<Contact> conToUpdate = (List<Contact>) objectsToUpdate.get('contact');
				update conToUpdate;
			}

			if(objectsToUpdate.containsKey('customAttributes')) {
                List<CustomAttribute__c> caList = (List<CustomAttribute__c>) objectsToUpdate.get('customAttributes');
                update caList;
            }
		}

		public override void prepareResponse() {

			Map < String, String > responseMap = new Map < String, String > ();
			Map < String, String > accountFieldMap = reverseMap(helper.getAccountFieldMap()); // Salesforce field name to json field name map

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

			if (contextRecord != null) {
				apiResp.linklog('Account', contextRecord.Id);
				responseMap.put('Account', contextRecord.Id);
			}
			apiResp.setResponse(responseMap);
		}

		// END WSI_ApiRequest OVERRIDES

		private void updateAccountCustomAttributes(List < Object > customAttributesList) {
			GW_CustomAttribute.cacheCustomAttributes(new List < sObject > {
				(SObject) contextRecord
			});
			
			Map < String, CustomAttribute__c > existingCAMap = new Map < String, CustomAttribute__c > ();
			List < CustomAttribute__c > caForUpdateList = new List < CustomAttribute__c > ();
			if (GW_CustomAttribute.objectCustomAttributesCache != null) {
				for (CustomAttribute__c ca: GW_CustomAttribute.objectCustomAttributesCache.get((Id) contextRecord.get('Id'))) {
					existingCAMap.put(ca.Name, ca);
				}
			}
			
			for (Object caObj: customAttributesList) {
				Map < String, Object > caMap = (Map < String, Object > ) caObj;
				objectNameToFieldNameNewFieldValueMap.put('customAttributes', new Map < String, String > ());
				// Such custom attribute exists already
				String attrKey = (String) caMap.get('name');
				if (existingCAMap.containsKey(attrKey)) {
					CustomAttribute__c ca = existingCAMap.get(attrKey);
					String attrValue = String.valueOf(caMap.get('value'));
					
					if (String.valueOf(GW_CustomAttribute.getValue(ca)) != String.valueOf(attrValue) && (attrValue != null)) {
						objectNameToFieldNameNewFieldValueMap.get('customAttributes').put(attrKey, attrValue);
						GW_CustomAttribute.setValue(ca, caMap.get('value'));
						caForUpdateList.add(ca);
					}
				}
			}
			if (caForUpdateList.size() > 0) {
				objectsToUpdate.put('customAttributes', caForUpdateList);
			}
		}

		private void updateAccountContact(List < Object > contacts, String contactType) {

			Map < Id, Contact > contacts2Update = new Map < Id, Contact > ();
			Map < String, String > contactFieldMap = helper.getContactFieldMap();
			Map<String,String> contactFieldsToUpdate = new Map<String,String>();
			
			for (Object contact: contacts) {
				Map < String, Object > confield = (Map < String, Object > ) contact;
				String conType = String.valueOf(confield.get('type'));
				
				Contact contactToUpdate;
				// Query the contact
	        	if(conType == 'FINANCE') {
	            	contactToUpdate = (Contact) GW_sObject.queryRecord('Contact', (Id)contextRecord.get('Finance_contact__c'));
	          	}else if(conType == 'PORTAL_USER') {
	            	contactToUpdate = (Contact) GW_sObject.queryRecord('Contact', (Id)contextRecord.get('Portal_User__c'));
	          	}else{
	          		for (sObject con: GW_sObject.queryRecords('Contact', 'AccountId=\'' + contextRecord.Id + '\' AND Local_Platform_Id__c = \'' + String.valueOf(conField.get('localPlatformId') + '\''))) {
						contactToUpdate = (Contact)con;
						break;
					}
	          	}
	          	
	          	for(String fieldName : confield.keySet()){
	          		if(fieldName.equalsIgnoreCase('TYPE')) continue;
	          		
	          		String apiField = contactFieldMap.get(fieldName);
	          		if(String.valueOf(contactToUpdate.get(apiField)) != String.valueOf(confield.get(fieldName)) && (confield.get(fieldName) != null)) {
	                	contactFieldsToUpdate.put(apiField, String.valueOf(confield.get(fieldName)));
	                	
	                	String fieldValue = String.valueOf(confield.get(fieldName));
	                	if(apiField == 'Subscriptions__c') fieldValue = helper.getContactSubscriptionsMappingValue(fieldValue);
	                	
	                	contactToUpdate.put(apiField, fieldValue);
	                }
	          	}
				if(!contacts2Update.containsKey(contactToUpdate.Id)) contacts2Update.put(contactToUpdate.Id, contactToUpdate);
			}
			objectNameToFieldNameNewFieldValueMap.put('Contacts', contactFieldsToUpdate);
			objectsToUpdate.put('contact', contacts2Update.values());
		}

		private void updateAccountAddresses(List < Object > objAddress, Map < String, String > accountFieldsToUpdate) {
			Map < String, String > accountFieldMap = helper.getAccountFieldMap();
			for (Object obj: objAddress) {
				Map < String, Object > mapAddr = (Map < String, Object > ) obj;
				
				String prefix = String.valueOf(mapAddr.get('type')).toLowerCase();
				prefix = prefix.equalsIgnoreCase('TRADING') ? 'service' : prefix;
				for (String addressKey: mapAddr.keySet()) {
					if (addressKey == 'type' || !accountFieldMap.containsKey(prefix + addressKey)) continue;
					
					String addrField = accountFieldMap.get(prefix + addressKey);
					String addrValue = String.valueOf(mapAddr.get(addressKey));
					addrValue = addrField == 'ServiceCountry__c' ? helper.getServiceCountryCodeMappingValue(addrValue) : addrValue;
					
					if (mapAddr.get(addressKey) != null && String.valueOf(contextRecord.get(addrField)) != addrValue) {
						accountFieldsToUpdate.put(addrField, addrValue);
					}
				}
			}
		}

	}

	//Mapping field helper
	class MapFieldValueHelper {
		
		Map < String, String > countryCodeMap;
		private Map < String, String > loadCountryCodeMap(){
			if(countryCodeMap != null) return countryCodeMap;
			
			countryCodeMap = new Map<String, String>();
			Map < String, String > countryCodeMap = new Map < String, String > ();
			Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
			List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
			for( Schema.PicklistEntry f : ple){
				countryCodeMap.put(f.getValue(), f.getLabel());
			}
			
			return countryCodeMap;
		}
		
		public String getServiceCountryCodeMappingValue(String countryCode) {
			countryCodeMap = loadCountryCodeMap();
			if(String.isEmpty(countryCode) || !countryCodeMap.containsKey(countryCode)) return null;
			return countryCodeMap.get(countryCode.toUpperCase());
		}
		
		public Map < String, String > getAccountFieldMap() {
			Map < String, String > accountFieldMap = new Map < String, String > ();

			// Fill Account mapping
			accountFieldMap.put('localId','LocalPlatformId__c');
           	accountFieldMap.put('accountExtId','AccountExtId__c');
           	accountFieldMap.put('localParentId','LocalPlatformId__c');
			accountFieldMap.put('accountName', 'Name');
			accountFieldMap.put('companyRegId', 'Company_Reg_No__c');
			accountFieldMap.put('phone', 'Phone');
			accountFieldMap.put('otherPhone', 'Other_Phone__c');
			accountFieldMap.put('email', 'Email__c');
			accountFieldMap.put('type', 'Type');
			accountFieldMap.put('syncError', 'Sync_Error__c');

			accountFieldMap.put('billingstreet', 'BillingStreet');
			accountFieldMap.put('billingcity', 'BillingCity');
			accountFieldMap.put('billingstate', 'BillingState');
			accountFieldMap.put('billingpostalCode', 'BillingPostalCode');
			accountFieldMap.put('billingcountryCode', 'BillingCountryCode');
			accountFieldMap.put('billinglatitude', 'BillingLatitude');
			accountFieldMap.put('billinglongitude', 'BillingLongitude');

			accountFieldMap.put('shippingstreet', 'ShippingStreet');
			accountFieldMap.put('shippingcity', 'ShippingCity');
			accountFieldMap.put('shippingstate', 'ShippingState');
			accountFieldMap.put('shippingpostalCode', 'ShippingPostalCode');
			accountFieldMap.put('shippingcountryCode', 'ShippingCountryCode');
			accountFieldMap.put('shippinglatitude', 'ShippingLatitude');
			accountFieldMap.put('shippinglongitude', 'ShippingLongitude');
			
			accountFieldMap.put('servicestreet', 'ServiceStreet__c');
			accountFieldMap.put('servicecity', 'ServiceCity__c');
			accountFieldMap.put('servicestate', 'ServiceState__c');
			accountFieldMap.put('servicepostalCode', 'ServicePostalCode__c');
			accountFieldMap.put('servicecountryCode', 'ServiceCountry__c');
			//accountFieldMap.put('shippinglatitude', 'ShippingLatitude');
			//accountFieldMap.put('shippinglongitude', 'ShippingLongitude');

			return accountFieldMap;
		}

		public Map < String, String > getContactFieldMap() {
			Map < String, String > contactFieldMap = new Map < String, String > ();
			contactFieldMap.put('firstName', 'FirstName');
			contactFieldMap.put('lastName', 'LastName');
			contactFieldMap.put('salutation', 'Salutation');
			contactFieldMap.put('email', 'Email');
			contactFieldMap.put('phone', 'Phone');
			contactFieldMap.put('localPlatformId', 'Local_Platform_Id__c');
			contactFieldMap.put('subscriptions', 'Subscriptions__c');
			contactFieldMap.put('type', 'Role__c');
			return contactFieldMap;
		}

		public String getAccountTypeMappingValue(String key) {
			if (String.isBlank(key)) return null;
			key = key.trim();
			Map < String, String > mAccountType = new Map < String, String > ();
			mAccountType.put('CAR_DEALER', 'Car Dealer');
			mAccountType.put('GROUP_ACCOUNT', 'GROUP_ACCOUNT');
			mAccountType.put('OEM_DEALER', 'OEM_DEALER');
			mAccountType.put('RECRUITER', 'RECRUITER');
			if (key.contains(',')) {
				String res = '';
				for (String s: key.split(',')) {
					res += mAccountType.get(s.trim()) + ';';
				}
				return res.trim().removeEnd(';');
			}
			return mAccountType.get(key);
		}

		public String getContactTypeMappingValue(String key) {
			if (String.isBlank(key)) return null;
			Map < String, String > mContactType = new Map < String, String > ();
			mContactType.put('PORTAL_USER', 'Portal User');
			mContactType.put('FINANCE', 'Finance Contact');
			mContactType.put('LOCATION_USER', 'Location User');
			mContactType.put('LEAD_EMAIL', 'Lead Email');
			mContactType.put('LEAD_EMAIL_CC', 'Lead Email CC');
			mContactType.put('REPORTING_EMAIL', 'Reporting Email');
			if (key.contains(',')) {
				String res = '';
				for (String s: key.split(',')) {
					res += mContactType.get(s.trim()) + ';';
				}
				return res.trim().removeEnd(';');
			}
			return mContactType.get(key);
		}

		public String getContactSubscriptionsMappingValue(String key) {
			if (String.isBlank(key)) return null;
			Map < String, String > mContactSubs = new Map < String, String > ();
			mContactSubs.put('PROSELLER_NEWSLETTER', 'PROSELLER NEWSLETTER');
			mContactSubs.put('PROSELLER_REPORT', 'PROSELLER REPORT');
			mContactSubs.put('PROMOTIONAL', 'PROMOTIONAL');
			mContactSubs.put('NEWSLETTER', 'NEWSLETTER');
			mContactSubs.put('REPORT', 'REPORT');
			mContactSubs.put('SURVEY', 'SURVEY');
			mContactSubs.put('INVITE', 'INVITE');
			mContactSubs.put('CAMPAIGN', 'CAMPAIGN');
			mContactSubs.put('THIRD_PARTY', 'THIRD PARTY');
			if (key.contains(',')) {
				String res = '';
				for (String s: key.split(',')) {
					res += mContactSubs.get(s.trim()) + ';';
				}
				return res.trim().removeEnd(';');
			}
			return mContactSubs.get(key);
		}

	}

}