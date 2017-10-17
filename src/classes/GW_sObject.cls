public with sharing class GW_sObject {

    public static Map<String, Schema.SObjectType> globalDescMap { get { if ( globalDescMap == null ) globalDescMap = Schema.getGlobalDescribe(); return globalDescMap;  }}

    static Map<String, String> mapFieldType = new Map<String, String>();
    static Map<String, String> mapFieldLabel = new Map<String, String>();
    static Map<String, Schema.DescribeFieldResult> mapFieldResult = new Map<String, Schema.DescribeFieldResult>();

    ////////////////////////////
    // General record Queries
    ////////////////////////////

	/**
    *   @Author                     : GIS Dev
    *   @Created Date               : Aug/10/2017
    *   @param (sObjectType)        : type String define sObject API name
    *   @param (whereClause)        : type String define custom where cluase for query condition
    *   @param (additionalFields)   : type List<String> define additional fields to query statement
    *   @param (queryPostfix)       : type String define postfix @Ex(FOR UPDATE, LIMIT,) to query statement
    *   @param (excludedFields)     : type Set<String> define some field name to exclude from query statement
    *   @Description                : this method use to query record from Sobject by custom where cluase, but exclude some fields that contain in @param (excludedFields)
    */
    public static List<sObject> queryRecords(String sObjectType, String whereClause, List<String> additionalFields, String queryPostfix, Set<String> excludedFields) {
        
        additionalFields = additionalFields == null ? new List<String>() : additionalFields;
        excludedFields = excludedFields == null ? new Set<String>() : excludedFields;
        
        // get all field from sObject and threw each field that contain in excludedFields
        Set<String> allFields = new Set<String>(getAllSObjectFieldNames(sObjectType));
        for(String f : allFields) {
            for(String x : excludedFields) {
                if(f.equalsIgnoreCase(x)) allFields.remove(f);
            }
        }
        
        List<String> lstFields = new List<String>(allFields);
        // add more additional fields
        lstFields.addAll(additionalFields);

        String query = getQueryBasePart(sObjectType, lstFields, null, null);
        query +=  getWhereClause( sObjectType, whereClause);

        if (queryPostfix != null) query+= ' ' + queryPostfix;

        try {
            return Database.query(query);
        } catch (Exception e) { 
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(String sObjectType, String whereClause, List<String> additionalFields, String queryPostfix, Set<String> excludedFields): ' + e.getMessage() + '[' + query + ']');
        }
    }

    /**
    *   @Author                     : GIS Dev
    *   @Created Date               : Aug/10/2017
    *   @param (sObjectType)        : type String define sObject API name
    *   @param (soIds)              : type Set<ID> define collection of Id for query condition
    *   @param (additionalFields)   : type List<String> define additional fields to query statement
    *   @param (queryPostfix)       : type String define postfix @Ex(FOR UPDATE, LIMIT,) to query statement
    *   @param (excludedFields)     : type Set<String> define some field name to exclude from query statement
    *   @Description                : this method use to query record from Sobject by collection of Id, but exclude some fields that contain in @param (excludedFields)
    */
    public static List<sObject> queryRecords(String sObjectType, Set<Id> soIds, List<String> additionalFields, String queryPostfix, Set<String> excludedFields) {
        
        if (soIds == null)
            return new List<sObject>();

        additionalFields = additionalFields == null ? new List<String>() : additionalFields;
        excludedFields = excludedFields == null ? new Set<String>() : excludedFields;
        
        // get all field from sObject and threw each field that contain in excludedFields
        Set<String> allFields = new Set<String>(getAllSObjectFieldNames(sObjectType));
        for(String f : allFields) {
            for(String x : excludedFields) {
                if(f.equalsIgnoreCase(x)) allFields.remove(f);
            }
        }

        // case set of allFields to list of fields
        List<String> fields = new List<String>(allFields);
            // add more additional fields
            fields.addAll(additionalFields);

        String query = getQueryBasePart(sObjectType, fields);
            query +=  getWhereClause( sObjectType, 'id IN :soIds' );

        if (queryPostfix != null)
            query += ' ' + queryPostfix;

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(String sObjectType, Set<Id> soIds, List<String> additionalFields): ' + e.getMessage());
        }
    }

    /**
    *   @Author                         : GIS Dev
    *   @Created Date                   : Aug/10/2017
    *   @param (parentIds)              : type Set<ID> define collection of Parent'sId for query condition
    *   @param (childRelationshipName)  : type String define child relationship name in Parent sObject
    *   @param (orderBy)                : type String define orderBy
    *   @param (childrenWhereClause)    : type String define custom where cluase for child query statement
    *   @param (excludedFields)         : type Set<String> define some field name to exclude from query statement
    *   @Description                    : this method use to query record with parent -< childs from Sobject by collection of Id, but exclude some fields that contain in @param (excludedFields)
    */
    public static List<sObject> getChildren (Set<Id> parentIds, String childRelationshipName, String orderBy, String childrenWhereClause, Set<String> excludedFields) {
        
        if (parentIds == null || parentIds.isEmpty())
            return null;
        
        String parentType;
        Schema.SObjectType parentSOType;
        Schema.SObjectType childSOType;

        for (ID id : parentIds) {
            parentSOType = Id.getSObjectType();
            break;
        }

        parentType = parentSOType.getDescribe().getName();

        List<Schema.ChildRelationship> lstchildrelationships = parentSOType.getDescribe().getChildRelationships();

        for (Schema.ChildRelationship rel : lstchildrelationships) {
            if (rel.getrelationshipname() == childRelationshipName)
                childSOType = rel.getChildSObject();
        }

        if (childSOType == null )
            throw new GW_sObjectException('Exception in GW_sObject: getChildIds(): childRelationshipName not found: '+childRelationshipName);

        List<sObject> children = new List<sObject>();
        List<sObject> parents  = new List<sObject>();
        String query;

        try {

            excludedFields = excludedFields == null ? new Set<String>() : excludedFields;

            // get all field from child sObject and threw each field that contain in excludedFields
            Set<String> allFields = new Set<String>(getAllSObjectFieldNames(childSOType.getDescribe().getName()));
            for(String f : allFields) {
                for(String x : excludedFields) {
                    if(f.equalsIgnoreCase(x)) allFields.remove(f);
                }
            }
            
            List<String> fields = new List<String>(allFields);

            String subQuery = getQueryBasePart(childRelationshipName, fields, orderBy, childrenWhereClause);

            query = 'SELECT Id, (' + subQuery + ') FROM ' + parentType + ' WHERE Id IN :parentIds';

            List<sObject> queryResultList = Database.query(query);

            for (sObject so : queryResultList) {
                List<sObject> soList = so.getSObjects(childRelationshipName);
                if (soList != null && soList.size() > 0 )
                    children.addAll(soList );
            }
        } catch (Exception e) {
            UTIL.log('Query: '+query);
            throw new GW_sObjectException('Exception in GW_sObject: getChildren() for relationship '+childRelationshipName +' '+parentIds+': '+e.getMessage());
        }
        return children;
    }
	
    public static List<sObject> queryRecords(String sObjectType, Set<Id> soIds) {
        return queryRecords(sObjectType, soIds, new List<String>());
    }

    public static List<sObject> queryRecords(String sObjectType, Set<Id> soIds, List<String> additionalFields) {
        return queryRecords(sObjectType, soIds, additionalFields, null);
    }

    public static List<sObject> queryRecords(String sObjectType, Set<Id> soIds, List<String> additionalFields, String queryPostfix) {
        if (soIds == null) return new List<sObject>();
        List<String> fields = getAllSObjectFieldNames(sObjectType);
        additionalFields = additionalFields == null ? new List<String>() : additionalFields;
        fields.addAll(additionalFields);
        String query = getQueryBasePart(sObjectType, fields);
        query +=  getWhereClause( sObjectType, 'id IN :soIds' );
        if (queryPostfix != null) query += ' ' + queryPostfix;

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(String sObjectType, Set<Id> soIds, List<String> additionalFields): ' + e.getMessage());
        }
    }

    public static List<sObject> queryRecordsForUpdate(String sObjectType, Set<Id> soIds, List<String> additionalFields) {
        return queryRecords(sObjectType, soIds, additionalFields, 'FOR UPDATE');
    }

    // using specified list of fields
    public static List<sObject> queryRecords(String sObjectType, List<String> fields, Set<Id> soIds) {
        if (soIds == null || soIds.isEmpty() || String.isBlank(sObjectType) || fields.isEmpty() ) return null;
        String query = getQueryBasePart(sObjectType, fields);
        query += getWhereClause( sObjectType, 'id IN :soIds');
        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }

