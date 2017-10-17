public class HNDL_CustomAttribute extends TriggerManager.TriggerHandler {

    public override void bulkBefore(List <SObject> soLst, Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        // Cache Custom Attributes
        UTIL.cache(soLst);
        // Get custom attributes definition and cache those too
        Set<Id> customAttributeDefIdSet = new Set<Id>();
        for(sObject so : soLst) {
            customAttributeDefIdSet.add((Id) so.get('CustomAttributeDefinition__c'));
        }
        UTIL.cacheUncachedRecords(customAttributeDefIdSet);
        validateAttributes(oldMap,newMap);
    }

    public override void beforeInsert(SObject so) {
    	CustomAttribute__c attr = (CustomAttribute__c)so;
        String valDefMatch = validateDefinitionMatching(attr,null);
        if(valDefMatch != null) {
            attr.addError(valDefMatch);
        }
        updateFields(attr);
    }

    public override void beforeUpdate(SObject oldSo, SObject so) {
        CustomAttribute__c attr = (CustomAttribute__c)so;
        CustomAttribute__c oldattr = (CustomAttribute__c)oldSo;
        updateFields(attr);
    }

    public override void beforeDelete(SObject so) {}

    public override void afterInsert(SObject so) {}
    public override void andFinally() {}

//////////////////////////////
// private helper methods
//////////////////////////////

    private void updateFields(CustomAttribute__c ca) {
        // Fill the parentId field value
        if(ca.ParentId__c == null) {
            if(ca.Lead__c != null) {
                ca.ParentId__c = ca.Lead__c;
            }
            else if(ca.Account__c != null) {
                ca.ParentId__c = ca.Account__c;
            }
            else {
                ca.addError('Impossible to fill Parent Id, please ensure that lookup relation is set up correctly!');
            }
        }
    }

    private void validateAttributes(Map<Id,sObject> oldMap, Map<Id,sObject> newMap) {
        Set<Id> defIds = new Set<Id>();
        if (newMap != null) {
            for (sObject sobj: newMap.values()) {
                CustomAttribute__c attr = (CustomAttribute__c) sobj;
                defIds.add(attr.CustomAttributeDefinition__c);
            }
            Map<Id, CustomAttributeDefinition__c> defMap = new Map<Id, CustomAttributeDefinition__c>([SELECT Id, Unique__c, ValidationRegEx__c, Object__c, AttributeType__c, RelationshipTarget__c FROM CustomAttributeDefinition__c WHERE Id IN :defIds]);
            for (CustomAttribute__c attr: (List<CustomAttribute__c>) newMap.values()) {
                Object val = GW_CustomAttribute.getValue(attr);
                CustomAttributeDefinition__c currCAD = defMap.get(attr.CustomAttributeDefinition__c);
                // Unique key validation
                if (currCAD.Unique__c && val != null) {
                    attr.Uniqueness__c = attr.MemberUnit__c + '_' + attr.Name + '_' + String.valueOf(val);
                } else {
                    attr.Uniqueness__c = null;
                }
                // Validation regex check
                if (currCAD.ValidationRegEx__c != null && val != null) {
                    Boolean regexMatch = Pattern.matches(currCAD.ValidationRegEx__c, String.valueOf(val));
                    if (regexMatch == false) {
                        attr.addError('Validation of key:' + attr.name + ' with value: ' + val + ' failed with REGEX: ' + currCAD.ValidationRegEx__c);
                    }
                }
                // Object matching check
                String valDefMatch = validateDefinitionMatching(attr,currCAD);
                if(valDefMatch != null) {
                    attr.addError(valDefMatch);
                }
                // Clean the name if the ID is null
                if(attr.RelationshipId__c == NULL && ((CustomAttribute__c)oldMap.get(attr.Id)).RelationshipId__c != NULL) {
                    attr.RelationshipName__c = NULL;
                }
                // Relationship field validation
                if(currCAD.AttributeType__c.toUpperCase() == 'RELATIONSHIP') {
                    if(attr.RelationshipId__c == NULL && (attr.RelationshipName__c != NULL || attr.RelationshipName__c != '')) {
                        attr.RelationshipName__c = NULL;
                    }
                }
            }
        }
    }

    private String validateDefinitionMatching(CustomAttribute__c ca, CustomAttributeDefinition__c cad) {
        if(cad == null) {
            cad = (CustomAttributeDefinition__c) UTIL.getCached(ca.CustomAttributeDefinition__c);
            if(cad == null) {
                cad = (CustomAttributeDefinition__c) GW_sObject.queryRecord('CustomAttributeDefinition__c', ca.CustomAttributeDefinition__c);
            }
        }
        if(cad == null)
            return 'There is no Custom Attribute Definition defined for this Custom Attribute, please check.';
        if(ca.Lead__c != null && cad.Object__c != 'Lead') {
            return ('Attribute has relation to Lead but chosen Custom Attribute Definition points to: ' + cad.Object__c);
        }
        if(ca.Account__c != null && cad.Object__c != 'Account') {
            return ('Attribute has relation to Account but chosen Custom Attribute Definition points to: ' + cad.Object__c);
        }

        return null;
    }

    // Constructor
    public HNDL_CustomAttribute() { super('HNDL_CustomAttribute', CustomAttribute__c.sObjectType); }
}