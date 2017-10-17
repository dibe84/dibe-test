/**
 *  Unitest for coverage code of class AccountChart 
 *  @author: Pheaktra Hun
 *  @date : 11-Jul-2016
 *  @ticket : Task #9533 - CD-553 - Booked & delivered revenue charts on account layout
 */
@isTest
public class TST_CHART_AccountRevenue {

    static Account makeNewAccount() {

        createMembers();

        Account newAcct = new Account();
        newAcct.Name = 'Test Account 1'; 
        insert newAcct;
        
        Contact con=new Contact();
        con.LastName='TestContact';
        con.AccountId=NewAcct.Id;
        con.Fax='1234567';
        con.Email='Test@test.com';
        con.MobilePhone='+13469756789';

        insert con;
        
        MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test Adsales' AND LineOfBusiness__c = 'AD'];
        Opportunity opp = new Opportunity( MemberUnit__c=mu.Id, Name='testOpp', AccountId=newAcct.Id, CloseDate=Date.today(), StageName='Finished' );
        insert opp;
        
        Product2 newProduct = new Product2();
        newProduct.Name = 'Test Widget';
        newProduct.Family = 'Widgets';
        insert newProduct;

        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry();
        pbe.IsActive = TRUE;
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id = newProduct.Id;
        pbe.UnitPrice = 5555;
        pbe.UseStandardPrice = FALSE;
        insert pbe;
        
        OpportunityLineItem newOLI = new OpportunityLineItem();
        newOLI.PricebookEntryId = pbe.Id;
        newOLI.Description= 'Test Oppty #1';
        newOLI.Ad_Name__c = 'abc';
        newOLI.OpportunityId = opp.Id;
        newOLI.from_Date__c = Date.today();
        newOLI.until_Date__c = Date.today()+5;
        newOLI.Billing_Category__c = 'CPM';
        newOLI.Quantity = 100000;
        newOLI.UnitPrice = 3;
        insert newOLI;
        
        Rev__c rev = new Rev__c(Opportunity__c=opp.Id, Product__c=newProduct.Id);
        insert rev;
        
        RS__c rs = new RS__c(Rev__c=rev.Id, Opportunity__c=opp.Id, UniqueKey__c='uniqueKey', StartOfPeriod__c=Date.today());
        insert rs;
        
        return newAcct;
    }

    static testMethod void testChartData() {
        Account newAcct = makeNewAccount();
        ApexPages.StandardController stdCon = new ApexPages.StandardController(newAcct);
        
        CHART_AccountRevenue adc = new CHART_AccountRevenue(stdCon);
        adc.getAdvertiserBookedRevenueAmountMoM();
        adc.getAdvertiserBookedRevenueAmountYoY();
        adc.getAdvertiserDeliveredRevenueAmountMoM();
        adc.getAdvertiserDeliveredRevenueAmountYoY();
        adc.getAgencyBookedRevenueAmountMoM();
        adc.getAgencyBookedRevenueAmountYoY();
        adc.getAgencyDeliveredRevenueAmountMoM();
        adc.getAgencyDeliveredRevenueAmountYoY();
        
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

}