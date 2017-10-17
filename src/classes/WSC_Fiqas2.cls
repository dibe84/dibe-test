global class WSC_Fiqas2 {
    private static final String APINAME = 'WSC_Fiqas2';
    
    public class InvoiceGetPDF extends FiqasRequest { 
        Invoice__c inv;
        
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('InvoiceGetPDF',APINAME);
            super.init(contextRecordId);
            inv = (Invoice__c) this.contextRecord;
            this.mapper.mappingElements = getMapper_invoiceGetPDF(contextRecordId);            
            this.setResultClass(APINAME+'.FiqasResult');
            this.setHandlerClass(APINAME+'.InvoiceGetPDF_Handler');
            this.mockMap.putAll( getMocks_InvoiceGetPDF() ); 

          	this.setEndpoint(this.baseEndpoint + 'GetDocument');
       		this.setHttpMethod('POST');

        }
		
        public override String getBody() {
            return super.getBody() +'&'+ UTIL_WSC.urlEncodeObject( this.mapper.getOutputMap() );
        }
        
        public override Boolean readyForCallout() { 
            return (!inv.Invoice_PDF_Retrieved__c && inv.FQ_InvoiceID__c != NULL );
        }
    }
    
    webservice static string FQ_ResendInvoicePDF(String invId){
        UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Fiqas2.ResendInvoicePDF');
        req.init(invId); 
        UTIL_WSC.WSC_Result res = req.call();
		
        if(res.statusCode == 200 && res.getResponseData().get('Status') == 'OK'){
            Return 'The invoice has been sent out succesfully';
        }else{
            Return 'The re-sending has failed: ' +  res.getResponseData().get('Reason');
        }     
    }
    
    public class ResendInvoicePDF extends FiqasRequest { 
        Invoice__c inv;
        
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('ResendInvoicePDF',APINAME);
            super.init(contextRecordId);
            inv = (Invoice__c) this.contextRecord;
            this.mapper.mappingElements = getMapper_ResendInvoicePDF(contextRecordId);
            this.setResultClass(APINAME+'.FiqasResult');
            this.setHandlerClass(APINAME+'.ResendInvoicePDF_Handler');
            this.mockMap.putAll( getMocks_ResendInvoicePDF() ); 

          	this.setEndpoint(this.baseEndpoint + 'Ebay_ResendInvoice');
       		this.setHttpMethod('POST');
        }
		
        public override String getBody() {
            return super.getBody() +'&'+ UTIL_WSC.urlEncodeObject( this.mapper.getOutputMap() );
        }
        
        public override Boolean readyForCallout() { 
            return TRUE;
        }
    }

    // Generic request object for all outgoing API calls
    public virtual class FiqasRequest extends UTIL_WSC.WSC_Request {
        public virtual override void init(Id contextRecordId) {
            super.init(contextRecordId);
            this.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            this.setHeader('Accept-Charset','utf-8');
            this.setHeader('Date', Datetime.now().formatGMT('EEE, d MMM yyyy HH:mm:ss z'));
            this.getWsSettings(APINAME,null);
            this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsUser, this.wsKeystring));
        }
        public virtual override Boolean readyForCallout() { return TRUE; } // override with entry criteria in specific implementation, when these apply

        public virtual override String getBody() 			{

            Map<String,Object> generalParams = new Map<String,Object>();

            generalParams.put('user', WSUSER);
			generalParams.put('challenge', 0);
			generalParams.put('key', WSKEYSTRING);
			generalParams.put('tranid', 0);

            return UTIL_WSC.urlEncodeObject(generalParams);

        }
        public override String getFormattedBody() 	{

            return getBody();
        }
    }

    // Generic Result object for all responses to outgoing API calls
    public class FiqasResult extends UTIL_WSC.WSC_Result {

        public override Map<String,Object> getResponseData() {

            if (resp !=null && !String.isBlank(resp.getBody()) ) {
                Map<String,Object> respMap = new Map<String,Object>();

                Dom.Document doc = new Dom.Document();
        		doc.load(resp.getBody());

        		Dom.XMLNode responseLines = doc.getRootElement();

        		for(Dom.XmlNode parent : responseLines.getChildElements()){

                    respMap.put('Status', parent.getAttribute('Status', ''));
                    respMap.put('Reason', parent.getAttribute('Reason', ''));

                    for(Dom.XmlNode child : parent.getChildElements()){
                    	respMap.put(child.getName(), child.getText());
                    }
        		}
                return respMap;
            }else
            	return null;
		}

        public override String getFormattedBody() {
            Map<String,Object> resp = this.getResponseData();
            if (resp != null) {
                if(resp.containsKey('PDFFile')) {
                    resp.put('PDFFile','See attachment for PDF content');
                }
				return JSON.serializePretty(resp);
            } else return '<Empty>';
        }
    }

    public virtual class FiqasHandler extends UTIL_WSC.WSC_ResultHandler {
        public virtual override void handle() {
            super.handle();
        }
    }

