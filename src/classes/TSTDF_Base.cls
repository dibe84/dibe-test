public virtual class TSTDF_Base { // base test data factory, creating test data

    public TSTDF_DataContainer data = null;
    public TSTDF_BaseDataSet dataSet = null;

    public TSTDF_Base() {
        this(new TSTDF_BaseDataSet());
    }

    public TSTDF_Base(TSTDF_BaseDataSet dataSet) {
        this.data = new TSTDF_DataContainer();
        this.data.testUsers.put( 'runningUser', (User) [ select Id from User where Id = :UserInfo.getUserId() ] );
        this.dataSet = dataSet;
    }

    // use this method for creating the testData in @testSetup method
    public virtual void createTestSet() {
        insertPlatformDataSet();
        insertAdSalesDataSet();
        insertVerticalDataSet();
    }

    public virtual void insertPlatformDataSet(){
        UTIL_CustomJob.createTestCustomJobs(); // create custom async jobs
        insertMemberStructure(); // create member and memberunits

        insertCustomLabels();
        insertCustomSettings();
        insertCustomAttributeDefinitions();

        System.runAs ( this.data.testUsers.get( 'runningUser' ) ) {
            insertRoleStructure();
            insertUsers();
        }
    }

    public virtual void insertAdsalesDataSet(){
        System.runAs ( this.data.testUsers.get( 'testUser') ) {
            insertLeads();
            insertAccounts();
            insertContacts();
            this.data.accounts[0].Finance_contact__c = this.data.contacts[0].Id;
            update this.data.accounts[0];

            insertProducts();
            insertPricebookEntries();
            insertOpportunity();
            insertOlis();
            insertCustomAttributes();
            UTIL_RecordRestriction.requestAdminBypass();
            insertInvoices();
            insertInvoiceLines();
            UTIL_RecordRestriction.removeAdminBypass();
        }
    }


    public virtual void insertVerticalDataSet(){
        //TODO
    }

    public virtual void startASyncJobs() {
        System.runAs ( this.data.testUsers.get( 'testAdmin') ) {
            UTIL_CustomJob.startAllCustomJobs();
        }
    }

    // retrieve create testdata from database and store in Maps
    public void queryResults() {
        queryResults(null);
    }

    // retrieve create testdata from database and store in Maps
    public void queryResults(Set<String> objToQuery) {
        this.data.testUsers.put( 'testUser',  (User) GW_sObject.queryRecords('User', 'UserName = \''+dataSet.TESTUSERNAME+'\'')[0]);
        this.data.testUsers.put( 'adminUser', (User) GW_sObject.queryRecords('User', 'UserName = \''+dataSet.TESTADMINUSERNAME+'\'')[0]);
        this.data.testUsers.put( 'testVertUser', (User) GW_sObject.queryRecords('User', 'UserName = \''+dataSet.VERTICALTESTUSERNAME+'\'')[0]);
        RecordType rtMember = [SELECT Id From RecordType WHERE SobjectType='Account' AND DeveloperName='Member'];

        if (null == objToQuery || objToQuery.contains('members')) {
            List<Member__c> members = (List<Member__c>) GW_sObject.queryRecords('Member__c', 'Id <> null');
            this.data.members = new Map<String, Member__c>();
            for (Member__c member : members) {
                this.data.members.put(member.MemberId__c, member);
            }
        }
        if (null == objToQuery || objToQuery.contains('memberunits')) { this.data.memberunits = GW_sObject.queryRecords('MemberUnit__c', 'Id <> null'); }
        if (null == objToQuery || objToQuery.contains('leads')) { this.data.leads = GW_sObject.queryrecords('Lead', 'Id <> null'); }
        if (null == objToQuery || objToQuery.contains('accounts')) { this.data.accounts = GW_sObject.queryRecords('Account', 'RecordTypeId <> \''+rtMember.Id+'\' ORDER BY Id'); } // skip the created Member Account record
        if (null == objToQuery || objToQuery.contains('opps')) { this.data.opps = GW_sObject.queryRecords('Opportunity', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('products')) { this.data.products = GW_sObject.queryRecords('Product2', 'Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('pbes')) { this.data.pbes = GW_sObject.queryRecords('PricebookEntry', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('contacts')) { this.data.contacts = GW_sObject.queryRecords('Contact', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('olis')) { this.data.olis = GW_sObject.queryRecords('OpportunityLineItem', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('revs')) { this.data.revs = GW_sObject.queryRecords('Rev__c', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('rss')) { this.data.rss = GW_sObject.queryRecords('RS__c', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('metrics')) { this.data.metrics = GW_sObject.queryRecords('Metric__c', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('invoices')) { this.data.invoices = GW_sObject.queryRecords('Invoice__c', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('invoiceLines')) { this.data.invoiceLines = GW_sObject.queryRecords('InvoiceLine__c', ' Id <> null ORDER BY Id'); }
        if (null == objToQuery || objToQuery.contains('customAttributeDefinitions')) { this.data.customAttributeDefinitions = GW_sObject.queryRecords('CustomAttributeDefinition__c', 'Id <> null ORDER By Id'); }
        queryAdditionalResults();
    }

    public virtual void queryAdditionalResults() {}

    public virtual void insertUsers() {
        this.data.testUsers = dataSet.constructUserMap();
        insert this.data.testUsers.values();
    }

    public virtual void insertLeads() {
        
        Id ownerId = this.data.testUsers.get('testUser').Id;
        Id memberId = this.data.members.values()[0].Id;
        Id memberUnitId = this.data.memberUnits[0].Id;
        List<Lead> leads = dataSet.constructLeads( ownerId , memberId , memberUnitId );
        this.data.leads.addAll(leads);
        insert leads;
    }

    public virtual void insertAccounts() {
        List<Account> accounts = dataSet.constructAccounts(this.data.members.get(dataSet.COUNTRYROLENAME));
        for(Account acc : accounts){
        		acc.RecordTypeId = UTIL_RecordType.getRecordTypeByName('Account','Advertiser').Id;
        }
        this.data.accounts.addAll(accounts);
        insert accounts;
    }
    public virtual void insertContacts() {
        List<Contact> contacts = dataSet.constructContacts(this.data.accounts[0]);
        this.data.contacts.addAll(contacts);
        insert contacts;
    }

    public virtual void insertProducts() {
        List<Product2> products = dataSet.constructProducts();
        this.data.products.addAll(products);
        UTIL.Log('added Products: ' + products);
        insert products;
        UTIL.Log('inserted Products: ' + products);
    }

    public virtual void insertPricebookEntries() {
        List<PriceBookEntry> pbes = dataSet.constructPricebookEntries(this.data.products[0]);
        this.data.pbes.addAll(pbes);
        UTIL.log('added PBEs: ' + pbes);
        insert pbes;
        UTIL.log('inserted PBEs: ' + pbes);
    }

    public virtual void insertOpportunity() {
        List<Opportunity> opps = new List<Opportunity>();
        Opportunity opp = dataSet.constructOpportunity(this.data.accounts[0], Test.getStandardPricebookId(), this.data.contacts[0]);
        opps.add(opp);
        this.data.opps.addAll(opps);
        insert opps;
    }

    public virtual void insertCustomAttributeDefinitions() {
        List<CustomAttributeDefinition__c> cadList = new List<CustomAttributeDefinition__c>();
        cadList.addAll(dataSet.constructCustomAttributeDefinitions());
        this.data.customAttributeDefinitions.addAll(cadList);
        insert cadList;
    }

    public virtual void insertCustomAttributes() {}

    public virtual void insertRevs() {}

    public virtual void insertRSs() {}

    public virtual void insertOlis() {
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        List<OpportunityLineItem> constructedOlis = dataSet.constructOpportunityLineItems(this.data.opps);
        olis.addAll(constructedOlis);
        this.data.olis.addAll(olis);
        insert olis;
    }

    public virtual void insertRoleStructure() {
        upsert dataSet.constructRoleStructure();
    }

    public virtual void insertCustomLabels(){
        insert dataSet.constructCustomLabels();
    }

    public virtual void insertCustomSettings(){
        insert dataSet.constructRecordRestrictions();
        insert dataSet.constructWebserviceSettings();
    }

    public virtual void insertMemberStructure() {
        Account memberAccount = dataSet.constructMemberAccount();
        insert memberAccount;

        Member__c member = dataSet.constructMember(memberAccount.Id);
        insert member;
        this.data.members.put(member.MemberId__c, member);

        List<MemberUnit__c> memberUnits = new List<MemberUnit__c>();
        memberUnits.add(dataSet.constructMemberUnit(member.Id, 'Test Adsales', 'AD'));
        memberUnits.add(dataSet.constructMemberUnit(member.Id, 'Test Vertical', 'AU'));
        insert memberUnits;
        this.data.memberUnits.addAll(memberUnits);

        member.DefaultMemberUnit__c = memberUnits[0].Id;
        update member;
    }

    public virtual void insertInvoices() {
        List<Invoice__c> invoices = new List<Invoice__c>();
        invoices.add(dataSet.constructInvoice(data.accounts[0]));
        this.data.invoices.addAll(invoices);
        //insert this.data.invoices;
    }

    public virtual void insertInvoiceLines() {
        List<InvoiceLine__c> invoiceLines = new List<InvoiceLine__c>();
        invoiceLines.add(dataSet.constructInvoiceLine(data.invoices[0]));
        this.data.invoiceLines.addAll(invoiceLines);
        //insert this.data.invoiceLines;
    }
}