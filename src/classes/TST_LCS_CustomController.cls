@isTest
private class TST_LCS_CustomController {
  	
  	private static String USER_TEST_EMAIL = 'testUser1@testtt.com';
    private static User adminUser {get{
        return [Select Id from User where Email =:USER_TEST_EMAIL];
    } private set;}
  	
  	@testSetup
    static void setup() {
        Profile p=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
        User userAdmin = GW_User.createTestUser(p);
        userAdmin.Username='testUser1@testtt.com';
        userAdmin.LastName='testLastName';
        userAdmin.Email= USER_TEST_EMAIL;
        userAdmin.Alias='test1';
        userAdmin.TimeZoneSidKey='Pacific/kiritimati';
        userAdmin.LocaleSidKey='ar';
        userAdmin.EmailEncodingKey='UTF-8';
        userAdmin.ProfileId=p.Id;
        userAdmin.LanguageLocaleKey='en_US';   
        insert userAdmin;
    }
     
    @isTest static void TestGetActiveSiteAlert() {
        System.runAs(adminUser){
            Site_Alert__c siteAlert = new Site_Alert__c(Active__c= true,Alert_Text__c='Test with security.', name='Test site alert',Site__c = 'Test site');
            insert siteAlert;
            List<Site_Alert__c> lstResults =  LCS_CustomController.getActiveSiteAlert(siteAlert.Site__c);
            system.assert(!lstResults.isEmpty());
          	system.assertEquals(siteAlert.Alert_Text__c, lstResults.get(0).Alert_Text__c);
        }
    } 
    
    @isTest static void TestGetArticleViewCount() {
        System.runAs(adminUser){
           List<Bilbasen__kav> lstRecord = [Select title From Bilbasen__kav Where  PublishStatus= 'online' And Language = 'da' limit 1];
           List<String> lstArticles = new List<String>();
           String curTitle = !lstRecord.isEmpty() ? lstRecord.get(0).title : 'TestGetArticleViewCount';
           Object result =  LCS_CustomController.getArticleViewCount(new List<String>{curTitle},'Bilbasen');
           system.assert( result != null );
        }
    } 
    
    @isTest static void TestGetInitialData() {
        System.runAs(adminUser){
        	Object result = LCS_CustomController.getInitialData('Bilbasen', 'DK_BB');
        	List<Object> lstResults = (List<Object>)result;
        	system.assert( lstResults.size() == 2 );
        }
    } 
    
	@isTest static void TestGetAllSiteLinks() {
        System.runAs(adminUser){
            Map<String,List<String>> mapTest = new Map<String,List<String>>();
            mapTest.put('Test', new List<String>{'test'});
            List<DevSettings__c> lstDevSetting = new List<DevSettings__c>{ 
                new DevSettings__c ( name = 'Test_Footer_Structure',value__c='Test_Footer_Structure', Description__c = JSON.serialize(mapTest)),
                new DevSettings__c ( name = 'Test_test_link',value__c='Test_test_link', Description__c = 'www.test.com')
            };
            insert lstDevSetting;
           
            Test.startTest();
               Object result = LCS_CustomController.getAllSiteLinks('Test', 'link', true) ;
            Test.stopTest();
            
            List<Object> lstResults = (List<Object>)result;
            system.assert(lstResults.size()>1);
            
        }
    } 
    
