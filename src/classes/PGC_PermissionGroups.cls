public with sharing class PGC_PermissionGroups {
	public F_PermissionGroup.CalculationResult calcResult { get; set; }
    public String filterMode { get; set; }
	public Map<Id, User> userMap { get; set; }
	public transient Map<Id, Profile> profileMap { get; set; }
	public transient Map<Id, PermissionGroup__c> permissionGroupMap { get; set; }
	public transient Map<Id, F_PermissionGroup.PermissionGroup> apexPermissionGroupMap { get; set; }
	public transient Map<Id, PermissionSet> permissionSetMap { get; set; }
	public transient Map<Id, UserRole> roleMap { get; set; }
	public transient Map<Id, Action> actionMap { get; set; }
    public transient Map<Id, Member__c> memberMap { get; set; }
	public List<Action> actionList { get; set;}
	public List<F_PermissionGroup.PermissionGroup> apexPermissionGroupList { get {
		if(apexPermissionGroupMap == null){
			this.apexPermissionGroupMap = F_PermissionGroup.getApexPermissionGroupCache();
		}
        List<F_PermissionGroup.PermissionGroup> result = apexPermissionGroupMap.values();
        result.sort();
        if (this.filterMode == 'member') {
            Set<String> memberNames = new Set<String>();
            for (Member__c m : this.memberMap.values()) {
                memberNames.add(m.MemberId__c);
            }
            List<F_PermissionGroup.PermissionGroup> newResult = new List<F_PermissionGroup.PermissionGroup>();
            for (F_PermissionGroup.PermissionGroup pg : result) {
                Boolean found = false;
                for (String s : memberNames) {
                    if (pg.obj.Name.indexOf(s) > -1) {
                        found = true;
                    }
                }
                if (found) {
                    newResult.add(pg);
                }
            }
            return newResult;
        } else if (this.filterMode == 'assigned') {
            List<F_PermissionGroup.PermissionGroup> newResult = new List<F_PermissionGroup.PermissionGroup>();
            for (F_PermissionGroup.PermissionGroup pg : result) {
                if (pg.assignedProfiles.size() > 0 || pg.assignedUsers.size() > 0) {
                    newResult.add(pg);
                }
            }
            return newResult;
        } else if (this.filterMode == 'userAssigned') {
            List<F_PermissionGroup.PermissionGroup> newResult = new List<F_PermissionGroup.PermissionGroup>();
            for (F_PermissionGroup.PermissionGroup pg : result) {
                if (pg.assignedUsers.size() > 0) {
                    newResult.add(pg);
                }
            }
            return newResult;
        } else if (this.filterMode == 'profileAssigned') {
            List<F_PermissionGroup.PermissionGroup> newResult = new List<F_PermissionGroup.PermissionGroup>();
            for (F_PermissionGroup.PermissionGroup pg : result) {
                if (pg.assignedProfiles.size() > 0) {
                    newResult.add(pg);
                }
            }
            return newResult;
        }
		return result;
	} private set;}
	public Id selectedUserId { get; set; }

	public class Action {
		public User user { get; set; }
		public List<PermissionSet> addItems { get; set; }
		public List<PermissionSet> removeItems { get; set; }
		public String addItemsString { get {
			List<String> names = new List<String>();
			for (PermissionSet ps : this.addItems) {
				names.add(ps.Name);
			}
			return String.join(names, '<br />\n');
		} private set;}
		public String removeItemsString { get {
			List<String> names = new List<String>();
			for (PermissionSet ps : this.removeItems) {
				names.add(ps.Name);
			}
			return String.join(names, '<br />\n');
		} private set;}

		public Action(User user) {
			this.user = user;
			this.addItems = new List<PermissionSet>();
			this.removeItems = new List<PermissionSet>();
		}

		public void add(PermissionSet ps) {
			this.addItems.add(ps);
		}

		public void remove(PermissionSet ps) {
			this.removeItems.add(ps);
		}
	}

	public PGC_PermissionGroups() {
		this.userMap = new Map<Id, User>((List<User>) GW_sObject.queryRecords('User', 'IsActive = true AND ContactId = null'));
		this.profileMap = new Map<Id, Profile>((List<Profile>) GW_sObject.queryRecords('Profile', ''));
		this.permissionGroupMap = new Map<Id, PermissionGroup__c>((List<PermissionGroup__c>) GW_sObject.queryRecords('PermissionGroup__c', ''));
		this.permissionSetMap = new Map<Id, PermissionSet>((List<PermissionSet>) GW_sObject.queryRecords('PermissionSet', ''));
		this.roleMap = new Map<Id,UserRole>((List<UserRole>) GW_sObject.queryRecords('UserRole', ''));
        this.memberMap = new Map<Id,Member__c>((List<Member__c>) GW_sObject.queryRecords('Member__c', ''));
		this.calc();
		this.actionList= actionMap.values();
		this.apexPermissionGroupMap = F_PermissionGroup.getApexPermissionGroupCache();
        this.filterMode = 'all';
	}
	// Entire tree for all PS

	public PageReference applyChanges() {
		try {
			F_PermissionGroup.process(this.userMap.keySet(), null);
			this.calc();
			this.actionList= actionMap.values();
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Permission Groups were successfully applied'));
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error applying Permission Groups: ' + e.getMessage() + ' Trace: ' + e.getStackTraceString()));
		}
		return null;
	}

	public PageReference applyUserChanges() {
		try {
			F_PermissionGroup.process(new Set<Id>{this.selectedUserId}, null);
			this.calc();
			this.actionList= actionMap.values();
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Permission Groups were successfully applied for user: ' + this.userMap.get(this.selectedUserId).Username));
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error applying Permission Groups: ' + e.getMessage() + ' Trace: ' + e.getStackTraceString()));
		}
		return null;
	}
    
    public PageReference applyFilter() {
		return null;
	}

	private void calc() {
		this.calcResult = F_PermissionGroup.calculate(this.userMap.keySet(), null);
		if (this.calcResult.changesPending) {
			this.actionMap = new Map<Id, Action>();
			for (Id userId : this.calcResult.permissionSetsToAdd.keySet()) {
				Action userAction = this.actionMap.get(userId);
				if (userAction == null) {
					userAction = new Action(this.userMap.get(userId));
				}
				for (PermissionSet ps : this.calcResult.permissionSetsToAdd.get(userId)) {
					userAction.add(ps);
				}
				this.actionMap.put(userId, userAction);
			}
			for (Id userId : this.calcResult.permissionSetsToRemove.keySet()) {
				Action userAction = this.actionMap.get(userId);
				if (userAction == null) {
					userAction = new Action(this.userMap.get(userId));
				}
				for (PermissionSet ps : this.calcResult.permissionSetsToRemove.get(userId)) {
					userAction.remove(ps);
				}
				this.actionMap.put(userId, userAction);
			}
		} else {
			this.actionMap = new Map<Id, Action>();
		}
	}
    
    public String getGraphBuilderString() {
        String par;
        String chi; 
        String tmp = 'http://yuml.me/diagram/nofunky/class/';
        List<PermissionGroupRelationship__c> pgr = [select id, Parent__r.PermissionSets__c, Child__r.PermissionSets__c, Child__r.Name, Parent__r.Name from PermissionGroupRelationship__c where (not Name like 'ORIG_%') and (not Parent__r.Name like 'ORIG_%') and (not Child__r.Name like 'ORIG_%')  ];
        for (PermissionGroupRelationship__c x: pgr) {
            par = x.Parent__r.Name; 
            chi = x.Child__r.Name;
            if(x.Parent__r.PermissionSets__c != null) {
                par += '|'+ x.Parent__r.PermissionSets__c.replace(',',';+');
            }
			if(x.Child__r.PermissionSets__c != null) {
                chi += '|'+ x.Child__r.PermissionSets__c.replace(',',';+');
            }
            tmp += '['+par+']^['+chi+'],';
        } 
        tmp = tmp.substring(0, tmp.length()-1);
        System.debug(tmp);
        return tmp;
    }

}