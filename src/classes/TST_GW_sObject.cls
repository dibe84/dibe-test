@isTest
private class TST_GW_sObject {
	
	private static Account acc;
	private static List<Opportunity> opps = new List<Opportunity>();
	private static Opportunity opp1;
	private static Opportunity opp2;
    private static User userAdmin;
    private static User currentUser = [ select Id from User where Id = :UserInfo.getUserId() limit 1]; 

	// create Account and Opportunities
	private static void createBasedata() { 
		
      system.runAs( currentUser ){
            Profile p=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
            userAdmin = GW_User.createTestUser(p);
            userAdmin.Username='testUser1@boco.com';
            userAdmin.LastName='testLastName1';
            userAdmin.Email='testEmail1@boco.com';
            userAdmin.Alias='test1';
            userAdmin.TimeZoneSidKey='Pacific/kiritimati';
            userAdmin.LocaleSidKey='ar';
            userAdmin.EmailEncodingKey='UTF-8';
            userAdmin.ProfileId=p.Id;
            userAdmin.LanguageLocaleKey='en_US';   
            insert userAdmin;                    
       }
	    
	    System.runAs ( userAdmin ) {
	    	
	    	acc = GW_Account.insertSObject();
            acc = (Account) GW_sObject.queryRecord('Account', acc.id);
            
	        opp1 = GW_Opportunity.createSObject(acc);
	        insert opp1;
	        opp1 = (Opportunity) GW_sObject.queryRecord('Opportunity', opp1.id);
	
	        opp2 = GW_Opportunity.createSObject(acc);
	        insert opp2;
	        opp2 = (Opportunity) GW_sObject.queryRecord('Opportunity', opp2.id);
	    }
	    
        opps.add(opp1);
        opps.add(opp2);
    }


	


	@isTest static void test_baseQueries() {
		createBasedata();        

	    List<Account> accs = (List<Account>) GW_sObject.queryRecords('Account', new Set<Id>{acc.id});
	    system.assertNotEquals(accs.size(),0,'An Account should have been created.');
	
	    Account acc2 = (Account) GW_sObject.queryRecord('Account', acc.id);
	    system.assertEquals(acc.Id, acc2.Id,'Should be same accounts.');
	
	    acc2 = (Account) GW_sObject.queryRecord('Account', acc.id); // query all fields
	    system.assertEquals(acc.Id, acc2.Id,'Should be same accounts.');
	    system.assertNotEquals(acc2.LastModifiedById, null,'All fields should be queried.');
	
	    List<String> fields = new List<String>{'id','createddate'}; // add as lowercase to avoid duplicates
	    acc2 = (Account) GW_sObject.queryRecord('Account', fields, acc.id);
	    system.assertEquals(acc.CreatedDate, acc2.CreatedDate,'Should be same accounts.');
	
	    // custom where clause
	    accs = (List<Account>) GW_sObject.queryRecords('Account', 'Id != null');
	    system.assertEquals(acc.CreatedDate, acc2.CreatedDate,'Should be same accounts.');

	}

	@isTest static void test_exceptions_queries() {
        List<Account> accs;
        Account acc2;
        Set<Id> nullSet;

        createBasedata();
        Test.startTest();        

	        try {
	            accs = (List<Account>) GW_sObject.queryRecords('NO OBJECT', new Set<Id>{acc.id});
	        } catch ( GW_sObject.GW_sObjectException soe) {
	            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
	        }
	
	        try {
	        	
	            accs = (List<Account>) GW_sObject.queryRecords('Account', nullSet);
	        } catch ( GW_sObject.GW_sObjectException soe) {
	            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
	        }
	
	        List<String> fields = new List<String>{'Id','CreatedDate'};
	        try {
	            acc2 = (Account) GW_sObject.queryRecord('NO OBJECT',fields, acc.id);
	        } catch ( GW_sObject.GW_sObjectException soe) {
	            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
	        }
	
	        try {
	            acc2 = (Account) GW_sObject.queryRecord('Account', fields, null);
	        } catch ( GW_sObject.GW_sObjectException soe) {
	            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
	        }
	
	        try {
	            accs = (List<Account>) GW_sObject.queryRecords('Account', '#$%SOMEGARBAGE#$%');
	        } catch ( GW_sObject.GW_sObjectException soe) {
	            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
	        }

        Test.stopTest();
    }

