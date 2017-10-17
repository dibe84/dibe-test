@isTest
public class TST_CustomAttributes {

	@isTest static void testBasicCreationForAccount() {
		Test.startTest();
		TST_DataFactory.createBasicAccount(1);
		List<Account> testAccList = [SELECT Id, Name FROM Account];
		System.assertNotEquals(FALSE,(testAccList.size() > 0));
		TST_DataFactory.createMemberUnit(testAccList.get(0).Id);
		List<MemberUnit__c> testMUList = [SELECT Id, Name FROM MemberUnit__c];
		System.assertNotEquals(FALSE,(testMUList.size() > 0));
		List<Member__c> testMemberList = [SELECT Id, Name FROM Member__c];
		System.assertNotEquals(FALSE,(testMemberList.size() > 0));

		// Create AMUA
		TST_DataFactory.createAccountMemberUnitAssociation(testMUList.get(0).Id,testAccList.get(0).Id);
		List<AccountMemberUnitAssociation__c> amuaList = [SELECT Id, Name FROM AccountMemberUnitAssociation__c];
		System.assertNotEquals(FALSE,(amuaList.size() > 0));

		// Create CAD for Account
		TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Account','String');
		List<CustomAttributeDefinition__c> testCADList = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c];
		System.assertNotEquals(FALSE,(testCADList.size() > 0));

		// Create CA for given Account and CAD
		TST_DataFactory.createCustomAttributeForAccount(testCADList.get(0), 'testKey', testAccList.get(0).Id);
		List<CustomAttribute__c> testCAList = [SELECT Id, Name FROM CustomAttribute__c];
		System.assertNotEquals(FALSE,(testCAList.size() > 0));

		// Modify the account to trigger validations
		Account testAcc = testAccList.get(0);
		testAcc.BillingHouseNumber__c = 1;
		update testAcc;

