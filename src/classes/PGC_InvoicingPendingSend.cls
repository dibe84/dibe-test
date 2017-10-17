public with sharing class PGC_InvoicingPendingSend {

    public List<GW_InvoiceBatch.InvoiceBatchItem> pendingSendBatches { get; set; }
    public String pendingSendBatchReportId { get; set; }
    public String invoiceBatchId { get; set; }
    public InvoiceBatch__c batch { get; set; }
    public Boolean displayCancelPopup { get; set; }
    public String pendingSelMemberUnitId { get; set; }
    
    public String batchSendingError { get; set; }
    public Boolean displayBatchSendingErrorPopup { get; set; }

    public String currencyName { get {
        return UserInfo.getDefaultCurrency();
    }}

	public void setMemberUnitPendingApex(){
		if( String.isBlank( pendingSelMemberUnitId ) ) pendingSelMemberUnitId = null;
		retrievePendingSendBatchList();
	}
    
    PageReference dashBoardPageRef = ApexPages.currentPage();

    public PGC_InvoicingPendingSend() {
        this.batch = new InvoiceBatch__c();
        this.pendingSendBatches = new List<GW_InvoiceBatch.InvoiceBatchItem>();
        this.pendingSendBatchReportId = getPendingSendBatchReportId();
    }

    public void retrievePendingSendBatchList() {
        this.pendingSendBatches = GW_InvoiceBatch.getInvoicePendingSendBatchList( pendingSelMemberUnitId );
    }

    private String getPendingSendBatchReportId() {
        List<Report> reports = [ SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Invoicing_Batch_Invoices' ];

        return reports.size() > 0 ? (String) reports.get(0).get('Id') : 'REPORT_NOT_FOUND';
    }

    public void closeCancelPopup() {
        displayCancelPopup = false;
        batch.CancellationReason__c = null;
    }

    public void closeBatchSendingErrorPopup() {
    	batchSendingError = '';
        displayBatchSendingErrorPopup = false;
    }

    public void displayCancelPopup() {
        displayCancelPopup = true;
    }

    public PageReference sendPendingInvoiceBatch() {

        PageReference pr = null;

    	try {
    		if( GW_InvoiceBatch.batchHasUnhealthyAccounts( invoiceBatchId ) ){
    			batchSendingError = 'You have at least 1 billing account that is incomplete. Please amend this / these accounts before sending.';
    			displayBatchSendingErrorPopup = true;
    		} else {
	            GW_InvoiceBatch.sendToBilling( invoiceBatchId );
	            pr = new PageReference(dashBoardPageRef.getUrl());
	            pr.setRedirect(true);
    		}    
    	}catch( Exception ex ){
    		batchSendingError = ex.getMessage();
    		displayBatchSendingErrorPopup = true;
    	}

        return pr;
    }

    public PageReference cancelPendingInvoiceBatch() {
        try {
            GW_Invoice.cancelInvoicingBatch(invoiceBatchId, batch.CancellationReason__c);
        } catch (Exception e) {
            UTIL.log('An error occured while cancelling the invoice batch. Error: ' + e.getMessage());
        }

        PageReference pr = new PageReference(dashBoardPageRef.getUrl());
        pr.setRedirect(true);
        return pr;
    }
}