    @isTest static void TestCreateCallLog() {
     	System.runAs(adminUser){
        	String preSettingName = 'Test_test';
        	List<Object> lstInvalues = new List<Object>{new Map<String,String>{'name'=>'OriginChannel__c', 'value'=>'Bilbasen'}};
        	DevSettings__c devSetting = new DevSettings__c( name = preSettingName,value__c='testss', Description__c = JSON.serialize(lstInvalues));
        	insert devSetting;
        	  
        	List<Object> lstObjs = new List<Object>{
            	new Map<String,String> { 'name' => 'Origin__c' , 'value' => 'Web'},
            	new Map<String,String> { 'name' => 'SuppliedName__c' , 'value' => 'Test_Test'},
            	new Map<String,String> { 'name' => 'MemberUnitId__c' , 'value' => 'ECGDKCS'},
            	new Map<String,String> { 'name' => 'MemberId__c' , 'value' => 'ECGDK'},
            	new Map<String,String> { 'name' => 'SuppliedEmail__c' , 'value' => 'Test@test.com.test'},
            	new Map<String,String> { 'name' => 'SuppliedPhone__c' , 'value' => '+1239484774789'},
            	new Map<String,String> { 'name' => 'Category__c' , 'value' => 'Andet'},
            	new Map<String,String> { 'name' => 'Description__c' , 'value' => 'test'}
            };
		
            Test.startTest();
        	   Object result = LCS_CustomController.createCallLog( JSON.serialize(lstObjs) , preSettingName);
            Test.stopTest();
        	
            List<Object> lstResults = (List<Object>)result;
        	Map<String,String> mapResult  = (Map<String,String>)lstResults.get(0);
        	System.assert( mapResult.get('isSuccess') == 'true' );
        }
    } 


    @isTest static void TestCreateCallLogErrors(){
    	System.runAs(adminUser){
        	String preSettingName = 'Test_test';
        	List<Object> lstInvalues = new List<Object>{new Map<String,String>{'name'=>'OriginChannel__c', 'value'=>'Bilbasen'}};

            List<Object> lstObjs = new List<Object>{
                new Map<String,String> { 'name' => 'Origin__c' , 'value' => ''},
                new Map<String,String> { 'name' => 'SuppliedName__c' , 'value' => ''},
                new Map<String,String> { 'name' => 'MemberUnitId__c' , 'value' => ''},
                new Map<String,String> { 'name' => 'MemberId__c' , 'value' => ''},
                new Map<String,String> { 'name' => 'SuppliedEmail__c' , 'value' => ''},
                new Map<String,String> { 'name' => 'SuppliedPhone__c' , 'value' => '+1239484774789'},
                new Map<String,String> { 'name' => 'Category__c' , 'value' => ''},
                new Map<String,String> { 'name' => 'Description__c' , 'value' => ''}
            };

            Object result = LCS_CustomController.createCallLog(JSON.serialize(lstObjs), preSettingName);
            List<Object> lstResults = (List<Object>)result;
            Map<String,String> mapResult  = (Map<String,String>)lstResults.get(0);
            System.assert(mapResult.get('isSuccess') == 'false', 'Custom Settings DevSettings__c do not have mapping data'); 

            Test.startTest();
        	    DevSettings__c devSetting = new DevSettings__c(name = preSettingName,value__c='testss', Description__c = JSON.serialize(lstInvalues));
        	    insert devSetting;
        	 
                result = LCS_CustomController.createCallLog(JSON.serialize(lstObjs), preSettingName);

                lstResults = (List<Object>)result;
                mapResult  = (Map<String,String>)lstResults.get(0);
                System.assert(mapResult.get('isSuccess') == 'false', 'Required fields error'); 
            Test.stopTest();
        }
    } 
    
