public class WSC_API_SFECG_v1 {
    private static final String APINAME = 'WSC_API_SFECG_v1';
    private static final String API_UTIL_NAME = 'UTIL_WSC_API_SFECG';

    public class AccountPush extends UTIL_WSC_API_SFECG.ApiRequest {
        Account acc;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('AccountPush',APINAME);
            super.init(contextRecordId);
            this.getWsSettings(APINAME,(String)this.contextRecord.get('MemberId__c'));
            this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsUser, this.wsKeystring));
            acc = (Account) this.contextRecord;
            this.mapper.mappingElements = getMapper_accountPush(contextRecordId);

            this.setResultClass(API_UTIL_NAME+'.ApiResult');
            this.setHandlerClass(APINAME+'.accountPush_Handler');
            this.mockMap.putAll( getMocks_accountPush() );

            String endpoint;
            if (acc.LocalPlatformId__c == null) { 				// Insert
                endpoint = this.baseEndpoint + 'accounts/';
                this.setHttpMethod('POST');
            } else { 											// Update
                endpoint = this.baseEndpoint + 'accounts/' + acc.LocalPlatformId__c;
                this.setHttpMethod('PUT');
            }

            if( !String.isBlank( this.endpointURLParameters ) ){
                endpoint += '?' + this.endpointURLParameters;	
            }

            this.setEndpoint( endpoint );    
        }
        
        public override Boolean readyForCallout() {
            return !acc.DoNotSyncToLocalPlatform__c;
        }
    }

    public class InvoicePush extends UTIL_WSC_API_SFECG.ApiRequest {
        Invoice__c inv;
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('InvoicePush', APINAME);
            super.init(contextRecordId);
            this.getWsSettings(APINAME,(String)this.contextRecord.get('MemberId__c'));
            this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsUser, this.wsKeystring));
            inv = (Invoice__c) this.contextRecord;
            Account acc = (Account) UTIL.getCached(inv.BillingAccount__c);

            this.mapper.mappingElements = getMapper_InvoicePush(contextRecordId);
            this.setResultClass(API_UTIL_NAME+'.ApiResult');
            this.setHandlerClass(APINAME+'.invoicePush_Handler');
            this.mockMap.putAll(getMocks_invoicePush());
            
            String endpoint;
            if (inv.LocalPlatformId__c == null){
                endpoint = this.baseEndpoint + 'accounts/' + acc.LocalPlatformId__c + '/invoices/';
                this.setHttpMethod('POST');
            }
            else {
                endpoint = this.baseEndpoint + 'accounts/' + acc.LocalPlatformId__c + '/invoices/' + inv.LocalPlatformId__c;
                this.setHttpMethod('PUT');
            }

            if( !String.isBlank( this.endpointURLParameters ) ){
                endpoint += '?' + this.endpointURLParameters;	
            }

            this.setEndpoint( endpoint );    
        }
    }

    public class BookingPush extends UTIL_WSC_API_SFECG.ApiRequest {
        Rev__c rev;
        Opportunity opp;
        Account acc;

        public override void init(Id contextRecordId) {
            this.setCalloutDetails('BookingPush',APINAME);
            super.init(contextRecordId);
            this.getWsSettings(APINAME,(String)this.contextRecord.get('MemberId__c'));
            this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsUser, this.wsKeystring));
            rev = (Rev__c) this.contextRecord;
            opp = (Opportunity) UTIL.getCached(rev.Opportunity__c);
            acc = (Account) UTIL.getCached(opp.AccountId);

            this.mapper.mappingElements = getMapper_BookingPush(contextRecordId);
            this.setResultClass(API_UTIL_NAME+'.ApiResult');
            this.setHandlerClass(APINAME+'.BookingPush_Handler');
            this.mockMap.putAll( getMocks_BookingPush() );

            String endpoint;
            if (rev.LocalBookingId__c == null) { 				// Insert
                endpoint = this.baseEndpoint + 'accounts/'+acc.LocalPlatformId__c+'/bookings';
                this.setHttpMethod('POST');
            } else { 											// Update
                endpoint = this.baseEndpoint + 'accounts/'+acc.LocalPlatformId__c+'/bookings/'+rev.LocalBookingId__c;
                this.setHttpMethod('PUT');
            }
            
            if( !String.isBlank( this.endpointURLParameters ) ){
                endpoint += '?' + this.endpointURLParameters;	
            }
            
            this.setEndpoint( endpoint );    
        }
        public override Boolean readyForCallout() {
            return (rev != null &&
                    rev.NumStatus__c > 1 && 			// rev should be signed
                    acc.LocalPlatformId__c != null && 	// account should be synced with local platform
                    !rev.OutOfSync__c && 				// rev should be in Sync state
                   	rev.Type__c == 'Master' 			// only Master Revenue Items should be sent. TODO: work out final solution
                   );
        }
    }

    //NOT USED YET!//
    public class AccountGet extends UTIL_WSC_API_SFECG.ApiRequest {
        public override void init(Id contextRecordId) {
            this.setCalloutDetails('AccountGet',APINAME);
            this.setResultClass(API_UTIL_NAME+'.ApiResult');
            this.setHandlerClass(APINAME+'.accountGet_Handler');
            Account acc = (Account) this.contextRecord;
            this.getWsSettings(APINAME,acc.MemberId__c);
            this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsUser, this.wsKeystring));
            this.mockMap.putAll( getMocks_accountGet() );
            this.setEndpoint(this.baseEndpoint + 'accounts/' + acc.LocalPlatformId__c);
            this.setHttpMethod('GET');
        }
    }

    public class InvoicePDFGet extends UTIL_WSC_API_SFECG.ApiRequest {
        Invoice__c inv;

        public override void init(Id contextRecordId) {
            this.setCalloutDetails('InvoicePDFGet',APINAME);
            super.init(contextRecordId);
            this.setResultClass(APINAME+'.PDFResult');
            this.setHandlerClass(APINAME+'.InvoicePDFGet_Handler');
            inv = (Invoice__c) this.contextRecord;
            this.getWsSettings(APINAME,inv.MemberId__c);
            this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsUser, this.wsKeystring));
            this.mockMap.putAll(getMocks_InvoicePDFGet());
            this.setEndpoint(this.baseEndpoint + inv.InvoiceDocumentURL__c);
            this.setHttpMethod('GET');
        }

        public virtual override Boolean readyForCallout() {
            return (!inv.Invoice_PDF_Retrieved__c && inv.InvoiceDocumentURL__c != NULL );
        }



    }

    public class PDFResult extends UTIL_WSC.WSC_Result {
        public override String getFormattedBody() {
            if(resp.getStatusCode() == UTIL_WSC.HTTP_OK) {
                return 'Status: ' + resp.getStatus() + '. See response attachment for details.';
            } else {
                return resp.getBody();
            }
        }

        public override Blob getBlobBody() {
            return resp.getBodyAsBlob();
        }
    }


