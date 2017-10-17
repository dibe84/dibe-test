public with sharing class PGC_InvoicingBatchHistory {
    
    public String memberId { get; set; }
    private List<Member__c> members = new List<Member__c>();
    public List<GW_InvoiceBatch.InvoiceBatchHistoryItem> historyItems { get; set; }
    public String batchHistoryReportId { get; set; }
    public String batchHistoryFailedInvoicesReportId { get; set; }
    public String historySelMemberUnitId { get; set; }
    
    public String currencyName { get {
        return UserInfo.getDefaultCurrency();
    }}
    
    public String invoiceBatchId { get; set; }

    PageReference dashBoardPageRef = ApexPages.currentPage();

    public PGC_InvoicingBatchHistory() {
        this.historyItems = new List<GW_InvoiceBatch.InvoiceBatchHistoryItem>();
        this.batchHistoryReportId = getBatchHistoryReportId();
        this.batchHistoryFailedInvoicesReportId = getBatchHistoryFailedInvoicesReportId();
    }

	public void setMemberUnitHistoryApex(){
		if( String.isBlank( historySelMemberUnitId ) ) historySelMemberUnitId = null;
		retrieveBatchHistoryList();
	}

    public PageReference retrieveBatchHistoryList() {
        this.historyItems = retrieveBatchHistory();
        return null;
    }

    private String getBatchHistoryReportId() {
        List<Report> reports = [ SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Invoicing_Batch_Invoices' ];

        return reports.size() > 0 ? (String) reports.get(0).get('Id') : 'REPORT_NOT_FOUND';
    }

    private String getBatchHistoryFailedInvoicesReportId() {
        List<Report> reports = [ SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Invoicing_Batch_Failed_Invoices' ];

        return reports.size() > 0 ? (String) reports.get(0).get('Id') : 'REPORT_NOT_FOUND';
    }

    private List<GW_InvoiceBatch.InvoiceBatchHistoryItem> retrieveBatchHistory() {
        return GW_InvoiceBatch.getHistoryListWithLimit( 25 , historySelMemberUnitId );
    }

    public PageReference resendFailed() {
        GW_InvoiceBatch.resendInvoiceBatchFailedInvoices(invoiceBatchId);
        PageReference pr = new PageReference(dashBoardPageRef.getUrl());
        pr.setRedirect(true);

        return pr;
    }
}