@isTest
private class TST_LCS_UpdateRecordOwnerController {

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
 
     
    @isTest static void TestUpdateRecordOwner() {
        
        createTestUserAdmin();
        
        System.runAs ( userAdmin ) {
        	
        	Case cc1 = new Case( SuppliedEmail= 'TST_Case@test.com',  SuppliedName = 'TST_Case1', SuppliedPhone = '+123456', Origin = 'Web', ownerId = userAdmin.id);
        	insert cc1;
        
            Group g1 = new Group(Name='Tes_group_name', type='Queue',DeveloperName = 'Tes_group_name');
            insert g1;
            
            QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
            insert q1;
            
            Map<String,String> mapResult = LCS_UpdateRecordOwnerController.updateRecordOwner(cc1.id, g1.Name);
            cc1 = [select id,  ownerId from Case where id = :cc1.id];
          
            system.assertEquals( 'true' ,  mapResult.get('isSuccess') );
        }
    } 
    
    
    
    
    
  
}