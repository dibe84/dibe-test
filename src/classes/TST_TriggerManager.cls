@isTest
private class TST_TriggerManager { 
	
	@isTest static void testVirtualMethods() {
        Profile pf = GW_User.getProfileByName('System Administrator');
        User u = GW_User.createTestUser(pf, 'triggermanager_user1@test.org');
        insert u;
		
        Test.startTest();
        system.runAs(u) {
            List<Account> lstAccount = new List<Account>();

            Account testAcc1 = GW_Account.createSObject('TestAcc1');
            insert testAcc1;
            lstAccount.add(testAcc1);

            Account testAcc2 = GW_Account.createSObject('TestAcc2');
            insert testAcc2;
            lstAccount.add(testAcc2); 

            TriggerManager.TriggerHandler t = new TriggerManager.TriggerHandler('testVirtualMethods', Account.sObjectType);
            Boolean noErrors = false;

            try {
                t.bulkAfter( lstAccount, new Map<Id, Account>(lstAccount), new Map<Id, Account>(lstAccount));
                t.bulkBefore(lstAccount, new Map<Id, Account>(lstAccount), new Map<Id, Account>(lstAccount));
                t.beforeInsert((SObject) testAcc1);
                t.beforeUpdate((SObject) testAcc1, (SObject) testAcc1);
                t.beforeDelete(testAcc1);

                t.afterDelete(testAcc1);
                t.afterInsert(testAcc1);
                t.afterUndelete(testAcc1);
                t.afterUpdate(testAcc1, testAcc1);
                t.andFinally();
                noErrors = true;

            } catch ( TriggerManager.TriggerException te) {
                UTIL.log( 'error in TriggerManager - testVirtualMethods: ' + te.getMessage() );
            }
            Test.stopTest();
            System.assert(noErrors, true);

        }
    }

    @isTest static void testMissingHandler() {
        Profile pf = GW_User.getProfileByName('System Administrator');
        User u = GW_User.createTestUser(pf, 'triggermanager_user2@test.org');
        insert u;
		
        Test.startTest();
        system.runAs(u) {
            // check for missing Handler
            try {
                TriggerManager.createHandler(GW_Account.class); 
            } catch ( TriggerManager.TriggerException te) {
                System.assert( te.getMessage().contains('Not a valid Trigger Handler') );
            }
        }
        Test.stopTest();
    }
    
    @isTest static void testHNDL_Campaign() {
        
        Profile pf = GW_User.getProfileByName('System Administrator');
        User u = GW_User.createTestUser(pf, 'triggermanager_user2@test.org');
        insert u;

        Test.startTest();
        system.runAs(u) {
            
            //Create Account
            Account testAcc1 = GW_Account.createSObject('TestAcc1');
            insert testAcc1;
            
            // Create members 
            List<Member__c> memberList = new List<Member__c>();
            memberList.add(new Member__c(Name='EBAYK', Account__c = testAcc1.Id));
            insert memberList;
            
            // Create member units
            List<MemberUnit__c> memberUnitList = new List<MemberUnit__c>();
            memberUnitList.add(new MemberUnit__c(Name = 'EBAYK member unit', Member__c=memberList.get(0).Id, LineOfBusiness__c='AD'));
            insert memberUnitList;
    
            // Create campaign
            Campaign camp = new Campaign();
            camp.Name = 'Test Campaign';
            camp.MailBetweenStart__c = '00:00';
            camp.MailBetweenEnd__c = '23:59';
            camp.Sender__c = 'test@test.com';
            camp.EmailTemplateContact__c = 'Contact_Template';
            camp.EmailTemplateLead__c = 'Lead_Template';
            camp.Landing_Page__c = 'http://test.com';
            camp.Type = 'Email';
            camp.Member__c = memberUnitList[0].Member__c;
            camp.MemberUnit__c = memberUnitList[0].Id;   
        	insert camp;
            
        }
        Test.stopTest();
        
        
    }
	
}