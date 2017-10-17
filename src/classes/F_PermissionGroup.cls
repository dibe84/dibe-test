global class F_PermissionGroup {
	public class CalculationResult {
		public Boolean changesPending { get; set; }
		public Map<Id,Set<PermissionSet>> currentStatusByUser { get; set; }
		public Map<Id,Set<PermissionSet>> desiredStatusByUser { get; set; }
		public Map<Id,Set<PermissionSet>> permissionSetsToAdd { get; set; }
		public Map<Id,Set<PermissionSet>> permissionSetsToRemove { get; set; }
	}

	global class PermissionGroup implements Comparable {
		public PermissionGroup__c obj { get; set; }
		public List<PermissionGroup> children { get; set; }
		public Set<PermissionSet> permissionSets { get; set; }
		public Set<PermissionSet> getEffectivePermissionSets() {
			Set<PermissionSet> result = new Set<PermissionSet>();
			result.addAll(this.permissionSets);
			if (this.children != null) {
				for (PermissionGroup child : this.children) {
					Set<PermissionSet> childResult = child.getEffectivePermissionSets();
					if (childResult != null) {
						result.addAll(childResult);
					}
				}
			}
			return result;
		}
		public Set<Profile> assignedProfiles { get; set; }
		public Set<User> assignedUsers { get; set; }

		public String getAssignmentString() {
			String result = '<ul>';
			for (Profile p : this.assignedProfiles) {
				result += '<li class="profile"><a href="/'+p.Id+'" target="_blank">' + p.Name + '</a></li>';
			}
		        for (User u : this.assignedUsers) {
		        	if (u != null) {
		                	result += '<li class="user"><a href="/'+u.Id+'" target="_blank">' + u.Name + '</a></li>';
		        	}
		        }

			result += '</ul>';
			return result;
		}

		public PermissionGroup(PermissionGroup__c obj) {
			this(obj, null);
		}

		public PermissionGroup(PermissionGroup__c obj, List<PermissionGroup> children) {
			this.obj = obj;
			this.permissionSets = permissionSetStringToPermissionSetList(obj.PermissionSets__c);
			this.children = children;
			this.assignedProfiles = new Set<Profile>();
			this.assignedUsers = new Set<User>();
		}

		public void setChildren(List<PermissionGroup> children) {
			this.children = children;
		}

		public String getChildrenHTML() {
			String result = '<ul>';
			if (this.children != null) {
				for (PermissionGroup pg : this.children) {
					result += '<li class="pg"><a href="/'+pg.obj.id + '" target="_blank">' + pg.obj.Name + '</a><br />';
					result += pg.getChildrenHTML();
					result += '</li>';
				}
			}
			if (this.permissionSets != null) {
				for (PermissionSet ps : this.permissionSets) {
					result += '<li class="ps"><a href="/'+ps.Id+'" target="_blank">' + ps.Name + '</a></li>';
				}
			}
			result += '</ul>';
			return result;
		}

		public String getParentHTML() {
			String result = '<ul>';
			for (PermissionGroup__c parentPg : allDescendantsPermissionGroupCache.keySet()) {
				if (allDescendantsPermissionGroupCache.get(parentPg).contains(this.obj)) {
					result += '<li class="pg"><a href="/'+parentPg.id+'" target="_blank">' + parentPg.Name + '</a></li>';
				}
			}
			result += '</ul>';
			return result;
		}
        
        global Integer compareTo(Object o) {
            PermissionGroup pg = (PermissionGroup) o;
            if (pg.obj.Name == this.obj.name) {
                return 0;
            } else if (pg.obj.Name > this.obj.Name) {
                return -1;
            } else {
                return 1;
            }
        }
	}

	/* Public methods */
	public static CalculationResult calculate(Set<Id> userIds, Set<String> profileNames) {
		clearCache();
		CalculationResult calculationResult = null;

		Set<Id> profileUserIds = profileIdsToUserIds(profileNamesToProfileIds(profileNames));
		if (userIds == null) {
			userIds = new Set<Id>();
		}
		userIds.addAll(profileUserIds);

		Map<Id, User> userMap = new Map<Id, User>((List<User>) GW_sObject.queryRecords('User', userIds));
		Set<Id> profileIds = new Set<Id>();
		for (User u : userMap.values()) {
			profileIds.add(u.ProfileId);
		}

		Map<Id, String> profileNameMap = new Map<Id, String>();
		Map<Id, Profile> profileMap = new Map<Id, Profile>( ((List<Profile>) GW_sObject.queryRecords('Profile', profileIds)) );

		for (Profile p : profileMap.values()) {
			profileNameMap.put(p.Id, p.Name);
		}

		// Get all related top-level assignments
		List<PermissionGroupAssignment__c> assignments = permissionGroupAssignmentCache;
		Map<Id,List<PermissionGroup__c>> profileIdToPermissionGroups = new Map<Id, List<PermissionGroup__c>>();
		Map<Id,List<PermissionGroup__c>> userIdToPermissionGroups = new Map<Id, List<PermissionGroup__c>>();

		for (PermissionGroupAssignment__c pga : assignments) {
			if (pga.Type__c == 'User') {
				List<PermissionGroup__c> mapItem = userIdToPermissionGroups.get(pga.User__c);
				if (mapItem == null) {
					mapItem = new List<PermissionGroup__c>();
				}
				mapItem.add(permissionGroupCache.get(pga.PermissionGroup__c));
				userIdToPermissionGroups.put(pga.User__c, mapItem);
				// containsKey() is required to prevent error due to user language change
			} else if (pga.Type__c == 'Profile' && profileNameCache.containsKey(pga.Profile__c)) {
				Id profileId = profileNameCache.get(pga.Profile__c).Id;
				List<PermissionGroup__c> mapItem = profileIdToPermissionGroups.get(profileId);
				if (mapItem == null) {
					mapItem = new List<PermissionGroup__c>();
				}
				mapItem.add(permissionGroupCache.get(pga.PermissionGroup__c));
				profileIdToPermissionGroups.put(profileId, mapItem);
			}
		}

		Map<Id,List<PermissionGroup__c>> combinedUserIdToPermissionGroups = new Map<Id,List<PermissionGroup__c>>();

		for (Id userId : userIds) {
			List<PermissionGroup__c> mapItem = combinedUserIdToPermissionGroups.get(userId);
			if (mapItem == null) {
				mapItem = new List<PermissionGroup__c>();
			}
			List<PermissionGroup__c> byUser = userIdToPermissionGroups.get(userId);
			if (byUser != null) {
				mapItem.addAll(byUser);
			}
			List<PermissionGroup__c> byProfile = profileIdToPermissionGroups.get(userMap.get(userId).ProfileId);
			if (byProfile != null) {
				mapItem.addAll(byProfile);
			}
			combinedUserIdToPermissionGroups.put(userId, mapItem);
		}


		Map<Id,Set<PermissionSet>> combinedUserIdToPermissionSets = new Map<Id, Set<PermissionSet>>();

		for (Id userId : combinedUserIdToPermissionGroups.keySet()) {
			Set<PermissionSet> result = new Set<PermissionSet>();
			for (PermissionGroup__c pg : combinedUserIdToPermissionGroups.get(userId)) {
				PermissionGroup apg = apexPermissionGroupCache.get(pg);

				result.addAll(apg.getEffectivePermissionSets());
			}
			combinedUserIdToPermissionSets.put(userId, result);
		}

		Map<Id,Set<PermissionSet>> currentUserIdToPermissionSets = new Map<Id, Set<PermissionSet>>();

		for (Id userId : userIds) {
			List<Id> assignedPermissionSetIds = userPermissionSetIdAssignmentCache.get(userId);
			Set<PermissionSet> assignedPermissionSets = new Set<PermissionSet>();
			if (assignedPermissionSetIds != null) {
				for (Id psId : assignedPermissionSetIds) {
					assignedPermissionSets.add(permissionSetCache.get(psId));
				}
			}
			currentUserIdToPermissionSets.put(userId, assignedPermissionSets);
		}

		calculationResult = new CalculationResult();
		calculationResult.changesPending = false;
		calculationResult.desiredStatusByUser = combinedUserIdToPermissionSets;
		calculationResult.currentStatusByUser = currentUserIdToPermissionSets;
		calculationResult.permissionSetsToAdd = new Map<Id,Set<PermissionSet>>();
		calculationResult.permissionSetsToRemove = new Map<Id,Set<PermissionSet>>();

		for (Id userId : calculationResult.desiredStatusByUser.keySet()) {
			for (PermissionSet ps : calculationResult.desiredStatusByUser.get(userId)) {
				if (calculationResult.currentStatusByUser.get(userId).contains(ps) == false) {
					Set<PermissionSet> mapItem = calculationResult.permissionSetsToAdd.get(userId);
					if (mapItem == null) {
						mapItem = new Set<PermissionSet>();
					}
					mapItem.add(ps);
					calculationResult.permissionSetsToAdd.put(userId, mapItem);
				}
			}
		}

		for (Id userId : calculationResult.currentStatusByUser.keySet()) {
			if (calculationResult.currentStatusByUser.get(userId) != null) {
				for (PermissionSet ps : calculationResult.currentStatusByUser.get(userId)) {
					if (calculationResult.desiredStatusByUser.get(userId) != null) {
						if (calculationResult.desiredStatusByUser.get(userId).contains(ps) == false) {
							Set<PermissionSet> mapItem = calculationResult.permissionSetsToRemove.get(userId);
							if (mapItem == null) {
								mapItem = new Set<PermissionSet>();
							}
							mapItem.add(ps);
							calculationResult.permissionSetsToRemove.put(userId, mapItem);
						}
					}
				}
			}
		}

		if (calculationResult.permissionSetsToAdd.keyset().size() > 0 || calculationResult.permissionSetsToRemove.keySet().size() > 0) {
			calculationResult.changesPending = true;
		}

		return calculationResult;
	}

	public static void process(Set<Id> userIds, Set<String> profileNames) {
		Configuration__c conf = Configuration__c.getInstance('EnablePermissionGroups');
		if (conf != null && conf.Value__c == '1') {
			CalculationResult calc = calculate(userIds, profileNames);
			if (calc.changesPending) {
				List<PermissionSetAssignment> permissionSetsToAssign = new List<PermissionSetAssignment>();
				List<PermissionSetAssignment> permissionSetsToRemove = new List<PermissionSetAssignment>();
				List<PermissionSetAssignment> existingPermissionSetAssignments = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment];
				Map<Id,Map<Id,PermissionSetAssignment>> userToPermissionSetIdToAssignmentId = new Map<Id,Map<Id,PermissionSetAssignment>>();
				for (PermissionSetAssignment psa : existingPermissionSetAssignments) {
					Map<Id,PermissionSetAssignment> mapItem = userToPermissionSetIdToAssignmentId.get(psa.AssigneeId);
					if (mapItem == null) {
						mapItem = new Map<Id,PermissionSetAssignment>();
					}
					mapItem.put(psa.PermissionSetId, psa);
					userToPermissionSetIdToAssignmentId.put(psa.AssigneeId, mapItem);
				}
				for (Id userId : calc.permissionSetsToAdd.keySet()) {
					for (PermissionSet ps : calc.permissionSetsToAdd.get(userId)) {
						permissionSetsToAssign.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id));
					}
				}
				for (Id userId : calc.permissionSetsToRemove.keySet()) {
					Map<Id, PermissionSetAssignment>permissionSets = userToPermissionSetIdToAssignmentId.get(userId);
					for (PermissionSet ps : calc.permissionSetsToRemove.get(userId)) {
						if(permissionSets == null || ps == null || !permissionSets.containsKey(ps.Id)) continue;
						permissionSetsToRemove.add(permissionSets.get(ps.Id));
					}
				}

				insert permissionSetsToAssign;
				delete permissionSetsToRemove;
			}
		}
	}



	/* Public helpers */
	public static String validatePermissionSetNames(String names) {
		if (names == null || names == '') {
			return null;
		} else {
			List<String> permissionSetNames = permissionSetStringToPermissionSetStringList(names);
			List<String> errors = new List<String>();
			for (String ps : permissionSetNames) {
				if (permissionSetByNameCache.get(ps) == null) {
					errors.add('Invalid Permission Set Name: ' + ps);
				}
			}
			if (errors.size() == 0) {
				return null;
			} else {
				return String.join(errors, '\n');
			}
		}
	}

	public static String validateAvailability(Id permissionGroupId) {
		PermissionGroup__c pg = permissionGroupCache.get(permissionGroupId);
		Set<PermissionGroup__c> allDescendants = allDescendantsPermissionGroupCache.get(permissionGroupCache.get(permissionGroupId));

		List<String> unavailablePermissionGroups = new List<String>();
		for (PermissionGroup__c dpg : allDescendants) {
			if (dpg.Available__c == false) {
				unavailablePermissionGroups.add('Permission Group: ' + dpg.Name + ' is not set to available.');
			}
		}
		if (pg.Available__c == false) {
			unavailablePermissionGroups.add('Permission Group: ' + pg.Name + ' is not set to available.');
		}

		if (unavailablePermissionGroups.size() == 0) {
			return null;
		} else {
			return String.join(unavailablePermissionGroups, '\n');
		}
	}

	public static Boolean isValidProfileName(String profileName) {
		Boolean found = false;
		for (Profile p : profileCache.values()) {
			if (profileName == p.Name) {
				found = true;
			}
		}
		return found;
	}

	public static String validateDeletion(Id permissionGroupId) {
		// Deletion is not allowed if the PG (or its parents) have any assignments..
		String result = null;

		Set<PermissionGroup__c> relatedPermissionGroups = new Set<PermissionGroup__c>();
		PermissionGroup__c currentPg = permissionGroupCache.get(permissionGroupId);
		relatedPermissionGroups.add(currentPg);
		for (PermissionGroup__c possibleParentPg : allDescendantsPermissionGroupCache.keySet()) {
			if (allDescendantsPermissionGroupCache.get(possibleParentPg).contains(currentPg)) {
				relatedPermissionGroups.add(possibleParentPg);
			}
		}

		List<String> errors = new List<String>();
		for (PermissionGroup__c pg : relatedPermissionGroups) {
			if (permissionGroupToPermissionGroupAssignmentCache.get(pg) != null) {
				if (permissionGroupToPermissionGroupAssignmentCache.get(pg).size() > 0) {
					errors.add('Related Permission Group: ' + pg.Name + ' has assignments, thus you cannot delete ' + currentPg.Name);
				}
			}
		}

		if (errors.size() > 0) {
			result = String.join(errors, '\n');
		}


		return result;
	}

	public static void validateNonRecursive() {
		clearCache();
		for (PermissionGroup__c pg : allDescendantsPermissionGroupCache.keySet()) {
			if (allDescendantsPermissionGroupCache.get(pg).contains(pg)) {
				UTIL.throwError('This would create a recursive permission group structure');
			}
		}
	}

	public static List<User> getUsers() {
		return userCache.values();
	}

	/* Private methods */
	private static Set<Id> profileIdsToUserIds(Set<Id> profileIds) {
		Set<Id> result = new Set<Id>();
		Map<Id, User> userMap = new Map<Id, User>([SELECT Id, ProfileId FROM User WHERE ProfileId IN :profileIds AND IsActive = true]);

		result.addAll(userMap.keySet());
		return result;
	}

	private static Set<Id> profileNamesToProfileIds(Set<String> profileNames) {
		Set<Id> profileIds = new Set<Id>();
		if (profileNames != null) {
			for (Profile p : profileCache.values()) {
				if (profileNames.contains(p.Name)) {
					profileIds.add(p.Id);
				}
			}
		}
		return profileIds;
	}

	private static Id profileNameToProfileId(String profileName) {
		Profile p = profileNameCache.get(profileName);
		if (p != null) {
			return p.Id;
		} else {
			return null;
		}
	}

	private static Set<PermissionSet> permissionSetStringToPermissionSetList(String names) {
		Set<PermissionSet> result = new Set<PermissionSet>();
		if (names == null || names == '') {
			return result;
		} else {
			List<String> permissionSetNames = permissionSetStringToPermissionSetStringList(names);
			for (String ps : permissionSetNames) {
				if (permissionSetBynameCache.get(ps) != null) {
					result.add(permissionSetBynameCache.get(ps));
				}
			}
			return result;
		}
	}

	private static List<String> permissionSetStringToPermissionSetStringList(String names) {
		List<String> result = new List<String>();
		if (names == null || names == '') {
			return result;
		} else {
			List<String> parts = names.split(',');
			for (String p : parts) {
				result.add(p.deleteWhitespace());
			}
			return result;
		}
	}

	private static Set<PermissionGroup__c> getAllChildren(PermissionGroup__c pg, Set<PermissionGroup__c> passedPgs) {
		Set<PermissionGroup__c> allChildren = new Set<PermissionGroup__c>();
		Set<PermissionGroup__c> myChildren = childPermissionGroupCache.get(pg);
		if (passedPgs == null) {
			passedPgs = new Set<PermissionGroup__c>();
		} else {
			if (passedPgs.contains(pg)) {
				UTIL.throwError('Recursion detected!');
			}
		}
		passedPgs.add(pg);
		if (myChildren != null) {
			for (PermissionGroup__c result : myChildren) {
				Set<PermissionGroup__c> childrenResult = getAllChildren(result, passedPgs);
				allChildren.addAll(childrenResult);
				passedPgs = null;
			}
			allChildren.addAll(myChildren);
		}
		return allChildren;
	}

	public static void clearCache() {
		apexPermissionGroupCache = null;
		permissionSetCache = null;
		permissionSetByNameCache = null;
		permissionGroupCache = null;
		permissionGroupRelationshipCache = null;
		childPermissionGroupCache = null;
		allDescendantsPermissionGroupCache = null;
		permissionGroupAssignmentCache = null;
		permissionGroupToPermissionGroupAssignmentCache = null;
		profileNameCache = null;
		userCache = null;
		userPermissionSetIdAssignmentCache = null;
	}

	public static Map<Id, PermissionGroup> getApexPermissionGroupCache() {
		Map<Id, PermissionGroup> result = new Map<Id, PermissionGroup>();
		for (PermissionGroup__c pg : apexPermissionGroupCache.keySet()) {
			result.put(pg.Id, apexPermissionGroupCache.get(pg));
		}
		return result;
	}

	public static Map<Id, PermissionGroup__c> getPermissionGroupCache() {
		return permissionGroupCache;
	}

	public static Map<Id, Profile> getProfileCache() {
		return profileCache;
	}

	public static Map<Id, PermissionSet> getPermissionSetCache() {
		return permissionSetCache;
	}



	/* Private cache */
	private static Map<PermissionGroup__c, PermissionGroup> apexPermissionGroupCache {
		get {
			if (apexPermissionGroupCache == null) {
				apexPermissionGroupCache = new Map<PermissionGroup__c, PermissionGroup>();
				for (PermissionGroup__c pg : permissionGroupCache.values()) {
					PermissionGroup apg = new PermissionGroup(pg);
					apexPermissionGroupCache.put(pg, apg);
				}
				for (PermissionGroup__c pg : apexPermissionGroupCache.keySet()) {
					Set<PermissionGroup__c> children = childPermissionGroupCache.get(pg);
					List<PermissionGroup> apgChildren = new List<PermissionGroup>();
					if (children != null) {
						for (PermissionGroup__c child : children) {
							apgChildren.add(apexPermissionGroupCache.get(child));
						}
					}
					apexPermissionGroupCache.get(pg).setChildren(apgChildren);
				}
				for (PermissionGroupAssignment__c  pga : permissionGroupAssignmentCache) {
					if (pga.Type__c == 'Profile') {
						apexPermissionGroupCache.get(permissionGroupCache.get(pga.PermissionGroup__c)).assignedProfiles.add(profileNameCache.get(pga.Profile__c));
					} else if (pga.Type__c == 'User') {
						apexPermissionGroupCache.get(permissionGroupCache.get(pga.PermissionGroup__c)).assignedUsers.add(userCache.get(pga.User__c));
					}
				}
			}
			return apexPermissionGroupCache;
		}
	}

	private static Map<Id,PermissionSet> permissionSetCache {
		get {
			if (permissionSetCache == null) {
				permissionSetCache = new Map<Id, PermissionSet>((List<PermissionSet>) GW_sObject.queryRecords('PermissionSet', ''));
			}
			return permissionSetCache;
		} private set;
	}

	private static Map<String, PermissionSet> permissionSetByNameCache {
		get {
			if (permissionSetByNameCache == null) {
				permissionSetByNameCache = new Map<String, PermissionSet>();
				for (PermissionSet ps : permissionSetCache.values()) {
					permissionSetByNameCache.put(ps.Name, ps);
				}
			}
			return permissionSetByNameCache;
		} private set;
	}

	private static Map<Id, PermissionGroup__c> permissionGroupCache {
		get {
			if (permissionGroupCache == null) {
				permissionGroupCache = new Map<Id, PermissionGroup__c>((List<PermissionGroup__c>) GW_sObject.queryRecords('PermissionGroup__c', ''));
			}
			return permissionGroupCache;
		} private set;
	}

	private static Map<Id, PermissionGroupRelationship__c> permissionGroupRelationshipCache {
		get {
			if (permissionGroupRelationshipCache == null) {
				permissionGroupRelationshipCache = new Map<Id, PermissionGroupRelationship__c>((List<PermissionGroupRelationship__c>) GW_sObject.queryRecords('PermissionGroupRelationship__c', ''));
			}
			return permissionGroupRelationshipCache;
		} private set;
	}

	private static Map<PermissionGroup__c, Set<PermissionGroup__c>> childPermissionGroupCache {
		get {
			if (childPermissionGroupCache == null) {
				childPermissionGroupCache = new Map<PermissionGroup__c, Set<PermissionGroup__c>>();
				for (PermissionGroupRelationship__c pgr : permissionGroupRelationshipCache.values()) {
					Set<PermissionGroup__c> mapItem = childPermissionGroupCache.get(permissionGroupCache.get(pgr.Parent__c));
					if (mapItem == null) {
						mapItem = new Set<PermissionGroup__c>();
					}
					mapItem.add(permissionGroupCache.get(pgr.Child__c));
					childPermissionGroupCache.put(permissionGroupCache.get(pgr.Parent__c), mapitem);
				}
			}
			return childPermissionGroupCache;
		} private set;
	}

	private static Map<PermissionGroup__c, Set<PermissionGroup__c>> allDescendantsPermissionGroupCache {
		get {
			if (allDescendantsPermissionGroupCache == null) {
				allDescendantsPermissionGroupCache = new Map<PermissionGroup__c, Set<PermissionGroup__c>>();
				for (PermissionGroup__c pg : permissionGroupCache.values()) {
					allDescendantsPermissionGroupCache.put(pg, getAllChildren(pg, null));
				}
			}
			return allDescendantsPermissionGroupCache;
		} private set;
	}

	private static List<PermissionGroupAssignment__c> permissionGroupAssignmentCache {
		get {
			if (permissionGroupAssignmentCache == null) {
				permissionGroupAssignmentCache = (List<PermissionGroupAssignment__c>) GW_sObject.queryRecords('PermissionGroupAssignment__c', '');
			}
			return permissionGroupAssignmentCache;
		} private set;
	}

	private static Map<PermissionGroup__c, List<PermissionGroupAssignment__c>> permissionGroupToPermissionGroupAssignmentCache {
		get {
			if (permissionGroupToPermissionGroupAssignmentCache == null) {
				permissionGroupToPermissionGroupAssignmentCache = new Map<PermissionGroup__c, List<PermissionGroupAssignment__c>>();
				for (PermissionGroupAssignment__c pga : permissionGroupAssignmentCache) {
					PermissionGroup__c pg = permissionGroupCache.get(pga.PermissionGroup__c);
					List<PermissionGroupAssignment__c> mapItem = permissionGroupToPermissionGroupAssignmentCache.get(pg);
					if (mapItem == null) {
						mapItem = new List<PermissionGroupAssignment__c>();
					}
					mapItem.add(pga);
					permissionGroupToPermissionGroupAssignmentCache.put(pg, mapItem);
				}
			}
			return permissionGroupToPermissionGroupAssignmentCache;
		} private set;
	}

	private static Map<String,Profile> profileNameCache {
		get {
			if (profileNameCache == null) {
				profileNameCache = new Map<String,Profile>();
				for (Profile p : profileCache.values()) {
					profileNameCache.put(p.Name, p);
				}
			}
			return profileNameCache;
		} private set;
	}

	private static Map<Id,User> userCache {
		get {
			if (userCache == null) {
				userCache = new Map<Id,User>();
				for (User u : (List<User>) GW_sObject.queryRecords('User', 'ContactId = null AND IsActive = true')) {
					userCache.put(u.Id, u);
				}
			}
			return userCache;
		} private set;
	}

	private static Map<Id,Profile> profileCache {
		get {
			if (profileCache == null) {
				profileCache = new Map<Id,Profile>();
				for (Profile p : [SELECT Id, Name FROM Profile]) {
					profileCache.put(p.Id, p);
				}
			}
			return profileCache;
		} private set;
	}

	private static Map<Id,List<Id>> userPermissionSetIdAssignmentCache {
		get {
			if (userPermissionSetIdAssignmentCache == null) {
				userPermissionSetIdAssignmentCache = new Map<Id, List<Id>>();
				List<PermissionSetAssignment> assignments = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSet.IsOwnedByProfile = false];
				for (PermissionSetAssignment psa : assignments) {
					List<Id> mapItem = userPermissionSetIdAssignmentCache.get(psa.AssigneeId);
					if (mapItem == null) {
						mapItem = new List<Id>();
					}
					mapItem.add(psa.PermissionSetId);
					userPermissionSetIdAssignmentCache.put(psa.AssigneeId, mapItem);
				}
			}
			return userPermissionSetIdAssignmentCache;
		} private set;
	}
}