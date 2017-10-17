public with sharing class WSC_DNB_TOOLKIT {

	public static DNB_Settings__c DNBset = DNB_Settings__c.getInstance('DNBaccess');

    //*****************Lookup Company DUNS*********************//
    
	public static Account[] lookupDNBCompanies( String Name , String CountryCode , String PostCode ){
     
        // Create the request xml body 
        DOM.Document doc = new DOM.Document();
        Dom.XmlNode envelope = createEnvelope( doc );    
        enrichDNBLookupEnvelope( envelope , Name , CountryCode , PostCode );
        
        // Create a HTTP Request
        HttpRequest req = createHTTPRequest( DNBset.DUNSservice__c , doc);
        HttpResponse res = new HttpResponse();
     
        // Create a HTTP Transport
        Http http = new Http();
     
        list <Account> results = new list <Account>();     
    
        try {
        	
        	if( Test.IsRunningTest() ){
        		res = getDNBLookupMockResponse();
        	} else {
                res = http.send(req);
        	}
            results = parseLookupResponse( res );   
        
        } catch(exception e) {
      	    System.debug('error: ' + e + '--->' + e.getStackTraceString());
        }
        
        return results;
	}    


    private static void enrichDNBLookupEnvelope( dom.XmlNode envelope , String name , String countryCode , String postCode ){
    	
    	System.debug(name);
    	System.debug(countryCode);
    	System.debug(postCode);
    	
    	dom.XmlNode body = envelope.addChildElement('Body', DNBset.soapNS__c, null)
    	                           .addChildElement('ws_LookUp', DNBset.serviceNS1__c, 'look')
    	                           .addChildElement('lookUpRequest', null, null);
        dom.XmlNode accountinfo = body.addChildElement('lookUpInput', null, null);  
            
        body.addChildElement('UserId', null, null).addTextNode( DNBset.Username__c );
        body.addChildElement('Password', null, null).addTextNode( DNBset.Password__c );
        
        name = name == null ? '' : name; 
        countryCode = countryCode == null ? '' : countryCode;
        postCode = postCode == null ? '' : postCode;
        
        accountinfo.addChildElement('Name', null, null).addTextNode( name );
        accountinfo.addChildElement('Country_Code', null, null).addTextNode( countryCode );
        accountinfo.addChildElement('Post_Code', null, null).addTextNode( postCode );
    }


    public static HTTPResponse getDNBLookupMockResponse(){
    	
    	HTTPResponse res = new HTTPResponse();
    	
    	// DGX Response
    	Dom.Document resDoc = new Dom.Document();  
        Dom.XMLNode dgxResponse = resDoc.createRootElement('Envelope', 'http://schemas.xmlsoap.org/soap/envelope/' , 'SOAP-ENV')
                                        .addChildElement( 'Body' , DNBset.SoapNS__c , null )
                                        .addChildElement( 'ws_LookUpResponse' , DNBset.ServiceNS1__c , null ) 
                                        .addChildElement( 'lookupResponse', 'Test', null)
                                        .addChildElement( 'DGX', null , null );
        
        // SignOn Status
    	Dom.XMLNode signonStatus = dgxResponse.addChildElement( 'SIGNONMSGSRSV1', null , null )
                                              .addChildElement( 'SONRS', null , null )
                                              .addChildElement( 'STATUS', null , null );
                                              
        signonStatus.addChildElement( 'CODE', '123' , null).addTextNode( '0' );
        signonStatus.addChildElement( 'MESSAGE', null , null );                                      
                        
        // Credit Status                                              
        Dom.XmlNode creditStatus = dgxResponse.addChildElement( 'CREDITMSGSRSV2', null , null )
                                              .addChildElement( 'LOOKUPTRNRS', null , null )
                                              .addChildElement( 'STATUS', null , null );     
                                                                                
    	creditStatus.addChildElement( 'CODE', '123' , null).addTextNode( '0' );
        creditStatus.addChildElement( 'MESSAGE', null , null ); 
    	
    	// Lookup Result Set Company
        Dom.XmlNode company = dgxResponse.getChildElement( 'CREDITMSGSRSV2', null)
                                           .getChildElement( 'LOOKUPTRNRS', null)
        		                           .addChildElement( 'LOOKUPRS', null , null )
        		                           .addChildElement( 'LOOKUPRSCOMPANY', null , null )
        		                           .addChildElement( 'ArrayOfLOOKUPRSCOMPANYItem', null , null );  
        		                             	
    	company.addChildElement('NME', null , null ).addTextNode('Marktplaats B.V.');
    	company.addChildElement('ADR_LINE', null , null ).addTextNode( 'Wibautstraat 224' );
    	company.addChildElement('NON_POST_TOWN', null , null ).addTextNode( 'Amsterdam' );
    	company.addChildElement('POST_CODE', null , null ).addTextNode( '1097 DN' );
    	company.addChildElement('DUNS_NBR', null , null ).addTextNode('416499457');
        
    	res.setBody( resDoc.toXmlString() );
    	return res;
    }

    
    public static Account[] parseLookupResponse( HttpResponse res ){
    
        List<Account> Accountslist= new List<Account>();
        
        Dom.Document resDoc = res.getBodyDocument();  
        Dom.XMLNode envelope = resDoc.getRootElement();
        System.debug('##### Inbound Message: ' + resDoc.toXmlString());
        Dom.XmlNode dgxResponse = envelope.getChildElement('Body', DNBset.SoapNS__c)
                                          .getChildElement('ws_LookUpResponse', DNBset.ServiceNS1__c )
                                          .getChildElement('lookupResponse', 'Test')
                                          .getChildElement('DGX', null);
        
        Dom.XmlNode signonStatus = dgxResponse.getChildElement('SIGNONMSGSRSV1', null)
                                              .getChildElement('SONRS', null)
                                              .getChildElement('STATUS', null); 
        
        String signonStatusCode = signonStatus.getChildElement('CODE', '123').getText(); 
        String errorMessage;

        if( signonStatusCode != '0' ){

            errorMessage = signonStatus.getChildElement('MESSAGE', null).getText();
       	    System.debug('Error message in the Signon Response: ' + errorMessage );

        } else {
        	
            Dom.XmlNode creditStatus = dgxResponse.getChildElement('CREDITMSGSRSV2', null)
                                                  .getChildElement('LOOKUPTRNRS', null)
                                                  .getChildElement('STATUS', null); 
        	
        	String creditStatusCode = creditStatus.getChildElement('CODE', '123').getText();

        	if( creditStatusCode != '0' ){

        		errorMessage = creditStatus.getChildElement('MESSAGE', null).getText();
        		System.debug('Error message in the Credit Response: ' + errorMessage );

        	} else {
        		
        		List<dom.XmlNode> resultCompanies = dgxResponse.getChildElement('CREDITMSGSRSV2', null)
        		                                               .getChildElement('LOOKUPTRNRS', null)
        		                                               .getChildElement('LOOKUPRS', null)
        		                                               .getChildElement('LOOKUPRSCOMPANY', null)
        		                                               .getChildren();
                for ( dom.XmlNode node : resultCompanies ){
                    
                    if( node.getName()=='ArrayOfLOOKUPRSCOMPANYItem' ) { 
                        
                        Account a = new Account( Name = node.getChildElement('NME', null).getText()
                                                ,BillingStreet = node.getChildElement('ADR_LINE', null).getText()
                                                ,BillingCity = node.getChildElement('NON_POST_TOWN', null).getText()
                                                ,BillingPostalCode = node.getChildElement('POST_CODE', null).getText() 
                                                ,DUNS_Number__c = node.getChildElement('DUNS_NBR', null).getText() );
                        Accountslist.add(a);
                    }
                
                }
                        
            }
        } 
        
        return Accountslist;
    }


    //*****************Retrieve Credit Rating*********************//
    
    public static void loadCreditRatingInfo( Account targetAccount ){
     
        // Create the request xml body 
        DOM.Document doc = new DOM.Document();
        Dom.XmlNode envelope = createEnvelope( doc );    
        enrichGDMEnvelope( envelope , targetAccount.DUNS_Number__c , targetAccount.BillingCountryCode );
        
        // Create a HTTP Request
        HttpRequest req = createHTTPRequest( DNBset.CreditService__c , doc);
        HttpResponse res = new HttpResponse();
     
        // Create a HTTP Transport
        Http http = new Http();
     
        try {
        	
        	if( Test.IsRunningTest() ){
        		res = getGDMMockResponse();
        	} else {
                res = http.send(req);
        	}
        	Dom.Document resDoc = res.getBodyDocument();  
        	System.debug( resDoc.toXmlString() );
            parseGDMResponse( res , targetAccount );   
        
        } catch(exception e) {
      	    System.debug('error: ' + e);
        }
    }

    
    private static void enrichGDMEnvelope( dom.XmlNode envelope , String DUNSnumber , String CountryCode ){
    	
        dom.XmlNode body =      envelope.addChildElement('Body', DNBset.soapNS__c, null).addChildElement('ws_GDM', DNBset.serviceNS2__c, 'wsp').addChildElement('gdmRequest', null, null);
        dom.XmlNode orders =    body.addChildElement('Orders', null, null);
        dom.XmlNode imm =       body.addChildElement('Immediate_Delivery', null, null);
        dom.XmlNode add =       body.addChildElement('AdditionalFields', null, null).addChildElement('ArrayOfAdditionalFieldsItem', null, null);    
            
        body.addChildElement('UserId', null, null).addTextNode( DNBset.Username__c );
        body.addChildElement('Password', null, null).addTextNode( DNBset.Password__c );
        orders.addChildElement('Product', null, null).addTextNode( 'GDM Plus' );
        orders.addChildElement('Product_Type', null, null).addTextNode( 'D' );
        
        if(CountryCode=='DE'){
        	 orders.addChildElement('Reason_Code', null, null).addTextNode('1');
        
        }
        
        orders.addChildElement('DnB_DUNS_Number', null, null).addTextNode( DUNSnumber );
        
        imm.addChildElement('Mode', null, null).addTextNode('DIRECT');
        imm.addChildElement('Format', null, null).addTextNode('XML');
        add.addChildElement('FieldName', null, null).addTextNode('CR_RULE');
        
        if(CountryCode =='CA'){
            add.addChildElement('FieldValue', null, null).addTextNode('MP_SF_CAN');
        }else if(CountryCode =='US'){
            add.addChildElement('FieldValue', null, null).addTextNode('MP_SF_US');
        }else { 
            add.addChildElement('FieldValue', null, null).addTextNode('MP_SF');
        }
    }


    public static HTTPResponse getGDMMockResponse(){
    	
    	HTTPResponse res = new HTTPResponse();
    	
    	// DGX Response
    	Dom.Document resDoc = new Dom.Document();  
        Dom.XMLNode descisionInfo = resDoc.createRootElement( 'Envelope', 'http://schemas.xmlsoap.org/soap/envelope/' , 'SOAP-ENV' )
                                          .addChildElement( 'Body' , DNBset.SoapNS__c , null )
                                          .addChildElement( 'ws_GDMResponse' , DNBset.ServiceNS2__c , null ) 
                                          .addChildElement( 'gdmResponse', null , null )
                                          .addChildElement( 'DGX', null , null )
                                          .addChildElement( 'CREDITMSGSRSV2', null , null )
                                          .addChildElement( 'DATATRNRS', null , null )
        		                          .addChildElement( 'DATARS', null , null )
        		                          .addChildElement( 'RPT', null , null )
        		                          .addChildElement( 'DCSN_INFO', null , null );
        		                             	
        descisionInfo.addChildElement( 'CR_DCSN', null , null ).addTextNode('1');
        descisionInfo.addChildElement( 'RSK_BAND', null , null ).addTextNode('123456');
        descisionInfo.addChildElement( 'DM_RSK_RATG', null , null ).addTextNode('1');
        descisionInfo.addChildElement( 'CR_LMT', null , null ).addTextNode('600000');
        descisionInfo.addChildElement( 'DM_SIC', null , null ).addTextNode('7374');
        
    	res.setBody( resDoc.toXmlString() );
    	return res;
    }


    public static void parseGDMResponse( HttpResponse res , Account targetAccount ){

        Dom.Document resDoc = res.getBodyDocument();           
        TG_XmlDom dom = new TG_XmlDom(resDoc.toXmlString());
        TG_XmlNode root = dom.root;  
        TG_XmlNode DCSN_INFO = root.getElementByTagName('DCSN_INFO');
        TG_XmlNode CR_DCSN = DCSN_INFO.getElementByTagName('CR_DCSN');
        TG_XmlNode RSK_BAND = DCSN_INFO.getElementByTagName('RSK_BAND');
        TG_XmlNode CR_LMT = DCSN_INFO.getElementByTagName('CR_LMT');
        TG_XmlNode DM_SIC = DCSN_INFO.getElementByTagName('DM_SIC');

        //Get the Rating
        Decimal creditRate = decimal.valueOf( CR_DCSN.nodeValue );
        if( creditRate != null ){
        	creditRate = 8 - creditRate;
        }
        targetAccount.DNB_Credit_Rate__c = creditRate;
        targetAccount.DNB_RiskRate__c = decimal.valueOf( RSK_BAND.nodeValue );
        targetAccount.DNB_Max_credit_limit__c = decimal.valueOf( CR_LMT.nodeValue );
        targetAccount.Sic = DM_SIC.nodeValue;
    }
    
    
    private static Dom.XmlNode createEnvelope( DOM.Document doc ){
    	
        dom.XmlNode envelope = doc.createRootElement('Envelope', DNBset.soapNS__c, 'soapenv');
        envelope.setNamespace('xsi', DNBset.xsi__c);
        envelope.setAttributeNS('schemaLocation', DNBset.soapNS__c, DNBset.xsi__c, null);
        return envelope;
    }
    
    
    private static HttpRequest createHTTPRequest( String endpoint , DOM.Document bodyContent ){
    	
    	HttpRequest req = new HttpRequest();
	    req.setMethod('POST');
        req.setEndpoint( endpoint );
        req.setHeader('Content-Type', 'text/xml');
        req.setBodyDocument( bodyContent );
        return req;
    }
}