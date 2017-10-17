/**
 * Contains related SF & DFP fields
 */
public with sharing class DARTObject {
  
  public DARTObject(){}
  
  public interface IValidator
  {  
    void checkError(Object o);
    List<String> getListError();
    Boolean isError();
    
  }
  
  public interface IDARTConnector
  {
    void connect(); 
    List<IDARTGenericObject> getDartObjects();
    
  }  
  
  public virtual interface IDARTGenericObject
  {
  }
      
  public virtual interface IDARTObject extends IDARTGenericObject
  { 
    String getDartId();
    String getTempId();
    String getDartName();
    
    void setTempId(String tmpId);
    void setDartName(String dartNme);
    void setDartId(String dartId);
    
    String getAssignAdserver();
    void setAssignAdserver(String assAdserver);
    
    String getDartErrMsg();
    void setDartErrMsg(String errMsg);
  }
  
  /** ----------- Advertiser/Company ------------- */
  public interface IDARTObjectAdvertiser extends IDARTObject
  {
    
    String getAccountId();
    String getAccountName();
    String getAccountRectName();
    
  }
  
  /** 
   * Order interface
   */
  public interface IDARTObjectOrder extends IDARTObject
  {

    String getPONumber();
    
    DARTPerson getPrimaryTrafficker();
    DARTPerson getSalepeople();
     
     void setPrimaryTrafficker(DARTPerson trafficker);
     void setSalePeople(DARTPerson speople);
     
     String getOppID();
     String getOppName();
     String getOwnerId();
     
     String getOrderAvertiserId();
     void setAdvertiserId(String advertiserId);
  }
  
  /** 
   * Forecast Interface
   */
  
  public interface IDARTObjectForecast extends IDARTObject
  {
    String getForecastId();
    void setForecastId(String forecastId); 
    
    String getOrderId();
    void setOrderId(String orderId);
    
    String getAvailableUnits();
    void setAvailableUnits(String avalUnit);
    
    String getMatchingUnits();
    void setMatchingUnits(String matchingUnit);
      
    String getShareOfVoice();
  
  }

  /** 
   * Ads(LineItem) interface
   */
  public interface IDARTObjectAds extends IDARTObject
  {
    IDARTObjectOrder getOrder();
    void setOrder(IDARTObjectOrder dartOrder);

    DateTime getStartDateTime();
    DateTime getEndDateTime();
    String getName();
    String getRate();
    String getUnit();
    String getOppItemID();
    String getProductName();
    String getAdId();  
    String getStatus();  
    String getCurrencyCode();
    Integer getPriority();
    String getDartWebPropertyAlias();
    
    //Fields for retrieve from DFP 
    DateTime getExternalFromDate();
   	void setExternalFromDate(DateTime externalFromDate);
   	DateTime getExternalEndDate();
   	void setExternalEndDate(DateTime externalEndDate);
   	Long getExternalQualilty();
   	void setExternalQuality(Long externalQty);
   	String getExternalBillingCategory();
   	void setExternalBillingCategory(String externalBillingCat);
   	Long getExternalSalePrice(); 
   	void setExternalSalePrice(Long externalSalePrice);

  } 
  
  /** 
   * Delivery interface
   */
  public interface IDARTObjectDelivery extends IDARTGenericObject{
    
    Integer getAdDelivered();
    Integer getImpressionsDelivered();
    Integer getAdClickedLifetime();
    Integer getClicksDelivered();
    Double getAdOSI();
    String getAdId();
    String getOrderId();
  }
  
  /** IDARTItem interface */
  
  public interface IDARTItem {
    
    String getProductName();
    String getOppItemID();
    String getStartMonth();
    String getStartDay();
    String getStartYear();
    String getEndMonth();
    String getEndDay();
    String getEndYear();
    String getPackage();
    String getPeriod();
    String getQuantity();
    String getFCQty();
    String getFCAdServedEvery();
    String[] getDayOfWeek();
    String[] getHourOfDay();
    Country__c[] getIncludeCountry();
    City__c[] getIncludeCity();
    AreaCode__c[] getIncludeAreaCode();
    String getOS();
    String getWebBrowser();
    Content__c[] getIncludeDartSite();
    Content__c[] getIncludeDartZone();
    Content__c[] getListContentsTargeting();
    //Content__c[] getIncludeContentCat();
    //Chr-@updated replace object PlacementTargeting__c by use Placement__c instead
    Placement__c[] getIncludePlacementTarget();
    String getKeyWKV();
    String getAdSlotH();
    String getAdSlotW();
    String getBillingCat();
    String getOpportunityId();
    String getMinorVersion();
    String getMajorVersion();
    String getDartProductType();
    String[] getDartCompanionSize();
    String[] getDartMasterSize();
    
    String getLineItemType(); //SUY Sreymol 26/05/2014 : DFP Sync Not Pushing Line Item Type Correctly
    List<String> getListAdSlotWH();
    Geography__c[] getIncludeGeography();
    Devices__c[] getIncludeDevice();
    Connection__c[] getIncludeConnection();
    String getDeviceCategory();
    String getAdOpsComments();
    Content__c[] getPredefinedAdunit();
    String getPredefinedDeviceCategory();
    
  }
  
  
  
  /** Asbstract for all dart controllers*/
  
  public abstract class AbstractDARTController{
    protected String invokedMethod;
    protected List<DARTObject.IDARTGenericObject> listDartObjects;
    
    public virtual List<DARTObject.IDARTGenericObject> getListDart()
    {
      return listDartObjects;
    } 
    
   /**
    * @return invoked mothode(ex: getLineItem, createLineItem,...)
    */
    public String getInvokedMethod()
    {
      return invokedMethod;
    }
  }
  

  /** 
   * Abstract of all DARTObjects with shared properties 
   */
  public abstract class AbsractDARTObject implements IDARTObject{
    String dartId;
    String tempId;
    String dartName;
    String assignAdserver;
    String errMsg;
    
   /**
    * @return dartId
    */
    public String getDartId()
    {
      return dartId;
    }
    
   /**
    * @return temporaryId
    */
    public String getTempId()
    {
      return tempId;
    }
    
   /**
    * @return DartName
    */
    public String getDartName()
    {
      return dartName;
    }
    
    /**
    * @param temporaryId
    */
    public void setTempId(String tmpId)
    {
      tempId = tmpId;
    }
    
   /**
    * @param DartName
    */
    public void setDartName(String dName)
    {
      dartName = dName;
    }
    
   /**
    * @param dartId
    */
    public void setDartId(String dartId)
    {
      this.dartId = dartId;
    }
    
   /**
    * @return assignAdserver
    */
    public String getAssignAdserver()
    {
      return assignAdserver;
    }
    
    /**
     * @param assignAdserver
     */
    public void setAssignAdserver(String assignAdserver)
    {
      this.assignAdserver = assignAdserver;
    }
    
   /**
    * @return error message
    */
    public String getDartErrMsg()
    {
      return errMsg;
    }
    
    /**
     * @param error message
     */
    public void setDartErrMsg(String errMsg)
    {
       this.errMsg = errMsg;
    }
    
  }
  
  /** 
   * Object Order 
   */ 
  public class DARTOrder extends AbsractDARTObject implements IDARTObjectOrder{
     
    Opportunity opp;
    String advertiserId;
    String salepeopleId ;
    
    DARTPerson primaryTrafficker;
    DARTPerson salePeople;
    
    /**
     * constructor
     * @param Opportunity
     */
    public DARTOrder(Opportunity opp)
    { 
      this.opp = opp;
       
    }
    
    /**
     * constructor
     * @param orderId
     * @param advertiserId
     */
    public DARTOrder(String orderId, String advertiserId)
    {
      dartId= orderId;
      this.advertiserId = advertiserId;
    }
    
    /**
     * @return OpportunityId
     */
    public String getOppID()
    {
      return opp.id;
    }
    
    /**
     * @return Opportunity's ownerId
     */
    public String getOwnerId()
    {
        return opp.Owner.id;
    }
    
    /**
     * @return Opportunity's Name
     */
    public String getOppName()
    {
      return opp.Name;
    }
    
    /**
     * @return PO_Number
     * @updated:Chr - 22-05-2015 #5306:  Pass the Salesforce 'I/O Number' into the 'PO Number' field at the Order level in DFP 
     */
    public String getPONumber()
    {
      return opp.IOnumber__c;
    }
    
    /**
     * @return primaryTrafficker
     */
    public DARTPerson getPrimaryTrafficker()
    {
      return primaryTrafficker;
    }
    
    /**
     * @return salepeople
     */
    public DARTPerson getSalepeople()
    {
      return salePeople;
    }
   
    /**
     * @param Order startDate
     */
    public DateTime getDartStartDateTime()
    {
      return opp.CampaignStart__c;
    }
    
    /**
     * @param Order endDate
     */
    public DateTime getDartEndateTime()
    {
      return opp.CampaignEnd__c;
    }
    
    /**
     * @param Order start month
     */
    public String getStartMonth()
    {
      return opp.CampaignStart__c==null?'':opp.CampaignStart__c.month()+'';
    }
    
    /**
     * @param Order start day
     */
    public String getStartDay()
    {
      return opp.CampaignStart__c==null?'':opp.CampaignStart__c.day()+'';
    }
    
    /**
     * @param Order start year
     */
    public String getStartYear()
    {
      return opp.CampaignStart__c==null?'':opp.CampaignStart__c.year()+'';
    }
    
    /**
     * @param Order end month
     */
    public String getEndMonth()
    {
      return opp.CampaignEnd__c==null?'':opp.CampaignEnd__c.month()+'';
    }
    
    /**
     * @param Order end day
     */
    public String getEndDay()
    {
      return opp.CampaignEnd__c==null?'':opp.CampaignEnd__c.day()+'';
    }
    
    /**
     * @param Order end year
     */
    public String getEndYear()
    {
      return opp.CampaignEnd__c==null?'':opp.CampaignEnd__c.year()+'';
    }
    
    /**
     * @param AdvertiserId
     */
    public void setAdvertiserId(String advertiserId)
    {
      this.advertiserId = advertiserId;
    }
    
    /**
     * @return AdvertiserId
     */
    public String getOrderAvertiserId()
    {
        return advertiserId;
    }
    
    /**
     * @param salePeople
     */
    public void setSalepeople(DARTPerson salePeople)
    {
      this.salePeople  = salePeople;
    }
    
    /**
     * @param primaryTarfficker
     */
    public void setPrimaryTrafficker(DARTPerson primaryTrafficker)
    {
      this.primaryTrafficker = primaryTrafficker;
    }
    
  }
      
  /** 
   * Object Advertiser/Company 
   */ 
  public class DARTAdvertiser extends AbsractDARTObject implements IDARTObjectAdvertiser{
    
    Account acc;
    /**
     * constructor
     * @param Account
     */
    public DARTAdvertiser(Account acc)
    {
        this.acc = acc;
    }
    
    /**
     * @return Account's Id
     */
    public String getAccountId()
    {
        return acc.id;
    }
    
    /**
     * @return Account's name
     */
    public String getAccountName()
    {
        return acc.Name;
    }
    
    /**
     * @return Account's recordType
     */
    public String getAccountRectName()
    {
        return acc.RecordType.Name;
    }
  }
  
  
  /**
   * Ads object 
   */
  public class DARTAds extends DARTForecast implements IDARTObjectAds{
    
    IDARTObjectOrder dartOrder;
    /**
     * contructor
     * @param OpportunityLineItem
     */
    public DARTAds(OpportunityLineItem item)
    {
      super(item);
    }
    
    /**
     * @return DartObjectOrder
     */ 
    public IDARTObjectOrder getOrder()
    {
       return dartOrder;
    }
    
    /**
     * @param dartObjectOrder
     */ 
    public void setOrder(IDARTObjectOrder dartOrder)
    {
      this.dartOrder = dartOrder;
    }
    
    /**
     * @return lineItem startDate
     */
    public DateTime getStartDateTime()
    {
        return item.from_Date__c;  
    }
    
   /**
    * @return lineItem endDate
    */
    public DateTime getEndDateTime()
    {
      return item.until_Date__c;
    }
     
     /**
     * @return Name of lineItem
     */
     public String getName()
     {
       return item.UniqueAdName__c;  
     }
     
     /**
     * @return CMP_net_net_net__c(Rate)
     */
     public String getRate()
     {
      // TODO: JvdH check what field should be used here
      
      return item.SalesPriceNet__c*1000000+''; //(item.CPM_net_net_net__c!=null?(item.CPM_net_net_net__c*1000000)+'':'0');      
     }
     
     /**
     * @return lineItem billingCategory
     */
     public String getUnit()
     {
        return item.Billing_category__c+'';
     }
    
    /**
     * @return AdID
     */
    public String getAdId()
    {
        return item.Ad_Id__c;
    }
    
    /**
     * @return status
     */
    public String getStatus()
    {
        return (item.Ad_Id__c==null?'Created':'Updated');
    }
    
    /**
     * @return currencyCode
     */
    public String getCurrencyCode()
    {
        return (UserInfo.isMultiCurrencyOrganization()?item.get('CurrencyIsoCode')+'':UserInfo.getDefaultCurrency());
    }
    
    /**
     * @return lineItem's priority
     */
    public Integer getPriority()
    {   
        return DARTUtil.toInteger(item.PriceBookEntry.Product2.Advertising_Medium__r.Dart_Prio__c);
    } 
    
    /**
     * @return DartWebPropertyAlias
     */
    public String getDartWebPropertyAlias()
    {
        return item.PriceBookEntry.Product2.Advertising_Medium__r.Dart_WebPropertyAlias__c;
    }
    
    //@created date: 15-06-2015
    //@Desc: Additional LineItem's fields properties
   	    private DateTime externalFromDate;
   	    private DateTime externalEndDate;
   	    private Long externalQty;
   	    private String externalBillingCat;
   	    private Long externalSalePrice;
   		
   		/**
   		 * @return DFP's fromDate
   		 */
   		public DateTime getExternalFromDate(){
   			return externalFromDate;
   		}
   		
   		/**
   		 * @param DFP's fromDate 
   		 */
   		public void setExternalFromDate(DateTime externalFromDate){
   			this.externalFromDate = externalFromDate;
   		}
   		
   		/**
   		 * @return LineItem's EndDate 
   		 */
   		public DateTime getExternalEndDate(){
   			return externalEndDate;
   		}
   		
   		/**
   		 * @param LineItem's EndDate 
   		 */
   		public void setExternalEndDate(DateTime externalEndDate){
   			this.externalEndDate = externalEndDate;
   		}
   		
   		/**
   		 * @return LineItem's quantity 
   		 */
   		public Long getExternalQualilty(){
   			return externalQty;
   		}
   		
   		/**
   		 * @param LineItem's quantity 
   		 */
   		public void setExternalQuality(Long externalQty){
   			this.externalQty = externalQty;
   		}
   		
   		/**
   		 * @return LineItem's billingCate 
   		 */
   		public String getExternalBillingCategory(){
   			return externalBillingCat;
   		}
   		
   		/**
   		 * @param LineItem's billingCate 
   		 */
   		public void setExternalBillingCategory(String externalBillingCat){
   			this.externalBillingCat = externalBillingCat;
   		}
   		
   		/**
   		 * @return LineItem's SalePrice 
   		 */
   		public Long getExternalSalePrice(){ 
   			return externalSalePrice;
   		}
   		
   		/**
   		 * @param LineItem's SalePrice 
   		 */
   		public void setExternalSalePrice(Long externalSalePrice){
   			this.externalSalePrice = externalSalePrice;
   		}

  }
  
  /**
   * DFP's user properties
   */
  public class DARTPerson extends AbsractDARTObject{
    
    public DARTPerson(){}
    
      String userEmail;
      
      public String getUserEmail()
      {
        return userEmail;
      }
      public void setUserEmail(String userEmail)
      {
        this.userEmail = userEmail;
      }

  } 
  
  /** 
   * Forecast Object
   */
  
  public virtual class DARTForecast extends AbsractDARTObject implements IDARTItem{
    
    // SUY Sreymol 27/05/2014 : DFP Sync Not Pushing Line Item Type Correctly    
    final Map<String, String> mLineItemTypes = new Map<String, String>{'Standard' => 'STANDARD', 'Sponsorship' => 'SPONSORSHIP', 'Bulk' => 'BULK', 
                                                    'Standard High' => 'STANDARD', 'Standard Normal' => 'STANDARD', 'Standard Low' => 'STANDARD', 
                                                    'Network' => 'NETWORK', 'Price Priority' => 'PRICE_PRIORITY', 'House' => 'HOUSE'};
     
    protected OpportunityLineItem item; 
    /**
     * Forecast constructor
     */
    public DARTForecast(OpportunityLineItem item)
    {
      this.item = item;
    }
    
    /**
     * @return lineItem's Id
     */
    public String getOppItemID()
    {
      return item.ID;
      
    }  
    
    /**
     * @return Opportunity's ID
     */
    public String getOpportunityId()
    {
        return item.OpportunityId;
    }
    
    /**
     * @return Product2's name
     */
    public String getProductName()
    {
      return item.PriceBookEntry.Product2.Name+'';
    }
    
    /**
     * @return start month
     */
    public String getStartMonth()
    {
      return item.from_Date__c==null?'':item.from_Date__c.month()+'';
    }
    
    /**
     * @return start day
     */
    public String getStartDay()
    {
      return item.from_Date__c==null?'':item.from_Date__c.day()+'';
    }
    
    /**
     * @return start year
     */
    public String getStartYear()
    {
      return item.from_Date__c==null?'':item.from_Date__c.year()+'';
    }
    
    /**
     * @return end month
     */
    public String getEndMonth()
    {
      return item.from_Date__c==null?'':item.until_Date__c.month()+'';
    }
    
    /**
     * @return end day
     */
    public String getEndDay()
    {
      return item.from_Date__c==null?'':item.until_Date__c.day()+'';
    }
    
    /**
     * @return end year
     */
    public String getEndYear()
    {
      return item.from_Date__c==null?'':item.until_Date__c.year()+'';
    }
    
    /**
     * @return lineItem's package name
     * JvdH: package removed from OLI...
     */
    public String getPackage()
    {
      return '';
    } 
    
    /**
     * @return lineItem's description
     */
    public String getLineDesc()
    {
      return item.Description==null?'':item.Description+'';
    }
    
    /**
     * @return lineItem's period
     * JvdH: period removed from OLI...
     */
    public String getPeriod()
    {
      return  ''; //item.Period__c==null?'':item.Period__c+'';
    }
    
    /**
     * @return lineItem's quantity
     */
    public String getQuantity()
    {
        Decimal q = item.Quantity;
        //if (item.Billing_Category__c == 'CPM') q *= 1000;
      	return q==null?'':q.intValue()+'';
    }
    
    /**
     * @return FC_Quantity__c
     */    
    public String getFCQty()
    {
      return item.FC_Quantity__c==null?'':item.FC_Quantity__c.intValue()+'';
    }
    
    /**
     * @return FC_Ad_Server_every__c of lineItem
     */
    public String getFCAdServedEvery()
    {
      return item.FC_Ad_served_every__c==null?'':item.FC_Ad_served_every__c.intValue()+'';
    }
    
    /**
     * @return FC_Period__c of lineItem
     */
    public String getFCPeriodDart6()
    {
        return item.FC_Period__c==null?'':item.FC_Period__c;
    }
    
    /**
     * @return list string of Day of Week
     */
    public String[] getDayOfWeek()
    {
      //String[] selectedDays = (item.AdDayOfWeek__c+'').split(';'); //multi-pkl
      return (item.AdDayOfWeek__c==null?new List<String>():item.AdDayOfWeek__c.split(';')); //multi-pkl
    }
    
    /**
     * @return list string of Hour of Day
     */
    public String[] getHourOfDay()
    {
      //String[] selectedHoD = (item.AdHourOfDay__c+'').split(';');
      return (item.AdHourOfDay__c==null?new List<String>():item.AdHourOfDay__c.split(';'));
    }
    
    Country__c[] countries;
    /**
     * @return list of country from targeting of lineItem
     */
    public Country__c[] getIncludeCountry()
    {
      if(item.Targeting__c==null)return new List<Country__c>(); 
       
       if(countries==null)
       {     
         countries = DARTUtil.getListCountries(item.Targeting__c);
       }
       return countries;  
    }
    
    City__c[] cities;
    /**
     * @return list of city from targeting of lineItem
     */
    public City__c[] getIncludeCity()
    {
      if(item.Targeting__c==null)return new List<City__c>(); 
       
       if(cities==null)
       {
         cities = DARTUtil.getListCities(item.Targeting__c);
       }
       return cities;
    }
    
    AreaCode__c[] areas;
    /**
     * @return list of AreaCode from targeting of lineItem
     */
    public AreaCode__c[] getIncludeAreaCode()
    {
      if(item.Targeting__c==null)return new List<AreaCode__c>(); 
      
       if(areas==null)
       {
         areas = DARTUtil.getListAreaCodes(item.Targeting__c);
       }
       return areas; 
    }
    
    Geography__c[] geographies;
    /**
     * @return list of geography from targeting of lineItem
     */
    public Geography__c[] getIncludeGeography()
    {
      if(item.Targeting__c==null) return new List<Geography__c>();
      if(geographies==null)
      {
        geographies = DARTUtil.getListGeographies(item.Targeting__c);
      }
      return geographies;
      
    }
    
    Devices__c[] devices;
    /**
     * @return list of device from targeting of lineItem
     */
    public Devices__c[] getIncludeDevice()
    {
      if(item.Targeting__c==null) return new List<Devices__c>();
      if(devices==null)
      {
        devices = DARTUtil.getListDevices(item.Targeting__c);
      }
      return devices;
    }
    
    TargetingFrequencyAssociation__c[] frequencyCappings;
    /**
     * @return list of TargetingFrequency from targeting of lineItem
     */
    public TargetingFrequencyAssociation__c[] getFrequencyCappings() 
    {
		if(item.Targeting__c==null) return new List<TargetingFrequencyAssociation__c>();
      	if(frequencyCappings==null)
      	{
       		frequencyCappings = DARTUtil.getListFrequencyCappings(item.Targeting__c);
      	}
      	return frequencyCappings;
    }
    
    
    Connection__c[] connections;
    /**
     * @return list of connection from targeting of lineItem
     */
    public Connection__c[] getIncludeConnection()
    {
      if(item.Targeting__c==null) return new List<Connection__c>();
      if(connections==null)
      {
        connections = DARTUtil.getListConnections(item.Targeting__c);
      }
      return connections;
    }
    
    /**
     * @return pick list value of Device category
     */
     public String getDeviceCategory()
     {
     	return item.Device_Targeting__c;
     }
     
     /**
      * @return predefined adunit
      */
     public Content__c[] getPredefinedAdunit(){
     	return DARTUtil.getPredefinedContents(item.Predefined_Adunit__c);
     }
     /**
      * @return predefined device category
      */
      public String getPredefinedDeviceCategory()
     {
     	return item.Predefined_DeviceCategory__c;
     }
     
     /**
      * @ return Ad Ops Comments
      */
      public String getAdOpsComments()
      {
      	return item.AdOpsComments__c;
      }
    
    Region__c[] regions;
    /**
     * @return list of region from targeting of lineItem
     */
    public Region__c[] getIncludeRegions()
    {
        if(item.Targeting__c==null)return new List<Region__c>(); 
       
       if(regions==null)
       {
         regions = DARTUtil.getListRegions(item.Targeting__c);
       }
       return regions; 
    }
    
    /**
     * @return value of Operating System (ex: Window,Machintos,...)
     */
    public String getOS()
    {
      return  (item.AdOperatingSystems__c==null?';':item.AdOperatingSystems__c);//';' will split into zero size
    }
    
    /**
     * @return value of AdWebBrowser(ex: Mozilla,...)
     */
    public String getWebBrowser()
    {
      return (item.AdWebBrowsers__c==null?';':item.AdWebBrowsers__c);//';' will split into zero size
    }
    
    /**
     *
     */ 
    public String getWebBrowerVersion()
    {
      return '';//'(item.AdBrowser_Version__c==null?'':item.AdBrowser_Version__c);
    } 
     
    /**
     *
     */
    public String getWebBrowserSubVersion()
    {
      return '';//' (item.AdBrowser_SubVersion__c==null?'':item.AdBrowser_SubVersion__c);
    } 
    
    /**
     * @return list of content that have type='Dart - Zone' && AvailableSite from product in case fixed_site__c=true
     */ 
    public Content__c[] getIncludeDartSite()
    {
      Content__c[] listCont =  DARTUtil.getListContents(item.Targeting__c, item.PriceBookEntry.Product2Id);
       
       //NK: 28/02/2013: only include the available sites if 'Fixed_Site__c' on product is selected? If it is not selected then it should only pass the selected sites/zones/contentcategory from the tree as above.
       
       if(item.PriceBookEntry.Product2.Fixed_Site__c)
       {
            Content__c[] availSites = DARTUtil.getListAvailSites(item.PriceBookEntry.Product2Id,new Set<String>{'Dart - Zone','Dart - Site'});
            listCont.addAll(availSites);
       }
       
      return listCont;
    }
    
    /**
     * @return list all content that have type='Dart - Zone'
     */
    public Content__c[] getIncludeDartZone()
    {
      return DartUtil.getContentsByTargetType(item.Targeting__c, new List<String>{'Dart - Zone'});
    }
    
    /**Get list of Content in targetingContentAssociation
     * @param targetingId
     * @return list of contents 
     */
     public Content__c[] getListContentsTargeting(){
     	return DARTUtil.getContentsByTargetType(item.Targeting__c, New List<String>{'Dart - Site', 'Dart - Zone', 'Dart - ContentCategory'});
     }
    
    /**
     * Theany: 02/04/2014: replace all using getIncludeContentCat with getIncludePlacementTarget
     * Chr-@updated: 20-03-2015: replace PlacementTargeting__c by Placement__c
     */
    public Placement__c[] getIncludePlacementTarget()
    {
        Placement__c[] placementTargets = DartUtil.getPlacementTargeting(item.Targeting__c);
        return placementTargets;
        
    }
    
    /**
     * @return Opportunity's keyvalue
     */ 
    public String getKeyWKV()
    { 
        String combKVAdkey = '';
        
        String combOperator = item.Keywords_KeyValue_combination__c == null ? 'AND' : item.Keywords_KeyValue_combination__c;
        combOperator = combOperator == 'OR' ? '- OR -' : combOperator;
        
        if (item.KeyValueString__c != null && item.AdKeywords__c != null) combKVAdkey = '('+item.KeyValueString__c + ' '+combOperator+' ' + item.AdKeywords__c+')';
        else if (item.KeyValueString__c != null && item.AdKeywords__c == null) combKVAdkey = item.KeyValueString__c;
        else if (item.KeyValueString__c == null && item.AdKeywords__c != null) combKVAdkey = item.AdKeywords__c;
        return combKVAdkey;
    }
   
    /**
     * #3368: DFP Sync Not Pushing Line Item Type Correctly
     * To push dart ad type to DFP
     * @author SUY Sreymol
     * @createddate : 26 May 2014
     * @return string
     */
    public String getLineItemType() {
        return item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c == null ? '' : (mLineItemTypes.get(item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c) == null ? '' : (mLineItemTypes.get(item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c))) ;
    }
    //------------ 26 May 2014 ---------------------//
    /**
     * AdSlotSize height get from product2.Advertising_Medium__r.DART_AdSlotSize__c
     * ex: 300x600
     * @return the first value befor(x) ex: 300
     */
    public String getAdSlotH()
    {
      String adslot = item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c;
      return (adslot==null?'':adslot.split('x')[1]);
    }
    
    /**
     * AdSlotSize weight get from product2.Advertising_Medium__r.DART_AdSlotSize__c
     * ex: 300x600
     * @return the second value after(x) ex:600 
     */
    public String getAdSlotW()
    {
      String adslot = item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c;
      return (adslot==null?'':adslot.split('x')[0]);
    }
    
    //11-11-2013 
    /**
     * Product AdSlotSize now can be multi-selected value
     * @return list of AdSlotSize including weight & height
     */
    public List<String> getListAdSlotWH(){
        List<String> lstAdSlotWH = new List<String>();
        if(item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c != null){
            lstAdSlotWH= item.PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c.split(';');
        }       
        return lstAdSlotWH; // lstAdSlotH{120x600,160x600,....};
    }

    /**
     * @return lineItem's billingCategory
     */
    public String getBillingCat()
    {
      return (item.Billing_category__c==null?'':item.Billing_category__c);
    }
    
    /**
     * @return value of lineItem's AdBrowsersMinorVersion 
     */
    public String getMinorVersion()
    {
        return item.AdBrowsersMinorVersion__c;
    }
    
    /**
     * @return value of lineItem's AdBrowsersMajorVersion 
     */
    public String getMajorVersion()
    {
        return item.AdBrowsersMajorVersion__c;
    }
    
    /**
     * @return Dart Product type value(starndard, sponsorship,...) 
     */
    public String getDartProductType()
    { 
        return item.PriceBookEntry.Product2.Advertising_Medium__r.Dart_Product_Type__c;
    }
    
    /**
     * @return list of DartCompanionSize, the value splited by (';')
     */
    public String[] getDartCompanionSize()
    {
        String compSize = item.PriceBookEntry.Product2.Advertising_Medium__r.DART_CompanionSize__c;
        return compSize==null?new List<String>():compSize.split(';');
    }
    
    /**
     * @return list of dartMasterSize, the value splited by (';')
     */
    public String[] getDartMasterSize()
    {
        String masterSize=item.PriceBookEntry.Product2.Advertising_Medium__r.DART_MasterSize__c;
        return masterSize==null?new List<String>():masterSize.split(';');
    }
    
    
    String totalUnits;
    /**
     * Properties of Forecast (DART6)
     */
    String availableUnits;
    
    /**
     * @return availableUnits
     */
    public String getAvailableUnits()
    {
      return availableUnits;
    }
    
    /**
     * @param avalUnit
     */
    public void setAvailableUnits(String avalUnit)
    {
      this.availableUnits = avalUnit;
    }
    
    /**
     * @return totalUnits 
     */
    public String getMatchingUnits()
    {
        return totalUnits;
    }
    
    /**
     * @param matchingUnit
     */
    public void setMatchingUnits(String matchingUnit)
    {
        totalUnits = matchingUnit;
    }
    
    /** 
     * @return value of share of voice: availableUnits / matchingUnits * 100 
     */
     public String getShareOfVoice(){
              
          Double totalD = DARTUtil.toDouble(totalUnits);
          if(totalD==0)return ''; 
          
          Double availD = DARTUtil.toDouble(availableUnits);
          
          return Decimal.valueOf(availD/totalD*100).setScale(2)+'';
     }
     
// Pheaktra Hun: 31-Aug-2016. For:  Time targeting with different hours on different days
      public DTOTimeTargeting[] getListDTOTimeTargeting(){
          
          DTOTimeTargeting[] theList = new List<DTOTimeTargeting>(); 
          
          if(item != null){ 
            if(item.DFP_Time_Monday__c != null){
              theList.add( new DTOTimeTargeting('monday', item.DFP_Time_Monday__c ) );
            }
            if(item.DFP_Time_Tuesday__c != null){
              theList.add( new DTOTimeTargeting('tuesday', item.DFP_Time_Tuesday__c ) );
            }
            if(item.DFP_Time_Wednesday__c != null){
              theList.add( new DTOTimeTargeting('wednesday', item.DFP_Time_Wednesday__c ) );
            }
            if(item.DFP_Time_Thursday__c != null){
              theList.add( new DTOTimeTargeting('thursday', item.DFP_Time_Thursday__c ) );
            }
            if(item.DFP_Time_Friday__c != null){
              theList.add( new DTOTimeTargeting('friday', item.DFP_Time_Friday__c ) );
            }
            if(item.DFP_Time_Saturday__c != null){
              theList.add( new DTOTimeTargeting('saturday', item.DFP_Time_Saturday__c ) );
            }
            if(item.DFP_Time_Sunday__c != null){
              theList.add( new DTOTimeTargeting('sunday', item.DFP_Time_Sunday__c ) );
            } 
          }
           
          return theList;
      }
  }
  
  // Pheaktra Hun: 31-Aug-2016. For:  Time targeting with different hours on different days
  public class DTOTimeTargeting{
        public String day;
        public String[] hours = new List<String>(); 
          
      public DTOTimeTargeting(String day, String strHours){
        this.day = day; 
        this.hours = getHours(strHours);
      }
      
      // Ex: strHours = '0:00 - 0:59; 1:00 - 1:59; 2:00 - 2:59; 4:00 - 4:59; 21:00 - 21:59; 22:00 - 22:59'
      //     this method will return  (0:00 - 2:59, 4:00 - 4:59, 21:00 - 22:59 )
      private String[] getHours(String strHours){  
        
        String[] hours = new List<String>();
        for( String h : strHours.split(';') ){  
          if( h.trim() != '' )  hours.add(h.trim()); 
        }
        hours.sort(); 
         
        Map<Integer, String> theMap = new Map<Integer, String>();
        for( String hour : hours ){ 
          Integer h = Integer.valueOf(hour.substring(0,hour.indexOf(':')) );
          
          if( theMap.get(h-1) == null ){
            theMap.put(h, hour);
          }else{
            String startHour = theMap.get(h-1).split('-')[0];
            String endHour = hour.split('-')[1];
            theMap.remove(h-1);
            theMap.put(h, startHour + ' - ' + endHour);
          }
        }
         
        return theMap.values();
      } 
      
  }
  
  
  
  /** 
   * DARTDelivery Object 
   * Trying to reduce the script statement to the minimum to ensure that US, 40K Monthly is feasible
   */
  
  public class DARTDelivery  implements IDARTObjectDelivery{
    
    //constructor
    public DARTDelivery()
    {
    }
     public Map<Object,Object> mapRecord;
      /**
       * @param mapRecord
       */
      public DARTDelivery(Map<Object,Object> mapRecord)
      {
        this.mapRecord = mapRecord;
      }
      
      /**
       * @return value of AdDelivered from DFP's report
       */
      public Integer getAdDelivered()
      {
        return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_ADDELIVERED)+'');
      }
      
      /**
       * @return value of ImpressionDelivered from DFP's report
       */
      public Integer getImpressionsDelivered()
      {
        return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_IMPRESS_DELIVERED)+'');
      }
      
      /**
       * @return value of ImpressionDelivered from DFP's report
       */
      public Integer getAdClickedLifetime()
      {
        return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_ADCLICKED_LIFETIME)+'');
      }
      
      /**
       * @return value of ImpressionDelivered from DFP's report
       */
      public Integer getClicksDelivered()
      {
        return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_CLICKS_DELIVERED)+'');
      }
      
      /**
       * @return value of AdOSI from DFP's report
       */
      public Double getAdOSI()
      {
        return DARTUtil.toDouble(mapRecord.get(DEL_FIELD_ADOSI)+'');
      }
      
      /**
       * @return value of ImpressionDelivered from DFP's report
       */
      public String getAdId()
      {
        return mapRecord.get(DEL_FIELD_ADID)+'';
      }
      
      /**
       * @return value of ImpressionDelivered from DFP's report
       */
      public String getOrderId()
      {
        return mapRecord.get(DEL_FIELD_ORDERID)+'';
      }
      
      /**
       * @return Object by column(report's field name)
       */
      public Object getValue(String colname)
      {
        return mapRecord.get(colname);
      }
      
      /**
       * @return delivery report date
       */
      public String getDateString()
      {
        return mapRecord.get(DEL_FIELD_DATE_OR_MONTH) + '';
      }
      
      /**
       * @return AdActiveViewViewableImpression
       */
       public Integer getAdActiveViewViewableImpression()
       {
        	return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS) + '');
       }
       
       /**
       * @return AdActiveViewMeasurableImpression
       */
       public Integer getAdActiveViewMeasurableImpression()
       {
        	return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_AD_ACTIVE_VIEW_MEASURABLE_IMPRESSIONS) + '');
       }
       
       /**
       * @return AdActiveViewMeasurableImpression
       */
       public Double getAdActiveViewViewableImpressionRate()
       {
        	return DARTUtil.toDouble(mapRecord.get(DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS_RATE) + '');
       }
  }
  
   public final static String BILLING_CPM = 'CPM';
   public final static String BILLING_CPC = 'CPC';
   public final static String BILLING_CPD = 'CPD';
  
   public final static String DEL_FIELD_ADDELIVERED = 'AdDeliveredLifetime';// lineitemLifetimeXfpImpressions
   public final static String DEL_FIELD_ADCLICKED_LIFETIME = 'AdClickedLifetime';//lineitemLifetimeXfpClicks
   
   public final static String DEL_FIELD_ADOSI = 'AdOSI';//mergeLineItemDeliveryIndicator                  //OSI (Lifetime)
   public final static String DEL_FIELD_ADID = 'AdId';//lineItemId  
   public final static String DEL_FIELD_ORDERID = 'CampaignId';//orderId
   public final static String DEL_FIELD_IMPRESS_DELIVERED = 'ImpressionsDelivered';//mergeReservationImpressionsDelivered  //   Impressions Delivered  
   public final static String DEL_FIELD_CLICKS_DELIVERED = 'ClicksDelivered';//mergeReservationClicksDelivered      //   Clicks Recorded 
   public final static String DEL_FIELD_DATE_OR_MONTH = 'dateormonth'; // date for RSD and month for RS
   
   //Chr: 22-08-2016 add other three columns for the import delviery
   public final static String DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS = 'AdActiveViewViewableImpression';
   public final static String DEL_FIELD_AD_ACTIVE_VIEW_MEASURABLE_IMPRESSIONS = 'AdActiveViewMeasurableImpression';
   public final static String DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS_RATE = 'AdActiveViewViewableImpressionRate';
   
   //For Adx import
   public final static String ADX_FIELD_LEVEL_IMPRESSION = 'AdxImpression'; //adxReservationImpressionsDelivered
   public final static String ADX_FIELD_LEVEL_CLICK = 'AdxClick'; // adxReservationClicksDelivered
   public final static String ADX_FIELD_LEVEL_REVENUE = 'AdxRevenue'; // adxReservationPubCostDelivered
   
  /** 
   * Adx interface
   */
  public interface IDARTObjectAdx extends IDARTGenericObject{
    
    Integer getAdxImpression();
    Integer getAdxClick();
    Double getAdxRevenue();
    String getAdId();
    String getOrderId();
  }
  
  public class DARTAdxImport  implements IDARTObjectAdx{
  	
	    //constructor
	    public DARTAdxImport(){
	    }
	    
	    public Map<Object,Object> mapRecord;
	      
	      /**
	       * @param mapRecord
	       */
	      public DARTAdxImport(Map<Object,Object> mapRecord)
	      {
	        this.mapRecord = mapRecord;
	      }
	      
	      /**
	       * @return value of Adx Impression from DFP's report
	       */
	      public Integer getAdxImpression()
	      {
	        return DARTUtil.toInteger((mapRecord.get(ADX_FIELD_LEVEL_IMPRESSION)+'').replace(',', '').replace('.', ''));
	      }
	      
	      /**
	       * @return value of Adx Click from DFP's report
	       */
	      public Integer getAdxClick()
	      {
	        return DARTUtil.toInteger((mapRecord.get(ADX_FIELD_LEVEL_CLICK)+'').replace(',', '').replace('.', ''));
	      }
	      
	      /**
	       * @return value of AdxRevenue from DFP's report
	       */
	      public Double getAdxRevenue()
	      {
	        return Double.valueOf(mapRecord.get(ADX_FIELD_LEVEL_REVENUE)+'');
	      }
	      
	      /**
	       * @return value of ImpressionDelivered from DFP's report
	       */
	      public String getAdId()
	      {
	        return mapRecord.get(DEL_FIELD_ADID)+'';
	      }
	      
	      /**
	       * @return value of ImpressionDelivered from DFP's report
	       */
	      public String getOrderId()
	      {
	        return mapRecord.get(DEL_FIELD_ORDERID)+'';
	      }
	      
	      /**
	       * @return Object by column(report's field name)
	       */
	      public Object getValue(String colname)
	      {
	        return mapRecord.get(colname);
	      }
	      
	      /**
	       * @return delivery report date
	       */
	      public String getDateString()
	      {
	        return mapRecord.get(DEL_FIELD_DATE_OR_MONTH) + '';
	      }
  	}	
  
}