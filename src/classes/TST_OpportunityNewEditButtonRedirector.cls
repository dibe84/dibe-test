@isTest
private class TST_OpportunityNewEditButtonRedirector {

    private static opportunity oppTract;
    private static opportunity oppNoTract;
    private static opportunity oppWithMemberTract;
    private static Account accWithTract;
    private static Account accNoTract;
    private static Account accWithMemberUnitEnableTract;
    private static Member__c mbTract;
    private static Member__c mbNoTract;
    private static MemberUnit__c memberUnitNoTract;
    private static MemberUnit__c memberUnitTract;
    private static Account acc;
    private static User testUser;
    
    static void createTestUser() {
        Profile testProfile = GW_User.getProfileByName('System Administrator');
        testUser = GW_User.createTestUser(testProfile);
        insert testUser;
    }
    
    static void testSetupData() {
        UserRole testRole = GW_User.getUserRole(testUser.id);
        acc = new Account(
                Name='TestAccMember',
                BillingStreet='test',
                BillingPostalCode='8883',
                BillingCountryCode='ZA',
                BillingCity='test',
                BillingCountry='South Africa', 
                BillingStateCode = 'GT',
                ownerId = testUser.Id
              );
        insert acc;
        
        //create contact 
        Contact con = GW_Contact.insertSObject('LastName', acc);
        
        //create members Tract
        List<Member__c> listMembers = new List<Member__c>();
        String memberId = testRole.DeveloperName;
        if(String.isNotEmpty(memberId) && memberId.length() > 5) {
            memberId = memberId.substring(0,5);
        }
        mbTract = new Member__c(Name='TestMemberTract', Account__c = acc.Id, MemberId__c = memberId);
        listMembers.add(mbTract);
        
        //create member no Tract
        mbNoTract = new Member__c(Name='TestMemberNoTract', Account__c = acc.Id);
        listMembers.add(mbNoTract);
        insert listMembers;
        
        //create memberUnits with Tract
        List<MemberUnit__c> listMemberUnits = new List<MemberUnit__c>();
        memberUnitTract = new MemberUnit__c(
            Name = 'Test member unit',
            Member__c = mbTract.Id, 
            LineOfBusiness__c = 'AD',
            EnableTRACT__c = true
        );
        listMemberUnits.add(memberUnitTract);
        
        //create memberUnit with Tract
        memberUnitNoTract = new MemberUnit__c(
            Name = 'Test member unit',
            Member__c=mbNoTract.Id, 
            LineOfBusiness__c='AD',
            EnableTRACT__c = false
        );
        listMemberUnits.add(memberUnitNoTract);
        insert listMemberUnits;
        
        mbTract.DefaultMemberUnit__c = memberUnitTract.Id;
        update mbTract;
        
        mbNoTract.DefaultMemberUnit__c = memberUnitNoTract.Id;
        update mbNoTract;
        
        //create account no Tract
        List<Account> listAccs = new List<Account>();
        accNoTract = new Account(
            Name='TestAccNoTract',
            BillingStreet='test',
            BillingPostalCode='8883',
            BillingCountryCode='ZA',
            BillingCity='test',
            BillingCountry='South Africa', 
            BillingStateCode = 'GT',
            Member__c = mbNoTract.Id
         );
        listAccs.add(accNoTract);
        
        //create account with Tract
        accWithTract = new Account(
            Name='TestAccTract',
            BillingStreet='test',
            BillingPostalCode='8883',
            BillingCountryCode='ZA',
            BillingCity='test',
            BillingCountry='South Africa', 
            BillingStateCode = 'GT',
            Member__c = mbTract.Id,
            Tract_AccountNumber__c = '234',
            Tract_AccountId__c = '235'
        );
        listAccs.add(accWithTract);
        
        accWithMemberUnitEnableTract = new Account(
            Name='TestAccTract',
            BillingStreet='test',
            BillingPostalCode='8883',
            BillingCountryCode='ZA',
            BillingCity='test',
            BillingCountry='South Africa', 
            BillingStateCode = 'GT',
            Member__c = mbTract.Id
        );
        listAccs.add(accWithMemberUnitEnableTract);
        insert listAccs;
        
        //create AccountMemberUnitAssociation with Tract
        List<AccountMemberUnitAssociation__c> assAccMemUnits = new List<AccountMemberUnitAssociation__c>();
        AccountMemberUnitAssociation__c amuaWithTract = new AccountMemberUnitAssociation__c();
        amuaWithTract.MemberUnit__c = memberUnitTract.Id;
        amuaWithTract.Account__c = accWithTract.Id;
        assAccMemUnits.add(amuaWithTract);
        
        //create AccountMemberUnitAssociation with Tract
        AccountMemberUnitAssociation__c amuaMemberUnitEnableTract = new AccountMemberUnitAssociation__c();
        amuaMemberUnitEnableTract.MemberUnit__c = memberUnitTract.Id;
        amuaMemberUnitEnableTract.Account__c = accWithMemberUnitEnableTract.Id;
        assAccMemUnits.add(amuaMemberUnitEnableTract);
        insert assAccMemUnits;
        
        //create opportunnity with account has Tract
        List<Opportunity> listOpps = new List<Opportunity>();
        oppTract = new Opportunity(
            name = 'TestOppTract',
            CloseDate= System.today(),
            StageName = 'Qualification',
            AccountId = accWithTract.Id,
            MemberUnit__c = memberUnitTract.Id,
            Primary_Contact__c = con.Id
        );
        listOpps.add(oppTract);
        
        oppWithMemberTract = new Opportunity(
            name = 'TestOppMemberTract',
            CloseDate= System.today(),
            StageName = 'Qualification',
            AccountId = accWithMemberUnitEnableTract.Id,
            MemberUnit__c = memberUnitTract.Id,
            Primary_Contact__c = con.Id
        );
        listOpps.add(oppWithMemberTract);
        
        //create opportunnity with account has no Tract
        oppNoTract = new Opportunity(
            name = 'TestOppNoTract',
            CloseDate= System.today(),
            StageName = 'Qualification',
            AccountId = accNoTract.Id,
            MemberUnit__c = memberUnitNoTract.Id,
            Primary_Contact__c = con.Id
        );
        listOpps.add(oppNoTract);
        insert listOpps;
    }
    
