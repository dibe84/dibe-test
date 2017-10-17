@isTest
private class TST_GW_SocialPost {

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
 
     
    @isTest static void TestinitialCaseMemberId() {
        
        createTestUserAdmin();
        
        System.runAs ( userAdmin ) {
            
           Case ca = new Case(status='New',MemberUnitId__c='test',MemberId__c='1234s');
           insert ca;
           
           SocialPost  socialPost = new SocialPost(parentId= ca.id, Provider='Facebook',PostTags='TestM_test_ttesttt',Name='Test test'); 
           insert socialPost;
           
           List<Case> lstCases =  GW_sObject.queryRecords('Case', new List<String> {'id','MemberId__c '}, new Set<Id>{ca.id} );
           system.assert(!lstCases.isEmpty());
           String expMemberId = socialPost.PostTags.split('_')[0];
           system.assert( (lstCases.get(0).MemberId__c == expMemberId));
            
        }
    } 
    
    
   
    
    
  
}