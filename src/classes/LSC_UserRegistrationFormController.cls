/**
 * @Buss: To sign up user from Force.com/Community site 
 * @author: GIS
 * @createddate: 10 Apr 2017
 */
public with sharing class LSC_UserRegistrationFormController {
    
    @AuraEnabled
    public static String getFieldSet( String objectName, String fieldSetsName ){
        List<LSC_Helper.FieldSetMember> fieldSetsList = LSC_Helper.getFieldSet( objectName, fieldSetsName );
        if( !fieldSetsList.isEmpty() ){
            return JSON.serialize( fieldSetsList );    
        }
        return '';
    }
    
}