@isTest
private class TST_LSC_UserRegistrationFormController {
    
    @isTest 
    static void testFieldSetGetter() {
        
        // get field set for company details page
        Set<String> lstAccFieldSet = Schema.SObjectType.Account.fieldSets.getMap().keyset();
        if(!lstAccFieldSet.isEmpty()){
        	for(String fieldsetName: lstAccFieldSet){
        		String result = LSC_UserRegistrationFormController.getFieldSet( 'Account', fieldsetName);
        		System.assertNotEquals(null, result);
        	}
        }

        // get field set for user page
        Set<String> lstConFieldSet = Schema.SObjectType.Contact.fieldSets.getMap().keyset();
        if(!lstConFieldSet.isEmpty()){
        	for(String fieldsetName: lstConFieldSet){
        		String result = LSC_UserRegistrationFormController.getFieldSet( 'Contact', fieldsetName);
        		System.assertNotEquals(null, result);
        	}
        }
    }
    
}