    @isTest static void TestCreateCaseFromCallLog() {
        
        System.runAs(adminUser){
        	String preSettingName = 'Test_test';
        	List<Object> lstInvalues = new List<Object>{new Map<String,String>{'name'=>'OriginChannel__c', 'value'=>'Bilbasen'}};
        	DevSettings__c devSetting = new DevSettings__c( name = preSettingName,value__c='testss', Description__c = JSON.serialize(lstInvalues));
        	insert devSetting;

            String calemail = 'Test@test.com.test';
            List<Object> lstObjs = new List<Object>{
            	new Map<String,String> {'name' => 'Origin__c' , 'value' => 'Web'},
            	new Map<String,String> {'name' => 'SuppliedName__c' , 'value' => 'Test_Test'},
            	new Map<String,String> {'name' => 'MemberUnitId__c' , 'value' => 'ECGDKCS'},
            	new Map<String,String> {'name' => 'MemberId__c' , 'value' => 'ECGDK'},
            	new Map<String,String> {'name' => 'SuppliedEmail__c' , 'value' => calemail},
            	new Map<String,String> {'name' => 'SuppliedPhone__c' , 'value' => '+1239484774789'},
            	new Map<String,String> {'name' => 'Category__c' , 'value' => 'Andet'},
            	new Map<String,String> {'name' => 'Description__c' , 'value' => 'test'}
            };
            
            Test.startTest();
                Object result = LCS_CustomController.createCallLog(JSON.serialize(lstObjs), preSettingName);
                List<CallLog__c> lstCals = [Select id, CaseId__c, ContactId__c, SuppliedName__c 
                                                From CallLog__c 
                                                Where SuppliedEmail__c =:calemail
                                            ];

                System.assert(!lstCals.isEmpty()); 
                String callLogId = lstCals.get(0).id;
                String wsResult = WS_UI.createCaseFromCallLog(callLogId)[0];
                System.assert((wsResult =='Case has been created successfully!'));

                // test call log case errors
                String er1Result = WS_UI.createCaseFromCallLog(callLogId)[0];
                System.assert((er1Result =='Case is already created for this Call Log.'));

                wsResult = GW_Case.createCaseFromCallLog('incorrect id')[0];
                System.assert((wsResult.contains('incorrect id')));
            Test.stopTest();
        }
    } 

    public static testMethod void testCreateCaseAutomaticallyFromCallLog() {

        System.runAs(adminUser){
            String preSettingName = 'Test_test';
            List<Object> lstInvalues = new List<Object>{new Map<String,String>{'name'=>'OriginChannel__c', 'value'=>'Bilbasen'}};
            DevSettings__c devSetting = new DevSettings__c( name = preSettingName,value__c='testss', Description__c = JSON.serialize(lstInvalues));
            insert devSetting;

            String calemail = 'Test@test.com.test';
            List<Object> lstObjs = new List<Object>{
                new Map<String,String> {'name' => 'Origin__c' , 'value' => 'Web'},
                new Map<String,String> {'name' => 'SuppliedName__c' , 'value' => 'Test_Test'},
                new Map<String,String> {'name' => 'MemberUnitId__c' , 'value' => 'ECGDKCS'},
                new Map<String,String> {'name' => 'MemberId__c' , 'value' => 'ECGDK'},
                new Map<String,String> {'name' => 'SuppliedEmail__c' , 'value' => calemail},
                new Map<String,String> {'name' => 'SuppliedPhone__c' , 'value' => '+1239484774789'},
                new Map<String,String> {'name' => 'Category__c' , 'value' => 'Andet'},
                new Map<String,String> {'name' => 'Description__c' , 'value' => 'test'}
            };
            
            Test.startTest();
                Object result = LCS_CustomController.createCallLog(JSON.serialize(lstObjs), preSettingName);
                List<CallLog__c> lstCals = [
                    SELECT id, CaseId__c, ContactId__c, SuppliedName__c 
                    FROM CallLog__c 
                    WHERE SuppliedEmail__c = :calemail
                ];

                System.assert(!lstCals.isEmpty()); 
                CallLog__c cl = lstCals.get(0);
                cl.OwnerId = adminUser.Id;
                update cl;
                System.assertEquals([SELECT Id, CaseID__c FROM CallLog__c WHERE Id = :cl.Id].CaseID__c, null);

                cl.Status__c = 'In Progress';
                update cl;
                System.assertNotEquals([SELECT Id, CaseID__c FROM CallLog__c WHERE Id = :cl.Id].CaseID__c, null);
                
            Test.stopTest();

        }
    }
    
