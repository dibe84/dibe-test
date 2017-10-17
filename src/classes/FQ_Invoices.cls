@RestResource(urlMapping='/PushInvoices/*')
global class FQ_Invoices {
    
    ///Push fiqas invoices
    @HttpPost
    global static string doPost() {
        
        List<Invoice__c> invoicesInsertSFDCList = new List<Invoice__c>();
        List<Invoice__c> invoicesUpdateSFDCList = new List<Invoice__c>();    
        List<Invoice__c> invoicesUpsertSFDCList = new List<Invoice__c>();    
        
        RestRequest req = RestContext.request;
        String jsonRequest = req.requestBody.toString();
        jsonRequest = jsonRequest.replace('{"FQ_Invoices":', '');
                
        list<InvoiceUpsert> invList = (List<InvoiceUpsert>)System.JSON.deserialize(jsonRequest, List<InvoiceUpsert>.class);
        if (invList.isEmpty()){return 'No invoices found in message'; }
        
        ///set/check CustNrs / InvNames
        Set<String> setCustnr = new Set<String>();
        Set<String> setInvName = new Set<String>();
        Set<String> setInvId = new Set<String>();

        for(InvoiceUpsert inv : invList)
        {
            if (inv.custnr != null && inv.custnr != ''){ setCustnr.add(inv.custnr); }
            if (inv.name != null && inv.name != ''){ setInvName.add(inv.name); }
            if (inv.oppid != null && inv.oppid != ''){ setInvId.add(inv.oppid); }
        }
        
        if (setCustnr.isEmpty()){ return'No customer nrs found in message'; }
        if (setInvName.isEmpty()){ return'No invoice names found in message'; }
        
        ///get accList/invlist
        List<Account> accList = [select Id, Name, AccountExtId__c, FQ_CustNr__c from Account where AccountExtId__c in: setCustnr or FQ_CustNr__c in: setCustnr];
        if (accList.isEmpty()){ return'No matching accounts found'; }
        List<Invoice__c> invoicesList = [select Id, BillingAccount__c, Name, FQ_InvoiceID__c from Invoice__c where FQ_InvoiceID__c in: setInvName OR Id in: setInvId];
        
        ///set sets existing ids & Fiqas IDs
        set<string> fqInvoiceNames = new set<string>();
        set<string> invoiceIds = new set<string>(); 
        map<string,string> fqIdMap = new map<string,string>();
        
        for(Invoice__c inv : invoicesList){ 
            if(inv.FQ_InvoiceID__c != NULL){
                fqInvoiceNames.add(inv.FQ_InvoiceID__c);
                fqIdMap.put(inv.FQ_InvoiceID__c, inv.id);
            }
            invoiceIds.add(inv.id);    
        }
        
        //Loop the Invoices add add some fields in the object.
        for(InvoiceUpsert inv : invList){                        
            if(!String.isBlank(inv.oppid) && invoiceIds.contains(inv.oppid)){
                UTIL.log('Flow UpdateInvoiceById');
                invoice__c invoice = createInvoicesSFDCObj(inv);
                invoice.id = inv.oppid;
                invoicesUpsertSFDCList.add(invoice);
                
            }else if(!String.isBlank(inv.oppid) && !invoiceIds.contains(inv.oppid)){
                UTIL.log('LogInvaledInvoice Values');
                UTIL.customLog('WARN', 'FIQAS Post: Invoice Exist in Fiqas but doesn\'t in Salesforce', 'FQ_Invoices', inv.oppid );
                        
            }else if(fqInvoiceNames.contains(inv.name)){
                UTIL.log('Flow updateInvoiceByFQId');
                invoice__c invoice = createInvoicesSFDCObj(inv);
                invoice.id = fqIdMap.get(inv.name);
                invoicesUpsertSFDCList.add(invoice);
                
            }else if(!fqInvoiceNames.contains(inv.name)){
                UTIL.log('Flow insertInvoice');
                invoice__c invoice = createInvoicesSFDCObj(inv);
                
                invoice.UniqueKey__c = inv.name;
                invoice.StartDate__c = inv.periodFrom;
                invoice.EndDate__c = inv.periodUntil;

                for(Account acc : accList){
                    if(inv.custnr == acc.AccountExtId__c || inv.custnr == acc.FQ_CustNr__c){
                        invoice.BillingAccount__c = acc.Id;
                        break;
                    }
                }
                
                invoicesUpsertSFDCList.add(invoice);                
            }
        }
        
        upsert invoicesUpsertSFDCList;
        UTIL.insertCustomLogs();
        
        return 'true';
    }
    
    private static Invoice__c createInvoicesSFDCObj(InvoiceUpsert inv){
        
        Invoice__c i = new Invoice__c();
        
        i.FQ_InvoiceID__c = inv.name;
        i.FQ_InvoiceStatus__c = inv.paymentStatus;
        i.FQ_InvoiceDescription__c = inv.description;
        i.FQ_InvoiceAmount__c = inv.invoiceAmount;
        i.FQ_InvoicePaidAmount__c = inv.amountPaid;
        i.FQ_InvoiceDate__c = inv.invoiceDate;
        i.FQ_PaymentDate__c = inv.paymentDate;
        i.FQ_DunningNextStep__c = inv.nextstep;
        i.FQ_DunningBlockType__c = inv.blocktype;
        i.FQ_DunningStartDate__c = inv.blockstartdate;
        i.FQ_DunningEndDate__c = inv.blockenddate;
        i.FQ_DunningBlockReason__c = inv.blockreason;  
 
        return i;
    }
    
    
    public class InvoiceUpsert {
         public String custnr;
         public String name;
         public Date invoiceDate;
         public Decimal invoiceAmount;
         public String oppid;
         public Date paymentDate;
         public String paymentStatus;
         public String description;
         public Date periodFrom;
         public Date periodUntil;
         public Double amountPaid;
         public String nextstep;
         public String blocktype;
         public Date blockstartdate;
         public Date blockenddate;
         public String blockreason;
         public Decimal invoiceAmountWrittenoff;
         public Decimal invoiceExtraAmount;
         public String invoiceCurrency;
         public String invoiceStatus;
         public String accountId;
         public String id;
    } 
    
    ///Get fiqas invoices
    webservice static string retrieveInvoices(string recordID, string externalAccId){
        
        if(string.isBlank(externalAccId)){Return 'NOEXTERNALID';}
        
        WSC_Fiqas.FiqasResponse fr;  
        fr = WSC_Fiqas.invoicesGet(externalAccId);
        
        for(WSC_Fiqas.FiqasResponseElement fre : fr.elements){
            if(fre.status == 'FAILED'){
                Return 'Failed to retrieve invoices: ' + fre.reason;
            }
        }
             
        list<Invoice__c> relatedInvoices = [SELECT id, FQ_InvoiceID__c FROM Invoice__c WHERE BillingAccount__c =: recordID];
        set<string> fqInvoiceIds = new set<string>();
        set<string> invoiceIds = new set<string>(); 
        map<string,string> fqIdMap = new map<string,string>();
        
        for(Invoice__c inv : relatedInvoices){ 
            if(inv.FQ_InvoiceID__c != NULL){
                fqInvoiceIds.add(inv.FQ_InvoiceID__c);
                fqIdMap.put(inv.FQ_InvoiceID__c, inv.id);
            }
            invoiceIds.add(inv.id);    
        }
        
        list<invoice__c> upsertInvoices = new list<invoice__c>();
        
        for(WSC_Fiqas.FiqasResponseElement fre : fr.elements){
            if(fre.data.get('IndividualInvoiceId') != '' && invoiceIds.contains(fre.data.get('IndividualInvoiceId'))){
                UTIL.log('Flow UpdateInvoiceById');
                invoice__c inv = updateInvoiceById(fre, fr.timestamp);
                upsertInvoices.add(inv);
                
            }else if(!String.isBlank(fre.data.get('IndividualInvoiceId')) && !invoiceIds.contains(fre.data.get('IndividualInvoiceId'))){
                UTIL.log('LogInvaledInvoice Values');
                logInvaledInvoice(fre.data.get('IndividualInvoiceId'));
                
            }else if( fqInvoiceIds.contains(fre.data.get('InvoiceNumber'))){
                UTIL.log('Flow updateInvoiceByFQId');
                invoice__c inv = updateInvoiceByFqId(fre, fr.timestamp, fqIdMap.get(fre.data.get('InvoiceNumber')));
                upsertInvoices.add(inv);
                
            }else if( !fqInvoiceIds.contains(fre.data.get('InvoiceNumber'))){
                UTIL.log('Flow insertInvoice');
                invoice__c inv = insertInvoice(fre, fr.timestamp, recordID);
                upsertInvoices.add(inv);    
            }
        }
        
        upsert upsertInvoices;
        if(!UTIL.customLogsList.isEmpty()){UTIL.insertCustomLogs();}
        return 'SUCCES';
    }
    
    public static Invoice__c updateInvoiceById(WSC_Fiqas.FiqasResponseElement fre, datetime timestamp){
        invoice__c inv = setInvoiceFields(fre, timestamp);
        inv.Id = id.valueof(fre.data.get('IndividualInvoiceId'));
        return inv;        
    }
        
    public static Invoice__c updateInvoiceByFqId(WSC_Fiqas.FiqasResponseElement fre, datetime timestamp, string invId){
        invoice__c inv = setInvoiceFields(fre, timestamp);
        inv.Id = id.valueof(invId);
        return inv;
    }
    
    public static void logInvaledInvoice(string deletedInvID){
        UTIL.customLog('WARN', 'FIQAS Get: Invoice Exist in Fiqas but doesn\'t in Salesforce', 'WSC_FIQAS', deletedInvID );
    }
    
    public static Invoice__c insertInvoice(WSC_Fiqas.FiqasResponseElement fre, datetime timestamp, id recordID){       
        invoice__c inv = setInvoiceFields(fre, timestamp);
        inv.BillingAccount__c = recordID;
        inv.UniqueKey__c = fre.data.get('InvoiceNumber');
        return inv;
    }
    
    public static Invoice__c setInvoiceFields(WSC_Fiqas.FiqasResponseElement fre, datetime timestamp){
       
        invoice__c inv = new invoice__c(
            FQ_InvoiceID__c = fre.data.get('InvoiceNumber'),
            FQ_InvoiceAmount__c = decimal.valueOf(fre.data.get('InvoiceAmount')),
            FQ_InvoiceDate__c = createDateFromString(fre.data.get('InvoiceDate')),
            FQ_InvoiceDescription__c = fre.data.get('InvoiceDescription'),
            FQ_InvoiceStatus__c = fre.data.get('InvoicePaymentStatus'),
            FQ_InvoicePaidAmount__c = decimal.valueOf(fre.data.get('InvoiceAmountPaid')),
            FQ_PaymentDate__c = createDateFromString(fre.data.get('LatestPaymentDate')),
            FQ_DunningBlockreason__c = fre.data.get('DunningBlockReason'),
            FQ_DunningBlocktype__c = fre.data.get('DunningBlockType'),
            FQ_DunningStartdate__c = createDateFromString(fre.data.get('DunningBlockStartDate')),
            FQ_DunningEnddate__c = createDateFromString(fre.data.get('DunningBlockEndDate')),
            StartDate__c = createDateFromString(fre.data.get('InvoicePeriodFrom')),
        	EndDate__c = createDateFromString(fre.data.get('InvoicePeriodTo')),
            FQ_DunningNextStep__c = fre.data.get('DunningNextStep'),
            FQ_SyncReason__c = fre.reason,
            FQ_SyncStatus__c = fre.status,
            FQ_SyncTimestamp__c = timestamp    
        );

        return inv;
    }
    
    public static date createDateFromString(string ds){
        Date convertedDate;
        if(ds.length() == 8){
            convertedDate = date.newInstance(integer.valueof(ds.substring(0,4)), integer.valueof(ds.substring(4,6)), integer.valueof(ds.substring(6,8)));
        }
        return convertedDate;
    }   
}