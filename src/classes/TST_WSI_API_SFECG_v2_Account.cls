@isTest
public with sharing class TST_WSI_API_SFECG_v2_Account {
    @isTest static void TST_PUT_emptyRequest() {
		Test.startTest();
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		Account testAcc = [SELECT Id, Name FROM Account].get(0);
		Contact testContact = [SELECT Id, Name FROM Contact].get(0);
		CustomAttributeDefinition__c testCAD = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c].get(0);
		CustomAttribute__c testCA = [SELECT Id, Name FROM CustomAttribute__c].get(0);

		// Prepare request/response objects
		preparePUTRequestSalesforceId(req,res, testAcc.Id);
		req.requestBody = Blob.valueOf(JSON.serializePretty(new Map<String,String>()));

		// Launch request
		WSI_CTRL.putRequest();

		// Logging after process
		UTIL.log('RestRequest: ' + req);
		UTIL.log('RestResponse: ' + res);
		UTIL.log('RestResponseBody: ' + res.responseBody.toString());

		// Validate
		System.assertNotEquals(NULL,req);
		System.assertNotEquals(NULL,res);
		System.assertEquals('304',String.valueOf(res.StatusCode));
	}
	
	@isTest static void TST_POST_AccountInsert() {
		Test.startTest();
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		// Prepare request/response objects
		preparePOSTRequest(req, res);
		
		Map<String, Object> requestMap = buildAccountPOSTRequestJSON();
		req.requestBody = Blob.valueOf(JSON.serializePretty(requestMap));

		// Launch request
		WSI_CTRL.putRequest();

		// Logging after process
		UTIL.log('RestRequest: ' + req);
		UTIL.log('RestResponse: ' + res);
		UTIL.log('RestResponseBody: ' + res.responseBody.toString());

		// Validate
		System.assertNotEquals(NULL,req);
		System.assertNotEquals(NULL,res);
		System.assertEquals('200',String.valueOf(res.StatusCode));
		
		String accName = (String)requestMap.get('accountName');
		Account testAcc = [Select Name From Account Where Name=:accName limit 1];
		System.assertEquals(testAcc.Name, accName);
		
		List<Contact> contacts = [Select LastName From Contact limit 1];
		System.assertNotEquals(contacts.size(), 0);
	}

	@isTest static void TST_PUT_AccountNameUpdate() {
		Test.startTest();
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		Account testAcc = [SELECT Id, Name, OwnerId FROM Account].get(0);
		Contact testContact = [SELECT Id, Name FROM Contact].get(0);
		CustomAttributeDefinition__c testCAD = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c].get(0);
		CustomAttribute__c testCA = [SELECT Id, Name FROM CustomAttribute__c].get(0);

		// Prepare request/response objects
		preparePUTRequestSalesforceId(req,res, testAcc.Id);

		// Build request itself
		Map<String,String> requestMap = buildAccountRequestJSON();
		requestMap.put('accountName','updatedAccountName');
		req.requestBody = Blob.valueOf(JSON.serializePretty(requestMap));

		// Launch request
		WSI_CTRL.putRequest();

		// Validate
		UTIL.log('XXXXXXXXXXXX responsebody tostring(): ' + res.responseBody.toString());
		System.assertEquals('200',String.valueOf(res.StatusCode));

		System.assertNotEquals(testAcc.Name,'updatedAccountName');
		testAcc = [SELECT Id, Name FROM Account WHERE Name =: 'updatedAccountName'].get(0);
		System.assertEquals('updatedAccountName',testAcc.Name);
	}

	@isTest static void TST_PUT_AccountAddressUpdate() {
		Test.startTest();
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		Account testAcc = [SELECT Id, Name, OwnerId FROM Account].get(0);
		Contact testContact = [SELECT Id, Name FROM Contact].get(0);
		CustomAttributeDefinition__c testCAD = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c].get(0);
		CustomAttribute__c testCA = [SELECT Id, Name FROM CustomAttribute__c].get(0);

		// Prepare request/response objects
		preparePUTRequestSalesforceId(req,res, testAcc.Id);

		// Prepare Account
		testAcc.BillingStreet = '5th';
		testAcc.BillingCity = 'Berlin';
		testAcc.BillingCountry = 'Germany';
		testAcc.ShippingStreet = 'Main';
		testAcc.ShippingCity = 'Paris';
		testAcc.ShippingCountry = 'France';

		update testAcc;

		// Build request itself
		String jsonInput = '{ "accountName" : "updatedAccountName", "addresses" : [' +
				'{ "type" : "BILLING", "street" : "Leyland", "city" : "Ottawa", "countryCode" : "CA", "postalCode" : "90210"},' +
				'{ "type" : "SHIPPING", "street" : "First", "city" : "Buenos Aires", "countryCode" : "AR", "postalCode" : "99000"}' +
		']}';
		req.requestBody = Blob.valueOf(jsonInput);

		// Launch request
		WSI_CTRL.putRequest();

		// Validate
		UTIL.log('XXXXXXXXXXXX responsebody tostring(): ' + res.responseBody.toString());
		System.assertEquals('200',String.valueOf(res.StatusCode));

		System.assertNotEquals(testAcc.Name,'updatedAccountName');
		testAcc = [SELECT Id, Name, BillingStreet, BillingCity, BillingCountry, BillingPostalCode, ShippingPostalCode, ShippingStreet, ShippingCity, ShippingCountry FROM Account WHERE Name =: 'updatedAccountName'].get(0);
		System.assertEquals('updatedAccountName',testAcc.Name);
		System.assertEquals('Leyland',testAcc.BillingStreet);
		System.assertEquals('Ottawa',testAcc.BillingCity);
		System.assertEquals('Canada',testAcc.BillingCountry);
		System.assertEquals('90210',testAcc.BillingPostalCode);
		System.assertEquals('99000',testAcc.ShippingPostalCode);
		System.assertEquals('First',testAcc.ShippingStreet);
		System.assertEquals('Buenos Aires',testAcc.ShippingCity);
		System.assertEquals('Argentina',testAcc.ShippingCountry);
	}

	@isTest static void TST_PUT_AccountContactFieldsUpdate() {
		Test.startTest();
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		Account testAcc = [SELECT Id, Name, OwnerId, Portal_User__c FROM Account].get(0);
		Contact testContact = [SELECT Id, Name, FirstName, LastName, Email, Salutation FROM Contact].get(0);
		CustomAttributeDefinition__c testCAD = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c].get(0);
		CustomAttribute__c testCA = [SELECT Id, Name FROM CustomAttribute__c].get(0);

		// Create finance contact
		Contact financeContact = new Contact(FirstName = 'Gordon', LastName = 'Gecko', Email = 'gordon@gecko.com', Salutation = 'Mr.');
		insert financeContact;

		// Update relations between test objects
		testAcc.Portal_User__c = testContact.Id;
		testAcc.Finance_contact__c = financeContact.Id;
		update testAcc;

		testAcc = [SELECT Id, Name, OwnerId, Portal_User__c, Finance_contact__c FROM Account].get(0);
		System.assertEquals(testAcc.Portal_User__c,testContact.Id);
		System.assertEquals(testAcc.Finance_contact__c,financeContact.Id);
		// Prepare request/response objects
		preparePUTRequestSalesforceId(req,res,testAcc.Id);

		// Create test JSON body
		String jsonInput = '{ "accountName" : "updatedAccountName", "contacts" : [' +
				'{ "type" : "PORTAL_USER", "firstName" : "John", "lastName" : "Travolta", "email" : "john.travolta@vincent.vega", "salutation" : "Mr."},' +
				'{ "type" : "FINANCE", "firstName" : "Abraham", "lastName" : "Lincoln", "email" : "gordon@gecko.com", "salutation" : "Mr."}' +
		']}';

		req.requestBody = Blob.valueOf(jsonInput);

		// Launch request
		WSI_CTRL.putRequest();

		// Validate request
		UTIL.log('XXXXXXXXXXXX responsebody tostring(): ' + res.responseBody.toString());
		System.assertEquals('200',String.valueOf(res.StatusCode));

		// Validate account
		System.assertNotEquals(testAcc.Name,'updatedAccountName');
		testAcc = [SELECT Id, Name FROM Account].get(0);
		System.assertEquals('updatedAccountName',testAcc.Name);

		// Validate contact
		testContact = [SELECT Id, Name, FirstName, LastName, Email, Salutation FROM Contact WHERE FirstName =: 'John'].get(0);
		System.assertEquals('John',testContact.FirstName);
		System.assertEquals('Travolta',testContact.LastName);
		System.assertEquals('john.travolta@vincent.vega',testContact.Email);
		System.assertEquals('Mr.',testContact.Salutation);
		financeContact = [SELECT Id, Name, FirstName, LastName, Email, Salutation FROM Contact WHERE FirstName =: 'Abraham'].get(0);
		System.assertEquals('Abraham',financeContact.FirstName);
		System.assertEquals('Lincoln',financeContact.LastName);
		System.assertEquals('gordon@gecko.com',financeContact.Email);
		System.assertEquals('Mr.',financeContact.Salutation);
	}

	@isTest static void TST_PUT_UpdateDifferentCA() {
		Test.startTest();
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		Account testAcc = [SELECT Id, Name, OwnerId FROM Account].get(0);
		Contact testContact = [SELECT Id, Name FROM Contact].get(0);
		CustomAttributeDefinition__c testCAD = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c].get(0);
		CustomAttribute__c testCA = [SELECT Id, Name FROM CustomAttribute__c].get(0);

		// Prepare request/response objects
		preparePUTRequestSalesforceId(req,res, testAcc.Id);

		// Prepare request
		req.requestBody = Blob.valueOf(getCustomAttributesForTest(FALSE));

		// Launch request
		WSI_CTRL.putRequest();

		// Validate
		UTIL.log('XXXXXXXXXXXX responsebody tostring(): ' + res.responseBody.toString());
		System.assertEquals('200',String.valueOf(res.StatusCode));
		Contact testRefContact = [SELECT Id, Name FROM Contact WHERE Name = :'refThisContact'].get(0);
		Map<Id,CustomAttribute__c> tempCaMap = new Map<Id, CustomAttribute__c>([SELECT Id FROM CustomAttribute__c]);
		List<CustomAttribute__c> changedCA = GW_CustomAttribute.getList(tempCaMap.keySet());
		System.assertEquals(changedCA.size(),4);
		for(CustomAttribute__c ca : changedCA) {
			if(ca.Name == 'numberCAKey') System.assertEquals(String.valueOf(GW_CustomAttribute.getValue(ca)),'200');
			if(ca.Name == 'stringCAKey') System.assertEquals(String.valueOf(GW_CustomAttribute.getValue(ca)),'updatedCAValue');
			if(ca.Name == 'relToContactKey') System.assertEquals(String.valueOf(GW_CustomAttribute.getValue(ca)),testRefContact.Id);
			if(ca.Name == 'relToAccountKey') System.assertEquals(String.valueOf(GW_CustomAttribute.getValue(ca)),testAcc.Id);
		}
	}

	@isTest static void TST_PUT_AccountContactFieldsUpdateErrorNoMatch() {
		Test.startTest();
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		Account testAcc = [SELECT Id, Name, OwnerId, Portal_User__c FROM Account].get(0);
		Contact testContact = [SELECT Id, Name, FirstName, LastName, Email, Salutation FROM Contact].get(0);
		CustomAttributeDefinition__c testCAD = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c].get(0);
		CustomAttribute__c testCA = [SELECT Id, Name FROM CustomAttribute__c].get(0);

		testAcc.Portal_User__c = testContact.Id;
		update testAcc;

		testAcc = [SELECT Id, Name, OwnerId, Portal_User__c FROM Account].get(0);
		System.assertEquals(testAcc.Portal_User__c,testContact.Id);
		// Prepare request/response objects
		preparePUTRequestSalesforceId(req,res, testContact.Id); // wrong id to get 404

		Map<String,String> accountRequestJSON = buildAccountRequestJSON();
		req.requestBody = Blob.valueOf(JSON.serializePretty(accountRequestJSON));

		// Launch request
		WSI_CTRL.putRequest();

		// Validate if proper error happened
		System.assertEquals('404',String.valueOf(res.StatusCode));
		System.assertEquals(String.valueOf(res.responseBody.toString()).contains(UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_NOTFOUND)),TRUE);
	}

	private static String getCustomAttributesForTest(Boolean lockStringRecord) {
		String finalJSON = '';

		// Get existing CAs and CADs,
		Account testAcc = [SELECT Id, Name, OwnerId, Portal_User__c FROM Account].get(0);
		Contact testContact = [SELECT Id, Name FROM Contact].get(0);
		List<CustomAttributeDefinition__c> testCADList = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c];
		List<CustomAttribute__c> testCAList = [SELECT Id, Name FROM CustomAttribute__c];
		List<MemberUnit__c> testMUList = [SELECT Id, Name FROM MemberUnit__c];

		// Delete existing CA&CADs, we want clean slate
		delete testCAList;
		delete testCADList;

		// Create objects to-be-referenced
		Account refThisAccount = new Account(Name='refAccountName',BillingStreet='Street',BillingPostalCode='1Nl1',BillingCountryCode='NL',BillingCity='City');
		insert refThisAccount;
		Contact refThisContact = GW_Contact.insertSObject('refThisContact', refThisAccount);

		finalJSON += '{ "accountName" : "' + refThisAccount.Name + '"';
		// Create containers for CADs and CAs
		List<Map<String,String>> caList = new List<Map<String,String>>();

		// Create number, string, date, relationship custom attributes
		CustomAttributeDefinition__c numberCAD = TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Account','Number');
		numberCAD.ApiUpdateable__c = TRUE;
		update numberCAD;
		CustomAttributeDefinition__c stringCAD = TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Account','String');
		stringCAD.ApiUpdateable__c = !lockStringRecord;
		update stringCAD;
		CustomAttributeDefinition__c relToContactCAD = TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Account','Relationship');
		relToContactCAD.ApiUpdateable__c = TRUE;
		relToContactCAD.RelationshipTarget__c = 'Contact';
		update relToContactCAD;
		CustomAttributeDefinition__c relToAccountCAD = TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Account','Relationship');
		relToAccountCAD.ApiUpdateable__c = TRUE;
		relToAccountCAD.RelationshipTarget__c = 'Account';
		update relToAccountCAD;

		List<CustomAttributeDefinition__c> createdCADList = [SELECT Id, Name FROM CustomAttributeDefinition__c];
		System.assertEquals(4,createdCADList.size());

		finalJSON += ', "attributes" : [';

		// Create corresponding CAs
		CustomAttribute__c numberCA = TST_DataFactory.createCustomAttributeForAccount(numberCAD,'numberCAKey',testAcc.Id);
		GW_CustomAttribute.setValue(numberCA,100);
		update numberCA;
		finalJSON += '{"name" : "numberCAKey", "value" : "200"}';

		CustomAttribute__c stringCA = TST_DataFactory.createCustomAttributeForAccount(stringCAD,'stringCAKey',testAcc.Id);
		GW_CustomAttribute.setValue(stringCA,'stringCAValue');
		update stringCA;
		finalJSON += ',{"name" : "stringCAKey", "value" : "updatedCAValue"}';

		CustomAttribute__c relToContactCA = TST_DataFactory.createCustomAttributeForAccount(relToContactCAD,'relToContactKey',testAcc.Id);
		GW_CustomAttribute.setValue(relToContactCA,testContact.Id);
		update relToContactCA;
		finalJSON += ',{"name" : "relToContactKey", "value" : "' + refThisContact.Id + '"}';

		CustomAttribute__c relToAccountCA = TST_DataFactory.createCustomAttributeForAccount(relToAccountCAD,'relToAccountKey',testAcc.Id);
		GW_CustomAttribute.setValue(relToAccountCA,refThisAccount.Id);
		update relToContactCA;
		finalJSON += ',{"name" : "relToAccountKey", "value" : "' + testAcc.Id + '"}';

		List<CustomAttribute__c> createdCAList = [SELECT Id, Name FROM CustomAttribute__c];
		System.assertEquals(4,createdCAList.size());

		finalJSON += ']}';
		return finalJSON;
	}

	private static void preparePOSTRequest(RestRequest req, RestResponse res) {
		req.requestURI = '/api/v2/accounts/';
		req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;
	}

	private static void preparePUTRequestLocalId(RestRequest req, RestResponse res, String localId) {
		req.requestURI = '/api/v2/accounts/' + localId;
		req.httpMethod = 'PUT';
		RestContext.request = req;
		RestContext.response = res;
	}

	private static void preparePUTRequestSalesforceId(RestRequest req, RestResponse res, Id salesforceId) {
		req.requestURI = '/api/v2/accounts/' + salesforceId;
		req.httpMethod = 'PUT';
		RestContext.request = req;
		RestContext.response = res;
	}

	private static Map<String,String> buildAccountRequestJSON() {
		Map<String, String> requestMap = new Map<String,String>();
		requestMap.put('accountName','testPUTREQUEST_NAME');
		return requestMap;
	}
	
	private static Map<String, Object> buildAccountPOSTRequestJSON() {
		Map<String, Object> requestMap = new Map<String,Object>();
		requestMap.put('accountName','testPOSTREQUEST_NAME');
		requestMap.put('type','CAR_DEALER');
		requestMap.put('memberUnit','GTAUG');
		
		Map<String, Object> attributeMap = new Map<String, Object>();
		attributeMap.put('value', '123456');
		attributeMap.put('name', 'AU_ACCOUNT_EXTERNAL_ID');
		requestMap.put('attributes', new List<Map<String, Object>>{attributeMap});
		
		Map<String, Object> addressMap = new Map<String, Object>();
		addressMap.put('type', 'BILLING');
		addressMap.put('street', '22/1 York Street');
		addressMap.put('city', 'Sydney');
		addressMap.put('postalCode', '2000');
		addressMap.put('countryCode', 'AU');
		requestMap.put('addresses', new List<Map<String, Object>>{addressMap});
		
		Map<String, Object> contactMap = new Map<String, Object>();
		contactMap.put('type', 'PORTAL_USER');
		contactMap.put('lastName', 'Smith');
		contactMap.put('email', 'johnSmith@gmail.com');
		contactMap.put('localPlatformId', 'localPlatformId1');
		contactMap.put('subscriptions', 'PROSELLER_NEWSLETTER, PROSELLER_REPORT');
		requestMap.put('contacts', new List<Map<String, Object>>{contactMap});
		return requestMap;
	}

	private static void prepareDefaultDataSet() {
		// Create Account
		TST_DataFactory.createBasicAccount(1);
		List<Account> testAccList = [SELECT Id, Name FROM Account];
		System.assertNotEquals(FALSE,(testAccList.size() > 0));
		// Create Contact
		TST_DataFactory.createBasicContact(testAccList.get(0));
		List<Contact> testContactList = [SELECT Id, FirstName, LastName FROM Contact];
		System.assertNotEquals(0,testContactList.size());
		// Create Member Unit and Member
		TST_DataFactory.createMemberUnit(testAccList.get(0).Id);
		List<MemberUnit__c> testMUList = [SELECT Id, Name FROM MemberUnit__c];
		System.assertNotEquals(FALSE,(testMUList.size() > 0));
		
		List<Member__c> testMemberList = [SELECT Id, MemberId__c, DefaultMemberUnit__c, Name FROM Member__c];
		System.assertNotEquals(FALSE,(testMemberList.size() > 0));
		testMemberList[0].MemberId__c = 'GTAUG';
		testMemberList[0].DefaultMemberUnit__c = testMUList[0].Id;
		update testMemberList;
		
		// Create AMUA
		TST_DataFactory.createAccountMemberUnitAssociation(testMUList.get(0).Id,testAccList.get(0).Id);
		List<AccountMemberUnitAssociation__c> amuaList = [SELECT Id, Name FROM AccountMemberUnitAssociation__c];
		System.assertNotEquals(FALSE,(amuaList.size() > 0));
		// Create CAD for given Account
		TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Account','String');
		List<CustomAttributeDefinition__c> testCADList = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c];
		System.assertNotEquals(FALSE,(testCADList.size() > 0));
		// Create CA for given Account and CAD
		TST_DataFactory.createCustomAttributeForAccount(testCADList.get(0), 'testKey', testAccList.get(0).Id);
		List<CustomAttribute__c> testCAList = [SELECT Id, Name FROM CustomAttribute__c];
		System.assertNotEquals(FALSE,(testCAList.size() > 0));
	}
}