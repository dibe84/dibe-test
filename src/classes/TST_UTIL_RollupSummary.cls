@isTest
public class TST_UTIL_RollupSummary {
    @IsTest static void myUnitTest() {

        Profile pf = [Select Id from Profile where Name = 'System Administrator' or Name = 'Systeembeheerder'];
        UserRole role = GW_USER.getRolesMap().values().get(0);
        
        Set<ID> tstAccounts = new Set<ID>();
 
        User u = new User();
        u.UserRoleId = role.Id;
        u.FirstName = 'Test';
        u.LastName = 'User';
        u.Email = 'testuser@test123456789.com';
        u.CompanyName = 'test.com';
        u.Title = 'Test User';
        u.Username = 'testuser@test123456789.com';
        u.Alias = 'testuser';
        u.CommunityNickname = 'Test User';
        u.TimeZoneSidKey = 'America/Mexico_City';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.ProfileId = pf.Id;
        u.LanguageLocaleKey = 'en_US';
        insert u;
 
        system.runAs(u){
           Webservice_Settings__c setting = new Webservice_Settings__c();
           setting.Name = 'Webservice';
           insert setting;
            
            Test.startTest();
            //create account
            Account member = new Account();
            member.Name = 'TestMember';
            insert member;
            
            Member__c mb1 = new Member__c(Account__c=member.Id, MemberId__c='GTZAF');
            Member__c mb2 = new Member__c(Account__c=member.Id, MemberId__c='GTAUS');
            insert mb1;
            insert mb2;

            //create account
	        Account testAcc1 = new Account();
	        testAcc1.Name = 'TestAcc1';
	        insert testAcc1;
 
            Contact testContact1 = new Contact(Lastname='TestContact1', AccountId=testAcc1.Id);
            insert testContact1;
            
            Account testAcc2 = new Account();
	        testAcc2.Name = 'TestAcc2';
	        insert testAcc2;
 
            Contact testContact2 = new Contact(Lastname='TestContact2', AccountId=testAcc2.Id);
            insert testContact2;
            
            Contact testContact3 = new Contact(Lastname='TestContact3', AccountId=testAcc2.Id);
            insert testContact3;
            
            tstAccounts.add(testAcc1.Id);
            tstAccounts.add(testAcc2.Id);
            
            list<UTIL_RollupSummary.fieldDefinition> fieldDefinitions = new list<UTIL_RollupSummary.fieldDefinition> 
			{ new UTIL_RollupSummary.fieldDefinition('COUNT', 'Id', 'AnnualRevenue') };
        	
        	// scenario added 3 contact to 2 accounts
        	UTIL_RollupSummary.rollUpTrigger(fieldDefinitions, tstAccounts, 'Contact', 'AccountId', 'Account', '');
 
			testAcc1 = [select id, Name, AnnualRevenue from Account Where id =:testAcc1.Id];
			testAcc2 = [select id, Name, AnnualRevenue from Account Where id =:testAcc2.Id];
			 
            system.assertEquals(testAcc1.AnnualRevenue,1);
            system.assertEquals(testAcc2.AnnualRevenue,2);
            
            // deleted 1 contact from acc1
            delete testContact1;
            
            UTIL_RollupSummary.rollUpTrigger(fieldDefinitions, tstAccounts, 'Contact', 'AccountId', 'Account', '');
 
			testAcc1 = [select id, Name, AnnualRevenue from Account Where id =:testAcc1.Id];
			testAcc2 = [select id, Name, AnnualRevenue from Account Where id =:testAcc2.Id];
			
            system.assertEquals(testAcc1.AnnualRevenue,0);
            system.assertEquals(testAcc2.AnnualRevenue,2);
            Test.stopTest();
        }
    }
}