@isTest
private class TST_c_JIT {

	@testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
	
	@isTest static void test_method_one() {
		
		TST_DataFactory fac = TST_DataFactory.getInstance();
        Test.startTest();
        // Need to insert a community user
        List<Profile> allProfiles = GW_User.userProfileMap.values();
        Profile communityProfile = null;
        for (Profile p : allProfiles) {
            if (p.Name == 'Customer Community User') {
                communityProfile = p;
                break;
            }
        }
        
        fac.acc.Portal_User__c = fac.con.Id;
        fac.acc.Finance_Contact__c = fac.con.Id;
        fac.acc.UniquePlatformId__c = 'EBAYKRE';
        update fac.acc;
        
        System.debug('### fac :: ' + fac);

        System.runAs(new User(Id=UserInfo.getUserId())) {

        	c_JIT jit = new c_JIT();

        	//Create Jit User
	        User cu = jit.createUser(null, null, null, 'EBAYKRE', new Map<String,String>(), null);
	        
	        //Update Jit  User
	        jit.updateUser(cu.Id, null, null, null, 'EBAYKRE', null, null);
			System.debug('### cu :: ' + cu);

			List<PermissionSetAssignment> existingAssignments = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :cu.Id];

			System.assert( cu != null && cu.Id <> null, 'There should be a user created from JIT');

			System.debug('### existingAssignments :: ' + existingAssignments);

			System.assert( !existingAssignments.isEmpty() && existingAssignments.size() == 2, 'There should be 2 permissionset create for new user from JIT');


        }

        

        Test.stopTest();

	}
	
	
	
}