		Test.stopTest();
	}

	@isTest static void testBasicCreationForLead() {
		Test.startTest();
		// Create accounts
		TST_DataFactory.createBasicAccount(1);
		List<Account> testAccList = [SELECT Id, Name FROM Account];
		System.assertNotEquals(FALSE,(testAccList.size() > 0));
		// Create member unit
		TST_DataFactory.createMemberUnit(testAccList.get(0).Id);
		List<MemberUnit__c> testMUList = [SELECT Id, Name FROM MemberUnit__c];
		System.assertNotEquals(FALSE,(testMUList.size() > 0));
		// Members
		List<Member__c> testMemberList = [SELECT Id, Name FROM Member__c];
		System.assertNotEquals(FALSE,(testMemberList.size() > 0));
		// Create Lead
		TST_DataFactory.createLead('testLead','testCompany',testMemberList.get(0).Id,testMUList.get(0).Id);
		List<Lead> testLeadList = [SELECT Id, Name FROM Lead];
		System.assertNotEquals(FALSE,(testLeadList.size() > 0));
		// Create CAD for Account
		TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Lead','String');
		List<CustomAttributeDefinition__c> testCADList = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c];
		System.assertNotEquals(FALSE,(testCADList.size() > 0));

		// Create CA for given Account and CAD
		TST_DataFactory.createCustomAttributeForLead(testCADList.get(0).Id, 'testKey', testLeadList.get(0).Id);
		List<CustomAttribute__c> testCAList = [SELECT Id, Name FROM CustomAttribute__c];
		System.assertNotEquals(FALSE,(testCAList.size() > 0));

		// Modify the lead to trigger validations
		Lead testLead = testLeadList.get(0);
		testLead.Touch__c = 'testContent';
		update testLead;

		// Ensure that the CA was created automatically
		testCAList = [SELECT Id, Name, Account__c, ParentId__c, Lead__c FROM CustomAttribute__c];
		CustomAttribute__c testCA = testCAList.get(0);
		System.assertEquals(testLead.Id,testCA.Lead__c);
		System.assertEquals(testLead.Id,testCA.ParentId__c);

		Test.stopTest();
	}

	@isTest static void testAutomaticCreationForAccount() {
		Test.startTest();
		TestDataGenerator dataGenerator = new TestDataGenerator();
		TST_DataFactory.createBasicAccount(1);
		List<Account> testAccList = [SELECT Id, Name FROM Account];
		System.assertNotEquals(FALSE,(testAccList.size() > 0));
		TST_DataFactory.createMemberUnit(testAccList.get(0).Id);
		List<MemberUnit__c> testMUList = [SELECT Id, Name FROM MemberUnit__c];
		System.assertNotEquals(FALSE,(testMUList.size() > 0));
		List<Member__c> testMemberList = [SELECT Id, Name FROM Member__c];
		System.assertNotEquals(FALSE,(testMemberList.size() > 0));

		// Create AMUA
		TST_DataFactory.createAccountMemberUnitAssociation(testMUList.get(0).Id,testAccList.get(0).Id);
		List<AccountMemberUnitAssociation__c> amuaList = [SELECT Id, Name FROM AccountMemberUnitAssociation__c];
		System.assertNotEquals(FALSE,(amuaList.size() > 0));

		// Create CAD for Account
		TST_DataFactory.createCustomAttributeDefinition(testMUList.get(0).Id,'Account','String');
		List<CustomAttributeDefinition__c> testCADList = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c];
		System.assertNotEquals(FALSE,(testCADList.size() > 0));

		// Mark the definition as mandatory
		CustomAttributeDefinition__c testCAD = testCADList.get(0);
		testCAD.AutoCreate__c = true;
		testCAD.PrefillConfiguration__c = '15_test';
		testCAD.Object__c = 'Account';
		update testCAD;

		// Modify the account to trigger validations
		Account testAcc = testAccList.get(0);
		testAcc.BillingHouseNumber__c = 1;
		update testAcc;

		// Ensure that the CA was created automatically
		List<CustomAttribute__c> testCAList = [SELECT Id, Name, Account__c, ParentId__c FROM CustomAttribute__c];
		CustomAttribute__c testCA = testCAList.get(0);
		System.assertNotEquals(FALSE,(testCAList.size() > 0));
		System.assertEquals(testAcc.Id,testCA.Account__c);
		System.assertEquals(testAcc.Id,testCA.ParentId__c);

		// Make use of test factory methods
		testCA = GW_CustomAttribute.createSObject('testKey');
		System.assertNotEquals(NULL,testCA);

		testCA = GW_CustomAttribute.createSObject('myKey','myTestString');
		System.assertNotEquals(NULL,testCA);
		System.assertEquals(testCA.StringValue__c,'myTestString');
		System.assertEquals(testCA.ValueType__c,'STRING');
		System.assertEquals(GW_CustomAttribute.setValue(testCA,'anotherString'),TRUE);
		System.assertEquals(GW_CustomAttribute.getValue(testCA),'anotherString');

		String longString = '=================================================================================================';
		longString += '=================================================================================================';
		longString += '=================================================================================================';
		longString += '=================================================================================================';
		longString += '=================================================================================================';
		testCA = GW_CustomAttribute.createSObject('myKey',longString);
		System.assertNotEquals(NULL,testCA);
		System.assertEquals(testCA.LongTextValue__c,longString);
		System.assertEquals(testCA.ValueType__c,'LONGTEXT');
		System.assertEquals(GW_CustomAttribute.setValue(testCA,longString),TRUE);
		System.assertEquals(GW_CustomAttribute.getValue(testCA),longString);

		testCA = GW_CustomAttribute.createSObject('myKey',150.0);
		System.assertNotEquals(NULL,testCA);
		System.assertEquals(testCA.NumberValue__c,150.0);
		System.assertEquals(testCA.ValueType__c,'NUMBER');
		System.assertEquals(GW_CustomAttribute.setValue(testCA,200.0),TRUE);
		System.assertEquals(GW_CustomAttribute.getValue(testCA),200.0);

		DateTime testTime = DateTime.now();
		testCA = GW_CustomAttribute.createSObject('myKey',testTime);
		System.assertNotEquals(NULL,testCA);
		System.assertEquals(testCA.DatetimeValue__c,testTime);
		System.assertEquals(testCA.ValueType__c,'DATETIME');
		testTime = DateTime.now();
		System.assertEquals(GW_CustomAttribute.setValue(testCA,testTime),TRUE);
		System.assertEquals(GW_CustomAttribute.getValue(testCA),testTime);

		Date testDate = Date.today();
		testCA = GW_CustomAttribute.createSObject('myKey',testDate);
		System.assertNotEquals(NULL,testCA);
		System.assertEquals(testCA.DateValue__c,testDate);
		System.assertEquals(testCA.ValueType__c,'DATE');
		System.assertEquals(GW_CustomAttribute.setValue(testCA,testDate),TRUE);
		System.assertEquals(GW_CustomAttribute.getValue(testCA),testDate);

		testCA = GW_CustomAttribute.createSObject('myKey',TRUE);
		System.assertNotEquals(NULL,testCA);
		System.assertEquals(testCA.BooleanValue__c ,TRUE);
		System.assertEquals(testCA.ValueType__c,'BOOLEAN');
		System.assertEquals(GW_CustomAttribute.setValue(testCA,TRUE),TRUE);
		System.assertEquals(GW_CustomAttribute.getValue(testCA),TRUE);

		testCA.Account__c = testAccList.get(0).Id;
		testCA.ParentId__c = testAccList.get(0).Id;
		testCA.CustomAttributeDefinition__c = testCAD.Id;
		insert testCA;
		// Test manual update

		testCA.BooleanValue__c = FALSE;
		testCA.ValueType__c = 'STRING';
		testCA.StringValue__c = 'myTestStringContent';

		update testCA;

		testCA = GW_CustomAttribute.getRecord(testCA.Id);
		System.assertEquals(testCA.BooleanValue__c,FALSE);
		System.assertEquals(testCA.ValueType__c,'String');
		System.assertEquals(testCA.StringValue__c,'myTestStringContent');

		Test.stopTest();
	}

	@isTest static void testRelationshipCreation() {
		Test.startTest();
		// Create accounts
		TST_DataFactory.createBasicAccount(2);
		List<Account> testAccList = [SELECT Id, Name FROM Account];
		System.assertNotEquals(FALSE,(testAccList.size() == 2));
		// Create member unit
		TST_DataFactory.createMemberUnit(testAccList.get(0).Id);
		List<MemberUnit__c> testMUList = [SELECT Id, Name FROM MemberUnit__c];
		System.assertNotEquals(FALSE,(testMUList.size() > 0));
		// Members
		List<Member__c> testMemberList = [SELECT Id, Name FROM Member__c];
		System.assertNotEquals(FALSE,(testMemberList.size() > 0));
		// Create Lead
		TST_DataFactory.createLead('testLead','testCompany',testMemberList.get(0).Id,testMUList.get(0).Id);
		List<Lead> testLeadList = [SELECT Id, Name FROM Lead];
		System.assertNotEquals(FALSE,(testLeadList.size() > 0));
		// Create CAD for Account (relationship to lead)
		TST_DataFactory.createCustomAttributeDefinitionRelation(testMUList.get(0).Id,'Account','Lead');
		List<CustomAttributeDefinition__c> testCADList = [SELECT Id, Name, AttributeType__c FROM CustomAttributeDefinition__c];
		System.assertNotEquals(FALSE,(testCADList.size() > 0));
		// Create custom attribute for account using provided definition
		TST_DataFactory.createCustomAttributeForAccount(testCADList.get(0),'myTestAttrKey',testAccList.get(0).Id);
		// Ensure that the CA was created
		List<CustomAttribute__c> testCAList = [SELECT Id, Name, Account__c, ParentId__c, Lead__c, ValueType__c FROM CustomAttribute__c];
		System.assertNotEquals(FALSE,(testCAList.size() > 0));
		// Check if CA was created with proper settings
		CustomAttribute__c testCA = testCAList.get(0);
		System.assertEquals(testAccList.get(0).Id,testCA.Account__c);
		System.assertEquals(testAccList.get(0).Id,testCA.ParentId__c);
		System.assertEquals('Relationship',testCA.ValueType__c);

		// Set up VF page
		PageReference accCustomAttrPageRef = Page.AccountCustomAttributes;
		Test.setCurrentPage(accCustomAttrPageRef);
		// Add ID to page parameters
		ApexPages.currentPage().getParameters().put('id', testAccList.get(0).Id);
		// Set up controller
		PGC_CustomAttributes pgcCA = new PGC_CustomAttributes();
		// Assert correct number of CA's is presented on page
		System.assertNotEquals(FALSE,(pgcCA.customAttributes.size() == 1));
		System.assertNotEquals(FALSE,(pgcCA.groupNameToCustomAttributeList.keySet().size() == 1));
		// Simulate update for custom attributes using actual search class
		PGC_CustomAttributeObjectSearch pgcCASearch = new PGC_CustomAttributeObjectSearch();
		pgcCASearch.searchString = 'testLead';
		pgcCASearch.objectType = 'Lead';
		pgcCASearch.search();
		// Determine whether the object was successfully found
		System.assertNotEquals(FALSE,(pgcCASearch.results.size() != 0));
		// Update the custom attribute using search results
		List<CustomAttribute__c> caOnPage = pgcCA.groupNameToCustomAttributeList.get(PGC_CustomAttributes.DEFAULTGROUPNAME);
		System.assertEquals(1,caOnPage.size());
		// Update object values
		CustomAttribute__c caToUpdate = caOnPage.get(0);
		caToUpdate.RelationshipId__c = pgcCASearch.results.get(0).objId;
		caToUpdate.RelationshipName__c = pgcCASearch.results.get(0).Name;
		List<CustomAttribute__c> updatedCAList = new List<CustomAttribute__c>();
		updatedCAList.add(caToUpdate);
		pgcCA.groupNameToCustomAttributeList.put(PGC_CustomAttributes.DEFAULTGROUPNAME, updatedCAList);
		pgcCA.valueMap.put(caToUpdate.Id,pgcCASearch.results.get(0).objId);
		UTIL.Log('Content of groupNameToCustomAttributeList:' + pgcCA.groupNameToCustomAttributeList);
		// Save the updated attributes
		pgcCA.save();
		// Ensure that process completed successfully
		testCAList = [SELECT Id, Name, Account__c, ParentId__c, ValueType__c, RelationshipName__c, RelationshipId__c FROM CustomAttribute__c];
		System.assertNotEquals(FALSE,(testCAList.size() > 0));
		System.assertEquals(testCAList.get(0).RelationshipId__c,testLeadList.get(0).Id);
		System.assertEquals(testCAList.get(0).RelationshipName__c,testLeadList.get(0).Name);

		Test.stopTest();
	}


	@isTest static void testAutomaticCreationForMultipleMUnits() {
		UTIL_Log.start();
		Test.startTest();
		TestDataGenerator dataGenerator = new TestDataGenerator();
		TST_DataFactory.createBasicAccount(30);
		List<Account> testAccList = (List<Account>)(GW_sObject.queryRecords('Account',''));
		testAccList.get(0).RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
		testAccList.get(1).RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
		testAccList.get(2).RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
		// Create members & member units
		List<Member__c> memberList = new List<Member__c>();
		memberList.add(new Member__c(Name='EBAYK', Account__c = testAccList.get(0).Id));
		memberList.add(new Member__c(Name='BEL', Account__c = testAccList.get(1).Id));
		memberList.add(new Member__c(Name='ECITA', Account__c = testAccList.get(2).Id));
		insert memberList;
		List<MemberUnit__c> memberUnitList = new List<MemberUnit__c>();
		memberUnitList.add(new MemberUnit__c(Name = 'EBAYK member unit', Member__c=memberList.get(0).Id, LineOfBusiness__c='AD'));
		memberUnitList.add(new MemberUnit__c(Name = 'BEL member unit', Member__c=memberList.get(1).Id, LineOfBusiness__c='AD'));
		memberUnitList.add(new MemberUnit__c(Name = 'ECITA member unit', Member__c=memberList.get(2).Id, LineOfBusiness__c='AD'));
		insert memberUnitList;
		Map<Id,MemberUnit__c> memberToMUMap = new Map<Id,MemberUnit__c>();
		for(MemberUnit__c mu : memberUnitList) {
			memberToMUMap.put(mu.Member__c,mu);
		}
		List<AccountMemberUnitAssociation__c> amuaList = new List<AccountMemberUnitAssociation__c>();
		for(Integer i = 3; i < 30; i++) {
			AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c();
			if(i < 11) {
				testAccList.get(i).Member__c = memberList.get(0).Id;
				amua.MemberUnit__c = memberToMUMap.get(memberList.get(0).Id).Id;
				amua.Account__c = testAccList.get(i).Id;
			}
			if( i >= 11 && i < 20) {
				testAccList.get(i).Member__c = memberList.get(1).Id;
				amua.MemberUnit__c = memberToMUMap.get(memberList.get(1).Id).Id;
				amua.Account__c = testAccList.get(i).Id;
			}
			if (i >= 20 ){
				amua.MemberUnit__c = memberToMUMap.get(memberList.get(2).Id).Id;
				amua.Account__c = testAccList.get(i).Id;
				testAccList.get(i).Member__c = memberList.get(2).Id;
			}
			testAccList.get(i).RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Advertiser').getRecordTypeId();
			amuaList.add(amua);
		}

		insert amuaList;
		update testAccList;
		amuaList = (List<AccountMemberUnitAssociation__c>) GW_sObject.queryRecords('AccountMemberUnitAssociation__c','');
		System.assertEquals(27,amuaList.size());
		// Create CAD for Account
		TST_DataFactory.createCustomAttributeDefinition(memberUnitList.get(0).Id,'Account','String');
		TST_DataFactory.createCustomAttributeDefinition(memberUnitList.get(1).Id,'Account','String');
		List<CustomAttributeDefinition__c> cadList = (List<CustomAttributeDefinition__c>) GW_sObject.queryRecords('CustomAttributeDefinition__c','');
		System.assertEquals(2,cadList.size());
		for(CustomAttributeDefinition__c cad : cadList) {
			cad.AutoCreate__c = true;
			cad.PrefillConfiguration__c = '15_test';
			cad.Object__c = 'Account';
			cad.AttributeKey__c = 'attrKey';
		}

		update cadList;
		update testAccList;

		List<CustomAttribute__c> caList = (List<CustomAttribute__c>) GW_sObject.queryRecords('CustomAttribute__c','');
		System.assertEquals(17,caList.size());
		testAccList = (List<Account>)(GW_sObject.queryRecords('Account',''));
		TST_DataFactory.createCustomAttributeDefinition(memberUnitList.get(2).Id,'Account','String');
		cadList = (List<CustomAttributeDefinition__c>) GW_sObject.queryRecords('CustomAttributeDefinition__c','');
		for(CustomAttributeDefinition__c cad : cadList) {
			cad.AutoCreate__c = true;
			cad.PrefillConfiguration__c = '15_test';
			cad.Object__c = 'Account';
			cad.AttributeKey__c = 'attrKey';
		}
		update cadList;
		update testAccList;

		caList = (List<CustomAttribute__c>) GW_sObject.queryRecords('CustomAttribute__c','');
		System.assertEquals(27,caList.size());

		Test.stopTest();
	}
}