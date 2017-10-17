public class UTIL_StringParser {
    
    public static String parseAndReplace(String input, sObject sObj, String leftTag, string rightTag) {
    	Object objValue;
        String tag,value;
        if (input == null) input = '';
        While(input.substringBetween(leftTag,rightTag) != null ) {
           tag = input.substringBetween(leftTag,rightTag);
           tag = tag.deleteWhitespace();
           /*String sObjName = sObj.getSObjectType().getDescribe().getName();
           if ( !GW_sObject.fieldExists( sObjName, tag) ) 
               throw new UTIL.CustomException('Invalid field specified: ['+sObjName+'.'+tag+']');
           objValue = sObj.get(tag);
           value = objValue!=null?String.valueOf(objValue):'';*/
           value = getParsedValue(sObj, tag);
           input = input.replace(leftTag+tag+rightTag, value);
        }
		return input;
    }
    
    public static String parseAndReplace(String input, sObject sObj) {
        return parseAndReplace(input,sObj,'{{','}}');
    }
    
    public static Map<String, Object> lowerCaseKeys(Map<String, Object> mp, string sObjectType){
        Map<String, Object> outputMap = new map<String, Object>();       
        
        mp = setNullValues(mp, sObjectType);
        
        for (String key : mp.keySet() ) {
       
        if (mp.get(key) instanceof Map<String,Object> ) {
            String parentObjType = (String) ((Map<String,Object>) mp.get('attributes')).get('type');           
            outputMap.put(key.toLowerCase(), lowerCasekeys((Map<String, Object>) mp.get(key), parentObjType ) );
        } else {
        	outputMap.put(key.toLowerCase(), mp.get(key) );
        }
        
        }
        
        return outputMap;
    }

    public static Map<String, Object> setNullValues(Map<String, Object> mp, string sObjectType){        
        
        Schema.SObjectType convertType = Schema.getGlobalDescribe().get(sObjectType);
		Sobject sObj = convertType.newSObject();
               
        for(SObjectField f: sObj.getSobjectType().getdescribe().fields.getmap().values()) {
            	string checkVal = string.valueof(mp.get(String.valueOf(f)));
            	if(checkVal == NULL){
                    mp.put(String.valueOf(f), null);
                }
        }     
        return mp;     
    }
    
    public static String getParsedValue(sObject sObj, string tag){
          
        String parentObjType = string.valueof(sObj.getSObjectType());
        
        Map<String,Object> objMap = lowerCaseKeys((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(sObj)), parentObjType);   
        
        string mTag = tag.toLowerCase();
        
        While(mTag.contains('.')){
            list<string> tags = mTag.split('\\.', 2);
            mTag = tags.get(1);
            
            if(!objMap.containsKey(tags.get(0)))throw new UTIL.CustomException('Parent: ' + tags.get(0) + ' not found in field: ['+tag+']');  
            objMap = (Map<String,Object>) objMap.get(tags.get(0));
        }
        if(!objMap.containsKey(mTag))throw new UTIL.CustomException('Invalid field specified: ['+tag+']');
        Object objValue = objMap.get(mTag);
		return objValue!=null?String.valueOf(objValue):'';
    }
}