    @isTest static void TestGetCurrentDate() {
        
        System.runAs(adminUser){
        	//We cannot perform DML on business hours, so we need to select the default one.
            List<BusinessHours> lstBusHours=[select id,name from BusinessHours where IsDefault=true];
        	System.assert(!lstBusHours.isEmpty());
        	
        	Holiday hol = new Holiday(Name='Test holiday', activitydate = System.Today(),isAllDay = true );
			insert hol;
			
			String curSiteName = lstBusHours.get(0).name;
			
			DevSettings__c devSetting = new DevSettings__c(Name = curSiteName + LCS_BusinessHoursDetailsController.CALLMEBACK , value__c ='Inactive');
			insert devSetting;
			
            Test.startTest();
    			String whereClause = 'isActive = true And Name =\'' + curSiteName + '\'';
    	   		List<BusinessHours> lstResult =  GW_sObject.queryRecords('BusinessHours', new List<String>{'id'}, whereClause);
            	
            	Object obj = LCS_CustomController.getCurrentDate(curSiteName);
            	List<Object> lstObjResults = ((List<Object>)obj);
            	
            	Map<String,Boolean> mapResults =  (Map<String,Boolean>)(lstObjResults[0]);
            	System.assert(!mapResults.isEmpty());
            	DevSettings__c expDevSetting =  (DevSettings__c)(lstObjResults[1]);
            	System.assert( (expDevSetting.value__c== 'Inactive'));
            Test.stopTest();
        }
    } 
    
    @isTest static void TestgetDataCategoryLabel() {
        System.runAs(adminUser){
        	String label = LCS_CustomController.getDataCategoryLabel('DK_DBA','profil');
            System.assertEquals(label, 'profil');
        }
    } 
    
    @isTest static void test_getActiveSiteAlert() {
    	System.runAs(adminUser){
        	Site_Alert__c siteAlert = new Site_Alert__c(Active__c= true,Alert_Text__c='Test with security.', name='Test site alert',Site__c = 'Test site');
            insert siteAlert;
            List<Site_Alert__c> lstSA = LCS_CustomController.getActiveSiteAlert(siteAlert.Site__c);
            System.assert(lstSA.get(0).Alert_Text__c == siteAlert.Alert_Text__c);
        }
    } 
    
    @isTest static void test_getFieldSet() {
    	System.runAs(adminUser){
    		String preSettingName = 'Test_test';
        	List<Object> lstInvalues = new List<Object>{new Map<String,String>{'name'=>'OriginChannel__c', 'value'=>'Bilbasen'}};
        	DevSettings__c devSetting = new DevSettings__c(name = preSettingName, value__c='testss', Description__c = JSON.serialize(lstInvalues));
        	insert devSetting;
        	 
    		String objName = 'CallLog__c';
    		String fsn = 'TEsttttt';
    		Object result = LCS_CustomController.getFieldSet(objName, fsn, preSettingName);
            System.assert(result != null);

            Test.startTest();
                Object err1 = LCS_CustomController.getFieldSet('fakeObject', fsn, preSettingName);
                List<Object> erRes = (List<Object>) err1;
                List<String> categVal = (List<String>) erRes.get(1);
                System.assert(categVal.isEmpty(), 'OBJNAME NOT FOUND');
                
                Map<String,List<String>> err2 = LCS_UTILS.getDependentOptionsImpl('CallLog__c' , 'WrongField__c' , 'Category__c'); 
                System.assert(err2.isEmpty(), 'FIELD NOT FOUND'); 

                LCS_UTILS.PicklistEntryWrapper pickWr = new LCS_UTILS.PicklistEntryWrapper();
                pickWr.active = 'active';
                pickWr.defaultValue = 'defaultValue';
                pickWr.value = 'value';

                LCS_UTILS.FieldSetMember membWr = new LCS_UTILS.FieldSetMember(true);

                List<Schema.PicklistEntry> entryList = CallLog__c.Category__c.getDescribe().getPicklistValues();
                LCS_UTILS.PicklistOptions plWr = new LCS_UTILS.PicklistOptions(entryList[0]);
                System.assertNotEquals(plWr.label, null);
            Test.stopTest();
        }
    }
  
}