//////////////////////////////////////////////////////////////////////
// Implementation of handler, mapper and mocks - per API method
//////////////////////////////////////////////////////////////////////

    // result handlers
    public class InvoiceGetPDF_Handler extends FiqasHandler {
        public override void handle() {
            super.handle();

            if (this.result.statusCode == HTTP_OK && this.result.getResponseData().get('PDFFile') != null) {
                Invoice__c inv = (Invoice__c) this.request.contextRecord;

                String pdfContent = (String) this.result.getResponseData().get('PDFFile');
                Attachment att = new Attachment();
                att.parentId = inv.id;
                att.name = inv.Id + '_' + inv.FQ_InvoiceID__c + '.pdf';
                att.body = EncodingUtil.base64Decode(pdfContent);

                inv.Invoice_PDF_Retrieved__c = true;

                UTIL_WSC.doUpdate(inv);
                UTIL_WSC.doInsert(att);
            }
            if (this.result.statusCode == HTTP_OK && this.result.getResponseData().get('Reason') != null) {
                this.result.success = FALSE;
                logError((String) this.result.getResponseData().get('Reason'));
            }
        }
    }
    
    public class ResendInvoicePDF_Handler extends FiqasHandler{
               
        public override void handle() { 
            super.handle();
			
            if (this.result.statusCode == HTTP_OK && this.result.getResponseData().get('Status') != 'OK') {
                this.result.success = FALSE;
                logError((String) this.result.getResponseData().get('Reason'));
            } 
        }
    }
    
    // Field mappers
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_InvoiceGetPDF(Id invId) {
        invoice__c inv	= (Invoice__c) UTIL.getCached(invId);
        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add( new UTIL_Fieldmapper.mappedField('InvoiceNo', inv.FQ_InvoiceID__c, 'String', 32, TRUE, TRUE) );
        return elements;
    }
    
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_ResendInvoicePDF(Id invId) {
        invoice__c inv	= (Invoice__c) UTIL.getCached(invId);

        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add( new UTIL_Fieldmapper.mappedField('InvoiceNo', inv.FQ_InvoiceID__c, 'String', 32, TRUE, FALSE) );
		elements.add( new UTIL_Fieldmapper.mappedField('MailTo', inv.Finance_Contact_Email__c, 'String', 64, TRUE, FALSE) );
        elements.add( new UTIL_Fieldmapper.mappedField('MailBcc', '', 'String', 64, FALSE, FALSE) );
        return elements;
    }
    
    // Mocks
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_InvoiceGetPDF() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
		mocks.put('getSuccess',new UTIL_WSC.WSC_Mock('OK',200,'<?xml version="1.0" encoding="utf-8"?><ArrayOfGetDocumentOut xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://www.fiqas.nl/AdaptAPI/"><GetDocumentOut><PDFFile>fwejfwejfqbfrjhfrwejhweedds</PDFFile></GetDocumentOut></ArrayOfGetDocumentOut>'));
		return mocks;
    }
    
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_ResendInvoicePDF() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
		mocks.put('getSuccess',new UTIL_WSC.WSC_Mock('OK',200,'<?xml version="1.0" encoding="utf-8"?><ArrayOfEbay_ResendInvoiceOut xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://www.fiqas.nl/AdaptAPI/"><Ebay_ResendInvoiceOut Status="OK" Reason=" "/></ArrayOfEbay_ResendInvoiceOut>'));
		mocks.put('getFailed',new UTIL_WSC.WSC_Mock('OK',200,'<?xml version="1.0" encoding="utf-8"?><ArrayOfGetDocumentOut xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://www.fiqas.nl/AdaptAPI/"><GetDocumentOut Status="FAILED" Reason="InvoiceNo \'BEC15070000\' does not exists "/></ArrayOfGetDocumentOut>'));
        return mocks;
    }
}