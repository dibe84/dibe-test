@isTest
private class TST_PermissionGroups extends TSTDF_Base {
    
    public TST_PermissionGroups(TSTDF_Dataset dataset) {
		super(dataset);
    }
	
    public static TST_PermissionGroups factory = new TST_PermissionGroups(new TSTDF_Dataset());
    
    public class TSTDF_Dataset extends TSTDF_BaseDataSet {}
    
    public override void queryAdditionalResults() {}
    
	@testSetup static void setup() {
		UTIL.isRunningTestSetup = true;
		factory.createTestSet();
        factory.queryResults();
		System.runAs (factory.data.testUsers.get( 'adminUser') ) {
			insert new List<PermissionSet>{
				new PermissionSet(Label='PS1', Name='PS1', PermissionsAssignTopics = true),
				new PermissionSet(Label='PS2', Name='PS2'),
				new PermissionSet(Label='PS3', Name='PS3'),
				new PermissionSet(Label='PS4', Name='PS4'),
				new PermissionSet(Label='PS5', Name='PS5')
			};
			PermissionSet ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'PS1'];
			insert new ObjectPermissions(ParentId = ps1.Id, PermissionsCreate = true, PermissionsDelete = true, PermissionsRead = true, PermissionsEdit = true, PermissionsModifyAllRecords = true, PermissionsViewAllRecords = true, SobjectType = 'Account');
			insert new FieldPermissions(ParentId = ps1.Id, PermissionsRead = true, PermissionsEdit = true, Field = 'Account.Finance_Contact__c', SobjectType = 'Account');
		}
        
        insert new Configuration__c(Name='EnablePermissionGroups', Value__c='1');

		createPermissionGroupStructure();

