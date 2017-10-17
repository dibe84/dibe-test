/**
 * Created by rvannierop on 1/31/2017.
 */

public class WSC_API_SFECG_v2 {
    private static final String APINAME = 'WSC_API_SFECG_v2';
    private static final String API_UTIL_NAME = 'UTIL_WSC_API_SFECG';

	
	public class ServiceDeactivationSpoc extends UTIL_WSC_API_SFECG.ApiRequest{
		
		Opportunity opp;
		
		public override void init(Id contextRecordId){
			this.setCalloutDetails('ServiceDeactivationSpoc',APINAME);
			super.init(contextRecordId);
			opp = GW_Opportunity.getRecord(contextRecordId, new List<String>{'Account.LocalPlatformId__c'});
			String memberUnitId = opp.MemberUnitId__c;
			this.getWsSettings(APINAME,memberUnitId);
			this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsUser, this.wsKeystring));
			
			Map<String, String> mapParams = new Map<String, String>();
            mapParams.put('terminationReason', String.valueOf(this.mAdditionalParams.get('terminationReason')));
            mapParams.put('endDate', String.valueOf(this.mAdditionalParams.get('endDate')));
			mapParams.put('proName', String.valueOf(this.mAdditionalParams.get('proName')));
            mapParams.put('memberUnitId', memberUnitId);
            String uniqueLocalBookingId = String.valueOf(this.mAdditionalParams.get('uniqueLocalBookingId'));
            
			Boolean isInsert = opp.LocalPlatformId__c  == null;
			this.mapper.mappingElements = getMapper_ServiceDeactivationSpoc(opp, isInsert, mapParams);
			Map<String,Object> output = this.mapper.getOutputMap();
			this.setResultClass(API_UTIL_NAME +'.ApiResult');
            this.setHandlerClass(APINAME+'.ServiceDeactivationSpoc_Handler');
            this.mockMap.putAll(getMocks_ServiceDeactivationSpoc());
            
            if(String.isBlank(uniqueLocalBookingId)) {
            	List<OpportunityLineItem> oplList = GW_OpportunityLineItem.getListFromRelated(opp.Id);
            	uniqueLocalBookingId = (oplList == null || oplList.isEmpty()) ? '' : oplList[0].UniqueLocalBookingId__c;
            }
            