    static testMethod void testCreateNewOpportunityWithAccountHasTractNum() { 
        createTestUser();
        System.runAs(testUser){
            testSetupData();
            Test.StartTest();
                PageReference pageRef = Page.OpportunityNewEditButtonRedirector;
				pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_EDITMODE, 'false');
                pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_ACCID, oppTract.accountId);
                Test.setCurrentPage(pageRef);
    
                ApexPages.StandardController stdOpportunity =  new ApexPages.StandardController(oppTract);
                PGC_OpportunityNewEditButtonRedirector controller = new PGC_OpportunityNewEditButtonRedirector(stdOpportunity);
                
                controller.isEditMode = false;
                controller.redirect();
                
                List<Opportunity> opps = [select id from opportunity where AccountId =: accWithTract.Id];
                System.assertEquals(1, opps.size());
            
                account a = controller.acc;
                System.assertNotEquals(null, a);
                System.assertEquals(true, a.Member__r.DefaultMemberUnit__r.EnableTRACT__c);
            
                //Test Coverage
                controller.goToCurrentPage();
                
            Test.StopTest();
        }
        
    }
    
    static testMethod void testCreateNewOpportunityWithAccountNoTractNum() {
        createTestUser();
        System.runAs(testUser){
            testSetupData();
            Test.StartTest();
                PageReference pageRef = Page.OpportunityNewEditButtonRedirector;
				pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_EDITMODE, 'false');
                pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_ACCID, oppNoTract.accountId);
                Test.setCurrentPage(pageRef);
    
                ApexPages.StandardController stdOpportunity =  new ApexPages.StandardController(oppNoTract);
                PGC_OpportunityNewEditButtonRedirector controller = new PGC_OpportunityNewEditButtonRedirector(stdOpportunity);
                
                //controller.isEditMode = false;
                controller.redirect();
            
                account a = controller.acc;
                System.assertNotEquals(null, a);
                System.assertEquals(false, a.Member__r.DefaultMemberUnit__r.EnableTRACT__c);
            
            Test.StopTest();
        }
    }
    
    static testMethod void testCreateNewOpportunityWithMemberUnitEnableTract() {
        createTestUser();
        System.runAs(testUser){
            testSetupData();
            Test.StartTest();
                PageReference pageRef = Page.OpportunityNewEditButtonRedirector;
				pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_EDITMODE, 'false');
                pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_ACCID, oppWithMemberTract.accountId);
                Test.setCurrentPage(pageRef);
    
                ApexPages.StandardController stdOpportunity =  new ApexPages.StandardController(oppWithMemberTract);
                PGC_OpportunityNewEditButtonRedirector controller = new PGC_OpportunityNewEditButtonRedirector(stdOpportunity);
                
                //controller.isEditMode = false;
                //controller.redirect();
            
                //account a = controller.acc;
                //System.assertNotEquals(null, a);
                //System.assertEquals(true, a.Member__r.DefaultMemberUnit__r.EnableTRACT__c);
            
            Test.StopTest();
        }
    }
    
    static testMethod void testEditOpportunityWithMemberUnitEnableTract() {
        createTestUser();
        System.runAs(testUser){
            testSetupData();
            Test.StartTest();
                PageReference pageRef = Page.OpportunityNewEditButtonRedirector;
				pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_ACCID, oppTract.accountId);
                pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_EDITMODE, 'true');
                Test.setCurrentPage(pageRef);
    
                ApexPages.StandardController stdOpportunity =  new ApexPages.StandardController(oppTract);
                PGC_OpportunityNewEditButtonRedirector controller = new PGC_OpportunityNewEditButtonRedirector(stdOpportunity);
                
                controller.isEditMode = true;
                controller.redirect();
            
                opportunity opp = controller.opp;
                System.assertNotEquals(null, opp);
                MemberUnit__c mbunit = [select id, EnableTRACT__c from MemberUnit__c where id =: opp.MemberUnit__c];
                System.assertEquals(true, mbunit.EnableTRACT__c);
            
            Test.StopTest();
        }
    }
    
    static testMethod void testEditOpportunityWithMemberUnitUnenableTract() {
        createTestUser();
        System.runAs(testUser){
            testSetupData();
            Test.StartTest();
                PageReference pageRef = Page.OpportunityNewEditButtonRedirector;
				pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_EDITMODE, 'true');
                pageRef.getParameters().put(PGC_OpportunityNewEditButtonRedirector.PARAM_ACCID, oppNoTract.accountId);
                Test.setCurrentPage(pageRef);
    
                ApexPages.StandardController stdOpportunity =  new ApexPages.StandardController(oppNoTract);
                PGC_OpportunityNewEditButtonRedirector controller = new PGC_OpportunityNewEditButtonRedirector(stdOpportunity);
                 
                controller.isEditMode = true;
                controller.redirect();
            
                opportunity opp = controller.opp;
                System.assertNotEquals(null, opp);
                System.assertEquals(false, opp.MemberUnit__r.EnableTRACT__c);
            
            Test.StopTest();
        }
    }
    
    static testMethod void testCreateOpportunityFromListView() {
        createTestUser();
        System.runAs(testUser){
            testSetupData();
            Test.StartTest();
                PageReference pageRef = Page.OpportunityNewEditButtonRedirector;
                Test.setCurrentPage(pageRef);
                ApexPages.StandardController stdOpportunity =  new ApexPages.StandardController(oppTract);
                PGC_OpportunityNewEditButtonRedirector controller = new PGC_OpportunityNewEditButtonRedirector(stdOpportunity);
                controller.isEditMode = false;
                controller.fromListView = true;
                controller.redirect();
                //Test Coverage
                controller.listAccsOptions = new list<Account>{accWithTract, accWithMemberUnitEnableTract, accNoTract} ;
                controller.searchStr = 'Test';
                controller.searchAccount();
                pageRef.getParameters().put('selAccId', accWithTract.Id);
                controller.setSelectedAccId();
                controller.doNext();
                System.assertEquals(accWithTract.Id, controller.selectedAccId);
            Test.StopTest();
        }
    
    }
}