/**
 * Batch process of Booking
 * Request to create Order/LineItem in DFP
 * @CreatedDate: 29-01-2013
 */ 

global class BatchDARTBookingProcess extends BatchAvailabilityForecastProcess implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallOuts{
    
    
    // Mapping dartVersion and order in a network
    Map<String, DARTObject.IDARTObjectOrder> mapNetworkOrder;
    
    // Store Log message for all requests even error or success.
    public List<DARTLogger.LogMessage> lstLogMsg = new List<DARTLogger.LogMessage>();
    // Store all ads/lineItems request success
    List<DARTObject.IDARTObjectAds> lstAllAdsSuccess = new List<DARTObject.IDARTObjectAds>();
    // Store all ads/lineItems request failure
    List<DARTObject.IDARTObjectAds> lstAllAdsError = new List<DARTObject.IDARTObjectAds>();
    // Store all orders request success
    List<DARTObject.IDARTObjectOrder> lstAllOrderSuccess = new List<DARTObject.IDARTObjectOrder>();
    // Store all Orders request failure
    List<DARTObject.IDARTObjectOrder> lstAllOrderError = new List<DARTObject.IDARTObjectOrder>();
    // Store list Advertiser/Company (DART)
    List<DARTObject.IDARTObjectAdvertiser> lstDartAdvertiser = new List<DARTObject.IDARTObjectAdvertiser>();
    // Message error when upadate opporturnity failed.
    String msgFailureUpdateOpp='';
    // Message error when update opportunityLineItem failed.
    String msgFailureUpdateOppItem='';
    // Booking emailTemplate
    public final String TEMPLETE_NAME = 'BookingEmailTemplate';
    // Store Order request failure in different network
    Map<String, String> mapOrderErr;
    // Store list Advertiser/Company(SF) 
    List<Advertiser__c> listAdvertiser;
    // public Map<String, String> mapAdvertiser;
    Map<String, Advertiser__c> mapAdvertiser;
    
    List<OpportunityLineItem> listItems;
    
    /**
     * Controller1: No/All LineItems selected 
     */
    public BatchDARTBookingProcess(String oppId)
    {  
        super(oppId);
    }
    
    /**
     * Controller2: Some of LineItems selected 
     */
    public BatchDARTBookingProcess(String oppId, Set<String> lineItemIds)
    {
        super(oppId, lineItemIds);
    }
    /**
     * @return default WHERE for booking process(Product's recordType=DART6)
     */
    public override String getDefaultWhere()
    {
        return  ' WHERE OpportunityId=%1 AND PricebookEntry.Product2.RecordType.Name IN (%2)';
    }
    
    /**
     * Start batch 
     */ 
    global override Database.QueryLocator start(Database.BatchableContext BC)
    {
        mapAdvertiser = new Map<String, Advertiser__c>();
        mapOrderErr = new Map<String, String>();
        mapNetworkOrder = new Map<String, DARTObject.DARTOrder>();
        listItems = new List<OpportunityLineItem>();
        for(OpportunityLineItem item: [select id,Adserver_ID_Order_ID__c, Adserver_Adv_Advertiser_ID__c ,PriceBookEntry.Product2.Site__r.Country__c,
                                        PricebookEntry.Product2.RecordType.Name, Opportunity.CurrencyIsoCode From OpportunityLineItem where opportunityId =: oppId])
        {
            if(item.Adserver_ID_Order_ID__c != null && item.Adserver_Adv_Advertiser_ID__c != null)
            {
                DARTObject.DARTOrder ord = new DARTObject.DARTOrder(item.Adserver_ID_Order_ID__c, item.Adserver_Adv_Advertiser_ID__c);
                mapNetworkOrder.put(item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c,ord);
            }
            
        }

        opp = [Select id, Name, P_O_Number__c, CampaignStart__c, CampaignEnd__c, Owner.Name, Owner.id, Owner.Email
                , Agency__c, AccountId, Owner.Dart_User_Name__c, IOnumber__c From Opportunity Where id =: oppId];
            
        
        // Find Advertiser
        listAdvertiser = DARTUtil.getAdvertiser(opp.AccountId, opp.Agency__c);
        
        for(Advertiser__c adv : listAdvertiser)
        {
            if(adv.Dart6_Advertiser_Id__c != null){
                mapAdvertiser.put(DARTUtil.DART6+'_'+adv.AdServer_Login_Name__c, adv);  
            }
        }         
                
        return Database.getQueryLocator(soqlItems);
    }
    
    /**
     * Execute batch 
     */ 
    global override void execute(Database.BatchableContext BC, List<sObject> scope)
    {   
        String dartMethod;
        for(Sobject sobj : scope)
        {
            OpportunityLineItem oppItem;
            String dartVerCountry;
            BookingController bookingCon;

            try{ 
                oppItem = (OpportunityLineItem)sobj; 
                listItems.add(oppItem);
                bookingCon = new BookingController(opp, oppItem); 
                dartVerCountry = oppItem.PricebookEntry.Product2.RecordType.Name+'_'+oppItem.PriceBookEntry.Product2.Site__r.Country__c;
            }
            catch(Exception ex){if(mapOrderErr.get(dartVerCountry) == null){
                    DARTObject.IDARTObjectOrder orderErr = new DARTObject.DARTOrder(opp);
                    orderErr.setDartErrMsg(ex.getMessage());
                    lstAllOrderError.add(orderErr);
                    mapOrderErr.put(dartVerCountry, 'Error');
                }
                break;
            }
            
            // Advertiser not null 
            //  => update Advertiser depend on product recordType(DART6)
            //  => If Product recordType=DART6 && Advertiser__c.Dart6_Advertiser_Id__c==null
            //     -> Request to create Advertiser in DFP 6
            //     -> Update field in SF
            // Advertiser = null
            //  => Request to create new Advertiser depend on product recordType
            //  => Create new Advertiser in SF
            
            String dartType = oppItem.PricebookEntry.Product2.RecordType.Name;
                    if(mapAdvertiser.get(dartVerCountry) == null)
                    {
                        try{
                            
                            // If there is no Advertiser found in SF => Search in DFP
                            bookingCon.processSearchAdvertiser();
                            List<DARTObject.IDARTObjectAdvertiser> lstExistingAdvs = bookingCon.getListAdvertiserExist();
                            dartMethod = bookingCon.getInvokedMethod();
                            // Log messages for searching Advertiser in DFP
                            DARTLogger.LogMessage logMsgGetAdv = new DARTLogger.LogMessage(
                                                        oppItem.Id ,DARTLogger.OPPERATION_SEARCH_ADVERTISER,
                                                        dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                                        DARTLogger.TYPE_SUCCESS, '', '');
                                
                            lstLogMsg.add(logMsgGetAdv);
                            
                            if(lstExistingAdvs.isEmpty())
                            {
                                bookingCon.requestCreateAdvertiser();
                                lstDartAdvertiser = bookingCon.getListAdvertiser();
                                dartMethod = bookingCon.getInvokedMethod();
                                // Log messages for requesting to create Advertiser in DFP 
                                DARTLogger.LogMessage logMsgCreateAdv = new DARTLogger.LogMessage(
                                                            oppItem.Id , DARTLogger.OPPERATION_CREATE_NEW_ADVERTISER,
                                                            dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                                            DARTLogger.TYPE_SUCCESS, '', '');
                                lstLogMsg.add(logMsgCreateAdv);
                            }else
                            {
                                lstDartAdvertiser.addAll(lstExistingAdvs);
                            }
                            
                            Advertiser__c adv = new Advertiser__c();
                            
                            if(dartType.equals(DARTUtil.DART6))
                                adv.Dart6_Advertiser_Id__c = lstDartAdvertiser.get(0).getDartId();
                            
                            mapAdvertiser.put(dartVerCountry, adv);
                            
                            System.debug('=================>> mapAdvertiser:' + mapAdvertiser);
                            
                        }catch(Exception ex)
                        {
                            DARTObject.IDARTObjectOrder orderErr = new DARTObject.DARTOrder(opp);
                            orderErr.setDartErrMsg(ex.getMessage());
                            lstAllOrderError.add(orderErr);
                            DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage('' ,
                            DARTLogger.OPPERATION_SUBMIT_COMPANY_ADVERTISER,''
                            ,oppItem.PricebookEntry.Product2.RecordType.Name,ex);
                            lstLogMsg.add(logMsg);
                            break;
                        }
                    } 
                if(mapNetworkOrder.get(dartVerCountry) == null) //In each network one order is created
                {
                    List<DARTObject.IDARTObjectOrder> listOrder = new List<DARTObject.IDARTObjectOrder>();
                    try
                        {
                            // Get existing order by opp's name
                            List<DARTObject.IDARTObjectOrder> lstExistOrder = bookingCon.getExistOrder();
                            if(!lstExistOrder.isEmpty())
                            {
                                listOrder.addAll(lstExistOrder);
                                lstAllOrderSuccess.addAll(lstExistOrder);
                            }else{
                                // Order Request
                                UTIL.log('bookingCon:' + bookingCon);
                                UTIL.log('mapAdvertiser:' + mapAdvertiser);
                                bookingCon.processAndSendOrder(mapAdvertiser); 
                                dartMethod = bookingCon.getInvokedMethod(); 
                                listOrder = bookingCon.getListOrder();
                                lstAllOrderSuccess.addAll(listOrder);
                            }
                            // Log messages when Order request success 
                            DARTLogger.LogMessage logMsgOrder = new DARTLogger.LogMessage(
                                                    opp.Id ,DARTLogger.OPPERATION_SUBMIT_ORDER,
                                                    dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                                    DARTLogger.TYPE_SUCCESS, '', '');
                            
                            lstLogMsg.add(logMsgOrder);
                            System.debug('------------>>dartVerCountry:' + dartVerCountry);
                            System.debug('------------>>listOrder:' + listOrder);
                            mapNetworkOrder.put(dartVerCountry, listOrder.get(0));
                         
                        }// Request Order Error
                        catch(Exception ex){
                            if(mapOrderErr.get(dartVerCountry) == null){
                                DARTObject.IDARTObjectOrder orderErr = new DARTObject.DARTOrder(opp);
                                orderErr.setDartErrMsg(ex.getMessage());
                                lstAllOrderError.add(orderErr);
                                mapOrderErr.put(dartVerCountry, 'Error');
                            }
                            DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ORDER,'',oppItem.PricebookEntry.Product2.RecordType.Name,ex);
                            lstLogMsg.add(logMsg); 
                            break;
                        }
                        
                        if(listOrder != null)
                        {
                            try
                            {
                                // Ads/LineItem Request
                                bookingCon.processAndSendLineItem(listOrder.get(0), mapAdvertiser);
                                dartMethod = bookingCon.getInvokedMethod();
                                //mapNetworkOrder.put(dartVerCountry, listOrder.get(0)); 
                                lstAllAdsSuccess.addAll(bookingCon.getListAds()); 
                                
                                // Log messages when Ads request success 
                                DARTLogger.LogMessage logMsgAds = new DARTLogger.LogMessage(
                                                            oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ADS,
                                                            dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                                            DARTLogger.TYPE_SUCCESS, '', '');
                                    
                                lstLogMsg.add(logMsgAds);
                            }
                            catch(Exception ex){
                                DARTObject.DARTAds adsErr = new DARTObject.DARTAds(oppItem);
                                adsErr.setDartErrMsg(ex.getMessage());
                                lstAllAdsError.add(adsErr); 
                                //mapNetworkOrder.put(dartVerCountry, listOrder.get(0));
                                DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ADS,'',oppItem.PricebookEntry.Product2.RecordType.Name,ex);
                                lstLogMsg.add(logMsg);
                                }
                            }
                        } 
                    else 
                    {
                        try
                        {
                            bookingCon.processAndSendLineItem(mapNetworkOrder.get(dartVerCountry), mapAdvertiser); 
                            dartMethod = bookingCon.getInvokedMethod();
                            lstAllAdsSuccess.addAll(bookingCon.getListAds());
                            // Log messages when request Ads success 
                            DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(
                                                    oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ADS,
                                                    dartMethod,oppItem.PricebookEntry.Product2.RecordType.Name,
                                                    DARTLogger.TYPE_SUCCESS, '', '');
                        
                            lstLogMsg.add(logMsg);
                        }
                        catch(Exception ex){
                            DARTObject.DARTAds adsErr = new DARTObject.DARTAds(oppItem);
                            adsErr.setDartErrMsg(ex.getMessage());
                            lstAllAdsError.add(adsErr);
                            DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage(oppItem.Id ,DARTLogger.OPPERATION_SUBMIT_ADS,'',oppItem.PricebookEntry.Product2.RecordType.Name,ex);
                            lstLogMsg.add(logMsg);
                        }
                    }   
                }   
    }
    
    /** 
     * Finish batch:
     * Send Email to opp's owner that including booking informations
     * Update opportunity: Booking_in_Processing__c = false
     * Update OpporutunityLineItem: Adserver_ID_Order_ID__c, Adserver_Adv_Advertiser_ID__c & Ad_Id__c  
     * Log the success/error message to Note of opportunity
     */
    global override void finish(Database.BatchableContext BC)
    {
        List<DARTObject.IDARTObjectOrder> lstAllOrder = new List<DARTObject.IDARTObjectOrder>();
        lstAllOrder.addAll(lstAllOrderSuccess);
        lstAllOrder.addAll(lstAllOrderError);
        
        List<DARTObject.IDARTObjectAds> lstAllAds = new List<DARTObject.IDARTObjectAds>();
        lstAllAds.addAll(lstAllAdsError);
        lstAllAds.addAll(lstAllAdsSuccess);
        
        
        try{
            
            Map<String, Advertiser__c> mapAdverUpsert = new Map<String, Advertiser__c>();
            String strUpdInsAdv='';
            for(String str:mapAdvertiser.keySet())
            {
                
                for(OpportunityLineItem item: listItems)
                {
                    String dartVerNetwork=item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c;

                    if(str.equals(dartVerNetwork))
                    {
                        Advertiser__c advToUpsert;
                        Advertiser__c adv = mapAdvertiser.get(str);
                        if(adv.Id==null)
                        {
                            strUpdInsAdv= DARTLogger.OPPERATION_CREATE_NEW_ADVERTISER;
                            advToUpsert = new Advertiser__c();
                            advToUpsert.Account__c=opp.AccountId;
                            advToUpsert.Agency__c=opp.Agency__c;
                            advToUpsert.AdServer_Login_Name__c = item.PriceBookEntry.Product2.Site__r.Country__c;
                        }else{
                            strUpdInsAdv=DARTLogger.OPPERATION_UPDATE_ADVERTISER;
                            advToUpsert = new Advertiser__c(id=adv.Id);
                        }
                        
                        if((item.PricebookEntry.Product2.RecordType.Name).equals(DARTUtil.DART6))
                            advToUpsert.Dart6_Advertiser_Id__c = adv.Dart6_Advertiser_Id__c;
                        
                        mapAdverUpsert.put(str,advToUpsert);
                    }
                }
                
            }
            upsert mapAdverUpsert.values();
            
            // Add log messages
            for(Advertiser__c adv:mapAdverUpsert.values()){
                
                DARTLogger.LogMessage logMsgUpInAdv = new DARTLogger.LogMessage(
                                    adv.id ,'Create/Update Advertiser',
                                    '','',
                                    DARTLogger.TYPE_SUCCESS, '', '');
                             
                            lstLogMsg.add(logMsgUpInAdv);
            }
            
        }catch(Exception ex){DARTLogger.LogMessage logMsg = new DARTLogger.LogMessage('' ,'Update/Insert Advertiser','','',ex);lstLogMsg.add(logMsg);}
        
        if(!mapNetworkOrder.isEmpty())
        {
            List<OpportunityLineItem> lstOppItemToupdateFldOrderID = new List<OpportunityLineItem>();
            for(String ordKey : mapNetworkOrder.keySet())
            {
                //OpportunityLineItem itemupdate;
                for(OpportunityLineItem item: listItems)
                {
                    String networkType = item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c;
                    if(networkType.equals(ordKey))
                    {
                        DARTObject.IDARTObjectOrder ord = mapNetworkOrder.get(networkType);
                        item.Adserver_ID_Order_ID__c = (ord==null?'':ord.getDartId());
                        item.Adserver_Adv_Advertiser_ID__c = (ord==null?'':ord.getOrderAvertiserId());  
                        lstOppItemToupdateFldOrderID.add(item);
                    }   
                }
            }
            update lstOppItemToupdateFldOrderID;
        }
        
        
        if(!lstAllAds.isEmpty())
        {
            // Update opportunityLineItem
            List<OpportunityLineItem> listOppItemToUpdate = new List<OpportunityLineItem>();
            for(DARTObject.IDARTObjectAds ads : lstAllAds)
            {
                OpportunityLineItem oppItem = new OpportunityLineItem(Id=ads.getOppItemID());
                DARTObject.IDARTObjectOrder ord = ads.getOrder();
                if(ads.getDartId() != null)
                {
                    //oppItem.Adserver_ID_Order_ID__c = (ord==null?'':ord.getDartId());
                    //if(ord!=null && ord.getOrderAvertiserId()!=null)
                    //{
                    //oppItem.Adserver_Adv_Advertiser_ID__c = (ord==null?'':ord.getOrderAvertiserId()); 
                    //}
                    oppItem.Ad_Id__c = ads.getDartId();
                    listOppItemToUpdate.add(oppItem); 
                }
            }
             
            DARTLogger.LogMessage logMsgUpdateoppItem;
            try
            {
                Database.SaveResult[] results = Database.Update(listOppItemToUpdate, false);
                // Log messages when update oppItem successfully  
                logMsgUpdateoppItem = new DARTLogger.LogMessage(
                                        opp.Id ,DARTLogger.OPPERATION_UPDATE_OPPLINEITEM,
                                        '','',
                                        DARTLogger.TYPE_SUCCESS, '', '');
                
                lstLogMsg.add(logMsgUpdateoppItem);
                
            }
            // Log messages when failure to update oppItem  
            catch(Exception ex){
                logMsgUpdateoppItem = new DARTLogger.LogMessage(opp.Id ,DARTLogger.OPPERATION_UPDATE_OPPLINEITEM,'','',DARTLogger.TYPE_ERROR, ex.getMessage(), '');
                lstLogMsg.add(logMsgUpdateoppItem); 
                msgFailureUpdateOppItem='Error: failure to update OpportunityLineItem <br/>' +ex.getTypeName() + ' - ' + ex.getCause() + ': ' + ex.getMessage();
            }   
        }
        
        // Update oppotunity
        DARTLogger.LogMessage logMsgUpdateopp;
        try
        {
            Opportunity oppty = new Opportunity(Id=oppId);
            oppty.Booking_in_Processing__c = false;
            update oppty;
            // Log messages when update opp successfully  
            logMsgUpdateopp = new DARTLogger.LogMessage(
                                    opp.Id ,DARTLogger.OPPERATION_UPDATE_OPP,
                                    '','',
                                    DARTLogger.TYPE_SUCCESS, '', '');
            
            lstLogMsg.add(logMsgUpdateopp);
        }
        // Log messages when exception occur(update failed) 
        catch(Exception ex){logMsgUpdateopp = new DARTLogger.LogMessage(opp.Id ,DARTLogger.OPPERATION_UPDATE_OPP,'','',DARTLogger.TYPE_ERROR, ex.getMessage(), '');lstLogMsg.add(logMsgUpdateopp);msgFailureUpdateOpp = 'Error: failure to update Oppotunity<br/>' +ex.getTypeName() + ' - ' + ex.getCause() + ': ' + ex.getMessage();}
        
        
        // Send Email
        
        List<EmailTemplate> emailTemplate = [select Id, Subject, HtmlValue, Body from EmailTemplate Where Name=:TEMPLETE_NAME limit 1];
        
        System.debug('=============================> Ads SIZE: ' + lstAllAds.size());
        
        if(!emailTemplate.isEmpty())
        {

            String htmlBody='';
            // prepare to send email
            htmlBody = emailTemplate.get(0).HtmlValue;
            htmlBody = htmlBody.replace('@@@', DARTUtil.generateTableCompaigns(lstAllOrder))
                        .replace('###', DARTUtil.generateTableCompaignItems(lstAllAds))
                        .replace('{!opp.Name}', opp.Name)
                        .replace('{!opp.Owner}', UserInfo.getName())// opp.Owner.Name+'')
                        .replace('{!opp.Id}', DARTUtil.URL_INSTANCE+'/'+opp.Id)
                        .replace('#$',(lstAllOrder.isEmpty()?'There is no Order request successfully.':''))
                        .replace('msgOppUpdateOppFail', ('').equals(msgFailureUpdateOpp)?'':msgFailureUpdateOpp)
                        .replace('msgOppItemUpdateFail', ('').equals(msgFailureUpdateOppItem)?'':msgFailureUpdateOppItem);
                        
            //NK:31/07/2013:CR: email should be sent to whoever clicked the button
            DARTUtil.sendMail(new List<String>{UserInfo.getUserEmail()},null, DARTUtil.EMAIL_SUBJECT_BOOKING, 'ECG Mailer', htmlBody); 
            
            //For Testing only 
            DARTUtil.sendMail(new List<String>{'rvannierop@ebay.com'},null, DARTUtil.EMAIL_SUBJECT_BOOKING, 'Opportunity Owner', htmlBody);
            //pavlo// DARTUtil.sendMail(new List<String>{opp.Owner.Email}, DARTUtil.EMAIL_SUBJECT_BOOKING, 'Opportunity Owner', htmlBody);
            //DARTUtil.sendMail(new List<String>{'sochanra.yos@gaea-sys.com'},null, DARTUtil.EMAIL_SUBJECT_BOOKING, 'Opportunity Owner', htmlBody);
                          
        }   
        else //in case no email template found then it will send email to SF current user
        {
            //Email send to opportunity owner if there is no email template found.
            String errMsg = 'Dear ' + UserInfo.getName()+//opp.Owner.Name + 
                            '<br/><br/> There is no EmailTemplate name '+ TEMPLETE_NAME+ 'found.';
                             
            //NK:31/07/2013:CR: email should be sent to whoever clicked the button
            DARTUtil.sendMail(new List<String>{UserInfo.getUserEmail()},null, DARTUtil.EMAIL_SUBJECT_BOOKING,'ECG Mailer', errMsg); 
            DARTUtil.sendMail(new List<String>{'rvannierop@ebay.com'},null, DARTUtil.EMAIL_SUBJECT_BOOKING,'ECG Mailer', errMsg); 
        }  
          
        //Log the error message(s) -> insert in to attachement file of opportunity.
        
        System.debug('------------------------------>>> lstLogMsg:' + lstLogMsg);
     
        DARTLogger.getInstance().log(oppId,lstLogMsg);
       
    }
    

}