//  // using specified list of fields based on lookup/master-detail Ids
    public static List<sObject> queryRecords(String sObjectType, List<String> fields, String idField, Set<Id> soIds) {
        if (soIds == null || soIds.isEmpty() || String.isBlank(sObjectType) || fields.isEmpty() ) return null;
        String query = getQueryBasePart(sObjectType, fields);

        //Let an exception be trown when the idField does not exist on the object
        getFieldDescribe(sObjectType, idField);

        query += getWhereClause( sObjectType, idField+' IN :soIds');
        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }

	// 21 July 2017 : using specified list of fields based on lookup/master-detail Ids
    public static List<sObject> queryRecordsForUpdate (String sObjectType, List<String> fields, String idField, Set<Id> soIds) {
        if (soIds == null || soIds.isEmpty() || String.isBlank(sObjectType) || fields.isEmpty() ) return null;
        String query = getQueryBasePart(sObjectType, fields);

        //Let an exception be trown when the idField does not exist on the object
        getFieldDescribe(sObjectType, idField);

        query += getWhereClause( sObjectType, idField+' IN :soIds') + ' FOR UPDATE';

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }
	
    // custom whereclause
    public static List<sObject> queryRecords(string sObjectType, string whereClause) {
        return queryRecords(sObjectType, whereClause, new List<String>());
    }

    public static List<sObject> queryRecords(String sObjectType, String whereClause, List<String> additionalFields) {
        return queryRecords(sObjectType, whereClause, additionalFields, null);
    }

    public static List<sObject> queryRecordsForUpdate(String sObjectType, String whereClause) {
        return queryRecords(sObjectType, whereClause, new List<String>(), 'FOR UPDATE');
    }

    public static List<sObject> queryRecords(String sObjectType, String whereClause, List<String> additionalFields, String queryPostfix) {
        List<String> fields = getAllSObjectFieldNames(sObjectType);
        additionalFields = additionalFields == null ? new List<String>() : additionalFields;
        fields.addAll(additionalFields);
        String query = getQueryBasePart(sObjectType, fields);
        query +=  getWhereClause( sObjectType, whereClause);
        if (queryPostfix != null) query+= ' ' + queryPostfix;

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(String sObjectType, String whereClause, List<String> additionalFields): ' + e.getMessage() + '[' + query + ']');
        }
    }

    // custom whereclause AND Idset
    public static List<sObject> queryRecords(string sObjectType, string whereClause, Set<Id> soIds) {
        String query = getQueryBasePart(sObjectType, null);
        query +=  getWhereClause( sObjectType, whereClause + ' AND id IN :soIds');

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }

    public static List<sObject> queryRecords(String sObjectType, String inFieldName, Set<String> soNames) {
        String query = getQueryBasePart(sObjectType, null);
           query += getWhereClause(sObjectType, inFieldName + ' IN :soNames');

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }

    // To query using lookup related field and providing set of ids for that field, e.g.
    // GW_sObject.queryRecords('RS__c','Opportunity__c',oppMap.keySet()) will get all RS related to this set of Opportunity ids
    public static List<sObject> queryRecords(String sObjectType, Set<Id> soIds, String inFieldName) {
        String query = getQueryBasePart(sObjectType, null);
        query += getWhereClause(sObjectType, inFieldName + ' IN :soIds');

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }
    
    public static List<sObject> queryRecords(String sObjectType, List<String> additionalFields, String whereClause, Set<String> param1, Set<String> param2, String queryPostfix){
        List<String> objFields = getAllSObjectFieldNames(sObjectType);
        additionalFields = additionalFields == null ? new List<String>() : additionalFields;
        objFields.addAll(additionalFields);
        String query = getQueryBasePart(sObjectType, objFields) + ' ' + whereClause;
        if (queryPostfix != null) query += ' ' + queryPostfix;
        try {
            //return Database.query(query); 
            /* to fix Query of LOB fields Exception heap usage to exceed limit */
            List<sObject> queryList = new List<sObject>();
            for(sObject obj : Database.query(query)){
                queryList.add(obj);
            }
            return queryList;
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }
     
    //custom whereclause with Idset
    //Needs to be upgraded:
    //1- The set should be called from idMap. Instead of idSet1 till idSet3
    //2- The idMap should be able to contain everytype objecttype instead of only id's
    public static List<sObject> queryRecords(string sObjectType, string whereClause, Map<string, Set<id>> idMap ){
        Set<id> idSet1 = idMap.get('idSet1');
        Set<id> idSet2 = idMap.get('idSet2');
        Set<id> idSet3 = idMap.get('idSet3');

        String query = getQueryBasePart(sObjectType, null);
        query +=  getWhereClause( sObjectType, whereClause);

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }
    
    public static List<sObject> queryRecords(string sObjectType, string whereClause, Map<string, Set<String>> stringMap ){
        Set<String> stringSet1 = stringMap.get('stringSet1');
        Set<String> stringSet2 = stringMap.get('stringSet2');
        Set<String> stringSet3 = stringMap.get('stringSet3');

        String query = getQueryBasePart(sObjectType, null);
        query +=  getWhereClause( sObjectType, whereClause);

      	try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }

    // all options
    public static List<sObject> queryRecords(String sObjectType, List<String> objFields, String whereClause) {
        String query = getQueryBasePart(sObjectType, objFields);
        query +=  getWhereClause( sObjectType, whereClause);

        try {
            return Database.query(query);
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: queryRecords(): ' + e.getMessage());
        }
    }

    // query single record
    public static sObject queryRecord(String sObjectType, Id soId) {
        Set<Id> soIds = new Set<Id> {soId};
        List<sObject> soList = queryRecords(sObjectType, soIds);
        if (soList == null || soList.isEmpty() ) return null;
        return soList[0];
    }

    public static sObject queryRecordForUpdate(String sObjectType, Id soId) {
        Set<Id> soIds = new Set<Id> {soId};
        List<sObject> soList = queryRecordsForUpdate(sObjectType, soIds, new List<String>());
        if (soList == null || soList.isEmpty() ) return null;
        return soList[0];
    }

    public static sObject queryRecord(String sObjectType, Id soId, List<String> additionalFields) {
        Set<Id> soIds = new Set<Id> {soId};
        List<sObject> soList = queryRecords(sObjectType, soIds, additionalFields);
        if (soList == null || soList.isEmpty() ) return null;
        return soList[0];
    }

    public static sObject queryRecord(String sObjectType, List<String> fields, Id soId) {
        Set<Id> soIds = new Set<Id> {soId};
        List<sObject> soList = queryRecords(sObjectType, fields, soIds);
        if (soList == null || soList.isEmpty() ) return null;
        return soList[0];
    }

    // check if object is of certain type
    public static Boolean isObjectType(Id id, Schema.sObjectType sObjectType) {
        if (id == null) {
            throw new GW_sObjectException('Exception in GW_sObject: isObjectType() - Invalid Id.');
        }
        return (id.getsObjectType() == sObjectType);
    }

    // get objectName from an sObject ID
    public static string getobjectNameFromId(Id soId) {
        if (soId == null) return null;
        try {
            return soId.getSObjectType().getDescribe().getName();
        } catch (Exception e) {
            throw new GW_sObjectException('Exception in GW_sObject: getobjectNameFromId() - Invalid Id:'+soId+' - ' + e.getMessage());
        }
    }

    // convert a List to Set of Id
    public static Set<Id> getIdSet(List<sObject> soList) {
        if (soList == null || soList.isEmpty() ) return null;
        Map<Id, sObject> soMap = new Map<Id, sObject>(soList);
        return soMap.keySet();
    }

    // return a set of parent Ids
    public static Set<Id> getParentIds(List<sObject> childList, String parentIdField) {
        Set<Id> parentIds = new Set<Id>();
        if (childList==null) return new Set<Id>();
        for (sObject so : childList) {
            if (parentIdField != null && so.get(parentIdField) != null)
                parentIds.add((Id) so.get(parentIdField));
        }
        return parentIds;
    }

    // return a set of child Ids - Expecting the set to contain Id's of the same type
    public static Set<Id> getChildIds(Set<Id> parentIds, String childRelationshipName) {
        return getChildIds(parentIds, childRelationshipName, null);
    }

    // return a set of childs Ids with a where clase - Expecting the set to contain Id's of the same type
    public static Set<Id> getChildIds(Set<Id> parentIds, String childRelationshipName, String whereClause) {
        if (parentIds == null || parentIds.isEmpty() ) return null;
        String parentType;
        for (Id id : parentIds) {
            if (id == null) continue;
            parentType = getobjectNameFromId(id);
            break;
        }
        if (parentType == null) return null; // no valid Ids found in parentIds

        List<sObject> children = new List<sObject>();
        List<sObject> parents  = new List<sObject>();

        String query = 'SELECT Id, (SELECT Id FROM ' + childRelationshipName + ') FROM ' + parentType + ' WHERE Id IN :parentIds';

        //String query;
        //if (whereClause != null) 
        //    query = 'SELECT Id, (SELECT Id FROM ' + childRelationshipName + ') FROM ' + parentType + ' WHERE Id IN :parentIds';
        //else 
        //    query = 'SELECT Id, (SELECT Id FROM ' + childRelationshipName + ' ' + whereClause + ') FROM ' + parentType + ' WHERE Id IN :parentIds';

        try {
            for (sObject so : Database.query(query)) {
                if( so.getSObjects(childRelationshipName) != null ) children.addAll(so.getSObjects(childRelationshipName) );
            }
        } catch (Exception e) {
            UTIL.log(query);
            throw new GW_sObjectException('Exception in GW_sObject: getChildIds() for relationship '+childRelationshipName +' ' + parentIds + ' ' + whereClause + ': '+ e.getMessage());
        }


        return getIdSet(children);
    }

    public static Map<String,Set<Id>> splitIdSetByObjectType(Set<Id> soIds) {
        Map<String,Set<Id>> objIdsMap = new Map<String,Set<Id>>();
        String sObjectType;
        for (Id soId : soIds) {
            sObjectType = GW_sObject.getobjectNameFromId(soId);
            if (sObjectType == null) continue;
            if (!objIdsMap.containsKey(sObjectType)) objIdsMap.put(sObjectType, new Set<Id>() );
            objIdsMap.get(sObjectType).add(soId);
        }
        return objIdsMap;
    }

    // return a list of child Records -
    public static List<sObject> getChildren(Id parentId, String childRelationshipName) {
        return getChildren(new Set<Id>{parentId}, childRelationshipName);
    }

    public static List<sObject> getChildren(Id parentId, String childRelationshipName, String orderBy) {
        return getChildren(new Set<Id>{parentId}, childRelationshipName, orderBy);
    }

    public static List<sObject> getChildren( Id parentId, String childRelationshipName, String orderBy, String childrenWhereClause) {
        return getChildren(new Set<Id>{parentId}, childRelationshipName, orderBy, childrenWhereClause);
    }

    public static List<sObject> getChildren(Set<Id> parentIds, String childRelationshipName) {
        return getChildren(parentIds, childRelationshipName, null);
    }

    public static List<sObject> getChildren(Set<Id> parentIds, String childRelationshipName, String orderBy) {
        return getChildren( parentIds, childRelationshipName, orderBy, null );
    }

    public static List<sObject> getChildren ( Set<Id> parentIds, String childRelationshipName, String orderBy, String childrenWhereClause ) {
        if (parentIds == null || parentIds.isEmpty() ) return null;
        String parentType;
        Schema.SObjectType parentSOType;
        Schema.SObjectType childSOType;

        for (Id id : parentIds) {
            parentSOType = Id.getSObjectType();
            break;
        }
        parentType = parentSOType.getDescribe().getName();
        List<Schema.ChildRelationship> lstchildrelationships = parentSOType.getDescribe().getChildRelationships();

        for (Schema.ChildRelationship rel : lstchildrelationships) {
            if (rel.getrelationshipname() == childRelationshipName)
                childSOType = rel.getChildSObject();
        }
        if (childSOType == null )throw new GW_sObjectException('Exception in GW_sObject: getChildIds(): childRelationshipName not found: '+childRelationshipName);

        List<sObject> children = new List<sObject>();
        List<sObject> parents  = new List<sObject>();
        String query;

        try {
            List<String> fields = getAllSObjectFieldNames(childSOType.getDescribe().getName());
            String subQuery = getQueryBasePart(childRelationshipName, fields, orderBy, childrenWhereClause);
            query = 'SELECT Id, (' + subQuery + ') FROM ' + parentType + ' WHERE Id IN :parentIds';
            System.debug('===============' + query);
            List<sObject> queryResultList = Database.query(query);
            for (sObject so : queryResultList) {
                List<sObject> soList = so.getSObjects(childRelationshipName);
                if (soList != null && soList.size() > 0 ) children.addAll(soList );
            }
        } catch (Exception e) {
            UTIL.log('Query: '+query);
            throw new GW_sObjectException('Exception in GW_sObject: getChildren() for relationship '+childRelationshipName +' '+parentIds+': '+e.getMessage());
        }


        return children;
    }

    public static Map<id, List<sObject>> getChildrenMap(Set<Id> parentIds, String childRelationshipName, String orderBy){
        if (parentIds == null || parentIds.isEmpty() ) return null;
        String parentType;
        Schema.SObjectType parentSOType;
        Schema.SObjectType childSOType;

        for (Id parentId : parentIds) {
            parentSOType = parentId.getSObjectType();
            break;
        }
        parentType = parentSOType.getDescribe().getName();
        List<Schema.ChildRelationship> lstchildrelationships = parentSOType.getDescribe().getChildRelationships();

        for (Schema.ChildRelationship rel : lstchildrelationships) {
            if (rel.getrelationshipname() == childRelationshipName)
                childSOType = rel.getChildSObject();
        }
        if (childSOType == null )throw new GW_sObjectException('Exception in GW_sObject: getChildIds(): childRelationshipName not found: '+childRelationshipName);

        Map<id, list<sObject>> parentChildMap = new map<id, list<sObject>>();
        String query;

        try {
            List<String> fields = getAllSObjectFieldNames(childSOType.getDescribe().getName());
            String subQuery = getQueryBasePart(childRelationshipName, fields, orderBy);
            query = 'SELECT Id, (' + subQuery + ') FROM ' + parentType + ' WHERE Id IN :parentIds';
            for (sObject so : Database.query(query)) {
                id soCurrentId = so.id;
                List<sObject> soList = so.getSObjects(childRelationshipName);
                parentChildMap.put(soCurrentId, soList);
            }
        } catch (Exception e) {
            UTIL.log('Query: '+query);
            throw new GW_sObjectException('Exception in GW_sObject: getChildren() for relationship '+childRelationshipName +' '+parentIds+': '+e.getMessage());
        }


        return parentChildMap;
    }

    public static Map<id, List<sObject>> getChildrenMap(Set<Id> parentIds, String childRelationshipName, Set<String> additionalFields, String orderBy){
        if (parentIds == null || parentIds.isEmpty() ) return null;
        String parentType;
        Schema.SObjectType parentSOType;
        Schema.SObjectType childSOType;

        for (Id parentId : parentIds) {
            parentSOType = parentId.getSObjectType();
            break;
        }
        parentType = parentSOType.getDescribe().getName();
        List<Schema.ChildRelationship> lstchildrelationships = parentSOType.getDescribe().getChildRelationships();

        for (Schema.ChildRelationship rel : lstchildrelationships) {
            if (rel.getrelationshipname() == childRelationshipName)
                childSOType = rel.getChildSObject();
        }
        if (childSOType == null )throw new GW_sObjectException('Exception in GW_sObject: getChildIds(): childRelationshipName not found: '+childRelationshipName);

        Map<id, list<sObject>> parentChildMap = new map<id, list<sObject>>();
        String query;

        try {
            List<String> fields = getAllSObjectFieldNames(childSOType.getDescribe().getName());
            if (additionalFields != null) {
                fields.addAll(additionalFields);
            }
            String subQuery = getQueryBasePart(childRelationshipName, fields, orderBy);
            query = 'SELECT Id, (' + subQuery + ') FROM ' + parentType + ' WHERE Id IN :parentIds';
            for (sObject so : Database.query(query)) {
         id soCurrentId = so.id;
                List<sObject> soList = so.getSObjects(childRelationshipName);
                parentChildMap.put(soCurrentId, soList);
            }
        } catch (Exception e) {
            UTIL.log('Query: '+query);
            throw new GW_sObjectException('Exception in GW_sObject: getChildren() for relationship '+childRelationshipName +' '+parentIds+': '+e.getMessage());
        }


        return parentChildMap;
    }

    public class GW_sObjectException extends Exception {}

    // checks 1 or more fields have changes - assuming same sobject types
    public static Boolean oneOrMoreFieldsChanged(sObject so, sObject oldSo, Set<String> fields) {
        String sObjName = so.getSObjectType().getDescribe().getName();
        for (String field : fields) {
            if ( !GW_sObject.fieldExists( sObjName, field) ) throw new UTIL.CustomException('Invalid field specified: ['+sObjName+'.'+field+']');
            if (oldSo == null){
                return so.get(field) != null && !String.isEmpty(String.valueOf(so.get(field)));
            }
            else {
                Object fieldValue = (String.valueOf(so.get(field)) == '') ? null : so.get(field);
                Object oldFieldValue = (String.valueOf(oldSo.get(field)) == '') ? null : oldSo.get(field);
                if ( fieldValue <> oldFieldValue ) return true;
            }
        }
        return false;
    }


    // Returns the fields that have changed
    public static Set<String> getChangedFields(sObject so, sObject oldSo, Set<String> fields) {
        
        Set<String> changedFields = new Set<String>();
        
        if (oldSo == null){
            return changedFields;
        }       
         
        String sObjName = so.getSObjectType().getDescribe().getName();
        for (String field : fields) {
            if ( !GW_sObject.fieldExists( sObjName, field) ){
                throw new UTIL.CustomException('Invalid field specified: ['+sObjName+'.'+field+']');
            }   
            Object fieldValue = (String.valueOf(so.get(field)) == '') ? null : so.get(field);
            Object oldFieldValue = (String.valueOf(oldSo.get(field)) == '') ? null : oldSo.get(field);
            if ( fieldValue <> oldFieldValue ){
                changedFields.add(field);
            }    
        }
        return changedFields;
    }


    // describe methods
    public static Schema.DescribeSObjectResult getSObjectDescribe(String objectName) {
        Schema.SObjectType SObjectTypeObj = globalDescMap.get(objectName);
        if (SObjectTypeObj == null) throw new GW_sObjectException('Exception in GW_sObject: getSObjectDescribe() - ObjectName: \'' + objectName + '\' does not exist');
        return SObjectTypeObj.getDescribe();
    }

    public static Schema.SObjectType getSObjectType(String objectName) { return globalDescMap.get(objectName); }

    public static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        String mapObjectFieldKey = objectName + fieldName;
        if ( mapFieldResult.containsKey(mapObjectFieldKey) ) return mapFieldResult.get(mapObjectFieldKey);
        else {
            Schema.DescribeSObjectResult r = getSObjectDescribe(objectName);
            Map<String, Schema.SObjectField> fields = r.fields.getMap();
            Schema.SObjectField sfield = fields.get(fieldName);
            if (sfield == null) throw new GW_sObjectException('Exception in GW_sObject: getFieldDescribe() - FieldName: \'' + fieldName + '\' does not does not exist for Object \'' + ObjectName + '\'.');
            Schema.DescribeFieldResult dfr = sfield.getDescribe();
            mapFieldResult.put(mapObjectFieldKey, dfr);
            return dfr;
        }
    }

    public static Boolean fieldExists(String objectName, String fieldName) {
        String mapObjectFieldKey = objectName + fieldName;
        if ( mapFieldResult.containsKey(mapObjectFieldKey) ) return true;
        else {
            Schema.DescribeSObjectResult r = getSObjectDescribe(objectName);
            Map<String, Schema.SObjectField> fields = r.fields.getMap();
            Schema.SObjectField sfield = fields.get(fieldName);
            if (sfield == null) return false;
            return true;
        }
    }

    // Its ugly but fast
    public static Boolean fieldExists(String fieldName, sObject so) {
        try {
            so.get(fieldName);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static List<String> getAllSObjectFieldNames(String objectName) {
        Schema.DescribeSObjectResult r = getSObjectDescribe(objectName);
        Set<String> setFields = r.fields.getMap().keySet();
        List<String> theFields = new List<String>();
        theFields.addAll(setFields);
        return theFields;
    }

    public static String getFieldType(String objectName, String fieldName) {
        String mapObjectFieldKey = objectName + fieldName;

        if ( mapFieldType.containsKey(mapObjectFieldKey) ) return mapFieldType.get(mapObjectFieldKey);
        else {
            Schema.DescribeFieldResult dfr = getFieldDescribe(objectName, fieldName);
            Schema.DisplayType type = dfr.getType();
            String fieldType = type.Name();
            mapFieldType.put(mapObjectFieldKey, fieldType);
            return fieldType;
        }
    }

    public static String getFieldLabel(String objectName, String fieldName) {
        Schema.DescribeFieldResult dfr = getFieldDescribe(objectName, fieldName);
        return dfr.getLabel();
    }

    public static Database.UpsertResult[]  upsertSeparately(List<sObject> objects) {
        return upsertSeparately(objects, new Map<String,SChema.SObjectField>());
    }
    
    public static Database.UpsertResult[] upsertSeparately(List<sObject> objects, Map<String,Schema.SObjectField> upsertKeyMap) {
        Database.UpsertResult[] result = new List<Database.UpsertResult>();
        Map<String,List<sObject>> recordsPerType = new Map<String,List<sObject>>();
        for (sObject sObj : objects) {
            String objectType = sObj.getSobjectType().getDescribe().getName();
            List<sObject> mapItem = recordsPerType.get(objectType);
            if (mapItem == null) {
                Type t = Type.forName('List<'+objectType+'>');
                mapItem = (List<sObject>) t.newInstance();
            }
            mapItem.add(sObj);
            recordsPerType.put(objectType, mapItem);
        }

        for (String objectType : recordsPerType.keySet() ) {
        
            if (upsertKeyMap.get(objectType) == null) {
                result.addAll(Database.upsert( recordsPerType.get(objectType), FALSE ) );
            } else {
                result.addAll(Database.upsert( recordsPerType.get(objectType), upsertKeyMap.get(objectType)));
            }
        }
        return result;
    }

    public static List<String> getPickListValues(String objectName, String fieldName) {
        List<Schema.PicklistEntry> ple = GW_sObject.getFieldDescribe(objectName, fieldName).getPicklistValues();
        List<String> values = new List<String>();
        for ( Schema.PicklistEntry f : ple ) {
            values.add(f.getValue() );
        }
        return values;
    }

    public static String getFirstPickListValue(String objectName, String fieldName) {
        //List<Schema.PicklistEntry> ple = GW_sObject.getFieldDescribe(objectName, fieldName).getPicklistValues();
        return getPickLIstValues(objectName, fieldName)[0];
    }

    // Private members for queries
    private static string getWhereClause(String objectName, String customClause) {
        String checkcustomClause = customClause == null || customClause == 'null' ? '' : customClause.trim();
        String whereClause = '';
        if ( !String.isBlank(checkcustomClause) && !checkcustomClause.startsWith('LIMIT')) {
            whereClause += 'WHERE ' + customClause;
            if ( !whereClause.containsIgnoreCase('LIMIT') ) whereClause += ' LIMIT 40000';
        }

        return whereClause;
    }

    /*// provide base-query using all fields
    private static string getQueryBasePart(string objectName) {
        List<String> allFields = getAllSObjectFieldNames(objectName);
        return getQueryBasePart(objectName, allFields, null);
    }*/

    /*// provide base query using just 1 list of objectfields
    private static string getQueryBasePart(string objectName, List<String> fields) {
        return getQueryBasePart(objectName, fields, null);
    }*/

    // provide base query using provide list of objectfields
    private static string getQueryBasePart(string objectName, List<String> objFields) {
        return getQueryBasePart(objectName, objFields, null);
    }

    private static string getQueryBasePart(string objectName, List<String> objFields, string orderBy) { 
        return getQueryBasePart(objectName, objFields, orderBy, null );
    }

    private static string getQueryBasePart ( string objectName, List<String> objFields, string orderBy, string whereClause ) {
        String query = 'SELECT Id';
        Set<String> uniqueFieldNames = new Set<String>();
        if (objFields==null) objFields = getAllSObjectFieldNames(objectName);
        //uniqueFieldNames.addAll(new Set<String>{'createddate','lastmodifieddate'}); // must be all lower case to avoid duplicates
        uniqueFieldNames.addAll(objFields);

        uniqueFieldNames.removeAll(new Set<String>{'id','ID','Id','iD'}); // Id is added as first element, preventing duplicate fields

        for (String field : uniqueFieldNames) query += ', ' + field ;
        query += ' FROM ' + objectName + ' ';
        if ( whereClause != null ) query += 'WHERE ' + whereClause; 
        if (orderBy != null) query += ' ORDER BY '+orderBy;
        return query;
    }
    
    public static Map<String,String> getChildRelationshipsMap( String parentObjAPIName , String childObjAPIName ){
        
        Map<String,String> childRelationshipsMap = new Map<String,String>(); 
        String lookupFieldName = null;
        
        Schema.SObjectType parentObjType = globalDescMap.get( parentObjAPIName );
        Schema.SObjectType childObjType = globalDescMap.get( childObjAPIName );
        
        List<Schema.ChildRelationship> lstchildrelationships = parentObjType.getDescribe().getChildRelationships();
         for (Schema.ChildRelationship rel : lstchildrelationships) {
            if( childObjType == rel.getChildSObject() ){
                lookupFieldName = rel.getField().getDescribe().getName();
                childRelationshipsMap.put( lookupFieldName , rel.getrelationshipname() );
            }
         }
        
        return childRelationshipsMap;
     }    
}