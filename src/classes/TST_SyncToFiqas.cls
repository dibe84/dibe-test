@isTest
public class TST_SyncToFiqas {
    // Using basic AdSales Test set:
    // Account acc
    // Opportunity opp
    // Oli1: 1/1/2030 - 30/6/2030
    // Oli2: 31/1/2030 - 1/6/2030
    @testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet(); 
		UTIL_CustomJob.startCustomJob('BAT_AccountSyncFiqas');
    	UTIL.isRunningTestSetup = false;
    }

    @isTest static void testSettingSyncBoxesAccount() {
		// retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        System.runAs ( fac.testUser ) {
        	TST_DataFactory.completeAccountDetails(fac.acc, fac.con);
        }
        Test.stopTest();

        fac.queryResults();
        // all checkboxes should be set to true
        System.assertEquals(TRUE,fac.acc.FQ_syncAccountDetails__c);
    }
    
    @isTest static void testSuccessfulAccountSync() {
		// retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        System.runAs ( fac.testUser ) {
            System.assertNotEquals(null, fac.acc.Member__c);
              TST_DataFactory.changeAccountDetails(fac.acc, fac.con);
        }
		// The custom job should handle the sync process
        fac.queryResults();
        System.assertEquals(TRUE,fac.acc.FQ_syncAccountDetails__c);
        System.runAs ( fac.adminUser ) { 
            UTIL_CustomJob.startCustomJob('BAT_AccountSyncFiqas');
        }
        Test.stopTest();

        fac.queryResults();
        System.assertEquals(FALSE,fac.acc.FQ_syncAccountDetails__c);
        System.assertEquals(null,fac.acc.FQ_SyncReason__c);
        System.assertEquals('OK',fac.acc.FQ_SyncStatus__c);
    }

    @isTest static void testSuccessfulContactUpdateSync() {
		// retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        System.assertEquals(false,fac.acc.FQ_syncAccountDetails__c);
        
        Test.startTest();
        System.runAs ( fac.testUser ) {
        	fac.con.Email = 'othercontact@email.com';
        	fac.con.Salutation = 'Mrs.';
           	fac.con.LastName = 'test';
           	update fac.con;
        }
        Test.stopTest();

        fac.queryResults();

        System.assertEquals(TRUE, fac.acc.FQ_syncAccountDetails__c);
        
    }
    
    @isTest static void testAccountSyncMissingFields() {
		// retrieve test data, not all mandatory info is filled. Sync to fiqas should return error
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        Test.startTest();
        System.runAs ( fac.testUser ) {
        	fac.acc.FQ_syncAccountDetails__c = true;
            update fac.acc;
        }
		// The custom job should handle the sync process
        System.runAs ( fac.adminUser ) { 
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();

        fac.queryResults();
        System.assertEquals('FAILED - Missing fields for sync to Billing',fac.acc.FQ_SyncStatus__c);    	
    } 
/*    
    @isTest static void testSuccessfulInvoiceSync() {
		// create data set with Rev__c/RS__c/Metrics__c/Invoice__c, including a finished month, with all mandatory fields for Fiqas filled (see WSC_Fiqas.getFiqasInvoiceInput() for mandatoryfields) 
		// make sure all metric Clicks and Impressions will be filled, setting the RS__c in "Metrics Complete" (3) status
		// try to invoice a finished month, emulating pressing the 'Send to Billing' button on Invoices list view (calling: GW_Invoice.sendInvoices() webservice)
        // Assert that FQ_SyncStatus__c is set to 'Sent to Fiqas' for the Invoice__c and RS__c records below
       	
        completeAccountDetails(fac.account);
        completeContactDetails(fac.contact);
        
        Date period1Start = Date.newInstance(2015, 01, 01);
        Date period1End	= Date.newInstance(2015, 01, 01);
        Date period2Start = Date.newInstance(2015, 02, 26);
        Date period2End = Date.newInstance(2015, 02, 26);
        fac.generateOppLineItems(period1Start, period1End, period2Start, period2End);
        fac.queryResults();
  
        Test.startTest();
           GW_Invoice.sendInvoices(fac.invoices);
        Test.stopTest();
   
        InvoiceLine__c inv = [Select id, FQ_SyncStatus__c from InvoiceLine__c where Invoice__c =: lstInvId[0]];
        System.assertEquals(inv.FQ_SyncStatus__c,'OK');   
    }
    
    @isTest static void testInvoiceSyncMissingFields() {
		// create same set as in succes scenario, but leave out a mandatory field (null), assert that FQ_SyncStatus__c is set to 'FAILED' and a missing field is mentioned in  FQ_SyncReason__c

		       
        Date period1Start = Date.newInstance(2014, 12, 26);
        Date period1End	= Date.newInstance(2015, 01, 26);
        Date period2Start = Date.newInstance(2015, 02, 26);
        Date period2End = Date.newInstance(2015, 02, 26);
        fac.generateOppLineItems(period1Start, period1End, period2Start, period2End);
        fac.queryResults();
        RS__c rs = GW_RS.getRecord(fac.rss[0].Id);
        //WSC_Fiqas.getFiqasInvoiceInput(rs);
        
        

        //----------------------------------
		
    }
    
    @isTest static void testInvoiceSyncMetricsNotComplete() {
		// create same set as in succes scenario, but leave 1 or more Metric__c records incomplete, assert that rs.FQ_SyncStatus__c is set to 'FAILED' and rs.FQ_SyncReason__c = 'Revenue Schedule not ready for Invoicing'
    }
*/
    
}