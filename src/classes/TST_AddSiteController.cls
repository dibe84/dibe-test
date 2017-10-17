/**
 * author : HCS
 * date   : 2017-02-14
 */
@isTest
private class TST_AddSiteController {

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
 
     
    @isTest static void TestGetSiteAlert() {
        
        createTestUserAdmin();
        
        System.runAs ( userAdmin ) {
        	
            Site_Alert__c siteAlert = new Site_Alert__c(Active__c= true,Alert_Text__c='Test with security.', name='Test site alert');
            insert siteAlert;
            
            Apexpages.Standardcontroller setCon = new Apexpages.Standardcontroller( new Site_Alert__c());
            
            AddSiteController controller = new AddSiteController(setCon);
            system.assert( String.isEmpty(controller.curSiteAlert.id));
            
            setCon = new Apexpages.Standardcontroller(siteAlert);
            controller = new AddSiteController(setCon);
            system.assert( (controller.curSiteAlert.id == siteAlert.id));
            
            List<SelectOption> lstOptions = controller.getItems();
            
            controller.curSiteAlert.Site__c= 'TestSite';
            controller.saveSiteAlert();
            
            system.assert( !controller.isRequestError);
            
            
        }
    } 
    
    
    
    
    
  
}