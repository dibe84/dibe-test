public with sharing class PGC_Invoicing {
	
    public InvoicingSummary summary { get; set; }
    public String openItemsReportId { get; set; }
    public String exceptionsReportId { get; set; }
    public String overdeliveryReportId  { get; set; }
    public String negativeBalanceReportId { get; set; }
    public String memberUnitId { get; set; }
    public String openSelMemberUnitId { get; set; }
	public String metriceCompletedReportId { get; set; }
	
    public String currencyName { 
		get {
			return UserInfo.getDefaultCurrency();
		}
	}
	
	public void setMemberUnitOpenApex(){
		if( String.isBlank( openSelMemberUnitId ) ) openSelMemberUnitId = null;
		this.retrieveInvoicingSummary();
	}
	
	//Report filter only work with date format mm/dd/yyyy
    public String currentDateReportFormat { get 
    	{ 
    		return system.now().format('MM/dd/yyyy');
    	}
    }

    public PGC_Invoicing() {
        //retrieveInvoicingSummary();
        this.openItemsReportId = getInvoicingOpenItemReportId();
        this.exceptionsReportId = getInvoicingExceptionsReportId();
        this.negativeBalanceReportId = getNegativeBalanceReportId();
        this.overdeliveryReportId = getOverdeliveryReportId();
		this.metriceCompletedReportId = getMetriceCompletedReportId();
    }

    public PageReference retrieveInvoicingSummary() {
		System.debug( 'DELTA' );
		System.debug( openSelMemberUnitId );
        this.summary = new InvoicingSummary( openSelMemberUnitId );
        return null;
    }

    private String getInvoicingOpenItemReportId() {
        List<Report> reports = [ SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Invoicing_Open_Items' ];

        return reports.size() > 0 ? (String) reports.get(0).get('Id') : 'REPORT_NOT_FOUND';
    }

    private String getInvoicingExceptionsReportId() {
        List<Report> reports = [ SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Invoicing_Exceptions' ];

        return reports.size() > 0 ? (String) reports.get(0).get('Id') : 'REPORT_NOT_FOUND';
    }

    private String getNegativeBalanceReportId() {
        List<Report> reports = [ SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Negative_Balance_Open_Items' ];

        return reports.size() > 0 ? (String) reports.get(0).get('Id') : 'REPORT_NOT_FOUND';
    }

    private String getOverdeliveryReportId() {
        List<Report> reports = [ SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Overdelivery_Open_Items' ];

        return reports.size() > 0 ? (String) reports.get(0).get('Id') : 'REPORT_NOT_FOUND';
    }
	
	//Get Metrice Completed Report Id - 28/03/2017
    private String getMetriceCompletedReportId() {
        List<Report> reports = [ SELECT Id, DeveloperName FROM Report WHERE DeveloperName='Metrics_Completion' ];

        return reports.size() > 0 ? (String) reports.get(0).get('Id') : 'REPORT_NOT_FOUND';
    }

    public PageReference generateInvoiceBatch() {
        PageReference pageRef = ApexPages.currentPage();

        if (null != memberUnitId) {
            try {
            	GW_Invoice.processBatch(memberUnitId);
            } catch (Exception e) {
            	UTIL.log('Exception occured while trying to generate invoice batch for ' + memberUnitId + ': ' + e.getMessage());
            }
        	pageRef.setRedirect(true);
        }
        return pageRef;
    }

    public class InvoicingSummary {
        public Integer totalOpenItems { get; set; }
        public Decimal totalAmount { get; set; }
        public Map<String, InvoicingDetailRow> detailRows { get; set; }

        public InvoicingSummary( String selMemberUnitId ) {
            
            List<RS__c> rss = GW_Invoice.getPGCInvoicingReadyRS( selMemberUnitId );
        	List<Rev__c> revs = GW_Invoice.getPGCInvoicingReadyRevItems( selMemberUnitId );

            this.totalOpenItems = rss.size() + revs.size();
            this.totalAmount = 0;

            buildDetailRows(GW_sObject.getIdSet(rss), GW_sObject.getIdSet(revs) , selMemberUnitId );
        }

        private void buildDetailRows(Set<Id> rsIdsToInv, Set<Id> revIdsToInv , String selMemberUnitId ) {
        	
            detailRows = new Map<String, InvoicingDetailRow>();

            List<AggregateResult> openItemSummary = [SELECT  SUM(InvoicingBalance__c) balanceTotal, COUNT(Id) numItems, Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c FROM Rs__c WHERE Id IN :rsIdsToInv AND Opportunity__r.MemberUnit__c = :selMemberUnitId GROUP BY Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c ];
            List<AggregateResult> revOpenItemSummary = [SELECT SUM(InvoicingBalance__c) balanceTotal, COUNT(Id) numItems, Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c FROM Rev__c WHERE Id IN :revIdsToInv AND Opportunity__r.MemberUnit__c = :selMemberUnitId GROUP BY Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c ];

            List<AggregateResult> negativeBalanceOpenItemSummary = [SELECT SUM(InvoicingBalance__c) negBalanceTotal, Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c FROM Rs__c WHERE Id IN :rsIdsToInv AND Opportunity__r.MemberUnit__c = :selMemberUnitId AND InvoicingBalance__c < 0 GROUP BY Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c ];
            List<AggregateResult> revNegativeBalanceOpenItemSummary = [SELECT SUM(InvoicingBalance__c) negBalanceTotal, Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c FROM Rev__c WHERE Id IN :revIdsToInv AND Opportunity__r.MemberUnit__c = :selMemberUnitId AND InvoicingBalance__c < 0 GROUP BY Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c ];

            List<AggregateResult> overdeliveryOpenItemSummary = [SELECT SUM(RevenueOverdelivered__c) overdeliveryTotal, Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c FROM Rs__c WHERE Id IN :rsIdsToInv AND Opportunity__r.MemberUnit__c = :selMemberUnitId GROUP BY Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c ];
			
			//get number of uncompleted metrices per each member
			List<AggregateResult> numOfuncomMetricePerMU = [SELECT Count(Id) numuncompletMet, Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c FROM RS__c WHERE ID IN: rsIdsToInv AND Opportunity__r.MemberUnit__c = :selMemberUnitId AND Until_Date__c < TODAY AND CompletedMetrics__c < 100 AND BillingCategoryCalculation__c NOT IN ('ServiceFee_OneTime', 'ServiceFee_MonthlyFixed') GROUP BY Opportunity__r.MemberUnit__r.Member__r.MemberId__c, Opportunity__r.MemberUnit__r.LineOfBusiness__c];
			
            openItemSummary.addAll(revOpenItemSummary);
            negativeBalanceOpenItemSummary.addAll(revNegativeBalanceOpenItemSummary);

            for (AggregateResult ar : openItemSummary) {
                String memberUnitId = (String) ar.get('MemberId__c') + (String) ar.get('LineOfBusiness__c');

                if (false == detailRows.containsKey(memberUnitId)) {
                    detailRows.put(memberUnitId, new InvoicingDetailRow());
                    detailRows.get(memberUnitId).memberUnitId = memberUnitId;
                }

                detailRows.get(memberUnitId).openItems += (Integer) ar.get('numItems');
                detailRows.get(memberUnitId).amount += (Decimal) ar.get('balanceTotal');

                totalAmount += (Decimal) ar.get('balanceTotal');
            }

            for (AggregateResult ar : negativeBalanceOpenItemSummary) {
                String memberUnitId = (String) ar.get('MemberId__c') + (String) ar.get('LineOfBusiness__c');
                detailRows.get(memberUnitId).negativeBalanceAmount += (Decimal) ar.get('negBalanceTotal');
            }

            for (AggregateResult ar : overDeliveryOpenItemSummary) {
                String memberUnitId = (String) ar.get('MemberId__c') + (String) ar.get('LineOfBusiness__c');
                detailRows.get(memberUnitId).overdeliveredAmount += (Decimal) ar.get('overdeliveryTotal');
            }
			
			//get number of uncompleted metrices per each member 27/03/2017
            for (AggregateResult ar : numOfuncomMetricePerMU) {
                String memberUnitId = (String) ar.get('MemberId__c') + (String) ar.get('LineOfBusiness__c');
                detailRows.get(memberUnitId).numOfUncompletedMetrice += (Integer) ar.get('numuncompletMet');
            }
			
            Map<String, Integer> exceptionMap = GW_Opportunity.createExceptionSummaryMap( selMemberUnitId );

            for (String memberUnitId : exceptionMap.keySet()) {
            	
                if ( !detailRows.containsKey(memberUnitId)  ) {
                    detailRows.put(memberUnitId, new InvoicingDetailRow());
                    detailRows.get(memberUnitId).memberUnitId = memberUnitId;
                }
                detailRows.get(memberUnitId).exceptions = exceptionMap.get(memberUnitId);
            }

            // remove lines for MemberUnit batches that are busy generating invoices
            List<InvoiceBatch__c> processingBatches = (List<InvoiceBatch__c>) GW_sObject.queryRecords('InvoiceBatch__c', 'Status__c IN (\'Generating Invoices\', \'Cancelling Batch\')');

            for (InvoiceBatch__c batch : processingBatches) {
                if (!detailRows.containsKey(batch.MemberUnitId__c)) {
                    continue;
                }
                totalAmount -= detailRows.get(batch.MemberUnitId__c).amount;
                detailRows.remove(batch.MemberUnitId__c);
            }
        }
    }

    public class InvoicingDetailRow {
        public String memberUnitId { get; set; }
        public Integer openItems { get; set; }
        public Integer exceptions { get; set;  }
        public Decimal amount { get; set; }
        public Decimal overdeliveredAmount { get; set; }
        public Decimal negativeBalanceAmount { get; set; }
		public Integer numOfUncompletedMetrice { get; set;  }

        public InvoicingDetailRow() {
            this.openItems = this.exceptions = this.numOfUncompletedMetrice = 0;
            this.amount = this.overdeliveredAmount = this.negativeBalanceAmount = 0;
        }
    }
}