            String endPoint = this.baseEndpoint + 'accounts/'+ opp.Account.LocalPlatformId__c+'/bookings/' + uniqueLocalBookingId;
            if( !String.isBlank( this.endpointURLParameters ) ){
                endPoint += '?' + this.endpointURLParameters;
            }
            this.setHttpMethod('PUT');
            this.setEndpoint(endPoint);
		}
		
		public override Boolean readyForCallout() {
            return true;
        }
	}
	
	
    public class BookingPushTract extends UTIL_WSC_API_SFECG.ApiRequest{

        OpportunityLineItem opl;
        Opportunity opp;
        Account acc;

        public override void init(Id contextRecordId) {
            this.setCalloutDetails('BookingPushTract',APINAME);
            super.init(contextRecordId);
            opp = GW_Opportunity.getRecord(contextRecordId);
            this.getWsSettings(APINAME,opp.MemberUnitId__c);  
            this.setEndpoint(this.baseEndpoint); 
            this.setHeader('Authorization', UTIL_WSC.getBasicAuthenticationKey(this.wsUser, this.wsKeystring));

            List<OpportunityLineItem> oppLineItem = GW_OpportunityLineItem.getListFromRelated(opp.Id);
            if ( oppLineItem != null && !oppLineItem.isEmpty() ){
            	opl = oppLineItem[0];	
            }
            
            Map<id,Account> accountMap = GW_Account.getMapFromRelated(new List<Opportunity>{opp});
            if ( accountMap.values().size() != 0 ) acc = accountMap.values()[0];

            this.mapper.mappingElements = getMapper_BookingPushTract(opl.Id);
            Map<String,Object> output = this.mapper.getOutputMap();
            this.setResultClass(API_UTIL_NAME +'.ApiResult');
            this.setHandlerClass(APINAME+'.BookingPushTract_Handler');
            this.mockMap.putAll(getMocks_BookingPush());

            String endPoint = '';
            if (String.isBlank(opl.UniqueLocalBookingId__c)) { 				// Insert
                endPoint = this.baseEndpoint + 'accounts/'+acc.LocalPlatformId__c+'/bookings';
                this.setHttpMethod('POST');
            } else { 											// Update
                endPoint = this.baseEndpoint + 'accounts/'+acc.LocalPlatformId__c+'/bookings/'+opl.UniqueLocalBookingId__c;
                this.setHttpMethod('PUT');
            }
            if( !String.isBlank( this.endpointURLParameters ) ){
                endpoint += '?' + this.endpointURLParameters;
            }
            this.setEndpoint(endPoint);
        }
        public override Boolean readyForCallout() {
            return opp.ContractStatus__c == 'Signed';
        }

    }

    public class bookingPush extends UTIL_WSC_API_SFECG.ApiRequest {
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
            this.setResultClass(API_UTIL_NAME +'.ApiResult');
            this.setHandlerClass(APINAME+'.BookingPush_Handler');
            this.mockMap.putAll( getMocks_BookingPush() );

            if (rev.LocalBookingId__c == null) { 				// Insert
                this.setEndpoint(this.baseEndpoint + 'accounts/'+acc.LocalPlatformId__c+'/bookings');
                this.setHttpMethod('POST');
            } else { 											// Update
                this.setEndpoint(this.baseEndpoint + 'accounts/'+acc.LocalPlatformId__c+'/bookings/'+rev.LocalBookingId__c);
                this.setHttpMethod('PUT');
            }
        }
        public override Boolean readyForCallout() {
            Boolean isReady = (rev != null &&
                    rev.NumStatus__c > 1 && 			// rev should be signed
                    acc.LocalPlatformId__c != null && 	// account should be synced with local platform
                    !rev.OutOfSync__c && 				// rev should be in Sync state
                    rev.Type__c == 'Master' 			// only Master Revenue Items should be sent.
            );

            return isReady;
        }
    }// END BookingPush

    //////////////////////////////////////////////////////////////////////
    // Implementation of handler, mapper and mocks - per API method
    //////////////////////////////////////////////////////////////////////

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

    public class BookingPushTract_Handler extends UTIL_WSC_API_SFECG.ApiHandler {
        public override void handle() {
            super.handle();
            if (this.result.statusCode == UTIL_WSC.HTTP_CREATED) {
			    //PlaceHolder
			    String localId = (String) this.result.getResponseData().get('localId');
			    Opportunity opp = GW_Opportunity.getRecord(request.contextRecord.Id);
			    //opp.LocalPlatformId__c = localId;
			    List<Opportunity> opps = new List<Opportunity>{opp};
				GW_Opportunity.setTractOrderStatus(opps);
				UTIL_WSC.doUpdate(opps);
                List<OpportunityLineItem> oppLineItem = GW_OpportunityLineItem.getListFromRelated(opp.Id);
                if ( oppLineItem != null && !oppLineItem.isEmpty() ) {
                    oppLineItem[0].UniqueLocalBookingId__c = localId;
                    update oppLineItem;
                }
            }
        }
    }

	public class ServiceDeactivationSpoc_Handler extends UTIL_WSC_API_SFECG.ApiHandler {
		public override void handle() {
            super.handle();
            if (this.result.statusCode == UTIL_WSC.HTTP_CREATED || this.result.statusCode == UTIL_WSC.HTTP_NOCONTENT || this.result.statusCode == UTIL_WSC.HTTP_OK) {
            	List<OpportunityLineItem> oplList = GW_OpportunityLineItem.getListFromRelated(request.contextRecord.Id);
            	if (oplList.isEmpty()) return;
                List<TRACT_Service__c> services = GW_TractService.getRecordByOliId(oplList[0].Id);
                if (!services.isEmpty()) {
                    for (TRACT_Service__c service : services) {
                        service.LocalDeactivated__c = true;
                    }
                    update services;
                }
            }
        }
	}
	
	private static List<UTIL_Fieldmapper.mappedElement> getMapper_ServiceDeactivationSpoc(Opportunity opp, Boolean isInsert, Map<String, String> mapParams) {
        String endDate = mapParams.get('endDate');
        String memberUnitId = mapParams.get('memberUnitId');
        String terminationReason = mapParams.get('terminationReason');
        String proName = mapParams.get('proName');
		proName = String.escapeSingleQuotes(proName);
        List<OpportunityLineItem> lstoplis = GW_sObject.queryRecords('OpportunityLineItem','Product2.Name like \'%' + proName + '%\' AND OpportunityId =\'' + opp.Id + '\' limit 1', new List<String>{'product2.Tract_SKU__c', 'product2.Parent__c','product2.tract_ParentId__c'});
		List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
		if(!lstoplis.isEmpty()){
			OpportunityLineItem lineItem = lstoplis[0];
		
			elements.add(new UTIL_Fieldmapper.mappedField('localid', opp.Account.LocalPlatformId__c, 'String', 100, FALSE, FALSE));
			elements.add(new UTIL_Fieldmapper.mappedField('memberUnit', memberUnitId, 'String', 100, FALSE, FALSE));
			elements.add(new UTIL_Fieldmapper.mappedField('SKU_Number', lineItem.Product2.Tract_SKU__c.split('#')[0], 'String', 100, FALSE, FALSE));
			elements.add(new UTIL_Fieldmapper.mappedField('endDate', endDate, 'String', 100, FALSE, FALSE));
			elements.add(new UTIL_Fieldmapper.mappedField('terminationReason', terminationReason, 'String', 100, FALSE, FALSE));
            
		}
		
       	return elements;
    }
    
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_BookingPush(Id revId) {

        Rev__c rev 				= (Rev__c) UTIL.getCached(revId);
        Subscription subscr     = new Subscription(rev.Id);
        Opportunity opp         = (Opportunity) UTIL.getCached( rev.Opportunity__c );
        User oppOwner           = (User) UTIL.getCached( opp.OwnerId );


        Set<Id> revProductIds = new Set<Id>();
        Set<Id> revPricebookIds = new Set<Id>();
        Map<Id, Product2> productMap;
        Map<Id, Pricebook2> pricebookMap;
        Map<Id, PricebookEntry> pricebookEntryMap = new Map<Id, PricebookEntry>();
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();

        for (Rev__c r : subscr.revItems) {
            revPricebookIds.add(r.Pricebook__c);
            revProductIds.add(r.Product__c);
        }

        productMap = new Map<Id, Product2>([SELECT Id, LocalProductId__c FROM Product2 WHERE Id IN: revProductIds]);
        pricebookMap = new Map<Id, Pricebook2>([SELECT Id, Name FROM PriceBook2 WHERE Id IN: revPricebookIds]);
        pricebookEntryMap = new Map<Id, PricebookEntry>([SELECT Id, Name FROM PricebookEntry WHERE Product2Id IN :revProductIds AND Pricebook2Id IN :revPricebookIds ]);
        pricebookEntries = (List<PricebookEntry>) GW_sObject.queryRecords('PricebookEntry', pricebookEntryMap.keySet());
        GW_PriceBookEntry.putPbesInCache(pricebookEntries);

        List<UTIL_Fieldmapper.mappedElement> elements = new List<UTIL_Fieldmapper.MappedElement>();
        elements.add( new UTIL_Fieldmapper.mappedField('localId', rev.LocalBookingId__c, 'String', 32, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('salesforceId', rev.Id, 'String', 18, FALSE, TRUE) );
        elements.add( new UTIL_Fieldmapper.mappedField('subscriptionEndDate', rev.SubscriptionEndDate__c, 'Date', 18, TRUE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('terminationDate', rev.TerminationDate__c, 'Date', 18, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('terminationReason', rev.TerminationReason__c, 'String', 255, FALSE, TRUE));
        elements.add( new UTIL_Fieldmapper.mappedField('username', oppOwner.email , 'String', 64, TRUE, TRUE ) );

        UTIL_Fieldmapper.mappedList adjustments = new UTIL_Fieldmapper.mappedList('adjustments');

        for (Rev__c r : subscr.revitems) {

            Product2 product = productMap.get(r.Product__c);
            PriceBook2 pb = pricebookMap.get(r.Pricebook__c);
            PriceBookEntry pbe = GW_PriceBookEntry.getPbeFromCache( product.Id , pb.Id );
            if( pbe == null )    { pbe = new PriceBookEntry(); }

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


            adjustments.add( (new UTIL_Fieldmapper.mappedObject('')).
                    add( new UTIL_Fieldmapper.mappedField('localProductId', product.localProductId__c, 'String', 148, TRUE, TRUE) ).
                    add( new UTIL_Fieldmapper.mappedField('pricebookName', pb.Name, 'String', 255, TRUE,TRUE)).
                    add( new UTIL_Fieldmapper.mappedField('startDate', r.From_Date__c, 'Date', 18, TRUE, TRUE)).
                    add( new UTIL_Fieldmapper.mappedField('endDate', r.Until_Date__c, 'Date', 18, TRUE, TRUE)).
                    add( new UTIL_Fieldmapper.mappedField('type', r.Type__c, 'String', 255, TRUE, TRUE)).
                    add( new UTIL_Fieldmapper.mappedField('unitPrice', r.UnitPrice__c, 'Double', 100, TRUE, TRUE)).
                    add( new UTIL_Fieldmapper.mappedField('tresholdQuantity', r.BundleSize__c, 'Double', 100, FALSE, TRUE)).
                    add( new UTIL_Fieldmapper.mappedField('contractDiscountPercentage', r.ContractDiscount__c, 'Double', 100, FALSE,TRUE) ).
                    add( new UTIL_Fieldmapper.mappedField('bookingStatus', r.Status__c, 'String', 255, TRUE, TRUE) ).
                    add( new UTIL_Fieldmapper.mappedField('quantity', rev.QuantityBilled__c, 'Double', 100 , FALSE, FALSE ) ).
                    add(pbeElem)
            );

        }
        elements.add(adjustments);

        return elements;
    }
    private static List<UTIL_Fieldmapper.mappedElement> getMapper_BookingPushTract(Id oplId) {
        OpportunityLineItem opli = GW_OpportunityLineItem.getRecord(oplId);
        Opportunity opp = GW_Opportunity.getRecord(opli.OpportunityId);
        Id oppId = opp.Id;
        Account acc = GW_Account.getRecord(opp.accountId);
                
        //List<OpportunityLineItem> opls = GW_OpportunityLineItem.getListFromRelated(opp.Id);
        List<OpportunityLineItem> opls = GW_sObject.queryRecords('OpportunityLineItem','OpportunityId =\'' + oppId + '\'', new List<String>{'product2.Tract_SKU__c, product2.Parent__c','product2.tract_ParentId__c'});
		//collect product ids from Opportunity Product
        Set<Id> setProductIds = new Set<Id>();

        List<AccountMemberUnitAssociation__c> amuaList = GW_AccountMemberUnitAssociation.getAll(acc.Id);
        String memberUnits = '';
        for(AccountMemberUnitAssociation__c accMem : amuaList ){
            memberUnits = memberUnits + accMem.MemberUnit__r.MemberUnitId__c+ ',';
        }


        for (OpportunityLineItem lineItem : opls) setProductIds.add( (!String.isBlank(lineItem.Product2.Parent__c)) ? lineItem.Product2.Parent__c : lineItem.Product2Id);
        //map product Id with list product tags
        Map<id, List<ProductTag__c>> mProdvsProductTags = (Map<id, List<ProductTag__c>>) GW_sObject.getChildrenMap(setProductIds, 'ProductTags__r', null);
		system.debug('ProductTags ' + mProdvsProductTags);
		
        if(opls.isEmpty()) {
            UTIL.throwError('Opportunity ' + opp.Name + ' does not contain any Opportunity Line Items');
            return null;
        }else {
			mProdvsProductTags = mProdvsProductTags == null ? new Map<id, List<ProductTag__c>>() : mProdvsProductTags;
            User usr = GW_User.getUser(opp.CreatedById);
            // Get the memberunit details.
            MemberUnit__c memberUnit = GW_MemberUnit.getMemberUnitById(GW_AccountMemberUnitAssociation.getAll(opp.accountId)[0].MemberUnit__c);
            
            List<UTIL_Fieldmapper.mappedElement> message = new List<UTIL_Fieldmapper.MappedElement>();
            message.add(new UTIL_Fieldmapper.mappedField('localid',acc.LocalPlatformId__c, 'String', 100, FALSE, FALSE));
            message.add(new UTIL_Fieldmapper.mappedField('salesforceId', opp.Id, 'String', 50, FALSE, FALSE));

            //message.add(new UTIL_Fieldmapper.mappedField('startDate', '27-04-2017','String', 50, FALSE, FALSE));
            //message.add(new UTIL_Fieldmapper.mappedField('endDate', '28-06-2017','String', 50, FALSE, FALSE));
            message.add(new UTIL_Fieldmapper.mappedField('bookingStatus',opp.Status__c, 'String', 50, FALSE, FALSE));
            message.add( new UTIL_Fieldmapper.mappedField('memberUnit',memberUnits.removeEnd(','), 'String', 18, TRUE, TRUE) );
            //message.add(new UTIL_Fieldmapper.mappedField('accountCategegory', memberUnit.Account_Category__c, 'String', 50, FALSE, FALSE));
            //message.add(new UTIL_Fieldmapper.mappedField('verticalCategory', 'Autos', 'String', 50, FALSE, FALSE));
            //message.add(new UTIL_Fieldmapper.mappedField('countryCode', acc.BillingCountryCode, 'String', 50, FALSE, FALSE));  // ToDo: This should be looked in the customSetting based on the acc.BillingCountryCode
            message.add(new UTIL_Fieldmapper.mappedField('username', usr.Email, 'String', 50, FALSE, FALSE));
           
            UTIL_Fieldmapper.mappedList oppLineItemsList = new UTIL_Fieldmapper.mappedList('lineItems');
            for (OpportunityLineItem opl:opls) {
                //Product2 product = GW_Product.getRecord(opl.product2Id);
                UTIL_Fieldmapper.mappedObject lineItemsObject = new UTIL_Fieldmapper.mappedObject('');
                lineItemsObject.add(new UTIL_Fieldmapper.mappedField('salesforceId', opl.Id, 'String', 50, FALSE, FALSE));
                lineItemsObject.add(new UTIL_Fieldmapper.mappedField('serviceResourceId', opl.Tract_ServiceId__c, 'String', 50, FALSE, FALSE));
                lineItemsObject.add(new UTIL_Fieldmapper.mappedField('productId', opl.product2.Tract_SKU__c.split('#')[0], 'String', 50, FALSE, FALSE));
                lineItemsObject.add(new UTIL_Fieldmapper.mappedField('productName', opl.productName__c, 'String', 50, FALSE, FALSE));
                Double quantity = double.valueOf(opl.Quantity);
                lineItemsObject.add(new UTIL_Fieldmapper.mappedField('quantity', quantity.intValue(), 'Integer',32, FALSE, FALSE));
                lineItemsObject.add(new UTIL_Fieldmapper.mappedField('startDate', opl.from_Date__c, 'String',32, FALSE, FALSE));

                //if product has Parent__c field is blank --> it's a parent product
				String productId = String.isBlank(opl.Product2.Parent__c) ? opl.Product2Id : opl.Product2.Parent__c;
				//add Product Tag to mapperu
                lineItemsObject.add(getMapper_ProductTags(mProdvsProductTags.get(productId)));
                oppLineItemsList.add(lineItemsObject);
            }
            message.add(oppLineItemsList);
            return message;
        }
    }
	
	/**
     * Generate Product Tag mapper
     * @param: lstProductTags a list of Product Tag
     * @return: list of product tag mapper
     */
    private static UTIL_Fieldmapper.mappedList getMapper_ProductTags(List<ProductTag__c> lstProductTags) {
    	lstProductTags = lstProductTags == null ? new List<ProductTag__c>() : lstProductTags;
        UTIL_Fieldmapper.mappedList mapProductTag = new UTIL_Fieldmapper.mappedList('productTags');
        for (ProductTag__c productTag : lstProductTags) {
            UTIL_Fieldmapper.mappedObject productTagObj = new UTIL_Fieldmapper.mappedObject('');
            productTagObj.add(new UTIL_Fieldmapper.mappedField('id', (productTag.ProductTag_External_ID__c+'').split('_').size() == 2 ? (productTag.ProductTag_External_ID__c+'').split('_')[1]:'', 'String', 32, FALSE, FALSE))
            			.add(new UTIL_Fieldmapper.mappedField('name', productTag.Name, 'String', 50, FALSE, FALSE))
            			.add(new UTIL_Fieldmapper.mappedField('description', productTag.Description__c, 'String', 50, FALSE, FALSE))
            			.add(new UTIL_Fieldmapper.mappedField('priority', 23, 'Double', 32, FALSE, FALSE));
            mapProductTag.add(productTagObj);
        }
        
        return mapProductTag;
    }
    
    //Mocks
    private static Map<String, UTIL_WSC.WSC_Mock> getMocks_BookingPush() {
        Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();

        // insert account succesful
        mocks.put('insertSuccess',new UTIL_WSC.WSC_Mock('OK',201,'{"localId" : "24_v2","productId" : "2","startDate" : "2015-12-17","endDate" : "2016-12-31"}'));

        return mocks;
    }
    
    private static Map<String, UTIL_WSC.WSC_MOCK> getMocks_ServiceDeactivationSpoc(){
    	Map<String, UTIL_WSC.WSC_Mock> mocks = new Map<String, UTIL_WSC.WSC_Mock>();
    	mocks.put('insertSuccess',new UTIL_WSC.WSC_Mock('OK', 201, '{"localId" : "24_v2","productId" : "2","startDate" : "2015-12-17","endDate" : "2016-12-31"}'));
    	return mocks;
    }
}