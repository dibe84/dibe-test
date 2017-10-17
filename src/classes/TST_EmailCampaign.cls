@isTest
public class TST_EmailCampaign extends TSTDF_Base {
        
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
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'EBAYKRE_DBA_2017'
            })
        };
    }
    
    @testSetup static void setup() {
        
        UTIL.isRunningTestSetup = true;
        
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            // Insert EmailTemplates
            EmailTemplate leadEmailTemplate = new EmailTemplate();
            leadEmailTemplate.isActive = true;
            leadEmailTemplate.Name = 'Lead_Template';
            leadEmailTemplate.DeveloperName = 'Lead_Template';
            leadEmailTemplate.TemplateType = 'visualforce';
            leadEmailTemplate.Markup = '<messaging:emailTemplate subject="Test Campaign Template" recipientType="Lead"  relatedToType="Campaign"><messaging:htmlEmailBody></messaging:htmlEmailBody></messaging:emailTemplate>';
            leadEmailTemplate.FolderId = UserInfo.getUserId();

            insert leadEmailTemplate;

            // Insert EmailTemplates
            EmailTemplate contactEmailTemplate = new EmailTemplate();
            contactEmailTemplate.isActive = true;
            contactEmailTemplate.Name = 'Contact_Template';
            contactEmailTemplate.DeveloperName = 'Contact_Template';
            contactEmailTemplate.TemplateType = 'visualforce';
            contactEmailTemplate.Markup = '<messaging:emailTemplate subject="Test Campaign Template" recipientType="Lead"  relatedToType="Campaign"><messaging:htmlEmailBody></messaging:htmlEmailBody></messaging:emailTemplate>';
            contactEmailTemplate.FolderId = UserInfo.getUserId();

            insert contactEmailTemplate;
        }
 		
        UTIL.isRunningTestSetup = false;
    }

   
    @isTest
    static void testEmailCampaign() {
        // retrieve test data
        //factory.queryResults();
        //MemberUnit__c mu = [SELECT Id, Member__c FROM MemberUnit__c LIMIT 1];
        
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits','users', 'contacts' });
        Account acc = result.accounts.values().get(0);
        Contact cont = result.contacts.values().get(0);
        MemberUnit__c mu = result.memberunits.values().get(0);

      
        // Create campaign
        Campaign camp = new Campaign();
        camp.Name = 'Test Campaign';
        camp.MailBetweenStart__c = '00:00';
        camp.MailBetweenEnd__c = '23:59';
        camp.Sender__c = 'thomas.ward@ebay.com';
        camp.EmailTemplateContact__c = 'Contact_Template';
        camp.EmailTemplateLead__c = 'Lead_Template'; 
        camp.Landing_Page__c = 'http://www.example.com/blaat';
        camp.Type = 'Email';
        camp.Member__c = mu.Member__c;
        camp.MemberUnit__c = mu.Id;
                
        insert camp;
        
        CampaignMemberStatus cms1 = new CampaignMemberStatus(CampaignId = camp.Id, HasResponded=false, Label = 'Unsent', SortOrder = 3, isDefault = true);
        CampaignMemberStatus cms2 = new CampaignMemberStatus(CampaignId = camp.id, HasResponded=false, Label = 'Queued', SortOrder = 4, isDefault = false);
        CampaignMemberStatus cms3 = new CampaignMemberStatus(CampaignId = camp.Id, HasResponded=false, Label = 'Opened Landing Page', SortOrder = 5, isDefault = false);
        
        insert cms1;
        insert cms2;
        insert cms3;
                 
        
        // Create lead
        Lead l = new Lead();
        l.FirstName = 'Test';
        l.LastName = 'Lead';
        l.Company = 'Test Company';
        l.Email = 'test@lead.com';
        l.Member__c = mu.Member__c;
        l.MemberUnit__c = mu.Id;
        
        insert l;        
        
        // Add to campaign
        CampaignMember cm1 = new CampaignMember();
        cm1.LeadId = l.Id;
        cm1.CampaignId = camp.Id;
        cm1.Status = 'Unsent';
        insert cm1;
        
        CampaignMember cm2 = new CampaignMember();
        cm2.ContactId = cont.Id;
        cm2.CampaignId = camp.Id;
        cm2.Status = 'Unsent';
        insert cm2;
               
        CustomJob__c CJ = new CustomJob__c(Name='BAT_SendCampaignMails', JobFrequency__c='2min',JobType__c='Batch',LastRun__c=system.today().addDays(-1),LastCheck__c=system.today().addDays(-1),BatchSize__c=5,Active__c=true,WhereClause__c='Status = \'Queued\'',IsRunning__c=false, TimeoutPerBatch__c = 600);
        insert CJ;
        
        // Test webservice
        Test.startTest();        
        System.runAs(result.users.get('EBAYKRE_Rep')) {  
            String resultSevice = CampaignWebservices.queueAllUnsent(camp.Id);
        }
        
        System.runAs(result.users.get('admin')) { 
            UTIL_CustomJob.startCustomJob('BAT_SendCampaignMails');
        }
        
        
        // Run job
        Blob aesKey = EncodingUtil.convertFromHex('8a6a961d6a0867d55affc5a896c6e30f6b7fbe6b7421fc4498776b2cd89e9342'); // AES256 key..
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', aesKey, Blob.valueOf(cm1.Id + ''));
        String hexId = EncodingUtil.convertToHex(encryptedData);
        
        PageReference pageRef = Page.KijijiITMailCampaignToCase;
        Test.setCurrentPage(pageRef);
      
        // Add parameters to page URL
        ApexPages.currentPage().getParameters().put('id', hexId);
        
        ForceDotComMailCampaignToCase controller = new ForceDotComMailCampaignToCase();
        
        String r1 = ForceDotComMailCampaignToCase.saveHit(cm1.Id);
        String r2 = ForceDotComMailCampaignToCase.saveResponse('Test', 'Test' , 'Test', 'Test', 'Test', cm1.Id + '', camp.Id);
        
        //17-07-2017 - increase coverage for ForceDotComMailCampaignToCaseException
        ForceDotComMailCampaignToCase.unsubscribe(cm1.Id);
        
        encryptedData = Crypto.encryptWithManagedIV('AES256', aesKey, Blob.valueOf(l.Id + ''));
        hexId = EncodingUtil.convertToHex(encryptedData);
        ApexPages.currentPage().getParameters().put('id', hexId);
        ForceDotComMailCampaignToCase controller2 = new ForceDotComMailCampaignToCase(); 
        
        encryptedData = Crypto.encryptWithManagedIV('AES256', aesKey, Blob.valueOf(cont.Id + ''));
        hexId = EncodingUtil.convertToHex(encryptedData);
        ApexPages.currentPage().getParameters().put('id', hexId);
        ForceDotComMailCampaignToCase controller3 = new ForceDotComMailCampaignToCase(); 
        String r3 = ForceDotComMailCampaignToCase.saveResponse('Test', 'Test' , 'Test', 'Test', 'Test', cont.Id + '', null);
        
        Test.stopTest();
   
    }
    
    
    @isTest
    static void test_BATSendCampaignMails() {
        
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'accounts','memberunits','users', 'contacts' });
        Account acc = result.accounts.values().get(0);
        Contact cont = result.contacts.values().get(0);
        MemberUnit__c mu = result.memberunits.values().get(0);
        
        // Create campaign
        Campaign camp = new Campaign();
        camp.Name = 'Test Campaign';
        camp.MailBetweenStart__c = '00:00';
        camp.MailBetweenEnd__c = '23:59';
        camp.Sender__c = 'BATSendCampaignMails@Test.com';
        camp.EmailTemplateContact__c = 'Contact_Template';
        camp.EmailTemplateLead__c = 'Lead_Template';
        camp.Landing_Page__c = 'http://www.example.com/blaat';
        camp.Type = 'Email';
        camp.Member__c = mu.Member__c;
        camp.MemberUnit__c = mu.Id;               
        insert camp;
        
        CampaignMemberStatus cms1 = new CampaignMemberStatus(CampaignId = camp.Id, HasResponded=false, Label = 'Unsent', SortOrder = 3, isDefault = true);
        CampaignMemberStatus cms2 = new CampaignMemberStatus(CampaignId = camp.id, HasResponded=false, Label = 'Queued', SortOrder = 4, isDefault = false);
        CampaignMemberStatus cms3 = new CampaignMemberStatus(CampaignId = camp.Id, HasResponded=false, Label = 'Opened Landing Page', SortOrder = 5, isDefault = false);
        list<CampaignMemberStatus> lstCms = new list<CampaignMemberStatus>{cms1, cms2, cms3};
        insert lstCms;                 
        
        // Create lead
        Lead l = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Company', Email = 'test@lead.com', Member__c = mu.Member__c, MemberUnit__c = mu.Id );
        insert l;        
        
        
        CustomJob__c CJ = new CustomJob__c(Name='BAT_SendCampaignMails', JobFrequency__c='2min',JobType__c='Batch',LastRun__c=system.today().addDays(-1),LastCheck__c=system.today().addDays(-1),BatchSize__c=5,Active__c=true,WhereClause__c='Status = \'Queued\'',IsRunning__c=false, TimeoutPerBatch__c = 600);
        insert CJ;
        
        // Add to campaign
        CampaignMember cm1 = new CampaignMember(LeadId = l.Id, CampaignId = camp.Id, Status = 'Queued');        
        CampaignMember cm2 = new CampaignMember(ContactId = cont.Id, CampaignId = camp.Id, Status = 'Queued');
        
        list<CampaignMember> lstCm = new list<CampaignMember>{cm1, cm2};
        insert lstCm;
                       
        Test.startTest();        
        
        System.runAs(result.users.get('admin')) { 
            
            UTIL_CustomJob.startCustomJob('BAT_SendCampaignMails');
            
            BAT_SendCampaignMails testBatch = new BAT_SendCampaignMails(new List<CampaignMember>());
        }
        
        Test.stopTest();
    }

}