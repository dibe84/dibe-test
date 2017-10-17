@isTest
public with sharing class TST_WSI_API_SFECG_v1_Lead {
    
    static MemberUnit__c memUnit;
    static String leadId;
    private static void prepareDefaultDataSet() {
		// Create Account
		TST_DataFactory.createBasicAccount(1);
		List<Account> testAccList = [SELECT Id, Name FROM Account];
		System.assertNotEquals(FALSE,(testAccList.size() > 0));
		
		TST_DataFactory.createMemberUnit(testAccList.get(0).Id);
		List<MemberUnit__c> testMemUnitList = [Select Id, Member__c From MemberUnit__c];
		System.assertNotEquals(FALSE,(testMemUnitList.size() > 0));
		memUnit = testMemUnitList.get(0);
		
		TST_DataFactory.createLead('LeadName', 'LeadCompany', memUnit.Member__c, memUnit.Id);
		List<Lead> testLeadList = [Select Id From Lead];
		System.assertNotEquals(FALSE,(testLeadList.size() > 0));
		
		leadId = testLeadList.get(0).Id;
		
    }
    
	@isTest static void TST_PUT_LeadInsert() {
		
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		// Prepare request/response objects
		preparePUTRequestSalesforceId(req, res, null, false);

		// Build request itself
		Map<String,String> requestMap = buildLeadRequestJSON();
		req.requestBody = Blob.valueOf(JSON.serializePretty(requestMap));

		// Launch request
		WSI_CTRL.putRequest();

		// Validate
		UTIL.log('XXXXXXXXXXXX responsebody tostring(): ' + res.responseBody.toString());
		System.assertEquals('200', String.valueOf(res.StatusCode));

		Map<String, Object>mapResponse = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
		System.assert(mapResponse.containsKey('id'));
		
		String lId = String.valueOf(mapResponse.get('id'));
		
		List<Lead>lstLeads = [Select Id From Lead Where Id=:lId];
		System.assert(lstLeads.size() > 0);
		
	}

	@isTest static void TST_PUT_LeadUpdate() {
		
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		// Prepare request/response objects
		preparePUTRequestSalesforceId(req, res, leadId, false);

		// Build request itself
		String jsonInput = '{ "firstName" : "firstName" }';
		req.requestBody = Blob.valueOf(jsonInput);

		// Launch request
		WSI_CTRL.putRequest();

		// Validate
		UTIL.log('XXXXXXXXXXXX responsebody tostring(): ' + res.responseBody.toString());
		System.assertEquals('200', String.valueOf(res.StatusCode));

		Lead le = [SELECT FirstName From Lead Where Id=:leadId].get(0);
		System.assertEquals('firstName', le.FirstName);
	}

	@isTest static void TST_PUT_LeadConvert() {
		
		prepareDefaultDataSet();
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();

		// Prepare request/response objects
		preparePUTRequestSalesforceId(req, res, leadId, true);

		// Create test JSON body
		String jsonInput = '{ "lastName" : "lastName" }';

		req.requestBody = Blob.valueOf(jsonInput);

		// Launch request
		WSI_CTRL.putRequest();

		// Validate request
		UTIL.log('XXXXXXXXXXXX responsebody tostring(): ' + res.responseBody.toString());
		System.assertEquals('200', String.valueOf(res.StatusCode));
		
		Map<String, Object>mapResponse = (Map<String, Object>)JSON.deserializeUntyped(res.responseBody.toString());
		System.assert(mapResponse.containsKey('accountId'));
		System.assert(mapResponse.containsKey('contactId'));
		System.assert(mapResponse.containsKey('opportunityId'));
		
		String accId = String.valueOf(mapResponse.get('accountId'));
		List<Account>lstAccs = [Select Id From Account Where Id=:accId];
		System.assert(lstAccs.size() > 0);
		
		String conId = String.valueOf(mapResponse.get('contactId'));
		List<Contact>lstCons = [Select LastName, Id From Contact Where Id=:conId];
		System.assert(lstCons.size() > 0);
		System.assertEquals('lastName', lstCons.get(0).LastName);
		
		String oppId = String.valueOf(mapResponse.get('opportunityId'));
		List<Opportunity>lstOpps = [Select Id From Opportunity Where Id=:oppId];
		System.assert(lstOpps.size() > 0);
		
	}

	private static void preparePUTRequestLocalId(RestRequest req, RestResponse res, String localId) {
		req.requestURI = '/api/v1/leads/ECGDK/' + localId;
		req.httpMethod = 'PUT';
		RestContext.request = req;
		RestContext.response = res;
	}

	private static void preparePUTRequestSalesforceId(RestRequest req, RestResponse res, Id salesforceId, Boolean isConvert) {
		req.requestURI = '/api/v1/leads/' + (isConvert ? 'convert/' : '') + (salesforceId == null ? '' : salesforceId);
		req.httpMethod = 'PUT';
		RestContext.request = req;
		RestContext.response = res;
	}

	private static Map<String,String> buildLeadRequestJSON() {
		return new Map<String, String>{
			'salutation' => 'Mr.',
			'firstName' => 'test',
			'lastName' => 'test',
			'member' => memUnit.Member__c + '',
			'memberUnit' => memUnit.Id + '',
			'email' => 'test@test.com',
			'externalInfo' => 'test',
			'touch' => 'test',
			'street' => 'street',
			'city' => 'city',
			'postalCode' => 'postalCode',
			'state' => 'Alaska',
			'country' => 'United States',
			'leadSource' => 'Web',
			'status' => 'Open',
			'title' => 'test',
			'annualRevenue' => '0.0',
			'company' => 'test',
			'description' => 'test',
			'industry' => 'Banking',
			'mobilePhone' => 'mobilePhone',
			'phone' => 'phone',
			'website' => 'www.test.com'
		};
	}

}