		UTIL.isRunningTestSetup = false;
	}

	@isTest static void checkTestDataSet() {
		factory.queryResults();

		List<PermissionSet> permissionSets = [SELECT Id, Name FROM PermissionSet WHERE Name IN ('PS1', 'PS2', 'PS3', 'PS4', 'PS5')];
		System.assertEquals(permissionSets.size(), 5);

		List<PermissionGroup__c> permissionGroups = [SELECT Id, Name FROM PermissionGroup__c WHERE Name IN ('PG1', 'PG2', 'PG3', 'PG4', 'PG5', 'PG6')];
		System.assertEquals(permissionGroups.size(), 6);

		List<PermissionGroupRelationship__c> permissionGroupRelationships = [SELECT Id, Name FROM PermissionGroupRelationship__c];
		System.assertEquals(permissionGroupRelationships.size(), 4);
	}

	@isTest static void testUserAssignment() {
		factory.queryResults();

		Map<String, PermissionGroup__c> pgMap = getPermissionGroups();

		System.debug(LoggingLevel.ERROR, [SELECT Id, Username, IsActive FROM User]);

		// Add an assignment for a user to PG1 and PG4 -> expect processing to render us a user with only PS1
		Test.startTest();
			List<PermissionGroupAssignment__c> assignmentsToInsert = new List<PermissionGroupAssignment__c>{
				new PermissionGroupAssignment__c(User__c=factory.data.testUsers.get('testUser').Id, PermissionGroup__c=pgMap.get('PG1').Id),
				new PermissionGroupAssignment__c(User__c=factory.data.testUsers.get('testUser').Id, PermissionGroup__c=pgMap.get('PG4').Id)
			};

			insert assignmentsToInsert;

			System.runAs ( factory.data.testUsers.get( 'adminUser') ) {
				F_PermissionGroup.process(new Set<Id>{factory.data.testUsers.get('testUser').Id}, null);
			}

		Test.stopTest();
		System.assert(checkPermissionSetAssignment(factory.data.testUsers.get('testUser').Id, new Set<String>{'PS1', 'PS2', 'PS3', 'PS4', 'PS5'}));
	}

	@isTest static void testProfileAssignment() {
		factory.queryResults();

		Map<String, PermissionGroup__c> pgMap = getPermissionGroups();
		Profile profile = [SELECT Id, Name FROM Profile WHERE Name = :factory.dataSet.ADSALESPROFILENAME];

		// Add an assignment for a user to PG1 and PG4 -> expect processing to render us a user with only PS1
		Test.startTest();
			List<PermissionGroupAssignment__c> assignmentsToInsert = new List<PermissionGroupAssignment__c>{
				new PermissionGroupAssignment__c(Profile__c = profile.Name, PermissionGroup__c=pgMap.get('PG1').Id),
				new PermissionGroupAssignment__c(Profile__c = profile.Name, PermissionGroup__c=pgMap.get('PG4').Id)
			};

			insert assignmentsToInsert;

			System.runAs ( factory.data.testUsers.get( 'adminUser') ) {
				F_PermissionGroup.process(null, new Set<String>{profile.Name});
			}

		Test.stopTest();
		System.assert(checkPermissionSetAssignment(factory.data.testUsers.get('testUser').Id, new Set<String>{'PS1', 'PS2', 'PS3', 'PS4', 'PS5'}));
	}

	@isTest static void testUnavailableFailure() {
		factory.queryResults();

		Map<String, PermissionGroup__c> pgMap = getPermissionGroups();
		Profile profile = [SELECT Id, Name FROM Profile WHERE Name = :factory.dataSet.ADSALESPROFILENAME];

		pgMap.get('PG1').Available__c = false;
		update pgMap.get('PG1');

		// Add an assignment for a user to PG1 and PG4 -> expect processing to render us a user with only PS1
		Test.startTest();
			List<PermissionGroupAssignment__c> assignmentsToInsert = new List<PermissionGroupAssignment__c>{
				new PermissionGroupAssignment__c(Profile__c = profile.Name, PermissionGroup__c=pgMap.get('PG1').Id),
				new PermissionGroupAssignment__c(Profile__c = profile.Name, PermissionGroup__c=pgMap.get('PG4').Id)
			};

			try {
				insert assignmentsToInsert;
				System.assert(false); // this should happen
			} catch (Exception e) {
				System.assertEquals(true, e.getMessage().contains('Permission Group: PG1 is not set to available.'));
			}

		Test.stopTest();
	}

	@isTest static void testCircularReferenceFailure() {
		factory.queryResults();

		Map<String, PermissionGroup__c> pgMap = getPermissionGroups();

		// Add an assignment for a user to PG1 and PG4 -> expect processing to render us a user with only PS1
		Test.startTest();
			List<PermissionGroupRelationship__c> permissionGroupsToInsert = new List<PermissionGroupRelationship__c>{
				new PermissionGroupRelationship__c(Parent__c = pgMap.get('PG6').Id, Child__c = pgMap.get('PG5').Id),
				new PermissionGroupRelationship__c(Parent__c = pgMap.get('PG5').Id, Child__c = pgMap.get('PG6').Id)
			};

			try {
				insert permissionGroupsToInsert;
				System.assert(false); // this should happen
			} catch (Exception e) {
				System.assertEquals(true, e.getMessage().contains('Recursion detected!'));
			}
		Test.stopTest();
	}

	@isTest static void testDeleteInUsePG() {
		factory.queryResults();

		Map<String, PermissionGroup__c> pgMap = getPermissionGroups();

		// Add an assignment for a user to PG1 and PG4 -> expect processing to render us a user with only PS1
		Test.startTest();
			List<PermissionGroupAssignment__c> assignmentsToInsert = new List<PermissionGroupAssignment__c>{
				new PermissionGroupAssignment__c(User__c=factory.data.testUsers.get('testUser').Id, PermissionGroup__c=pgMap.get('PG1').Id)
			};

			insert assignmentsToInsert;

			System.runAs(factory.data.testUsers.get('adminUser')) {
				F_PermissionGroup.process(new Set<Id>{factory.data.testUsers.get('testUser').Id}, null);
			}

			try {
				F_PermissionGroup.clearCache();
				delete pgMap.get('PG2');
				System.assert(false); // this should happen
			} catch (Exception e) {
				System.assertEquals(true, e.getMessage().contains(' has assignments, thus you cannot delete'));
			}
		Test.stopTest();
	}

