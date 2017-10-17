@isTest
public with sharing class TST_LCS_Console_RelatedListController {
	
	public static Boolean noContactError = false;
	static testMethod void test_relatedListInit() {
		Contact c = new Contact(LastName = 'TST_Contact');
		insert c;
		Case cs = new Case(RecordTypeId= GW_Case.recordTypeIdECGDKCS, SuppliedEmail= 'TST_Case@test.com',  
							ContactId = c.Id, SuppliedName = 'TST_Case1', SuppliedPhone = '+123456789', Origin = 'Web');
		insert cs;

		Test.startTest();
			LCS_Console_RelatedListController rlCntr = new LCS_Console_RelatedListController();
			rlCntr.objectId = cs.Id;
			Boolean isObjError = testRLPageErrors(LCS_Console_RelatedListController.RL_WRONG_OBJECT);
			System.assertNotEquals(isObjError, true, 'No error - correct object'); 

			/* ------- test LPC_RelatedList page errors -------- */
			rlCntr.objectId = c.Id; // not supported object for the related list 
			isObjError = testRLPageErrors(LCS_Console_RelatedListController.RL_WRONG_OBJECT);
			System.assert(isObjError);

			noContactError = true;
			rlCntr.objectId = cs.Id;
			Boolean isNoCnontError = testRLPageErrors(LCS_Console_RelatedListController.RL_NO_CONTACT);
			System.assert(isNoCnontError);
		Test.stopTest();
	}

	private static Boolean testRLPageErrors(String pgError){
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		Boolean isError = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains(pgError)){
		    	isError = true;
		    } 
		}
		return isError;
	}
}