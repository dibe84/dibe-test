///////////////////////////////////////////////////////////////////////////
// Class UTIL_FieldSet
// Handles generic RecordType related methods. .
// Author:  Jochem van den Heuvel
/////////////////////////////////////////////////////////////////////////// 
public with sharing class UTIL_RecordType{
	private static Map<Schema.SObjectType,Map<String,RecordType>> recordTypeCache; // sobject => Developername => RecordType
	private static Map<Id,RecordType> recordTypes;
	
	static {
    	recordTypeCache		= new Map<Schema.SObjectType,Map<String,RecordType>>();
		recordTypes 		= new Map<Id,RecordType>([SELECT Id, Name, DeveloperName, SObjectType, IsActive FROM RecordType LIMIT 10000]);
	}

	public static Map<String, RecordType> GetRecordTypesForObjectType(Schema.SObjectType token) {
		// Already in cache? 
	    Map<String, RecordType> mapRecordTypes = recordTypeCache.get(token);
	    
		// If not, fill cache with active RecordTypes for this sObject (that are available for running user)
	    if (mapRecordTypes == null) {
	        mapRecordTypes = new Map<String, RecordType>();
		    for (RecordType rt : recordTypes.values() ) {
				if (rt != null && rt.IsActive && rt.SObjectType == token.getDescribe().getName() ) {
		            mapRecordTypes.put(rt.DeveloperName,rt);
		        }
		    }
	        recordTypeCache.put(token,mapRecordTypes);
	    }
	    return mapRecordTypes;
	}

	// if need to check for User availability... ffu
	/*
	private static Map<String, RecordType> GetRecordTypesByDeveloperNameAvailableToUser(Schema.SObjectType token) {
		// Already in cache? 
	    Map<String, RecordType> mapRecordTypes = recordTypeCache.get(token);
	    
		// If not, fill cache with active RecordTypes for this sObject (that are available for running user)
	    if (mapRecordTypes == null) {
	        mapRecordTypes = new Map<String, RecordType>();
			
			// Get the Describe Result
		    Schema.DescribeSObjectResult obj = token.getDescribe();

		    // Obtain the RecordTypeInfos for this SObjectType token
		    Map<Id,Schema.RecordTypeInfo> recordTypeInfos = obj.getRecordTypeInfosByID();

		    // Only returs the ones available to the running User
		    for (Schema.RecordTypeInfo rti : recordTypeInfos.values() ) {
				RecordType rt = recordTypes.get(rti.getRecordTypeId());
		        if (rt != null && rti.isAvailable() && rt.IsActive ) {
		            mapRecordTypes.put(rt.DeveloperName,rt);
		        }
		    }
	        recordTypeCache.put(token,mapRecordTypes);
	    }
	    return mapRecordTypes;
	}
	*/
	
	public static RecordType getRecordTypeByName(String objectName, String rtDeveloperName) {
		Schema.SObjectType token = GW_sObject.getSObjectType(objectName);
		Map<String, RecordType> objectRtMap = GetRecordTypesForObjectType(token);
		if(objectRtMap != null) {
			return objectRtMap.get(rtDeveloperName);
		}
		return null;
	}
	
	public static RecordType getRecordTypeById(Id rtId) {
		//UTIL.log('rtId: '+ rtId);
		if (rtId == null) return null;
		UTIL.log('RecordTypes: '+ UTIL_RecordType.recordTypes);
		return recordTypes.get(rtId);
	}


}