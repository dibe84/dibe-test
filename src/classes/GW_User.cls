public with sharing class GW_User {

    public static final Id ADMINPROFILEID = '00e90000001p3zc';

    public static Boolean userMapRequery = false;

	public static Map<Id, User> userMap {
		get {
        	if (userMap == null || userMapRequery) {
        		userMap = new Map<Id, User>(); 
        		List<User> users = [SELECT  Id,  Username,  LastName,  FirstName,  Name,  Email,  Phone,  Alias,
        							TimeZoneSidKey,  UserRoleId,  LocaleSidKey,  CurrencyIsoCode,  ProfileId,
        							UserType,  LanguageLocaleKey
        							FROM User LIMIT 1000];
        		for (User u : users) userMap.put(u.Id, u);
        	}
            return userMap;
        }
        private set;
	}

    public static Map<Id, Profile> userProfileMap {
		get {
        	if (userProfileMap == null) {
        		userProfileMap = new Map<Id, Profile>();
        		List<Profile> profiles = [ SELECT  Id,  Name FROM Profile LIMIT 1000];
        		for (Profile p : profiles) userProfileMap.put(p.Id, p);
        	}
            return userProfileMap;
        }
        private set;
	}

    public static Map<Id, CustomPermission> customPermissions {
        get {
            if (customPermissions == null) {
                customPermissions = new Map<Id,CustomPermission>((List<CustomPermission>) GW_sObject.queryRecords('CustomPermission', ''));
            }
            return customPermissions;
        }
    }

    public static Set<String> userCustomPermissions {
        get {
            if (userCustomPermissions == null) {
                Map<Id, CustomPermission> customPerms = customPermissions;
                Set<id> cPermIds = new Set<id>(customPerms.keySet());
                id userId = UserInfo.getUserId();

                list<PermissionSetAssignment> permAssignments = Database.query('SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId');

                Set<id> permIds  = new Set<id>();
                for(PermissionSetAssignment pa: permAssignments){
                    permIds.add(pa.PermissionSetId);
                }

                List<SetupEntityAccess> results = Database.query('SELECT Id, SetupEntityId, ParentId FROM SetupEntityAccess WHERE SetupEntityId IN :cPermIds AND ParentId IN :permIds');

                Set<String> userCustomPerms = new set<String>();
                for (SetupEntityAccess sea : results) {
                    userCustomPerms.add(customPermissions.get(sea.SetupEntityId).DeveloperName);
                }
             	userCustomPermissions = userCustomPerms;
            }
            return userCustomPermissions;
        }
    }

	private static Map<Id,UserRole> userRoleMap { // Map UserId => UserRole
		get {
        	if (userRoleMap == null || userMapRequery) {
        		userRoleMap = new Map<Id,UserRole>();
        		for (User u : userMap.values() ) {
        			userRoleMap.put(u.id, rolesIdMap.get(u.UserRoleId) );
        		}
        	}
            return userRoleMap;
        }
        private set;
	}
    private static Map<Id, UserRole> rolesIdMap { // Role Id => UserRole
        get {
        	if (rolesIdMap == null) fillRoleMaps();
            return rolesIdMap;
        }
        private set;
    }

    public static Map<Id, UserRole> getRolesMap() {
        return rolesIdMap;
    }
    private static Map<String, UserRole> rolesNameMap { // Role Developer Name => UserRole
        get {
        	if (rolesNameMap == null) fillRoleMaps();
            return rolesNameMap;
        }
        private set;
    }
    private static void fillRoleMaps() {
    	rolesNameMap = new Map<String, UserRole>();
    	rolesIdMap = new Map<Id, UserRole>();

    	List<UserRole> roles = [	SELECT  Id, Name, ParentRoleId, RollupDescription, DeveloperName
    								FROM UserRole
									LIMIT 1000 ];
    	for (UserRole r : roles) {
    		rolesNameMap.put(r.DeveloperName, r);
    		rolesIdMap.put(r.Id,r);
    	}
    }

    public static UserRole getUserRole(Id userId) {
    	return userRoleMap.get(userId);
    }

    public static Id getRoleId(String devName) {
    	if (rolesNameMap.containsKey(devname) )
    		return rolesNameMap.get(devname).Id;
    	else return null;
    }

    public static String getRoleName(Id roleId) {
    	if (roleId != null && rolesIdMap.containsKey(roleId) )
    		return rolesIdMap.get(roleId).DeveloperName;
    	else return 'No role selected';
    }

    public static Id getProfileIdByName(String profileName) {
        for (Profile p : userProfileMap.values()) {
            if (p.Name == profileName) {
                return p.Id;
            }
        }
        return null;
    }

    public static Boolean hasCustomPermission(String developerName) {
        UTIL.log('TESTER5 :' + userCustomPermissions );
        UTIL.log('TESTER5 :' + userCustomPermissions.contains(developerName));

        return userCustomPermissions.contains(developerName);
    }

    // test helper methods
    public static final String DEFAULT_ROLENAME = 'GTAUSAD';
    public static final String DEFAULT_PROFILE = 'Standard User';
    public static final String DEFAULT_USERNAME = 'Testuser@ecgtest.org';
    public static Integer usercounter = 1;

    // base creation from strings
    public static User createTestUser(String userName, String userRoleName, String profileName) {
    	UserRole ur = rolesNameMap.get(userRoleName);
    	createTestUserRole(ur, userRoleName);
        Profile pf = getProfileByName(profileName);
        If (ur == null || pf == null) UTIL.throwError('Cannot request User Creation with UserRoleName \'' + userRoleName + '\' or Profilename \'' + profileName + '\' that dont exist');
        return createTestUser(username,ur,pf);
    }

    public static User createTestUser(String userName, String userRoleName, Profile pf) {
    	UserRole ur = rolesNameMap.get(userRoleName);
    	createTestUserRole(ur, userRoleName);
        If (ur == null || pf == null) UTIL.throwError('Cannot request User Creation with UserRoleName \'' + userRoleName + '\' or Profilename \'' + (null == pf ? '' : pf.Name) + '\' that dont exist');
        return createTestUser(username,ur,pf);
    }
	
	private static void createTestUserRole(UserRole ur, String userRoleName) {
        if (ur == null) {
            UserRole countryLevelRole;
            for(UserRole uu : [SELECT Id, DeveloperName FROM UserRole WHERE DeveloperName = 'THBET' limit 1]){
            	countryLevelRole = uu;
            }
            if(countryLevelRole == null) {
                countryLevelRole = new UserRole(Name='Test Country Level Role', DeveloperName = 'THBET');
                insert countryLevelRole;
            }
            ur = new UserRole(Name='Test Member Unit Level Role (THBET)', ParentRoleId = countryLevelRole.Id, DeveloperName = userRoleName);
            insert ur;
        }
    }
    // base creation
    public static User createTestUser(String userName, UserRole ur, Profile pf) {
        User u = new User();
        u.UserRoleId = ur.Id;
        u.FirstName = 'Test';
        u.LastName = 'User';
        u.Email = 'testuser@ecgtest123456789.com';
        u.CompanyName = 'test.com';
        u.Title = 'Test User';
        u.Username = userName;
        u.Alias = ((String)pf.id).right(3)+username.left(5).deleteWhitespace();
        u.CommunityNickname = u.Alias;
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        u.LocaleSidKey = 'nl_NL';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.ProfileId = pf.Id;
        u.LanguageLocaleKey = 'nl_NL';
        return u;
    }

    public static User createTestUser() 				{ return createTestUser(DEFAULT_USERNAME+(usercounter++).format()); }
    public static User createTestUser(String userName) 	{ return createTestUser(userName, DEFAULT_ROLENAME, DEFAULT_PROFILE); }
    public static User createTestUser(UserRole ur, String profileName){
        return createTestUser(DEFAULT_USERNAME+(usercounter++).format(),ur.DeveloperName,profileName);
    }
    public static User createTestUser(Profile pf, String userName) 	{ return createTestUser(userName, DEFAULT_ROLENAME, pf); }
	public static User createTestUser(Profile pf) 	{ 
		pf = [Select Id, Name From Profile Where id = :pf.id];
		return createTestUser(DEFAULT_USERNAME+(usercounter++).format(), DEFAULT_ROLENAME, pf); 
	}
    public static User insertTestUser() {
        User u = createTestUser(DEFAULT_USERNAME);
        insert u;
        return u;
    }

    public static User insertTestUser(String userName) {
        User u = createTestUser(userName);
        insert u;
        return u;
    }


// Role factory
//
    /*public static UserRole getUserRole(String devName) {

        if (rolesNameMap.containsKey(devName) )
            return rolesNameMap.get(devName);
        else {
            UserRole ur = new UserRole(DeveloperName = devName, Name = devName);
        	insert ur;
        	return ur;
        }
    }*/

  	// user helpers
  	/*public static User getUser(Id uId) {
  		User u = [Select UserType, Id, Email From User Where Id =: uId];
  		return u;
  	}*/
	public static User getUser(Id uId) {
        String userId = String.valueOf(uId);
        userId = userId.length()>15?userId.substring(0, 15):userId;
        User u = [Select UserType, Id, Email From User Where Id =: userId];
        return u;
    }

//profile helpers
	public static Profile getProfileByName(String profileName) {
	  	List<Profile> pfs = [Select Id from Profile where Name = :profileName];
        if (!pfs.isEmpty()) return pfs[0];
	  	return null;
	}

    public static Profile getProfileById(Id profileId){
        List<Profile> pfs = [Select Id, UserLicense.Name from Profile where Id =: profileId];
        if (!pfs.isEmpty()) return pfs[0];
	  	return null;
    }

	public static void setInactive(User user){
		user.IsActive = false;
	}
	
	static Map<Id, Boolean> mapIsGuest = new Map<Id, Boolean>();
	public static Boolean isGuest(Id userId){
		if(!mapIsGuest.containsKey(userId)) {
			for(User u : [select Profile.UserLicense.Name from User where id=:userId]) {
				mapIsGuest.put(u.id, u.Profile.UserLicense.Name.equalsIgnoreCase('Guest User License'));
			}
		}
		return mapIsGuest.get(userId);
	}
}