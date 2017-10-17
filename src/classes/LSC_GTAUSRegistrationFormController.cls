public with sharing class LSC_GTAUSRegistrationFormController {
    
    public static MemberUnit__c memberUnit {
        get{
            if (memberUnit == null) {
                String memberUnitId = UTIL.getConfig('GTAUS_RegistrationMemberUnitId');
                try {
                    memberUnit = GW_MemberUnit.getMemberUnitList(memberUnitId)[0];
                } catch(Exception ex) {
                    UTIL.throwError('Member Unit ' + memberUnitId + ' is missing ',ex);
                }
            }
            return memberUnit;
        }set;
    }
    
    @AuraEnabled
    public static String getFieldSet( String objectName, String fieldSetsName ){
        List<LSC_Helper.FieldSetMember> fieldSetsList = LSC_Helper.getFieldSet( objectName, fieldSetsName );
        return ( !fieldSetsList.isEmpty() ? JSON.serialize( fieldSetsList ): '');
    }
    
    @AuraEnabled
    public static Map<String, Object> submitRegistration ( String formDetail, String formType) {  
        Map<String, Object> mResult = new Map<String, Object>{
            'isSuccess' => true,
            'errMsg' => ''
        };
        
        Savepoint dbsavepoint = Database.setSavepoint();
        String sorryError = 'Sorry, an error has occurred.';
        
        try{
            Lead newLead = new Lead();
	        newLead.Member__c = memberUnit.Member__c;
	        newLead.MemberUnit__c = memberUnit.Id;
        
            String infoRegistrationLead = UTIL.getConfig('GTAUS_RegistrationLead');
            Map<String, Map<String,String>> mRegistrationLead = (Map<String, Map<String,String>>)JSON.deserializeStrict(infoRegistrationLead,Map<String,  Map<String,String>>.class);
            Map<String,String> mFieldSetting = mRegistrationLead.get(formType);
            
            // assign contact field value to new Contact sobject
            for( Object eachDetail : (List<Object>)JSON.deserializeUntyped( formDetail ) ){
                Map<String, Object> detailMap = (Map<String, Object>) eachDetail;
                newLead.put( (String)detailMap.get('name'), (String)detailMap.get('name') == 'Phone' ? '+' + detailMap.get('value') : detailMap.get('value') );
            }
            
            for( String field : mFieldSetting.keySet() ){
                newLead.put( field, mFieldSetting.get(field) );
            }
            
            insert newLead;
            
        } catch(DMLException exp){ 
            Database.rollback(dbsavepoint);
            mResult.put('isSuccess', false);
            mResult.put('errMsg', sorryError);
            mResult.put('rawMsg', exp.getMessage()+'. '+exp.getStackTraceString());
        } catch (Exception ex) {
            Database.rollback(dbsavepoint);
            mResult.put('isSuccess', false);
            mResult.put('errMsg', sorryError);
            mResult.put('rawMsg', ex.getMessage()+'. '+ex.getStackTraceString());
        }

        return mResult;
    }
}