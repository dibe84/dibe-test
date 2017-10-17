public with sharing class GW_InvoiceLine {

    private static final Schema.sObjectType GW_BASEOBJECT = InvoiceLine__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'InvoiceLine__c';
	public static final String BILLINGSCHEME_MONTHLYINARREARS = 'Monthly in Arrears';
	public static final String BILLINGSCHEME_MULTIMONTHFIRSTBATCH = 'Multi-month first Batch';


    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // public query methods
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    public static InvoiceLine__c           getRecord(Id id)           { return (InvoiceLine__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,InvoiceLine__c>   getMap(Set<id> ids)        { return new Map<id,InvoiceLine__c>( getList(ids) ); }
    public static List<InvoiceLine__c>     getList(Set<id> ids)       { return (List<InvoiceLine__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }

//////////////////////////////////////////////////////////////////////////////////////////////////////
// related methods use to retrieve a list of childs(base object) from a list of parent objects
//////////////////////////////////////////////////////////////////////////////////////////////////////

    // RS/Invoice parent (both use same childRelationship name)
    public static List<InvoiceLine__c>   getListFromRelated(Id parentId)        { return (List<InvoiceLine__c>) GW_sObject.getChildren(parentId, 'InvoiceLines__r'); }
    public static List<InvoiceLine__c>   getListFromRelated(Set<Id> parentIds)  { return (List<InvoiceLine__c>) GW_sObject.getChildren(parentIds, 'InvoiceLines__r'); }
    public static Set<Id>             	 getIdSetFromRelated(Set<Id> parentIds) { return GW_sObject.getChildIds(parentIds, 'InvoiceLines__r'); }

	private static Decimal getTotalAmountForRev(Rev__c rev, List<RS__c> rsList) {
		Decimal amount = 0.0;
		for(RS__c rs : rsList) {
			amount += ((Rev.UnitPrice__c==null?0:Rev.UnitPrice__c) + (Rev.IndirectDiscountAmount__c==null?0:Rev.IndirectDiscountAmount__c) ) * (rs.QuantityBilled__c==null?0:rs.QuantityBilled__c) * ((rev.UPCF__c == null || rev.UPCF__c == 0) ? 1 : rev.UPCF__c);
		}
		return amount;
	}

    public static InvoiceLine__c createInvoiceLineFromInvoicingItem(sObject invoicingItem, InvoiceBatch__c invBatch) {
        Rev__c rev;
        RS__c rs;
        Product2 prod;
        Account billingAcc;
        Opportunity opp;

        String ilUniqueKey;
        String invoiceUID; 
        String vatPercentage;
        String lineOfBusiness;
        String curISOcode;

        if ( invoicingItem == null ) UTIL.throwError('No valid InvoicingItem supplied');
        //if ( inv == null ) UTIL.throwError('No valid Invoice supplied');

        String objectType = GW_sObject.getobjectNameFromId( (Id) invoicingItem.get('Id'));
        if (objectType != 'Rev__c' && objectType != 'RS__c') UTIL.throwError('No valid InvoicingItem supplied');
        if (objectType == 'Rev__c') {
            rev = (Rev__c) invoicingItem;
            ilUniqueKey = 'REV_'+invBatch.BatchId__c+'_'+rev.Id;
            invoiceUID = invBatch.BatchId__c +'_'+rev.InvUidCalc__c;

        } else {
            rs = (RS__c) invoicingItem;
            ilUniqueKey = 'RS_'+invBatch.BatchId__c+'_'+rs.UniqueKey__c;
            invoiceUID = invBatch.BatchId__c +'_'+rs.InvUidCalc__c;
            rev = (Rev__c)UTIL.getCached(rs.Rev__c);
        }
        prod = (Product2) UTIL.getCached(rev.Product__c);
        opp = (Opportunity) UTIL.getCached(rev.Opportunity__c);
        billingAcc = (Account) UTIL.getCached(opp.Billing_Account__c);
        
        vatPercentage = billingAcc.VAT__c!=null?String.valueOf(billingAcc.VAT__c.intValue()):'0';
        lineOfBusiness = opp.LineOfBusiness__c;
        curISOcode = opp.CurrencyIsoCode;
        
        InvoiceLine__c il = new InvoiceLine__c();

        if (rs == null) {
            il.Rev__c = rev.Id;
        } else {
            il.Rev__c = null;
            il.RS__c = rs.Id;
        }
        Decimal qBilled = ((Decimal)invoicingItem.get('QuantityBilled__c'))==null?0:(Decimal)invoicingItem.get('QuantityBilled__c');
        Decimal indirectDiscountAmount = ((Decimal)invoicingItem.get('IndirectDiscountAmount__c'))==null?0:(Decimal)invoicingItem.get('IndirectDiscountAmount__c');
        Decimal unitPrice = ((Decimal)invoicingItem.get('UnitPrice__c'))==null?0:(Decimal)invoicingItem.get('UnitPrice__c');
        Decimal upcf = (rev.UPCF__c == null || rev.UPCF__c == 0) ? 1 : rev.UPCF__c;
        Decimal revenueAfterID = ((Decimal)invoicingItem.get('Revenue__c'))==null?0:(Decimal)invoicingItem.get('Revenue__c');
        Decimal indirectDiscountTotal = (indirectDiscountAmount)*qBilled*upcf;
		il.UPCF__c = upcf;
        if(objectType == 'Rev__c') {
			il.Amount__c = unitPrice;
        } else {
            il.Amount__c = (revenueAfterID + indirectDiscountTotal).setscale(2);
        }

		//il.Invoice__r = inv;
		il.BillingAccountId__c = opp.Billing_Account__c;
        il.UniqueKey__c = ilUniqueKey;
        il.invoiceUID__c = invoiceUID;
		il.Quantity__c = qBilled;
        if(prod != null){
    		il.FQ_ProductCode__c = prod.ProductCode;
    		il.FQ_ProductType__c = prod.Product_Type__c;
    		il.FQ_ProductSubType__c = prod.Product_SubType__c;
		}
        il.VatPercentage__c = vatPercentage;
		il.LineOfBusiness__c = lineOfBusiness;
		il.CurrencyIsoCode = curISOcode;
        il.IndirectDiscountAmount__c = indirectDiscountTotal.setscale(2);
		il.InvoiceLineDescription__c = getInvoiceLineDescription(invoicingItem);
        
        il.StartDate__c = getInvoiceLineStartDate(invoicingItem);
        il.EndDate__c = getInvoiceLineEndDate(invoicingItem);
        return il;
    }
    
    private static Date getInvoiceLineStartDate(sObject invoicingItem) {
        if(invoicingItem == null) return null;

        // RS & Rev
        if(invoicingItem.get('From_Date__c') != null && ((Date)invoicingItem.get('From_Date__c')) != null) {
            return (Date)invoicingItem.get('From_Date__c');
        }
        return null;
    }

    private static Date getInvoiceLineEndDate(sObject invoicingItem) {
        if(invoicingItem == null) return null;

        // RS & Rev
        if(invoicingItem.get('Until_Date__c') != null && ((Date)invoicingItem.get('Until_Date__c')) != null) {
            return (Date)invoicingItem.get('Until_Date__c');
        }
        return null;
    }

    private static String getInvoiceLineDescription(sObject invoicingItem) {
        if(invoicingItem == null) return '';
		String objectType = GW_sObject.getObjectNameFromId(invoicingItem.Id);

        // RS
        if('RS__c' == objectType && (String)invoicingItem.get('InvoiceLineDescription__c') != null && (String)invoicingItem.get('InvoiceLineDescription__c') != '') {
            return (String)invoicingItem.get('InvoiceLineDescription__c');
        }
        // Rev
        if('Rev__c' == objectType && (String)invoicingItem.get('Description__c') != null && (String)invoicingItem.get('Description__c') != '') {
            return (String)invoicingItem.get('Description__c');
        }
        return '';
    }

    public static InvoiceLine__c createInvoiceLineForIndDiscount(Decimal discount, String invoiceUID, String invoiceLineUID, InvoiceLine__c defaultLine ) {
        
        if (defaultLine==null) UTIL.throwError('Default invoiceline not defined for ID line');
        Account billingAcc 	= (Account) UTIL.getCached(defaultLine.BillingAccountId__c);
        if (billingAcc==null) UTIL.throwError('Billing Account not defined for ID line');
        
        SObject revenue;
        if( defaultLine.Rev__c == null ){
        	revenue = UTIL.getCached( defaultLine.Rs__c );
        } else {
        	revenue = UTIL.getCached( defaultLine.Rev__c );
        }
        String oppId = ( String ) revenue.get('Opportunity__c');
        Opportunity opp = (Opportunity) UTIL.getCached( oppId );
        if (opp==null) UTIL.throwError('Opportunity not defined for ID line');

        InvoiceLine__c il = new InvoiceLine__c();
        il.Amount__c = discount * -1;
        il.IndirectDiscountAmount__c = 0;
        il.BillingAccountId__c = defaultLine.BillingAccountId__c;
        //il.Invoice__r = inv;
        il.InvoiceLineDescription__c = (billingAcc.MemberId__c != 'ECGDK') ? 'Indirect Discount' : 'Bureauprovision (' + billingAcc.AccountDiscount__c.intValue() + '%)';
        il.Quantity__c = 1;
        il.UniqueKey__c = invoiceLineUID;
        il.InvoiceUID__c = invoiceUID;
        il.FQ_ProductCode__c = defaultLine.FQ_ProductCode__c;
        il.FQ_ProductType__c = defaultLine.FQ_ProductType__c;
        il.FQ_ProductSubType__c = defaultLine.FQ_ProductSubType__c;
        il.VatPercentage__c = defaultLine.VatPercentage__c;
        il.LineOfBusiness__c = 'AdSales';
        il.CurrencyIsoCode = defaultLine.CurrencyIsoCode;
        
        Datetime auxTs = defaultLine.StartDate__c;
        Integer currYear = auxTs.year();
        Integer currMonth = auxTs.month();
        Integer numberOfDays = Date.daysInMonth( currYear , currMonth );
        
        il.StartDate__c = Date.newInstance( currYear , currMonth , 1 );
        il.EndDate__c = Date.newInstance( currYear , currMonth , numberOfDays );
        
        return il;
    }

	private static Map<Invoice__c,List<RS__c>> buildInvToRSMap(List<Invoice__c> invList, Map<Invoice__c,List<sObject>> invToSourceObjMap) {
		if(invList == null || invList.size() == 0 || invToSourceObjMap== null || invToSourceObjMap.size() == 0) {
			return new Map<Invoice__c,List<RS__c>>();
		}
		Map<Invoice__c,List<RS__c>> invToRSMap = new Map<Invoice__c,List<RS__c>>();
		for(Invoice__c inv : invList) {
			if(invToSourceObjMap.containsKey(inv)) {
				invToRSMap.put(inv,(List<RS__c>)invToSourceObjMap.get(inv));
			}
		}
		return invToRSMap;
	}
    
    public static Map<String, List<InvoiceLine__c>> returnMapInvoiceUIDInvoiceLines(List<InvoiceLine__c> ils) {
        Map<String, List<InvoiceLine__c>> mapUID2InvoiceLines = new Map<String, List<InvoiceLine__c>>();
        
        for (InvoiceLine__c il : ils ) {
            if (mapUID2InvoiceLines.containsKey(il.InvoiceUID__c)) {
            	mapUID2InvoiceLines.get(il.InvoiceUID__c).add(il);   
            } else {
                mapUID2InvoiceLines.put(il.InvoiceUID__c,new List<InvoiceLine__c>{il});     
            }    
        }
        return mapUID2InvoiceLines;
    }

	private static Map<Invoice__c,List<Rev__c>> buildInvToRevMap(List<Invoice__c> invList, Map<Invoice__c,List<sObject>> invToSourceObjMap) {
		if(invList == null || invList.size() == 0 || invToSourceObjMap== null || invToSourceObjMap.size() == 0) {
			return new Map<Invoice__c,List<Rev__c>>();
		}
		Map<Invoice__c,List<Rev__c>> invToRevMap = new Map<Invoice__c,List<Rev__c>>();
		for(Invoice__c inv : invList) {
			if(invToSourceObjMap.containsKey(inv)) {
				invToRevMap.put(inv,(List<Rev__c>)invToSourceObjMap.get(inv));
			}
		}
		return invToRevMap;
	}

    public static Boolean setStatus(InvoiceLine__c il) {
        StatusCalculator statusCalc = new StatusCalculator(il);
        return statusCalc.setStatus(il);
    }

    public class StatusCalculator extends StatusCalculator.AbstractStatusCalculator {
        // constructor
        public StatusCalculator(InvoiceLine__c il) { super(il, new Map<Integer, String>{-1 => 'Cancelled', 0 => 'Draft', 6 => 'Ready for Invoicing', 7 => 'Sent to Billing'});}

        public override Boolean passCriteria(sObject so, Integer stage) {
            InvoiceLine__c il = (InvoiceLine__c) so;
            Invoice__c inv = (Invoice__c) UTIL.getCached(il.Invoice__c);
            if (stage==-1) return true; // Will Not Be Invoiced due to cancelation
            if (stage==0) { if ( !inv.Cancelled__c) return true; }// Draft is default 0
            if (stage==6) { if ( !inv.Cancelled__c || il.Previously_Sent_To_Billing__c) return true; } // Ready for Invoicing
            if (stage==7) { if ( il.FQ_SyncStatus__c == 'OK' || il.Previously_Sent_To_Billing__c) return true; } // sent to Billing
            return false;
        }
	}

    // used to cache objects for Invoice creation
    public static void cacheRelatedRecords(List<InvoiceLine__c> ils) {
        if (ils == null) {
            return;
        }
        set<Id> rsIds = new Set<Id>();
        set<Id> invIds = new Set<Id>();

        for (InvoiceLine__c il : ils) {
            if (il.RS__c != null) rsIds.add(il.RS__c);
            if (il.Invoice__c != null) invIds.add(il.Invoice__c);
        }
        Map<Id,RS__c> rsMap = GW_RS.getMap(rsIds);
        Map<Id,Invoice__c> invMap = GW_Invoice.getMap(invIds);

        Map<Id,Rev__c> revMap = GW_Revenue.getMapFromRelated(rsMap.values() );
        Map<Id,Opportunity> oppMap = GW_Opportunity.getMapFromRelated(revMap.values() );
        Set<Id> billingAccs = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        for (Opportunity opp : oppMap.values() ) {
         	if (opp.Billing_Account__c != null) billingAccs.add(opp.Billing_Account__c);
            if (opp.Primary_Contact__c != null) contactIds.add(opp.Primary_Contact__c);
        }
        Map<id,Account> accMap = GW_Account.getMap(billingAccs);
        List<Contact> primContacts = (List<Contact>) GW_sObject.queryRecords('Contact', contactIds);
        Set<Id> productIds = new Set<Id>();
        for (Rev__c rev : revMap.values() ) {
            if (rev.Product__c != null) productIds.add(rev.Product__c);
        }
        List<Product2> prods = (List<Product2>) GW_sObject.queryRecords('Product2', productIds);

        UTIL.cache(rsMap);
        UTIL.cache(invMap);
        UTIL.cache(revMap);
        UTIL.cache(oppMap);
        UTIL.cache(accMap);
        UTIL.cache(primContacts);
        UTIL.cache(prods);
    }

    public static void checkStatusChangeAndUpdate(List<InvoiceLine__c> ils) {
        List<Invoice__c> invs;
        List<InvoiceLine__c> ilsToUpdate = checkStatusChange(ils);

        if (!ilsToUpdate.isempty() ) {
            try {
                update ilsToUpdate;
            } catch(Exception ex) {
                UTIL.throwError('GW_InvoiceLine.checkStatusChangeAndUpdate(): Error updating InvoiceLines: ',ex);
            }
        }
    }
    
    public static List<InvoiceLine__c> checkStatusChange(List<InvoiceLine__c> ils) {
        List<InvoiceLine__c> ilsToUpdate = new List<InvoiceLine__c>();
        
        for (InvoiceLine__c il: ils) {
            if ( GW_InvoiceLine.setStatus(il) ) { ilsToUpdate.add(il); }
        }
        
        return ilsToUpdate;
    }
    
    public static List<InvoiceLine__c> markAsSynced(List<InvoiceLine__c> ils) {
        
        for (InvoiceLine__c il : ils) {
            il.FQ_SyncStatus__c = 'OK';
        }
        
        return ils;
    }
	
    public static void calcRollupsInvoiceLineToRS(set<Id> rsIds) {
    	list<UTIL_RollUpSummary.fieldDefinition> fieldDefinitions = new list<UTIL_RollUpSummary.fieldDefinition>{
        	new UTIL_RollUpSummary.fieldDefinition('SUM', 'AmountNet__c', 'RevenueInvoiced__c'),
            new UTIL_RollUpSummary.fieldDefinition('COUNT', 'Id', 'NumInvoiceLines__c')
        };
        UTIL_RollUpSummary.rollUpTrigger(fieldDefinitions, rsIds, 'InvoiceLine__c', 'RS__c', 'RS__c', 'AND Invoice__r.Cancelled__c = FALSE');
    }
    
    public static void calcRollupsInvoiceLineToRev(set<Id> revIds) {
    	list<UTIL_RollUpSummary.fieldDefinition> fieldDefinitions = new list<UTIL_RollUpSummary.fieldDefinition>{
        	new UTIL_RollUpSummary.fieldDefinition('SUM', 'AmountNet__c', 'RevenueInvoiced__c'),
            new UTIL_RollUpSummary.fieldDefinition('COUNT', 'Id', 'NumInvoiceLines__c')
        };
        UTIL_RollUpSummary.rollUpTrigger(fieldDefinitions, revIds, 'InvoiceLine__c', 'Rev__c', 'Rev__c', 'AND Invoice__r.Cancelled__c = FALSE');
    }
}