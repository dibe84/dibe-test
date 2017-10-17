///////////////////////////////////////////////////////////////////////////
// Class Finance Request Gateway  --
//
// 
//
///////////////////////////////////////////////////////////////////////////
global with sharing class GW_FinanceRequest {

	private static final Schema.sObjectType GW_BASEOBJECT = Finance_Request__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Finance_Request__c';

	//////////////////////////////////////////////////////////////////////////////////////////////////////
	// public query methods
	//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Finance_Request__c           getRecord(Id id)           { return (Finance_Request__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<Id,Finance_Request__c>   getMap(Set<id> ids)        { return new Map<Id,Finance_Request__c>( getList(ids) ); }
    public static List<Finance_Request__c>     getList(Set<id> ids)       { return (List<Finance_Request__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }


    public static void createFinanceRequest(List<Finance_Request__c> frList) {
    	if ( frList == null || frList.isEmpty() ) return;

    	List<Finance_Request__c> financeRequestToProcess = new List<Finance_Request__c>();

    	Set<Id> tractInvoiceIdList = new Set<Id>();
    	for (Finance_Request__c record: frList) {
    		record.Status__c = 'New';
    		record.Needs_Recalculation__c = true;
    		tractInvoiceIdList.add(record.TRACT_Invoice__c);
    		//record.Billing_Account__c = getBillingAccountId(record.TRACT_Invoice__c);
    		financeRequestToProcess.add(record);
    	}

    	try{

    		Map<Id, Tract_Invoice__c> tractInvoiceMap = getRelatedInvoices ( tractInvoiceIdList );
	    	Map<Id, Finance_Request__c> financeRequestToInsertMap = new Map<Id, Finance_Request__c>();
	    	
	    	if ( tractInvoiceMap != null && !tractInvoiceMap.isEmpty() ) {
		    	
		    	for (Finance_Request__c record: financeRequestToProcess ) {
		    		Tract_Invoice__c ti = tractInvoiceMap.get(record.TRACT_Invoice__c);
		    		
		    		if ( ti != null ) {
		    			record.Billing_Account__c = ti.Billing_Account__c;
		    			record.New_Amount_Excl_VAT__c = ti.Amount__c;
		    			financeRequestToInsertMap.put(ti.Id, record);
		    		}

		    	}
		    }

		} catch ( Exception ex ) {
			UTIL.log(ex.getMessage());
		}
    	

    } //end createFinanceRequest

    webservice static void recalculate(Id accId, Id fRequestId) {
    	if ( accId == null || fRequestId == null ) return;

    	try{
    		Finance_Request__c fReqObject = GW_FinanceRequest.getRecord(fRequestId);
    		if ( fReqObject != null ) {
	    		fReqObject.Needs_Recalculation__c = false;
	    		Map<String, Object> rateMap = WSC_Tract.getTaxRatesTable(fReqObject.Id);
	    		Double rateValue = 0.0;
	    		if (rateMap != null){
	    			rateValue = Double.valueOf(rateMap.get('rate'));
	    			fReqObject.New_Taxes_Fees__c = rateValue * fReqObject.New_Amount_Excl_VAT__c;
	    		}
	    		update fReqObject;
	    		updateFinanceRequestLineItem( new Set<Id> {fReqObject.Id}, rateValue);
	    	}
		} catch (Exception ex) {
			UTIL.log(ex.getMessage());
		}

    }

    private static void updateFinanceRequestLineItem ( Set<Id> frIdSet, Double taxRate ) {
    	if ( frIdSet == null || frIdSet.isEmpty() ) return;

    	List<Finance_Request_Line_Item__c> frliList = new List<Finance_Request_Line_Item__c>();
    	for(Finance_Request_Line_Item__c record: [Select Id, New_Taxes_Fees__c, New_Amount_Excl_Tax__c from Finance_Request_Line_Item__c where Finance_Request__c =: frIdSet] ) {
    		record.New_Taxes_Fees__c = record.New_Amount_Excl_Tax__c * taxRate;
    		frliList.add(record);
    	}

    	update frliList;

    }

    public static void createFinanceRequestLineItem ( List<Finance_Request__c> frList ) {
    	if ( frList == null || frList.isEmpty() ) return;

    	Set<Id> tractInvoiceIdList = new Set<Id>();
    	for ( Finance_Request__c record: frList ) {
    		tractInvoiceIdList.add(record.TRACT_Invoice__c);
    	}

    	Map<Id, Tract_Invoice__c> tractInvoiceMap = getRelatedInvoices ( tractInvoiceIdList );
    	List<Finance_Request_Line_Item__c> financeRequestLineItemsToInsert = new List<Finance_Request_Line_Item__c>();

    	if ( tractInvoiceIdList != null && !tractInvoiceIdList.isEmpty() ) {

    		for ( Finance_Request__c record: frList ) {

    			TRACT_Invoice__c tractInvoice = tractInvoiceMap.get(record.TRACT_Invoice__c);
    			if ( tractInvoice != null ) {
    				List<Tract_Invoice_Item__c> tiiList = tractInvoice.Tract_Invoice_Items__r;

	    			for (Tract_Invoice_Item__c recordTII : tiiList) { 
		    			Finance_Request_Line_Item__c frli = new Finance_Request_Line_Item__c();
		    			frli.Finance_Request__c = record.Id;
		    			frli.Billing_Account__c = record.Billing_Account__c;
		    			frli.TRACT_Invoice_Item__c = recordTII.Id;
		    			frli.New_Amount_Excl_Tax__c = recordTII.Unit_Amount__c;

		    			financeRequestLineItemsToInsert.add(frli);
		    		}

    			}

    		}

    		insert financeRequestLineItemsToInsert;

    	}

    }

    private static Map<Id, TRACT_Invoice__c> getRelatedInvoices ( Set<Id> tractInvoiceId ) {
    	if ( tractInvoiceId == null ) return null;
    	return new Map<Id, Tract_Invoice__c>([select Id, Billing_Account__c, Amount__c, (select Id, Name, Unit_Amount__c from Tract_Invoice_Items__r) from Tract_Invoice__c where Id =:tractInvoiceId]);
    }

}