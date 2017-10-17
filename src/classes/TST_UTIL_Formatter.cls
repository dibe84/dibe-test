@isTest 
private class TST_UTIL_Formatter {

	@IsTest static void test_localDate() {
        User testUser = GW_User.insertTestUser();
        Test.startTest();
        System.runAs ( testUser ) {  
            Datetime myDate =
			datetime.newInstance(2012, 12, 1, 12, 30, 2);
			
			UTIL_Formatter ctrl = new UTIL_Formatter();
			String output = ctrl.getFormattedString(); // check no input
			System.assertEquals(output,'N/A');
			
			ctrl.dbDateTime = myDate;
			output = ctrl.getFormattedString();
			System.assertEquals(output,'1-12-2012 12:30');
			
			ctrl.reqFormat = 'hh:mm';
			output = ctrl.getFormattedString();
			System.assertEquals(output,'12:30');
			
			Datetime myDateGMT = datetime.newInstanceGmt(2012, 12, 1, 12, 30, 2);
			ctrl.dbDateTime = myDateGMT;
			
			output = ctrl.getFormattedString();
			System.assertEquals(output,'01:30');
	    }
	    
	    testUser.LocaleSidKey = 'en_US';
	    testUser.TimeZoneSidKey = 'America/Chicago'; // GMT-6
	    update testUser; //M/d/yyyy h:mm a
	    
	    system.runAs(testUser){	
			Datetime myDate =
			datetime.newInstance(2012, 12, 1, 12, 30, 2);
			
			UTIL_Formatter ctrl = new UTIL_Formatter();
			ctrl.dbDateTime = myDate;
			
			String output = ctrl.getFormattedString();
			System.assertEquals(output,'12/1/2012 12:30 PM');
			
			ctrl.reqFormat = 'hh:mm';
			output = ctrl.getFormattedString();
			System.assertEquals(output,'12:30');
			
			Datetime myDateGMT = datetime.newInstanceGmt(2012, 12, 1, 12, 30, 2);
			ctrl.dbDateTime = myDateGMT;
			
			output = ctrl.getFormattedString();
			System.assertEquals(output,'06:30');
	    }
	    
	    testUser.LocaleSidKey = 'zh_TW'; // should use DEFAULT: 'dd/M/yyyy hh:mm'
	    update testUser;
	    
	    system.runAs(testUser){	
			Datetime myDate =
			datetime.newInstance(2012, 12, 1, 12, 30, 2);
			
			UTIL_Formatter ctrl = new UTIL_Formatter();
			ctrl.dbDateTime = myDate;
			
			String output = ctrl.getFormattedString();
			System.assertEquals(output,'01/12/2012 12:30');
	    }
    }
	
	@IsTest static void test_localNumber() {
	    User testUser = GW_User.insertTestUser();
        
        Test.startTest();
        System.runAs ( testUser ) {	
			UTIL_Formatter ctrl = new UTIL_Formatter();
			ctrl.myNumber = 12.34;
			
			String output = ctrl.getFormattedString();
			System.assertEquals(output,'12,34');
			
			ctrl.myNumber = 12.3;
			output = ctrl.getFormattedString();
			System.assertEquals(output,'12,30');
			
			ctrl.myNumber = 12;
			output = ctrl.getFormattedString();
			System.assertEquals(output,'12,00');
			
			ctrl.myNumber = 12345;
			output = ctrl.getFormattedString();
			System.assertEquals(output,'12.345,00');
			
			ctrl.myNumber = 0;
			output = ctrl.getFormattedString();
			System.assertEquals(output,'0,00');
	    }
	    
	    testUser.LocaleSidKey = 'en_US';
	    update testUser;
	    
	    system.runAs(testUser){	
			UTIL_Formatter ctrl = new UTIL_Formatter();
			ctrl.myNumber = 12.34;
			
			String output = ctrl.getFormattedString();
			System.assertEquals(output,'12.34');
			
			ctrl.myNumber = 12345;
			output = ctrl.getFormattedString();
			System.assertEquals(output,'12,345.00');
			
			ctrl.myNumber = 0;
			output = ctrl.getFormattedString();
			System.assertEquals(output,'0.00');
	    }
    }
}