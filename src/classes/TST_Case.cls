@isTest
private class TST_Case {
    
    private static final string GROUP_CSWEB = 'ECGDK CS Web';
    
    public static DF factory;

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'EBAYKRE_Rep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'EBAYKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
            
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('EBAYKRE-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'RE',
                DF_Scenario.CONF_USERS               => new List<String> { 'EBAYKRE_Rep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser'
            })
                
        };
    }
    
    @testSetup static void setup() {
        /*
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
        */
        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        UTIL.isRunningTestSetup = false;
        
        if([select id from Group where Name = :TST_Case.GROUP_CSWEB and Type = 'Queue'].isEmpty()) {
            insert new Group(Name = TST_Case.GROUP_CSWEB, Type = 'Queue');
        }
    }
    
    @isTest static void test_initialNewCases(){
        Case cc1 = new Case(RecordTypeId= GW_Case.recordTypeIdECGDKCS,SuppliedEmail= 'TST_Case@test.com',  SuppliedName = 'TST_Case1', SuppliedPhone = '+123456789', Origin = 'Web');
        Case cc2 = new Case(RecordTypeId= GW_Case.recordTypeIdECGDKCS,SuppliedEmail= 'TST_Case@test.com',  SuppliedName = 'TST_Case2', SuppliedPhone = '+223456789', Origin = 'Web');
        Case cc3 = new Case(RecordTypeId= GW_Case.recordTypeIdECGDKCS,SuppliedEmail= 'TST_Case3@test.com', SuppliedName = 'TST_Case3', SuppliedPhone = '+223456789', Origin = 'Web');
        Test.startTest();
        insert new List<Case>{cc1, cc2, cc3};
        Test.stopTest();
        
        // Case conatct and Owner are set
        //  cc1 and cc2 share the same contact since it have the same email
        cc1 = [select id, contactId, ownerId from Case where id = :cc1.id];
        system.assert(cc1.contactId != null);
        
        cc2 = [select id, contactId, ownerId from Case where id = :cc2.id];
        system.assert(cc2.contactId == cc1.contactId);
        
        // cc3 has a separated contact
        cc3 = [select id, contactId, ownerId from Case where id = :cc3.id];
        system.assert(cc3.contactId != null && cc3.contactId != cc2.contactId);
    }
    
    @isTest static void test_linkCaseToLiveChatTranscript(){
        Case cc1 = new Case(KeyToLiveChatTranscript__c = 'KeyLINKINTEST', RecordTypeId= GW_Case.recordTypeIdECGDKCS,SuppliedEmail= 'TST_Case@test.com',  SuppliedName = 'TST_Case1', SuppliedPhone = '+123456789', Origin = 'Web');
        insert cc1;
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        
        LiveChatTranscript lct1 = new LiveChatTranscript(KeyToCase__c = 'KeyLINKINTEST', LiveChatVisitorId = lcv.Id);
        insert lct1;
        
        Test.startTest();
        cc1.Origin = 'LiveChat';
        update cc1;
        Test.stopTest();
        
        // cc1 and lct1 are linked now
        System.assertEquals(cc1.Id, [Select CaseId From LiveChatTranscript Where Id =: lct1.Id].CaseId);
    }
   
   //18-07-2017
    @isTest static void test_createCase(){
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','contacts', 'memberunits'});
        Account acc = result.accounts.values().get(0);
        Contact cont = result.contacts.values().get(0);
        
        Test.startTest();
        Case c = GW_Case.createCase(acc.id, cont.id, 'web', true);
        insert c;
        
        list<Case> lstResult = GW_Case.getList(new Set<Id>{c.id});
        Map<Id,Case> mapCase = GW_Case.getMap(new Set<Id>{c.id});
        Case cResult = GW_Case.getRecord(c.id);
        system.assertEquals('Web',cResult.Origin);
        system.assertEquals(acc.id,cResult.AccountId);
        system.assertEquals(cont.id,cResult.ContactId);
        Test.stopTest();
        
    }
}