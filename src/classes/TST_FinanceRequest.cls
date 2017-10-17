@isTest
private class TST_FinanceRequest {
	
	public static Account acc;
	public static Contact con;
	public static Case caseObject;
	public static Tract_Invoice__c inv;
	public static List<Tract_Invoice_Item__c> invIList = new List<Tract_Invoice_Item__c>();

	public static void createTractInvoice(){
		inv = new Tract_Invoice__c();
		inv.Billing_Account__c = acc.Id;
		inv.Amount__c = 43.9;
		inv.Billing_Period__c = 'Monthly';
		inv.Currency_Code__c = 'EUR';
		inv.External_Id__c = '1234';
		inv.Billing_Scheme__c = 'Direct Debit';
		inv.Due_Date__c = System.today().addMonths(1);
		inv.Finance_Contact_Email__c = 'josh@debug.com';
		inv.Occurred_On__c = System.today().addDays(-3);
		inv.Status__c = 'Draft';
		inv.Name = '3242';

		insert inv;
		//inv = GW_TractInvoice.getRecord(inv.Id);
		createTractInvoiceItem();
	}

	public static void createTractInvoiceItem() {
		Tract_Invoice_Item__c invI = new Tract_Invoice_Item__c();
		invI.Description__c = 'Test Description';
		invI.End_Date__c = System.today().addMonths(11);
		invI.External_Id__c = '23452';
		invI.P_O_Number__c = '32498';
		invI.Quantity__c = 3;
		invI.Start_Date__c = System.today();
		invI.Status__c = 'Draft';
		invI.TRACT_Invoice__c = inv.Id;
		invI.Unit_Amount__c = 345.20;

		insert invI;
		invIList.add(invI);
	}

	public static void createCase() {
		caseObject = new Case();
		caseObject.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Finance Support').getRecordTypeId();
		caseObject.Subject = 'Test';
		caseObject.AccountId = acc.Id;
		caseObject.ContactId = con.Id;
		caseObject.Description = 'TEST Description';
		insert caseObject;
	}

	public static void setup() {
		// Insert account
		// get it tract enabled
		// create tract invoice object
		// create tract invoice line item objects
		// create case 
		// create finance request
		acc = GW_Account.insertSObject();
		acc.Tract_AccountId__c = '3422';
		acc.Tract_AccountNumber__c = 'EKA23423';
		update acc;
		con = GW_Contact.createSObject('TestLast', acc);
		createTractInvoice();
		createCase();

	}

	@isTest static void testCreateFinanceRequest(){
		setup();
		Finance_Request__c fr = new Finance_Request__c();
		fr.RecordTypeId = Schema.SObjectType.Finance_Request__c.getRecordTypeInfosByName().get('Full Credit & Reissue').getRecordTypeId();
		fr.Billing_Account__c = acc.Id;
		fr.Case__c = caseObject.Id;
		fr.Line_Item_PO_Number__c = 2332;
		fr.Reason__c = 'Incorrect pricing';
		fr.Reason_Description__c = 'sjdjfhjfkkfjsd';
		fr.TRACT_Invoice__c = inv.Id; 
		insert fr;

		System.assertEquals(GW_FinanceRequest.getRecord(fr.Id).Status__c, 'New');
		System.assertEquals([select count() from Finance_Request_Line_Item__c where Finance_Request__c =: fr.Id], 1);

	}

	@isTest static void testRecalculate(){
		setup();
		Finance_Request__c fr = new Finance_Request__c();
		fr.Billing_Account__c = acc.Id;
		fr.Case__c = caseObject.Id;
		fr.Line_Item_PO_Number__c = 2332;
		fr.Reason__c = 'Incorrect pricing';
		fr.Reason_Description__c = 'sjdjfhjfkkfjsd';
		fr.TRACT_Invoice__c = inv.Id; 
		insert fr;
		Finance_Request__c frObject = GW_FinanceRequest.getRecord(fr.Id);

		System.assertEquals(frObject.Status__c, 'New');

		GW_FinanceRequest.recalculate(acc.Id, frObject.Id);

	}

	@isTest static void testCreateInvoiceReissue(){
		setup();
		Finance_Request__c fr = new Finance_Request__c();
		fr.Billing_Account__c = acc.Id;
		fr.Case__c = caseObject.Id;
		fr.Line_Item_PO_Number__c = 2332;
		fr.Reason__c = 'Incorrect pricing';
		fr.Reason_Description__c = 'sjdjfhjfkkfjsd';
		fr.TRACT_Invoice__c = inv.Id; 
		insert fr;
		Finance_Request__c frObject = GW_FinanceRequest.getRecord(fr.Id);

		System.assertEquals(frObject.Status__c, 'New');
		System.assertEquals(frObject.Needs_Recalculation__c, true);
		GW_FinanceRequest.recalculate(acc.Id, frObject.Id);

		frObject = GW_FinanceRequest.getRecord(fr.Id);
		System.assertEquals(frObject.Needs_Recalculation__c, false);

		frObject.Status__c = 'Approved';
		update frObject;



	}
	
	
}