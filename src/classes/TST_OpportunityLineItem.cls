@isTest
private class TST_OpportunityLineItem {
     
    static PricebookEntry pbe;
    static Opportunity opp; 
    static OpportunityLineItem oli;
    
    static void setup() { 
        
        User testUser;
        User thisUser = new User( Id=UserInfo.getUserId() );
        System.runAs ( thisUser ) {

            createMembers();
            createRoleStructure();
            
            List<User> users = new List<User>();
            ///testUser = GW_User.createTestUser( 'MyTestUser_TST_AdSalesIO@ecgtests.com', 'TTCLGAD', 'Ad Sales Rep' );
            testUser = GW_User.createTestUser( 'MyTestUser_TST_AdSalesIO@ecgtests.com', 'TTCLGAD', 'System Administrator' );
            users.add(testUser);
            insert users;
        }

        System.runAs ( testUser ) {
            Account acc = GW_Account.insertSObject(); 
            Contact con = GW_Contact.insertSObject('LastName', acc);
            Product2 prod = GW_Product.insertSObject('Banners'); 
            pbe = GW_Product.insertPricebookEntry( prod, new Pricebook2(id=Test.getStandardPricebookId()), 10.00);
            opp = GW_Opportunity.insertSObject(acc, con); 
        }
    }
    
    /**
     * insert user role
     */
    private static void createRoleStructure() {
        List<UserRole> memberUnitRoles = new List<UserRole>();
        UserRole countryLevelRole = new UserRole(Name='Test Country Level Role', DeveloperName='TTCLG');
        insert countryLevelRole;
        memberUnitRoles.add(new UserRole(Name='Test Member Unit Level Role (Adsales)', ParentRoleId=countryLevelRole.Id, DeveloperName='TTCLGAD'));
        insert memberUnitRoles;
    }


    /**
     * insert member and member unit for testing
     */
    private static void createMembers() {

        Id RecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
        Account memberAccount = new Account(RecordTypeId=RecId, name='MemberAccount', BillingCountry='Netherlands', ShippingCountry='Italy');
        insert memberAccount;
        Member__c member = GW_Member.insertSObject('Test Member', 'TTCLG',memberAccount);
        List<MemberUnit__c> memberUnits = new List<MemberUnit__c>();
        memberUnits.add(GW_MemberUnit.insertObject(member.Id, 'Test Adsales', 'AD'));
        memberUnits.add(GW_MemberUnit.insertObject(member.Id, 'Test Automotive', 'AU'));
        member.DefaultMemberUnit__c = memberUnits[1].Id;
        update member;
    }

    static testMethod void testConfigureDefaultDFPTargeting() {
        setup(); 
        String dartName3 = 'DartName3';
        String dartName4 = 'DartName4';
         
        Content__c content_Prededined = new Content__c(Active__c = true, DartName__c = 'DartName1');
        Content__c content_FixedSite = new Content__c(Active__c = true, DartName__c = 'DartName2');
        Content__c content_LineDescr1 = new Content__c(Active__c = true, DartName__c = dartName3);
        Content__c content_LineDescr2 = new Content__c(Active__c = true, DartName__c = dartName4);
        
        insert new List<Content__c>{content_Prededined, content_FixedSite, content_LineDescr1, content_LineDescr2};
        
        Placement__c placement = new Placement__c();
        insert placement;
        
        // Fixed site product with predefined content and placement
        Product2 product = new Product2(id = pbe.Product2Id, Fixed_Site__c = true, PredifinedAdunit__c = content_Prededined.id, Placement__c = placement.id, Billing_Category__c = 'CPM_Delivery');
        update product;
         
        Available_Site__c availableSite = new Available_Site__c(Product__c = product.id, available_Site__c = content_FixedSite.id);
        insert availableSite;
        
        // reselect IndirectDiscount__c
        opp = (Opportunity) UTIL.getCached(opp.Id); 
        opp = (Opportunity) GW_sObject.queryRecords(GW_sObject.getobjectNameFromId(opp.Id), new Set<Id>{opp.Id})[0]; //Get all fields information
        oli = GW_OpportunityLineItem.createSObject(opp, pbe, 10, 10);
        // Set Rich_Line_Description__c, it is content.DartName__c, and will create TargetingContentAssociations 
        oli.Rich_Line_Description__c = dartName3 + ',' + dartName4; 
        
        Test.startTest();
            // Setting default targeting when saving new OLI 
            LCC_ProductConfigurator.saveOpportunityLineItem(oli); 
            Id targetingId = ((OpportunityLineItem)UTIL.getCached(oli.Id)).Targeting__c;
            
            // Asserting Targeting__c and its related list are created.
            Targeting__c defaultTargeting = [select id, (select id from TargetingContentAssociations__r), (select id from PlacementTargetingAssociations__r) from Targeting__c where id = :targetingId];
            
            // 4 TargetingContentAssociations are created from:
            //     - 1 from Product2.PredifinedAdunit__c
            //     - 1 from Product2 Available_Site__c related list since Product2 is fixed site
            //     - 2 from OLI.Rich_Line_Description__c, Comma separeted DartNames
            System.assertEquals(4, defaultTargeting.TargetingContentAssociations__r.size());
            
            // 1 PlacementTargetingAssociation is created from Product2.Placement__c
            System.assertEquals(1, defaultTargeting.PlacementTargetingAssociations__r.size());
        Test.stopTest(); 
    }
}