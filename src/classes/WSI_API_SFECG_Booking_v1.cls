public with sharing class WSI_API_SFECG_Booking_v1 {

    private static final String APINAME = 'WSI_API_SFECG_Booking_v1';


    public WSI_API_SFECG_Booking_v1() { }

    public static void process(String wsClassName, WSI_CTRL.APIResponse resp, Booking booking) {
            Type t = Type.forName(APINAME + '.' + wsClassName);
            WSI_BookingApiRequest apiRequest = (WSI_BookingApiRequest) t.newInstance();

            apiRequest.init(resp, booking);
            apiRequest.processRequest();
    }


    public class Booking {

            public String memberId {get; set;}
            public String accountId {get; set;}
            public String memberUnitId {get;set;}
            public String bookingId {get; set;}
            public String localOpportunityId {get;set;}
            public String uniqueLocalOpportunityId {get;set;}
            public String localProductId {get;set;}
            public String startDateString {get;set;}
            public Date startDate {get;set;}
            public String terminationDateString {get;set;}
            public Date terminationDate {get;set;}
            public String terminationReason {get;set;}
            public Decimal unitPrice {get;set;}
            public String type {get;set;}
            public Integer tresholdQuantity {get;set;}
            public Decimal contractDiscountPercentage{get;set;}
            public String status {get;set;}
            public String purchaseOrderNumber {get;set;}

            public String localId {get;set;}
            public String pricebookName {get;set;}
            public String memberUnit {get;set;}
            public String bookingStatus {get;set;}
            public String salesforceId {get;set;}
            public List<Map<String, String>> lineItems {get; set;}

            public Opportunity opp{get;set;}
            public OpportunityLineItem oli{get;set;}
            public Account acc{get;set;}
            public PriceBookEntry priceBookEntry {get;set;}
            public Map<String, PriceBookEntry> priceBookEntryMap {get;set;}
            public Rev__c masterRevenueItem {get;set;}

            public List<OpportunityLineItem> olis {get; set;}


            public override String toString() {
                return '{ '
                        + 'MemberId : \'' + memberId +'\', '
                        + 'accountId : \'' + accountId +'\', '
                        + 'memberUnitId : \'' + memberUnitId +'\', '
                        + 'bookingId : \'' + bookingId +'\', '
                        + 'localOpportunityId : \'' +  localOpportunityId +'\', '
                        + 'pricebookName : \'' +  pricebookName +'\', '
                        + 'localProductId : \'' +  localProductId +'\', '
                        + 'startDateString : \'' +  startDateString +'\', '
                        + 'startDate : ' +  startDate +', '
                        + 'terminationDateString : \'' +  terminationDateString +'\', '
                        + 'terminationReason : \'' +  terminationReason +'\', '
                        + 'unitPrice : ' +  unitPrice +', '
                        + 'contractDiscountPercentage : ' + contractDiscountPercentage + ', '
                        + 'type : \'' + type + '\' '
                        + '}';
            }

            public void digestRequest(Map<String,Object> requestJSON) {

                try{

                    this.localOpportunityId = (String) requestJSON.get('localOpportunityId');
                    this.status = (String) requestJSON.get('status');
                    this.purchaseOrderNumber = (String) requestJSON.get('purchaseOrderNumber');


                    this.localId = (String) requestJSON.get('localId');
                    this.pricebookName = (String) requestJSON.get('pricebookName');
                    //this.memberUnit = (String) requestJSON.get('memberUnit');
                    this.bookingStatus = (String) requestJSON.get('bookingStatus');
                    this.type = (String) requestJSON.get('type');
                    this.salesforceId = (String) requestJSON.get('salesforceId');
                    List<Object> listItemObjects = (List<Object>) requestJSON.get('lineItems');
                    this.lineItems = new List<Map<String, String>>();
                    for ( Object record: listItemObjects ){
                        
                        this.lineItems.add( 
                            digestLineItemRequest ( (Map<String, Object>) JSON.deserializeUntyped( JSON.serialize(record) ) )
                        );

                    }

                } catch(Exception e) {
                    throw new UTIL.CustomException('Parameters in request body in incorrect format: ' + requestJSON +  e.getMessage());
                }
            }

            

            private Map<String, String> digestLineItemRequest( Map<String, Object> listItemsJSON ) {
                
                if ( listItemsJSON == null ) return null;
            
                Map<String, String> listItemsData = new Map<String, String>();
                
                listItemsData.put('localId', (String) listItemsJSON.get('localId') );
                listItemsData.put('parentLineItemId', (String) listItemsJSON.get('parentLineItemId') );
                listItemsData.put('productId', (String) listItemsJSON.get('productId') );
                listItemsData.put('quantity', String.valueOf( listItemsJSON.get('quantity') ) );
                listItemsData.put('salesPrice', (String) listItemsJSON.get('salesPrice') );
                listItemsData.put('startDate', (String) listItemsJSON.get('startDate') );
                listItemsData.put('endDate', (String) listItemsJSON.get('endDate') );
                
                return listItemsData;
        
            }

            public void initOpportunity() {
            
                MemberUnit__c muObject = [select Id from MemberUnit__c where MemberUnitId__c =: this.memberUnitId limit 1];
                Id memberUnitSalesforceId = muObject != null ? muObject.Id : null;
                if ( memberUnitSalesforceId != null ) {
                    UTIL.cache(GW_sObject.queryRecords('MemberUnit__c', new Set<Id>{memberUnitSalesforceId}));
                }
                this.uniqueLocalOpportunityId = this.memberUnitId + '_' + this.localOpportunityId == null ? bookingId : null;
                if (this.salesforceId != null) {
                    //localOpportunityId
                    //Look it up
                    List<sObject> opps = GW_sObject.queryRecords('Opportunity', 'Id = \'' + this.salesforceId + '\'');
                    if (opps.size() > 0) {
                        //Found it?
                       //Store it as the parent to link the new booking to.
                        this.opp = (Opportunity) opps.get(0);
                    }
                    else {
                        //Else it is a new Opportunity and localOpportunityId was supplied
                        //Store it as the opportunity that needs upsertion and linking with the rev later.
                        this.opp = new Opportunity(UniquePlatformId__c = this.uniqueLocalOpportunityId);
                    }
                }
                else {
                    this.opp = new Opportunity();
                }


                ////populateOpportunity();
                    if (this.localOpportunityId != null) {
                        this.opp.Name = 'SelfService_' + this.localOpportunityId;
                    }
                    else {
                        this.opp.Name = 'SelfService_' + this.localId + ' ' + System.now().format();
                    }
                    if (this.opp.Id == null){
                        this.opp.closeDate = Date.today();
                        this.opp.accountId = this.acc.Id;
                        this.opp.RecordTypeId = UTIL_RecordType.getRecordTypeByName('Opportunity', this.bookingStatus != null && this.bookingStatus.equalsIgnoreCase('Signed') ? 'Approved' : 'Preapproved').Id;
                        this.opp.ApprovalStatus__c = this.bookingStatus != null && this.bookingStatus.equalsIgnoreCase('Signed') ? 'Previously Approved' : 'Approval Requested';
                        this.opp.contractStatus__c = this.bookingStatus;
                        if ( memberUnitSalesforceId != null )
                            this.opp.MemberUnit__c = memberUnitSalesforceId;
                    }

                    if ( this.uniqueLocalOpportunityId != null && this.opp.UniquePlatformId__c != this.uniqueLocalOpportunityId ) 
                        this.opp.UniquePlatformId__c = this.uniqueLocalOpportunityId;
                    if ( this.bookingStatus != null && this.opp.Status__c != this.bookingStatus ) {
                        this.opp.Status__c = this.bookingStatus;
                        this.opp.StageName = this.bookingStatus;
                        this.opp.ContractStatus__c = this.bookingStatus;
                    }
                    if ( this.purchaseOrderNumber != null && this.opp.P_O_Number__c != this.purchaseOrderNumber )
                        this.opp.P_O_Number__c = this.purchaseOrderNumber;
                        
                    if (this.opp.Primary_Contact__c == null) this.opp.Primary_Contact__c = this.acc.Finance_contact__c;

            }
    }

    public virtual class WSI_BookingApiRequest extends WSI_ApiRequest {

        private Booking booking;
        private Subscription subscr;

        public void init(WSI_CTRL.APIResponse apiResp, Booking booking) {
            this.booking = booking;
            init(apiResp);
        }

        public override void init(WSI_CTRL.APIResponse apiResp) {
            super.init(apiResp);
        }

        public override void setContextRecords() {

            try {
                //Contextrecord is the master rev (Subscription) that needs updating.
                //First try to find master Rev based on UniqueLocalBookingId and UniqueLocalPlatformId on Account.
                String uniqueLocalBookingId = booking.bookingId;
                String uniqueLocalAccountId = booking.memberId + '_' + booking.accountId;

                String whereClause = 'UniqueLocalBookingId__c = \'' + uniqueLocalBookingId + '\' AND Opportunity__r.Account.UniquePlatformId__c = \''+uniqueLocalAccountId+'\'';

                List<sObject> revs = GW_sObject.queryRecords('Rev__c', whereClause);

                whereClause = 'UniquePlatformId__c = \'' + uniqueLocalAccountId + '\'';

                List<sObject> accs = GW_sObject.queryRecords('Account', whereClause);

                if (accs.size() == 0 ) throw new UTIL.customException('Account with unique local platform id unknown: ' + uniqueLocalAccountId);

                booking.acc = (Account) accs.get(0);

                parseRequestJSON();
                booking.digestRequest(requestJSON);

                //When it is an existing subscription the context is the master revenue item.
                if (revs.size() > 0) {
                    booking.masterRevenueItem = (Rev__c) revs.get(0);
                    subscr = new Subscription(booking.masterRevenueItem.Id);
                    if (booking.startDate != null) {
                        contextRecord = subscr.getRevenueItemByFromDate(booking.startDate);
                        if (contextRecord == null){
                            contextRecord = subscr.createNewAdjustment();
                        }
                    }
                    else{
                        contextRecord = booking.masterRevenueItem;
                    }
                    Id oppId = (Id) contextRecord.get('Opportunity__c');
                    booking.opp = (Opportunity) GW_sObject.queryRecord('Opportunity', oppId);
                }
                else {
                    contextRecord = null;
                }
            }
            catch(UTIL.CustomException customE) {
                apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Error while retrieving context:' + customE.getMessage());
                throw new WSI_CTRL.APIException();
            }
            catch (Exception e) {
                contextRecordNotFound('Unexpected error : ' + booking + e.getMessage() + e.getStackTraceString());
            }
        }

        public override void prepareResponse() {
            Map<String,Object> responseMap = new Map<String,Object>(); //All updated values

            responseMap.put('localOpportunityId', booking.opp.LocalPlatformId__c);
            responseMap.put('localOpportunityId', booking.opp.Id);

            List<Object> adjustments = new List<Object>();
            Set<Id> revProductIds = new Set<Id>();
            Set<Id> revPricebookIds = new Set<Id>();
            Map<Id, Product2> productMap;
            Map<Id, Pricebook2> pricebookMap;

            if (contextRecord != null && booking != null && booking.masterRevenueItem != null ){
                apiResp.linklog('Rev__c', booking.masterRevenueItem.Id);
            }

            apiResp.setResponse(responseMap);
        }

        private void validatePricebookEntry() {

            if ( String.isEmpty(booking.pricebookName) ) throw new UTIL.CustomException('No pricebook specified to find the correct listprice for product with id \'' + booking.localProductId + '\'');

            //Check if pricebook exists
            List<PriceBook2> pbs = (List<PriceBook2>) GW_sObject.queryRecords('PriceBook2', 'Name =\'' + booking.pricebookName + '\'');
            if (pbs.size() == 0 ) throw new UTIL.CustomException('Pricebook with name \'' + booking.pricebookName + '\' couldn\'t be found.');
            booking.priceBookEntryMap = new Map<String, PriceBookEntry>();

            for(Map<String, String> record : booking.lineItems){
                //Check if the local product is supplied and exists
                List<Product2> products = (List<Product2>) GW_sObject.queryRecords('Product2', 'Tract_SKU__c =\'' + record.get('productId') + '\'');
                if (products.size() == 0 ) throw new UTIL.CustomException('Product with localProductId \'' + booking.localProductId + '\' couldn\'t be found.');

                for (Product2 product2Record: products) {

                    //Check if the pricebook entry exists
                    List<PriceBookEntry> bpes = (List<PriceBookEntry>) GW_sObject.queryRecords('PriceBookEntry', 'Product2Id =\'' + product2Record.Id + '\' AND PriceBook2Id = \'' + pbs.get(0).Id + '\'');
                    if (bpes.size() != 0 ){
                        booking.pricebookEntryMap.put(record.get('localId'), bpes.get(0));
                        booking.pricebookEntry = bpes.get(0);
                    }

                }
                if (booking.opp == null) throw new UTIL.CustomException('Opportunity not set...');

            }
            booking.opp.PriceBook2Id = booking.priceBookEntry.priceBook2Id;
            booking.opp.CurrencyIsoCode = booking.priceBookEntry.CurrencyIsoCode;
        }
    }
    //END WSI_BookingApiRequest

    public class BookingInsert extends WSI_BookingApiRequest {

        public override void prepareUpdate() {}

        public override void validateData() {

            try {
                //Check if the required fields are provided in request.
                if (   String.isEmpty(booking.pricebookName)
                    || String.isEmpty(booking.localId)
                    || String.isEmpty(booking.memberUnitId)
                ) {
                        throw new UTIL.CustomException('One of the required fields is missing (pricebookName, localProductId, startDate) ' + booking.localId + '  ' +  booking.pricebookName + '  ' + booking.memberUnitId);
                }
                //Rev should not already exist for a booking insert.
                if (booking.masterRevenueItem != null) {
                    throw new WSI_CTRL.APIException('There is already a booking known with bookingId: ' + booking.bookingId);
                }
                booking.initOpportunity();
                validatePricebookEntry();

                booking.type = 'Master';

            }
            catch(UTIL.CustomException customE) {
                apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Data validation error: ' + customE.getMessage());
                throw new WSI_CTRL.APIException();
            }
            catch(WSI_CTRL.APIException apiException) {
                apiResp.addApiError(UTIL_WSC.HTTP_CONFLICT,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_CONFLICT), 'Data validation error: ' + apiException.getMessage());
                throw new WSI_CTRL.APIException();
            }
            catch(Exception e){
                if (e.getMessage().containsIgnoreCase('currently being modified by another user')) {
                    apiResp.addApiError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'Data validation error: Record is currently unavailable as it is locked by another process, please try again.');
                    throw new WSI_CTRL.APIException();
                }
                else {
                    apiResp.addApiError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'Unexpected error during data validation:' + e.getMessage() + e.getStackTraceString());
                }
                throw new WSI_CTRL.APIException();
            }
        }

        public override void executeDML() {
            //Set up the Subscription based on Parameters
            //Use subscription class.

            //Execute the creation of an opportunity and linking of the new rev as one transaction.
            Long start = Datetime.now().getTime();      
            Long timeDifference = 0;        
            timeDifference =  Datetime.now().getTime() - timeDifference - start;        
            UTIL.log('TIMECHECK Begin ExecuteDML: ' + timeDifference);

            try {

                if (String.isEmpty(booking.opp.UniquePlatformId__c)) {
                    booking.opp.UniquePlatformId__c = booking.memberUnitId + '_' + booking.bookingId;
                }

                try {

                    if (booking.opp.Id == null) {
                        upsert booking.opp UniquePlatformId__c;
                    }
                }
                catch(DmlException e) {

                    String eMsg = ''+e.getMessage();
                    if (!eMsg.containsIgnoreCase('DUPLICATE') && !eMsg.containsIgnoreCase('UNABLE_TO_LOCK_ROW')){
                        throw e;
                    }
                }

                if (booking.opp.Id == null) {
                    List<sObject> opps = GW_sObject.queryRecords('Opportunity', 'UniquePlatformId__c = \'' + booking.opp.UniquePlatformId__c + '\'');

                    if (opps.size() > 0) {
                        //Found it?
                       booking.opp = (Opportunity) opps.get(0);
                    }
                }

                booking.olis = new List<OpportunityLineItem>();
                
                OpportunityLineItem oliObject = (OpportunityLineItem) contextRecord;
                for( Map<String, String> recordMap : booking.lineItems ) {


                    String[] startDateList = (recordMap.get('startDate')).split('-');
                    String[] endDateList = (recordMap.get('endDate')).split('-');
                    
                    Date stateDate = System.Date.newInstance( Integer.valueOf(startDateList[0]), Integer.valueOf(startDateList[1]), Integer.valueOf(startDateList[2]));
                    Date endDate = System.Date.newInstance( Integer.valueOf(endDateList [0]), Integer.valueOf(endDateList [1]), Integer.valueOf(endDateList [2]));
                    booking.olis.add(
                        new OpportunityLineItem(
                            OpportunityId = booking.opp.Id,
                            Billing_Category__c = 'CPM',
                            PricebookEntryId = booking.priceBookEntryMap.get( recordMap.get('localId') ).Id,
                            from_Date__c = stateDate,
                            until_Date__c= endDate,
                            Quantity = Integer.valueOf( recordMap.get('quantity') ),
                            UnitPrice = Decimal.valueOf( recordMap.get('salesPrice') ),
                            UniqueLocalBookingId__c = recordMap.get('localId'),
                            ParentOpportunityLocaLId__c  = recordMap.get('parentLineItemId')
                        )
                     );

                }

                UTIL.log('OpportunityLineItems before insert ' + booking.olis);
                
                insert booking.olis;
                
                //unit price was not updated on insert but on update, this is a workaround 
                update booking.olis;
                
                matchAddOnsParentOpportunityLineItemId(booking.olis);
                
                if(booking.opp.ContractStatus__c == 'Signed') {
                    doTractInboundCall(booking.opp.Id);
                }
                
                UTIL.log('OpportunityLineItems after insert ' + booking.olis);
                timeDifference =  Datetime.now().getTime() - timeDifference - start;        
                UTIL.log('TIMECHECK after opportunity upsert: ' + timeDifference);

            }
            catch (Exception e) {
                System.debug('Exception type caught: ' + e.getTypeName());    
                System.debug('Message: ' + e.getMessage());    
                System.debug('Cause: ' + e.getCause());    // returns null
                System.debug('Line number: ' + e.getLineNumber());    
                System.debug('Stack trace: ' + e.getStackTraceString());    
                if (e.getMessage().containsIgnoreCase('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                    apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST), 'Data validation error: Account is closed for business.');
                    throw new WSI_CTRL.APIException();
                }
                else if (e.getMessage().containsIgnoreCase('DUPLICATE_VALUE')) {
                    apiResp.addApiError(UTIL_WSC.HTTP_CONFLICT,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_CONFLICT), 'Data validation error: There is already a booking known with bookingId: ' + booking.bookingId);
                    throw new WSI_CTRL.APIException();
                }
                else{
                    throw new WSI_CTRL.APIException(e.getMessage());
                }
            }
        }
    }
    

    public class BookingUpdate extends WSI_BookingApiRequest {

        public override void validateData() {

            try {

                if ( String.isEmpty(booking.type) ) {
                        throw new UTIL.CustomException('One of the required fields is missing (type)');
                }

                if ('MASTER'.equals(booking.type.toUpperCase())){
                    booking.type = 'Master';
                    validateMasterUpdateData();
                }
                else if ('ADJUSTED'.equals(booking.type.toUpperCase())) {
                    booking.type = 'Adjusted';
                    //validateAdjustmentData();
                }
                else {
                    throw new UTIL.customException('type \'' + booking.type + '\' not allowed. Please use \'Master\' or \'Adjusted\'');
                }

            }
            catch(UTIL.CustomException customE) {
                apiResp.addApiError(UTIL_WSC.HTTP_BADREQUEST,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_BADREQUEST),'Data validation error: ' + customE.getMessage());
                throw new WSI_CTRL.APIException();
            }
            catch(Exception e){
                apiResp.addApiError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'Unexpected error during data validation: ' + e.getMessage() + e.getStackTraceString());
                throw new WSI_CTRL.APIException();
            }

        }

        private void validateMasterUpdateData() {

            //Check if the required fields are provided in request
            if (!String.isEmpty(booking.localOpportunityId)){

                booking.initOpportunity();
                validatePricebookEntry();
            }

        }

        private void validateAdjustmentData() {

            //Check if the required fields are provided in request.
            if (booking.masterRevenueItem == null) {
                throw new UTIL.CustomException('Subscription with bookingid \''+booking.bookingId+'\' unknown.: ');
            }
            if (   String.isEmpty(booking.startDateString)
                || String.isEmpty(booking.type)
            ) {
                throw new UTIL.CustomException('One of the required fields is missing (startDate, type)');
            }
            if (!String.isEmpty(booking.terminationReason) || booking.terminationDate != null) {
                throw new UTIL.CustomException('You cannot terminate a subscription for type is \'Adjusted\'');
            }
            if (!String.isEmpty(booking.localProductId)){
                booking.initOpportunity();
                validatePricebookEntry();
            }

            if ( booking.startDate != null ) {
                //Starting an adjustment is only possible with date bigger than: From_Date__c and lastInvoicedDate__c and smaller than SubscriptionEndDate__c
                if ( !(booking.startDate >= booking.masterRevenueItem.From_Date__c  && (booking.masterRevenueItem.LastBilledDate__c == null || booking.startDate >= booking.masterRevenueItem.LastBilledDate__c) && booking.startDate <= booking.masterRevenueItem.SubscriptionEndDate__c) ) {
                    throw new UTIL.CustomException('It\'s not possible to do an adjustment starting ' + booking.startDate + ' the subscription starts at ' + booking.masterRevenueItem.From_Date__c
                    + ', is invoiced until ' + booking.masterRevenueItem.LastBilledDate__c + ' and ends on ' + booking.masterRevenueItem.SubscriptionEndDate__c);
                }
            }
        }

        public override void prepareUpdate() {
            //Perform an edit or a cancelation
        }

        public override void executeDML() {
            try{
                UTIL.log('Update booking ' + booking.opp);
                update booking.opp;
            } catch (Exception e) {

                System.debug('Exception type caught: ' + e.getTypeName());    
                System.debug('Message: ' + e.getMessage());    
                System.debug('Cause: ' + e.getCause());    // returns null
                System.debug('Line number: ' + e.getLineNumber());    
                System.debug('Stack trace: ' + e.getStackTraceString());  
            }

            try{

                Map<String, OpportunityLineItem> oppLineItemRecordMap = new Map<String, OpportunityLineItem>();
                for (OpportunityLineItem record:
                    [select Id, Name, 
                        (select Id, Name, PricebookEntryId, Billing_Category__c, BillingCalc__c, FC_Quantity__c, UPCF__c,  ListPrice__c, SalesPriceNet__c, CustomListPrice__c, from_Date__c, until_Date__c, Quantity,
                            UnitPrice,
                            UniqueLocalBookingId__c
                        from OpportunityLineItems ) 
                    from Opportunity
                    where Id =: booking.opp.Id ].OpportunityLineItems ) {

                    oppLineItemRecordMap.put(record.UniqueLocalBookingId__c, record);

                }

                UTIL.log('here now f ' + oppLineItemRecordMap);

                booking.olis = new List<OpportunityLineItem>();
                for( Map<String, String> recordMap : booking.lineItems ) {


                    OpportunityLineItem  oppLineItem = oppLineItemRecordMap.get(recordMap.get('localId'));
                    String[] startDateList = (recordMap.get('startDate')).split('-');
                    String[] endDateList = (recordMap.get('endDate')).split('-');
                    
                    Date stateDate = System.Date.newInstance( Integer.valueOf(startDateList[0]), Integer.valueOf(startDateList[1]), Integer.valueOf(startDateList[2]));
                    Date endDate = System.Date.newInstance( Integer.valueOf(endDateList [0]), Integer.valueOf(endDateList [1]), Integer.valueOf(endDateList [2]));

                    if ( oppLineItem == null ){
                        booking.olis.add(
                            new OpportunityLineItem(
                                OpportunityId = booking.opp.Id,
                                //PricebookEntryId = oliObject.PricebookEntryId,
                                PricebookEntryId = booking.priceBookEntryMap.get( recordMap.get('localId') ).Id,
                                Billing_Category__c = 'CPM',
                                from_Date__c = stateDate,
                                until_Date__c= endDate,
                                Quantity = Integer.valueOf( recordMap.get('quantity') ),
                                UnitPrice = Decimal.valueOf( recordMap.get('salesPrice') ),
                                UniqueLocalBookingId__c = recordMap.get('localId'),
                                ParentOpportunityLocaLId__c  = recordMap.get('parentLineItemId')
                            )
                         );
                    } else {

                        oppLineItem.Billing_Category__c = 'CPM';
                        oppLineItem.from_Date__c = stateDate;
                        oppLineItem.until_Date__c = endDate;
                        oppLineItem.Quantity = Integer.valueOf( recordMap.get('quantity') );
                        oppLineItem.UnitPrice = Decimal.valueOf( recordMap.get('salesPrice') );
                        oppLineItem.UniqueLocalBookingId__c = recordMap.get('localId');
                        oppLineItem.ParentOpportunityLocaLId__c  = recordMap.get('parentLineItemId');
                        
                        booking.olis.add(oppLineItem);
                    }

                }
                upsert booking.olis;
                
                if(booking.opp.ContractStatus__c == 'Signed') {
                    doTractInboundCall(booking.opp.Id);
                }
                
            }
            catch (Exception e) {
                apiResp.addApiError(UTIL_WSC.HTTP_SERVERERROR,UTIL_WSC.statusMsg.get(UTIL_WSC.HTTP_SERVERERROR),'Unexpected error while commiting to the database: ' + e.getMessage());
                throw new WSI_CTRL.APIException();
            }
        }

    }
    
    
    /**
     * Fetch ParentOpportunityLineItemId By UniqueLocalBookingId
     */
    private static void matchAddOnsParentOpportunityLineItemId (List<OpportunityLineItem> lstParentItems) {
        List<String> parentIds = new List<String>();
        List<String> localParentIds = new List<String>();
        for (OpportunityLineItem oli : lstParentItems) {
            if (oli.UniqueLocalBookingId__c != null) localParentIds.add(oli.UniqueLocalBookingId__c);
            parentIds.add(oli.Id);
        }
        String listIds = '(\'' + String.join(parentIds, '\',\'') + '\')';
        String localListIds = '(\'' + String.join(localParentIds, '\',\'') + '\')';
        String whereAddons = 'ParentOpportunityLineItemId__c IN ' + listIds + ' OR ParentOpportunityLocaLId__c IN ' + localListIds;
        List<OpportunityLineItem> lstAddonsItems = (List<OpportunityLineItem>) GW_sObject.queryRecords('OpportunityLineItem', whereAddons );
        
        Map<String, OpportunityLineItem[]> mAddOnsByParentLocalIds = new Map<String, OpportunityLineItem[]>();
        List<String> parentLocalIds = new List<String>();
        for (OpportunityLineItem addonItem : lstAddonsItems) {
            if (addonItem.ParentOpportunityLocaLId__c != null) {
                if (!mAddOnsByParentLocalIds.containsKey(addonItem.ParentOpportunityLocaLId__c)) {
                    mAddOnsByParentLocalIds.put(addonItem.ParentOpportunityLocaLId__c, new List<OpportunityLineItem>());
                    parentLocalIds.add(addonItem.ParentOpportunityLocaLId__c);
                }
                mAddOnsByParentLocalIds.get(addonItem.ParentOpportunityLocaLId__c).add(addonItem);
            }
        }
        listIds = '(\'' + String.join(parentLocalIds, '\',\'') + '\')';
        String whereParents = 'UniqueLocalBookingId__c IN ' + listIds;
        List<OpportunityLineItem> lstParents = (List<OpportunityLineItem>) GW_sObject.queryRecords('OpportunityLineItem', whereParents );
        Map<String, OpportunityLineItem> fetchAddons = new Map<String, OpportunityLineItem>();
        for (OpportunityLineItem parentLine : lstParents) {
            if (!mAddOnsByParentLocalIds.containsKey(parentLine.UniqueLocalBookingId__c)) continue;
            for (OpportunityLineItem addOns : mAddOnsByParentLocalIds.get(parentLine.UniqueLocalBookingId__c)) {
                addOns.ParentOpportunityLineItemId__c = parentLine.Id;
                fetchAddons.put(addOns.Id, addOns);
            }
        }
        update fetchAddons.values();
    }

    @Future(callout=true)
    private static void doTractInboundCall(String Id){
        WSC_Tract.checkForOrderTractProcessingselfService(Id);
    }
}