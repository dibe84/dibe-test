global with sharing class F_SandboxInitialisation implements SandboxPostCopy  {
	static Set<String> systemFields = new Set<String>{'isdeleted', 'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid', 'systemmodstamp', 'lastvieweddate', 'lastreferenceddate'};
	public static String DefaultDataContainer = 'SBDC_Default';
	private static Map<Id, Id> idMap = new Map<Id, Id>();

	public class DataContainer {
		public Map<Id, Member__c> members = new Map<Id, Member__c>();
		public Map<Id, MemberUnit__c> memberUnits = new Map<Id, MemberUnit__c>();
		public Map<Id, Account> memberAccounts = new Map<Id, Account>();
		public Map<Id, CustomAttributeDefinition__c> customAttributeDefinitions = new Map<Id, CustomAttributeDefinition__c>();
		public Map<Id, Account> accounts = new Map<Id, Account>();
		public Map<Id, Contact> contacts = new Map<Id, Contact>();
		//public Map<Id, Content__c> contents = new Map<Id, Content__c>();
		public Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>();
		public Map<Id, OpportunityLineItem> opportunityLineItems = new Map<Id, OpportunityLineItem>();
		public Map<Id, echosign_dev1__SIGN_Agreement__c> agreements = new Map<Id, echosign_dev1__SIGN_Agreement__c>();
		public Map<Id, Rev__c> revs = new Map<Id, Rev__c>();
		public Map<Id, RS__c> rss = new Map<Id, RS__c>();
		public Map<Id, Metric__c> metrics = new Map<Id, Metric__c>();
		public Map<Id, Invoice__c> invoices = new Map<Id, Invoice__c>();
		public Map<Id, InvoiceLine__c> invoiceLines = new Map<Id, InvoiceLine__c>();
		public Map<Id, Lead> leads = new Map<Id, Lead>();
		public Map<Id, CustomAttribute__c> customAttributes = new Map<Id, CustomAttribute__c>();
		public Map<Id, AccountMemberUnitAssociation__c> amuas = new Map<Id, AccountMemberUnitAssociation__c>();
		//public Map<Id, WS_ScheduledCallout__c> scheduledCallouts = new Map<Id, WS_ScheduledCallout__c>();
		public Map<Id, WS_Log__c> wsLogs = new Map<Id, WS_Log__c>();
		public Map<Id, PortalProduct__c> portalProducts = new Map<Id, PortalProduct__c>();
		public Map<Id, PortalProductGrouping__c> portalProductGroupings = new Map<Id, PortalProductGrouping__c>();
		public Map<Id, Rule__c> rules = new Map<Id, Rule__c>();
		public Map<Id, RuleAssociation__c> ruleAssociations = new Map<Id, RuleAssociation__c>();
		public Map<Id, RuleToRule__c> ruleToRules = new Map<Id, RuleToRule__c>();
		public Map<Id, PermissionGroup__c> permissionGroups = new Map<Id, PermissionGroup__c>();
		public Map<Id, PermissionGroupAssignment__c> permissionGroupAssignments = new Map<Id, PermissionGroupAssignment__c>();
		public Map<Id, PermissionGroupRelationship__c> permissionGroupRelationships = new Map<Id, PermissionGroupRelationship__c>();
		public Map<Id, CommunityConfiguration__c> communityConfigurations = new Map<Id, CommunityConfiguration__c>();
		public Map<Id, Configuration__c> configurations = new Map<Id, Configuration__c>();
		public Map<Id, CustomJob__c> customJobs = new Map<Id, CustomJob__c>();
		public Map<Id, Custom_ECG_Labels__c> customEcgLabels = new Map<Id, Custom_ECG_Labels__c>();
		public Map<Id, DART_Advertiser_Type_Mapper__c> dartAtm = new Map<Id, DART_Advertiser_Type_Mapper__c>();
		public Map<Id, DART_Browser_Mapper__c> dartBm = new Map<Id, DART_Browser_Mapper__c>();
		public Map<Id, DART_OS_Mapper__c> dartOm = new Map<Id, DART_OS_Mapper__c>();
		public Map<Id, DevSettings__c> devSettings = new Map<Id, DevSettings__c>();
		public Map<Id, DNB_Settings__c> dnbSettings = new Map<Id, DNB_Settings__c>();
		public Map<Id, FieldValidation__c> fieldValidationSettings = new Map<Id, FieldValidation__c>();
		public Map<Id, MailTrigger__c> mailTriggers = new Map<Id, MailTrigger__c>();
		public Map<Id, MapInsight_AccountComponentConfiguration__c> mapInsightAcc = new Map<Id, MapInsight_AccountComponentConfiguration__c>();
		public Map<Id, MapInsight_Configuration__c> mapInsightConfigurations = new Map<Id, MapInsight_Configuration__c>();
		public Map<Id, MapInsight_Metric__c> mapInsightMetrics = new Map<Id, MapInsight_Metric__c>();
		public Map<Id, MapInsight_Object__c> mapInsightObjects = new Map<Id, MapInsight_Object__c>();
		public Map<Id, MapInsight_RecordFilter__c> mapInsightRecordFilters = new Map<Id, MapInsight_RecordFilter__c>();
		public Map<Id, MapInsight_RegionMapping__c> mapInsightRegionMappings = new Map<Id, MapInsight_RegionMapping__c>();
		public Map<Id, RecordRestrictions__c> recordRestrictions = new Map<Id, RecordRestrictions__c>();
		public Map<Id, RuleObjectMap__c> ruleObjectMaps = new Map<Id, RuleObjectMap__c>();
		public Map<Id, Webservice_Settings__c> webServiceSettings = new Map<Id, Webservice_Settings__c>();
		public Map<Id, WSC_Subscription__c> wscSubscriptionSettings = new Map<Id, WSC_Subscription__c>();

		//public Map<Id, Placement__c> placements = new Map<Id, Placement__c>();
		public Map<Id, Site__c> sites = new Map<Id, Site__c>();
	}

	// Creation
	public static DataContainer retrieveDataFromOrg() {
		DataContainer dc = new DataContainer();
		dc.members.putAll((List<Member__c>) GW_sObject.queryRecords('Member__c', '', null, null, systemFields));
		dc.memberUnits.putAll((List<MemberUnit__c>) GW_sObject.queryRecords('MemberUnit__c', '', null, null, systemFields));
		dc.memberAccounts.putAll((List<Account>) getParentRecords(dc.members, 'Account__c'));
		dc.customAttributeDefinitions.putAll((List<CustomAttributeDefinition__c>) getRelatedRecords(dc.memberUnits, 'CustomAttributeDefinitions__r'));
		dc.accounts.putAll((List<Account>) selectRandomAccounts(dc.members));
		dc.contacts.putAll((List<Contact>) getRelatedRecords(dc.accounts, 'Contacts'));
		/*dc.placements.putAll((List<Placement__c>) GW_sObject.queryRecords('Placement__c', ''));

        Set<Id> contentIds = new Set<Id>();
        for (Placement__c placement : dc.placements.values()) {
            if (placement.Content_Category_Site__c != null) {
                contentIds.add(placement.Content_Category_Site__c);
            }
        }
        if (contentIds.size() > 0) {
            dc.contents.putAll((List<Content__c>) GW_sObject.queryRecords('Content__c', contentIds));
        }*/
		dc.opportunities.putAll((List<Opportunity>) getRelatedRecords(dc.accounts, 'Opportunities'));
		dc.opportunityLineItems.putAll((List<OpportunityLineItem>) getRelatedRecords(dc.opportunities, 'OpportunityLineItems'));
		dc.agreements.putAll((List<echosign_dev1__SIGN_Agreement__c>) getRelatedRecords(dc.opportunities, 'echosign_dev1__R00N70000001hM2REAU__r'));
		dc.revs.putAll((List<Rev__c>) getRelatedRecords(dc.opportunities, 'Revenue_Items__r'));
		dc.rss.putAll((List<RS__c>) getRelatedRecords(dc.opportunities, 'Revenue_Schedules__r'));
		if (dc.rss.keySet().size() != 0) {
			dc.metrics.putAll((List<Metric__c>) getRelatedRecords(dc.rss, 'Metrics__r'));
		}
		dc.invoices.putAll((List<Invoice__c>) getRelatedRecords(dc.accounts, 'InvoicesN__r'));
		if (dc.invoices.keySet().size() != 0) {
			dc.invoiceLines.putAll((List<InvoiceLine__c>) getRelatedRecords(dc.invoices, 'InvoiceLines__r'));
		}
		dc.leads.putAll((List<Lead>) selectRandomLeads(dc.memberUnits));
		dc.customAttributes.putAll((List<CustomAttribute__c>) getRelatedRecords(dc.accounts, 'Custom_Attributes__r'));
		dc.customAttributes.putAll((List<CustomAttribute__c>) getRelatedRecords(dc.leads, 'Custom_Attributes__r'));
		dc.customAttributes.putAll((List<CustomAttribute__c>) getRelatedRecords(dc.contacts, 'Custom_Attributes__r'));
		dc.amuas.putAll((List<AccountMemberUnitAssociation__c>) getRelatedRecords(dc.accounts, 'MemberUnitAssociations__r'));
		//dc.scheduledCallouts.putAll((List<WS_ScheduledCallout__c>) GW_sObject.queryRecords('WS_ScheduledCallout__c', getRelatedWSSC(dc.accounts.values(), dc.revs.values())));
		//dc.wsLogs.putAll((List<WS_Log__c>) getRelatedRecords(dc.scheduledCallouts, 'WS_Logs__r'));
		dc.portalProductGroupings.putAll((List<PortalProductGrouping__c>)  GW_sObject.queryRecords('PortalProductGrouping__c', '', null, null, systemFields));
		dc.portalProducts.putAll((List<PortalProduct__c>) getRelatedRecords(dc.portalProductGroupings, 'PortalProducts__r'));
		dc.rules.putAll((List<Rule__c>) GW_sObject.queryRecords('Rule__c', '', null, null, systemFields));
		dc.ruleAssociations.putAll((List<RuleAssociation__c>) GW_sObject.queryRecords('RuleAssociation__c', '', null, null, systemFields));
		dc.ruleToRules.putAll((List<RuleToRule__c>) GW_sObject.queryRecords('RuleToRule__c', '', null, null, systemFields));
		dc.permissionGroups.putAll((List<PermissionGroup__c>) GW_sObject.queryRecords('PermissionGroup__c', '', null, null, systemFields));
		dc.permissionGroupAssignments.putAll((List<PermissionGroupAssignment__c>) GW_sObject.queryRecords('PermissionGroupAssignment__c', '', null, null, systemFields));
		dc.permissionGroupRelationships.putAll((List<PermissionGroupRelationship__c>) GW_sObject.queryRecords('PermissionGroupRelationship__c', '', null, null, systemFields));

		dc.sites.putAll((List<Site__c>) GW_sObject.queryRecords('Site__c', '', null, null, systemFields));

		dc.communityConfigurations.putAll((List<CommunityConfiguration__c>) CommunityConfiguration__c.getAll().values());
		dc.configurations.putAll((List<Configuration__c>) Configuration__c.getAll().values());
		dc.customJobs.putAll((List<CustomJob__c>) CustomJob__c.getAll().values());
		dc.customEcgLabels.putAll((List<Custom_ECG_Labels__c>) Custom_ECG_Labels__c.getAll().values());
		dc.dartAtm.putAll((List<DART_Advertiser_Type_Mapper__c>) DART_Advertiser_Type_Mapper__c.getAll().values());
		dc.dartBm.putAll((List<DART_Browser_Mapper__c>) DART_Browser_Mapper__c.getAll().values());
		dc.dartOm.putAll((List<DART_OS_Mapper__c>) DART_OS_Mapper__c.getAll().values());
		dc.devSettings.putAll((List<DevSettings__c>) DevSettings__c.getAll().values());
		dc.dnbSettings.putAll((List<DNB_Settings__c>) DNB_Settings__c.getAll().values());
		dc.fieldValidationSettings.putAll((List<FieldValidation__c>) FieldValidation__c.getAll().values());
		dc.mailTriggers.putAll((List<MailTrigger__c>) MailTrigger__c.getAll().values());
		dc.mapInsightAcc.putAll((List<MapInsight_AccountComponentConfiguration__c>) MapInsight_AccountComponentConfiguration__c.getAll().values());
		dc.mapInsightConfigurations.putAll((List<MapInsight_Configuration__c>) MapInsight_Configuration__c.getAll().values());
		dc.mapInsightMetrics.putAll((List<MapInsight_Metric__c>) MapInsight_Metric__c.getAll().values());
		dc.mapInsightObjects.putAll((List<MapInsight_Object__c>) MapInsight_Object__c.getAll().values());
		dc.mapInsightRecordFilters.putAll((List<MapInsight_RecordFilter__c>) MapInsight_RecordFilter__c.getAll().values());
		dc.mapInsightRegionMappings.putAll((List<MapInsight_RegionMapping__c>) MapInsight_RegionMapping__c.getAll().values());
		dc.recordRestrictions.putAll((List<RecordRestrictions__c>) RecordRestrictions__c.getAll().values());
		dc.ruleObjectMaps.putAll((List<RuleObjectMap__c>) RuleObjectMap__c.getAll().values());
		dc.webServiceSettings.putAll((List<Webservice_Settings__c>) Webservice_Settings__c.getAll().values());
		dc.wscSubscriptionSettings.putAll((List<WSC_Subscription__c>) WSC_Subscription__c.getAll().values());

		return dc;
	}

	private static Set<Id> getRelatedWSSC(List<Account> accounts, List<Rev__c> revs) {
		Set<Id> result = new Set<Id>();
		if (accounts.size() == 0 && revs.size() == 0) {
			return result;
		}
		result.addAll(GW_sObject.getIdSet(accounts));
		result.addAll(GW_sObject.getIdSet(revs));
		return result;
	}

	private static List<Lead> selectRandomLeads(Map<Id, MemberUnit__c> memberUnits) {
		List<Lead> result = new List<Lead>();
		for (MemberUnit__c mu : memberUnits.values()) {
			String leadQuery = 'MemberUnit__c = \'' + mu.Id + '\'';
			leadQuery += ' AND IsConverted = FALSE';
			leadQuery += ' LIMIT 1';
			result.addAll((List<Lead>) GW_sObject.queryRecords('Lead', leadQuery, null, null, systemFields));
		}
		return result;
	}

	private static List<Account> selectRandomAccounts(Map<Id, Member__c> members) {
		List<Account> result = new List<Account>();
		String baseQuery = 'Id IN (SELECT BillingAccount__c FROM Invoice__c) ';
		// For every member select up to 50 random accounts which have some data
		// Either an invoice, opportunity
		for (Member__c m : members.values()) {
			result.addAll((List<Account>) GW_sObject.queryRecords('Account', baseQuery + ' AND Member__c = \'' + m.Id + '\' LIMIT 1'));
		}
		return result;
	}

	private static List<sObject> getRelatedRecords(Map<Id, sObject> sObjects, String childRelationshipName) {
		if (sObjects == null || sObjects.values() == null || sObjects.values().size() == 0) {
			return new List<sObject>();
		}
		return GW_sObject.getChildren(sObjects.keySet(), childRelationshipName, null, null, systemFields);
	}

	private static List<sObject> getParentRecords(Map<Id, sObject> sObjects, String field) {
		Set<Id> retrieveIds = new Set<Id>();
		List<sObject> result = new List<sObject>();
		for (sObject sObj : sObjects.values()) {
			retrieveIds.add((Id) sObj.get(field));
		}
		Map<String, Set<Id>> objTypeIdSet = GW_sObject.splitIdSetByObjectType(retrieveIds);
		for (String sObjectType : objTypeIdSet.keySet() ) {
			result.addAll(GW_sObject.queryRecords(sObjectType, objTypeIdSet.get(sObjectType), null, null, systemFields));
		}
		return result;
	}

	public static void createStaticResource(String fileName, DataContainer dc) {
		String body = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(dc)));
		List<StaticResource> staticResources = [SELECT Id FROM StaticResource WHERE Name = :fileName];

		HttpRequest req = new HttpRequest();
		// in case this exists use PATCH
		if (staticResources.size() == 0) {
			req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v35.0/tooling/sobjects/StaticResource');
		} else {
			req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v35.0/tooling/sobjects/StaticResource/' + staticResources.get(0).Id + '?_HttpMethod=PATCH');
		}

		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
		req.setBody('{"Name":"'+filename+'"'+', "ContentType":"application/json"'+', "Body":"'+body+'"'+', "CacheControl":"Public"}');
		Http http = new Http();
		if (!Test.isRunningTest()) {
			HttpResponse res = http.send(req);
		}

		return;
	}

	public static void exportCurrentStatus(String fileName) {
		DataContainer dc = retrieveDataFromOrg();
		createStaticResource(fileName, dc);
		return;
	}

	// Application
	public static DataContainer parseDataFromStaticResource(String dcJson) {
		return (DataContainer) JSON.deserialize(dcJson, DataContainer.class);
	}

	public static void cleanOrg(String sbIdentifier) {
		// Lots of deletes!
		if (UTIL.isSandbox() || Test.isRunningTest()) {
			if (sbIdentifier != UTIL.orgIdentifier && !Test.isRunningTest()) {
				return;
			} else {
				TriggerManager.isSuspended = true;
				delete [SELECT Id FROM PermissionGroupRelationship__c];
				delete [SELECT Id FROM PermissionGroupAssignment__c];
				delete [SELECT Id FROM PermissionGroup__c];
				delete [SELECT Id FROM RuleToRule__c];
				delete [SELECT Id FROM RuleAssociation__c];
				delete [SELECT Id FROM Rule__c];
				delete [SELECT Id FROM PortalProduct__c];
				delete [SELECT Id FROM PortalProductGrouping__c];
				delete [SELECT Id FROM WS_Log__c];
				//delete [SELECT Id FROM WS_ScheduledCallout__c];
				delete [SELECT Id FROM CustomAttribute__c];
				delete [SELECT Id FROM AccountMemberUnitAssociation__c];
				delete [SELECT Id FROM Lead];
				try {
					delete [SELECT Id FROM Metric__c];
				} catch (Exception e ) {}
				delete [SELECT Id FROM InvoiceLine__c];
				delete [SELECT Id FROM Invoice__c];
				delete [SELECT Id FROM RS__c];
				delete [SELECT Id FROM Rev__c];
				delete [SELECT Id FROM echosign_dev1__SIGN_Agreement__c];
				delete [SELECT Id FROM OpportunityLineItem];
				delete [SELECT Id FROM Opportunity];
				delete [SELECT Id FROM CustomAttributeDefinition__c];
				delete [SELECT Id FROM MemberUnit__c];
				delete [SELECT Id FROM Contact];
				delete [SELECT Id FROM Member__c];
				delete [SELECT Id FROM Account];

				delete [SELECT Id FROM CommunityConfiguration__c];
				delete [SELECT Id FROM Configuration__c];
				//delete [SELECT Id FROM Content__c];
				delete [SELECT Id FROM CustomJob__c];
				delete [SELECT Id FROM Custom_ECG_Labels__c];
				delete [SELECT Id FROM DART_Advertiser_Type_Mapper__c];
				delete [SELECT Id FROM DART_Browser_Mapper__c];
				delete [SELECT Id FROM DART_OS_Mapper__c];
				delete [SELECT Id FROM DevSettings__c];
				delete [SELECT Id FROM DNB_Settings__c];
				delete [SELECT Id FROM FieldValidation__c];
				delete [SELECT Id FROM MailTrigger__c];
				delete [SELECT Id FROM MapInsight_AccountComponentConfiguration__c];
				delete [SELECT Id FROM MapInsight_Configuration__c];
				delete [SELECT Id FROM MapInsight_Metric__c];
				delete [SELECT Id FROM MapInsight_Object__c];
				delete [SELECT Id FROM MapInsight_RecordFilter__c];
				delete [SELECT Id FROM MapInsight_RegionMapping__c];
				//delete [SELECT Id FROM Placement__c];
				delete [SELECT Id FROM RecordRestrictions__c];
				delete [SELECT Id FROM RuleObjectMap__c];
				delete [SELECT Id FROM Site__c];
				delete [SELECT Id FROM Webservice_Settings__c];
				delete [SELECT Id FROM WSC_Subscription__c];
			}
		}
		return;
	}

	public static void insertData(DataContainer dc) {
		// Upsert in a certain order
		TriggerManager.isSuspended = true;
		doInsert(fixLookups(dc.memberAccounts, dc));
		Map<Id, Member__c> members = new Map<Id, Member__c>((List<Member__c>) doInsert(fixLookups(dc.members, dc)));
		doInsert(fixLookups(dc.memberUnits, dc)); dc.memberUnits = null;
		doUpsertOnId(fixLookups(members, dc)); members = null;
		doInsert(fixLookups(dc.customAttributeDefinitions, dc)); dc.customAttributeDefinitions = null;
		doInsert(fixLookups(dc.accounts, dc)); dc.accounts = null;
		doInsert(fixLookups(dc.contacts, dc)); dc.contacts = null;
		//doInsert(fixLookups(dc.contents, dc)); dc.contents = null;
		doInsert(fixLookups(dc.opportunities, dc)); dc.opportunities = null;
		doInsert(fixLookups(dc.opportunityLineItems, dc)); dc.opportunityLineItems = null;
		doInsert(fixLookups(dc.agreements, dc)); dc.agreements = null;
		doInsert(fixLookups(dc.revs, dc)); dc.revs = null;
		doInsert(fixLookups(dc.rss, dc)); dc.rss = null;
		doInsert(fixLookups(dc.metrics, dc)); dc.metrics = null;
		doInsert(fixLookups(dc.invoices, dc)); dc.invoices = null;
		doInsert(fixLookups(dc.invoiceLines, dc)); dc.invoiceLines = null;
		doInsert(fixLookups(dc.leads, dc)); dc.leads = null;
		doInsert(fixLookups(dc.customAttributes, dc)); dc.customAttributes = null;
		doInsert(fixLookups(dc.amuas, dc)); dc.amuas = null;
		//doInsert(fixLookups(dc.scheduledCallouts, dc)); dc.scheduledCallouts = null;
		doInsert(fixLookups(dc.wsLogs, dc)); dc.wsLogs = null;
		doInsert(fixLookups(dc.portalProductGroupings, dc)); dc.portalProductGroupings = null;
		doInsert(fixLookups(dc.portalProducts, dc)); dc.portalProducts = null;
		doInsert(fixLookups(dc.rules, dc)); dc.rules = null;
		doInsert(fixLookups(dc.ruleAssociations, dc)); dc.ruleAssociations = null;
		doInsert(fixLookups(dc.ruleToRules, dc)); dc.ruleToRules = null;
		doInsert(fixLookups(dc.permissionGroups, dc)); dc.permissionGroups = null;
		doInsert(fixLookups(dc.permissionGroupAssignments, dc)); dc.permissionGroupAssignments = null;
		doInsert(fixLookups(dc.permissionGroupRelationships, dc)); dc.permissionGroupRelationships = null;
		doInsert(fixLookups(dc.communityConfigurations, dc)); dc.communityConfigurations = null;
		doInsert(fixLookups(dc.configurations, dc)); dc.configurations = null;
		doInsert(fixLookups(dc.customJobs, dc)); dc.customJobs = null;
		doInsert(fixLookups(dc.customEcgLabels, dc)); dc.customEcgLabels = null;
		doInsert(fixLookups(dc.dartAtm, dc)); dc.dartAtm = null;
		doInsert(fixLookups(dc.dartBm, dc)); dc.dartBm = null;
		doInsert(fixLookups(dc.dartOm, dc)); dc.dartOm = null;
		doInsert(fixLookups(dc.devSettings, dc)); dc.devSettings = null;
		doInsert(fixLookups(dc.dnbSettings, dc)); dc.dnbSettings = null;
		doInsert(fixLookups(dc.fieldValidationSettings, dc)); dc.fieldValidationSettings = null;
		doInsert(fixLookups(dc.mailTriggers, dc)); dc.mailTriggers = null;
		doInsert(fixLookups(dc.mapInsightMetrics, dc)); dc.mapInsightMetrics = null;
		doInsert(fixLookups(dc.mapInsightObjects, dc)); dc.mapInsightObjects = null;
		doInsert(fixLookups(dc.mapInsightRecordFilters, dc)); dc.mapInsightRecordFilters = null;
		doInsert(fixLookups(dc.mapInsightRegionMappings, dc)); dc.mapInsightRegionMappings = null;
		doInsert(fixLookups(dc.mapInsightAcc, dc)); dc.mapInsightAcc = null;
		doInsert(fixLookups(dc.mapInsightConfigurations, dc)); dc.mapInsightConfigurations = null;
		//doInsert(fixLookups(dc.placements, dc)); dc.placements = null;
		doInsert(fixLookups(dc.recordRestrictions, dc)); dc.customAttributeDefinitions = null;
		doInsert(fixLookups(dc.ruleObjectMaps, dc)); dc.customAttributeDefinitions = null;
		doInsert(fixLookups(dc.sites, dc)); dc.sites = null;
		doInsert(fixLookups(dc.webServiceSettings, dc)); dc.webServiceSettings = null;
		doInsert(fixLookups(dc.wscSubscriptionSettings, dc)); dc.wscSubscriptionSettings = null;
		return;
	}

	private static List<sObject> fixLookups(Map<Id, sObject> input, DataContainer dc) {
		List<sObject> output = new List<sObject>();
		if (input == null || input.values() == null) {
			return new List<sObject>();
		}
		for (sObject sObj : input.values()) {
			// we loop through all fields
			try {
				Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(sObj));
				for (String s : jsonMap.keySet()) {
					// Identify whether this field is an Id field
					try {
						Id idField = Id.valueOf((String) jsonMap.get(s));
						// If we get here this is an Id
						if (idMap.get(idField) == null) {
							// If this is not yet in our map then we put it to null
							if (String.valueOf(idField).left(3) != '005' && s != 'RecordTypeId' && s != 'Id' && s != 'PricebookEntryId') {
								jsonMap.put(s, null);
							}
						} else {
							jsonMap.put(s, idMap.get(idField));
						}
					} catch (Exception e) {
					}
				}
				jsonMap.putAll(fixSObject(sObj));
				output.add((sObject) JSON.deserialize(JSON.serialize(jsonMap), sObject.class));
			} catch (System.TypeException e) {
				// do nothing
			}
		}
		return output;
	}

	private static Map<String, Object> fixSObject(sObject sObj) {
		Map<String, Object> jsonMap = new Map<String, Object>();
		// #1: if this is an OLI we cnanot set both UP and TP
		try {
			if (sObj.get('UnitPrice') != null && sObj.get('TotalPrice') != null) {
				jsonMap.put('TotalPrice', null);
			}
		} catch (Exception e) {}
		return jsonMap;
	}

	private static List<sObject> doInsert(List<sObject> sObjects) {
		List<sObject> clonedSObjects = new List<sObject>();
		List<Id> beforeIdSet = new List<Id>();
		List<Id> afterIdSet = new List<Id>();
		for (sObject sObj : sObjects) {
			beforeIdSet.add(sObj.Id);
			clonedSObjects.add(sObj.clone(false, true, true));
		}
		try {
			insert clonedSObjects;
		} catch (Exception e) {
			if (e.getMessage().contains('INACTIVE_OWNER_OR_USER') || e.getMessage().contains('owner cannot be blank')) {
				for (sObject sObj : clonedSObjects) {
					sObj.put('OwnerId', UserInfo.getUserId());
				}
			}
			if (e.getMessage().contains('pricebook entry is inactive')) {
				if (Test.isRunningTest()) {
					return sObjects;
				}
				Set<Id> pbeIds = new Set<Id>();
				for (sObject sObj : clonedSObjects) {
					pbeIds.add((Id) sObj.get('PricebookEntryId'));
				}
				try {
					activateInactivePricebookEntries(pbeIds);
				} catch (Exception ex) {
					UTIL.Log('Failed to activate PBEs: ' + ex.getStackTraceString());
				}
			}
			try {
				insert clonedSObjects;
			} catch (Exception e2) {
				UTIL.throwError('Failed to fix data which is not inserting correctly. Error after attempted fix: ' + e2.getMessage() + ' Original error: ' + e.getMessage());
			}
		}
		for (sObject sObj : clonedSObjects) {
			afterIdSet.add(sObj.Id);
		}
		Integer i = 0;
		for (Id beforeId : beforeIdSet) {
			idMap.put(beforeId, afterIdSet.get(i));
			idMap.put(afterIdSet.get(i), afterIdSet.get(i));
			i++;
		}
		return clonedSObjects;
	}

	private static void activateInactivePricebookEntries(Set<Id> pbeIds) {
		List<PricebookEntry> pricebookEntries = (List<PricebookEntry>) GW_sObject.queryRecords('PricebookEntry', pbeIds);
		for (PricebookEntry pbe : pricebookEntries) {
			pbe.IsActive = true;
		}

		update pricebookEntries;
	}

	private static void setDefaultMemberUnitOnMembers() {
		Map<Id, Member__c> memberMap = new Map<Id, Member__c>((List<Member__c>) GW_sObject.queryRecords('Member__c', ''));
		Map<Id, MemberUnit__c> memberUnitMap = new Map<Id, MemberUnit__c>((List<MemberUnit__c>) GW_sObject.queryRecords('MemberUnit__c', ''));
		for (Id memId : memberMap.keySet()) {
			Member__c memb = memberMap.get(memId);
			for (MemberUnit__c memUnit : memberUnitMap.values()) {
				if (memUnit.MemberUnitId__c != NULL && memb.MemberId__c != NULL && memUnit.MemberUnitId__c.contains(memb.MemberId__c)) {
					memb.DefaultMemberUnit__c = memUnit.Id;
				}
			}
		}
		update memberMap.values();
	}

	private static void setDefaultPriceBookForMembers() {
		Map<Id, Pricebook2> pbMap = new Map<Id, Pricebook2> ((List<Pricebook2>) GW_sObject.queryRecords('Pricebook2', ''));
		Map<Id, MemberUnit__c> memberUnitMap = new Map<Id, MemberUnit__c> ((List<MemberUnit__c>) GW_sObject.queryRecords('MemberUnit__c', ''));
		for (Pricebook2 pb : pbMap.values()) {
			for (MemberUnit__c memb : memberUnitMap.values()) {
				if ((pb.Description != null && pb.Description.contains(memb.MemberUnitId__c)) || pb.Name.contains(memb.MemberUnitId__c)) {
					pb.MemberUnit__c = memb.Id;
				}
			}
		}
		update pbMap.values();
	}

	private static List<sObject> doUpsertOnId(List<sObject> sObjects) {
		GW_sObject.upsertSeparately(sObjects);
		return sObjects;
	}

	public static void applyPostInsertActions() {
		try {
			setDefaultMemberUnitOnMembers();
			setDefaultPriceBookForMembers();

		} catch (Exception e) {
			UTIL.Log('Exception during postInsertActions()' + e.getStackTraceString());
		}
	}

	public static void applyDataContainer(String s) {
		StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = :s];
		if (sr == null) {
			return;
		} else {
			DataContainer dc = parseDataFromStaticResource(sr.Body.toString());
			sr = null;
			insertData(dc);
			dc = null;
			applyPostInsertActions();
		}
	}
	public static void initDataAndRunJob(String s) {
		applyDataContainer(s);
		try {
			for (CronTrigger ct : [SELECT Id, CronExpression, EndTime, NextFireTime, OwnerId FROM CronTrigger]) {
				try {
					System.abortJob(ct.Id);
				} catch (Exception e) {}
			}
		} catch (Exception e) {

		}

		SCH_CustomJobDispatcher.start();
		//SCH_CustomJobDispatcher.schedule();
	}

    @future
	public static void prepareProducts() {
		List<Product2> prods = [ SELECT Id FROM Product2 WHERE PredifinedAdunit__c != null OR Placement__c != null ];

		for (Product2 prod : prods) {
			prod.PredifinedAdunit__c = null;
			prod.Placement__c = null;
		}
		update prods;
	}

	@future
	public static void activateJenkinsUATUser() {
		List<User> users = [ SELECT Id FROM User WHERE Alias = 'T-CIJUAT' ];
		if (users.size() == 1) {
			users.get(0).isActive = true;
			update users;
		}
	}

	// Helpers
	public static List<StaticResource> getAvailableStaticResources() {
		return [SELECT Id, Name, CreatedDate, LastModifiedDate, CreatedById, LastModifiedById FROM StaticResource WHERE Name LIKE 'SBDC_%'];
	}

	@future
	public static void doRunApexClass() {
		initDataAndRunJob(DefaultDataContainer);
	}
	
	// Running
	global void runApexClass(SandboxContext context) {
		doRunApexClass();
		activateJenkinsUATUser();
        prepareProducts();
        //call batch to update contact's email
        BAT_UpdateContactEmail batUpdateCont = new BAT_UpdateContactEmail();
        ID batchprocessid = Database.executeBatch(batUpdateCont);
    }
}