//////////////////////////////////////////////////////////////////////
// Implementation of handler, mapper and mocks - per API method
//////////////////////////////////////////////////////////////////////

    // result handlers
    public class AccountPush_Handler extends UTIL_WSC_API_SFECG.ApiHandler {
        public override void handle() {
            super.handle();

            Account acc = (Account) this.request.contextRecord;
            if (this.result.statusCode == UTIL_WSC.HTTP_CREATED || this.result.statusCode == UTIL_WSC.HTTP_NOCONTENT) {

                if(this.result.statusCode == UTIL_WSC.HTTP_CREATED){
                    String localId = (String) this.result.getResponseData().get('localId');
                    //if (localId==null) logError('No localId returned');
                    //
                    //acc = [Select Id, MemberId__c From Account Where Id =:acc.Id For Update];
                    acc.UniquePlatformId__c = acc.MemberId__c +'_'+localId;
                }

                // check child Revenue Items for processing
                List<Rev__c> allRevs = (List<Rev__c>) GW_sObject.queryRecords('Rev__c', 'Opportunity__r.AccountId = \'' + acc.Id + '\' AND LocalBookingId__c = NULL');
                List<Rev__c> revsNeedBookingPush = new List<Rev__c>();
                List<Rev__c> revsNeedBookingPush_v2 = new List<Rev__c>();

                for (Rev__c rev : allRevs) {
                    if (UTIL_WSC_Subscription.isSubscribedToWS(rev.MemberUnitId__c,'WSC_API_SFECG_v1', 'BookingPush')) {
                        revsNeedBookingPush.add(rev);
                    }
                    else if (UTIL_WSC_Subscription.isSubscribedToWS(rev.MemberUnitId__c,'WSC_API_SFECG_v2', 'BookingPush')) {
                        revsNeedBookingPush_v2.add(rev);
                    }
                }
                if (!revsNeedBookingPush.isEmpty()) {
                    UTIL_WSC.checkForProcessing('WSC_API_SFECG_v1.BookingPush', (new Map<Id,sObject>(revsNeedBookingPush)).keySet(), UTIL_WSC.bulkHandler.wsscToUpsert);
                }
                if (!revsNeedBookingPush_v2.isEmpty()) {
                    UTIL_WSC.checkForProcessing('WSC_API_SFECG_v2.BookingPush', (new Map<Id,sObject>(revsNeedBookingPush_v2)).keySet(), UTIL_WSC.bulkHandler.wsscToUpsert);
                }
            }
            if (this.result.statusCode == UTIL_WSC.HTTP_CONFLICT) {
                if (this.result.getResponseData() != null) {
                    Map<String, Object> fieldErrors = (Map<String, Object>) this.result.getResponseData().get('fieldErrors');
                    String localId = (String) fieldErrors.get('localId');
                    System.debug('AccountPush : ' + UTIL_WSC.HTTP_CONFLICT + ' localId ' + localId);
                    if (!String.isBlank(localId)) {
                        acc.UniquePlatformId__c = acc.MemberId__c +'_'+localId;
                        this.result.retryCallout = FALSE;
                    }
                }
            }
            if (acc.UniquePlatformId__c != null && (this.result.statusCode == UTIL_WSC.HTTP_CREATED || this.result.statusCode == UTIL_WSC.HTTP_CONFLICT) ) {
                UTIL_WSC.doUpdate(acc);
                UTIL.unCache(new Set<Id>{acc.Id});
            }
        }
    }

    public class InvoicePush_Handler extends UTIL_WSC_API_SFECG.ApiHandler {
        public override void handle() {
            super.handle();
            if(this.result.statusCode == UTIL_WSC.HTTP_CREATED || this.result.statusCode == UTIL_WSC.HTTP_NOCONTENT) {
                Invoice__c inv = (Invoice__c) this.request.contextRecord;

                if(this.result.statusCode == UTIL_WSC.HTTP_CREATED) {
                    String localId = (String) this.result.getResponseData().get('localInvoiceId');
                    inv.UniquePlatformId__c = inv.MemberId__c +'_'+localId;
					inv.ScheduledCalloutPending__c = false;
					UTIL_WSC.doUpdate(inv);
                    UTIL.unCache(new Set<Id>{inv.id});
                }
            }
        }
    }
    public class BookingPush_Handler extends UTIL_WSC_API_SFECG.ApiHandler {
        public override void handle() {
            super.handle();
            if (this.result.statusCode == UTIL_WSC.HTTP_CREATED) {
                //Rev__c rev = (Rev__c) ;
                //OpportunityLineItem oli = (OpportunityLineItem) UTIL.getCached(rev.OpportunityLineItemId__c);
                String localId = (String) this.result.getResponseData().get('localId');
                if (localId==null) {
                    logError('No localId returned');
                } else {
                	Rev__c rev = [Select Id, MemberUnitId__c, OpportunityLineItemId__c From Rev__c Where Id =:this.request.contextRecord.Id For Update];
                    OpportunityLineItem oli = [Select Id, Ad_Id__c From OpportunityLineItem Where id = :rev.OpportunityLineItemId__c For Update];

                    if (rev != null) {
                    	rev.UniqueLocalBookingId__c = rev.MemberUnitId__c +'_'+localId;
                		UTIL_WSC.doUpdate(rev);

                    }
                    if (oli != null) { // booking Id is saved on Oli to sync the Oli status to 'Scheduled'
                        if (oli.Ad_Id__c==null) oli.Ad_Id__c = rev.MemberUnitId__c +'_'+localId;
                        UTIL_WSC.doUpdate(oli);
                    }
                }
            }
        }
    }
    public class AccountGet_Handler extends UTIL_WSC_API_SFECG.ApiHandler {
        public override void handle() {}
    }
    public class InvoicePDFGet_Handler extends UTIL_WSC_API_SFECG.ApiHandler {
        public override void handle() {
            super.handle();

            if (this.result.statusCode == HTTP_OK) {
                Invoice__c inv = (Invoice__c) this.request.contextRecord;

                Blob pdfContent = this.result.getBlobBody();
                Attachment att = new Attachment();
                att.parentId = inv.id;
                att.name = inv.Id + '_' + inv.UniquePlatformId__c + '.pdf';
                att.body = pdfContent;

                inv.Invoice_PDF_Retrieved__c = true;

                UTIL_WSC.doUpdate(inv);
                UTIL_WSC.doInsert(att);
            }
        }
	}
    // Field mappers

    private static List<UTIL_Fieldmapper.mappedElement> getMapper_InvoicePush(Id invId) {
        // Get the objects
        Invoice__c invoice = (Invoice__c) UTIL.getCached(invId);
        List<InvoiceLine__c> invLinesList = GW_InvoiceLine.getListFromRelated(invId);
		Account billingAccount = (Account) UTIL.getCached(invoice.BillingAccount__c);

        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add(new UTIL_Fieldmapper.mappedField('localInvoiceId',                 invoice.LocalPlatformId__c, 'String',  255, FALSE, FALSE));
		elements.add(new UTIL_Fieldmapper.mappedField('localBillingAccountId',          billingAccount.localPlatformId__c, 'String', 249  , TRUE, FALSE));
		elements.add(new UTIL_Fieldmapper.mappedField('salesforceId',                   invoice.Id, 'String', 18, TRUE, TRUE));
		elements.add(new UTIL_Fieldmapper.mappedField('billingAccountExtId',			invoice.BillingAccountExtId__c,  'String', 15, TRUE, FALSE));
		elements.add(new UTIL_Fieldmapper.mappedField('description', 					invoice.InvoiceDescription__c, 'String', 200, FALSE, FALSE));
		elements.add(new UTIL_Fieldmapper.mappedField('currency', 						invoice.CurrencyIsoCode, 'String',  3, FALSE, FALSE));

        if (invLinesList != null ) {
			GW_InvoiceLine.cacheRelatedRecords(invLinesList);
            UTIL_Fieldmapper.mappedList invLines = new UTIL_Fieldmapper.mappedList('invoiceLines');

			List<InvoiceLine__c> reversedInvLines = new List<InvoiceLine__c>();
			for (Integer i = invLinesList.size()-1; i>=0; i--) {
				reversedInvLines.add(invLinesList[i]);
			}
			invLinesList = reversedInvLines;


            User ownerIndirectDiscount = null;
            String userIdIndirectDiscount = '';

            for (InvoiceLine__c invLine : invLinesList) {
                if (invLine.Rs__c != null) {
                    RS__c rs = (RS__c)UTIL.getCached(invLine.RS__c);
					Rev__c rev = (Rev__c)UTIL.getCached(rs.Rev__c);
					Opportunity opp = (Opportunity)UTIL.getCached(rs.Opportunity__c);
					ownerIndirectDiscount = (User) UTIL.getCached(opp.OwnerId);
                    userIdIndirectDiscount = ownerIndirectDiscount.localPlatformId__c;
                    break;
                }
            }

            for(InvoiceLine__c invLine : invLinesList) {

				RS__c rs;
				Rev__c rev;
				Opportunity opp;
				User owner;
				Date startDate;
				Date endDate;

				//Opp fields
				String ioNumber;
				String poNumber;

				//Rev fields
				String localBookingId;

				//Rs fields
				Double listPrice;

				String startDateString;
				String endDateString;

				Double unitListPriceCorrectionAmount = 0;

				String userId;

				if (invLine.Rs__c != null) {
					rs = (RS__c)UTIL.getCached(invLine.RS__c);
					rev = (Rev__c)UTIL.getCached(rs.Rev__c);
					opp = (Opportunity)UTIL.getCached(rs.Opportunity__c);

					listPrice = rs.ListPrice__c;
					startDate = rs.From_Date__c;
					endDate = rs.Until_Date__c;
					if (startDate == null) startDate = invoice.StartDate__c;
					if (endDate == null) endDate = invoice.EndDate__c;

					startDateString = UTIL.formatDate(startDate, 'yyyy-MM-dd');
					endDateString = UTIL.formatDate(endDate, 'yyyy-MM-dd');

					if (rev != null) {
						unitListPriceCorrectionAmount = rev.ListPriceCorrectionForm__c;
						localBookingId = rev.LocalBookingId__c;
					}

					if (opp != null) {
						owner = (User) UTIL.getCached(opp.OwnerId);
						userId = owner.localPlatformId__c;
						ioNumber = opp.IOnumber__c;
						poNumber = opp.P_O_Number__c;
					}
				}
                else {
                    listPrice = 0;
                    userId = userIdIndirectDiscount;
                }


                invLines.add((new UTIL_Fieldmapper.mappedObject('')).
								add(new UTIL_Fieldmapper.mappedField('salesforceId', invLine.Id, 'String', 18, TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('contractId', ioNumber, 'String', 30, TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('orderId', ioNumber, 'String', 30, TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('localProductId', invLine.FQ_ProductCode__c, 'String', 50, TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('localBookingId', localBookingId, 'String', 255, FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('localUserId', userId, 'String', 255, TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('purchaseOrderId', poNumber, 'String', 255 , FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('description', invLine.InvoiceLineDescription__c, 'String', 150 , FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('quantity', invLine.Quantity__c, 'Double', 100, TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('unitPriceCorrectionFactor', invLine.UPCF__c, 'Double',  100, FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('unitListPrice', listPrice, 'Double', 100, TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('unitSalesPrice', invLine.UnitPrice__c, 'Double', 100, TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('totalSalesPrice', invLine.Amount__c, 'Double', 100 , TRUE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('vatPercentage', invLine.VatPercentage__c, 'String', 2 , FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('startDate', startDateString, 'String', 10, FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('endDate', endDateString, 'String', 10, FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('unitListPriceCorrectionAmount', unitListPriceCorrectionAmount, 'DOUBLE', 100, FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('unitAccountDiscountAmount', 0, 'Double', 100, FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('unitContractDiscountAmount', 0, 'Double', 100, FALSE, FALSE)).
								add(new UTIL_Fieldmapper.mappedField('totalAgencyDiscountAmount', 0, 'Double', 100, FALSE, FALSE))
                            );
            }
            elements.add(invLines);
        }

        return elements;
    }
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_AccountPush(Id accId) {
        Account acc 			= GW_Account.getRecord(accId);
        Account parent 			= (Account) UTIL.getCached(acc.ParentId);
        Contact financeContact	= (Contact) UTIL.getCached(acc.Finance_Contact__c);
        Contact portalUser 		= (Contact) UTIL.getCached(acc.Portal_User__c);
        Set<CustomAttribute__c> attrs;
        List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAll(accId);
        String memberUnits = '';
        for(AccountMemberUnitAssociation__c accMem : amuaList ){
            memberUnits = memberUnits + accMem.MemberUnit__r.MemberUnitId__c+ ',';
        }


        if (GW_CustomAttribute.objectCustomAttributesCache != null && GW_CustomAttribute.objectCustomAttributesCache.containsKey(accId) ) {
        	attrs = GW_CustomAttribute.objectCustomAttributesCache.get(acc.Id);
        } else {
            attrs = new Set<CustomAttribute__c>(GW_CustomAttribute.getListFromRelated(acc.Id));
        }

        if ( parent==null) 			{ parent = new Account(); }
        if ( financeContact==null) 	{ financeContact = new Contact(); }
        if ( portalUser==null) 		{ portalUser = new Contact(); }

        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add( new UTIL_Fieldmapper.mappedField('localId', 		acc.LocalPlatformId__c, 'String', 32, FALSE, FALSE) );
        elements.add( new UTIL_Fieldmapper.mappedField('accountExtId', 	acc.AccountExtId__c, 'String', 15, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('salesforceId', 	acc.Id, 'String', 18, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('memberUnit', 	memberUnits.removeEnd(','), 'String', 18, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('localParentId', parent.LocalPlatformId__c, 'String', 50, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('status',        acc.Account_Status__c, 'String', 50, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('accountName',   acc.Name, 'String', 255, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('alternativeName', acc.AlternativeName__c, 'String', 255, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('vatId',         acc.Company_VAT_No__c, 'String', 25, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('companyRegId',  acc.Company_Reg_No__c, 'String', 25, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('Created',       acc.CreatedDate, 'Datetime', 25, TRUE, FALSE) );
        elements.add( new UTIL_Fieldmapper.mappedField('Modified',      acc.LastModifiedDate, 'Datetime', 25, TRUE, FALSE) );
        elements.add( new UTIL_Fieldmapper.mappedField('OwnerId',       acc.OwnerId, 'Reference', 25, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('phone',         acc.Phone, 'String', 40, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('otherPhone',    acc.Other_Phone__c, 'String', 40, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('email',         financeContact.Email, 'String', 50, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('invoiceDeliveryMethod', acc.InvoiceDeliveryMethod__c, 'String', 255, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('inventoryUploadMethod', acc.InventoryUploadMethod__c, 'String', 40, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('callTrackingPhoneNumber', acc.CallTrackingPhoneNumber__c, 'String', 40, FALSE, TRUE));

        elements.add((new UTIL_Fieldmapper.mappedObject('billingAddress')).
            add(new UTIL_Fieldmapper.mappedField('street', 		acc.BillingStreet, 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('city', 		acc.BillingCity, 'String', 40, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('state', 		acc.BillingState, 'String', 80, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('postalCode', 	acc.BillingPostalCode, 'String', 20, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('country', 	acc.BillingCountry, 'String', 80, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('countryCode', acc.BillingCountryCode, 'String', 3, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('stateCode', 	acc.BillingStateCode, 'String', 3, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('latitude', acc.BillingLatitude, 'String', 40, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('longitude', acc.BillingLongitude, 'String', 40, FALSE, TRUE))
        );
        elements.add((new UTIL_Fieldmapper.mappedObject('shippingAddress')).
            add(new UTIL_Fieldmapper.mappedField('street', 		acc.ShippingStreet, 'String', 255, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('city', 		acc.ShippingCity, 'String', 40, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('state', 		acc.ShippingState, 'String', 80, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('postalCode', 	acc.ShippingPostalCode, 'String', 20, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('country', 	acc.ShippingCountry, 'String', 80, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('countryCode', acc.ShippingCountryCode, 'String', 3, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('stateCode', 	acc.ShippingStateCode, 'String', 3, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('latitude', acc.ShippingLatitude, 'String', 40, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('longitude', acc.ShippingLongitude, 'String', 40, FALSE, TRUE))
        );

        elements.add( (new UTIL_Fieldmapper.mappedObject('financialContact')).
        	add(new UTIL_Fieldmapper.mappedField('firstName', 	financeContact.FirstName, 'String', 40, FALSE, TRUE)).
        	add(new UTIL_Fieldmapper.mappedField('lastName', 	financeContact.LastName, 'String', 50, FALSE, TRUE)).
        	add(new UTIL_Fieldmapper.mappedField('salutation', 	financeContact.Salutation, 'String', 50, FALSE, TRUE)).
        	add(new UTIL_Fieldmapper.mappedField('email', 		financeContact.Email, 'String', 50, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('phone',       financeContact.Phone, 'String', 32, FALSE, TRUE))
        );
        elements.add((new UTIL_Fieldmapper.mappedObject('portalUser')).
            add(new UTIL_Fieldmapper.mappedField('firstName',	portalUser.FirstName, 'String', 50, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('lastName',	portalUser.LastName, 'String', 80, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('salutation',	portalUser.Salutation, 'String', 50, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('email',		portalUser.Email, 'String', 50, FALSE, TRUE)).
            add(new UTIL_Fieldmapper.mappedField('phone',       financeContact.Phone, 'String', 32, FALSE, TRUE))
        );

        if (attrs != null ) {
            UTIL_Fieldmapper.mappedList customAttrs = new UTIL_Fieldmapper.mappedList('customAttributes');

            for(CustomAttribute__c attr :attrs) {
                customAttrs.add( (new UTIL_Fieldmapper.mappedObject('')).
                                add(new UTIL_Fieldmapper.mappedField('key', attr.Name , 'String', 80, TRUE, TRUE)).
                                add((UTIL_Fieldmapper.MappedElement)GW_CustomAttribute.getAPIValue(attr))
                               );
            }
            elements.add(customAttrs);
        }
        return elements;
    }
    
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_BookingPush(Id revId) {
        
        Rev__c rev 				= (Rev__c) UTIL.getCached(revId);
        Product2 prod			= (Product2) UTIL.getCached(rev.Product__c);
        if ( prod==null) 		{ prod = new Product2(); }

        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add( new UTIL_Fieldmapper.mappedField('localId', rev.LocalBookingId__c, 'String', 32, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('salesforceId', rev.Id, 'String', 18, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('productId', prod.LocalProductId__c, 'String', 18, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('startDate', rev.From_Date__c, 'Date', 18, TRUE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('endDate', rev.Until_Date__c, 'Date', 18, TRUE, TRUE) );
        
        Opportunity opp = (Opportunity) UTIL.getCached(rev.Opportunity__c);

        String revStatus = rev.Status__c;
        if(rev.MemberUnitId__c == 'ECITAAU' && revStatus == 'Finished'){
            Date curDate = Date.today();
            // CD-3712 to check if master RI has running adjustments for sending correct status to the local platform
            if(opp.Rev_Campaign_Start__c <= curDate && opp.Rev_Campaign_End__c >= curDate){
                revStatus = 'Running';
            }
        }
        System.debug(revStatus);
        elements.add( new UTIL_Fieldmapper.mappedField('bookingStatus', revStatus, 'String', 50, TRUE, TRUE));

        User oppOwner = (User) UTIL.getCached( opp.OwnerId );        
        PriceBookEntry pbe = GW_PriceBookEntry.getPbeFromCache( prod.Id , rev.PriceBook__c );
        if( pbe == null )    { pbe = new PriceBookEntry(); }

        elements.add( new UTIL_Fieldmapper.mappedField( 'username', oppOwner.email , 'String', 64, TRUE, TRUE ) );
        elements.add( new UTIL_Fieldmapper.mappedField( 'quantity', rev.QuantityBilled__c, 'Double', 100 , FALSE, FALSE ) );
        elements.add( new UTIL_Fieldmapper.mappedField( 'thresholdQuantity', rev.BundleSize__c, 'Double', 100 , FALSE, FALSE ) );

        if( rev.LocalBookingId__c == null ){

            UTIL_Fieldmapper.MappedList wrapperElement = new UTIL_Fieldmapper.MappedList('wrapper' , false ); 
    
            UTIL_Fieldmapper.MappedObject pbeElem = new UTIL_Fieldmapper.MappedObject( 'productDetails' , false );
            pbeElem.add( new UTIL_Fieldmapper.mappedField( 'description' , pbe.Description__c, 'String', 100, FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'packageName' , pbe.PackageName__c, 'String', 50, FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'packageType' , pbe.PackageType__c, 'String', 2, FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'savingsRate' , pbe.SavingsRate__c, 'String', 2, FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'isSpecialPrice' , pbe.IsSpecialPrice__c, 'String', 5 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'isTopup' , pbe.IsTopup__c, 'String', 5 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'enableWebsiteURL__c' , pbe.EnableWebsiteURL__c, 'String', 5 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numAds' , pbe.NumAds__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numBumpUps' , pbe.NumBumpUps__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numHighlights' , pbe.NumHighlights__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numHomepageGallery' , pbe.NumHomepageGallery__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numHomepageGallery31' , pbe.NumHomepageGallery31__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numSRPGallery7' , pbe.NumSRPGallery7__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numSRPGallery31' , pbe.NumSRPGallery31__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numTopAd7' , pbe.NumTopAd7__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numTopAd15' , pbe.NumTopAd15__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numTopAd31' , pbe.NumTopAd31__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numUrgent' , pbe.NumUrgent__c, 'Double', 100 , FALSE, FALSE ) )
                   .add( new UTIL_Fieldmapper.mappedField( 'numWebsiteURL' , pbe.NumWebsiteURL__c, 'Double', 100 , FALSE, FALSE ) );
    
            wrapperElement.add( pbeElem );
            
            elements.addAll( wrapperElement.children );
        }
                
        return elements;
    }

	// Mocks
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_AccountPush() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();

        // insert account succesful
        mocks.put('insertSuccess',new UTIL_WSC.WSC_Mock('OK',201,'{"localId": "123456789","accountExtId": "THBEL0000022303","salesforceId": "001O000000ptlLzIAI","localParentId": null,"status": "Active","accountName": "Test Acc","vatId": null,"billingAddress": {"stateCode": null,"countryCode": "NL","country": "Netherlands","postalcode": "1000AA","state": null,"city": "Amsterdam","street": "Wibautstraat"},"shippingAddress": {"stateCode": null,"countryCode": null,"country": null,"postalcode": null,"state": null,"city": null,"street": null},"financialContact": {"email": "test@jvdheuvel.net","salutation": null,"lastName": "Test","firstName": "T"},"portalUser": {"password": "{}%^MySecurePassword123","username": "testUser123","email": "test@jvdheuvel.net","salutation": null,"lastName": "Test","firstName": "T"}}'));

        return mocks;
    }
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_BookingPush() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();

        // insert account succesful
        mocks.put('insertSuccess',new UTIL_WSC.WSC_Mock('OK',201,'{"localId" : "24","productId" : "2","startDate" : "2015-12-17","endDate" : "2016-12-31"}'));

        return mocks;
    }
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_AccountGet() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();

        // insert account succesful

        mocks.put('getSuccess',new UTIL_WSC.WSC_Mock('OK',201,'{"localId": "123456789","accountExtId": "THBEL0000022303","salesforceId": "001O000000ptlLzIAI","localParentId": null,"status": "Active","accountName": "Test Acc","vatId": null,"billingAddress": {"stateCode": null,"countryCode": "NL","country": "Netherlands","postalcode": "1000AA","state": null,"city": "Amsterdam","street": "Wibautstraat"},"shippingAddress": {"stateCode": null,"countryCode": null,"country": null,"postalcode": null,"state": null,"city": null,"street": null},"financialContact": {"email": "test@jvdheuvel.net","salutation": null,"lastName": "Test","firstName": "T"},"portalUser": {"password": "{}%^MySecurePassword123","username": "testUser123","email": "test@jvdheuvel.net","salutation": null,"lastName": "Test","firstName": "T"}}'));

        return mocks;
    }
	private static Map<String, UTIL_WSC.WSC_Mock> getMocks_InvoicePDFGet() {
		return new Map<String, UTIL_WSC.WSC_Mock>();
	}
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_InvoicePush() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
        // Fake, update to be relevant
        mocks.put('insertSuccess',new UTIL_WSC.WSC_Mock('OK',201,'{"localId": "123456789"}'));
        return mocks;
    }

}