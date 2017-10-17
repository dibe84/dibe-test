/**
 * author : HCS
 * date   : 2017-02-14
 */
@isTest
private class TST_SnapIns_Controller {

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
 
     
    @isTest static void TestGetValueFromDevSetting() {
        
        createTestUserAdmin();
        
        System.runAs ( userAdmin ) {
            String curSiteName = 'TESTSITE';
           List<DevSettings__c> lstDevSettings = new List<DevSettings__c>{
           		new DevSettings__c(Name = curSiteName +'_ButtonId' , value__c ='Test1234'),
           		new DevSettings__c(Name = curSiteName +'_DeplymentId' , value__c ='69327484'),
           		new DevSettings__c(Name = curSiteName +'_OrId' , value__c ='Test193864')
           };
           
		   insert lstDevSettings;
		   
		    Pagereference pg = Page.LCS_SnapIns;
            
            Test.setCurrentPageReference(pg);
            pg.getParameters().put('siteName',curSiteName);
            
            SnapIns_Controller  controller = new SnapIns_Controller();
            
            controller.username = 'Test testLastName';
            controller.getUserPhoto();
            Map<String,String> mapObjs = (Map<String,String>)JSON.deserialize(controller.jsonObj,Map<String,String>.class);
            system.assert(!mapObjs.isEmpty());
            system.assert( (mapObjs.get(curSiteName+'_ButtonId') == lstDevSettings.get(0).value__c));
            system.assert( (mapObjs.get(curSiteName+'_DeplymentId') == lstDevSettings.get(1).value__c));
            system.assert( (mapObjs.get(curSiteName+'_OrId') == lstDevSettings.get(2).value__c));
            
           
            
            
        }
    } 
    
    
    
    
    
  
}