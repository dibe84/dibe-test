@isTest
private class TST_TractInvoicing {
	@testSetup
    public static void setup() {
    	TST_TractGeneric.setup();
    }
    
    /** Test for Q_SyncInvoiceLineStatus.cls **/
    @isTest static void test_Q_SyncInvoiceLineStatus() {
    	
        List<Account> createdAccount = GW_sObject.queryRecords('Account', '');
    	Id accId = createdAccount.get(0).Id;
    	
    	Invoice__c inv = new Invoice__c( 
            UniqueKey__c='TestFQInv', 
            BillingAccount__c = accId, 
            FQ_InvoiceID__c='BEC1507000', 
            StartDate__c = System.today(), 
            EndDate__c = System.today()
        );
    	insert inv;
    	
    	InvoiceLine__c il = new InvoiceLine__c();
        il.Amount__c = 100;
        il.IndirectDiscountAmount__c = 0;
        il.Invoice__c = inv.Id;
        il.InvoiceLineDescription__c = 'Indirect Discount';
        il.Quantity__c = 1;
        il.UniqueKey__c = 'ID_'+inv.Id+'_'; //+inv.StartDate__c;
        il.FQ_ProductCode__c = 'UK_AUS_BAN';
        il.FQ_ProductType__c = 'Banners';
        il.FQ_ProductSubType__c = '';
        il.RS__c = null;
        il.VatPercentage__c = '50';
        il.LineOfBusiness__c = 'AdSales';
        il.CurrencyIsoCode = inv.CurrencyIsoCode;
    	insert il;
    	
    	Q_SyncInvoiceLineStatus qsils = new Q_SyncInvoiceLineStatus();
        Test.startTest();
			System.enqueueJob(qsils);

            Boolean readyForRun = qsils.readyForRun();
            System.assertEquals( true, readyForRun );

            Integer numberRecords = qsils.getNumRecords();
            System.assertEquals( 1, numberRecords );

		Test.stopTest();
    }
    
    /** Test for PGC_InvoicingPendingSend **/
	@isTest static void test_PGC_InvoicingPendingSend () {

		InvoiceBatch__c bat =  GW_InvoiceBatch.createnewBatch('MU123');
		System.debug('###MN - bat :: ' + bat);

		Test.startTest();


			Test.setCurrentPageReference(new PageReference('Test'));
			PGC_InvoicingPendingSend ctrl = new PGC_InvoicingPendingSend();

			ctrl.closeCancelPopup();
			ctrl.closeBatchSendingErrorPopup();
			ctrl.displayCancelPopup();
			ctrl.sendPendingInvoiceBatch();
			ctrl.cancelPendingInvoiceBatch();


		Test.stopTest();
	}

	/** Test for BAT_CancelInvoiceBatch **/
	@isTest static void test_BAT_CancelInvoiceBatch () {

		InvoiceBatch__c invbat =  GW_InvoiceBatch.createnewBatch('MU123');
		//System.debug('###MN - invbat :: ' + invbat);

		//List<InvoiceLine__c> ils = GW_Invoice.generateInvoiceLines(invbat);
		//System.debug('###MN - ils :: ' + ils);

		//Invoice__c inv = GW_Invoice.createInvoiceForInvoiceLine(invbat, ils[0]);
		//System.debug('###MN - inv :: ' + inv);

		Test.startTest();

		BAT_CancelInvoiceBatch bat = new BAT_CancelInvoiceBatch(invbat.BatchId__c, 'Incorrectly created');
		database.executeBatch(bat,1);

		Test.stopTest();
	}
	
	/** Test for PGC_InvoicingBatchHistory.cls **/
	@isTest 
	static void test_PGC_InvoicingBatchHistory() {

        Test.startTest();

		// create invoice batch
		InvoiceBatch__c invoiceBatch = new InvoiceBatch__c();
		invoiceBatch.Name = 'test invoice batch';
		invoiceBatch.Status__c = 'Send To Billing';
		insert invoiceBatch;

		// test set current page reference
		PageReference invPage = Page.InvoicingPage;
		Test.setCurrentPage(invPage);		

		PGC_InvoicingBatchHistory invoiceBatchHistory = new PGC_InvoicingBatchHistory();
		
		String currencyName = invoiceBatchHistory.currencyName;
		invoiceBatchHistory.invoiceBatchId = (String)invoiceBatch.Id;

		System.assertEquals( true, invoiceBatchHistory.historyItems.isEmpty() );
		System.assertEquals( 'REPORT_NOT_FOUND', invoiceBatchHistory.batchHistoryReportId );
		System.assertEquals( 'REPORT_NOT_FOUND', invoiceBatchHistory.batchHistoryFailedInvoicesReportId );

		Test.stopTest();
	}
}