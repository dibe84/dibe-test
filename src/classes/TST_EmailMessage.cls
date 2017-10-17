@isTest
public class TST_EmailMessage {
    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void testReopenCaseWhenMasessageReplied(){
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        String testSubject = 'TST_emailMessage_Subject';
        Test.startTest();
        // here is an existing close case
        fac.createCase(testSubject);
        fac.cs.Status = 'Closed';
        update fac.cs;
        ID oldClosedCaseId = fac.cs.Id;
        // here is an replied message
        fac.createCase(testSubject);
        fac.createEmailMessage(testSubject);
        
        // new message is linked to closed case
        EmailMessage emailMsg = GW_EmailMessage.getRecord(fac.emailMessage.Id);
        System.assertEquals(oldClosedCaseId, emailMsg.ParentId);
        // the closed case has been reopened
        Case reopenCase = GW_EmailMessage.queryCaseRecords(new Set<Id>{oldClosedCaseId})[0];
        System.assertEquals('Reopen', reopenCase.Status);
        Test.stopTest();
    }
}