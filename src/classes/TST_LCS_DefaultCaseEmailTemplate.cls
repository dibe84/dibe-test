@isTest 
public class TST_LCS_DefaultCaseEmailTemplate {
    
    static User userAdmin {get{
    	if(userAdmin == null){
    		Profile p=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
	        userAdmin = GW_User.createTestUser(p);
	        userAdmin.Username='testUser1@testtt.com';
	        userAdmin.LastName='testLastName';
	        userAdmin.Email='testUser1@testtt.com';
	        userAdmin.Alias='test1';
	        userAdmin.TimeZoneSidKey='Pacific/kiritimati';
	        userAdmin.LocaleSidKey='ar';
	        userAdmin.EmailEncodingKey='UTF-8';
	        userAdmin.ProfileId=p.Id;
	        userAdmin.LanguageLocaleKey='en_US';   
	        insert userAdmin;
    	}
    	return userAdmin;
    }}


    @isTest static void Test_GetDefaultEmailTemplateId() {
        
        System.runAs(userAdmin){
            
            Case c = new Case(SuppliedEmail= 'TST_Case@test.com', OriginChannel__c = 'Test', SuppliedName = 'TST_Case1', SuppliedPhone = '+123456', Origin = 'Web', ownerId = userAdmin.id);
            insert c;
            
            EmailTemplate e = new EmailTemplate (developerName = 'ECGDK_CS_test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'ECGDK_CS_test'); 
			insert e;

			DevSettings__c devSetting = new DevSettings__c(Name = 'ECGDK_CS_DEFAULT_EMAIL_Test', value__c = 'info@bilbasen.dk');
			insert devSetting;
            
            Test.startTest();
	            //create QuickActionDefaults
	        	List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
		        {
		          new Map<String, Object>
		          	{
		                'targetSObject' 	=> new EmailMessage(),
		                'contextId' 		=> c.Id,
		                'actionType' 		=> 'Email',
		                'actionName' 		=> 'Case.Email',
		                'fromAddressList' 	=> new List<String> { 'salesforce@test.com' }
		          	}
		        };
	        
		        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
	            (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);

		        try {
		        	LCS_DefaultCaseEmailTemplate cont = new LCS_DefaultCaseEmailTemplate();
		            cont.onInitDefaults(defaultsSettings);
		        }
		        catch(Exception exc) {
		            //failureDuringExecution = e; 
		        }
            Test.stopTest();
        }
    } 

    @isTest static void Test_SkipDefaultEmailTemplateForMacro(){
        
        System.runAs(userAdmin){
            
            Case c = new Case(
            	SuppliedEmail= 'TST_Case@test.com', OriginChannel__c = 'Test', SuppliedName = 'TST_Case1', 
            	SuppliedPhone = '+123456', Origin = 'Web', ownerId = userAdmin.id , UseMacroEmailDefaults__c = true
            );
            insert c;
            
            Test.startTest();
	            //create QuickActionDefaults
	        	List<Map<String, Object>> defaultSettingAsObject = new List<Map<String, Object>>
		        {
		          new Map<String, Object>
		          	{
		                'targetSObject' 	=> new EmailMessage(),
		                'contextId' 		=> c.Id,
		                'actionType' 		=> 'Email',
		                'actionName' 		=> 'Case.Email',
		                'fromAddressList' 	=> new List<String> { 'salesforce@test.com' }
		          	}
		        };
	        
		        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
	            (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsObject), List<QuickAction.SendEmailQuickActionDefaults>.class);

		        try {
		        	LCS_DefaultCaseEmailTemplate cont = new LCS_DefaultCaseEmailTemplate();
		            cont.onInitDefaults(defaultsSettings);
		        }
		        catch(Exception exc) {
		            //failureDuringExecution = e; 
		        }
            Test.stopTest();
            Case mCase = [Select Id, UseMacroEmailDefaults__c From Case Where Id = :c.Id].get(0);
            System.assertEquals(false, mCase.UseMacroEmailDefaults__c);
        }
    } 
    
  
}