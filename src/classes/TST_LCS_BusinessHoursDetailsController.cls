/**
 * author : HCS
 * date   : 2017-02-14
 */
@isTest
private class TST_LCS_BusinessHoursDetailsController {

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
 
     
    @isTest static void TestActivateDeactivateCallMeBackButton() {
        
        createTestUserAdmin();
        
        System.runAs ( userAdmin ) {
        	
        	LCS_BusinessHoursDetailsController controller = new LCS_BusinessHoursDetailsController();
        	//Site object is read-only object to query or retrieve information on your Force.com site.
        	if(!controller.lstActiveSites.isEmpty()) { 
        		
        		String curSiteName = controller.lstActiveSites.get(0).getValue();
        		//value before update
        		String preStatus = controller.devSetting.value__c;
        		controller.curSite = curSiteName;
        		controller.updateStatus();
        		
        		String whereClause = 'Name =\'' + curSiteName + LCS_BusinessHoursDetailsController.CALLMEBACK + '\'';
		        List<String> lstFields = new List<String>{'id','Name','Value__c'};
		        String objType = 'DevSettings__c';
		        List<DevSettings__c> lstDevSettings = GW_sObject.queryRecords(objType, lstFields, whereClause);
		        
		        String expStatus = preStatus == 'Active' ? 'Inactive' :'Active';
		        system.assert(!lstDevSettings.isEmpty());
		        system.assertEquals(expStatus, lstDevSettings.get(0).value__c);
		        
		        controller.initDevSetting();
		        system.assertEquals(expStatus, controller.devSetting.value__c);
		       
        		
        	}
        }
    } 
    
  
}