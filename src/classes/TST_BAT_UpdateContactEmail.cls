@isTest
private class TST_BAT_UpdateContactEmail {
	
	static void createTestData(){
		//create account
		Account newAcct = new Account();
        newAcct.Name = 'Test Account 1'; 
        insert newAcct;
        //create contact
		List<Contact> conts = new List<Contact>();
		Contact con=new Contact();
        con.LastName='TestContact';
        con.AccountId=newAcct.Id;
        con.Fax='1234567';
        con.Email='test1@test.com';
        con.MobilePhone='+13469756789';
		conts.add(con);
		
        Contact con2=new Contact();
        con2.LastName='TestContact2';
        con2.AccountId=newAcct.Id;
        con2.Fax='1234567';
        con2.Email='test2@test.com';
        con2.MobilePhone='+13469756789';
		conts.add(con2);
		
        Contact con3=new Contact();
        con3.LastName='TestContact3';
        con3.AccountId=newAcct.Id;
        con3.Fax='1234567';
        con3.Email='test3@test.com';
        con3.MobilePhone='+13469756789';
        conts.add(con3);
        insert conts;
	}
	
    static testMethod void testUpdateContactEmail() {
    	createTestData();
        Test.startTest();
			//call batch to update contact's email
	        BAT_UpdateContactEmail batUpdateCont = new BAT_UpdateContactEmail();
	        ID batchprocessid = Database.executeBatch(batUpdateCont);
		Test.stopTest();
		List<Contact> lstConts2 = [Select Id, Email From Contact limit 10];
	    System.assertEquals('test1@example.com', [Select Id, Email From Contact Where email = 'test1@example.com'].email);
	    System.assertEquals('test2@example.com', [Select Id, Email From Contact Where email = 'test2@example.com'].email);
        
    }
}