public without sharing class  PGC_CustomAttributes {
    public Map<String,List<CustomAttribute__c>> groupNameToCustomAttributeList {get;set;}
    public List<CustomAttribute__c> customAttributes {set;get;}
    public Map<Id,Object> valueMap { get; set; }
    public Map<Id,CustomAttributeDefinition__c> customAttributeDefinitionMap { get; set; }
	public Id currentObjId;
    
    public static final String DEFAULTGROUPNAME = 'Default';

    public PGC_CustomAttributes(){
		currentObjId = ApexPages.currentPage().getParameters().get('Id');

        this.customAttributes = GW_CustomAttribute.getListFromRelated(currentObjId);
        this.valueMap = new Map<Id,Object>();
        this.groupNameToCustomAttributeList = new Map<String,List<CustomAttribute__c>>();

        Set<Id> definitionIds = new Set<Id>();
        for (CustomAttribute__c attr : this.customAttributes) {
            Object val = GW_CustomAttribute.getValue(attr);
            if (val == null) {
                val = '';
            }
            this.valueMap.put(attr.Id, val);
            definitionIds.add(attr.CustomAttributeDefinition__c);
        }
        this.customAttributeDefinitionMap = new Map<Id,CustomAttributeDefinition__c>([SELECT Id, Name, Label__c, Object__c, RelationshipTarget__c, Group__c FROM CustomAttributeDefinition__c WHERE id IN :definitionIds]);
        // Sort attributes by groups
        for(CustomAttribute__c attr : this.customAttributes) {
            // Group doesnt have to be defined, so to avoid using "null" as key, use 'Default' instead
            String groupKey = customAttributeDefinitionMap.get(attr.CustomAttributeDefinition__c).Group__c == null ? PGC_CustomAttributes.DEFAULTGROUPNAME : customAttributeDefinitionMap.get(attr.CustomAttributeDefinition__c).Group__c;
            List<CustomAttribute__c> caList = groupNameToCustomAttributeList.get(groupKey);
            if(caList == null)
                caList = new List<CustomAttribute__c>();
            caList.add(attr);
            groupNameToCustomAttributeList.put(groupKey,caList);
        }
        UTIL.log('Group content: ' + groupNameToCustomAttributeList);
    }

////////////////////////////////////////////////////////
// Execution of validation and update of Account
///////////////////////////////////////////////////////

    public void save() {
        customAttributes = new List<CustomAttribute__c>();
        for(String groupKey : groupNameToCustomAttributeList.keySet()) {
            for (CustomAttribute__c attr : groupNameToCustomAttributeList.get(groupKey)) {
                if(attr.RelationshipId__c != null && (attr.RelationshipName__c == null || attr.RelationshipName__c == '')) {
                    GW_CustomAttribute.setValue(attr, null);
                } else {
                    GW_CustomAttribute.setValue(attr, this.valueMap.get(attr.Id));
                }
                customAttributes.add(attr);
            }
        }
        saveAttributes();
        triggerRelatedObjects();
    }

    public void triggerRelatedObjects() {
        String objectType = GW_sObject.getobjectNameFromId(currentObjId);
        try {
            update GW_sObject.queryRecord(objectType,currentObjId);
        } catch (Exception e) {
            UTIL.log('Exception in PGC_CustomAttributes: ' + e.getStackTraceString());
        }
    }

    public void saveAttributes() {
        try {
            update customAttributes;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Changes are succesfully saved!'));
        } catch (System.DmlException ex) {
            if (ex.getDmlType(0) != StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION ){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'An unexpected error occured, please contact your Administrator: '+ex.getMessage()));
            }
        }
    }
}