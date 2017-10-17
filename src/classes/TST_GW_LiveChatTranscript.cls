@isTest
private class TST_GW_LiveChatTranscript {

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
 
     
    @isTest static void TestinitialCaseId() {
        
        createTestUserAdmin();
        
        System.runAs ( userAdmin ) {
            
           String uuID =  '13947jdhflsljfjksdjdd';
            
           Case ca = new Case(status='New',MemberUnitId__c='test',MemberId__c='1234s',KeyToLiveChatTranscript__c = uuID);
           insert ca;

           LiveChatVisitor lcv = new LiveChatVisitor();
           insert lcv;

           List<LiveChatTranscript> lsTranscript = new List<LiveChatTranscript>();
           lsTranscript.add( new LiveChatTranscript( LiveChatVisitorId = lcv.Id , KeyToCase__c= uuID));
           insert lsTranscript;
           
           lsTranscript = [SELECT id,CaseId from LiveChatTranscript where Id In : lsTranscript];
           
           system.assert(!lsTranscript.isEmpty());
           system.assert( (lsTranscript.get(0).caseId == ca.id));
           
           lsTranscript.get(0).caseId = null;
           update lsTranscript;
           
          
            
        }
    } 
    
    
   
    
    
  
}