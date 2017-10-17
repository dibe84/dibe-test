@isTest
private class TST_GW_User {
	@isTest static void TestMethods() {
		Profile testProfile = GW_User.getProfileByName('System Administrator'); 
		User testUser = GW_User.createTestUser(testProfile);
		system.assertEquals(testuser.ProfileId, testProfile.Id);		

    	//@Vitou 08-04-2015
        GW_User.insertTestUser();
            
    }
    
    //@vitou 08-04-2015
    @isTest static void TestMethod2() {
        Profile testProfile = GW_User.getProfileByName('System Administrator'); 
        User testUser = GW_User.createTestUser(testProfile);

        UserRole role = GW_User.getUserRole(testUser.id);
        map<Id, Profile> mapProfile =  GW_User.userProfileMap;
        map<Id, UserRole> mapRole = GW_User.getRolesMap();
        Id idRole = GW_User.getRoleId('test');
        GW_User.insertTestUser( UserInfo.getOrganizationId() + 'test@test.testcom');
        GW_User.setInactive(testUser);
    }
}