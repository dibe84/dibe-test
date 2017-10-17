/**  SFDC - DART mapping 
 
    1- Standard Opportunity
        Opportinity                 <------OrderId(Opt)------------     Order
        |----> LineItem1            <------AdId(*), OrderId(Opt)---     Ad1
        |----> LineItem2            <------AdId(*), OrderId(Opt)---     Ad2
          
    2- Mixed Opportunity
        Opportinity                 <------OrderId(Opt)------------     Order1
        |----> LineItem1            <------AdId(*), OrderId(Opt)---     Ad1.1
        |----> LineItem2            <------AdId(*), OrderId(Opt)---     Ad1.2
        |--> PackageMain            <------OrderId(*)--------------     Order2
        |----> PackageComponent1    <------AdId(*), OrderId(Opt)---     Ad2.1
        |----> PackageComponent2    <------AdId(*), OrderId(Opt)---     Ad2.2
     
    3-  Multi-Package Opportunity (Contains serveral packages)
        Opportunity
        |--> PackageMain1           <------OrderId(*)--------------     Order1
        |----> PackageComponent1.1  <------AdId(*), OrderId(Opt)---     Ad1.1
        |----> PackageComponent1.2  <------AdId(*), OrderId(Opt)---     Ad1.2
        |--> PackageMain2           <------OrderId(*)--------------     Order2
        |----> PackageComponent2.1  <------AdId(*), OrderId(Opt)---     Ad2.1
        |----> PackageComponent2.2  <------AdId(*), OrderId(Opt)---     Ad2.2
        
    4- Multiformat Opportunity
        Opportunity
        |--> LineItem1              <------OrderId(*)--------------     Order1
        |--> LineItem2              <------OrderId(*)--------------     Order2
        |--> LineItem3              <------OrderId(*)--------------     Order3
*/
public with sharing class BookingController{
    // list of order
	List<DARTObject.IDARTObjectOrder> lstOrder;
	// list of lineItem
    List<DARTObject.IDARTObjectAds> lstAds;
    // list of company(advertiser)
    List<DARTObject.IDARTObjectAdvertiser> lstDartAdvertiser;
    // list of existing company(advertiser)
    List<DARTObject.IDARTObjectAdvertiser> lstAdvsExist;
    
    
    Opportunity opp;
    OpportunityLineItem item;
    // dartversion 
    String dartVersion;
    AdServer_Login__c credential;
    // invoking type
    String invokedMethod;
    // related account of opp
    Account[] lstAccs;
   
   
    /** 
     * Contructor 
     * @param Opportunity
     * @param OpportunityLineItem
     */
    public BookingController(Opportunity opp, OpportunityLineItem item)
    {
    	this.opp = opp;
    	this.item = item;
    	
    	dartVersion = item.PricebookEntry.Product2.RecordType.Name;
		credential = DARTUtil.getCredential(dartVersion,item.PriceBookEntry.Product2.Site__r.Country__c);
		lstAccs = [Select id, Name, RecordType.name From Account Where id =: opp.AccountId];

    }
    
    /** 
     * Request to create new Advertiser/Company 
     */
    public void requestCreateAdvertiser()
    { 	
		// Request to Create new Advertiser/Company
		if(lstAccs.size() > 0)
		{
			HTTPWrapper.IGenericRequest dartAdvRequest = FactoryDARTRequest.getInstance().createDartSubmitAdvertiserRequest(credential, item, lstAccs.get(0));
	        DART6Parser.IDartParser dartAdvParser = FactoryParser.getInstance().createAdvertiserParser(lstAccs.get(0), dartVersion);
	        DARTObject.IDARTConnector dartAdvCon = FactoryConnector.getInstance().createConnector(dartVersion, dartAdvRequest, dartAdvParser);
	        dartAdvCon.connect();
	        lstDartAdvertiser = (List<DARTObject.IDARTObjectAdvertiser>) dartAdvCon.getDartObjects();
	        invokedMethod = dartAdvRequest.getInvokedMethod();
	        
	        System.debug('\n\n\n ===============> lstDartAdvertiser: ' + lstDartAdvertiser);
	        
		}
		else{
			throw new ExceptionGroup.DARTException('No related Account for this Opportunity.');
		}
    }
    
    /**
     * This is call to  create order in DFP 
     * @param mapping of Advertiser
     */
    public void processAndSendOrder(Map<String, Advertiser__c> mapAdvertiser)
    {

    	// Request person from dart5
    	// Dart5: UserRoleId=1 => Salesperson
    	// Dart5: UserRoleId=2 => Primary Traficker

		List<DARTObject.DARTPerson> listDartPerson = new List<DARTObject.DARTPerson>();
		Map<String, DARTObject.DARTPerson> mapDartUser = new Map<String, DARTObject.DARTPerson>();
		
    	if(dartVersion.equals(DARTUtil.DART6))
    	{
    		// Request to get User/Traficker ID (DART USER ID) 
	    	HTTPWrapper.IGenericRequest dartListSalesPerson = FactoryDARTRequest.getInstance().createDartSubmitSalePersonRequest('', credential, item, opp);
	        DART6Parser.IDartParser salespersonParser = FactoryParser.getInstance().createSalespersonParser(dartVersion);
	        DARTObject.IDARTConnector personCon = FactoryConnector.getInstance().createConnector(dartVersion, dartListSalesPerson, salespersonParser);
	        personCon.connect();
	        listDartPerson.addAll((List<DARTObject.DARTPerson>)personCon.getDartObjects());
    	}
    	
    	System.debug('=============> listDartPerson:' + listDartPerson);

        List<OpportunityTeamMember> lstOppTeamMember = DARTUtil.getOpportunityTeamMember(opp.id);
    
        for(DARTObject.DARTPerson p : listDartPerson)
        {
          /*if(lstOppTeamMember.size()>0){
            
            if((lstOppTeamMember.get(0).User.Name).equals(p.getDartName()))
            {
              mapDartUser.put(lstOppTeamMember.get(0).User.Name, p);
            }
          }else{
            if((credential.User_Name__c).equals(p.getUserEmail()))
            {
              mapDartUser.put(credential.User_Name__c, p);
            }
          }
          */
          if(UserInfo.getName().equals(p.getDartName()))
          {
          	mapDartUser.put(UserInfo.getName(), p);
          }
          else if((opp.Owner.Name).equals(p.getDartName()))
          {
            mapDartUser.put(opp.Owner.Name, p);
          }
        }
        
        System.debug('===============> mapDartUser: ' + mapDartUser);
       
    	// Order Request 
        HTTPWrapper.IGenericRequest dartSubmitOrderReq = FactoryDARTRequest.getInstance().createDARTSubmitOrderRequest(credential, opp, item, mapDartUser, mapAdvertiser);
        DART6Parser.IDartParser orderParser = FactoryParser.getInstance().createOrderParser(credential, dartVersion, opp);
        DARTObject.IDARTConnector orderCon = FactoryConnector.getInstance().createConnector(dartVersion, dartSubmitOrderReq, orderParser);
        orderCon.connect(); 
        invokedMethod = dartSubmitOrderReq.getInvokedMethod();
        lstOrder = (List<DARTObject.IDARTObjectOrder>)orderCon.getDartObjects();
        
        System.debug('====================> lstOrder: ' + lstOrder);
         
    }
    
   /**
    * Request to get existing order by opportunity's name
    * @return DartObjectOrder
    */ 
   	public List<DARTObject.IDARTObjectOrder> getExistOrder()
    {
    	// 25-07-2014: #3657 - find order before create. if exists, take it, otherwise create new."
        List<DARTObject.IDARTObjectOrder> lstExistOrder = new List<DARTObject.IDARTObjectOrder>();
        if(dartVersion.equals(DARTUtil.DART6))
    	{
	        // Request to getOrder by opp's name
	        HTTPWrapper.IGenericRequest dartGetOrderReq = FactoryDARTRequest.getInstance().createGetOrderRequest(credential, opp, item);
	        DART6Parser.IDartParser orderExtParser = FactoryParser.getInstance().createOrderParser(credential, dartVersion, opp);
	        DARTObject.IDARTConnector orderExtCon = FactoryConnector.getInstance().createConnector(dartVersion, dartGetOrderReq, orderExtParser);
	        orderExtCon.connect(); 
	        invokedMethod = dartGetOrderReq.getInvokedMethod(); 
	        lstExistOrder = (List<DARTObject.IDARTObjectOrder>)orderExtCon.getDartObjects();
	        
	        System.debug('==============>>lstExistOrder:' + lstExistOrder);
    	}
    	return lstExistOrder;
    }
    
   /**
    * This is process to create lineItem in DFP
    * @param dartOrdr object
    * @param mapping of Advertiser 
    */
    public void processAndSendLineItem(DARTObject.IDARTObjectOrder dartOrder, Map<String, Advertiser__c> mapAdvertiser)
    {
       List<DARTObject.IDARTObjectAds> lstExistLineItem = new List<DARTObject.IDARTObjectAds>();
    	
    	if(dartVersion.equals(DARTUtil.DART6) && item.Ad_Id__c == null)
    	{
	    	// Search lineItem before creating
	    	HTTPWrapper.IGenericRequest dartGetLineItemReq = FactoryDARTRequest.getInstance().createGetLineItemRequest(credential, item, dartOrder);
	        DART6Parser.IDartParser getLineItemParser = FactoryParser.getInstance().createAdsParser(credential, dartVersion, item, mapAdvertiser);
	        DARTObject.IDARTConnector getItemCon = FactoryConnector.getInstance().createConnector(dartVersion, dartGetLineItemReq, getLineItemParser);
	        getItemCon.connect();
	        invokedMethod = dartGetLineItemReq.getInvokedMethod();
	        lstExistLineItem = (List<DARTObject.IDARTObjectAds>)getItemCon.getDartObjects();
    	}
    	System.debug('------------------------>>lstExistLineItem:' + lstExistLineItem);
    	
    	if(lstExistLineItem.isEmpty())
    	{
    		// LineItem Request to create
	        HTTPWrapper.IGenericRequest dartSubmitAdsReq = FactoryDARTRequest.getInstance().createDARTSubmitAdsRequest(credential, item, dartOrder);
	        DART6Parser.IDartParser adsParser = FactoryParser.getInstance().createAdsParser(credential, dartVersion, item, mapAdvertiser);
	        DARTObject.IDARTConnector adsCon = FactoryConnector.getInstance().createConnector(dartVersion, dartSubmitAdsReq, adsParser);
	        adsCon.connect();
	        invokedMethod = dartSubmitAdsReq.getInvokedMethod();
	        lstAds = (List<DARTObject.IDARTObjectAds>)adsCon.getDartObjects();
    	}else
    	{
    		lstAds = new List<DARTObject.IDARTObjectAds>();
    		lstAds.AddAll(lstExistLineItem);
    	}
    	
        
        System.debug('=====================> ads: ' + lstAds);
    }
    
    /**
     * This is the process to search Advertiser in DFP by Account's name 
     */
    public void processSearchAdvertiser()
    {
    	HTTPWrapper.IGenericRequest dartAdvRequest = FactoryDARTRequest.getInstance().createDartGetAdvertiserRequest(credential, item, lstAccs.get(0));
        DART6Parser.IDartParser dartAdvParser = FactoryParser.getInstance().createAdvertiserParser(lstAccs.get(0), dartVersion);
        DARTObject.IDARTConnector dartAdvCon = FactoryConnector.getInstance().createConnector(dartVersion, dartAdvRequest, dartAdvParser);
        dartAdvCon.connect();
        lstAdvsExist = (List<DARTObject.IDARTObjectAdvertiser>) dartAdvCon.getDartObjects();
        invokedMethod = dartAdvRequest.getInvokedMethod();
    }
    
    /**
     * @return existing Advertiser
     */
    public List<DARTObject.IDARTObjectAdvertiser> getListAdvertiserExist()
    {
    	return lstAdvsExist;
    }
    
   /**
    * return list of responsed advertiser object after created in DFP
    */
    public List<DARTObject.IDARTObjectAdvertiser> getListAdvertiser()
    {
    	return lstDartAdvertiser;
    }
    
   /**
    * @return list of lineItem responsed after created in DFP
    */
    public List<DARTObject.IDARTObjectAds> getListAds()
    {
    	return lstAds;
    }
    
   /**
    * @return list of order responsed after created in DFP
    */
    public List<DARTObject.IDARTObjectOrder> getListOrder()
    {
    	return lstOrder;
    }
    
   /**
    * @return type of invoking methode, ex: getOrder, createOrder,....
    */
	public String getInvokedMethod() 
	{
		return invokedMethod;
	}
	
	
	
}