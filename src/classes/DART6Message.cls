/** 
 * Message Request for DFP
 * Including request to
 *  - get company(advertiser) by Account's name
 *  - create company(advertiser)
 *  - get user opportunity.owner.name or UserInfo.getName()
 *  - get order by Opportunity's name
 *  - create order
 *  - get lineItem by oppItem.Ad_Name__c
 *  - create order
 *  - get forecasting data
 *  - get delivery report
 *
 *	 @Revision: Chr - 10-08-2015
 *		-> Upgrade DFP from v201405 to v201505
 *		-> Some methode and class have been removed and created new
 */
public with sharing class DART6Message {
    public final static String DART6_WS_ERROR_PATTERN = 'Web service callout failed: WebService returned a SOAP Fault: \\[(.*?)\\] faultcode=soap:Server faultactor=';
    public final static Map<String, String> MAP_TIME_UNITS = new Map<String, String>{
                                                    'Minutes'=>'MINUTE', 
                                                    'Hours'=>'HOUR', 
                                                    'Days'=>'DAY', 
                                                    'Weeks'=>'WEEK', 
                                                    'Months'=>'MONTH',
                                                    'Minute'=>'MINUTE', 
                                                    'Hour'=>'HOUR', 
                                                    'Day'=>'DAY', 
                                                    'Week'=>'WEEK', 
                                                    'Month'=>'MONTH',
                                                    'Lifetime'=>'LIFETIME'};
                                                     
    
    public final static String BILLING_CATE_FIX_PRICE = 'Fix Price'; 
    public final static String LINEITEM_TYPE_NETWORK = 'NETWORK';
    public final static String LINEITEM_TYPE_HOUSE = 'HOUSE';
    public final static String LINEITEM_TYPE_AD_EXCHANGE='Ad Exchange';
    public final static String LINEITEM_TYPE_ADSENSE='AdSense';
    public final static String LINEITEM_TYPE_COMPANION='Companion';
    public final static String LINEITEM_TYPE_MASTER='Master';
    public final static String LINEITEM_TYPE_SPONSERSHIP = 'SPONSORSHIP';
    
    public final static String BREAKDOWN_DAILY = 'Daily';
    public final static String BREAKDOWN_MONTHLY = 'Monthly';
    public final static String DATERANGE_YESTERDAY = 'Yesterday';
    public final static String DATERANGE_LASTMONTH = 'LastMonth'; 
    //@updated Chr-28-08-2015: #7820 Runscope proxy for DFP
    //User proxy runscope to monitor traffice between SF and DFP
    public static Webservice_Settings__c WS 	= Webservice_Settings__c.getInstance('DFP');
	public static final String ENDPOINT_RUNSCOPE_PROXY     	= (!Test.IsRunningTest())?(WS.UseProxy__c?WS.EndpointProxy__c:WS.Endpoint__c):'testendpoint';                                         
    public DART6Message(){String s;}
    private static Set<String> setProductType = new Set<String>{LINEITEM_TYPE_COMPANION, LINEITEM_TYPE_MASTER};
     
    public abstract class AbstractDFPRequest extends AbstractDARTRequest implements HTTPWrapper.IInvoker{
          
    }
    
    /** 
     * @description request to create companay in DFP
     */
    public class DFPCompanyRequest extends AbstractDFPRequest{
        
        List<DART6_COMPANYSERVICE.Company> newCompanies;
        OpportunityLineItem item;
        Account acc;
        
        /**
         * @param related account of opportunity
         * @param OpportunityLineItem
         */
        public DFPCompanyRequest(Account acc, OpportunityLineItem item)
        {
            this.acc = acc;
            this.item = item;
        }
        
        public void invoke()
        {
            
            newCompanies = new List<DART6_COMPANYSERVICE.Company>();
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405

            DART6_COMPANYSERVICE.SoapRequestHeader header = new DART6_COMPANYSERVICE.SoapRequestHeader();
            header.applicationName='OrderService';
            header.networkCode=login.Network_ID__c;
            
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);
          
            DART6_COMPANYSERVICE.CompanyServiceInterfacePort companyRequest = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
            if(WS.UseProxy__c) companyRequest.endpoint_x = ENDPOINT_RUNSCOPE_PROXY+'CompanyService';
            companyRequest.RequestHeader = header;
            companyRequest.inputHttpHeaders_x = inputHttpHeaders_x;
            
            DARTObject.DARTAdvertiser dartAdvt = new DARTObject.DARTAdvertiser(acc);
            
            DART6_COMPANYSERVICE.Company com = new DART6_COMPANYSERVICE.Company();
            com.name = dartAdvt.getAccountName();
            com.externalId = dartAdvt.getAccountId();
            DART_Advertiser_Type_Mapper__c custAdvType = DART_Advertiser_Type_Mapper__c.getInstance(dartAdvt.getAccountRectName());
            com.type_x = (custAdvType!=null?custAdvType.DFP_Advertiser_Type__c:'');
            com.creditStatus ='ACTIVE';
            
             
            try{
	            List<DART6_COMPANYSERVICE.Company> cmps = companyRequest.createCompanies(new List<DART6_COMPANYSERVICE.Company>{com});
	            newCompanies.addAll(cmps);
            }catch(System.CalloutException cex){
	            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
	        }
            invokedMethod = 'Create Advertiser';
            
            
        }
        
        public Object getResponseObject(){
            //return DFP object from invoke
            return newCompanies;
        } 
    }
    
    
    /** 
     * @description request to get company(Advertiser) from DFP that filter by Account's name 
     */
    
    public class DFPGetAdvertiserRequest extends AbstractDFPRequest{
        OpportunityLineItem item;
        Account acc;
        List<DART6_COMPANYSERVICE.Company> dartAdvs;
        
        /**
         * @param OpportunityLineItem
         * @param related account of opportunity
         */
        public DFPGetAdvertiserRequest(OpportunityLineItem item, Account acc)
        {
            this.item = item;
            this.acc = acc;
        }
        
        public void invoke()
        {
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405
            DART6_COMPANYSERVICE.SoapRequestHeader header = new DART6_COMPANYSERVICE.SoapRequestHeader();
            header.applicationName='CompanyService';
            header.networkCode=login.Network_ID__c;
            
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);
            
            DART6_COMPANYSERVICE.CompanyServiceInterfacePort companyRequest = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
            if(WS.UseProxy__c) companyRequest.endpoint_x = ENDPOINT_RUNSCOPE_PROXY+'CompanyService';
            companyRequest.RequestHeader = header;
            companyRequest.inputHttpHeaders_x = inputHttpHeaders_x;
            
            String accName = (acc.Name+'').replace('\'', '\'\'').replace('"', '""');
            
            String querySt =  'WHERE name = \''+ accName+'\'';
            
            // Advertiser id
            DART6_COMPANYSERVICE.Statement filterAdv  = new DART6_COMPANYSERVICE.Statement();
            filterAdv.query = querySt;
                      
        
            DART6_COMPANYSERVICE.CompanyPage advPage = companyRequest.getCompaniesByStatement(filterAdv);
            dartAdvs = new List<DART6_COMPANYSERVICE.Company>();
            if (advPage.totalResultSetSize > 0) {
                for(DART6_COMPANYSERVICE.Company cmp : advPage.results ){
                    DART6_COMPANYSERVICE.Company dartAd = new DART6_COMPANYSERVICE.Company(); 
                    dartAd.id = cmp.id;
                    dartAd.name = cmp.name;
                    dartAdvs.add(dartAd);
                }
            }
            invokedMethod = 'getAdvertiser';
            
        }
        
        public Object getResponseObject(){
            //return DFP object from invoke
            return dartAdvs;
        }
    }
    
    /** 
     * @createdDate - 25-07-2014
     * @escription request to DFP to get Order that filter by Opportunity's name
     */
     public class DFPGetOrderRequest extends AbstractDFPRequest{
        
        Opportunity opp;
        OpportunityLineItem item;
        DART6_ORDERSERVICE.Order existOrder;
        
        /**
         * @param opportunity
         * @param OpportunityLineItem
         */
        public DFPGetOrderRequest(Opportunity opp, OpportunityLineItem item)
        {
            this.opp = opp;
            this.item = item;
        }
        
        public void invoke()
        {
            
            //Token
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405
            
            DART6_ORDERSERVICE.SoapRequestHeader header = new DART6_ORDERSERVICE.SoapRequestHeader();
            header.applicationName='OrderService';
            header.networkCode=login.Network_ID__c;
            
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);
            
            DART6_ORDERSERVICE.OrderServiceInterfacePort orderRequest = new DART6_ORDERSERVICE.OrderServiceInterfacePort();
            if(WS.UseProxy__c) orderRequest.endpoint_x = ENDPOINT_RUNSCOPE_PROXY+'OrderService';
            orderRequest.RequestHeader = header;
            orderRequest.inputHttpHeaders_x = inputHttpHeaders_x;
            
            DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(opp);  
            
            String oppName = dartOrder.getOppName().replace('\'', '\'\'').replace('"', '""');
            
            String querySt =  'WHERE name = \''+ oppName +'\'';
            
            // Get order
            DART6_ORDERSERVICE.Statement filterOrd  = new DART6_ORDERSERVICE.Statement();
            filterOrd.query = querySt;
                      
            DART6_ORDERSERVICE.OrderPage orderPage = orderRequest.getOrdersByStatement(filterOrd);
            List<DART6_ORDERSERVICE.Order> lstDartOrders = new List<DART6_ORDERSERVICE.Order>();
            if (orderPage.totalResultSetSize > 0) {
                for(DART6_ORDERSERVICE.Order ordRes : orderPage.results ){
                    DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order(); 
                    ord.id = ordRes.id;
                    ord.name = ordRes.name;
                    ord.advertiserId = ordRes.advertiserId;
                    
                    lstDartOrders.add(ord);
                }
            }
            if(!lstDartOrders.isEmpty()) existOrder =  lstDartOrders.get(0);
            invokedMethod = 'getOrderByName';
        }
        
        public Object getResponseObject()
        {
            return existOrder;
        }
     }
     
    /** 
     * @createdDate 25-07-2014
     * @description request to DFP to get lineItem that filter by Ad_Name__c 
     */
     
      public class DFPGetLineItemRequest extends AbstractDFPRequest{
        
        DART6_LINEITEMSERVICE.LineItem existItem;
        OpportunityLineItem item;
        DARTObject.IDARTObjectOrder dartOrder;
        public DFPGetLineItemRequest(OpportunityLineItem item, DARTObject.IDARTObjectOrder dartOrder)
        {
            this.dartOrder = dartOrder;
            this.item = item;   
        }
        
        public void invoke()
        {
        	
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405
        
            DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
            header.applicationName='LineItemService';
            header.networkCode=login.Network_ID__c;
            
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);
            
            DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
            if(WS.UseProxy__c) lineItemService.endpoint_x = ENDPOINT_RUNSCOPE_PROXY+'LineItemService';
            lineItemService.RequestHeader = header;
            lineItemService.timeout_x = 120000;
            lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;
            
            DARTObject.DARTAds dartAds = new DARTObject.DARTAds(item);
            
            String itemName = (dartAds.getName()!=null?dartAds.getName().replace('\'', '\'\'').replace('"', '""'):'');
            Long ordId = null;
            if(dartOrder != null)
            {
                ordId = Long.valueOf(dartOrder.getDartId()); 
            }
            
            String querySt =  'WHERE name = \''+ itemName +'\'  AND orderId=' + ordId;
            
            
            // Get LineItem
            DART6_LINEITEMSERVICE.Statement filterItem  = new DART6_LINEITEMSERVICE.Statement();
            filterItem.query = querySt;
                      
            DART6_LINEITEMSERVICE.LineItemPage itemPage = lineItemService.getLineItemsByStatement(filterItem);
            List<DART6_LINEITEMSERVICE.LineItem> lstDartItems = new List<DART6_LINEITEMSERVICE.LineItem>();
            if (itemPage.totalResultSetSize > 0) {
                for(DART6_LINEITEMSERVICE.LineItem itemRes : itemPage.results ){
                    DART6_LINEITEMSERVICE.LineItem lit = new DART6_LINEITEMSERVICE.LineItem(); 
                    lit.id = itemRes.id;
                    lit.orderId = itemRes.orderId;
                    
                    lstDartItems.add(lit);
                }
            }
            if(!lstDartItems.isEmpty()) existItem =  lstDartItems.get(0);
 
            invokedMethod = 'getLineItemByName';
			
        }
        
        public Object getResponseObject()
        {
            return existItem;
        }
     } 
    /**
     * @description request to create order in DFP 
     */
    
    public class DFPOrderRequest extends AbstractDFPRequest{
        
        DART6_ORDERSERVICE.Order newDartOrder;
        
        Opportunity opp;
        OpportunityLineItem item;
        Map<String, DARTObject.DARTPerson> mapDartUser;
        Map<String, Advertiser__c> mapAdvertiser;
        
        
        public DFPOrderRequest(Opportunity opp, OpportunityLineItem item, Map<String, DARTObject.DARTPerson> mapDartUser, Map<String, Advertiser__c> mapAdvertiser)
        {
            this.opp = opp; 
            this.item = item;
            this.mapDartUser = mapDartUser;
            this.mapAdvertiser= mapAdvertiser;
        }

        public void invoke()
        {
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405
        	//Sochanra 26-04-2016 -> get network timezone from AdserverLogin
      	    String networkTimezone = login.Timezone__c+'';
      
            DART6_ORDERSERVICE.SoapRequestHeader header = new DART6_ORDERSERVICE.SoapRequestHeader();
            header.applicationName='OrderService';
            header.networkCode=login.Network_ID__c;
          
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);
            
            DART6_ORDERSERVICE.OrderServiceInterfacePort orderRequest = new DART6_ORDERSERVICE.OrderServiceInterfacePort();
            if(WS.UseProxy__c) orderRequest.endpoint_x = ENDPOINT_RUNSCOPE_PROXY+'OrderService';
            orderRequest.RequestHeader = header;
            orderRequest.inputHttpHeaders_x = inputHttpHeaders_x;
            orderRequest.timeout_x = 120000;
            
            DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(opp);  
            
            // setDartTime Start
            DART6_ORDERSERVICE.Date_x datexStart = new DART6_ORDERSERVICE.Date_x();
            if(dartOrder.getDartStartDateTime()!=null){
	            datexStart.day = dartOrder.getDartStartDateTime().dayGmt(); //Integer.valueOf(dartOrder.getStartDay()+'');
	            datexStart.month = dartOrder.getDartStartDateTime().monthGmt(); //Integer.valueOf(dartOrder.getStartMonth()+'');
	            datexStart.year = dartOrder.getDartStartDateTime().yearGmt(); //Integer.valueOf(dartOrder.getStartYear()+'');
            }
            DART6_ORDERSERVICE.DateTime_x dartTimexStart = new DART6_ORDERSERVICE.DateTime_x();
            dartTimexStart.date_x = datexStart;
            dartTimexStart.hour = 0;
            dartTimexStart.minute = 0;
            dartTimexStart.second = 0;
            dartTimexStart.timeZoneID = networkTimezone;
            
            // setDartTime End
            DART6_ORDERSERVICE.Date_x datexEnd = new DART6_ORDERSERVICE.Date_x();
            if(dartOrder.getDartEndateTime()!=null){
	            datexEnd.day = dartOrder.getDartEndateTime().dayGmt(); //Integer.valueOf(dartOrder.getEndDay()+'');
	            datexEnd.month = dartOrder.getDartEndateTime().monthGmt(); //Integer.valueOf(dartOrder.getEndMonth()+'');
	            datexEnd.year = dartOrder.getDartEndateTime().yearGmt(); //Integer.valueOf(dartOrder.getEndYear()+'');
            }
            DART6_ORDERSERVICE.DateTime_x dartTimexEnd = new DART6_ORDERSERVICE.DateTime_x();
            dartTimexEnd.date_x = datexEnd;
            dartTimexEnd.hour = 23;
            dartTimexEnd.minute = 59;
            dartTimexEnd.second = 0;
            dartTimexEnd.timeZoneID = networkTimezone;

            // Create new Order 
            DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order();
            ord.poNumber = dartOrder.getPONumber();
            ord.startDateTime = dartTimexStart;
            ord.endDateTime = dartTimexEnd;
            ord.name = dartOrder.getOppName();
            ord.isArchived = false;
            
            //List<OpportunityTeamMember> lstOppTeamMember = DARTUtil.getOpportunityTeamMember(opp.id);
            //String trafickerId='';
            //if(lstOppTeamMember.size()>0)
            //{
            //  trafickerId = mapDartUser.get(lstOppTeamMember.get(0).User.Name)!=null?mapDartUser.get(lstOppTeamMember.get(0).User.Name).getDartId():'';
            //}else trafickerId = mapDartUser.get(login.User_Name__c)!=null?mapDartUser.get(login.User_Name__c).getDartId():'';
            
          String trafickerId = mapDartUser.get(UserInfo.getName())!=null?mapDartUser.get(UserInfo.getName()).getDartId():'';    
          String salespersonId = mapDartUser.get(opp.Owner.Name)!=null?mapDartUser.get(opp.Owner.Name).getDartId():'';
          
          String dartVer = item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c;
          
          
          if(mapAdvertiser.get(dartVer) != null)
          {
            ord.advertiserId = Long.valueOf(mapAdvertiser.get(dartVer).Dart6_Advertiser_Id__c);  // Company ID
          }
          if(!''.equals(salespersonId))
          {
            ord.salespersonId=Long.valueOf(salespersonId);
          }
          if(!''.equals(trafickerId))
          {
            ord.traffickerId = Long.valueOf(trafickerId);
          }
          //call to create order
	        try{  
		        List<DART6_ORDERSERVICE.Order>  lstOrdersRq =  orderRequest.createOrders(new List<DART6_ORDERSERVICE.Order>{ord});
		        if(!lstOrdersRq.isEmpty()) newDartOrder = lstOrdersRq.get(0);
	        }catch(System.CalloutException cex){
	            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
	        }
        
        invokedMethod = 'createOrder';
         
        }
        // this object returned from the invoke above and target for Parser to parse into our Apex DartObject 
        public Object getResponseObject(){
            //return DFP object from invoke
            return newDartOrder;
        }
    }
    
    /**
     * @description request to get Salesperson and Trafficker from DFP
     * - Salesperson: get from DFP's user filter by name = opportunity.owner.Name
     * - Trafficker: get from DFP's user filter by UserInfo.getName()
     */
    public class DFPSalespersonRequest extends AbstractDFPRequest{
   
        List<DART6_USERSERVICE.User_x> dartUsers;
        OpportunityLineItem oppItem;
        Opportunity opp;
        
        public DFPSalespersonRequest(OpportunityLineItem oppItem, Opportunity opp)
        {
          this.oppItem = oppItem;
          this.opp = opp;
        }
        
        public void Invoke()
    	{ 
      
	      AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,oppItem.PriceBookEntry.Product2.Site__r.Country__c);
	      String authToken = DARTUtil.getAccessToken(login); // new version 201405
          
          DART6_USERSERVICE.SoapRequestHeader userHeader = new DART6_USERSERVICE.SoapRequestHeader();
          userHeader.applicationName = 'UserService';
          userHeader.networkCode= login.Network_ID__c; 
          
          Map<String,String> inputHttpHeaders_x = new Map<String, String>();
          inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken); 
          
          DART6_USERSERVICE.UserServiceInterfacePort userRequest = new DART6_USERSERVICE.UserServiceInterfacePort();
          if(WS.UseProxy__c) userRequest.endpoint_x = ENDPOINT_RUNSCOPE_PROXY+'UserService';
          userRequest.RequestHeader = userHeader;
          userRequest.inputHttpHeaders_x = inputHttpHeaders_x;
          
          String uInfoName = UserInfo.getName().replace('\'', '\'\'').replace('"', '""');
          String ownerName = (opp.Owner.Name+'').replace('\'', '\'\'').replace('"', '""');
          
          String querySt =  'WHERE name = \''+ uInfoName+'\' OR name =\'' + ownerName + '\'';
            
            // Get User Id (traffickerId) DART User By UserName in Adsever Login
            DART6_USERSERVICE.Statement filterUser  = new DART6_USERSERVICE.Statement();
            filterUser.query = querySt;
                      
        
            DART6_USERSERVICE.UserPage userPage = userRequest.getUsersByStatement(filterUser);
            dartUsers = new List<DART6_USERSERVICE.User_x>();
            if (userPage.totalResultSetSize > 0){ 
                for(DART6_USERSERVICE.User_x user : userPage.results ){
                    DART6_USERSERVICE.User_x dartuser = new DART6_USERSERVICE.User_x(); 
                    dartUser.id = user.id;
                    dartUser.name = user.name;
                    dartUser.email = user.email;
                    dartUsers.add(dartUser);
                }
            }
            
            invokedMethod = 'getCurrentUser';
           
        }
        
        public Object getResponseObject()
        {
            return dartUsers;
        }
    }
    
    /**
     * @description request to DFP to create lineItem
     */
    public class DFPAdsRequest extends AbstractDFPRequest{

        DART6_LINEITEMSERVICE.LineItem dfpLineItemResponse;
        OpportunityLineItem item;
        DARTObject.IDARTObjectOrder dartOrder;

        public DFPAdsRequest(OpportunityLineItem item, DARTObject.IDARTObjectOrder dartOrder)
        {
            this.item = item;
            this.dartOrder = dartOrder;
        }   
        
        public void Invoke()
        { 
            //Token   
            DART6_KeyValueController ctrl;
            List<DART6_FORECASTSERVICE.CustomCriteriaSet> listCrit = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
            
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405
        	//Sochanra 26-04-2016 -> get network timezone from AdserverLogin
      	    String networkTimezone = login.Timezone__c+'';
            DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
            header.applicationName='LineItemService';
            header.networkCode=login.Network_ID__c;
            
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken); 
        
            DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
            if(WS.UseProxy__c) lineItemService.endpoint_x = ENDPOINT_RUNSCOPE_PROXY+'LineItemService';
            lineItemService.RequestHeader = header;
            lineItemService.timeout_x = 120000;
            lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;
            
            DARTObject.DARTAds dartAds = new DARTObject.DARTAds(item);
            
            // setDartTime Start
            DART6_LINEITEMSERVICE.Date_x datexStart = new DART6_LINEITEMSERVICE.Date_x();
            datexStart.day = dartAds.getStartDateTime().dayGmt();
            datexStart.month = dartAds.getStartDateTime().monthGmt();
            datexStart.year = dartAds.getStartDateTime().yearGmt();
            
            DART6_LINEITEMSERVICE.DateTime_x dartTimexStart = new DART6_LINEITEMSERVICE.DateTime_x();
            dartTimexStart.date_x = datexStart;
            
            dartTimexStart.hour = 0;
            dartTimexStart.minute = 0;
            dartTimexStart.second = 0;
            dartTimexStart.timeZoneID = networkTimezone;
                
            // setDartTime End
            DART6_LINEITEMSERVICE.Date_x datexEnd = new DART6_LINEITEMSERVICE.Date_x();
            datexEnd.day = dartAds.getEndDateTime().dayGmt();
            datexEnd.month = dartAds.getEndDateTime().monthGmt();
            datexEnd.year = dartAds.getEndDateTime().yearGmt();
            
            DART6_LINEITEMSERVICE.DateTime_x dartTimexEnd = new DART6_LINEITEMSERVICE.DateTime_x();
            dartTimexEnd.date_x = datexEnd;
            dartTimexEnd.hour = 23;
            dartTimexEnd.minute = 59;
            dartTimexEnd.second = 0;
            dartTimexEnd.timeZoneID = networkTimezone;
            
            // Get placementIds
            List<Long> placementIds = new List<Long>();
            
            //Theany: 2/4/2014: replace getIncludeContentCat with getIncludePlacementTarget   
            //Chr: @updated 28-07-2014: replace object PlacementTargeting__c by use PlacementTargetingDefinition__c instead 
            //Chr: @updated 20-03-2015: replace object PlacementTargetingDefinition__c by placement__c
            for(Placement__c pPlacement : dartAds.getIncludePlacementTarget())
            {
                if(pPlacement.Dart_Id__c != null) placementIds.add(Long.valueOf(pPlacement.Dart_Id__c+''));
            }
            
            //targetedAdUnits
            List<DART6_LINEITEMSERVICE.AdUnitTargeting> adUnitTargs = new List<DART6_LINEITEMSERVICE.AdUnitTargeting>();
            
            for(Content__c dartSite : dartAds.getIncludeDartSite())
            {
                DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
                adunit.adUnitId = dartSite.Name;
                adUnitTargs.add(adunit);
            }
            for(Content__c dartZone : dartAds.getIncludeDartZone())
            {
                DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
                adunit.adUnitId = dartZone.Name;
                adUnitTargs.add(adunit);
            }
            
            //Changed to use geography instead of country & city
            List<DART6_LINEITEMSERVICE.Location> lstLocations = new List<DART6_LINEITEMSERVICE.Location>();
            for(Geography__c g : dartAds.getIncludeGeography())
            {
                DART6_LINEITEMSERVICE.Location loc = new DART6_LINEITEMSERVICE.Location();
                 loc.id = Long.valueOf(g.Dart_ID__c+''); // 2124
                 loc.type_x = g.Type__c;
                 lstLocations.add(loc); 
            }
            
            for(Region__c rg : dartAds.getIncludeRegions())
            {  
                DART6_LINEITEMSERVICE.Location locRgn = new DART6_LINEITEMSERVICE.Location();
                if(rg.Dart_ID__c != null)
                {
                    locRgn.id = Long.valueOf(rg.Dart_ID__c+'');
                }
                
                locRgn.type_x = 'RegionLocation';
                lstLocations.add(locRgn);
            }
            
            //Pushing Device targeting to DFP
            DART6_LINEITEMSERVICE.BandwidthGroupTargeting bandwidthGroupTargeting = null;
            DART6_LINEITEMSERVICE.MobileCarrierTargeting mobileCarrierTargeting = null;
            Set<String> bandWidthParentIds = new Set<String>();
            Set<String> mobileCarParentIds = new Set<String>();
            Set<String> connIds = new Set<String>();
            for(Connection__c c : dartAds.getIncludeConnection())
            { 
            
                if(('BandwidthGroup').equals(c.DFP_API_Name__c))
                {
                    bandWidthParentIds.add(c.id);
                }
                else if(('MobileCarrier').equals(c.DFP_API_Name__c))
                {
                    mobileCarParentIds.add(c.id);
                }else connIds.add(c.id);
    
            }
       
            Set<String> mcParids = new Set<String>();
           
            // Bandwidth connection
            List<Connection__c> lstConnBwidth = new List<Connection__c>();
           
           for(Connection__c c : dartAds.getIncludeConnection())
           {
                if(bandWidthParentIds.contains(c.Node_ID__c))
                {
                    lstConnBwidth.add(c);
                }
                else if(mobileCarParentIds.contains(c.Node_ID__c))
                {
                    mcParids.add(c.Id);
                }
            }
       
            //MobileCarrier connection
            List<Connection__c> lstMbCar = new List<Connection__c>();
            for(Connection__c c : dartAds.getIncludeConnection())
            {
                if(mcParids.contains(c.Node_ID__c))
                {
                    lstMbCar.add(c);
                }
            }
           
            DART6_LINEITEMSERVICE.Technology[] listBandWidth = new List<DART6_LINEITEMSERVICE.Technology>();
            // Bandwidth 
            for(Connection__c con : lstConnBwidth)
            {
                DART6_LINEITEMSERVICE.Technology technologyBw = new DART6_LINEITEMSERVICE.Technology();
                technologyBw.id = con.Dart_ID__c.longValue();
                listBandWidth.add(technologyBw);
            }
           
            if(!listBandWidth.isEmpty())
            {
                bandwidthGroupTargeting = new DART6_LINEITEMSERVICE.BandwidthGroupTargeting();
                bandwidthGroupTargeting.bandwidthGroups = listBandWidth;
            }
           
            //MobileCarrier
            DART6_LINEITEMSERVICE.Technology[] techMobileCar = new List<DART6_LINEITEMSERVICE.Technology>();
            for(Connection__c con : lstMbCar)
            {
                DART6_LINEITEMSERVICE.Technology techMb = new DART6_LINEITEMSERVICE.Technology();
                techMb.id = con.Dart_ID__c.longValue();
                techMobileCar.add(techMb);
            }
           
            if(!techMobileCar.isEmpty())
            {
                mobileCarrierTargeting = new DART6_LINEITEMSERVICE.MobileCarrierTargeting();
                mobileCarrierTargeting.mobileCarriers = techMobileCar;
            }
            // ---------------- end of targeting device setup ----------------
            
            //pushing Connection targeting to DFP
            // -------------------------->> Device Targeting <<--------------------------------
           DART6_LINEITEMSERVICE.Technology[] listBrowsing = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listBrowsingLang = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listDeviceCap = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listDeviceCategory = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listDeviceManufacturer = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listOpSys = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listOpSysVersion = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listMobileDevice = new List<DART6_LINEITEMSERVICE.Technology>();
           DART6_LINEITEMSERVICE.Technology[] listMobileDeviceSubMod = new List<DART6_LINEITEMSERVICE.Technology>();
           
           //@updated 08-01-2015
           //Use Device category value in Product instead of seleted from targeting tree
           List<String> devCateValue = (dartAds.getDeviceCategory()!=null?dartAds.getDeviceCategory().split(','):new List<String>());
           for(Devices__c dev : DARTUtil.getListDevicesCategory(devCateValue))
           {
           		if(dev.Dart_ID__c !=null){
	           		DART6_LINEITEMSERVICE.Technology techDevCate = new DART6_LINEITEMSERVICE.Technology();
	                techDevCate.id = dev.Dart_ID__c.longValue();
	                listDeviceCategory.add(techDevCate);
           		}
           }

           //Targeting Device from targeting tree
           for(Devices__c d : dartAds.getIncludeDevice())
           {
                if(('Browser').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techBrw = new DART6_LINEITEMSERVICE.Technology();
                    techBrw.id = d.Dart_ID__c.longValue();
                    listBrowsing.add(techBrw);
                }
                else if(('BrowserLanguage').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techBrwLang = new DART6_LINEITEMSERVICE.Technology();
                    techBrwLang.id = d.Dart_ID__c.longValue();
                    listBrowsingLang.add(techBrwLang);
                }
                else if(('DeviceCapability').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techDevCap = new DART6_LINEITEMSERVICE.Technology();
                    techDevCap.id = d.Dart_ID__c.longValue();
                    listDeviceCap.add(techDevCap);
                }
                //else if(('DeviceCategory').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                //{
                //    DART6_LINEITEMSERVICE.Technology techDevCate = new DART6_LINEITEMSERVICE.Technology();
                //    techDevCate.id = d.Dart_ID__c.longValue();
                //    listDeviceCategory.add(techDevCate);
                //}
                else if(('DeviceManufacturer').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techDevMf = new DART6_LINEITEMSERVICE.Technology();
                    techDevMf.id = d.Dart_ID__c.longValue();
                    listDeviceManufacturer.add(techDevMf);
                } 
                else if(('OperatingSystem').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techOs = new DART6_LINEITEMSERVICE.Technology();
                    techOs.id = d.Dart_ID__c.longValue();
                    listOpSys.add(techOs);
                }
                else if(('OperatingSystemVersion').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techOsVersion = new DART6_LINEITEMSERVICE.Technology();
                    techOsVersion.id = d.Dart_ID__c.longValue();
                    listOpSysVersion.add(techOsVersion);
                }
                else if(('MobileDevice').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techMobileDev = new DART6_LINEITEMSERVICE.Technology();
                    techMobileDev.id = d.Dart_ID__c.longValue();
                    listMobileDevice.add(techMobileDev);
                }
                else if(('MobileDeviceSubmodel').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_LINEITEMSERVICE.Technology techMobileDevSubMd = new DART6_LINEITEMSERVICE.Technology();
                    techMobileDevSubMd.id = d.Dart_ID__c.longValue();
                    listMobileDeviceSubMod.add(techMobileDevSubMd);
                }
           }

           // DART6_LINEITEMSERVICE.BrowserTargeting
           DART6_LINEITEMSERVICE.BrowserTargeting browserTargeting = null;
           if(!listBrowsing.isEmpty())
           {
                browserTargeting = new DART6_LINEITEMSERVICE.BrowserTargeting();
                browserTargeting.browsers = listBrowsing;
           }
           
           // DART6_LINEITEMSERVICE.BrowserLanguageTargeting
           DART6_LINEITEMSERVICE.BrowserLanguageTargeting browserLanguageTargeting = null;
           if(!listBrowsingLang.isEmpty())
           {
                browserLanguageTargeting = new DART6_LINEITEMSERVICE.BrowserLanguageTargeting();
                browserLanguageTargeting.browserLanguages = listBrowsingLang;
           }
           
           // DART6_LINEITEMSERVICE.DeviceCapabilityTargeting
           DART6_LINEITEMSERVICE.DeviceCapabilityTargeting deviceCapabilityTargeting = null;
           if(!listDeviceCap.isEmpty())
           {
                deviceCapabilityTargeting = new DART6_LINEITEMSERVICE.DeviceCapabilityTargeting();
                deviceCapabilityTargeting.targetedDeviceCapabilities = listDeviceCap;
           }
           
           //DART6_LINEITEMSERVICE.DeviceCategoryTargeting
           DART6_LINEITEMSERVICE.DeviceCategoryTargeting deviceCategoryTargeting = null;
           if(!listDeviceCategory.isEmpty())
           {
                deviceCategoryTargeting = new DART6_LINEITEMSERVICE.DeviceCategoryTargeting();
                deviceCategoryTargeting.targetedDeviceCategories = listDeviceCategory;
           }
           
           //DART6_LINEITEMSERVICE.DeviceManufacturerTargeting ;
           DART6_LINEITEMSERVICE.DeviceManufacturerTargeting deviceManufacturerTargeting = null;
           if(!listDeviceManufacturer.isEmpty())
           {
                deviceManufacturerTargeting = new DART6_LINEITEMSERVICE.DeviceManufacturerTargeting();
                deviceManufacturerTargeting.deviceManufacturers = listDeviceManufacturer;
           }
           
           //DART6_LINEITEMSERVICE.OperatingSystemTargeting
           DART6_LINEITEMSERVICE.OperatingSystemTargeting OperatingSystemTargeting = null;
           if(!listOpSys.isEmpty())
           {
                OperatingSystemTargeting = new DART6_LINEITEMSERVICE.OperatingSystemTargeting();
                OperatingSystemTargeting.operatingSystems = listOpSys;
           }
           
           //DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting
           DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting operatingSystemVersionTargeting = null;
           if(!listOpSysVersion.isEmpty())
           {
                operatingSystemVersionTargeting = new DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting();
                operatingSystemVersionTargeting.targetedOperatingSystemVersions = listOpSysVersion;
           }
           
           //DART6_LINEITEMSERVICE.MobileDeviceTargeting
           DART6_LINEITEMSERVICE.MobileDeviceTargeting mobileDeviceTargeting = null;
           if(!listMobileDevice.isEmpty())
           {
                mobileDeviceTargeting = new DART6_LINEITEMSERVICE.MobileDeviceTargeting();
                mobileDeviceTargeting.targetedMobileDevices = listMobileDevice;
           }
           
           //DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting
           DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting mobileDeviceSubmodelTargeting = null;
           if(!listMobileDeviceSubMod.isEmpty())
           {
                mobileDeviceSubmodelTargeting = new DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting();
                mobileDeviceSubmodelTargeting.targetedMobileDeviceSubmodels = listMobileDeviceSubMod;
           }
           
            // --------------------- end of connection set up ------------
            
            //Set up Connection and Device targeting to the parent technologyTargeting
            //---------------------------- TechnologyTargeting ---------------------------//
            DART6_LINEITEMSERVICE.TechnologyTargeting technologyTargeting = new DART6_LINEITEMSERVICE.TechnologyTargeting();
          
          
            if(browserTargeting!=null)
            {
                technologyTargeting.browserTargeting = browserTargeting;
            }
          
            if(bandwidthGroupTargeting!=null)
            {
                technologyTargeting.bandwidthGroupTargeting = bandwidthGroupTargeting;
            }
          
            if(mobileCarrierTargeting!=null)
            {
                technologyTargeting.mobileCarrierTargeting = mobileCarrierTargeting;
            }
          
            if(browserTargeting!=null)
            {
                technologyTargeting.browserTargeting = browserTargeting;
            } 
          
            if(browserLanguageTargeting!=null)
            {
                technologyTargeting.browserLanguageTargeting = browserLanguageTargeting;
            }
          
            if(deviceCapabilityTargeting!=null)
            {
                technologyTargeting.deviceCapabilityTargeting = deviceCapabilityTargeting;
            }
          
            if(deviceCategoryTargeting!=null)
            {
                technologyTargeting.deviceCategoryTargeting = deviceCategoryTargeting;
            }
          
            if(deviceManufacturerTargeting!=null)
            {
                technologyTargeting.deviceManufacturerTargeting = deviceManufacturerTargeting;
            } 
          
            if(OperatingSystemTargeting!=null)
            {
                technologyTargeting.OperatingSystemTargeting = OperatingSystemTargeting; 
            }
          
            if(operatingSystemVersionTargeting!=null)
            {
                technologyTargeting.operatingSystemVersionTargeting = operatingSystemVersionTargeting; 
            }
          
            if(mobileDeviceTargeting!=null)
            {
                technologyTargeting.mobileDeviceTargeting = mobileDeviceTargeting;
            }  
          
            if(mobileDeviceSubmodelTargeting!=null)
            {
                technologyTargeting.mobileDeviceSubmodelTargeting = mobileDeviceSubmodelTargeting;
            }
            
            //DayPart
            List<DART6_LINEITEMSERVICE.DayPart> lstDayParts = new List<DART6_LINEITEMSERVICE.DayPart>();
            
            // Day of Week
            //ex: sunday; monday
            //ex: 22:00 - 22:59; 23:00 - 23:59
            //-> sunday: 22:00 - 22:59; 23:00 - 23:59
            //-> monday: 22:00 - 22:59; 23:00 - 23:59
                    
            /*for(String dw : dartAds.getDayOfWeek())
            {

                // Hours of Day
                //(22:00 - 22:59, 23:00 - 23:59,.....)
                //NK:Fixed: 09/02/2013
                String[] hods = dartAds.getHourOfDay();
                hods = !hods.isEmpty()?hods:new String[]{'00:00 - 23:59'}; //all time if time not specified.
                for(String hd : hods)
                { 
                    List<String> lsthd = hd.split('-'); // (22:00, 22:59)
                    List<String> lstTimeStart = lsthd[0].split(':'); //(22, 00)
                    List<String> lstTimeEnd = lsthd[1].split(':'); // (22, 59)
                    
                    DART6_LINEITEMSERVICE.TimeOfDay startTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay();
                    startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim()+'');
                    startTimeOfDay.minute ='ZERO';// lstTimeStart[1].trim();
                    
                    DART6_LINEITEMSERVICE.TimeOfDay endTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay();
                    endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'');
                    endTimeOfDay.minute ='FORTY_FIVE';// lstTimeEnd[1].trim();
                    
                    DART6_LINEITEMSERVICE.DayPart dayPart = new DART6_LINEITEMSERVICE.DayPart();
                    dayPart.dayOfWeek = dw.toUpperCase();
                    dayPart.startTime = startTimeOfDay;
                    dayPart.endTime = endTimeOfDay;
                            
                    lstDayParts.add(dayPart);
                            
                    } 
                }*/
              
                // Pheaktra Hun: 31-Aug-2016. For Time Targeting with different hours on different days
                for(DARTObject.DTOTimeTargeting dto : dartAds.getListDTOTimeTargeting() ){
	              for(String hour : dto.hours){   // Ex: dto.hours = ('0:00 - 0:59', '1:00 - 1:59')
	                List<String> lsthd = hour.split('-'); // (0:00, 0:59)
	                    List<String> lstTimeStart = lsthd[0].split(':'); //(0, 00)
	                    List<String> lstTimeEnd = lsthd[1].split(':'); // (0, 59)
	                
	                	DART6_LINEITEMSERVICE.TimeOfDay startTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay();
	                    startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim()+'');
	                    startTimeOfDay.minute ='ZERO'; 
	                    
	                    DART6_LINEITEMSERVICE.TimeOfDay endTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay(); 
	                    endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'')+1;
	                    endTimeOfDay.minute ='ZERO'; 
	                    
	                    DART6_LINEITEMSERVICE.DayPart dayPart = new DART6_LINEITEMSERVICE.DayPart();
	                    dayPart.dayOfWeek = dto.day.toUpperCase();
	                    dayPart.startTime = startTimeOfDay;
	                    dayPart.endTime = endTimeOfDay;
	                            
	                    lstDayParts.add(dayPart);
	              }
	            }
                
                // Targeting
                DART6_LINEITEMSERVICE.Targeting itemTargeting = new DART6_LINEITEMSERVICE.Targeting();
                
                // InventoryTargeting
                DART6_LINEITEMSERVICE.InventoryTargeting inventoryTargeting = new DART6_LINEITEMSERVICE.InventoryTargeting();
                //@updated:Chr - 08-04-2015
                //#5100 - if no placement & predefaulted targeting, available_sites on the product then AdUnit will auto send to DFP as Run of Network
                //Run of Network's id is store in custome object Site__c.Run_of_Network_ID__c 
                if(placementIds.isEmpty() && adUnitTargs.isEmpty()){
                	DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
                	adunit.adUnitId = item.PriceBookEntry.Product2.Site__r.Run_of_Network_ID__c;
    				inventoryTargeting.targetedAdUnits = new List<DART6_LINEITEMSERVICE.AdUnitTargeting>{adunit};
                }else{
	                inventoryTargeting.targetedPlacementIds = placementIds; 
	                inventoryTargeting.targetedAdUnits = adUnitTargs;
                }
                
                itemTargeting.inventoryTargeting  = inventoryTargeting;
                
                if(lstLocations.size()>0)
                {
                    //DART6_FORECASTSERVICE.GeoTargeting
                    DART6_LINEITEMSERVICE.GeoTargeting geoTargeting = new DART6_LINEITEMSERVICE.GeoTargeting();
                    geoTargeting.targetedLocations = lstLocations;
                    itemTargeting.geoTargeting = geoTargeting;
                    
                }
                
                if(lstDayParts.size()>0) // daysParts is not required if it has values, it will be set
                {
                    //DART6_FORECASTSERVICE.DayPartTargeting
                    DART6_LINEITEMSERVICE.DayPartTargeting dayPartTargeting = new DART6_LINEITEMSERVICE.DayPartTargeting();
                    dayPartTargeting.dayParts = lstDayParts;
                    dayPartTargeting.timeZone = 'BROWSER';
                    itemTargeting.dayPartTargeting = dayPartTargeting;
                }
                
                ctrl = new DART6_KeyValueController(item.PricebookEntry.Product2.Site__r.Id, dartAds.getKeyWKV(), authToken, login.Network_ID__c);
                    
                
                if(ctrl.isNeedToCreate()) 
                {
                    ctrl.searchCreateDFPFreeFormValues();
                    
                }
                listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>)ctrl.getListDart();
                
                itemTargeting.technologyTargeting = technologyTargeting;
                if(listCrit.size()>0)
                {
                    itemTargeting.customTargeting = listCrit.get(0);     
                }
                 
                // Money
                DART6_LINEITEMSERVICE.Money money = new DART6_LINEITEMSERVICE.Money();
                money.currencyCode = dartAds.getCurrencyCode(); //NK:16/01/2015: dynamic currency code already here so far.
                
                //money.currencyCode = 'AUD'; // JvdH TODO make dynamic. item.Opportunity.CurrencyIsoCode; // 'CAD';
                
                money.microAmount = Long.valueOf(dartAds.getRate()+'');
                
                 
                //LineItem Size
                //----------------11-11-2013--------------------------
               
                List<String> lstAdSlotWH = new List<String>();
                List<DART6_LINEITEMSERVICE.CreativePlaceholder> listCreativePLC = new List<DART6_LINEITEMSERVICE.CreativePlaceholder>();
                
                
                lstAdSlotWH = dartAds.getListAdSlotWH(); // lstAdSlotHW{120x600,160x600}; 
                //Get native style from custom setting
                Map<String, DART_NativeStylesMapper__c> mNativeStyles = DART_NativeStylesMapper__c.getAll();           
                for (String slotWH : lstAdSlotWH ){
                    DART6_LINEITEMSERVICE.CreativePlaceholder creativePlc = new DART6_LINEITEMSERVICE.CreativePlaceholder();
                    
                    DART6Message.setSize(creativePlc, slotWH, login.Network_ID__c, mNativeStyles);
                    listCreativePLC.add(creativePlc);               
                }   
                system.debug('/n/n listCreativePLC = ' +listCreativePLC); 
                //--------------------11-11-2013------------------
                
                                          
                //allCreativePlaceHolder.add(creativePlc);                
                                        
                /** Create LineItem */
                DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
                if(dartOrder != null)
                {
                    lineItem.orderId = Long.valueOf(dartOrder.getDartId()); // Set order id to LineItem
                }
                
                lineItem.name = dartAds.getName(); 
                
                if(dartAds.getUnit().equals(BILLING_CATE_FIX_PRICE) || dartAds.getUnit().equals('CPD'))
                {
                    lineItem.lineItemType = 'SPONSORSHIP';
                    
                }else
                {
                    lineItem.lineItemType = dartAds.getLineItemType() == '' ? 'STANDARD' : dartAds.getLineItemType();
                }
                lineItem.priority = dartAds.getPriority();
                lineItem.costType = dartAds.getUnit().equals(BILLING_CATE_FIX_PRICE)?'CPD':dartAds.getUnit();
                lineItem.startDateTime = dartTimexStart;
                lineItem.endDateTime = dartTimexEnd;
                lineItem.targeting = itemTargeting;
                lineItem.allowOverbook = true; // Chr: 11-07-2014: set to avoid error NOT_ENOUGH_INVENTORY
                lineItem.deliveryRateType = 'EVENLY'; // Chr: 29-09-2014: set deliverRateType to EVENLY for all lineItem
                lineItem.notes = dartAds.getAdOpsComments(); // Chr: 30-11-2015 pushing Ad Ops Comment to lineItem
                lineItem.creativeRotationType = 'EVENLY';
                String dartProType = dartAds.getDartProductType();
                if( String.isNotEmpty(dartProType) && setProductType.contains(dartProType)) {
                    lineItem.companionDeliveryOption = 'ALL';
                } else{
                    lineItem.roadblockingType = 'ONLY_ONE';
                } 
                
                
                if(!''.equals(dartAds.getQuantity()))
                {
                    DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal();
                    gl.unitType = ('CPC'.equals(dartAds.getUnit())?'CLICKS':'IMPRESSIONS'); 
                    
                    if((LINEITEM_TYPE_NETWORK.equals(dartAds.getLineItemType()) || LINEITEM_TYPE_HOUSE.equals(dartAds.getLineItemType()) || LINEITEM_TYPE_SPONSERSHIP.equals(dartAds.getLineItemType()))  ||  dartAds.getUnit().equals('CPD'))
                    {
                          gl.unitType = 'IMPRESSIONS';
                          gl.units = 100;
                          lineItem.primaryGoal = gl;
                    }
                    else
                    {
                          gl.units = Long.valueOf(dartAds.getQuantity()+'');
                          lineItem.primaryGoal = gl;
                    }
                }
                 
                // If line item start date is today then set StartDateTimeType to ONE_HOUR_FROM_NOW
                if(dartAds.getStartDateTime().isSameDay(System.today()))
                {
                    lineItem.startDateTimeType = 'ONE_HOUR_FROM_NOW';
                }
                lineItem.costPerUnit = money;
                
                // Passing Line description to DFP customField "Name Comment"
                // 05-06-2014
                // LineItem Custom field
                DART6_LINEITEMSERVICE.TextValue custVal = new DART6_LINEITEMSERVICE.TextValue();
                custVal.value = dartAds.getLineDesc();
                custVal.type_x = 'TextValue';
                
                // Chr: 22-05-2015 # 5306: Pass line description into customfield id=5320 at Line Item level in DFP 
                DART6_LINEITEMSERVICE.CustomFieldValue custFldVal = new DART6_LINEITEMSERVICE.CustomFieldValue();
                //Sochanra: 27-04-2016 #9210 get customFieldId from AdserverLogin (ExternalLineDescriptionId__c)
                custFldVal.customFieldId =  (login.ExternalLineDescriptionId__c!=null?Long.valueOf(login.ExternalLineDescriptionId__c+''):null); //9672;
                custFldVal.type_x= 'CustomFieldValue';
                custFldVal.value = custVal;
                lineItem.customFieldValues = new List<DART6_LINEITEMSERVICE.BaseCustomFieldValue>{custFldVal};
                
                // lineItem.creativePlaceholders = new DART6_LINEITEMSERVICE.CreativePlaceholder[]{creativePlc};
                
                // If Advertising_Medium__c.Dart_producttype__c = 'companion'
                // => Advertising_Medium__c.DART_MasterSize__c --> size
                //    Advertising_medium__c.DART_CompanionSize__c --> companions
                
                if( String.isNotEmpty(dartProType) && setProductType.contains(dartProType))  //LINEITEM_TYPE_COMPANION
                {
                    List<DART6_LINEITEMSERVICE.CreativePlaceholder> lstCpl = new List<DART6_LINEITEMSERVICE.CreativePlaceholder>();
                        
                        for(String s: dartAds.getDartMasterSize())
                        {
                            DART6_LINEITEMSERVICE.CreativePlaceholder cph = new DART6_LINEITEMSERVICE.CreativePlaceholder();
                            
                            DART6Message.setSize(cph, s, login.Network_ID__c, mNativeStyles);
                            
                            List<DART6_LINEITEMSERVICE.CreativePlaceholder> lstCompanion = new List<DART6_LINEITEMSERVICE.CreativePlaceholder>();
                            for(String cz : dartAds.getDartCompanionSize())
                            {
                                DART6_LINEITEMSERVICE.CreativePlaceholder comp = new DART6_LINEITEMSERVICE.CreativePlaceholder();
                                
                                DART6Message.setSize(comp, cz, login.Network_ID__c, mNativeStyles);
                                lstCompanion.add(comp);
                            }
                            
                            cph.companions = lstCompanion;
                            lstCpl.add(cph);
                        }
                    lineItem.creativePlaceholders = lstCpl;
                    //lineItem.EnvironmentType = 'VIDEO_PLAYER';
                }
                else
                {
                    lineItem.creativePlaceholders = listCreativePLC;
                }
                
                if(!''.equals(dartAds.getFCPeriodDart6()))
                {
                    // FrequencyCap
                    DART6_LINEITEMSERVICE.FrequencyCap freqCap = new DART6_LINEITEMSERVICE.FrequencyCap();
                    freqCap.numTimeUnits = DARTUtil.toInteger(dartAds.getFCAdServedEvery());
                    freqCap.maxImpressions = DARTUtil.toInteger(dartAds.getFCQty());
                    freqCap.timeUnit = MAP_TIME_UNITS.get(dartAds.getFCPeriodDart6()); 
                
                    lineItem.frequencyCaps = new DART6_LINEITEMSERVICE.FrequencyCap[]{freqCap};
                }
                
                if (!dartAds.getFrequencyCappings().isEmpty()) {
                	lineItem.frequencyCaps = new List<DART6_LINEITEMSERVICE.FrequencyCap>();
                	for (TargetingFrequencyAssociation__c tfa : dartAds.getFrequencyCappings()) {
                		// FrequencyCap
	                    DART6_LINEITEMSERVICE.FrequencyCap freqCap = new DART6_LINEITEMSERVICE.FrequencyCap();
	                    freqCap.numTimeUnits = DARTUtil.toInteger(tfa.FC_Ad_served_every__c);
	                    freqCap.maxImpressions = DARTUtil.toInteger(tfa.FC_Quantity__c);
	                    freqCap.timeUnit = MAP_TIME_UNITS.get(tfa.FC_Period__c); 
	                    lineItem.frequencyCaps.add(freqCap);
                	}
                }
                
                try{
                        if(dartAds.getAdId()==null) // if Ad_Id__c=null => Create new LineItem
                        {
                            invokedMethod = 'Create LineItem/Ads';
                            try
                            {
                                List<DART6_LINEITEMSERVICE.LineItem> lstItemResp = lineItemService.createLineItems(new List<DART6_LINEITEMSERVICE.LineItem>{lineItem});
                                if(!lstItemResp.isEmpty()) dfpLineItemResponse = lstItemResp.get(0);
                            }
                            catch(System.CalloutException cex){
                                throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                            }
                        }
                    else // Update LineItem  
                    {
                        invokedMethod = 'Get LineItem/Ads';
                        try
                        {
                            // Before upadate LineItem need to select LineItem from DFP by ID to ensure that 
                            // LineItem already started or not to get the field can't update push to lineItem 
                            // to avoid the error "LineItemError.ALREADY_STARTED @ startDateTime" 
                            lineItem.id = Long.valueOf(dartAds.getAdId());
                            // Get lineItem by ID
                            String querySt =  'WHERE id=' + lineItem.id;
                            
                            DART6_LINEITEMSERVICE.Statement filterItem  = new DART6_LINEITEMSERVICE.Statement();
                            filterItem.query = querySt;
                            DART6_LINEITEMSERVICE.LineItemPage itemPage = lineItemService.getLineItemsByStatement(filterItem);
                            
                            List<DART6_LINEITEMSERVICE.LineItem> lstItemSel = new List<DART6_LINEITEMSERVICE.LineItem>(); 
                            if(itemPage.totalResultSetSize > 0)
                            {
                                for(DART6_LINEITEMSERVICE.LineItem itm : itemPage.results)
                                {
                                    lstItemSel.add(itm);
                                }
                            }
                            DART6_LINEITEMSERVICE.LineItem lineItemSel;
                            if(!lstItemSel.isEmpty()) lineItemSel = lstItemSel.get(0);
							
							//Chr:@update-20-03-2015 #5038
							//always update startDate & endDate of lineItem execpt lineItem that has status = READY
							String lineItemStatus = (lineItemSel != null?lineItemSel.status:'');
							if((lineItemStatus).equals('READY')) lineItem.startDateTime = (lineItemSel != null?lineItemSel.startDateTime:null);
                            
                            
                            
                        }
                        catch(System.CalloutException cex){
                            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                        }
                        
                        invokedMethod = 'Update LineItem/Ads';
                        try
                        {
                            List<DART6_LINEITEMSERVICE.LineItem> listItemsTobeUpdated = lineItemService.updateLineItems(new List<DART6_LINEITEMSERVICE.LineItem>{lineItem});
                            if(!listItemsTobeUpdated.isEmpty())dfpLineItemResponse = listItemsTobeUpdated.get(0);
                            
                        }
                        catch(System.CalloutException cex){
                            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                        }
                    }
                    
                    if(listCrit.size()>0)
                    {
                        ctrl.updateDart6ValueIds();
                    }
                    
                    if(ctrl.isCreateNewKv())
                    {
                        ctrl.createObjectKeyVal();
                    }
                    System.debug('/n/n dfpLineItemResponse: ' + dfpLineItemResponse);
                    
                }
                catch(System.CalloutException cex){
                    throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage())); 
                }   
                catch(Exception ex){
                	System.debug('/n/n getStackTraceString(): ' + ex.getStackTraceString());
                    throw new ExceptionGroup.DARTException('' + ex.getMessage());
                    
                }     
            
        }
        
        public Object getResponseObject()
        {
            return dfpLineItemResponse;
        }
        
    }
    
    /**
     * @description request ot DFP to get Forecast 
     */
    
    public class DFPForecastRequest extends AbstractDFPRequest{
        
        List<String> adIds;
        OpportunityLineItem oppItem;
        
        DARTObject.DARTForecast dartObjForecast;
        
        public DART6_FORECASTSERVICE.AvailabilityForecast forecast;
        
        public DFPForecastRequest(OpportunityLineItem oppItem)
        {
            this.oppItem = oppItem;
        }
        
        public void invoke()
        {
            
            DART6_KeyValueController ctrl;
            List<DART6_FORECASTSERVICE.CustomCriteriaSet> listCrit = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
            
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,oppItem.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405
            //Sochanra 26-04-2016 -> get network timezone from AdserverLogin
      	    String networkTimezone = login.Timezone__c+'';
            DART6_FORECASTSERVICE.SoapRequestHeader header = new DART6_FORECASTSERVICE.SoapRequestHeader();
              
            header.applicationName='ForecastService';
            header.networkCode= login.Network_ID__c;
        
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);
            
            DART6_FORECASTSERVICE.ForecastServiceInterfacePort forecastService = new DART6_FORECASTSERVICE.ForecastServiceInterfacePort();
            if(WS.UseProxy__c) forecastService.endpoint_x = ENDPOINT_RUNSCOPE_PROXY+'ForecastService';
            forecastService.RequestHeader = header;
            forecastService.inputHttpHeaders_x = inputHttpHeaders_x;
            
            if(oppItem != null)
            {
                String strFCErr = '';
                
                    dartObjForecast = new DARTObject.DARTForecast(oppItem);
                    
                    // setDartTime Start
                    DART6_FORECASTSERVICE.Date_x datexStart = new DART6_FORECASTSERVICE.Date_x();
                    datexStart.day = Integer.valueOf(dartObjForecast.getStartDay()+'');
                    datexStart.month = Integer.valueOf(dartObjForecast.getStartMonth()+'');
                    datexStart.year = Integer.valueOf(dartObjForecast.getStartYear()+'');
                    
                    DART6_FORECASTSERVICE.DateTime_x dartTimexStart = new DART6_FORECASTSERVICE.DateTime_x();
                    dartTimexStart.date_x = datexStart;
                    dartTimexStart.hour = 0;
                    dartTimexStart.minute = 0;
                    dartTimexStart.second = 0;
                    dartTimexStart.timeZoneID = networkTimezone;
                    
                    // setDartTime End
                    DART6_FORECASTSERVICE.Date_x datexEnd = new DART6_FORECASTSERVICE.Date_x();
                    datexEnd.day = Integer.valueOf(dartObjForecast.getEndDay()+'');
                    datexEnd.month = Integer.valueOf(dartObjForecast.getEndMonth()+'');
                    datexEnd.year = Integer.valueOf(dartObjForecast.getEndYear()+'');
                    
                    DART6_FORECASTSERVICE.DateTime_x dartTimexEnd = new DART6_FORECASTSERVICE.DateTime_x();
                    dartTimexEnd.date_x = datexEnd;
                    dartTimexEnd.hour = 23;
                    dartTimexEnd.minute = 59;
                    dartTimexEnd.second = 0;
                    dartTimexEnd.timeZoneID = networkTimezone;
                    
                    //Get placement Ids
                    //NK:20/01/2013
                    //If Content.Type__c = “DART – ContentCategory”, it should be mapped to PlacementId
                    //If Content.Type__c = “DART – Site” or “DART – Zone”, it should be mapped to AdUnitId
                     
                    List<Long> placementIds = new List<Long>();
                    
                    //Theany: 2/4/2014: replace getIncludeContentCat with getIncludePlacementTarget
                    //Chr: @updated 28-07-2014: replace object PlacementTargeting__c by use PlacementTargetingDefinition__c instead  
                    //Chr: @updated 20-03-2015: replace object PlacementTargetingDefinition__c by placement__c
                    for(Placement__c pPlacement : dartObjForecast.getIncludePlacementTarget())
		            {
		                if(pPlacement.Dart_Id__c != null) placementIds.add(Long.valueOf(pPlacement.Dart_Id__c+''));
		            }
                    
                    //customTargeting
                    ctrl = new DART6_KeyValueController(oppItem.PricebookEntry.Product2.Site__r.Id, dartObjForecast.getKeyWKV(), authToken, login.Network_ID__c);

                    if(ctrl.isNeedToCreate()) 
                    {
                        ctrl.searchCreateDFPFreeFormValues();
                    }
                    listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>)ctrl.getListDart();
                    
                    
                    
                    //targetedAdUnits 
                    List<DART6_FORECASTSERVICE.AdUnitTargeting> adUnitTargs = new List<DART6_FORECASTSERVICE.AdUnitTargeting>();
                    
                    for(Content__c dartSite : dartObjForecast.getIncludeDartSite())
                    {
                        DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
                        adunit.adUnitId = dartSite.Name;
                        adUnitTargs.add(adunit);
                    }
                    for(Content__c dartZone : dartObjForecast.getIncludeDartZone())
                    {
                        DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
                        adunit.adUnitId = dartZone.Name;
                        adUnitTargs.add(adunit);
                    }
                    
                    //DART6_FORECASTSERVICE.Location
                     List<DART6_FORECASTSERVICE.Location> lstLocations = new List<DART6_FORECASTSERVICE.Location>();
                     
                     for(Geography__c g : dartObjForecast.getIncludeGeography())
                     {
                        DART6_FORECASTSERVICE.Location loc = new DART6_FORECASTSERVICE.Location();
                         loc.id = Long.valueOf(g.Dart_ID__c+''); 
                         loc.type_x = g.Type__c;
                         lstLocations.add(loc); 
                     }
                    
                    for(Region__c rg : dartObjForecast.getIncludeRegions())
                    {
                        DART6_FORECASTSERVICE.Location locRgn = new DART6_FORECASTSERVICE.Location();
                        if(rg.Dart_ID__c != null)
                        {
                            locRgn.id = Long.valueOf(rg.Dart_ID__c+'');
                        }
                        
                        locRgn.type_x = 'RegionLocation';
                        lstLocations.add(locRgn);
                    }
                    
            //DART6_FORECASTSERVICE.GeoTargeting
            DART6_FORECASTSERVICE.GeoTargeting geoTargeting = new DART6_FORECASTSERVICE.GeoTargeting();
            geoTargeting.targetedLocations = lstLocations;          
            
            DART6_FORECASTSERVICE.BandwidthGroupTargeting bandwidthGroupTargeting = null;
            DART6_FORECASTSERVICE.MobileCarrierTargeting mobileCarrierTargeting = null;
            Set<String> bandWidthParentIds = new Set<String>();
            Set<String> mobileCarParentIds = new Set<String>();
            Set<String> connIds = new Set<String>();
            for(Connection__c c : dartObjForecast.getIncludeConnection())
            {

                if(('BandwidthGroup').equals(c.DFP_API_Name__c))
                {
                    bandWidthParentIds.add(c.id);
                }
                else if(('MobileCarrier').equals(c.DFP_API_Name__c))
                {
                    mobileCarParentIds.add(c.id);
                }else connIds.add(c.id);
            }

            Set<String> mcParids = new Set<String>();

            // Bandwidth connection
            List<Connection__c> lstConnBwidth = new List<Connection__c>();

            for(Connection__c c : dartObjForecast.getIncludeConnection())
            {
                if(bandWidthParentIds.contains(c.Node_ID__c))
                {
                    lstConnBwidth.add(c);
                }
                else if(mobileCarParentIds.contains(c.Node_ID__c))
                {
                    mcParids.add(c.Id);
                }
            }

            //MobileCarrier connection
            List<Connection__c> lstMbCar = new List<Connection__c>();
            for(Connection__c c : dartObjForecast.getIncludeConnection())
            {
                if(mcParids.contains(c.Node_ID__c))
                {
                    lstMbCar.add(c);
                }
            }

            DART6_FORECASTSERVICE.Technology[] listBandWidth = new List<DART6_FORECASTSERVICE.Technology>();
            // Bandwidth 
            for(Connection__c con : lstConnBwidth)
            {
                DART6_FORECASTSERVICE.Technology technologyBw = new DART6_FORECASTSERVICE.Technology();
                technologyBw.id = con.Dart_ID__c.longValue();
                listBandWidth.add(technologyBw);
            }

            if(!listBandWidth.isEmpty())
            {
                bandwidthGroupTargeting = new DART6_FORECASTSERVICE.BandwidthGroupTargeting();
                bandwidthGroupTargeting.bandwidthGroups = listBandWidth;
            }

            //MobileCarrier
            DART6_FORECASTSERVICE.Technology[] techMobileCar = new List<DART6_FORECASTSERVICE.Technology>();
            for(Connection__c con : lstMbCar)
            {
                DART6_FORECASTSERVICE.Technology techMb = new DART6_FORECASTSERVICE.Technology();
                techMb.id = con.Dart_ID__c.longValue();
                techMobileCar.add(techMb);
            }

            if(!techMobileCar.isEmpty())
            {
                mobileCarrierTargeting = new DART6_FORECASTSERVICE.MobileCarrierTargeting();
                mobileCarrierTargeting.mobileCarriers = techMobileCar;
            }

            // -------------------------->> Device Targeting <<--------------------------------
            DART6_FORECASTSERVICE.Technology[] listBrowsing = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listBrowsingLang = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listDeviceCap = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listDeviceCategory = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listDeviceManufacturer = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listOpSys = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listOpSysVersion = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listMobileDevice = new List<DART6_FORECASTSERVICE.Technology>();
            DART6_FORECASTSERVICE.Technology[] listMobileDeviceSubMod = new List<DART6_FORECASTSERVICE.Technology>();
            
            //@updated 08-01-2015
            //Use Device category value in Product instead of seleted from targeting tree
           List<String> devCateValue = (dartObjForecast.getDeviceCategory()!=null?dartObjForecast.getDeviceCategory().split(','):new List<String>());
           for(Devices__c dev : DARTUtil.getListDevicesCategory(devCateValue))
           {
           		if(dev.Dart_ID__c !=null){
	           		DART6_FORECASTSERVICE.Technology techDevCate = new DART6_FORECASTSERVICE.Technology();
	                techDevCate.id = dev.Dart_ID__c.longValue();
	                listDeviceCategory.add(techDevCate);
           		}
           }
           
           //Targeting Device from targeting tree
            for(Devices__c d : dartObjForecast.getIncludeDevice())
            {
                if(('Browser').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techBrw = new DART6_FORECASTSERVICE.Technology();
                    techBrw.id = d.Dart_ID__c.longValue();
                    listBrowsing.add(techBrw);
                }
                else if(('BrowserLanguage').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techBrwLang = new DART6_FORECASTSERVICE.Technology();
                    techBrwLang.id = d.Dart_ID__c.longValue();
                    listBrowsingLang.add(techBrwLang);
                }
                else if(('DeviceCapability').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techDevCap = new DART6_FORECASTSERVICE.Technology();
                    techDevCap.id = d.Dart_ID__c.longValue();
                    listDeviceCap.add(techDevCap);
                }
                //else if(('DeviceCategory').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                //{
                //    DART6_FORECASTSERVICE.Technology techDevCate = new DART6_FORECASTSERVICE.Technology();
                //    techDevCate.id = d.Dart_ID__c.longValue();
                //    listDeviceCategory.add(techDevCate);
                //}
                else if(('DeviceManufacturer').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techDevMf = new DART6_FORECASTSERVICE.Technology();
                    techDevMf.id = d.Dart_ID__c.longValue();
                    listDeviceManufacturer.add(techDevMf);
                } 
                else if(('OperatingSystem').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techOs = new DART6_FORECASTSERVICE.Technology();
                    techOs.id = d.Dart_ID__c.longValue();
                    listOpSys.add(techOs);
                }
                else if(('OperatingSystemVersion').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techOsVersion = new DART6_FORECASTSERVICE.Technology();
                    techOsVersion.id = d.Dart_ID__c.longValue();
                    listOpSysVersion.add(techOsVersion);
                }
                
                else if(('MobileDevice').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techMobileDev = new DART6_FORECASTSERVICE.Technology();
                    techMobileDev.id = d.Dart_ID__c.longValue();
                    listMobileDevice.add(techMobileDev);
                }
                else if(('MobileDeviceSubmodel').equals(d.DFP_API_Name__c) && d.Dart_ID__c !=null)
                {
                    DART6_FORECASTSERVICE.Technology techMobileDevSubMd = new DART6_FORECASTSERVICE.Technology();
                    techMobileDevSubMd.id = d.Dart_ID__c.longValue();
                    listMobileDeviceSubMod.add(techMobileDevSubMd);
                }
            }

            // DART6_FORECASTSERVICE.BrowserTargeting
            DART6_FORECASTSERVICE.BrowserTargeting browserTargeting = null;
            if(!listBrowsing.isEmpty())
            {
                browserTargeting = new DART6_FORECASTSERVICE.BrowserTargeting();
                browserTargeting.browsers = listBrowsing;
            }

            // DART6_FORECASTSERVICE.BrowserLanguageTargeting
            DART6_FORECASTSERVICE.BrowserLanguageTargeting browserLanguageTargeting = null;
            if(!listBrowsingLang.isEmpty())
            {
                browserLanguageTargeting = new DART6_FORECASTSERVICE.BrowserLanguageTargeting();
                browserLanguageTargeting.browserLanguages = listBrowsingLang;
            }

            // DART6_FORECASTSERVICE.DeviceCapabilityTargeting
            DART6_FORECASTSERVICE.DeviceCapabilityTargeting deviceCapabilityTargeting = null;
            if(!listDeviceCap.isEmpty())
            {
                deviceCapabilityTargeting = new DART6_FORECASTSERVICE.DeviceCapabilityTargeting();
                deviceCapabilityTargeting.targetedDeviceCapabilities = listDeviceCap;
            }

            //DART6_FORECASTSERVICE.DeviceCategoryTargeting
            DART6_FORECASTSERVICE.DeviceCategoryTargeting deviceCategoryTargeting = null;
            if(!listDeviceCategory.isEmpty())
            {
                deviceCategoryTargeting = new DART6_FORECASTSERVICE.DeviceCategoryTargeting();
                deviceCategoryTargeting.targetedDeviceCategories = listDeviceCategory;
            }

            //DART6_FORECASTSERVICE.DeviceManufacturerTargeting ;
            DART6_FORECASTSERVICE.DeviceManufacturerTargeting deviceManufacturerTargeting = null;
            if(!listDeviceManufacturer.isEmpty())
            {
                deviceManufacturerTargeting = new DART6_FORECASTSERVICE.DeviceManufacturerTargeting();
                deviceManufacturerTargeting.deviceManufacturers = listDeviceManufacturer;
            }

            //DART6_FORECASTSERVICE.OperatingSystemTargeting
            DART6_FORECASTSERVICE.OperatingSystemTargeting OperatingSystemTargeting = null;
            if(!listOpSys.isEmpty())
            {
                OperatingSystemTargeting = new DART6_FORECASTSERVICE.OperatingSystemTargeting();
                OperatingSystemTargeting.operatingSystems = listOpSys;
            }

            //DART6_FORECASTSERVICE.OperatingSystemVersionTargeting
            DART6_FORECASTSERVICE.OperatingSystemVersionTargeting operatingSystemVersionTargeting = null;
            if(!listOpSysVersion.isEmpty())
            {
                operatingSystemVersionTargeting = new DART6_FORECASTSERVICE.OperatingSystemVersionTargeting();
                operatingSystemVersionTargeting.targetedOperatingSystemVersions = listOpSysVersion;
            }
            
            //DART6_FORECASTSERVICE.MobileDeviceTargeting
            DART6_FORECASTSERVICE.MobileDeviceTargeting mobileDeviceTargeting = null;
            if(!listMobileDevice.isEmpty())
            {
                mobileDeviceTargeting = new DART6_FORECASTSERVICE.MobileDeviceTargeting();
                mobileDeviceTargeting.targetedMobileDevices = listMobileDevice;
            }
           
            //DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting
            DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting mobileDeviceSubmodelTargeting = null;
            if(!listMobileDeviceSubMod.isEmpty())
            {
                mobileDeviceSubmodelTargeting = new DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting();
                mobileDeviceSubmodelTargeting.targetedMobileDeviceSubmodels = listMobileDeviceSubMod;
            }
            
            //TechnologyTargeting
            DART6_FORECASTSERVICE.TechnologyTargeting technologyTargeting = new DART6_FORECASTSERVICE.TechnologyTargeting();


            if(browserTargeting!=null)
            {
                technologyTargeting.browserTargeting = browserTargeting;
            }

            if(bandwidthGroupTargeting!=null)
            {
                technologyTargeting.bandwidthGroupTargeting = bandwidthGroupTargeting;
            }

            if(mobileCarrierTargeting!=null)
            {
                technologyTargeting.mobileCarrierTargeting = mobileCarrierTargeting;
            }

            if(browserTargeting!=null)
            {
                technologyTargeting.browserTargeting = browserTargeting;
            } 

            if(browserLanguageTargeting!=null)
            {
                technologyTargeting.browserLanguageTargeting = browserLanguageTargeting;
            }

            if(deviceCapabilityTargeting!=null)
            {
                technologyTargeting.deviceCapabilityTargeting = deviceCapabilityTargeting;
            }

            if(deviceCategoryTargeting!=null)
            {
                technologyTargeting.deviceCategoryTargeting = deviceCategoryTargeting;
            }

            if(deviceManufacturerTargeting!=null)
            {
                technologyTargeting.deviceManufacturerTargeting = deviceManufacturerTargeting;
            } 

            if(OperatingSystemTargeting!=null)
            {
                technologyTargeting.OperatingSystemTargeting = OperatingSystemTargeting; 
            }

            if(operatingSystemVersionTargeting!=null)
            {
                technologyTargeting.operatingSystemVersionTargeting = operatingSystemVersionTargeting; 
            }
            
            if(mobileDeviceTargeting!=null)
            {
                technologyTargeting.mobileDeviceTargeting = mobileDeviceTargeting;
            }  
          
            if(mobileDeviceSubmodelTargeting!=null)
            {
                technologyTargeting.mobileDeviceSubmodelTargeting = mobileDeviceSubmodelTargeting;
            }
                    
                    
			//NK:29/01/2013----------------------------
                    
                    
            //DayPart
            List<DART6_FORECASTSERVICE.DayPart> lstDayParts = new List<DART6_FORECASTSERVICE.DayPart>();
            
            // Day of Week
            //ex: sunday; monday
            //ex: 22:00 - 22:59; 23:00 - 23:59
            //-> sunday: 22:00 - 22:59; 23:00 - 23:59
            //-> monday: 22:00 - 22:59; 23:00 - 23:59
                    
            /*for(String dw : dartObjForecast.getDayOfWeek())
            {

                // Hours of Day
                //(22:00 - 22:59, 23:00 - 23:59,.....)
                //NK:Fixed: 09/02/2013
                String[] hods = dartObjForecast.getHourOfDay();
                hods = !hods.isEmpty()?hods:new String[]{'00:00 - 23:59'}; //all time if time not specified.
                for(String hd : hods)
                {
                    List<String> lsthd = hd.split('-'); // (22:00, 22:59)
                    List<String> lstTimeStart = lsthd[0].split(':'); //(22, 00)
                    List<String> lstTimeEnd = lsthd[1].split(':'); // (22, 59)
                    
                    DART6_FORECASTSERVICE.TimeOfDay startTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay();
                    startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim()+'');
                    startTimeOfDay.minute ='ZERO';// lstTimeStart[1].trim();
                    
                    DART6_FORECASTSERVICE.TimeOfDay endTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay();
                    endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'');
                    endTimeOfDay.minute ='FORTY_FIVE';// lstTimeEnd[1].trim();
                    
                    DART6_FORECASTSERVICE.DayPart dayPart = new DART6_FORECASTSERVICE.DayPart();
                    dayPart.dayOfWeek = dw.toUpperCase();
                    dayPart.startTime = startTimeOfDay;
                    dayPart.endTime = endTimeOfDay;
                    
                    lstDayParts.add(dayPart);
                    
                }
            }*/
            
            // Pheaktra Hun: 31-Aug-2016. For Time Targeting with different hours on different days
            for(DARTObject.DTOTimeTargeting dto : dartObjForecast.getListDTOTimeTargeting() ){
              for(String hour : dto.hours){   // Ex: dto.hours = ('0:00 - 0:59', '1:00 - 1:59')
                List<String> lsthd = hour.split('-'); // (0:00, 0:59)
                    List<String> lstTimeStart = lsthd[0].split(':'); //(0, 00)
                    List<String> lstTimeEnd = lsthd[1].split(':'); // (0, 59)
                
                	DART6_FORECASTSERVICE.TimeOfDay startTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay();
                    startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim()+'');
                    startTimeOfDay.minute ='ZERO'; 
                    
                    DART6_FORECASTSERVICE.TimeOfDay endTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay(); 
                    endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim()+'')+1;
                    endTimeOfDay.minute ='ZERO'; 
                    
                    DART6_FORECASTSERVICE.DayPart dayPart = new DART6_FORECASTSERVICE.DayPart();
                    dayPart.dayOfWeek = dto.day.toUpperCase();
                    dayPart.startTime = startTimeOfDay;
                    dayPart.endTime = endTimeOfDay;
                    
                    lstDayParts.add(dayPart);
              }
            }
                    
                                        
            // Targeting
            DART6_FORECASTSERVICE.Targeting itemTargeting = new DART6_FORECASTSERVICE.Targeting();
            
            // InventoryTargeting
            DART6_FORECASTSERVICE.InventoryTargeting inventoryTargeting = new DART6_FORECASTSERVICE.InventoryTargeting();
            //@updated:Chr - 08-04-2015
            //#5100 - if no placement & predefaulted targeting, available_sites on the product then AdUnit will auto send to DFP as Run of Network
            //Run of Network's id is store in custome object Site__c.Run_of_Network_ID__c 
            if(placementIds.isEmpty() && adUnitTargs.isEmpty()){
            	DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
            	adunit.adUnitId = oppItem.PriceBookEntry.Product2.Site__r.Run_of_Network_ID__c;
				inventoryTargeting.targetedAdUnits = new List<DART6_FORECASTSERVICE.AdUnitTargeting>{adunit};
            }else{
                inventoryTargeting.targetedPlacementIds = placementIds; 
                inventoryTargeting.targetedAdUnits = adUnitTargs;
            }
            itemTargeting.inventoryTargeting  = inventoryTargeting;
            itemTargeting.geoTargeting = geoTargeting;
            
            if(lstDayParts.size() > 0)
            {
                DART6_FORECASTSERVICE.DayPartTargeting dayPartTargeting = new DART6_FORECASTSERVICE.DayPartTargeting();
                dayPartTargeting.dayParts = lstDayParts;
                dayPartTargeting.timeZone = 'BROWSER';
                itemTargeting.dayPartTargeting = dayPartTargeting;
            }
 
	        itemTargeting.technologyTargeting = technologyTargeting;
	        if(listCrit.size()>0)
	        {
	            itemTargeting.customTargeting = listCrit.get(0);
	        }

                //-----------------12-11-2013----------------------------
                List<String> lstAdSlotWH_FORECASTSERVICE = new List<String>();
                List<DART6_FORECASTSERVICE.CreativePlaceholder> listCreativePLC_FORECASTSERVICE = new List<DART6_FORECASTSERVICE.CreativePlaceholder>();               
                
                lstAdSlotWH_FORECASTSERVICE = dartObjForecast.getListAdSlotWH(); // lstAdSlotHW{120x600,160x600};
                //Get native style from custom setting
                Map<String, DART_NativeStylesMapper__c> mNativeStyles = DART_NativeStylesMapper__c.getAll();           
                for (String slotWH_FORECASTSERVICE : lstAdSlotWH_FORECASTSERVICE ){
                    
                    DART6_FORECASTSERVICE.CreativePlaceholder creativePlc = new DART6_FORECASTSERVICE.CreativePlaceholder();
                    
                    DART6Message.setSize(creativePlc, slotWH_FORECASTSERVICE, login.Network_ID__c, mNativeStyles);
                    listCreativePLC_FORECASTSERVICE.add(creativePlc);               
                }   
            	//---------------------12-11-2013----------------------------------                   
                
                  
                DART6_FORECASTSERVICE.LineItem lineItem =  new DART6_FORECASTSERVICE.LineItem();
                //lineItem.lineItemType = 'STANDARD';
                //lineItem.costType = dartObjForecast.getBillingCat();
                //NK:12/03/2013
                lineItem.lineItemType = (dartObjForecast.getBillingCat().equals(BILLING_CATE_FIX_PRICE) || dartObjForecast.getBillingCat().equals('CPD'))?'SPONSORSHIP':'STANDARD';
                lineItem.costType = dartObjForecast.getBillingCat().equals(BILLING_CATE_FIX_PRICE)?'CPD':dartObjForecast.getBillingCat();
    			
                lineItem.startDateTime = dartTimexStart;
                lineItem.endDateTime = dartTimexEnd;
                lineItem.targeting = itemTargeting;
                lineItem.deliveryRateType = 'EVENLY'; // Chr: 29-09-2014: set deliverRateType to EVENLY for all lineItem
                lineItem.creativeRotationType = 'EVENLY';
                String dartProType = dartObjForecast.getDartProductType();
                if( String.isNotEmpty(dartProType) && setProductType.contains(dartProType)) {
                    lineItem.companionDeliveryOption = 'ALL';
                } else{
                    lineItem.roadblockingType = 'ONLY_ONE';
                }  
                
                Date dtFc = date.newinstance(Integer.valueOf(dartObjForecast.getStartYear()+''), Integer.valueOf(dartObjForecast.getStartMonth()+''), Integer.valueOf(dartObjForecast.getStartDay()+''));
                // If line item start date is today then set StartDateTimeType to ONE_HOUR_FROM_NOW
                if(dtFc.isSameDay(System.today()))
                {
                    lineItem.startDateTimeType = 'IMMEDIATELY';
                }
                
                DART6_FORECASTSERVICE.Goal gl = new DART6_FORECASTSERVICE.Goal();
                gl.unitType = ('CPC'.equals(dartObjForecast.getBillingCat())?'CLICKS':'IMPRESSIONS'); 
                if(LINEITEM_TYPE_NETWORK.equals(dartObjForecast.getDartProductType()) || LINEITEM_TYPE_HOUSE.equals(dartObjForecast.getDartProductType()) || LINEITEM_TYPE_SPONSERSHIP.equals(dartObjForecast.getDartProductType()) || dartObjForecast.getBillingCat().equals('CPD'))
                {
                	  gl.unitType = 'IMPRESSIONS';
                      gl.units = 100;
                      lineItem.primaryGoal = gl;
                }
                else
                {
                      gl.units = Long.valueOf(dartObjForecast.getQuantity()+'');
                      lineItem.primaryGoal = gl;
                }
                
                
                if(!''.equals(dartObjForecast.getFCPeriodDart6()))
                {
                    // FrequencyCap
                    DART6_FORECASTSERVICE.FrequencyCap freqCap = new DART6_FORECASTSERVICE.FrequencyCap();
                    freqCap.numTimeUnits = DARTUtil.toInteger(dartObjForecast.getFCAdServedEvery());
                    freqCap.maxImpressions = DARTUtil.toInteger(dartObjForecast.getFCQty());
                    freqCap.timeUnit = MAP_TIME_UNITS.get(dartObjForecast.getFCPeriodDart6()); 
                
                    lineItem.frequencyCaps = new DART6_FORECASTSERVICE.FrequencyCap[]{freqCap};
                }
                
                if (!dartObjForecast.getFrequencyCappings().isEmpty()) {
                	lineItem.frequencyCaps = new List<DART6_FORECASTSERVICE.FrequencyCap>();
                	for (TargetingFrequencyAssociation__c tfa : dartObjForecast.getFrequencyCappings()) {
                		// FrequencyCap
	                    DART6_FORECASTSERVICE.FrequencyCap freqCap = new DART6_FORECASTSERVICE.FrequencyCap();
	                    freqCap.numTimeUnits = DARTUtil.toInteger(tfa.FC_Ad_served_every__c);
	                    freqCap.maxImpressions = DARTUtil.toInteger(tfa.FC_Quantity__c);
	                    freqCap.timeUnit = MAP_TIME_UNITS.get(tfa.FC_Period__c); 
	                    lineItem.frequencyCaps.add(freqCap);
                	}
                }

                // If Advertising_Medium__c.Dart_producttype__c = “companion”
                // => Advertising_Medium__c.DART_MasterSize__c --> size
                //    Advertising_medium__c.DART_CompanionSize__c --> companions
                
                if( String.isNotEmpty(dartProType) && setProductType.contains(dartProType))  //LINEITEM_TYPE_COMPANION
                {
                    List<DART6_FORECASTSERVICE.CreativePlaceholder> lstCpl = new List<DART6_FORECASTSERVICE.CreativePlaceholder>();
                    for(String s: dartObjForecast.getDartMasterSize()){
                        DART6_FORECASTSERVICE.CreativePlaceholder cph = new DART6_FORECASTSERVICE.CreativePlaceholder();
                        
                        DART6Message.setSize(cph, s, login.Network_ID__c, mNativeStyles);
                        
                        List<DART6_FORECASTSERVICE.CreativePlaceholder> lstCompanion = new List<DART6_FORECASTSERVICE.CreativePlaceholder>();
                        for(String cz : dartObjForecast.getDartCompanionSize()) 
                        {
                            DART6_FORECASTSERVICE.CreativePlaceholder comp = new DART6_FORECASTSERVICE.CreativePlaceholder();
                            
                            DART6Message.setSize(comp, cz, login.Network_ID__c, mNativeStyles);
                            lstCompanion.add(comp);
                        }
                        
                        cph.companions = lstCompanion;
                        lstCpl.add(cph);
                    }
                    lineItem.creativePlaceholders = lstCpl;
                    //lineItem.EnvironmentType = 'VIDEO_PLAYER';
                }
                else{
                    lineItem.creativePlaceholders = listCreativePLC_FORECASTSERVICE;
                }

                try{
                	DART6_FORECASTSERVICE.ProspectiveLineItem prospectiveItem = new DART6_FORECASTSERVICE.ProspectiveLineItem();
                	prospectiveItem.LineItem = lineItem;
                	DART6_FORECASTSERVICE.AvailabilityForecastOptions availabilityFcOpt = new DART6_FORECASTSERVICE.AvailabilityForecastOptions();
                	availabilityFcOpt.includeTargetingCriteriaBreakdown = true;
                	availabilityFcOpt.includeContendingLineItems = true;
                	//Get forecast
                    forecast  =  forecastService.getAvailabilityForecast(prospectiveItem, availabilityFcOpt);
                    invokedMethod = 'getForecast';
                   if(listCrit.size()>0){
						ctrl.updateDart6ValueIds();
                   }
                   if(ctrl.isCreateNewKv()){
                        ctrl.createObjectKeyVal();
                   }
                }
                    
                catch(System.CalloutException cex){
                    throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                }   
                catch(Exception ex){
                    throw new ExceptionGroup.DARTException('' + ex.getMessage());
                }   
            }
        }
		
        public Object getResponseObject(){
            return forecast; 
        }
        
    }
    
    /**
     * @description delivery Request
     * AdServer_Login__c login = DARTUtil.getCredential('DART5','UK');
     */
    public class DeliveryRequest extends AbstractDFPRequest{
        private DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService;
        private Long reportjobId;
        private String xmlBody;
        private AdServer_Login__c credential;
        
        public DeliveryRequest(AdServer_Login__c credential, Long reportjobId, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService){
            this.reportjobId = reportjobId;
            this.reportService = reportService;
            this.credential = credential;
        }
        
        /** 
        * Download report from url when running completed
        */
        public void invoke(){ 
            DART6_REPORTSERVICE.ReportDownloadOptions reportOptions = new DART6_REPORTSERVICE.ReportDownloadOptions();
            reportOptions.exportFormat = 'XML';
            reportOptions.includeReportProperties = false;
            reportOptions.includeTotalsRow = false;
            reportOptions.useGzipCompression = false;
            String downloadUrl = reportService.getReportDownloadUrlWithOptions(reportjobId, reportOptions);
            HTTPWrapper.IRequest downloadxmlReq = new DART6Message.DART6ReportDownloadRequest(credential, downloadUrl);
            DART6Message.GenericResponse downloadxmlResponse = new DART6Message.GenericResponse(downloadxmlReq);
            xmlBody = downloadxmlResponse.getResBody(); 
        }

        /**
        * Get XML Boby for passer
        */
        public Object getResponseObject(){
            return xmlBody; 
        }
    }
    
    /**
     * @description request to download report 
     */
    public class DART6ReportDownloadRequest extends AbstractDART6Request{
        
        public DART6ReportDownloadRequest(AdServer_Login__c credential, String url)
        {
            super(credential);
            endPoint = url;
            method = 'GET';
            //new request to download report no need content-type
            //mapHeader.put('Content-type', 'text/xml');
            //constructBody();
        }
        protected override void composeHeader(){ }
        public override void constructBody(){}      
    }
    
    public class DART6TokenRequest extends AbstractDART6Request{
        
        public DART6TokenRequest(AdServer_Login__c credential)
        {
            super(credential);
            endPoint = DARTUtil.CLIENT_AUTH_URL;
            //mapHeader.put('Content-type', 'application/x-www-form-urlencoded');
            //constructBody();
        }
        
        public override void constructBody()
        {
            reqBody = 'service=gam&accountType=GOOGLE&' + 'Email=' + credential.User_Name__c + '&Passwd=' + credential.Password__c;
        }       
    } 
    
    
    
    /*------Add new after remove DART5Message -----*/
    public abstract class AbstractDARTRequest implements HTTPWrapper.IGenericRequest{
        protected String invokedMethod = '';
        
        /** what dart method has been invoked */
        public String getInvokedMethod()
        {
            return invokedMethod;
        }
    }
    
    public abstract class AbstractDART6Request extends AbstractDARTRequest implements HTTPWrapper.IRequest{
        protected Map<String,String> mapHeader;
        protected String reqBody  = '';
        protected String endPoint = '';
        protected String method   = 'POST';

        protected AdServer_Login__c credential;
        
        public AbstractDART6Request(AdServer_Login__c credential){
            this.credential = credential;
            endPoint = credential.Login_URL__c;
            mapHeader = new Map<String,String>();
            composeHeader();
        }
        
        protected virtual void composeHeader()
        {   
            //mapHeader.put('Cookie','');
            //mapHeader.put('Content-type','text/xml');
            //mapHeader.put('Accept-Encoding','gzip, deflate');
            //mapHeader.put('User-Agent','API_VERSION_DARTAPI_13.6.9 JRE_1.6.0_25');
            //String authsss = DARTUtil.composeDigestAuthorizationHeader(credential.User_Name__c,credential.Password__c,'/xmlserver/','POST');
            //mapHeader.put('Authorization',authsss);
        } 
        
        abstract void constructBody();
         
        public String getEndPoint()
        {
            return endPoint;
        }
        public Map<String,String> getHeader()
        {
            return mapHeader;
        }
        public String getBody()
        {
            return reqBody;
        }
        public String getMethod()
        {
            return method;
        } 
    }

    public class GenericResponse extends HTTPWrapper.AbstractResponse{
        
        public GenericResponse(IRequest req)
        { 
            super(req);
            excecute();
        } 
        public override String getMockedBody()
        { 
            return DARTMockUp.generateDart6Response(request);
        }
    }
    
    /** 
     * @createdDate 15-06-2015
     * @description request to DFP to get some fields of lineItem by AdIds
     * 		Start Time --> save in externalFromDate__c
	 *		End Time --> save in externalEndDate__c
	 *		Quantity --> save in externalQuantity__c
	 *		Rate type --> save in externalBillngCategory__c
	 *		Rate --> save in externalSalesPrice__c
     */
     
      public class DFPGetLineItemRequestById extends AbstractDFPRequest{
        
        DART6_LINEITEMSERVICE.LineItem dfpItem;
        OpportunityLineItem item;
        public DFPGetLineItemRequestById(OpportunityLineItem item){
            this.item = item;   
        }
        
        public void invoke()
        {
            
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6,item.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405
        
            DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
            header.applicationName='LineItemService';
            header.networkCode=login.Network_ID__c;
            
            Map<String,String> inputHttpHeaders_x = new Map<String, String>();
            inputHttpHeaders_x.put('Authorization', 'Bearer '+authToken);
            
            DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
            lineItemService.RequestHeader = header;
            lineItemService.timeout_x = 120000;
            lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;
            
            String querySt =  'WHERE Id = ' + item.Ad_Id__c+'';
            
            // Get LineItem
            DART6_LINEITEMSERVICE.Statement filterItem  = new DART6_LINEITEMSERVICE.Statement();
            filterItem.query = querySt;
            List<DART6_LINEITEMSERVICE.LineItem> lstItems = new List<DART6_LINEITEMSERVICE.LineItem>();          
            DART6_LINEITEMSERVICE.LineItemPage itemPage = lineItemService.getLineItemsByStatement(filterItem);
            if (itemPage.totalResultSetSize > 0) {
                for(DART6_LINEITEMSERVICE.LineItem itemRes : itemPage.results ){
                    lstItems.add(itemRes);
                }
            }
            if(!lstItems.isEmpty()) dfpItem = lstItems.get(0);
            invokedMethod = 'getLineItemById';
            
        }
        
        public Object getResponseObject(){
            return dfpItem;
        }
     }
     /**
      * @createdDate: 15-12-2016
      * @return Mapping DFP message & friendly message
      */
     public static Map<String, String> getMapFriendlyMsg() {
        List<DFP_Message_Error__c> allDFPMsgErr = DFP_Message_Error__c.getall().values();
        Map<String, String> mapMsg = new Map<String, String>();
        for (DFP_Message_Error__c cus : allDFPMsgErr) {
            mapMsg.put(cus.DFP_Message__c, cus.Friendly_Message__c);
        }
        return mapMsg;
    }
    
    // Bunhor @21-Feb-17:
    private static void setSize(DART6_FORECASTSERVICE.CreativePlaceholder holder, String adSlot, String networkId,Map<String, DART_NativeStylesMapper__c> mNativeStyleSetting) {
    	DART6_FORECASTSERVICE.Size itemSize = new DART6_FORECASTSERVICE.Size();
    	itemSize.isAspectRatio = false;
    	
    	// Check if Native style
    	if ( !adSlot.replace('x','').trim().isNumeric() ) {
    		DART_NativeStylesMapper__c nativeSetting = mNativeStyleSetting.get(networkId+adSlot);
    		if ( nativeSetting == null || nativeSetting.DART_CreativeTemplateId__c == null ) throw new ExceptionGroup.DARTException('Native Style Configure is required for "' + adSlot + '"');
    		
        	//Native size, which is a function of the how the client renders the creative. This must be used with 1x1 size.
        	holder.creativeSizeType = 'NATIVE';
        	holder.creativeTemplateId = nativeSetting.DART_CreativeTemplateId__c.longValue();
        	itemSize.width = 1;
        	itemSize.height = 1;
    	} else {
            String ww = adSlot.split('x')[0];
            String hh = adSlot.split('x')[1];
            itemSize.width = (('').equals(ww)?0:Integer.valueOf(ww+''));
            itemSize.height = (('').equals(hh)?0:Integer.valueOf(hh+''));
        }
        holder.size = itemSize;
    }
    
    private static void setSize(DART6_LINEITEMSERVICE.CreativePlaceholder holder, String adSlot, String networkId, Map<String, DART_NativeStylesMapper__c> mNativeStyleSetting) {
    	DART6_LINEITEMSERVICE.Size itemSize = new DART6_LINEITEMSERVICE.Size();
    	itemSize.isAspectRatio = false;
    	
    	// Check if Native style
    	if ( !adSlot.replace('x','').trim().isNumeric() ) {
    		DART_NativeStylesMapper__c nativeSetting = mNativeStyleSetting.get(networkId+adSlot);
    		if ( nativeSetting == null || nativeSetting.DART_CreativeTemplateId__c == null ) throw new ExceptionGroup.DARTException('Native Style Configure is required for "' + adSlot + '"');
    		
        	//Native size, which is a function of the how the client renders the creative. This must be used with 1x1 size.
        	holder.creativeSizeType = 'NATIVE';
        	holder.creativeTemplateId = nativeSetting.DART_CreativeTemplateId__c.longValue();
        	itemSize.width = 1;
        	itemSize.height = 1;
    	} else {
            String ww = adSlot.split('x')[0];
            String hh = adSlot.split('x')[1];
            itemSize.width = (('').equals(ww)?0:Integer.valueOf(ww+''));
            itemSize.height = (('').equals(hh)?0:Integer.valueOf(hh+''));
        }
        holder.size = itemSize;
    }
}