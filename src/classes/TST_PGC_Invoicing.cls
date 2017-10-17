/**
 * @desc : cover class PGC_Invoicing.cls
 * @createddate : 28 Mar 2017
 * @author : Gaeasys Team
 * @change log :
 *
 */
@isTest private class TST_PGC_Invoicing {
	
    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    
    @istest static void test_invoicing() {
        TST_DataFactory fac = TST_DataFactory.getInstance();
        fac.queryResults();
        Test.startTest();
			PGC_Invoicing con = new PGC_Invoicing();   
			PGC_Invoicing.InvoicingDetailRow invDetail = new PGC_Invoicing.InvoicingDetailRow(); 
			system.assertEquals(con.currencyName, UserInfo.getDefaultCurrency());
			system.assertEquals(con.currentDateReportFormat, system.now().format('MM/dd/yyyy'));
        Test.stopTest();
    } 
    
    @istest static void test_generateInvoiceBatch() {
        TST_DataFactory fac = TST_DataFactory.getInstance();
        fac.queryResults();
        Test.startTest();
        	PageReference invPage = Page.InvoicingPage;
        	Test.setCurrentPage(invPage);
        	
			PGC_Invoicing con = new PGC_Invoicing();  
			con.memberUnitId = 'THBE2AD';
			PageReference pagereturn = con.generateInvoiceBatch();   
        Test.stopTest();
    } 
}