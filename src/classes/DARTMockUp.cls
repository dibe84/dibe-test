/**
  * Response mock up for unit test
  * Created: 11/12/2012
  * @updated Chr: 13-08-2015
  *             => Update mock up response body as v201505
  */
@isTest
public with sharing class DARTMockUp {
    // Bunhor @01-Sep-16: 
    public class GenericRespone implements WebServiceMock {
        Object responseElement;
        public GenericRespone(Object responseElement) {
            this.responseElement = responseElement;
        }
        public void doInvoke(Object stub,
                Object request, Map<String, Object> response,
                String endpoint, String soapAction, String requestName,
                String responseNS, String responseName, String responseType) {
                response.put('response_x', responseElement); 
        }
    }
    
  
  public static String generateDart6Response(HTTPWrapper.IGenericRequest request)
    {
        
        if(request instanceof DART6Message.DART6TokenRequest)
        {
            return 'Auth=xxxxxxxxxxyyyyyyyyyyzzzzzzzzzz'; 
        }else if(request instanceof DART6Message.DART6ReportDownloadRequest)
        {
            return DART6_IMPORTDELIVERY_RES_MOCK;
        }
        
        return '';
    }
    
  public static DART6_FORECASTSERVICE.getAvailabilityForecastResponse_element getMockDart6ForecastResponse_x()
  {
    DART6_FORECASTSERVICE.getAvailabilityForecastResponse_element mockFcRes = new DART6_FORECASTSERVICE.getAvailabilityForecastResponse_element();
    DART6_FORECASTSERVICE.AvailabilityForecast rval = new DART6_FORECASTSERVICE.AvailabilityForecast();
    rval.availableUnits = 300;
    mockFcRes.rval = rval;
    return mockFcRes;
  }
  
  public static DART6_COMPANYSERVICE.createCompaniesResponse_element getMockDart6CompanyResponse_x()
  {
    DART6_COMPANYSERVICE.createCompaniesResponse_element mockRest = new DART6_COMPANYSERVICE.createCompaniesResponse_element();
    DART6_COMPANYSERVICE.Company com = new DART6_COMPANYSERVICE.Company();
    com.id=123456;
    com.type_x='ADVERTISER';
    mockRest.rval=new List<DART6_COMPANYSERVICE.Company>{com};
    return mockRest; 
  }

  public static DART6_USERSERVICE.getUsersByStatementResponse_element getMockDart6UserByStatement_x()
  {

    DART6_USERSERVICE.getUsersByStatementResponse_element mockUserRes = new DART6_USERSERVICE.getUsersByStatementResponse_element();
    DART6_USERSERVICE.UserPage userPage = new DART6_USERSERVICE.UserPage();
    
    DART6_USERSERVICE.User_x user_x = new DART6_USERSERVICE.User_x();
    user_x.name = 'TestingUser';
    user_x.email = 'dart6testuser@gmail.com';
    user_x.id = Long.valueOf('123456');
    
    userPage.results = new List<DART6_USERSERVICE.User_x>{user_x};
    userPage.totalResultSetSize=1;
    
    
    mockUserRes.rval= userPage;
    
    System.debug('---------------------->mockUserRes' + mockUserRes);
    
    return mockUserRes;
  }
  
  public static DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element getMockDart6ComByStatement_x()
  {
        DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element comRes = new DART6_COMPANYSERVICE.getCompaniesByStatementResponse_element();
        DART6_COMPANYSERVICE.CompanyPage rval = new DART6_COMPANYSERVICE.CompanyPage();
        
        DART6_COMPANYSERVICE.Company com = new DART6_COMPANYSERVICE.Company();
        com.id = 111111;
        com.name = 'ComTest';
        
        rval.results = new List<DART6_COMPANYSERVICE.Company>{com};
        rval.totalResultSetSize=1;
        
        
        comRes.rval= rval;
        
        return comRes;
    
  }
  
  
  public static DART6_ORDERSERVICE.createOrdersResponse_element getMockDart6ResponseOrder()
  {
    DART6_ORDERSERVICE.createOrdersResponse_element mockOrderRes = new DART6_ORDERSERVICE.createOrdersResponse_element();
    
    DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order();
    ord.advertiserId = Long.valueOf('3333330');
    ord.poNumber ='PO-123';
    ord.id=Long.valueOf('22222');
    ord.traffickerId = Long.valueOf('2145'); 
    
    mockOrderRes.rval = new List<DART6_ORDERSERVICE.Order>{ord};

    return mockOrderRes;

  } 
  
  public static DART6_LINEITEMSERVICE.createLineItemsResponse_element getMockDart6ResponseLineItem()
  {
    DART6_LINEITEMSERVICE.createLineItemsResponse_element lineItemRes_x = new DART6_LINEITEMSERVICE.createLineItemsResponse_element();
    DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
     
    DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal(); 
    gl.unitType = 'IMPRESSIONS';
    gl.units = 50;
     
    lineItem.id = Long.valueOf('123456');
    //lineItem.unitType = 'STANDARD';
    lineItem.costType = 'CPM';
    lineItem.orderId=Long.valueOf('111111'); 
    lineItem.primaryGoal = gl;
    
    lineItemRes_x.rval = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
    return lineItemRes_x;
    
    
  } 
  
  public static DART6_LINEITEMSERVICE.createLineItemsResponse_element getMockDart6ResponseLineItem1()
  {
    
    DART6_LINEITEMSERVICE.createLineItemsResponse_element lineItemRes_x = new DART6_LINEITEMSERVICE.createLineItemsResponse_element();
    DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
    
    DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal();
    gl.unitType = 'IMPRESSIONS';
    gl.units = 50;
    
    lineItem.id = Long.valueOf('123456');
    //lineItem.unitType = 'STANDARD';
    lineItem.costType = 'CPM';
    lineItem.orderId=Long.valueOf('111111');
    lineItem.primaryGoal = gl;
    
    lineItemRes_x.rval = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
    return lineItemRes_x;
    
  } 
  
  
  public static DART6_LINEITEMSERVICE.updateLineItemsResponse_element getMockDart6ResponseLineItemUpdate()
  {
    DART6_LINEITEMSERVICE.updateLineItemsResponse_element lineItemRes_x = new DART6_LINEITEMSERVICE.updateLineItemsResponse_element();
    DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
    
    DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal();
    gl.unitType = 'IMPRESSIONS';
    gl.units = 50;
    
    lineItem.id = Long.valueOf('123456');
    //lineItem.unitType = 'STANDARD';
    lineItem.costType = 'CPM';
    lineItem.orderId=Long.valueOf('111111');
    lineItem.primaryGoal = gl;
    
    
    lineItemRes_x.rval = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
    return lineItemRes_x;
    
  } 
  
  public static DART6_LINEITEMSERVICE.updateLineItemsResponse_element getMockDart6ResponseLineItemUpdate1()
  {
    DART6_LINEITEMSERVICE.updateLineItemsResponse_element lineItemRes_x = new DART6_LINEITEMSERVICE.updateLineItemsResponse_element();
    DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
    
    DART6_LINEITEMSERVICE.Goal gl = new DART6_LINEITEMSERVICE.Goal();
    gl.unitType = 'IMPRESSIONS';
    gl.units = 50;
    
    lineItem.id = Long.valueOf('123456');
    //lineItem.unitType = 'STANDARD';
    lineItem.costType = 'CPM';
    lineItem.orderId=Long.valueOf('111111');
    lineItem.primaryGoal = gl;
    
    
    lineItemRes_x.rval = new List<DART6_LINEITEMSERVICE.LineItem>{lineItem};
    return lineItemRes_x;
    
  }
  public static DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element getMockDataLineItemByStatement()
    {
        
        DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element lineItemResx = new DART6_LINEITEMSERVICE.getLineItemsByStatementResponse_element();
        DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
        lineItem.id = Long.valueOf('123456');
        
        lineItem.orderId=Long.valueOf('111111');
        lineItem.status='READY';
        
        //start datetime mockup
        DART6_LINEITEMSERVICE.DateTime_x startDateTime = new DART6_LINEITEMSERVICE.DateTime_x();
        DART6_LINEITEMSERVICE.Date_x stdate_x = new DART6_LINEITEMSERVICE.Date_x();
        stdate_x.year = 2015;
        stdate_x.month = 1;
        stdate_x.day = 1;
        startDateTime.hour = 14;
        startDateTime.minute = 30;
        startDateTime.second = 20;
        startDateTime.date_x = stdate_x;
        startDateTime.TimezoneID='Asia/Bangkok';
        lineItem.startDateTime = startDateTime;
        
        //end datetime mokup
        DART6_LINEITEMSERVICE.DateTime_x endDateTime = new DART6_LINEITEMSERVICE.DateTime_x();
        DART6_LINEITEMSERVICE.Date_x endDate_x = new DART6_LINEITEMSERVICE.Date_x();
        endDate_x.year = 2015;
        endDate_x.month = 1;
        endDate_x.day = 31;
        endDateTime.hour = 11;
        endDateTime.minute = 30;
        endDateTime.second = 30;
        endDateTime.date_x = endDate_x;
        endDateTime.TimezoneID='Asia/Bangkok';
        lineItem.endDateTime  = endDateTime;
        //primarygoal
        DART6_LINEITEMSERVICE.Goal primaryGoal = new DART6_LINEITEMSERVICE.Goal();
        primaryGoal.units = 300;
        lineItem.primaryGoal = primaryGoal;
        //microAmount
        DART6_LINEITEMSERVICE.Money money = new DART6_LINEITEMSERVICE.Money(); 
        money.microAmount=20*1000000;
        lineItem.costPerUnit = money;
        
        //costType
        lineItem.costType = 'CPM';
        
        DART6_LINEITEMSERVICE.LineItemPage page1 = new DART6_LINEITEMSERVICE.LineItemPage();
        page1.totalResultSetSize = 1;
        page1.startIndex = 1;
        page1.results = new DART6_LINEITEMSERVICE.LineItem[]{lineItem};
        
        lineItemResx.rval = page1;
        
        return lineItemResx;
    }
    
  public static DART6_ORDERSERVICE.getOrdersByStatementResponse_element getMockDart6ResponseOrdersByStatement()
  {
        
        DART6_ORDERSERVICE.getOrdersByStatementResponse_element ordRes = new DART6_ORDERSERVICE.getOrdersByStatementResponse_element();
        DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order();
        ord.advertiserId = 11111;
        ord.id = 22222;
        
        DART6_ORDERSERVICE.OrderPage rval =  new DART6_ORDERSERVICE.OrderPage();
        rval.totalResultSetSize = 1;
        rval.startIndex = 1;
        rval.results = new DART6_ORDERSERVICE.Order[]{ord};
        ordRes.rval = rval;
        return ordRes;
  }
    
  
  public static DART6_REPORTSERVICE.runReportJobResponse_element getMockDart6runReportJobResponse_element(){
    DART6_REPORTSERVICE.runReportJobResponse_element element = new DART6_REPORTSERVICE.runReportJobResponse_element();
    element.rval = new DART6_REPORTSERVICE.ReportJob();
    element.rval.id = 1111111;
    //element.rval.reportJobStatus = DART6_REPORTSERVICE.REPORTJOBSTATUS_IN_PROGRESS;    
    return element;
  }
  
  public static DART6_REPORTSERVICE.getReportJobStatusResponse_element getMockDart6runReportJobStatus(){
    DART6_REPORTSERVICE.getReportJobStatusResponse_element element = new DART6_REPORTSERVICE.getReportJobStatusResponse_element();
    element.rval = DART6_REPORTSERVICE.REPORTJOBSTATUS_COMPLETED;
    return element;
  }
  
  public static Dart6_ReportService.getReportDownloadUrlWithOptionsResponse_element getMockDart6getReportDownloadUrlWithOptionsResponse_element(){
    Dart6_ReportService.getReportDownloadUrlWithOptionsResponse_element element = new Dart6_ReportService.getReportDownloadUrlWithOptionsResponse_element();
    element.rval = 'testURLDOWNLOAD';
    return element; 
  }
  
  public static DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element getMockDart6CustomKVByStatement()
  {
    DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val1 = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
    val1.customTargetingKeyId = 11111;
    val1.id = 22222;
    val1.name = 'bmw';
    val1.matchType = 'EXACT';
    DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage page1 = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage();
    page1.totalResultSetSize = 1;
    page1.startIndex = 1;
    page1.results = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[]{val1};
    
    
    DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element el = new DART6_CUSTOMTARGETINGSERVICE.getCustomTargetingValuesByStatementResponse_element();
    
    
    el.rval = page1;
    
    return el;
    
  }
  
  public static DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element getMockDart6CreateFreeFormValue()
  {
    DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val1 = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
    val1.customTargetingKeyId = 11111;
    val1.id = 33333;
    val1.matchType = 'EXACT';
    val1.name = 'hummer';
    
    DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element el = new DART6_CUSTOMTARGETINGSERVICE.createCustomTargetingValuesResponse_element();
    el.rval = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[]{val1};
    
    return el;
  }
  /**
   * mockup test getCurrentNetwork
   */
  public static DART6_NETWORKSERVICE.getCurrentNetworkResponse_element getCurrentNetwork_element()
  {
    
    DART6_NETWORKSERVICE.getCurrentNetworkResponse_element response_x = new DART6_NETWORKSERVICE.getCurrentNetworkResponse_element();
    DART6_NETWORKSERVICE.Network network = new DART6_NETWORKSERVICE.Network();
    network.id=111111;
    network.effectiveRootAdUnitId='22222';
    response_x.rval = network;
    
    return response_x;
    
  }
      
  public final static String DART6_IMPORTDELIVERY_RES_MOCK = '<?xml version=\'1.0\'?>'+
      '<Report reportTimeStamp=\'2013-01-24T10:06:21.832Z\'><HeaderData/><ReportData>'+
            '<ColumnHeaders>'+
            '<ColumnHeader name=\'orderId\' localizedName=\'Order ID\'/>'+
            '<ColumnHeader name=\'lineItemId\' localizedName=\'Line item ID\'/>'+
            '<ColumnHeader name=\'lineitemLifetimeMergedImpressions\' localizedName=\'Ad server impressions\'/>'+
            '<ColumnHeader name=\'lineitemLifetimeMergedClicks\' localizedName=\'Ad server clicks\'/>'+
            '<ColumnHeader name=\'mergeReservationImpressionsDelivered\' localizedName=\'Reservation impression\'/>'+
            '<ColumnHeader name=\'mergeLineItemDeliveryIndicator\' localizedName=\'Delivery indicator\'/></ColumnHeaders>'+
            '<ColumnHeader name=\'mergeReservationClicksDelivered\' localizedName=\'Reservation Clicked\'/>'+
            '<ColumnHeader name=\'activeViewAdServerMeasurableImpressions\' localizedName=\'Messureable Impression\'/>'+
            '<ColumnHeader name=\'activeViewAdServerViewableImpressions\' localizedName=\'Viewable Impression\'/>'+
            '<ColumnHeader name=\'activeViewAdServerViewableImpressionsRate\' localizedName=\'Viewable Impression Rate\'/>'+
            '<DataSet>'+
            '<Row rowNum=\'1\'><Column name=\'orderId\'><Val>123456</Val></Column>'+
            '<Column name=\'lineItemId\'><Val>9056470</Val></Column>'+
            '<Column name=\'mergeReservationImpressionsDelivered\'><Val>222</Val></Column>'+
            '<Column name=\'mergeReservationClicksDelivered\'><Val>223</Val></Column>'+
            '<Column name=\'mergeLineItemDeliveryIndicator\'><Val>100</Val></Column>'+
            '<Column name=\'activeViewAdServerViewableImpressions\'><Val>14</Val></Column>'+
            '<Column name=\'activeViewAdServerMeasurableImpressions\'><Val>213</Val></Column>'+
            '<Column name=\'activeViewAdServerViewableImpressionsRate\'><Val>74</Val></Column>'+
            '</Row>'+
            '<Row rowNum=\'2\'><Column name=\'orderId\'><Val>212363990</Val></Column>'+
            '<Column name=\'lineItemId\'><Val>123456</Val></Column>'+
            '<Column name=\'mergeReservationImpressionsDelivered\'><Val>22</Val></Column>'+
            '<Column name=\'mergeReservationClicksDelivered\'><Val>223</Val></Column>'+
            '<Column name=\'mergeLineItemDeliveryIndicator\'><Val>222</Val></Column>'+
            '<Column name=\'activeViewAdServerViewableImpressions\'><Val>14</Val></Column>'+
            '<Column name=\'activeViewAdServerMeasurableImpressions\'><Val>213</Val></Column>'+
            '<Column name=\'activeViewAdServerViewableImpressionsRate\'><Val>14</Val></Column>'+
            '</Row>'+
            '</DataSet></ReportData></Report>';
      
      
      /*
                gNums[0] = 0; //orderId
                gNums[1] = 1; //lineItemId
                gNums[2] = 6; //activeViewAdServerMeasurableImpressions
                gNums[3] = 5; //activeViewAdServerViewableImpressions
                gNums[4] = 4; //lineItemDeliveryIndicator
                gNums[5] = 2; //lineitemLifetimeXfpImpressions
                gNums[6] = 3; //lineitemLifetimeXfpClicks
                gNums[7] = -1; //date
                gNums[8] = 7; //activeViewAdServerViewableImpressionsRate
       */
      
      
      
}