/* Disabled test due to Apex CPU time limit

	@isTest static void testPGCPermissionGroups() {
		factory.queryResults();

		Map<String, PermissionGroup__c> pgMap = getPermissionGroups();

		System.debug(LoggingLevel.ERROR, [SELECT Id, Username, IsActive FROM User]);

		// Add an assignment for a user to PG1 and PG4 -> expect processing to render us a user with only PS1
		Test.startTest();
			List<PermissionGroupAssignment__c> assignmentsToInsert = new List<PermissionGroupAssignment__c>{
				new PermissionGroupAssignment__c(User__c=factory.data.testUsers.get('testUser').Id, PermissionGroup__c=pgMap.get('PG1').Id),
				new PermissionGroupAssignment__c(User__c=factory.data.testUsers.get('testUser').Id, PermissionGroup__c=pgMap.get('PG4').Id)
			};

			insert assignmentsToInsert;

			PGC_PermissionGroups pgc = new PGC_PermissionGroups();
        	for (PGC_PermissionGroups.Action act : pgc.actionList) {
                String addString = act.addItemsString;
                String removeString = act.removeItemsString;
            }
			System.runAs ( factory.data.testUsers.get( 'adminUser') ) {
				pgc.applyChanges();
				pgc.applyUserChanges();
			}
        
        	List<F_PermissionGroup.PermissionGroup> apgList = pgc.apexPermissionGroupList;
        	for (F_PermissionGroup.PermissionGroup pg : apgList) {
                String assignmentString = pg.getAssignmentString();
                String childHTMLString = pg.getChildrenHTML();
                String parentHTMLString = pg.getParentHTML();
            }
        	pgc.filterMode = 'member';
        	apgList = pgc.apexPermissionGroupList;
        	pgc.filterMode = 'assigned';
        	apgList = pgc.apexPermissionGroupList;
        	pgc.filterMode = 'profileAssigned';
        	apgList = pgc.apexPermissionGroupList;            
        	pgc.filterMode = 'userAssigned';
        	apgList = pgc.apexPermissionGroupList;
        	
        
            

		Test.stopTest();
	}
*/

	@isTest static void testPGCPermissionViewer() {
		factory.queryResults();

		Map<String, PermissionGroup__c> pgMap = getPermissionGroups();

		Test.startTest();


			Test.setCurrentPageReference(new PageReference('Page.PermissionViewer'));
			System.currentPageReference().getParameters().put('id','' + pgMap.get('PG1').Id + ',' + factory.data.testUsers.get('testUser').ProfileId);
			System.currentPageReference().getParameters().put('objectType','all');

			PGC_PermissionViewer pgc = new PGC_PermissionViewer();
	        PGC_PermissionViewer.PVObject pvObj = PGC_PermissionViewer.getObject('Account', new List<Id>{pgMap.get('PG1').Id});
			String selectedIds = pgc.getSelectedIdsAsString();

		Test.stopTest();
	}


	private static Map<String, PermissionGroup__c> getPermissionGroups() {
		Map<String, PermissionGroup__c> result = new Map<String, PermissionGroup__c>();
		List<PermissionGroup__c> permissionGroups = [SELECT Id, Name, PermissionSets__c, Available__c FROM PermissionGroup__c];
		for (PermissionGroup__c pg : permissionGroups) {
			result.put(pg.Name, pg);
		}
		return result;
	}

	private static void createPermissionGroupStructure() {
		Map<String,PermissionGroup__c> permissionGroupMap = new Map<String,PermissionGroup__c>{
			'PG1' => new PermissionGroup__c(Name='PG1', PermissionSets__c='PS1', Available__c=true),
			'PG2' => new PermissionGroup__c(Name='PG2', PermissionSets__c='PS2,PS3', Available__c=true),
			'PG3' => new PermissionGroup__c(Name='PG3', PermissionSets__c='PS4', Available__c=true),
			'PG4' => new PermissionGroup__c(Name='PG4', PermissionSets__c=null, Available__c=true),
			'PG5' => new PermissionGroup__c(Name='PG5', PermissionSets__c='PS5', Available__c=true),
			'PG6' => new PermissionGroup__c(Name='PG6', PermissionSets__c='PS5', Available__c=true)
		};

		insert permissionGroupMap.values();

		List<PermissionGroupRelationship__c> permissionGroupRelationShipMap = new List<PermissionGroupRelationship__c>{
			new PermissionGroupRelationship__c(Parent__c = permissionGroupMap.get('PG1').Id, Child__c = permissionGroupMap.get('PG2').Id),
			new PermissionGroupRelationship__c(Parent__c = permissionGroupMap.get('PG2').Id, Child__c = permissionGroupMap.get('PG3').Id),
			new PermissionGroupRelationship__c(Parent__c = permissionGroupMap.get('PG2').Id, Child__c = permissionGroupMap.get('PG5').Id),
			new PermissionGroupRelationship__c(Parent__c = permissionGroupMap.get('PG4').Id, Child__c = permissionGroupMap.get('PG5').Id)
		};

		insert permissionGroupRelationShipMap;
	}

	private static Boolean checkPermissionSetAssignment(Id userId, Set<String> expectedPermissionSetNames) {
		List<PermissionSetAssignment> assignments = [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.IsOwnedByProfile = false AND AssigneeId = :userId];
		Set<String> foundStrings = new Set<String>();
		for (PermissionSetAssignment psa : assignments) {
			foundStrings.add(psa.PermissionSet.Name);
		}

		System.debug(LoggingLevel.ERROR, 'Expected: ' + expectedPermissionSetNames);
		System.debug(LoggingLevel.ERROR, 'Found: ' + foundStrings);

		for (String s : expectedPermissionSetNames) {
			if (foundStrings.contains(s) == false) {
				return false;
			}
		}

		for (String s : foundStrings) {
			if (expectedPermissionSetNames.contains(s) == false) {
				return false;
			}
		}

		return true;
	}
}