	@isTest static void test_ObjectTypeMethods() {
		Boolean same;
		String objName;

		createBasedata();
		
        same = GW_sObject.isObjectType(acc.id, Account.sObjectType);
	    system.assertEquals(same, true,'Should be same objectTypes.');
	
	    same = GW_sObject.isObjectType(acc.id, Contact.sObjectType);
	    system.assertEquals(same, false,'Should not be same objectTypes.');
	
	   objName = GW_sObject.getobjectNameFromId(acc.Id);
	   system.assertEquals(objName, 'Account','Should be an Account.');

	}

	@isTest static void test_exceptions_ObjectTypeMethods() {
        Boolean same;
		String objName;

        createBasedata();
        
        try {
            objName = GW_sObject.getobjectNameFromId( Id.valueOf('0Z13000001AY8hB') );
        } catch ( GW_sObject.GW_sObjectException soe) {
            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
        }

        try {
            same = GW_sObject.isObjectType(null, Account.sObjectType);
        } catch ( GW_sObject.GW_sObjectException soe) {
            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
        }

    }
	
    @isTest static void test_SetListMethods() {
        Set<Id> idSet;
        List<sObject> objList;

        createBasedata();
        
      
        idSet = GW_sObject.getIdSet(opps);
        System.assert( idSet.size() == opps.size(),'should be same size.' );
	
		idSet = GW_sObject.getParentIds(opps, 'AccountId');
		for (Id theId : idSet) {
			System.assertEquals(theId, acc.Id,'Account acc.Id should be returned.' );
			break;
		}
		
		idSet = GW_sObject.getChildIds(new Set<Id>{acc.Id}, 'Opportunities');
		System.assert(idSet.contains(opp1.Id),'Opp1.Id should be returned.' );
		System.assert(idSet.contains(opp2.Id),'Opp2.Id should be returned.' );
		System.assert(idSet.size()==2,'Only 2 opps should be returned.' );

		try {
            idSet = GW_sObject.getChildIds(new Set<Id>{acc.Id}, 'INVALIDRELATIONSHIP');
        } catch ( GW_sObject.GW_sObjectException soe) {
            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
        }

        objList = GW_sObject.getChildren(acc.Id, 'Opportunities');
        System.assert(objList.size()==2,'Only 2 opps should be returned.' );
        System.assert(objList[0].get('Name') !=null,'Objects Should have been queried.' );

        objList = GW_sObject.getChildren(new Set<Id>{acc.Id}, 'Opportunities');
        System.assert(objList.size()==2,'Only 2 opps should be returned.' );
        System.assert(objList[0].get('Name') !=null,'Objects Should have been queried.' );

        try {
            objList = GW_sObject.getChildren(new Set<Id>{acc.Id}, 'INVALIDRELATIONSHIP');
        } catch ( GW_sObject.GW_sObjectException soe) {
            System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
        }

    }

    @isTest static void test_DescribeMethods() {
    	String fieldType;
    	String fieldLabel;

        createBasedata();
 
	    fieldType = GW_sObject.getFieldType('Account', 'Site');
	    System.assertEquals(fieldType,'STRING');
		
	    fieldLabel =  GW_sObject.getFieldLabel('Account', 'Site');
	    System.assert(fieldLabel.length()>0 );
	
		try {
	         fieldLabel =  GW_sObject.getFieldLabel('Account', 'Bladibla');
	    } catch ( GW_sObject.GW_sObjectException soe) {
	         System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
	    }
	
	    // not a picklist
	    try {
	         fieldLabel =  GW_sObject.getFieldLabel('Account', 'CreatedDate');
	    } catch ( GW_sObject.GW_sObjectException soe) {
	         System.assert( soe.getMessage().contains('Exception in GW_sObject:') );
	    }
	
	    List<String> allFields = GW_sObject.getAllSObjectFieldNames('Account');
	    system.assert(allFields.size()>3);

    }
}