public class GW_CustomAttribute {

    private static final Schema.sObjectType GW_BASEOBJECT = CustomAttribute__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'CustomAttribute__c';
    private static final String DEFAULTFIELDSET = 'Default'; // default fieldset for this type
    public static Boolean syncToFiqas = true; // can be used to prevent syncing attrounts to Fiqas

////////////////////////////////////////////////////////
// Custom Attributes cached object map
////////////////////////////////////////////////////////
	public static Map<Id,Set<CustomAttribute__c>> objectCustomAttributesCache;

    public static void cacheCustomAttributes(List<sObject> parents) {
        cacheCustomAttributes(GW_sObject.getIdSet(parents));
    }

    public static void cacheCustomAttributes(Set<Id> parentIds) {
        if (objectCustomAttributesCache==null) objectCustomAttributesCache = new Map<Id,Set<CustomAttribute__c>>();

        // Currently working only for Accounts and Leads
        Set<Id> objIds = new Set<Id>();
        for(Id parentId : parentIds) {
            String sObjectName = GW_sObject.getobjectNameFromId(parentId);
            if(sObjectName == 'Account' || sObjectName == 'Lead') {
                objIds.add(parentId);
            }
        }

        if (!objIds.isEmpty()) {
            Map<id,CustomAttribute__c> attrMap = GW_CustomAttribute.getMapFromRelated(objIds);

            if (attrMap != null) {
                for (CustomAttribute__c a : attrMap.values() ) {
                    if ( !objectCustomAttributesCache.containsKey(a.ParentId__c) ) objectCustomAttributesCache.put(a.ParentId__c, new Set<CustomAttribute__c>() );
                    objectCustomAttributesCache.get(a.ParentId__c).add(a);
                }
            }
        }
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static CustomAttribute__c           getRecord(Id id)           { return (CustomAttribute__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,CustomAttribute__c>   getMap(Set<id> ids)        { return new Map<id,CustomAttribute__c>( getList(ids) ); }
    public static List<CustomAttribute__c>     getList(Set<id> ids)       { return (List<CustomAttribute__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }


//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of parents(base object) from a list of child objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // Account
    public static Map<id,CustomAttribute__c>  	getMapFromRelated(List<Account> soLst)      { return getMap(getIdSetFromRelated(GW_sObject.getIdSet(soLst) )); }
    public static Map<id,CustomAttribute__c>  	getMapFromRelated(Set<Id> parentIds)        { return getMap(getIdSetFromRelated( parentIds )); }
    public static List<CustomAttribute__c>   	getListFromRelated(Id parentId)  			{ return (List<CustomAttribute__c>) GW_sObject.getChildren(new Set<Id>{parentId}, 'Custom_Attributes__r', 'CustomAttributeDefinition__r.SortOrder__c ASC');}
    public static List<CustomAttribute__c>   	getListFromRelated(Set<Id> parentIds)  		{ return (List<CustomAttribute__c>) GW_sObject.getChildren(parentIds, 'Custom_Attributes__r', 'CustomAttributeDefinition__r.SortOrder__c ASC'); }
    public static Set<Id>       				getIdSetFromRelated(Set<Id> parentIds) 		{ return GW_sObject.getChildIds(parentIds, 'Custom_Attributes__r'); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of childs(base object) from a list of parent objects
//////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static CustomAttribute__c createSObject(String key) { return new CustomAttribute__c(Name=key); }

    public static CustomAttribute__c createSObject(String key, Object value) {
        CustomAttribute__c ca = new CustomAttribute__c(Name=key);

        If ((value instanceOf String) && (((String)value).length() < 256))  {
            ca.StringValue__c = (String) value;
        	ca.ValueType__c = 'STRING';
        }
        If ((value instanceOf String) && (((String)value).length() > 255))	{
            ca.LongTextValue__c = (String) value;
            ca.ValueType__c = 'LONGTEXT';
        }
        If (value instanceOf Decimal) {
            ca.NumberValue__c = (Decimal) value;
            ca.ValueType__c = 'NUMBER';
        }
        If (value instanceOf Datetime && !(value instanceOf Date)) { // A Date is also instance of Datetime, but not vice versa
            ca.DatetimeValue__c = (Datetime) value;
            ca.ValueType__c = 'DATETIME';
        }
        if (value instanceOf Date) {
            ca.DateValue__c = (Date) value;
            ca.ValueType__c = 'DATE';
        }

        If (value instanceOf Boolean){
            ca.BooleanValue__c = (Boolean) value;
            ca.ValueType__c = 'BOOLEAN';
        }

        return ca;
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// Custom logic
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static Object getValue(CustomAttribute__c attr) {
        If (attr.ValueType__c.toUpperCase() == 'STRING') 	{ return attr.StringValue__c; }
        If (attr.ValueType__c.toUpperCase() == 'LONGTEXT') 	{ return attr.LongTextValue__c; }
        If (attr.ValueType__c.toUpperCase() == 'CURRENCY' ) { return attr.CurrencyValue__c; }
        If (attr.ValueType__c.toUpperCase() == 'NUMBER' ) 	{ return attr.NumberValue__c; }
        If (attr.ValueType__c.toUpperCase() == 'DATETIME') 	{ return attr.DatetimeValue__c; }
        If (attr.ValueType__c.toUpperCase() == 'DATE') 		{ return attr.DateValue__c; }
        If (attr.ValueType__c.toUpperCase() == 'BOOLEAN') 	{ return attr.BooleanValue__c; }
        If (attr.ValueType__c.toUpperCase() == 'RELATIONSHIP') 	{ return attr.RelationshipId__c; }

        return null;
    }

    public static Boolean setValue(CustomAttribute__c attr, Object value) {
        try {
            If (attr.ValueType__c.toUpperCase() == 'STRING') 	{ attr.StringValue__c = String.valueOf(value); }
            If (attr.ValueType__c.toUpperCase() == 'LONGTEXT') 	{ attr.LongTextValue__c = String.valueOf(value); }
            If (attr.ValueType__c.toUpperCase() == 'CURRENCY' ) { attr.CurrencyValue__c = Decimal.valueOf(String.valueOf(value)).stripTrailingZeros(); }
            If (attr.ValueType__c.toUpperCase() == 'NUMBER' ) 	{ attr.NumberValue__c = String.valueOf(value) != '' ? Decimal.valueOf(String.valueOf(value)).stripTrailingZeros() : NULL; }
            If (attr.ValueType__c.toUpperCase() == 'DATETIME') 	{ attr.DatetimeValue__c = DateTime.valueOf(value); }
            If (attr.ValueType__c.toUpperCase() == 'DATE') 		{ attr.DateValue__c = Date.valueOf(value); }
            If (attr.ValueType__c.toUpperCase() == 'BOOLEAN') 	{ attr.BooleanValue__c = Boolean.valueOf(value); }
            If (attr.ValueType__c.toUpperCase() == 'RELATIONSHIP') { updateRelationshipField(attr,value); }
        } catch (Exception e) {
            return false;
        }
        return true;
    }

    public static Object getAPIValue(CustomAttribute__c attr) {
        if(attr.ValueType__c.toUpperCase() == 'RELATIONSHIP') {
            return getRelationshipForAPI(attr);
        } else if(attr.ValueType__c.toUpperCase() == 'BOOLEAN') {
            return new UTIL_Fieldmapper.mappedField('value', String.valueOf(getValue(attr)), 'String', 100, TRUE, TRUE);
        } else {
            return new UTIL_Fieldmapper.mappedField('value', getValue(attr) , attr.ValueType__c, 100, TRUE, TRUE);
        }
    }

    public static Object getRelationshipForAPI(CustomAttribute__c attr) {
        if(attr.RelationshipId__c != null && ((Id)attr.RelationshipId__c).getSObjectType().getDescribe().getName() == 'Account') {
            Account acc = (Account) UTIL.getCached(attr.RelationshipId__c);
            Account parent = (Account) UTIL.getCached(acc.ParentId);
            UTIL_Fieldmapper.MappedObject mappedObj = new UTIL_Fieldmapper.MappedObject('value');
            mappedObj.children = GW_Account.getAccountMapperFields(acc,parent);
            return mappedObj;
        } else {
            return new UTIL_Fieldmapper.mappedField('value', attr.RelationshipId__c, attr.ValueType__c, 100, TRUE, TRUE);
        }
    }

    private static void updateRelationshipField(CustomAttribute__c attr, Object value) {
        // If the incoming value is null, nullify the fields
        if(value == null || (String.valueOf(value) == '')) {
            attr.RelationshipId__c = null;
            attr.RelationshipName__c = null;
            return;
        }
        // Validate ID and if object type corresponds with definition
        Id incomingId = String.valueOf(value);
        CustomAttributeDefinition__c cad = (CustomAttributeDefinition__c) UTIL.getCached(attr.CustomAttributeDefinition__c);
        String objectAPIName = incomingId.getSObjectType().getDescribe().getName();
        // Invalid ID for target object set up in definition
        if(objectAPIName != cad.RelationshipTarget__c)
            throw new UTIL.CustomException();

        // Update the relationship name
        String relName = (String) (UTIL.getCached(incomingId)).get('Name');
        attr.RelationshipId__c = incomingId;
        attr.RelationshipName__c = relName;
    }

    private static Map<Id, Set<Id>> fillMemberUnitIds(Set<Id> objectIds, String objectName) {
        Map<Id, Set<Id>> memberUnitIds = new Map<Id, Set<Id>>();
        if(objectName == 'Account') {
            Map<Id, List<AccountMemberUnitAssociation__c>> associationsPerAccount = GW_AccountMemberUnitAssociation.getAll(objectIds);
            for (Id accountId : associationsPerAccount.keySet()) {
                List<AccountMemberUnitAssociation__c> associations = associationsPerAccount.get(accountId);
                for (AccountMemberUnitAssociation__c association : associations) {
                    if (!memberUnitIds.containsKey(accountId)) {
                        memberUnitIds.put(accountId, new Set<Id>());
                    }
                    memberUnitIds.get(accountId).add(association.MemberUnit__c);
                }
            }
        } else {
            List<sObject> objList = GW_sObject.queryRecords(objectName, objectIds);
            for (sObject sobj : objList) {
                if (GW_sObject.fieldExists(objectName,'MemberUnit__c')) {
                    Id sObjId = (Id) sobj.get('Id');
                    if (!memberUnitIds.containsKey(sObjId)) {
                        memberUnitIds.put(sObjId, new Set<Id>());
                    }
                    memberUnitIds.get(sObjId).add((Id) sObj.get('MemberUnit__c'));
                }
            }
        }
        return memberUnitIds;
    }

    private static void validateCustomAttribute(CustomAttributeDefinition__c def, Map<String, CustomAttribute__c> existingAttributes, String objectName, Id parentObjectId, Id memberUnitId, List<CustomAttribute__c> customAttributesToInsert) {
        Boolean create = false;
        if (existingAttributes == null) {
            create = true;
        } else {
            String attributeKey = def.MemberUnit__r.MemberUnitId__c + '_' + def.AttributeKey__c;
            if (existingAttributes.get(attributeKey) == null && def.AutoCreate__c == true) {
                create = true;
            }
        }
        if (create == true) {
            CustomAttribute__c ca = new CustomAttribute__c(
                Name = def.AttributeKey__c,
                MemberUnit__c = memberUnitId,
                ValueType__c = def.AttributeType__c,
                CustomAttributeDefinition__c = def.Id,
                ParentId__c = parentObjectId,
                Record_UniqueKey__c = parentObjectId + '_' + def.AttributeKey__c,
                BooleanValue__c = def.DefaultBooleanValue__c,
                CurrencyValue__c = def.DefaultCurrencyValue__c,
                DateTimeValue__c = def.DefaultDateTimeValue__c,
                DateValue__c = def.DefaultDateValue__c,
                LongTextValue__c = def.DefaultLongTextValue__c,
                NumberValue__c = def.DefaultNumberValue__c,
                StringValue__c = def.DefaultStringValue__c
            );
            if (def.PrefillConfiguration__c != null) {
                try {
                    List<String> splits = def.PrefillConfiguration__c.split('_');
                    if (splits.size() == 2) {
                        Integer length = Integer.valueOf(splits.get(0));
                        String chars = splits[1];
                        String result = '';
                        for (Integer i = 0; i < length; i++) {
                            Integer chosenChar = Integer.valueOf(Math.random() * chars.length());
                            String randomChar = chars.substring(chosenChar, chosenChar+1);
                            result += randomChar;
                        }
                        ca.StringValue__c = result;
                    }
                } catch (Exception e) {
                    UTIL.log('Failure during ensuring custom attributes key creation');
                }
            }
            // UTIL.Log('GW_sobject.getSObjectType(objectId): ' + GW_sobject.getSObjectType(parentObjectId)); <-- this can be null unfortunately
            if(objectName == 'Account') {
                ca.Account__c = parentObjectId;
            } else if(objectName == 'Lead') {
                ca.Lead__c = parentObjectId;
            }
            customAttributesToInsert.add(ca);
        }
    }

    public static void ensureCustomAttributeDefinitions(Set<Id> objectIds, String objectName) {
        Map<Id, Set<Id>> sObjMemberUnitIds = GW_CustomAttribute.fillMemberUnitIds(objectIds, objectName);
        Set<Id> memberUnitIdsOverall = new Set<Id>();
        for (Id objId : sObjMemberUnitIds.keySet()) {
            memberUnitIdsOverall.addAll(sObjMemberUnitIds.get(objId));
        }
        Map<Id, CustomAttributeDefinition__c> customAttributeDefinitions = getCustomAttributeDefinitionsBy(memberUnitIdsOverall, objectName);
        if (customAttributeDefinitions.size() == 0) { return; }

        Map<Id, Map<String, CustomAttribute__c>> existingCustomAttributeMap = buildSObjectExistingCustomAttributeMap(objectIds);
        Map<Id, List<CustomAttributeDefinition__c>> memberUnitToCustomAttributeDefinitions = buildMemberUnitToCustomAttributeDefinitionMap(customAttributeDefinitions);
        List<CustomAttribute__c> customAttributesToInsert = new List<CustomAttribute__c>();

        // For each object ID incoming
        for (Id objId : objectIds) {
			if (!sObjMemberUnitIds.containsKey(objId)) { continue; }
			
            for (Id memberUnitId : sObjMemberUnitIds.get(objId)) {
                List<CustomAttributeDefinition__c> defs = memberUnitToCustomAttributeDefinitions.get(memberUnitId);
                if (defs == null) {
                    continue;
                }
                for (CustomAttributeDefinition__c def : defs) {
                    validateCustomAttribute(def, existingCustomAttributeMap.get(objId), objectName, objId, memberUnitId, customAttributesToInsert);
                }
            }
        }
        if (customAttributesToInsert.size() > 0) {
            Savepoint sp = Database.setSavepoint();
        	try {
        		insert customAttributesToInsert;
        	} catch (Exception ex) {
        		Database.rollback(sp);
                UTIL.throwError('Failed to insert custom attributes.', ex);
            }
        }
    }

    private static Map<Id, CustomAttributeDefinition__c> getCustomAttributeDefinitionsBy(Set<Id> memberUnitIds, String objectName) {
        return new Map<Id, CustomAttributeDefinition__c>([
            SELECT Id, Name, MemberUnit__c, MemberUnit__r.MemberUnitId__c, AttributeKey__c,
                AttributeType__c, Object__c, Mandatory__c, AutoCreate__c, PrefillConfiguration__c,
                Unique__c, ValidationRegEx__c, DefaultBooleanValue__c, DefaultCurrencyValue__c, DefaultDateTimeValue__c,
                DefaultDateValue__c, DefaultLongTextValue__c, DefaultNumberValue__c, DefaultStringValue__c
            FROM CustomAttributeDefinition__c
            WHERE MemberUnit__c IN :memberUnitIds AND Object__c = :objectName
        ]);
    }

    private static Map<Id, List<CustomAttributeDefinition__c>> buildMemberUnitToCustomAttributeDefinitionMap(Map<Id, CustomAttributeDefinition__c> customAttributeDefinitions) {
        Map<Id, List<CustomAttributeDefinition__c>> resultMap = new Map<Id,List<CustomAttributeDefinition__c>>();
        for (CustomAttributeDefinition__c def : customAttributeDefinitions.values()) {
            if (!resultMap.containsKey(def.MemberUnit__c)) {
                resultMap.put(def.MemberUnit__c, new List<CustomAttributeDefinition__c>());
            }
            resultMap.get(def.MemberUnit__c).add(def);
        }
        return resultMap;
    }

    private static Map<Id, Map<String, CustomAttribute__c>> buildSObjectExistingCustomAttributeMap(Set<Id> objectIds) {
        Map<Id, Map<String, CustomAttribute__c>> resultMap = new Map<Id, Map<String,CustomAttribute__c>>(); // map objectId to Map<UniqueKey,CustomAttribute>
        List<CustomAttribute__c> existingCustomAttributeList = [SELECT Id, ParentId__c, UniqueKey__c FROM CustomAttribute__c WHERE ParentId__c IN :objectIds];

        for (CustomAttribute__c attr : existingCustomAttributeList) {
            if (!resultMap.containsKey(attr.ParentId__c)) {
                resultMap.put(attr.ParentId__c, new Map<String, CustomAttribute__c>());
            }
            resultMap.get(attr.ParentId__c).put(attr.Uniquekey__c, attr);
        }
        return resultMap;
    }

    public static Map<Id,Map<String,String>> validateCustomAttributes(Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        Map<Id,Map<String,String>> resultsForIdMap = new Map<Id,Map<String,String>>();
        try {
            Set<Id> keySet = newMap.keyset();
            Map<Id, String> validationResults = GW_CustomAttribute.validateCustomAttributes(keySet);
            for (Id objId : validationResults.keySet()) {
                String result = validationResults.get(objId);
                Map<String,String> resMap = resultsForIdMap.get(objId);
                if(resMap == null) {
                    resMap = new Map<String,String>();
                }
                if (result == '' || result == null) {
                    resMap.put('MandatoryDetailsError__c',null);
                    resMap.put('MandatoryDetailsFilled__c','TRUE');
                } else {
                    resMap.put('MandatoryDetailsError__c',result);
                    resMap.put('MandatoryDetailsFilled__c','FALSE');
                }
                resultsForIdMap.put(objId,resMap);
            }
        } catch (Exception e) {
            UTIL.throwError('validateCustomAttributes Exception Thrown: ', e);
        }

        return resultsForIdMap;
    }

    public static Map<Id,String> validateCustomAttributes(Set<Id> objectIds) {
        Map<Id,String> resultMap = new Map<Id,String>();
        //Initialize resultMap so that MandatoryDetailsFilled__c sets to TRUE if 
        //there are no existing CustomAttributes   
        for(Id objId : objectIds){
            resultMap.put(objId, '');
        }
        Map<Id, List<CustomAttribute__c>> existingCustomAttributeMap = new Map<Id, List<CustomAttribute__c>>(); // Map object Id to custom attributs list
        List<CustomAttribute__c> existingCustomAttributeList = [SELECT Id, Account__c, UniqueKey__c, CustomAttributeDefinition__c, CustomAttributeDefinition__r.Label__c, CustomAttributeDefinition__r.Mandatory__c, ValueType__c, BooleanValue__c, CurrencyValue__c, DateTimeValue__c, DateValue__c, LongTextValue__c, NumberValue__c, StringValue__c, ParentId__c, RelationshipName__c, RelationshipId__c FROM CustomAttribute__c WHERE ParentId__c IN :objectIds];
        for (CustomAttribute__c attr : existingCustomAttributeList) {
            if (!existingCustomAttributeMap.containsKey(attr.ParentId__c)) {
                existingCustomAttributeMap.put(attr.ParentId__c, new List<CustomAttribute__c>());
            }
            existingCustomAttributeMap.get(attr.ParentId__c).add(attr);
        }
        for (Id objId : existingCustomAttributeMap.keySet()) {
            List<String> errors = new List<String>();
            List<CustomAttribute__c> attributes = existingCustomAttributeMap.get(objId);
            for (CustomAttribute__c attr : attributes) {
                if (attr.CustomAttributeDefinition__r.Mandatory__c == true && (GW_CustomAttribute.getValue(attr) == null || GW_CustomAttribute.getValue(attr) == '')) {
                    errors.add('Missing required field "' + attr.CustomAttributeDefinition__r.Label__c + '"');
                }
            }
            if (errors.size() > 0) {
                resultMap.put(objId, String.join(errors, ','));
            } else {
                resultMap.put(objId, '');
            }
        }
        return resultMap;
    }

    public static void convertCustomAttributes(Map<Id,Id> caMapping){
        Set<Id> allIds = new Set<Id>(caMapping.keySet());
        allIds.addAll(caMapping.values());
        Set<Id> masterParents = new Set<Id>(caMapping.keySet());
        Set<Id> inheritParents = new Set<Id>(caMapping.Values());

        List<CustomAttribute__c> allAttributes = (List<CustomAttribute__c>) GW_sObject.queryRecords('CustomAttribute__c', 'ParentId__c IN: idSet1', new Map<String, Set<id>>{'idSet1' => allIds} );
 		List<CustomAttribute__c> masterAttributes = new List<CustomAttribute__c>();
        List<CustomAttribute__c> inheritAttributes = new List<CustomAttribute__c>();

        for (CustomAttribute__c ca: allAttributes) {
            if (masterParents.contains(ca.parentId__c)) {
                masterAttributes.add(ca);
            }
            if (inheritParents.contains(ca.parentId__c)) {
                inheritAttributes.add(ca);
            }
        }

        List<CustomAttribute__c> updateList = new List<CustomAttribute__c>();

        for (CustomAttribute__c master: masterAttributes) {
			for (CustomAttribute__c inherited: inheritAttributes) {
                if (master.name == inherited.name && caMapping.get(master.ParentId__c) == inherited.ParentId__c) {
                    inherited.StringValue__c = master.StringValue__c;
                    inherited.BooleanValue__c = master.BooleanValue__c;
                    inherited.CurrencyValue__c = master.CurrencyValue__c;
                    inherited.DateTimeValue__c = master.DateTimeValue__c;
                    inherited.DateValue__c = master.DateValue__c;
                    inherited.LongTextValue__c = master.LongTextValue__c;
                    inherited.NumberValue__c = master.NumberValue__c;
                    updateList.add(inherited);
                }
            }
        }
        update updateList;
    }
}