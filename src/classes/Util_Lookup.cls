/**
 * @author: GIS-DevTeam
 * @createdDate: 08/May/2017
 * @description: 
 *	- Use for lookup in lightning component
 *
 */
public without sharing class Util_Lookup {

    private static string addtionalCriteriaClause = '';

    @AuraEnabled
    public static RemoteResponse queryListLookupWithACriteria(String sObjName, String textFilter, List<String> lstFields, Integer lim, String recordTypeName, String criteriaField, String criteriaVal ){
        try{
            
            if (String.isNotBlank(criteriaField) && String.isNotBlank(criteriaVal)) addtionalCriteriaClause += ' AND ' + criteriaField + ' = \'' + criteriaVal + '\'';
            
            RemoteResponse response = queryListLookup(sObjName, textFilter, lstFields, lim, recordTypeName);
            
            return response;
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    @AuraEnabled
    public static RemoteResponse queryListLookup(String sObjName, String textFilter, List<String> lstFields, Integer lim, String recordTypeName){
        try{
        	String whereClause = '';
        	Integer i = 0;
        	for(String fname: lstFields){
        		whereClause+= fname.trim() + ' LIKE \'' + '%' + textFilter + '%' +'\' ';
        		if(lstFields.size() > 1 && i <= (lstFields.size() - 2)) whereClause += 'Or ';
        		i++;
        	}
        	
        	//add AND filter for recordtype.Name
        	if(String.isNotBlank(recordTypeName)){
        		whereClause += ' AND RecordType.Name = \'' + recordTypeName + '\'';
        	}
        	
            //In case the component need to filter from additional field
            if (String.isNotBlank(addtionalCriteriaClause)) whereClause += addtionalCriteriaClause;
            

        	whereClause += ' LIMIT ' + lim; System.debug('### whereClause :: ' + whereClause);
        	
        	List<sObject> lstLookup = GW_sObject.queryRecords(sObjName, whereClause, new List<String>());
        	
            RemoteResponse response = new RemoteResponse();
           	response.content = lstLookup.isEmpty()?null:lstLookup;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
    @AuraEnabled
    public static RemoteResponse queryLookupItem(String Id, String sObjName){
        try{
        	Set<Id> sId = new Set<Id>{Id};
        	List<sObject> lstLookup = GW_sObject.queryRecords(sObjName, sId);
        	
            RemoteResponse response = new RemoteResponse();
           	response.content = lstLookup.isEmpty()?null:lstLookup.get(0);
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
    	}
    }
}