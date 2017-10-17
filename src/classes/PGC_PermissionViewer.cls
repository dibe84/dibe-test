global with sharing class PGC_PermissionViewer {
	global class PVObject implements Comparable {
		public String name { get; set; }
		public String label { get; set; }
		public String type { get; set; }
		public PVValue c { get; set; }
		public PVValue r { get; set; }
		public PVValue u { get; set; }
		public PVValue d { get; set; }
		public PVValue v { get; set; }
		public PVValue w { get; set; }
		public List<PVField> fields { get; set; }
		public Integer getTotalNumberOfFields() {
			Integer count = 0;
			for (PVField f : this.fields) {
				count++;
			}
			return count;
		}
		public Integer getReadNumberOfFields() {
			Integer count = 0;
			for (PVField f : this.fields) {
				if (f.r.getValue() == true) {
					count++;
				}
			}
			return count;
		}
		public Integer getWriteNumberOfFields() {
			Integer count = 0;
			for (PVField f : this.fields) {
				if (f.w.getValue() == true) {
					count++;
				}
			}
			return count;
		}

		public PVObject(String name, String label, String type) {
			this.name = name;
			this.label = label;
			this.type = type;
			this.c = new PVValue();
			this.r = new PVValue();
			this.u = new PVValue();
			this.d = new PVValue();
			this.v = new PVValue();
			this.w = new PVValue();
			this.fields = new List<PVField>();

		}

		public void addField(PVField field) {
			this.fields.add(field);
		}

		global Integer compareTo(Object compareTo) {
			PVObject pvObj = (PVObject) compareTo;
			if (this.name == pvObj.Name) {
				return 0;
			} else {
				return this.name > pvObj.Name ? 1 : -1;
			}
		}

		public Boolean hasAssignment() {
			return (this.c.getValue() == true ||
				this.r.getValue() == true ||
				this.u.getValue() == true ||
				this.d.getValue() == true ||
				this.v.getValue() == true ||
				this.w.getValue() == true ||
				this.getReadNumberOfFields() > 0
			);
		}
	}

	global class PVField implements Comparable {
		public String name { get; set; }
		public String label { get; set; }
		public PVValue r { get; set; }
		public PVValue w { get; set; }

		public PVField(String name, String label) {
			this.name = name;
			this.label = label;
			this.r = new PVValue();
			this.w = new PVValue();
		}

		global Integer compareTo(Object compareTo) {
			PVField pvField = (PVField) compareTo;
			if (this.name == pvField.Name) {
				return 0;
			} else {
				return this.name > pvField.Name ? 1 : -1;
			}
		}
	}

	public class PVValue {
		public List<PVSource> sources { get; set; }
		public Object getValue() {
			return this.sources.size() > 0;
		}

		public String getHTML() {
			if (this.getValue() == true) {
				return '<div style="background-color: green; color: white; text-align: center;" title="'+this.getTitle()+'">' + this.sources.size() + '</div>';
			} else {
				return '<div style="background-color: red; text-align: center;">&nbsp;</div>';
			}
		}

		private String getTitle() {
			List<String> result = new List<String>();
			for (PVSource source : this.sources) {
				result.add(source.name);
			}
			return String.join(result, ',');
		}

		public void addSource(PVSource source) {
			this.sources.add(source);
		}

		public PVValue() {
			this.sources = new List<PVSource>();
		}
	}

	public class PVSource {
		public String type { get; set; }
		public Id sourceId { get; set; }
		public String name { get; set; }

		public PVSource(String type, Id sourceId, String name) {
			this.type = type;
			this.sourceId = sourceId;
			this.name = name;
		}
	}

	public class PVPermission {
		public String name { get; set; }
		public PVValue value { get; set; }

		public PVPermission(String name) {
			this.name = name;
			this.value = new PVValue();
		}
	}

	public Map<String, PVObject> objects { get; set; }
	public List<PVObject> getObjectList() {
		List<PVObject> values = this.objects.values();
		values.sort();
		return values;
	}
	public Map<String, PVPermission> systemPermissions { get; set; }
	public List<PVPermission> getSystemPermissionList() {
		List<PVPermission> values = this.systemPermissions.values();
		return values;
	}

	public Map<String,Map<String,Id>> options { get; set; }
	public String objectType { get; set; }
	public Set<Id> selectedIds { get; set; }
	public String selectedIdsJSON { get {
		return JSON.serialize(this.selectedIds);
	}}

	public String getSelectedIdsAsString() {
		List<String> stack = new List<String>();
		Map<Id, PermissionSet> permissionSets = F_PermissionGroup.getPermissionSetCache();
		Map<Id, Profile> profileMap = F_PermissionGroup.getProfileCache();
		for (Id selectedid : this.selectedIds) {
			if (GW_sObject.getobjectNameFromId(selectedId) == 'PermissionGroup__c') {
				stack.add('PG: ' + F_PermissionGroup.getPermissionGroupCache().get(selectedId).Name);
			} else if (GW_sObject.getobjectNameFromId(selectedId) == 'PermissionSet') {
				PermissionSet ps = permissionSets.get(selectedId);
				if (ps.ProfileId == null) {
					stack.add('PS: ' + ps.Name);
				} else {
					stack.add('Profile: ' + profileMap.get(ps.ProfileId).Name);
				}
			}
		}
		return String.join(stack, ', ');
	}
	public static Set<String> setupObjects = new Set<String>();
	public static Set<String> nonSetupObjects = new Set<String>{'Account', 'Contact', 'Lead', 'Campaign', 'CampaignMember', 'Product2', 'PricebookEntry', 'Pricebook2', 'Opportunity', 'OpportunityLineItem', 'User', 'Task', 'Case', 'Event', 'CaseComment'};


	public PGC_PermissionViewer() {
		this.selectedIds = new Set<Id>();
		// These can be permisison set IDs or permission group IDs

		String idParam = ApexPages.currentPage().getParameters().get('id');
		if (idParam != null && idParam != '') {
			List<String> params = idParam.split(',');
			for (String param : params) {
				selectedIds.add(Id.valueOf(param));
			}
		}

		Set<Id> permissionSetIds = new Set<Id>();

		for (Id selectedId : selectedIds) {
			if (GW_sObject.getobjectNameFromId(selectedId) == 'PermissionGroup__c') {
				for (PermissionSet ps : F_PermissionGroup.getApexPermissionGroupCache().get(selectedId).getEffectivePermissionSets()) {
					permissionSetIds.add(ps.id);
				}
			} else if (GW_sObject.getobjectNameFromId(selectedId) == 'PermissionSet') {
				permissionSetIds.add(selectedId);
			}
		}

		this.objectType = ApexPages.currentPage().getParameters().get('objectType');
		if (this.objectType == null) {
			this.objectType = 'all';
		}

		this.options = PGC_PermissionViewer.buildOptions();
		this.objects = PGC_PermissionViewer.buildBase(null);
		this.systemPermissions = new Map<String,PVPermission>();
		Map<String,Set<PermissionSet>> data = queryPermissionSets(permissionSetIds);
		applyResult(this.objects, this.systemPermissions, data);

		List<String> keysToRemove = new List<String>();
		if (this.objectType == 'all') {
			// fine, do nothing
		} else if (this.objectType == 'assigned') {
			for (String s : this.objects.keySet()) {
				if (this.objects.get(s).hasAssignment() == false) {
					keysToRemove.add(s);
				}
			}
		} else if (this.objectType == 'nonsetup') {
			for (String s : this.objects.keySet()) {
				if (nonSetupObjects.contains(s) == false && s.contains('__c') == false) {
					keysToRemove.add(s);
				}
			}
		} else if (this.objectType == 'nonsetupnonmanaged') {
			for (String s : this.objects.keySet()) {
				if ((nonSetupObjects.contains(s) == false && s.contains('__c') == false) || s.countMatches('__') == 2) {
					keysToRemove.add(s);
				}
			}
		} else if (this.objectType == 'nonsetupnonmanagednoncs') {
			for (String s : this.objects.keySet()) {
				if ((nonSetupObjects.contains(s) == false && s.contains('__c') == false) || s.countMatches('__') == 2) {
					keysToRemove.add(s);
				}
				if (this.objects.get(s).type == 'Custom Setting') {
					keysToRemove.add(s);
				}
			}
		}

		for (String s : keysToRemove) {
			this.objects.remove(s);
		}
	}

	private static Map<String,Map<String,Id>> buildOptions() {
		Map<String,Map<String,Id>> result = new Map<String,Map<String,Id>>();
		result.put('Profile', new Map<String,Id>());
		result.put('Permission Group', new Map<String,Id>());
		result.put('Permission Set', new Map<String,Id>());
		// We should be able to select Permission Sets, Profiles and Permission Groups
		Map<Id, PermissionSet> permissionSets = F_PermissionGroup.getPermissionSetCache();
		Map<Id, Profile> profileMap = F_PermissionGroup.getProfileCache();
		for (PermissionSet ps : permissionSets.values()) {
			if (ps.ProfileId != null) {
				result.get('Profile').put(profileMap.get(ps.ProfileId).Name, ps.Id);
			} else {
				result.get('Permission Set').put(ps.name, ps.Id);
			}

		}

		Map<Id, PermissionGroup__c> permissionGroups = new Map<Id, PermissionGroup__c>((List<PermissionGroup__c>) GW_sObject.queryRecords('PermissionGroup__c', ''));
		for (PermissionGroup__c pg : permissionGroups.values()) {
			result.get('Permission Group').put(pg.name, pg.Id);
		}

		return result;
	}

	private static Map<String,Set<PermissionSet>> queryPermissionSets(Set<Id> permissionSetIds) {
		Map<String,Set<PermissionSet>> result = new Map<String,Set<PermissionSet>>();
		Map<Id, PermissionSet> permissionSets = new Map<Id, PermissionSet>((List<PermissionSet>) GW_sObject.queryRecords('PermissionSet', permissionSetIds));
		// Object permissions
		List<ObjectPermissions> objectPermissions = [SELECT
			ParentId, PermissionsCreate, PermissionsDelete, PermissionsRead, PermissionsEdit, PermissionsModifyAllRecords, PermissionsViewAllRecords, SobjectType
			FROM ObjectPermissions
			WHERE ParentId IN :permissionSetIds
			AND (PermissionsCreate = true OR PermissionsDelete = true OR PermissionsRead = true OR PermissionsEdit = true OR PermissionsModifyAllRecords = true OR PermissionsViewAllRecords = true)
		];

		for (ObjectPermissions op : objectPermissions) {
			Set<String> keysToAdd = new Set<String>();
			if (op.PermissionsCreate) keysToAdd.add('OBJ_' + op.SobjectType + '_c');
			if (op.PermissionsRead) keysToAdd.add('OBJ_' + op.SobjectType + '_r');
			if (op.PermissionsEdit) keysToAdd.add('OBJ_' + op.SobjectType + '_u');
			if (op.PermissionsDelete) keysToAdd.add('OBJ_' + op.SobjectType + '_d');
			if (op.PermissionsViewAllRecords) keysToAdd.add('OBJ_' + op.SobjectType + '_v');
			if (op.PermissionsModifyAllRecords) keysToAdd.add('OBJ_' + op.SobjectType + '_w');
			for (String s : keysToAdd) {
				Set<PermissionSet> mapItem = result.get(s);
				if (mapItem == null) {
					mapItem = new Set<PermissionSet>();
				}
				mapItem.add(permissionSets.get(op.ParentId));
				result.put(s, mapItem);
			}
		}

		List<FieldPermissions> fieldPermissions = [SELECT
			ParentId, PermissionsEdit, PermissionsRead, SobjectType, Field
			FROM FieldPermissions
			WHERE ParentId IN :permissionSetIds
			AND (PermissionsRead = true OR PermissionsEdit = true)
		];

		for (FieldPermissions fp : fieldPermissions) {
			Set<String> keysToAdd = new Set<String>();
			if (fp.PermissionsRead) keysToAdd.add('FIELD_' +  fp.Field + '_r');
			if (fp.PermissionsEdit) keysToAdd.add('FIELD_' + fp.Field + '_w');
			for (String s : keysToAdd) {
				Set<PermissionSet> mapItem = result.get(s);
				if (mapItem == null) {
					mapItem = new Set<PermissionSet>();
				}
				mapItem.add(permissionSets.get(fp.ParentId));
				result.put(s, mapItem);
			}
		}

		// System Permissions
		Schema.DescribeSObjectResult dr = PermissionSet.sObjectType.getDescribe();
		Map<String, Schema.SObjectField> fm = dr.fields.getMap();

		Set<String> unqueryablePermissions = new Set<String>{'PermissionsConfigCustomRecs', 'PermissionsLightningExperienceUser'};

		for (PermissionSet ps : permissionSets.values()) {
			Set<String> keysToAdd = new Set<String>();
			for (String s : fm.keySet()) {
				try {
					if (ps.get(s) == true && s.substring(0,11) == 'Permissions') {
						keysToAdd.add('PERM_' + s.substring(11));
					}
				} catch (Exception e) {
					// unqueryable field..
				}
			}
			for (String s : keysToAdd) {
				Set<PermissionSet> mapItem = result.get(s);
				if (mapItem == null) {
					mapItem = new Set<PermissionSet>();
				}
				mapItem.add(permissionSets.get(ps.Id));
				result.put(s, mapItem);
			}
		}

		return result;
		// Field permissions
	}

	private static void applyResult(Map<String, PVObject> objects, Map<String, PVPermission> systemPermissions, Map<String,Set<PermissionSet>> permissions) {
		Map<Id, PVSource> sourceMap = new Map<Id, PVSource>();
		Map<Id, PermissionSet> permissionSets = new Map<Id, PermissionSet>((List<PermissionSet>) GW_sObject.queryRecords('PermissionSet', ''));
		Map<Id, Profile> profileMap = new Map<Id, Profile>((List<Profile>) GW_sObject.queryRecords('Profile', ''));

		for (PermissionSet ps : permissionSets.values()) {
			if (ps.ProfileId != null) {
				sourceMap.put(ps.Id, new PVSource('PermissionSet', ps.Id, profileMap.get(ps.ProfileId).Name));
			} else {
				sourceMap.put(ps.Id, new PVSource('PermissionSet', ps.Id, ps.Name));
			}
		}

		for (PVObject pvObj : objects.values()) {
			Set<PermissionSet> cPermissionSets = permissions.get('OBJ_' + pvObj.name + '_c');
			Set<PermissionSet> rPermissionSets = permissions.get('OBJ_' + pvObj.name + '_r');
			Set<PermissionSet> uPermissionSets = permissions.get('OBJ_' + pvObj.name + '_u');
			Set<PermissionSet> dPermissionSets = permissions.get('OBJ_' + pvObj.name + '_d');
			Set<PermissionSet> vPermissionSets = permissions.get('OBJ_' + pvObj.name + '_v');
			Set<PermissionSet> wPermissionSets = permissions.get('OBJ_' + pvObj.name + '_w');

			if (cPermissionSets != null) {
				for (PermissionSet ps : cPermissionSets) {
					pvObj.c.addSource(sourceMap.get(ps.Id));
				}
			}
			if (rPermissionSets != null) {
				for (PermissionSet ps : rPermissionSets) {
					pvObj.r.addSource(sourceMap.get(ps.Id));
				}
			}
			if (uPermissionSets != null) {
				for (PermissionSet ps : uPermissionSets) {
					pvObj.u.addSource(sourceMap.get(ps.Id));
				}
			}
			if (dPermissionSets != null) {
				for (PermissionSet ps : dPermissionSets) {
					pvObj.d.addSource(sourceMap.get(ps.Id));
				}
			}
			if (vPermissionSets != null) {
				for (PermissionSet ps : vPermissionSets) {
					pvObj.v.addSource(sourceMap.get(ps.Id));
				}
			}
			if (wPermissionSets != null) {
				for (PermissionSet ps : wPermissionSets) {
					pvObj.w.addSource(sourceMap.get(ps.Id));
				}
			}

			//UTIL.throwError('Test2: ' + permissions.get('FIELD_Account.Name_r'));

			for (PVField field : pvObj.fields) {
				Set<PermissionSet> frPermissionSets = permissions.get('FIELD_' + pvObj.name + '.' + field.name + '_r');
				Set<PermissionSet> fwPermissionSets = permissions.get('FIELD_' + pvObj.name + '.' + field.name + '_w');

				if (frPermissionSets != null) {
					for (PermissionSet ps : frPermissionSets) {

						field.r.addSource(sourceMap.get(ps.Id));
					}
				}

				if (fwPermissionSets != null) {
					for (PermissionSet ps : fwPermissionSets) {
						field.w.addSource(sourceMap.get(ps.Id));
					}
				}
			}
		}

		if (systemPermissions != null) {
			for (String key : permissions.keySet()) {
				if (key.contains('PERM_')) {
					PVPermission pvPerm = new PVPermission(key.substring(5));
					for (PermissionSet ps : permissions.get(key)) {
						pvPerm.value.addSource(sourceMap.get(ps.Id));
					}
					systemPermissions.put(pvPerm.name, pvPerm);
				}
			}
		}
	}

	private static Map<String, PVObject> buildBase(Set<String> buildObjects) {
		Map<String, PVObject> result = new Map<String, PVObject>();

		for (Schema.SObjectType sObjType : getSObjectTypes()) {
			Schema.DescribeSObjectResult dr = sObjType.getDescribe();
			if (buildObjects == null || buildObjects.contains(dr.getName())) {
				String type = 'Standard Object';
				if (dr.isCustom()) {
					type = 'Custom Object';
				}
				if (dr.isCustomSetting()) {
					type = 'Custom Setting';
				}

				PVObject pvObj = new PVObject(dr.getName(), dr.getLabel(), type);
				Map<String, Schema.SObjectField> fm = dr.fields.getMap();
				for (Schema.SObjectField sObjField : fm.values()) {
					Schema.DescribeFieldResult dfr = sObjField.getDescribe();
					pvObj.addField(new PVField(dfr.getName(), dfr.getLabel()));
				}
				pvObj.fields.sort();
				result.put(pvObj.name, pvObj);
			}
		}
		return result;
	}

	private static Set<Schema.SObjectType> getSObjectTypes() {
		Set<Schema.SObjectType> result = new Set<Schema.SObjectType>();
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for (Schema.SObjectType type : gd.values()) {
			result.add(type);
		}
		return result;
	}

	@RemoteAction
	public static PVObject getObject(String objectName, List<Id> selectedIds) {
		PVObject base = buildBase(new Set<String>{objectName}).get(objectName);

		Set<Id> permissionSetIds = new Set<Id>();
		for (Id selectedId : selectedIds) {
			if (GW_sObject.getobjectNameFromId(selectedId) == 'PermissionGroup__c') {
				for (PermissionSet ps : F_PermissionGroup.getApexPermissionGroupCache().get(selectedId).getEffectivePermissionSets()) {
					permissionSetIds.add(ps.id);
				}
			} else if (GW_sObject.getobjectNameFromId(selectedId) == 'PermissionSet') {
				permissionSetIds.add(selectedId);
			}
		}

		Map<String,Set<PermissionSet>> data = queryPermissionSets(permissionSetIds);
		Map<String, PVObject> queryMap = new Map<String, PVObject>();
		queryMap.put(objectName, base);
		applyResult(queryMap, null, data);
		return base;

	}
}