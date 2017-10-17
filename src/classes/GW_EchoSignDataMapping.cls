///////////////////////////////////////////////////////////////////////////
// Class EchoSign Data Mapping Gateway  --
//
// Used as a central location to manage interactions with the EchoSign Data Mapping Object
//
// Author:  gis-dev
// Email:   
//
///////////////////////////////////////////////////////////////////////////
public with sharing class GW_EchoSignDataMapping {
    private static final String GW_BASEOBJECTNAME = 'echosign_dev1__SIGN_Data_Mapping__c';
    
    //get echosign_dev1__SIGN_Data_Mapping__c record by Name
    public static List<echosign_dev1__SIGN_Data_Mapping__c> getRecords(String inFieldName, Set<String> soNames) { 
    	return (List<echosign_dev1__SIGN_Data_Mapping__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, inFieldName, soNames); 
    }
}