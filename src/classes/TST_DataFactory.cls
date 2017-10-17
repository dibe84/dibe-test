public class TST_DataFactory {
    
    //Changing on member unit sharing to private caused profile error, we need to enforce profile as admin
    //private final static String ADSALESPROFILENAME = 'Ad Sales Rep';    
    private final static String ADSALESPROFILENAME = 'System Administrator';
    private final static String ADMINPROFILENAME = 'System Administrator';
    
    private final static String TESTUSERNAME = 'MyTestUser_TST_AdSalesIO@ecgtests.com';
    private final static String TESTADMINUSERNAME = 'ADMIN_MyTestUser_TST_AdSalesIO@ecgtests.com';
    private final static String ADSALESROLENAME = 'TTCLGAD';
    private final static String AUTOMOTIVEROLENAME = 'TTCLGAU';
    private final static String COUNTRYROLENAME = 'TTCLG';

    private static TST_DataFactory instance = null;

    public User testUser;
    public User adminUser;
    public Account acc;
    public Contact con;
    //public Member__c member;
    //public Product2 prod;
    //public PricebookEntry pbe;
    public Opportunity opp;
    public OpportunityLineItem oli1;
    public OpportunityLineItem oli2;

    public static Date startOli1 = Date.newInstance(2030,1,1);
    public static Date endOli1 = Date.newInstance(2030,6,30);
    public static Date startOli2 = Date.newInstance(2030,1,31);
    public static Date endOli2 = Date.newInstance(2030,6,1);

    public Integer numDaysPeriod1;
    public Integer numDaysPeriod2;
    public Integer numMonthsPeriod1;
    public Integer numMonthsPeriod2;

    public List<Rev__c> revs;
    public List<RS__c> rss;
    public List<Metric__c> metrics;
    public List<Invoice__c> invoices;
    public List<InvoiceLine__c> invoiceLines;
    public SIC__c sic;
    
    public Case cs;
    public EmailMessage emailMessage;    
    public static Id accountMemberRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
    
    // instantiate via getInstance, only after first running createTestSet() from @testSetup.
    private TST_DataFactory() {
        this.testUser = (User) GW_sObject.queryRecords('User', 'UserName = \''+TST_DataFactory.TESTUSERNAME+'\'')[0];
        this.adminUser = (User) GW_sObject.queryRecords('User', 'UserName = \''+TST_DataFactory.TESTADMINUSERNAME+'\'')[0];

        queryResults();
    }

    // a static method that returns the instance of the record type
    public static TST_DataFactory getInstance() {
        if(instance == null) instance = new TST_DataFactory();
        return instance;
    }

    // use this static method for creating the testData in @testSetup method
    public static void createTestSet() {
        UTIL_CustomJob.createTestCustomJobs(); // create custom async jobs
        createMembers(); // create member and memberunits
        createCustomLabels();
        createCustomSettings();
        
        User testUser,adminUser;
        User thisUser = new User(Id = UserInfo.getUserId());
        System.runAs ( thisUser ) {
            createRoleStructure();

            List<User> users = new List<User>();
            testUser = GW_User.createTestUser(TESTUSERNAME, ADSALESROLENAME, ADSALESPROFILENAME );
            adminUser = GW_User.createTestUser(TESTADMINUSERNAME, COUNTRYROLENAME, ADMINPROFILENAME );
            users.add(testUser);
            users.add(adminUser);
            insert users;
        }

        //User testUser = (User) GW_sObject.queryRecords('User', 'UserName = \''+TST_DataFactory.TESTUSERNAME+'\'')[0];
        //User adminUser = (User) GW_sObject.queryRecords('User', 'UserName = \''+TST_DataFactory.TESTADMINUSERNAME+'\'')[0];

        System.runAs ( testUser ) {

            Account acc = GW_Account.insertSObject();
            Contact con = GW_Contact.insertSObject('LastName', acc);
            con.Primary__c=true;
            con.isActive__c=true;
            update con;
            createSIC();
            acc.Finance_contact__c = con.Id;
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Advertiser').getRecordTypeId();
            update acc;
            Product2 prod = GW_Product.insertSObject('Banners');
            PricebookEntry pbe = GW_Product.insertPricebookEntry( prod, new Pricebook2(id=Test.getStandardPricebookId()), 10.00);
            Opportunity opp = GW_Opportunity.insertSObject(acc, con);

            opp = (Opportunity) GW_sObject.queryRecords(GW_sObject.getobjectNameFromId(opp.Id), new Set<Id>{opp.Id})[0]; //Get all fields information

            generateOppLineItems(opp, pbe, startOli1, endOli1, startOli2, endOli2);
            
        }
    }

    private static void generateOppLineItems(Opportunity opp, PriceBookEntry pbe, Date period1Start, Date period1End, Date period2Start, Date period2End) {
        OpportunityLineItem oli1 = GW_OpportunityLineItem.createSObject(opp, pbe, 10, 10);
        OpportunityLineItem oli2 = GW_OpportunityLineItem.createSObject(opp, pbe, 12, 15);

        oli1.from_Date__c = period1Start;
        oli1.until_Date__c= period1End;
        oli1.Billing_Category__c = 'CPD';
        oli1.SalesPriceNet__c = oli1.UnitPrice;
        oli1.Description = 'TST Description1';
        oli1.UniqueLineDescription__c = 'TSTUniqueLineDescription1';

        oli2.from_Date__c = period2Start;
        oli2.until_Date__c= period2End;
        oli2.Billing_Category__c = 'CPM';
        oli2.SalesPriceNet__c = oli2.UnitPrice;
        oli2.Description = 'TST Description2';
        oli2.UniqueLineDescription__c = 'TSTUniqueLineDescription2';

        insert new List<OpportunityLineItem>{oli1, oli2};
    }

    private static void createRoleStructure() {
        List<UserRole> memberUnitRoles = new List<UserRole>();
        UserRole countryLevelRole = new UserRole(Name='Test Country Level Role', DeveloperName='TTCLG');
        insert countryLevelRole;
        memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (Adsales)', ParentRoleId=countryLevelRole.Id, DeveloperName='TTCLGAD'));
        memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (Automotive)', ParentRoleId=countryLevelRole.Id, DeveloperName='TTCLGAU'));
        insert memberUnitRoles;
    }

    private static void createMembers() {
        Account memberAccount = new Account(RecordTypeId=accountMemberRecordTypeId, name='MemberAccount', BillingCountry='Netherlands', ShippingCountry='Italy');
        insert memberAccount;
        Member__c member = GW_Member.insertSObject('Test Member', 'TTCLG',memberAccount);
        List<MemberUnit__c> memberUnits = new List<MemberUnit__c>();
        memberUnits.add(GW_MemberUnit.insertObject(member.Id, 'Test Adsales', 'AD'));
        memberUnits.add(GW_MemberUnit.insertObject(member.Id, 'Test Automotive', 'AU'));
        member = [SELECT Id, DefaultMemberUnit__c FROM Member__c WHERE Id=:member.Id];
        member.DefaultMemberUnit__c = memberUnits[1].Id;
        update member;
    }

    public void queryResults() {
        List<Account> accs = GW_sObject.queryRecords('Account', 'RecordTypeId <> \''+accountMemberRecordTypeId+'\''); // skip the created Member Account record
        //UTIL.log('Accs: '+accs);
        system.assertEquals(1,accs.size()); // check if test set was created correctly
        this.acc = accs[0];

        List<Opportunity> opps = GW_sObject.queryRecords('Opportunity', '');
        system.assertEquals(opps.size(),1);
        this.opp = opps[0];
        this.con = (Contact)GW_sObject.queryRecords('Contact', '')[0];
        List<OpportunityLineItem> olis = GW_sObject.queryRecords('OpportunityLineItem', '');
        system.assertEquals(olis.size(),2);
        for (OpportunityLineItem oli : olis) {
            if (oli.from_Date__c == startOli1) this.oli1 = oli;
            if (oli.from_Date__c == startOli2) this.oli2 = oli;
        }

        if (this.oli1 != null && this.oli2!=null) {
            this.numDaysPeriod1 = this.oli1.from_Date__c.daysBetween(this.oli1.until_Date__c) + 1;
            this.numDaysPeriod2 = this.oli2.from_Date__c.daysBetween(this.oli2.until_Date__c) + 1;
            this.numMonthsPeriod1 = this.oli1.from_Date__c.monthsBetween(this.oli1.until_Date__c)+1;
            this.numMonthsPeriod2 = this.oli2.from_Date__c.monthsBetween(this.oli2.until_Date__c)+1;
        }

        this.revs = GW_sObject.queryRecords('Rev__c', '');
        this.rss = GW_sObject.queryRecords('RS__c', '');
        this.metrics = GW_sObject.queryRecords('Metric__c', '');
        this.invoices = GW_sObject.queryRecords('Invoice__c', '');
        this.invoiceLines = GW_sObject.queryRecords('InvoiceLine__c', '');
        this.sic = (SIC__c)GW_sObject.queryRecords('SIC__c', '')[0];
    }

    public static void completeContactdetails(Contact con) {
        con.Email   = 'contact@email.com';
        con.Phone   = '+012324567891';
        con.Salutation = 'Mr';
        update con;
    }

    public static void completeAccountDetails(Account acc, Contact con) {
        acc.Name                = acc.Name+'Changed';
        acc.AccountExtId__c     = 'GTTEST01234';
        acc.Account_Status__c   = 'Status';
        acc.BillingStreet       = 'Street';
        acc.BillingPostalCode   = '12345';
        acc.BillingCity         = 'City';
        acc.BillingCountryCode  = 'US';
        acc.Account_Status__c   = 'Active';
        acc.Billing_Preference__c = 'Invoice';
        acc.FQ_CmrType__c = 'Banners';
        acc.Billing_Preference__c = 'Direct Debit';
        acc.Bank_AccountNumber__c = 'BE23776592232991';
        acc.Bank_Name__c = 'BELFIUS BANK';
        acc.BillingPreferenceValidFrom__c = Date.today(); //date
        acc.MandateId__c = 'THBEL0000000585-00000001';
        update acc;
    }

    public static void changeAccountDetails(Account acc, Contact con) {
        acc.Name        = acc.Name+'Changed';
        acc.AccountExtId__c     = 'GTTEST01234';
        acc.Account_Status__c   = 'Status';
        acc.BillingStreet       = 'Street';
        acc.BillingPostalCode   = '12345';
        acc.BillingCity         = 'Anothercity';
        acc.BillingCountryCode  = 'NL';
        acc.BillingCountry = 'Netherlands';
        acc.Account_Status__c   = 'Active';
        acc.Billing_Preference__c = 'Invoice';
        acc.FQ_CmrType__c = 'Banners';
        acc.Billing_Preference__c = 'Direct Debit';
        acc.Bank_AccountNumber__c = 'BE23776592232991';
        acc.Bank_Name__c = 'BELFIUS BANK';
        acc.BillingPreferenceValidFrom__c = Date.today(); //date
        acc.MandateId__c = 'THBEL0000000585-00000001';
        update acc;
    }

    private static void createSIC(){
        SIC__c sic = new SIC__c(Name='Test SicCode', Code__c='7374');
        insert sic;
    }

    public static void createCustomLabels(){
        List<Custom_ECG_Labels__c> customLabels = new List<Custom_ECG_Labels__c>();
        customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_' + ADSALESROLENAME, Value__c='TEST IO SUBJECT'));
        customLabels.add(new Custom_ECG_Labels__c(Name='IOName_' + ADSALESROLENAME, Value__c='TEST IO NAME'));
        customLabels.add(new Custom_ECG_Labels__c(Name='MandateSubject_' + AUTOMOTIVEROLENAME , Value__c='TEST Mandate Subject'));
        customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_xxxxxx', Value__c='TEST IO SUBJECT'));


        Insert customLabels;
    }

    public static void createCustomSettings(){
        
        DNB_Settings__c dnbSettings = new DNB_Settings__c( Name = 'DNBaccess' );
        dnbSettings.xsi__c = 'xsi__c';
        dnbSettings.DUNSservice__c = 'DUNSservice__c';
        dnbSettings.CreditService__c = 'CreditService__c';
        dnbSettings.soapNS__c = 'soapNS__c';
        dnbSettings.serviceNS1__c = 'serviceNS1__c';
        dnbSettings.serviceNS2__c = 'serviceNS2__c';
        dnbSettings.Username__c = 'Username__c';
        dnbSettings.Password__c = 'Password__c';
        
        insert dnbSettings;
    }

    // CUSTOM ATTRIBUTES - RELATED - PROBABLY CAN BE MADE MORE GENERIC

    public static void createMemberUnit(Id accountId){
        //create member
        Member__c mb = new Member__c(Name='Test member', Account__c = accountId);
        insert mb;
        //create memberUnit
        MemberUnit__c memberUnit = new MemberUnit__c(Name = 'Test member unit', Member__c=mb.Id, LineOfBusiness__c='AD');
        insert memberUnit;
    }

    public static void createBasicAccount(Integer numAccs)
    {
        List<Account> accList = new List<Account>();
        for(Integer i=0; i<numAccs; i++)
        {
            Account acc = new Account(
                        Name='Test Acc'+i,
                        //Country_Code__c='DE',
                        BillingStreet='Street',
                        BillingPostalCode='1Nl1',
                        BillingCountryCode='NL',
                        BillingCity='City'
                      );
            accList.add(acc);
        }
        insert accList;
    }

    public static void createBasicContact(Account acc) {
        Contact con = GW_Contact.insertSObject('testLastName', acc);
    }

    public static void createCustomAttributeForLead(Id cadId, String key, Id leadId) {
        CustomAttribute__c ca = new CustomAttribute__c();
        ca.Lead__c = leadId;
        ca.Name = key;
        ca.CustomAttributeDefinition__c = cadId;

        insert ca;
    }

    public static void createLead(String lName, String cName, Id memberId, Id memberUnitId) {
        Lead testLead = new Lead();
        testLead.Member__c = memberId;
        testLead.MemberUnit__c = memberUnitId;
        testLead.LastName = lName;
        testLead.Company = cName;

        insert testLead;
    }

    public static void createAccountMemberUnitAssociation(Id memberUnitId, Id accId) {
        AccountMemberUnitAssociation__c amua = new AccountMemberUnitAssociation__c();
        amua.MemberUnit__c = memberUnitId;
        amua.Account__c = accId;
        insert amua;
    }

    public static CustomAttribute__c createCustomAttributeForAccount(CustomAttributeDefinition__c cad, String key, Id accId) {
        CustomAttribute__c ca = new CustomAttribute__c();
        ca.Account__c = accId;
        ca.Name = key;
        ca.CustomAttributeDefinition__c = cad.Id;
        ca.ValueType__c = cad.AttributeType__c;

        insert ca;

        return ca;
    }

    public static CustomAttributeDefinition__c createCustomAttributeDefinition(Id memberUnitId, String objectType, String attributeType) {
        CustomAttributeDefinition__c cad = new CustomAttributeDefinition__c();
        cad.MemberUnit__c = memberUnitId;
        cad.Object__c = objectType;
        cad.AttributeType__c = attributeType;

        insert cad;

        return cad;
    }

    public static CustomAttributeDefinition__c createCustomAttributeDefinitionRelation(Id memberUnitId, String objectType, String relationshipTarget) {
        CustomAttributeDefinition__c cad = new CustomAttributeDefinition__c();
        cad.MemberUnit__c = memberUnitId;
        cad.Object__c = objectType;
        cad.AttributeType__c = 'Relationship';
        cad.RelationshipTarget__c = relationshipTarget;

        insert cad;

        return cad;
    }
    
    public static Contact createPrimaryContact(String lastName, Boolean isPrimary, String roleName, Account acc){
        Contact con1 = GW_contact.createSObject(lastName, acc);
        con1.Role__c = roleName;
        con1.Primary__c = isPrimary;
        con1.isActive__c = true;
        insert con1;
        return con1;
    }
    
    public void createCase(String subject) {
        cs = new Case(Subject = subject, SuppliedEmail = 'TST_createCase@test.com',  SuppliedName = 'TST_createCase', SuppliedPhone = '+1234567890', Origin = 'Web');  
        insert cs;
    }
    
    public void createEmailMessage(String subject) {
        emailMessage = new EmailMessage();
        emailMessage.Subject = subject;
        emailMessage.TextBody = 'TST_emailMessage_Body';
        emailMessage.FromAddress = 'TST_createCase@test.com';
        if (cs == null) {
            createCase(emailMessage.Subject);
        }
        
        emailMessage.ParentId = cs.Id;
        insert emailMessage;
    }
    public static void insertAccountMemberUnitAssociation(Id accId, Id memberUId){
        insert new AccountMemberUnitAssociation__c(Account__c = accId, MemberUnit__c = memberUId);
    }

}