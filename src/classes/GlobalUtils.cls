/*
 *
 * 2012-08-28: Sofiya Kachmar (CRMWaypoint)
*/
global class GlobalUtils {
/**
    * Static variable is used in trigger as flag to check if 
    * trigger have already run.
    */  
    global static Boolean isLooped = false;
    global static Boolean isLooped2 = false;
    global static Boolean isAlreadyProcessed = false;
    global static Boolean isSentToFiqas = false;
    global static Boolean isBASentToFiqas = false;
    global static Boolean isPASentToFiqas = false;
    global static Boolean isFromSUS = false;
    global static boolean inFutureContext = false;
    global static Boolean isSyncWithSUS = false;
    global static Boolean emailSentOLIChanges = false;
    global static Boolean emailSentOPPChanges =false;
    global static Boolean emailSentOPPTTEAMChanges =false;
    global static Boolean RSTriggerIsExecutingRevCalc = false;
    global static Boolean LineItemsIsExecutingUpdateRevenues = false;
    global static Boolean RevCalcExecuting_6475 = false;
    //global static Map<ID, Revenue__c> rsStaticRevMap = null; 
    global static Map<ID, Product2> rsStaticProdMap = null;
    //global static Integer iCount = 0;
    
    /**
     *
     */
    public void removeNullValues(List<sObject> sObjects){
        String sObjectName = String.valueOf(sObjects[0].getSobjectType());
        // Generate a Map of the fields for the selected object
        Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        Map<String,Schema.DescribeFieldResult> fieldsDescribe = new  Map<String,Schema.DescribeFieldResult>();
               
        //Iterate over input list
        for(sObject so:sObjects){
            
            //Iterate over all fields of the record
            for (String fieldName : fieldsMap.keySet()){
                try{
                    Object soField = so.get(fieldName);
                    System.debug('XXXXX filed-->' + fieldName + ': ' + soField);
                    if(soField != null && String.valueOf(soField).toLowerCase() == 'null' 
                       || (fieldName.toLowerCase().contains('street') && String.valueOf(soField).contains('null'))){
                        //populate the fieldsDescribe map in order to avoid limit with getDescribe
                        if(fieldsDescribe.get(fieldName) == null ){
                            fieldsDescribe.put(fieldName,fieldsMap.get(fieldName).getDescribe());
                        }
                        if( fieldsDescribe.get(fieldName).isCreateable() && fieldsDescribe.get(fieldName).isNillable()){
                            if(fieldName.toLowerCase().contains('street')){
                                so.put(fieldName, String.valueOf(soField).replace(' null','').replace('null ',''));
                                System.debug('XXXXX soField-->'+soField);
                                System.debug('XXXXX streetNullreplace-->'+String.valueOf(soField).replace(' null',''));
                            }else { 
                                so.put(fieldName, null);
                            }
                        }
                    }
                } catch(Exception e){
                    System.debug('XXXXX Exception-->'+e);
                    
                }
            }
        }
        
    }
    
}