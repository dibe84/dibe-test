/**
 * author : vitou
 * date   : 09-Apr-2015
 */
@isTest
private class TST_GW_Objects {

    private static User userAdmin;
    private static User currentUser = [ select Id from User where Id = :UserInfo.getUserId() ];
    
    public static void createTestUserAdmin()
    {
        System.runAs ( currentUser ) {
            Profile p=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
            userAdmin = GW_User.createTestUser(p);
            userAdmin.Username='testUser1@testtt.com';
            userAdmin.LastName='testLastName';
            userAdmin.Email='testUser1@testtt.com';
            userAdmin.Alias='test1';
            userAdmin.TimeZoneSidKey='Pacific/kiritimati';
            userAdmin.LocaleSidKey='ar';
            userAdmin.EmailEncodingKey='UTF-8';
            userAdmin.ProfileId=p.Id;
            userAdmin.LanguageLocaleKey='en_US';   
            insert userAdmin;
        }                       
    }
 
     //test GW_Account
    @isTest static void TestGW_Account() {
    	
    	createTestUserAdmin();
    	
    	System.runAs ( userAdmin ) {
	        GW_Account.insertSObject();
	        Account parentsAcc = GW_Account.createSObject('Test_Parents');
	        parentsAcc.ownerId = userAdmin.Id;
	        insert parentsAcc;
	        Account childAcc = GW_Account.createSObject('Test_Child',parentsAcc);
	        childAcc.ownerId = userAdmin.Id;
	        insert childAcc;
	        GW_Account.getRecord(parentsAcc.id);
	        GW_Account.getMap(new Set<id>{parentsAcc.id});
	        GW_Account.getList(new Set<id>{parentsAcc.id});
    	}
    } 
    
    //test GW_Account
     @isTest static void testGW_Account_PendingMandate() {
     	createTestUserAdmin();
    	
    	System.runAs ( userAdmin ) {
    		GW_Account.insertSObject();
		    Account parentsAcc = GW_Account.createSObject('Test_Parents');
		    insert parentsAcc;
		        
    		Test.startTest();
		        Boolean isPending = GW_Account.hasPendingMandate(parentsAcc.id);
		        system.assert(!isPending, 'There is no pending mandate on account as this has related Agreement.');
		        
		        echosign_dev1__SIGN_Agreement__c agreement = GW_Agreement.createAgreement(parentsAcc.Id, null, 'mandate');
		        insert agreement;
                agreement.echosign_dev1__Status__c = 'Out for Signature';
                update agreement;
		        isPending = GW_Account.hasPendingMandate(parentsAcc.id);
		        system.assert(isPending, 'TRUE beacuse of there is an Agreement is in Draft status. It means that this Account has pending mandate.');
		        
		        agreement.Type__c = 'io';
		        update agreement;
		        isPending = GW_Account.hasPendingMandate(parentsAcc.id);
		        system.assert(!isPending, 'FALSE because this account has only related IO agreement not Mandate.');
			Test.stopTest();
    	}
     }
    
    //test GW_Contact
     @isTest static void TestGW_Contact() {
     	
     	createTestUserAdmin();
        
        System.runAs ( currentUser ) {
	        Account Acc = GW_Account.createSObject('Test_Acc');
	        Acc.ownerId = userAdmin.Id;
	        insert  Acc;
	        Contact con = GW_Contact.createSObject('TestContact', Acc);
	        insert con;
	        
        }
        
     }
 
     //test GW_Member
     @isTest static void TestGW_Member() {
        Map<Id, Member__c> mapCache = GW_Member.memberCache;
        //GW_Member.getUserMember();
     }
     
      //test GW_Product
     @isTest static void TestGW_Product() {
        Product2 pro = new Product2(Name = 'Test Product', Billing_Category__c = 'CPM', Fixed_price__c = true,IsActive = true );
        insert pro;
        
        GW_Product.getRecord(pro.id);
        GW_Product.getMap(new Set<id>{pro.id});
        GW_Product.getList(new Set<id>{pro.id});
        GW_Product.insertSObject('productNameTest') ;
        Pricebook2 pb = GW_Product.insertPricebook();
        
     }
     
     @isTest 
     static void DEV_ObjectListControllerTest(){
        test.startTest();
            DEV_ObjectListController devObjLstCont = new DEV_ObjectListController();
        test.stopTest();
     }
}