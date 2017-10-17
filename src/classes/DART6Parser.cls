/** 
 * All Parsers for DFP
 */  
public with sharing class DART6Parser {
	
	public DART6Parser(){}
	
	public virtual interface IDartParser
    {
		void parse();
        List<DARTObject.IDARTGenericObject> getListDartObject();
    } 
    
	public interface IDART6Parser extends IDartParser 
	{ 
		void setObjectDFP(Object dfpObject);
	} 
	 
	/**
	 * Company parser
	 * Parse response object from DFP to apex DARTObject[]	
	 */ 
	public class DFPResponseToCompanyParser implements IDART6Parser{
		
		List<DARTObject.IDARTObjectAdvertiser> lstDartCom;
		List<DART6_COMPANYSERVICE.Company> coms;
		Account acc;
		
		public DFPResponseToCompanyParser(Account acc)
		{
			this.acc = acc;
		}
		
		public void setObjectDFP(Object dfpObject)
		{
			this.coms = (List<DART6_COMPANYSERVICE.Company>)dfpObject;
		}
		
		public void parse()
		{
			lstDartCom = new List<DARTObject.IDARTObjectAdvertiser>();
			
			
			for(DART6_COMPANYSERVICE.Company com : coms)
			{
				DARTObject.DARTAdvertiser drtAdv = new DARTObject.DARTAdvertiser(acc);
				drtAdv.setDartId(com.id+'');
				lstDartCom.add(drtAdv);
			}
			
		} 
		
		public List<DARTObject.IDARTObject> getListDartObject()
		{
			return lstDartCom;
		}
		
	}
	
	
	/**
	 * Order parser
	 * Parse response object from WSDL ivoked to apex DARTObject	
	 */
	public class DFPResponseToOrderParser implements IDART6Parser{
	 	
	 	List<DARTObject.IDARTObjectOrder> listOrder;
	 	DART6_ORDERSERVICE.Order objOrder;
	 	Opportunity opp;
	 	AdServer_Login__c credential;
	 	
	 	// Constructor 
		public DFPResponseToOrderParser(Opportunity opp, AdServer_Login__c credential)
		{
			  this.opp = opp; 
			  this.credential = credential;
		}
		
		public void setObjectDFP(Object dfpObject)
		{	
			this.objOrder = (DART6_ORDERSERVICE.Order)dfpObject;
		}
		
		public void parse()
		{
			listOrder = new List<DARTObject.IDARTObjectOrder>();
			DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(opp);
			
			if(objOrder != null)
			{
				dartOrder.setDartId(objOrder.id+'');
				dartOrder.setAdvertiserId(objOrder.advertiserId+'');
				dartOrder.setAssignAdserver(credential.Name+' ('+credential.User_Name__c+')');
				listOrder.add(dartOrder);
			}
		}
		
		public List<DARTObject.IDARTObject> getListDartObject()
		{
			return listOrder;
		}
	}
	
	
	
   /**
	* User parser
	* Parse response object from WSDL ivoked to apex DARTObject	
	*/
	public class DFPResponseToSalespersonParser implements IDART6Parser{
	 	 
	 	List<DART6_USERSERVICE.User_x> objUsers;
	 	
	 	List<DARTObject.DARTPerson> listSalesperson;
	 	
	 	
	 	// Constructor 
		public DFPResponseToSalespersonParser()
		{
			   
		}
		
		public void setObjectDFP(Object dfpObject)
		{
			this.objUsers  = (List<DART6_USERSERVICE.User_x>)dfpObject;
		}
		
		public void parse()
		{
			
			System.debug('-----------------> objUser: ' + objUsers);
			
		    listSalesperson =  new List<DARTObject.DARTPerson>();
	    	
	    	for(DART6_USERSERVICE.User_x u: objUsers)
	    	{
	    		DARTObject.DARTPerson objSalesp = new DARTObject.DARTPerson();
	    		objSalesp.setDartId(u.id+'');
		    	objSalesp.setDartName(u.name);
		    	objSalesp.setUserEmail(u.email);
		    	listSalesperson.add(objSalesp);
		    
	    	}
	    	
		}    
		
		public List<DARTObject.IDARTObject> getListDartObject()
		{
			
			return listSalesperson;
		} 
		
	}
	
	/**
	 * Availability Forecast
	 * Parse response object from WSDL ivoked to apex DARTObject	
	 */
	public class DFPResponseToForecastParser implements IDART6Parser{

	 	List<DARTObject.DARTForecast> listForecast;
	 	DART6_FORECASTSERVICE.AvailabilityForecast forecast;
	 	OpportunityLineItem item;
	 	
	 	/** Constructor */
		public DFPResponseToForecastParser(OpportunityLineItem item){
			this.item = item;   
		}
		
		public void setObjectDFP(Object dfpObject){
			this.forecast  = (DART6_FORECASTSERVICE.AvailabilityForecast)dfpObject;
		}
		
		public void parse()
		{

		    listForecast =  new List<DARTObject.DARTForecast>();
	    	DARTObject.DARTForecast objForecast = new DARTObject.DARTForecast(item);
	    	objForecast.setAvailableUnits(forecast.availableUnits==null?'':String.valueOf(forecast.availableUnits));
	    	objForecast.setMatchingUnits(forecast.matchedUnits==null?'':String.valueOf(forecast.matchedUnits));
	    	listForecast.add(objForecast);
	    	System.debug('---------------->forecast:'+forecast);
		}    
		
		public List<DARTObject.DARTForecast> getListDartObject(){
			return listForecast;
		} 		
	}
	
	
	/**
	 * Ads parser
	 * Parse response object from WSDL ivoked to apex DARTObject	
	 */
	 public class DFPResponseToAdsParser implements IDART6Parser{
	 	
	 	List<DARTObject.IDARTObject> lstDartObjects;
	 	List<DARTObject.DARTAds> lstAds;
	 	
	 	OpportunityLineItem item;
	 	AdServer_Login__c credential;
	 	Map<String, Advertiser__c> mapAdvertiser;
	 	
	 	DART6_LINEITEMSERVICE.LineItem lineItem;
	 	
	 	
	 	// Constructor
		public DFPResponseToAdsParser(OpportunityLineItem item, AdServer_Login__c credential, Map<String, Advertiser__c> mapAdvertiser)
		{
			this.item = item;
			this.credential = credential;
			this.mapAdvertiser = mapAdvertiser;
			
		}
		
		public void setObjectDFP(Object dfpObject)
		{
			this.lineItem  = (DART6_LINEITEMSERVICE.LineItem)dfpObject;
		}
		
		public void parse()
		{
			lstAds = new List<DARTObject.DARTAds>();
			String dartVer = item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c;
			DARTObject.DARTAds objAds = new DARTObject.DARTAds(item);
			objAds.setDartId(lineItem != null ? lineItem.id+'' : '');
			objAds.setOrder(new DARTObject.DARTOrder(lineItem != null?lineItem.orderId+'':'', (mapAdvertiser.get(dartVer)!=null?mapAdvertiser.get(dartVer).Dart6_Advertiser_Id__c:'')));
			objAds.setAssignAdserver(credential.Name+' ('+credential.User_Name__c+')');
			if(lineItem!=null) lstAds.add(objAds);

		} 
		
		public List<DARTObject.IDARTObject> getListDartObject()
		{
			
			return lstAds;
		}
		
	}
	
	 
	/**
	 * Delivery parser, dart6 and dart5 are simlilar but to reduce script statement we need to create the new Parser
	 */
	public class Xml6ToDeliveryParser implements IDART6Parser{
		
		protected List<DARTObject.IDARTGenericObject> listDeliveries; 
        protected String xmlRes;
        protected String sobjType;
        protected DartResponseMsg deliveryResponse;
		 
	 	Integer[] gNums = new Integer[9];
		public Xml6ToDeliveryParser(String sobjType){
			if(sobjType == DeliveryController.SOBJECT_OPPPRODUCT){ 
				/* NK:02/04/2013: Obsoleted. switched to xmlNode
				dartXMLQueryResPattern ='<Row rowNum=\'.*?\'>'+
				'<Column name=\'orderId\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'lineItemId\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'lineitemLifetimeMergedImpressions\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'lineitemLifetimeMergedClicks\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'mergeLineItemDeliveryIndicator\'><Val>(.*?)</Val></Column>'+ 
				'</Row>';*/ 
				
				
				gNums[0] = 0; //orderId
				gNums[1] = 1; //lineItemId
				gNums[2] = 2; //lineitemLifetimeMergedImpressions //totalReservationImpressionsDelivered
				gNums[3] = 3; //lineitemLifetimeMergedClicks // totalReservationClicksDelivered
				gNums[4] = 4; //mergeLineItemDeliveryIndicator
				gNums[5] = 2; //lineitemLifetimeMergedImpressions
				gNums[6] = 3; //lineitemLifetimeMergedClicks
				gNums[7] = -1; //""
				gNums[8] = -1; //""

				
			}else if(sobjType == DeliveryController.SOBJECT_METRIC){
				/* NK:02/04/2013: Obsoleted. switched to xmlNode
				dartXMLQueryResPattern ='<Row rowNum=\'.*?\'>'+
				'<Column name=\'orderId\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'lineItemId\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'date\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'mergeReservationImpressionsDelivered\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'mergeLineItemDeliveryIndicator\'><Val>(.*?)</Val></Column>'+ 
				'<Column name=\'mergeReservationClicksDelivered\'><Val>(.*?)</Val></Column>'+ 
				'</Row>';*/

				gNums[0] = 0; //orderId
				gNums[1] = 1; //lineItemId
				gNums[2] = 7; //activeViewAdServerMeasurableImpressions
				gNums[3] = 6; //activeViewAdServerViewableImpressions
				gNums[4] = 3; //lineItemDeliveryIndicator
				gNums[5] = 4; //totalReservationImpressionsDelivered
				gNums[6] = 5; //totalReservationClicksDelivered
				gNums[7] = 2; //date
				gNums[8] = 8; //activeViewAdServerViewableImpressionsRate
				
				
			}else if(sobjType == DeliveryController.SOBJECT_REVENUE_ITEM){
				/* NK:02/04/2013: Obsoleted. switched to xmlNode
				dartXMLQueryResPattern ='<Row rowNum=\'.*?\'>'+
				'<Column name=\'orderId\'><Val>(.*?)</Val></Column>'+
				'<Column name=\'lineItemId\'><Val>(.*?)</Val></Column>'+
				'<Column name=\'month\'><Val>(.*?)</Val></Column>'+
				'<Column name=\'mergeReservationImpressionsDelivered\'><Val>(.*?)</Val></Column>'+
				'<Column name=\'mergeLineItemDeliveryIndicator\'><Val>(.*?)</Val></Column>'+
				'<Column name=\'mergeReservationClicksDelivered\'><Val>(.*?)</Val></Column>'+
				'</Row>';*/
				
				gNums[0] = 0; //orderId
				gNums[1] = 1; //lineItemId
				gNums[2] = 6; //activeViewAdServerMeasurableImpressions
				gNums[3] = 5; //activeViewAdServerViewableImpressions
				gNums[4] = 4; //lineItemDeliveryIndicator
				gNums[5] = 2; //lineitemLifetimeXfpImpressions
				gNums[6] = 3; //lineitemLifetimeXfpClicks
				gNums[7] = -1; //date
				gNums[8] = 7; //activeViewAdServerViewableImpressionsRate

			}
		} 
		
		
 		private void doExtract()
	 	{
	 		//try{
	 			//System.debug('>>>>>>>>>>>>>>>>xmlRes 3/4/13 MM/DD/YY' + xmlRes);
	 			//Document dCov=new Document(Body=Blob.valueOf(xmlRes), Name='AdxImport'+System.today(), Type=' Temporary Document', ContentType='txt',FolderId=Userinfo.getUserId());
    			//insert dCov;
    			//dCov = null; // same mem
	 		//}catch(Exception e){}

	 		     //Integer i = 0;
	 		     
 		    //DEL_FIELD_ADDELIVERED => lineitemLifetimeMergedImpressions, mergeReservationImpressionsDelivered, mergeReservationImpressionsDelivered 
			//DEL_FIELD_ADCLICKED_LIFETIME => lineitemLifetimeMergedClicks, mergeReservationClicksDelivered, mergeReservationClicksDelivered
			//DEL_FIELD_ADOSI => mergeLineItemDeliveryIndicator, mergeLineItemDeliveryIndicator, mergeLineItemDeliveryIndicator
			//DEL_FIELD_ADID => lineItemId, lineItemId, lineItemId
			//DEL_FIELD_ORDERID => orderId, orderId, orderId
			//DEL_FIELD_IMPRESS_DELIVERED => lineitemLifetimeMergedImpressions, mergeReservationImpressionsDelivered, mergeReservationImpressionsDelivered
			//DEL_FIELD_CLICKS_DELIVERED => lineitemLifetimeMergedClicks, mergeReservationClicksDelivered, mergeReservationClicksDelivered
			//DEL_FIELD_DATE_OR_MONTH => '', date, month
	 		//NK: 01/03/2013: for xml doc: regex is too limited. can process more than 2k rows			 
			deliveryResponse.doc.getRootElement(); //Report-->ReportData-->DataSet-->Row-->Column
			DOM.XMLNode node = deliveryResponse.doc.getRootElement();
			try{
				 	for(Dom.XMLNode child: node.getChildElements()){
						if(child.getName().equals('ReportData')){
	   						for(Dom.XMLNode child2: child.getChildElements()){
	   							if(child2.getName().equals('DataSet')){
						        	for(Dom.XMLNode child3: child2.getChildElements()){
						        		if(child3.getName().equals('Row')) {
						        				List<Dom.XmlNode> lstChilds = child3.getChildElements();
								 			listDeliveries.add(	new DARTObject.DARTDelivery(
										   		new Map<Object,Object>
											   			{	
												   			DARTObject.DEL_FIELD_AD_ACTIVE_VIEW_MEASURABLE_IMPRESSIONS => getChildValue(lstChilds,gNums[2]) ,
												   			DARTObject.DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS => getChildValue(lstChilds,gNums[3]),
												   			DARTObject.DEL_FIELD_ADOSI => getChildValue(lstChilds,gNums[4]), 
												   			DARTObject.DEL_FIELD_ADID => getChildValue(lstChilds,gNums[1]),
												   			DARTObject.DEL_FIELD_ORDERID => getChildValue(lstChilds,gNums[0]),
												   			DARTObject.DEL_FIELD_IMPRESS_DELIVERED => getChildValue(lstChilds,gNums[5]),
												   			DARTObject.DEL_FIELD_CLICKS_DELIVERED => getChildValue(lstChilds,gNums[6]),
											   				DARTObject.DEL_FIELD_DATE_OR_MONTH => gNums[7] == -1 ? '' : getChildValue(lstChilds,gNums[7]),
											   				DARTObject.DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS_RATE => gNums[8] == -1 ? '' : getChildValue(lstChilds,gNums[8])
											   			}
									   			)
											);
				 						}
						        	}
						        }
	   						}
	   					}
					}   
					node = null;  
			}catch(Exception ex){
				throw new ExceptionGroup.ParserException(ex.getMessage());
			}
		}
		
		private String getChildValue(List<Dom.XmlNode> lstChilds, Integer index) {
			if(lstChilds.isEmpty() || ( (lstChilds.size()-1) < index)) return '';
			return lstChilds.get(index).getChildElements()[0].getText().replace('%', '').replace(',', '');
		}
		
		public void parse()
        {
        	
        	listDeliveries = new  List<DARTObject.DARTDelivery>();
            deliveryResponse = new DartResponseMsg(xmlRes);
            
            String availImpress='';
            if(deliveryResponse.isError)
            {   
                throw new ExceptionGroup.DARTException(deliveryResponse.errMsg);
            }
            else
            {
	        	try
	        	{
	        		doExtract();
	                deliveryResponse = null;
	        	}
	        	catch(Exception ex)
	        	{
	        		throw new ExceptionGroup.ParserException(ex.getMessage());
	        	}
            }
        	
        }
        
		public List<DARTObject.IDARTGenericObject> getListDartObject()
        { 
            return  listDeliveries;
        } 
			
		public void setObjectDFP(Object dfpObject){xmlRes = dfpObject +'';}
		
	}
	
	
	/** prepare the dart response message */
    public class DartResponseMsg{
        public Boolean isError {get;set;}
        public DOM.Document doc {get;set;}
        public String errMsg;

        /** constructor */
        public DartResponseMsg(String xmlRes)
        {       
            isError = false;
            doc = new DOM.Document();
            doc.load(xmlRes);    
            DOM.XMLNode node = doc.getRootElement();
            
            if(node.getName().equals('Errors') || node.getName().equals('Error'))
            {
                isError = true;
                errMsg = getStringErrors(node);
            } 
        }
        private String getStringErrors(DOM.XMLNode node) 
        {
              String result = '';
              if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) 
              {
                    if (node.getAttributeCount() > 0) 
                    { 
                        for (Integer i = 0; i< node.getAttributeCount(); i++ ) 
                        {
                            if(node.getAttributeKeyAt(i).equals('message'))
                            {   
                                result +=  node.getName() + '<br/>' +node.getAttribute('message', null)+ '<br/>';
                            }
                        }
                    }else{
                    	for (Dom.XMLNode child: node.getChildElements()){
	                		if(child.getName().equals('Message')){
	                			if (child.getNodeType() == DOM.XMLNodeType.ELEMENT){
	                                result = child.getText();
	                			}
	            			}
	                	}
                    }
                    for (Dom.XMLNode child: node.getChildElements()) 
                    {
                        result += getStringErrors(child);
                    }
                    return result;
              }
          return '';  //should never reach here
        
        }
        
    }
    
    /**
     * @created 15-06-2015
	 * Get additional fields from DFP
	 * Parse response object from WSDL ivoked to apex DARTObject	
	 */
	public class DFPResponseAdditionalItemFields implements IDART6Parser{

	 	List<DARTObject.DARTAds> lstObjItems = new List<DARTObject.DARTAds>();
	 	DART6_LINEITEMSERVICE.LineItem lineItem;
	 	OpportunityLineItem item;
	 	
	 	/** Constructor */
		public DFPResponseAdditionalItemFields(OpportunityLineItem item)
		{
			this.item = item;   
		}
		
		public void setObjectDFP(Object dfpObj)
		{
			this.lineItem  = (DART6_LINEITEMSERVICE.LineItem)dfpObj;
		}
		
		public void parse()
		{

		    if(lineItem!=null){
		    	DARTObject.DARTAds objItem = new DARTObject.DARTAds(item);
		    	//get start date
		    	DART6_LINEITEMSERVICE.DateTime_x startDateTime = lineItem.startDateTime;
		    	DART6_LINEITEMSERVICE.Date_x stdate_x = startDateTime.date_x;
		    	Integer stYear = stdate_x.year;
		        Integer stMonth = stdate_x.month;
		        Integer stDay = stdate_x.day;
		        Integer stHour = startDateTime.hour;
		        Integer stMinute = startDateTime.minute; 
		        Integer stSecond = startDateTime.second;
		        String dpfStTimezoneId = startDateTime.TimezoneID;
		        String strStartDt = stYear+'-'+stMonth+'-'+stDay+ ' ' + stHour+':'+stMinute+':'+stSecond;
		        DateTime finalStartDt = DARTUtil.fixTimezoneDateTime(strStartDt, dpfStTimezoneId);
		    	//get end date
		    	DART6_LINEITEMSERVICE.DateTime_x endDateTime = lineItem.endDateTime;
		    	DateTime finalEndDt;
		    	if(endDateTime!=null){ // sometime endDateTime return null(unlimited)
		    		DART6_LINEITEMSERVICE.Date_x endDate_x = endDateTime.date_x;
			    	Integer endYear = endDate_x.year;
			        Integer endMonth = endDate_x.month;
			        Integer endDay = endDate_x.day;
			        Integer endHour = endDateTime.hour;
			        Integer endMinute = endDateTime.minute;
			        Integer endSecond = endDateTime.second;
			        
			        String dpfEnTimezoneId = endDateTime.TimezoneID;
			        String strEndDt = endYear+'-'+endMonth+'-'+endDay+ ' ' + endHour+':'+endMinute+':'+endSecond;
			        finalEndDt  = DARTUtil.fixTimezoneDateTime(strEndDt, dpfEnTimezoneId);
		    	}
		    	//get quanity from dfp
		    	DART6_LINEITEMSERVICE.Goal primaryGoal = lineItem.primaryGoal;
		    	Long adQuantity = primaryGoal.units;
		    	//get Rate from dfp
		    	//microAmount need to /1000000 when push to SF
		    	DART6_LINEITEMSERVICE.Money money = lineItem.costPerUnit; 
		    	Long microAmount = money.microAmount/1000000;
	
		    	objItem.setExternalFromDate(finalStartDt);
		    	objItem.setExternalEndDate(finalEndDt);
		    	objItem.setExternalQuality(adQuantity);
		    	objItem.setExternalBillingCategory(lineItem.costType);
		    	objItem.setExternalSalePrice(microAmount);
		    	
		    	lstObjItems.add(objItem); 
		    }
		}    
		
		public List<DARTObject.IDARTObject> getListDartObject(){
			return lstObjItems;
		} 		
	}
	
	
	/**
	 * Delivery parser, dart6 and dart5 are simlilar but to reduce script statement we need to create the new Parser
	 */
	public class XmlToAdxImportParser implements IDART6Parser{
		
		protected List<DARTObject.IDARTGenericObject> listAdxReports; 
        protected String xmlRes;
        protected String sobjType;
        protected DartResponseMsg deliveryResponse;
		 
	 	Integer[] gNums = new Integer[5];
		public XmlToAdxImportParser(String sobjType){   
			if(sobjType == DeliveryController.SOBJECT_METRIC){
				
				//index from raw xml
				//0: date
				//1: revenue
				//2: click
				//3: impression

				gNums[0] = 0; //date
				gNums[1] = 1; //revenue
				gNums[2] = 2; //click
				gNums[3] = 3; //impression

			}
		} 

 		private void doExtract()
	 	{
	 		//try{
	 		//	System.debug('>>>>>>>>>>>>>>>>xmlRes 3/4/13 MM/DD/YY' + xmlRes);
	 		//	Document dCov=new Document(Body=Blob.valueOf(xmlRes), Name='AdxImportRevItem'+System.today(), Type=' Temporary Document', ContentType='txt',FolderId=Userinfo.getUserId());
    		//	insert dCov;
    		//	dCov = null; // same mem
	 		//}catch(Exception e){}
		 
			deliveryResponse.doc.getRootElement(); //Report-->ReportData-->DataSet-->Row-->Column
			DOM.XMLNode node = deliveryResponse.doc.getRootElement();
			try{
				 	for(Dom.XMLNode child: node.getChildElements()){
						if(child.getName().equals('ReportData')){
	   						for(Dom.XMLNode child2: child.getChildElements()){
	   							if(child2.getName().equals('DataSet')){
						        	for(Dom.XMLNode child3: child2.getChildElements()){
						        		if(child3.getName().equals('Row')) {
								 			listAdxReports.add(	new DARTObject.DARTAdxImport(
										   		new Map<Object,Object>
										   			{
										   				DARTObject.ADX_FIELD_LEVEL_CLICK => child3.getChildElements()[gNums[2]].getChildElements()[0].getText(),
											   			DARTObject.ADX_FIELD_LEVEL_IMPRESSION => child3.getChildElements()[gNums[3]].getChildElements()[0].getText(),
											   			DARTObject.ADX_FIELD_LEVEL_REVENUE => child3.getChildElements()[gNums[1]].getChildElements()[0].getText(), 
										   				DARTObject.DEL_FIELD_DATE_OR_MONTH =>child3.getChildElements()[gNums[0]].getChildElements()[0].getText()
										   			}
									   			)
											);
				 						}
						        	}
						        }
	   						}
	   					}
					}   
					node = null;  
			}catch(Exception ex){
				throw new ExceptionGroup.ParserException(ex.getMessage());
			}
		}
		
		public void parse()
        {
        	
        	listAdxReports = new  List<DARTObject.DARTAdxImport>();
            deliveryResponse = new DartResponseMsg(xmlRes);
            
            String availImpress='';
            if(deliveryResponse.isError)
            {   
                throw new ExceptionGroup.DARTException(deliveryResponse.errMsg);
            }
            else
            {
	        	try
	        	{
	        		doExtract();
	                deliveryResponse = null;
	        	}
	        	catch(Exception ex)
	        	{
	        		throw new ExceptionGroup.ParserException(ex.getMessage());
	        	}
            }
        	
        }
        
		public List<DARTObject.IDARTGenericObject> getListDartObject()
        { 
            return  listAdxReports;
        } 
			
		public void setObjectDFP(Object dfpObject){xmlRes = dfpObject +'';}
		
	}
	
    
}