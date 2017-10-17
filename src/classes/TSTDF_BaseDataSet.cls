public virtual class TSTDF_BaseDataSet {
    //Changing on member unit sharing to private caused profile error, we need to enforce profile as admin
    //public String ADSALESPROFILENAME            = 'Ad Sales Rep';
    //public String VERTICALPROFILENAME           = 'Automotive Sales Rep';
    public String ADSALESPROFILENAME            = 'System Administrator';
    public String VERTICALPROFILENAME           = 'System Administrator';
    public String ADMINPROFILENAME              = 'System Administrator';

    public String TESTUSERNAME                  = 'MyTestUser_TST_AdSalesIO@ecgtests.com';
    public String VERTICALTESTUSERNAME          = 'VERTICALTESTUSER@ecgtests.com';
    public String TESTADMINUSERNAME             = 'ADMIN_MyTestUser_TST_AdSalesIO@ecgtests.com';

    public String ADSALESROLENAME               = 'THBE2AD'; //Change to use with correct ROLE
    public String VERTICALROLENAME              = 'THBELAU_Rep';
    public String COUNTRYROLENAME               = 'THBEL';
    public String GTAUSROLENAME                 = 'GTAUSAD';
    public String ECITAROLENAME                 = 'ECITAAU';
    

    public static Map<String,RecordType> recordTypeNameMap {
        get {
            if (recordTypeNameMap == null) {
                List<RecordType> recordTypes = (List<RecordType>) GW_sObject.queryRecords('RecordType', '');
                Map<String,RecordType> recordTypeNameMap = new Map<String,RecordType>();
                for (RecordType rt : recordTypes) {
                    recordTypeNameMap.put(rt.sObjectType + '_' + rt.DeveloperName, rt);
                }
                return recordTypeNameMap;
            } else {
                return recordTypeNameMap;
            }
        }
    }

    public List<UserRole> constructRoleStructure(){
        List<UserRole> memberUnitRoles = new List<UserRole>();
        /*
        UserRole countryLevelRole = new UserRole(Name='Test Country Level Role', DeveloperName=COUNTRYROLENAME);
        insert countryLevelRole;
        memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (Adsales)', ParentRoleId=countryLevelRole.Id, DeveloperName=ADSALESROLENAME));
        memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (Automotive)', ParentRoleId=countryLevelRole.Id, DeveloperName=VERTICALROLENAME));
        UserRole countryLevelRole = [SELECT Id FROM UserRole WHERE DeveloperName=:COUNTRYROLENAME];
        memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (Adsales)', ParentRoleId=countryLevelRole.Id, DeveloperName=ADSALESROLENAME)); //Create Correct Role
        */
        
        map<String,string> mapDevNameROLEID = new map<String,string>{
                                                        COUNTRYROLENAME => '', 
                                                        VERTICALROLENAME => '',
                                                        GTAUSROLENAME => '',
                                                        ECITAROLENAME => '',
                                                        ADSALESROLENAME => ''
                                                    };
        
        for(UserRole userRole : [SELECT Id,DeveloperName FROM UserRole WHERE DeveloperName in: mapDevNameROLEID.keySet()]){
            mapDevNameROLEID.put(userRole.DeveloperName, userRole.ID);
        }
        
        UserRole countryLevelRole;
        if ( String.isBlank(mapDevNameROLEID.get(COUNTRYROLENAME))){
            countryLevelRole = new UserRole(Name='Test Country Level Role', DeveloperName=COUNTRYROLENAME);
            insert countryLevelRole;
        }
        else{
            countryLevelRole = new UserRole(id = mapDevNameROLEID.get(COUNTRYROLENAME));
        }
        
        if (String.isBlank(mapDevNameROLEID.get(ADSALESROLENAME))) memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (Adsales)', ParentRoleId=countryLevelRole.Id, DeveloperName=ADSALESROLENAME)); //Create Correct Role
        if (String.isBlank(mapDevNameROLEID.get(VERTICALROLENAME))) memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (Automotive)', ParentRoleId=countryLevelRole.Id, DeveloperName=VERTICALROLENAME));
        if (String.isBlank(mapDevNameROLEID.get(GTAUSROLENAME)))    memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (GTAUS)', ParentRoleId=countryLevelRole.Id, DeveloperName=GTAUSROLENAME)); 
        if (String.isBlank(mapDevNameROLEID.get(ECITAROLENAME)))    memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (ERICTA)', ParentRoleId=countryLevelRole.Id, DeveloperName=ECITAROLENAME));
        
        return constructRoleStructure(memberUnitRoles);
    }

    public virtual List<UserRole> constructRoleStructure(List<UserRole> memberUnitRoles){
        return memberUnitRoles;
    }

    public Map<String, User> constructUserMap(){
        Map<String, User> userMap = new Map<String, User>();
        userMap.put( 'testUser', GW_User.createTestUser(TESTUSERNAME, ADSALESROLENAME, ADSALESPROFILENAME ) );
        userMap.put( 'testVertUser', GW_User.createTestUser(VERTICALTESTUSERNAME, VERTICALROLENAME, VERTICALPROFILENAME ) );
        userMap.put( 'testAdmin',GW_User.createTestUser(TESTADMINUSERNAME, COUNTRYROLENAME, ADMINPROFILENAME ) );
        return constructUserMap(userMap);
    }

    public virtual Map<String, User> constructUserMap(Map<String, User> userMap) {
        return userMap;
    }

    public List<Account> constructAccounts(Member__c member){
        List<Account> accounts = new List<Account>();
        Account acc = new Account(Name='Test Account', Member__c = member.Id);
        acc.AccountExtId__c = member.MemberId__c +  acc.AccAutoNumber__c;
        accounts.add(acc);

        return constructAccounts(accounts);
    }

    public virtual List<Account> constructAccounts(List<Account> accounts) {
        return accounts;
    }

    public List<Lead> constructLeads(Id ownerId , Id memberId , Id memberUnitId){
        List<Lead> leads = new List<Lead>();
        Lead l = new Lead(LastName='Test Lastname', 
                          Company='Test Company', 
                          Member__c=memberId,
                          MemberUnit__c=memberUnitId,
                          OwnerId=ownerId);
        leads.add(l);

        return constructLeads(leads);
    }

    public virtual List<Lead> constructLeads(List<Lead> leads) {
        return leads;
    }

    public List<Contact> constructContacts(Account acc){
        List<Contact> contacts = new List<Contact>();

        contacts.add(new Contact(LastName='lastName',
                           AccountId=acc.Id,
                           Email='testemail@test.org',
                           Salutation='Mr.'
                          ));

        return constructContacts(contacts);
    }

    public virtual List<Contact> constructContacts(List<Contact> contacts) {
        return contacts;
    }

    public List<Product2> constructProducts(){

        List<Product2> products = new List<Product2>();

        String productName = 'TestProduct';
        Product2 product = new Product2(Name=productName,
                                Product_Type__c=productName,
                                Product_SubType__c=productName,
                                Billing_Category__c = 'CPM_Delivery;CPM_DailyFixed;CPD_Delivery;CPD_DailyFixed;CPC_Delivery;ServiceFee_OneTime;ServiceFee_MonthlyFixed;Subscription_MonthlyProRata');
        products.add(product);
        return constructProducts(products);
    }

    public virtual List<Product2> constructProducts(List<Product2> products){
        return products;
    }

    public List<PriceBookEntry> constructPriceBookEntries(Product2 product) {
        List<PriceBookEntry> pbes = new List<PriceBookEntry>();
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = product.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 10.0,
            IsActive = true
        );
        pbes.add(pbe);
        return constructPriceBookEntries(pbes);
    }

    public virtual List<PriceBookEntry> constructPriceBookEntries(List<PriceBookEntry> pbes) {
        return pbes;
    }

    public Account constructMemberAccount() {
        Account acc = new Account(
            RecordTypeId=recordTypeNameMap.get('Account_Member').Id,
            name='MemberAccount',
            BillingCountry='Netherlands',
            ShippingCountry='Italy'
        );
        return constructMemberAccount(acc);
    }
    public virtual Account constructMemberAccount(Account acc) { return acc; }

    public Member__c constructMember(Id accountId) {
        Member__c member = new Member__c(
            Name='Test Member',
            MemberId__c=COUNTRYROLENAME,
            Account__c=accountId,
            FQ_CmrType__c='Email template Banners'
        );
        return constructMember(member);
    }
    public virtual Member__c constructMember(Member__c member) { return member; }

    public MemberUnit__c constructMemberUnit(Id memberId, String name, String lineOfBusiness) {
        MemberUnit__c memberUnit = new MemberUnit__c(
            Member__c=memberId,
            Name=name,
            LineOfBusiness__c = lineOfBusiness
        );
        return constructMemberUnit(memberUnit);
    }
    public virtual MemberUnit__c constructMemberUnit(MemberUnit__c memberUnit) { return memberUnit; }

    public List<RecordRestrictions__c> constructRecordRestrictions() {
         List<RecordRestrictions__c> recordRestrictions = new List<RecordRestrictions__c> {
                new RecordRestrictions__c(Name= 'Lock RS when Invoice Sent', LineOfBusiness__c= null,LockedFields__c= 'Invoice__c,From_Date__c,Until_Date__c,Revenue__c,QuantityBilled__c,QuantityDelivered__c',LockRecord__c= true,
                                          Message__c= 'Invoice has been sent to billing for depending RS.',ObjectName__c= 'RS__c',Profiles__c= null,Active__c= true,StatusNumbers__c= '7,8,9'),
                new RecordRestrictions__c(Name= 'Lock Invoices Sent', LineOfBusiness__c= null, LockedFields__c= 'Amount__c,NumLineItems__c,MinInvLineStatus__c', LockRecord__c= true,
                                          Message__c= 'Invoice has been sent to billing.',ObjectName__c= 'Invoice__c',Profiles__c= null,Active__c= true,StatusNumbers__c= '7,8,9,10,11'),
                new RecordRestrictions__c(Name= 'InvoiceLine restrictions',LineOfBusiness__c= null,LockedFields__c= 'NumStatus__c,UniqueKey__c,FQ_SyncTimestamp__c,FQ_SyncStatus__c,Invoice__c,Amount__c',LockRecord__c= true,
                                          Message__c= 'InvoiceLine has been sent to Billing',ObjectName__c= 'InvoiceLine__c',Profiles__c= null,Active__c= true,StatusNumbers__c= '7,8,9'),
                new RecordRestrictions__c(Name= 'Opportunity key fields restrictions',LineOfBusiness__c= null,LockRecord__c= false,LockedFields__c='Lost__c,Billing_Account__c,Primary_Contact__c,CloseDate',
                                          Message__c= 'Key fields cannot be changed after the opportunity was signed.',ObjectName__c= 'Opportunity',Profiles__c= null,Active__c= true,StatusNumbers__c= '2,3,4,5'),
                new RecordRestrictions__c(Name= 'Opportunity Deletion Restriction',LineOfBusiness__c= null,LockedFields__c= null,LockRecord__c= true,
                                          Message__c= 'Opportunity cannot be deleted',ObjectName__c= 'Opportunity',Profiles__c= null,Active__c= true,StatusNumbers__c= '1,2,3,4,5')
        };
        return constructRecordRestrictions(recordRestrictions);
    }

    public virtual List<RecordRestrictions__c> constructRecordRestrictions(List<RecordRestrictions__c> recordRestrictions ) {
        return recordRestrictions;
    }

    public List<Webservice_Settings__c> constructWebserviceSettings(){
        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        return constructWebserviceSettings(wss);
    }

    public virtual List<Webservice_Settings__c> constructWebserviceSettings(List<Webservice_Settings__c> wss){
        return wss;
    }

    public List<Custom_ECG_Labels__c> constructCustomLabels() {
        List<Custom_ECG_Labels__c> customLabels = new List<Custom_ECG_Labels__c>();
        customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_' + ADSALESROLENAME, Value__c='TEST IO SUBJECT'));
        customLabels.add(new Custom_ECG_Labels__c(Name='IOName_' + ADSALESROLENAME, Value__c='TEST IO NAME'));
        customLabels.add(new Custom_ECG_Labels__c(Name='MandateSubject_' + VERTICALROLENAME , Value__c='TEST Mandate Subject'));
        customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_xxxxxx', Value__c='TEST IO SUBJECT'));
        return constructCustomLabels(customLabels);
    }

    public virtual List<Custom_ECG_Labels__c> constructCustomLabels(List<Custom_ECG_Labels__c> customLabels) {
        return customLabels;
    }

    /* Opportunity */
    public Opportunity constructOpportunity(Account parentAcc, Id priceBookId, Contact primaryContact) {
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = Date.today()+90;
        opp.StageName = GW_sObject.getFirstPickListValue('Opportunity','StageName');
        opp.CurrencyIsoCode = UTIL.corporateCurrency.IsoCode;
        opp.AccountId = parentAcc.Id;
        opp.Pricebook2Id = priceBookId;
        opp.Primary_Contact__c=primaryContact.Id;
        return constructOpportunity(opp);
    }

    public virtual Opportunity constructOpportunity(Opportunity opp) {
        return opp;
    }

    public List<OpportunityLineItem> constructOpportunityLineItems(List<Opportunity> opps) {
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        return constructOpportunityLineItems(opps, olis);
    }

    public virtual List<OpportunityLineItem> constructOpportunityLineItems(List<Opportunity> opps, List<OpportunityLineItem> olis) {
        return olis;
    }

    /* Invoices */
    public Invoice__c constructInvoice(Account a) {
        Invoice__c inv = new Invoice__c(UniqueKey__c='TestInv',
                                        //Startdate__c=date.newInstance(2016, 1, 1),
                                        //Enddate__c=date.newInstance(2016, 1, 1),
                                        BillingAccount__c =  a.Id,
                                        EndDate__c = System.today(),
                                        StartDate__c = System.today().addDays(-30),
                                        FQ_InvoiceID__c='BEC15070000');
        return constructInvoice(inv);
    }

    public virtual Invoice__c constructInvoice(Invoice__c inv) {
        return inv;
    }

    public InvoiceLine__c constructInvoiceLine(Invoice__c inv) {
        InvoiceLine__c il = new InvoiceLine__c();
        il.Amount__c = 100;
        il.IndirectDiscountAmount__c = 0;
        il.Invoice__c = inv.Id;
        il.InvoiceLineDescription__c = 'Indirect Discount';
        il.Quantity__c = 1;
        il.UniqueKey__c = 'ID_'+inv.Id+'_'; //+inv.StartDate__c;
        il.FQ_ProductCode__c = 'UK_AUS_BAN';
        il.FQ_ProductType__c = 'Banners';
        il.FQ_ProductSubType__c = '';
        il.RS__c = null;
        il.VatPercentage__c = '50';
        il.LineOfBusiness__c = 'AdSales';
        il.CurrencyIsoCode = inv.CurrencyIsoCode;

        return constructInvoiceLine(il);
    }

    public virtual InvoiceLine__c constructInvoiceLine(InvoiceLine__c il) {
        return il;
    }

    public List<CustomAttributeDefinition__c> constructCustomAttributeDefinitions() {
        List<CustomAttributeDefinition__c> cadList = new List<CustomAttributeDefinition__c>();
        return constructCustomAttributeDefinitions(cadList);
    }

    public virtual List<CustomAttributeDefinition__c> constructCustomAttributeDefinitions(List<CustomAttributeDefinition__c> cadList) {
        return cadList;
    }

}