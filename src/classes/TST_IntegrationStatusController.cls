@isTest
private class TST_IntegrationStatusController {

    private static User userAdmin;
  
    
    private static void createTestUserAdmin(){
       
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
 
     
    @isTest static void TestCheckExistingTopic() {
        
        createTestUserAdmin();
        
        System.runAs ( userAdmin ) {
           
           Test.startTest();
	           RemoteResponse result =  IntegrationStatusController.checkExistingTopic('Testtttt1111111','testt1113333');
	           system.assertEquals(  result.statusCode , RemoteResponse.STATUSCODE_OK);
	           
	           
	           String whereClause = 'Id =\'' + ((PushTopic)result.content).id + '\'';
	           List<PushTopic> lstExistTopics = GW_sObject.queryRecords( 'PushTopic' , new List<String>{'id'} , whereClause);
	           
	           system.assert((!lstExistTopics.isEmpty()));
	           
	           result =  IntegrationStatusController.checkExistingTopic('Testtttt1111111','testt1113333');
	           
           Test.stopTest();
        }
    } 
    
    
     @isTest static void TestgetListWSScheduledCallOuts() {
        
        createTestUserAdmin();
        
        System.runAs ( userAdmin ) {
           
           Test.startTest();
	           Account acc = GW_Account.insertSObject();
	         
	           List<WS_ScheduledCallout__c> lstWSCalouts = new List<WS_ScheduledCallout__c>{
	           	 new WS_ScheduledCallout__c(RecordId__c= acc.id)
	           };
	           
	           insert lstWSCalouts;
	           
           	   WS_Log__c wsLog = new WS_Log__c(ScheduledCallout__c= lstWSCalouts.get(0).id, Success__c= false, Error__c='Invalid field.', Account__c= acc.id ,CalloutName__c='test');
           	   insert wsLog;
           	   
	            Object result =  IntegrationStatusController.getListWSScheduledCallOuts( acc.id, 'Account') ;
	            Id expId = lstWSCalouts.get(0).id;
	            List<Object> lstObjs= (List<Object>)result;
	            List<RemoteResponse> lstRemotes = ((List<RemoteResponse>)lstObjs[0]);
	            Id resultId = ((WS_ScheduledCallout__c)lstRemotes[0].content).id;
	            system.assert( (expId == resultId));
	            
	            Contact con = GW_Contact.insertSObject('LastName', acc);
	            con.Primary__c=true;
	            con.isActive__c=true;
	            update con;
            	Opportunity opp = GW_Opportunity.insertSObject(acc, con);
	            result =  IntegrationStatusController.getListWSScheduledCallOuts( opp.id, 'Opprtunity') ;
	           
	           
           Test.stopTest();
        }
    } 
    
  
}