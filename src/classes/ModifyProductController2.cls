/** Controller of Product Configuration Page
  Main Functions:
    + Provides raw Campaign Items to be modified bases on the items in basket.
    + Duplicates the items.
    + Remove items from basket. 
    + Splits items into 1 calendar week bases on Start Date and End Date.
    + Splits items into 2 calendar weeks bases on Start Date and End Date.
    + Splits items into calendar month bases on Start Date and End Date.
    + Copies and pasts the value of the field through the column.
    + Saves all items as campaign items and links to media campaign.
    + Restricts field usage based on product checkbox controls
    + Populates Sales price from Rate Card object based on length/quantity for Accounts products
   
  Where is it used?
    + The reference page is called from page SelectSearch and button "Modify Products" in Campaign Item related list of Media Campaign(by passing the selected items as Ids on the fly.)
    
    @Revision
    
    Date		Author				Description
    11/3/15		suy sreymol			#5028 modifyproduct bug: adding new product to existing opp with existing lines
    								Using an existing opp with products, if i click on 'add product' and then find a new product and then click 'start configuration' 
    								i only see the new line item, NOT the existing line item.
    								
   */ 
public class ModifyProductController2 {

    public List < DtoItem > lstRecords { get; set; }
    public String selPosition { get; set; }
    public String selColumn { get; set; }
    public String selShare { get; set; }
    public String selCopies { get; set; }
    public String mcName { get; set; }
    public String accName { get; set; }
    public String accId { get; set; }
    public Decimal oppProb { get; set; }
    public String errorMsg { get; set; }
    public Boolean fromDateError { get; set; }
    public String BP_Collision { get; set; }
    public Boolean forceDateSave { get; set; } //Indicates that user decide to save even the Start Date > TODAY
    public Boolean errorFieldStatus { get; set; }
    public String refreshUrl { get; set; }
    public String ActiveTab { get; set; }
    public Integer prodcount { get; set; }
    public String mcPBId { set; get;}
    public Double selectedRandomNr { get; set; }
    public String warningOli { set; get;}
    public String isFromDateDisabled { set; get; }
    public Boolean isSave { get; set; }
    private String camItems;
    private String backUrl;
    private String id;
    private List < Media_Basket__c > baskets;
    private Set < String > sItemId;
    private Map < String, DtoItem > mapPackageMain = new Map < String, DtoItem > ();
    private String currencyOpp = '';
    public String hsize { get; set; }
    public Boolean isEdit { get; set; }
    public static Map < String, String > mapValueBillingCategory2 = new Map < String, String > ();
    private Integer dtoIdRunner;
    private final String EXP_GETKEYVALUE = '(\\(.*?=(.*?)\\))';
    private final String EXP_GETKEY = '(\\((.*?)\\=.*?)\\)';
 
  //Bunhor @28-04-14: For showing surcharge in each tab
    public String tab6Surcharge{get{return getSurchargeFromCS('TabSix')+'';}}
    public String tab3Surcharge{get{return getSurchargeFromCS('TabThree')+'';}}
    public String tab4Surcharge{get{return getSurchargeFromCS('TabFour')+'';}}
    public String tab5Surcharge{get{return getSurchargeFromCS('TabFive')+'';}}
    public String tab7Surcharge{get{return getSurchargeFromCS('TabSeven')+'';}}
    private final static String BILLING_CPM = 'CPM';
    private final static String BILLING_CPD = 'CPD';
    private final static String BILLING_CPC = 'CPC';
    private final static String BILLING_CPA = 'CPA';
    
    private final static String BILLING_SERVICE_FEE = 'ServiceFee';
    private final static String BILLING_CALC_1TIME = 'OneTime';
    private final static String BILLING_CALC_MFIXED = 'MonthlyFixed'; 
    
    private final String FEATURE_PACKAGE = 'Features';
    public Decimal accountDiscount{get;set;} 
      
    public ModifyProductController2(ApexPages.StandardController controller) {
        hsize = '63px';
        dtoIdRunner = 0;
        isSave = false; // to show error field after save
        //controller.setPageSize(10);
        errorFieldStatus = false;
        fromDateError = false;
        forceDateSave = false;
        isEdit = false;
        errorMsg = '';
        warningOli = '';
        isPollerMode = false;

        camItems = ApexPages.currentPage().getParameters().get('camItems');
        backUrl = ApexPages.currentPage().getParameters().get('retURL');
        refreshUrl = Apexpages.currentPage().getUrl();

        lDisplayRec = new List < DtoItem > ();
        numbtn = new Set < Integer > ();
        disableNext = true;
        disablePre = true;
        pageNum = 1;

        //get all value of Billing category 2
        Schema.DescribeFieldResult F1 = Product2.Billing_Category2__c.getDescribe();
        List < Schema.PicklistEntry > P1 = F1.getPicklistValues();

        for (Schema.PicklistEntry x: P1) {
            mapValueBillingCategory2.put(x.getValue(), x.getValue());
        }
        //Media Campaign Id manually passed by button "Add Items" in Campaign Items related list of Media Campaign
        id = ApexPages.currentPage().getParameters().get('mcId'); //id Opp
        mcPBId = ApexPages.currentPage().getParameters().get('mcPBId'); //id pricebook
        if (id == null) {
            id = ApexPages.currentPage().getParameters().get('id');
            isEdit = true;
        } 
         List <Opportunity> listMedia = [Select Billing_Account__r.AccountDiscount__c, Billing_Account__c  From Opportunity Where Id = : id];
        
        if (listMedia.isEmpty()) return;  
        
        // Jvdh: Percentage should be divided by 100
        accountDiscount = listMedia.get(0).Billing_Account__r.AccountDiscount__c==null?0:(listMedia.get(0).Billing_Account__r.AccountDiscount__c/100);
        
        getExistingLineItems();//@suy sreymol 11/3/15 get all existing lineitems
        
        if (!isEdit) { //Add mode
            initList();
        } else { // Edit mode
            //get all package products
            //@suy sreymol 11/3/15 
            /**sItemId = new Set < String > ();
            for (OpportunityLineItem oli: [Select Id From OpportunityLineItem Where OpportunityId = : id ]) {
                sItemId.add(oli.Id);
            }**/
            //end suy sreymol
            
            handleEdit();
            backUrl = '/' + ApexPages.currentPage().getParameters().get('id');
        }
        reEvaluateAll();
        gotoPage();
        system.debug('lDisplayRec ================== ' + lDisplayRec);
    }
    
    //@suy sreymol 11/3/15 to get all existing lineitems
    private List<OpportunityLineItem> existingItems = new List<OpportunityLineItem>();
    private void getExistingLineItems() {
    	String queryStr = 'Select Id';
        for (String f: mainFields) queryStr = queryStr + ', ' + f;
        queryStr = queryStr + ', Targeting__r.ID, Targeting__r.Name, PricebookEntry.Product2.RecordType.Name, PricebookEntry.Name,PricebookEntry.Product2.Billing_Category2__c,PricebookEntry.Product2.available_Key_Values__c, PricebookEntry.Product2.Id,PricebookEntry.Product2.Fixed_price__c,PricebookEntry.Product2.Fixed_Site__c,PricebookEntry.Product2.Variable_CPM_price__c,PricebookEntry.Product2.Billing_Category__c,PricebookEntry.Product2.Advertising_Medium__r.Name,PricebookEntry.Product2.Advertising_Medium__r.related_Mediums__c,PricebookEntry.Product2.Placement__r.Name,PricebookEntry.Product2.Site__r.Name,PricebookEntry.Product2.Name,PricebookEntry.Product2.AdServer_Keywords_Key_Values__c, PricebookEntry.Product2.FreeProduct__c,Geography__c,Connection_Targeting__c'; //@vitou 25-08-2015 : remove Device_Targeting__c
        queryStr = queryStr + ', ListPrice, CreatedDate, PricebookEntry.UnitPrice, PricebookEntry.Product2.CPM_Price__c, PricebookEntry.Product2.CPD_Price__c, PricebookEntry.Product2.CPC_Price__c, PricebookEntry.Product2.Product_SubType__c,PricebookEntry.Product2.PredifinedAdunit__c,PricebookEntry.Product2.PredifinedAdunit__r.Active__c '; // Bunhor(25-Mar-14)
        queryStr = queryStr + ' From OpportunityLineItem where OpportunityId =: id';
        
        UTIL.log('queryStr: '+queryStr);
        existingItems = Database.query(queryStr);
    }
    //end suy sreymol
    
    //MS 01-09-2014: Task 3830 -- for JS Tree
    public void doCopyForNewTargeting(){
       doCopyNewTargeting(false);     
    }
    
    private void doCopyNewTargeting(Boolean isForceCopy ){
        try{
            Set<String> setColumnForCopy= new Set<String>{'City_description__c','Countries_Description__c','Rich_Line_Description__c','KeyValueString__c'}; 
            for(String col:setColumnForCopy ){
                selColumn = col;
                system.debug('selColumn===='+selColumn);
                doCopy( isForceCopy );
            }     
          
        }catch(Exception e){
          Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
          Apexpages.addMessage(msg);
        }
        
    }
      
    public void doForceCopyForNewTargeting(){
        doCopyNewTargeting(true);       
    }
    //end of MS
    
    //populate the existing campaign item into product configuration screen
    private void handleEdit() {
        warningOli = '';
        lstRecords = new List < DtoItem > ();
        baskets = new List < Media_Basket__c > ();
        String productKeyValue = '';
		
		/**@suy sreymol 11/3/2015
		String queryStr = 'Select Id';
        for (String f: mainFields) {
            queryStr = queryStr + ', ' + f;
        } 
        //HB FIX, damit Pricebook abgefragt wird
        queryStr = queryStr + ', Targeting__r.ID, Targeting__r.Name, PricebookEntry.Product2.RecordType.Name, PricebookEntry.Name,PricebookEntry.Product2.Billing_Category2__c,PricebookEntry.Product2.available_Key_Values__c, PricebookEntry.Product2.Id,PricebookEntry.Product2.Fixed_price__c,PricebookEntry.Product2.Fixed_Site__c,PricebookEntry.Product2.Variable_CPM_price__c,PricebookEntry.Product2.Billing_Category__c,PricebookEntry.Product2.Advertising_Medium__r.Name,PricebookEntry.Product2.Exclusive_Placement__c,PricebookEntry.Product2.Advertising_Medium__r.related_Mediums__c,PricebookEntry.Product2.Placement__r.Name,PricebookEntry.Product2.Site__r.Name,PricebookEntry.Product2.Name,PricebookEntry.Product2.AdServer_Keywords_Key_Values__c, PricebookEntry.Product2.FreeProduct__c,Geography__c,Device_Targeting__c,Connection_Targeting__c';
        queryStr = queryStr + ', ListPrice, CreatedDate, PricebookEntry.UnitPrice, PricebookEntry.Product2.CPM_Price__c, PricebookEntry.Product2.CPD_Price__c, PricebookEntry.Product2.CPC_Price__c, PricebookEntry.Product2.Product_SubType__c,PricebookEntry.Product2.PredifinedAdunit__c,PricebookEntry.Product2.PredifinedAdunit__r.Active__c '; // Bunhor(25-Mar-14)
        queryStr = queryStr + ' From OpportunityLineItem  where Id IN: sItemId';
		*/
		
        // get product Id to select available site
        Set <String> proIdsAva = new Set < String > ();
        Map <String, String> mapAvailableSite = new Map < String, String > ();
        
        /**@suy sreymol 11/3/15 
        UTIL.log('queryStr: '+queryStr);
        List <OpportunityLineItem> lopli = (List <OpportunityLineItem> ) Database.query(queryStr); 
        for (OpportunityLineItem item: lopli) {
        */
        
        for (OpportunityLineItem item : existingItems) proIdsAva.add(item.PricebookEntry.Product2.Id);

        //get available site for opportunity
        for (Available_Site__c a: [Select a.available_Site__r.DartName__c, a.available_Site__r.Id, a.available_Site__c, a.Product__c, a.Id From Available_Site__c a where Product__c in : proIdsAva order by available_Site__r.DartName__c]) {
            if (!mapAvailableSite.containsKey(a.Product__c)) {
                mapAvailableSite.put(a.Product__c, a.available_Site__r.DartName__c + '.');
            } else {
                String tmp = mapAvailableSite.get(a.Product__c);
                tmp = tmp.subString(0, tmp.length() - 1);
                tmp += ',' + a.available_Site__r.DartName__c + '.';
                mapAvailableSite.put(a.Product__c, tmp);
            }
        }

        //get product for opportunity
        Map < Id, Product2 > mapProduct = new Map < Id, Product2 > ([select p.Id, p.Name, p.tech_targeting__c, p.Time__c, p.Keywords__c, p.FC__c, p.ManualSetEndDate__c, p.MonthsDays__c, p.Fixed_Price__c, p.Fixed_Site__c, p.Geo_IP__c, p.Rate_Card__c, FreeProduct__c 
                                       From Product2 p where id in : proIdsAva]);


        for (OpportunityLineItem item: existingItems) {
            Media_Basket__c bsk = new Media_Basket__c(AdPriceIdText__c = item.PriceBookEntryId, UserId__c = System.Userinfo.getUserId(), OpportunityId__c = id);
            baskets.add(bsk);

            //DtoItem newItem = new DtoItem(item.PricebookEntry.Name,item);
            Boolean hasSite = false;
            if (mapAvailableSite.containsKey(item.PricebookEntry.Product2.Id)) hasSite = true;
            DtoItem basketItem = new DtoItem(item.PricebookEntry.Product2.AdServer_Keywords_Key_Values__c, item); // Sreymol @createddate 02-Jan-2014
            // SUY Sreymol on 30-Dec-2013 
            // To convert all & in a string to &
            item.Placement_Targeting__c = item.Placement_Targeting__c == null ? '' : item.Placement_Targeting__c.unescapeHtml4();
            item.Rich_Line_Description__c = item.Rich_Line_Description__c == null ? '' : item.Rich_Line_Description__c.unescapeHtml4();
            //--------------------------------------------//
            DtoItem newItem = new DtoItem(item.PricebookEntry.Name, item, item.PricebookEntry.Product2.Fixed_Site__c, item.PricebookEntry.Product2.Id, mapAvailableSite.get(item.PricebookEntry.Product2.Id), hasSite, item.PricebookEntry.Product2.available_Key_Values__c, item.PricebookEntry.Product2.Billing_Category2__c, mapProduct.get(item.PricebookEntry.Product2.Id), (item.PricebookEntry.Product2.available_Key_Values__c == null ? false : true), dtoIdRunner);
            dtoIdRunner = newItem.dtoId;
            lstRecords.add(newItem);
            UTIL.log('HandleEdit: ' + lstRecords);
        }

        prodcount = lstRecords.size();
        refreshPosition(lstRecords);
        warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
    }

    /* 
    Selects all related basket records from the system to create a list of CompaignItems depends on its product to modify or remove.
  */
    private void initList() {
        warningOli = '';
        lstRecords = new List < DtoItem > ();
        List< DtoItem > newItems = new List < DtoItem > ();
        Set < String > sEntriesID = new Set < String > ();
        Map < String, Decimal > sEntriesPrice = new Map < String, Decimal > ();
		
		system.debug('currentID : ' + System.userInfo.getUserId());
		system.debug('opp Id : ' + id);
        baskets = [Select Id, AdPriceIdText__c From Media_Basket__c where UserId__c = : System.userInfo.getUserId() AND OpportunityId__c = : id];
        //system.debug(LoggingLevel.ERROR, 'baskets found: ' + baskets);

        for (Media_Basket__c media: baskets) sEntriesID.add(media.AdPriceIdText__c);
    /*HCS 03.06.2014
          KCA-8483 Inactive products being added to Opportunities
          When using the "Edit All" screens and the "Add Product" buttons in Opportunities, the users are able to select Products that are Inactive, just because the Pricebook Entry is Active.
          Please make a tweak to all of the queries that use the custom "Edit All/Add Product" screens so that only products are are "Active = True" on the Product2 table AND also "Active = True" on the Pricebook Entry are visible in the configuration screen.
          Added Product2.IsActive=true and IsActive=true to the query
        */
        Map < Id, PricebookEntry > mPriceBook = new Map < Id, PricebookEntry > ([Select Unitprice,
            Id,
            Name,
            Product2Id,
            Product2.Variable_CPM_price__c,
            Product2.Name,
            Product2.Id,
            Product2.Fixed_price__c,
            Product2.Advertising_Medium__r.Name,
            Product2.Advertising_Medium__r.FC_Quantity__c,
            Product2.Advertising_Medium__r.FC_Period__c,
            Product2.Advertising_Medium__r.FC_Ad_served_every__c,
            Product2.AdServer_Keywords_Key_Values__c,
            Product2.RecordType.Name,
            Product2.Billing_Category__c, 
            Product2.Billing_Category2__c,
            Product2.Advertising_Medium__r.related_Mediums__c,
            Product2.Placement__r.Name,
            Product2.Site__r.Name,
            Product2.Fixed_Site__c,
            Product2.available_Key_Values__c, 
            Product2.FreeProduct__c, 
            Product2.CPM_Price__c,
            Product2.CPD_Price__c,
            Product2.CPC_Price__c, 
            Product2.Content__r.SiteName__c,//HCS 20.01.2014  3. the same product has predefined 'content' or ad units. However they are not copied over to the line item.
            Product2.Product_SubType__c, //suy sreymol 21/08/2014 : get product sub type
            Product2.Device_Category__c , // Chr 08-01-2015: set Default value to device category of lineItem 
            Product2.PredifinedAdunit__c,
            Product2.PredifinedAdunit__r.Active__c,
            Product2.Placement__c //Chr: 19-03-2015: #5061: need product2.Placement__c record automatically copied over to targeting.PlacementTargetingAssociations record
            from PricebookEntry a where Id in : sEntriesID And Product2.IsActive=true  And IsActive=true
        ]);

        //  String billcat;
        Integer quant;
        String pack;
        //  Decimal pprice;     
        Set < String > proId = new Set < String > ();

        Map < String, String > mapDtoId = new Map < String, String > ();

        // get product Id to select available site
        Set < String > proIdsAva = new Set < String > ();
        Map < String, String > mapAvailableSite = new Map < String, String > ();
        
        //get product2Id from pricebookentry of the new basket
        for (PricebookEntry pbe: mPriceBook.values()) proIdsAva.add(pbe.Product2Id);
        
        //get product2 from existing lineitems
        Map<String, OpportunityLineItem> mapOpli = new Map<String, OpportunityLineItem>();
        for (OpportunityLineItem item : existingItems) {
        	proIdsAva.add(item.PricebookEntry.Product2Id);
        	mapOpli.put(item.PricebookEntryId, item);
        }

        //get available site of each product
        for (Available_Site__c a: [Select a.available_Site__r.DartName__c, a.available_Site__r.Id, a.available_Site__c, a.Product__c, a.Id From Available_Site__c a where Product__c in : proIdsAva order by available_Site__r.DartName__c]) {
            if (!mapAvailableSite.containsKey(a.Product__c)) {
                mapAvailableSite.put(a.Product__c, a.available_Site__r.DartName__c + '.');
            } else {
                String tmp = mapAvailableSite.get(a.Product__c);
                tmp = tmp.subString(0, tmp.length() - 1);
                tmp += ' , ' + a.available_Site__r.DartName__c + '.';
                mapAvailableSite.put(a.Product__c, tmp);
            }
        }

        //get product for opportunity
        Map < Id, Product2 > mapProduct = new Map < Id, Product2 > ([select p.Id, p.Name, p.tech_targeting__c, p.Time__c, p.Keywords__c, p.FC__c, p.ManualSetEndDate__c, p.MonthsDays__c, p.Fixed_Price__c, p.Fixed_Site__c, p.Geo_IP__c, p.Rate_Card__c, FreeProduct__c From Product2 p where id in : proIdsAva]);

        //MS 2-14-08-01 : KCA-9829 Update to Product Clone Button
        /*List<OpportunityLineItem> lstOpli = new List<OpportunityLineItem>([select Id, Placement_Targeting__c, Rich_Line_Description__c, KeyValueString__c, Targeting__c, PricebookEntryId from OpportunityLineItem where OpportunityId =:id]);
        Map<String, OpportunityLineItem> mapOpli = new Map<String, OpportunityLineItem>();
        for(OpportunityLineItem opli : lstOpli){
            mapOpli.put(opli.PricebookEntryId, opli);
        }**/
        //end of MS
        /*List<Targeting__c> lstTargetingTobeInsert = new List<Targeting__c>();
        for(Media_Basket__c media: baskets){
        	// Add Tareting To list
            lstTargetingTobeInsert.add(new Targeting__c(TempBinder__c=true, Description__c ='Tar_LineItemId'));
        }
        insert lstTargetingTobeInsert;
        */
        system.debug('baskets =: '+baskets);
        for (Media_Basket__c media: baskets) {
            PricebookEntry priceBook = mPriceBook.get(media.AdPriceIdText__c);
            pack = '';

            if (priceBook.Product2.RecordType.Name == 'Package') { // PACKAGE
                //  pack = 'Content Special';
                proId.add(pricebook.Product2Id);
            }
            
            //suy sreymol 21/08/2014 : change date to the first day of next calendar month if product is a feature package
            Date startDate = Date.today();
            if (priceBook.Product2.Product_SubType__c != null && priceBook.Product2.Product_SubType__c.contains(FEATURE_PACKAGE)) startDate = startDate.addMonths(1).toStartOfMonth();
            
            OpportunityLineItem camItem = new OpportunityLineItem(PricebookEntryId = priceBook.Id,
                PricebookEntry = priceBook,
                OpportunityId = id,
                //Billing_category__c = priceBook.Product2.Billing_Category__c, // Bunhor @2-Feb-15: commented out since Product2.Billing_Category__c changed to muulti-select
                UnitPrice = priceBook.Unitprice,
                Discount__c = 0,
                FC_Quantity__c = pricebook.Product2.Advertising_Medium__r.FC_Quantity__c,
                FC_Period__c = pricebook.Product2.Advertising_Medium__r.FC_Period__c,
                FC_Ad_served_every__c = pricebook.Product2.Advertising_Medium__r.FC_Ad_served_every__c,
                AdKeywords__c = pricebook.Product2.AdServer_Keywords_Key_Values__c,
                KeyValueString__c = (pricebook.Product2.AdServer_Keywords_Key_Values__c != null && pricebook.Product2.AdServer_Keywords_Key_Values__c != '') ? pricebook.Product2.AdServer_Keywords_Key_Values__c : '',
                Check_Inventory__c = true,
                from_date__c = startDate, //suy sreymol 21/08/2014 - change to the first day of next calendar month if product is a feature package
                until_Date__c = startDate.addMonths(1), //suy sreymol 21/08/2014 : change from Date.today -> startDate.addMonths(1)
                Quantity = quant
            );
            
            //Bunhor @9-May-15: set defualt for billing category 
            camItem.Billing_category__c = camItem.Billing_category__c == null ? BILLING_CPM : camItem.Billing_category__c; 
             
            camItem.Device_Targeting__c =(pricebook.Product2.Device_Category__c!=null?pricebook.Product2.Device_Category__c.replace(';',','):'');
            
            camItem.Rich_Line_Description__c = String.isEmpty( pricebook.Product2.Content__r.SiteName__c ) ? ''  :   pricebook.Product2.Content__r.SiteName__c  ;
            
            //MS 2014-08-01: KCA-9829 Update to Product Clone Button
            if(ApexPages.currentPage().getParameters().get('isClone') == 'isCloneButton'){
                if(mapOpli.get(media.AdPriceIdText__c) != null){
                    //System.debug('=======cloning....'+mapOpli.get(media.AdPriceIdText__c));
                    camItem.Placement_Targeting__c  = mapOpli.get(media.AdPriceIdText__c).Placement_Targeting__c;
                    camItem.KeyValueString__c       = mapOpli.get(media.AdPriceIdText__c).KeyValueString__c;
                    camItem.Rich_Line_Description__c= mapOpli.get(media.AdPriceIdText__c).Rich_Line_Description__c;
                    camItem.Targeting__c            = mapOpli.get(media.AdPriceIdText__c).Targeting__c; 
                }
            } 
              
            Boolean hasSite = false;

            if (mapAvailableSite.containsKey(priceBook.Product2.Id)) hasSite = true; 
            DtoItem newItem = new DtoItem(priceBook.Product2.Name, camItem, priceBook.Product2.Fixed_Site__c, priceBook.Product2.Id, mapAvailableSite.get(priceBook.Product2.Id), hasSite, priceBook.Product2.available_Key_Values__c, priceBook.Product2.Billing_Category2__c, mapProduct.get(priceBook.Product2.Id), (priceBook.Product2.available_Key_Values__c == null ? false : true), dtoIdRunner);
             
            dtoIdRunner = newItem.dtoId;
            system.debug('BBBBBB====>dtoIdRunner= ' + dtoIdRunner);
            mapDtoId.put(priceBook.Product2.Id, newItem.dtoId + ''); //get DtoId to use as key for Package Component related
            mapPackageMain.put(newItem.dtoId + '', newItem); //get main Package

            lstRecords.add(newItem);
            
            
        }
		 
		//@suy sreymol 11/3/15 - init all existing to display on the page
		for (OpportunityLineItem item : existingItems) {
            Media_Basket__c bsk = new Media_Basket__c(AdPriceIdText__c = item.PriceBookEntryId, UserId__c = System.Userinfo.getUserId(), OpportunityId__c = id);
            baskets.add(bsk);

            //DtoItem newItem = new DtoItem(item.PricebookEntry.Name,item);
            Boolean hasSite = false;
            if (mapAvailableSite.containsKey(item.PricebookEntry.Product2.Id)) hasSite = true;
            DtoItem basketItem = new DtoItem(item.PricebookEntry.Product2.AdServer_Keywords_Key_Values__c, item);
            // SUY Sreymol on 30-Dec-2013 
            // To convert all & in a string to &
            item.Placement_Targeting__c = item.Placement_Targeting__c == null ? '' : item.Placement_Targeting__c.unescapeHtml4();
            item.Rich_Line_Description__c = item.Rich_Line_Description__c == null ? '' : item.Rich_Line_Description__c.unescapeHtml4();
            //--------------------------------------------//
            DtoItem newItem = new DtoItem(item.PricebookEntry.Name, item, item.PricebookEntry.Product2.Fixed_Site__c, item.PricebookEntry.Product2.Id, mapAvailableSite.get(item.PricebookEntry.Product2.Id), hasSite, item.PricebookEntry.Product2.available_Key_Values__c, item.PricebookEntry.Product2.Billing_Category2__c, mapProduct.get(item.PricebookEntry.Product2.Id), (item.PricebookEntry.Product2.available_Key_Values__c == null ? false : true), dtoIdRunner);
            dtoIdRunner = newItem.dtoId;
            lstRecords.add(newItem);
        }
		//end suy sreymol
		 
		 system.debug('lstRecords :' + lstRecords);
        prodcount = lstRecords.size();

        refreshPosition(lstRecords);
        warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
    }
     
    /**
     * Check if this OpportunityLineItem taking PredifinedAdunit 
     * @Author Bunhor 
     * @CreatedDate 17-Feb-15
     */ 
	public static Boolean isAdUnitPredifined(OpportunityLineItem item, Product2 prod){
		return item.id==null  && String.isNotEmpty(prod.PredifinedAdunit__c) && prod.PredifinedAdunit__r.Active__c;
	}
	//&& String.isEmpty(item.Targeting__c)
	 
	/**
     * create Targeting__c and TargetingContentAssociation__c from predifined (only adding new product)
     * @Author Bunhor 
     * @CreatedDate 17-Feb-15
     * @updated: Chr: 19-03-2015: 
   	 * #5061: need product2.Placement__c record automatically copied over to targeting.PlacementTargetingAssociations record
   	 * action only when adding new lineItems to opp
     */ 
	private void createTargetingFromPredifined(OpportunityLineItem[] lstItem){ 
		Map<Integer, Targeting__c> mTargeting = new Map<Integer, Targeting__c>();
		Map<Integer, TargetingContentAssociation__c> mTargetingAsso = new Map<Integer, TargetingContentAssociation__c>();
		Map<Integer, PlacementTargetingAssociation__c> mPlacementAsso  =new Map<Integer, PlacementTargetingAssociation__c>();
		Map<Integer, String> mExtTarg = new Map<Integer, String>();
		
		for(Integer i=0; i<lstItem.size(); i++){
			OpportunityLineItem item = lstItem[i]; 
			if(item.id ==  null && String.isEmpty(item.Targeting__c)){
				//insert new targeting
				Targeting__c tg = new Targeting__c(TempBinder__c=true, Description__c ='Targeting created from predifined value, Product2.PredifinedAdunit__c');
				mTargeting.put(i, tg);
			}else if(item.id ==  null && String.isNotEmpty(item.Targeting__c)){
				mExtTarg.put(i, item.Targeting__c);
			}
		}
		if(!mTargeting.isEmpty()) insert mTargeting.values(); 

		//adding targeting & related association to the right lineItems
		for(Integer i=0; i<lstItem.size(); i++){
			OpportunityLineItem item = lstItem[i]; 
	
			if(item.id ==  null && String.isNotEmpty(item.Targeting__c)){
				String tId = mExtTarg.get(i);
				if(tId!=null){
					//create targetingAssociation in case PredifinedAdunit__r.Active__c=true
					if(isAdUnitPredifined(item, item.PricebookEntry.Product2)){
						TargetingContentAssociation__c  tgAsso = new TargetingContentAssociation__c(Targeting__c=tId, TargetingContent__c=item.PricebookEntry.Product2.PredifinedAdunit__c);
						mTargetingAsso.put(i, tgAsso);
					}
					//copy new placementTargetingAssociation from product
					PlacementTargetingAssociation__c plcAsso = new PlacementTargetingAssociation__c(Targeting__c=tId, Placement__c=item.PricebookEntry.Product2.Placement__c);
					mPlacementAsso.put(i, plcAsso);
				}
			}else if(item.id ==  null && String.isEmpty(item.Targeting__c)){
				Targeting__c tg = mTargeting.get(i);
				if(tg!=null){
					//create targetingAssociation in case PredifinedAdunit__r.Active__c=true
					if(isAdUnitPredifined(item, item.PricebookEntry.Product2)){
						TargetingContentAssociation__c  tgAsso = new TargetingContentAssociation__c(Targeting__c=tg.id, TargetingContent__c=item.PricebookEntry.Product2.PredifinedAdunit__c);
						mTargetingAsso.put(i, tgAsso);
					}
					//copy new placementTargetingAssociation from product
					PlacementTargetingAssociation__c plcAsso = new PlacementTargetingAssociation__c(Targeting__c=tg.id, Placement__c=item.PricebookEntry.Product2.Placement__c);
					mPlacementAsso.put(i, plcAsso);
				}
			}			
		}
		insert mTargetingAsso.values(); 
		insert mPlacementAsso.values();
		
	}
	
    /*
  
  Remove a basket record from list based on Ad_Price__c.Id
  
  */
    private void removeBasket(String pricebookEntryId) {
        warningOli = '';
        for (Integer k = 0; k < baskets.size(); k++) {
            if (baskets.get(k).AdPriceIdText__c == pricebookEntryId) {
                String idBasket = baskets.get(k).Id;
                baskets.remove(k);

                //remove basket from database
                delete[Select Id From Media_Basket__c where id = : idBasket];
                break;
            }
        }


        warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
    }
    /*
  Reset positon of DtoItem record depends on index in list
  */
    private void refreshPosition(List < DtoItem > recDTOs) {
        warningOli = '';
        for (Integer i = 0; i < recDTOs.size(); i++) {
            recDTOs.get(i).position = i;
        }
        //System.debug('>>>>>>>>>>>>>>>>recDTOs.size():'+recDTOs.size());
        warningOli = recDTOs.size() > 100 ? system.Label.Warning_OppLine : '';
    }


    private Media_Basket__c createNewBasket(OpportunityLineItem tmpCamItem) {
        Media_Basket__c nBasket = new Media_Basket__c(adPriceIdText__c = tmpCamItem.PricebookEntryId, OpportunityId__c = id, UserId__c = System.Userinfo.getUserId());
        return nBasket;

    }

    private OpportunityLineItem getNewCamItem(String productName, OpportunityLineItem camItem, Decimal quantity, Date startDate, Date endDate) {

        OpportunityLineItem nCamItem = createClone(productName, camItem, '');
        //camItem.clone(false,true);
        nCamItem.Quantity = quantity;
        nCamItem.from_Date__c = startDate;
        nCamItem.until_Date__c = endDate;

        //bindTreeConfigurator(nCamItem, productName);  -> bindTreeConfigurator(map);
        return nCamItem;
    }
    /*
    Return 3 letters day string of input date.
    Ex: getDayInWeek(17/05/2010) returns �MON�;
        
  */
    private String getDayInWeek(Date argDate) {
        DateTime tmp = DateTime.newInstance(argDate.year(), argDate.month(), argDate.day());
        return tmp.format('EEE');
    }
    /*
  Get number of crossing months that are available in input range.
    Ex:12/04/2010 , 12/05/2010
    Return 2;
  */
    private Integer getNumMonths(Date startDate, Date endDate) {
        Integer months = 0;
        Date lastSun = startDate;
        Date startTmp = startDate;
        Date lastDate;
        while (startTmp <= endDate) {
            lastDate = lastDate = Date.newInstance(startTmp.year(), startTmp.month(), date.daysInMonth(startTmp.year(), startTmp.month()));
            if (startTmp == lastDate) {
                months = months + 1;
                lastSun = startTmp;
            }
            startTmp = startTmp.addDays(1);
        }
        If(lastSun < endDate) {
            months = months + 1;
        }
        return months;
    }
    /*
  Get number of calendar weeks in input range date if iweek2 equal false.
  If iweek2 equal false , its return number of 2 calendar week.
  */
    private Integer getNumWeeks(Date startDate, Date endDate, Boolean isweek2) {
        Double week = 0;
        Double week2 = 0;
        Date lastSun = startDate;
        Date startTmp = startDate;
        while (startTmp <= endDate) {
            startTmp = startTmp.addDays(1);
            if (getDayInWeek(startTmp) == 'Sun') {
                week = week + 1;
                lastSun = startTmp;
            }
        }
        if (lastSun < endDate) week = week + 1;
        if (isweek2) return (Math.ceil(week / 2)).intValue();
        return week.intValue();

    }

    /*
  Copy value from selected field and  paste through the same column. 
  Types of field to be copied:
    - Checkbox (boolean)
    - Text
    - Number
    ** Ignore the other fields that already had value
  */
    private void doCopy(boolean force) {
        try {
            errorMsg = '';
            warningOli = '';
            fromDateError = false;
            forceDateSave = false;
            errorFieldStatus = false;
            DtoItem selDtoItem = lstRecords.get(Integer.valueOf(selPosition));
            //system.debug('selDtoItem ============= >>>>>>>>>>>> ' + selDtoItem);
            OpportunityLineItem selItem = selDtoItem.item;
            Targeting__c srcTar;
            //   String selItemidAsString = selItem.Targeting__c + '';
            if ((selItem.Targeting__c + '') != '') {
                srcTar = [Select Id, 
                        (Select Operator__c, Targeting__c, DART_KeyValue__c, DART_KeyValue__r.Key_Value_Name__c, targetkeyvalue__c From TargetingKeyValueAssociations__r), 
                        //(Select Targeting__c, Country__c, TargetCountry__c From TargetingCountryAssociations__r), 
                        (Select Targeting__c, TargetingContent__c, TargetingContent__r.DartName__c, Exclude__c, Target_Content_Key__c From TargetingContentAssociations__r), 
                        //(Select Targeting__c, City__c, targetcity__c From TargetingCityAssociations__r), 
                        (Select Targeting__c, AreaCode__c, Target_Areacode_Key__c From TargetingAreaCodeAssociations__r),
                        (Select Targeting__c, Geography__c, TargetGeography__c  From TargetingGeographyAssociations__r ),
                        (Select Targeting__c, Device__c, TargetDevice__c From TargetingDeviceAssociations__r),
                        (Select Targeting__c, Connection__c, TargetConnection__c From TargetingConnectionAssociations__r) 
                        From Targeting__c t Where Id =: selItem.Targeting__c];
         
            }
            Boolean isBoolean = false;
            Map < String, Schema.SObjectField > mapOpportItemField = Schema.SObjectType.OpportunityLineItem.fields.getMap();
            Schema.SObjectField so = mapOpportItemField.get(selColumn);

            if (so.getDescribe().getType() == Schema.DisplayType.BOOLEAN) {
                isBoolean = true;
            }

            Map < Integer, Targeting__c > mapTarget = new Map < Integer, Targeting__c > (); // new targeting
            Map < Integer, String > mapTargetId = new Map < Integer, String > (); //existing targetingId

            Map < Integer, OpportunityLineItem > mapOliExist = new Map < Integer, OpportunityLineItem > (); //for save Targeting match with line item  
            for (Integer i = Integer.valueOf(selPosition) + 1; i < lstRecords.size(); i++) {
                if (selColumn == 'UnitPrice') {
                    if (lstRecords.get(i).item.PricebookEntry.Product2.Fixed_price__c == true && (lstRecords.get(i).item.Billing_category__c == 'CPM' || lstRecords.get(i).item.Billing_category__c == 'Fix price' || lstRecords.get(i).item.Billing_category__c == 'CPD')) {
                        continue;
                    }
                } else if (selColumn == 'FC_Quantity__c' || selColumn == 'FC_Ad_Served_Every__c' || selColumn == 'FC_Period__c' || selColumn == 'Check_Inventory__c') {
                    if (lstRecords.get(i).pro.FC__c == false) {
                        continue;
                    }
                } else if (selColumn == 'AdBrowsersMinorVersion__c' || selColumn == 'AdBrowsersMajorVersion__c' || selColumn == 'AdOperatingSystems__c' || selColumn == 'AdWebBrowsers__c') {
                    if (lstRecords.get(i).pro.tech_targeting__c == false) {
                        continue;
                    }

                } else if (selColumn == 'Length_Months__c' ) {
                    if (lstRecords.get(i).pro.MonthsDays__c == false) {
                        continue;
                    }
                } else if (selColumn == 'until_Date__c') {
                    if (lstRecords.get(i).pro.ManualSetEndDate__c == false) {
                        continue;
                    }
                } else if (selColumn == 'AdDayofWeek__c' || selColumn == 'AdHourofDay__c' || selColumn == 'AdKeywords__c' || selColumn == 'Keywords_KeyValue_combination__c') {
                    if (lstRecords.get(i).pro.Time__c == false) {
                        continue;
                    }
                } else if (selColumn == 'Countries_Description__c' || selColumn == 'City_Description__c' || selColumn == 'Regions_Description__c') {
                    if (lstRecords.get(i).pro.Geo_IP__c == false) {
                        continue;
                    }
                }

                OpportunityLineItem tmp = lstRecords.get(i).item;
                if (!force) {
                    if ((!isBoolean && tmp.get(selColumn) != null && tmp.get(selColumn) != '') || (isBoolean && (tmp.get(selColumn) == selItem.get(selColumn)))) {
                        //break;
                        if (mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.Double || mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.Integer || mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.CURRENCY) {
                            if (tmp.get(selColumn) != 0) {
                                continue;
                            }
                        } else {
                            continue;
                        }
                    }
                }
                tmp.put(selColumn, selItem.get(selColumn));
               
                // Placement targeting 18-12-2013 Sreymol
                if (selColumn == 'PlacementTargeting__c') {
                    tmp.put('Placement_Targeting__c', selItem.get('Placement_Targeting__c'));
                }
                
                //HCS 19.12.2014 ListPriceCorrectionType__c for  ListPriceCorrectionType__c
                 if (selColumn == 'ListPriceCorrection__c') {
                    tmp.put('ListPriceCorrectionType__c', selItem.get('ListPriceCorrectionType__c'));
                }
                //-----------------//
                //Tree copier down direction: copy all tree relation of srcProduct to another
                if (srcTar <> null) {
                    //dirrectly comparation cause invalid id while id == null
                    String idAsString = tmp.Targeting__c;
                    system.debug('idAsString ======== ' + idAsString);
                    Targeting__c tmpTar;
                    if (idAsString == '' || idAsString == null) {
                        tmpTar = new Targeting__c(TempBinder__c = true, Description__c = selDtoItem.productName + ' targeting');
                        //insert tmpTar;
                        mapTarget.put(i, tmpTar);
                        mapOliExist.put(i, tmp);
                        //tmp.Targeting__c = tmpTar.Id;
                    } else {
                        mapTargetId.put(i, idAsString);
                    }
                }
            }

            for (Integer i = Integer.valueOf(selPosition) - 1; i >= 0; i--) {
                if (selColumn == 'UnitPrice') {
                    if (lstRecords.get(i).item.PricebookEntry.Product2.Fixed_price__c == true && (lstRecords.get(i).item.Billing_category__c == 'CPM' || lstRecords.get(i).item.Billing_category__c == 'Fix price')) {
                        continue;
                    }
                } 
                else if (selColumn == 'FC_Quantity__c' || selColumn == 'FC_Ad_served_every__c' || selColumn == 'FC_Period__c' || selColumn == 'Check_Inventory__c') {
                    if (lstRecords.get(i).pro.FC__c == false) {
                        continue;
                    }
                } else if (selColumn == 'AdBrowsersMinorVersion__c' || selColumn == 'AdBrowsersMajorVersion__c') {
                    if (lstRecords.get(i).pro.tech_targeting__c == false) {
                        continue;
                    }
                } else if (selColumn == 'Length_Months__c') {
                    if (lstRecords.get(i).pro.MonthsDays__c == false) {
                        continue;
                    }
                } else if (selColumn == 'until_Date__c') {
                    if (lstRecords.get(i).pro.ManualSetEndDate__c == false) {
                        continue;
                    }
                }

                OpportunityLineItem tmp = lstRecords.get(i).item;

                if (!force) {
                    if ((!isBoolean && tmp.get(selColumn) != null && tmp.get(selColumn) != '') || (isBoolean && (tmp.get(selColumn) == selItem.get(selColumn)))) {
                        // break;
                        if (mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.Double || mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.Integer || mapOpportItemField.get(selColumn).getDescribe().getType() == Schema.DisplayType.CURRENCY) {
                            if (tmp.get(selColumn) != 0) {

                                continue;
                            }
                        } else {
                            continue;
                        }


                    }
                }
                tmp.put(selColumn, selItem.get(selColumn));
              
                // Placement targeting 18-12-2013 Sreymol
                if (selColumn == 'Placement_Targeting__c') {
                    tmp.put('Placement_Targeting__c', selItem.get('Placement_Targeting__c'));
                }
                //-----------------//

                //Tree copier up direction: copy all tree relation of srcProduct to another
                if (srcTar <> null) {
                    String idAsString = tmp.Targeting__c;
                    if (idAsString == '' || idAsString == null) {
                        Targeting__c tmpTar = new Targeting__c(TempBinder__c = true, Description__c = selDtoItem.productName + ' targeting');
                        //insert tmpTar;
                        mapTarget.put(i, tmpTar);
                        mapOliExist.put(i, tmp);
                        //tmp.Targeting__c = tmpTar.Id;
                    } else {
                        mapTargetId.put(i, idAsString);
                    }

                }

            }
            //insert new targeting to pull ids 
            insert mapTarget.values();

            //match line item and targeting
            for (Integer keymap: mapOliExist.keySet()) {
                mapOliExist.get(keymap).Targeting__c = mapTarget.get(keymap).Id;
            }


            Map < String, Targeting__c > mapTarget2 = new Map < String, Targeting__c > (); //k= new tID; v = src

            for (Targeting__c t: mapTarget.values()) { //put new ids
                mapTarget2.put(t.Id, srcTar);
            }
            for (String idAsString: mapTargetId.values()) { //put existing ids
                mapTarget2.put(idAsString, srcTar);
            }
            mapTargetId = null;
            mapTarget = null;
            // rich copy
            if (selColumn == 'Rich_Line_Description__c') {
                //copyTargetContent (srcTar , tmp.Targeting__c);
                copyTargetContent(mapTarget2);
            } else if (selColumn == 'KeyValueString__c') {
                //copyTargetKeyValue (srcTar , tmp.Targeting__c);
                copyTargetKeyValue(mapTarget2);
            //Sreymol 02/04/2014
           // } else if (selColumn == 'CountriesDescription__c') {
           } else if (selColumn == 'Countries_Description__c') {
             //-----------------end-------------------------//
                //copyTargetCountry (srcTar , tmp.Targeting__c);
                copyTargetCountry(mapTarget2);
            //Sreymol 02/04/2014
            //} else if (selColumn == 'TargetCitiesString__c') { 
            } else if (selColumn == 'City_Description__c') {
            //-----------------end-------------------------//
                //copyTargetCity(srcTar , tmp.Targeting__c);
                copyTargetCity(mapTarget2);
            } else if (selColumn == 'AreaCode_Description__c') {
                //copyTargetAreacode(srcTar , tmp.Targeting__c);
                copyTargetAreacode(mapTarget2);
            }
            // Placement Targeting by Suy Sreymol on 18-Dec-2013
            else if (selColumn == 'Placement_Targeting__c') {
                copyPlacementTargeting(mapTarget2);
            //-----------------------------------------------------//
            //Sreymol 02/04/2014
            } else if (selColumn == 'Regions_Description__c') {
              copyTargetRegion(mapTarget2);
            }
      //---------------------------end--------------------------//
            if (selColumn == 'Quantity' || selColumn == 'Length_Months__c') {
                reEvaluateSalesPrice();
            }else if(selColumn == 'Connection_Targeting__c'){
                copyTargetingDevices(mapTarget2);
            }else if(selColumn == 'Device_Targeting__c'){
                copyTargetingConnections(mapTarget2);
                copyTargetingDevices(mapTarget2); //@vitou 25-08-2015
            }else if(selColumn == 'Geography__c'){
                copyTargetGeography(mapTarget2);
            }
            
          

            gotoPage();
            warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
        } catch (Exception e) {
            Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
            Apexpages.addMessage(msg);
        }
    }


    public PageReference copyField() {
        try {
            doCopy(false);

            warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
        } catch (Exception e) {
            Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
            Apexpages.addMessage(msg);
        }
        return null;
    }
    public PageReference forceCopyField() {
        try {
            doCopy(true);
            warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
        } catch (Exception e) {
            Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
            Apexpages.addMessage(msg);
        }
        return null;
    }
    //back to previous page
    public PageReference goBack() {
        return new PageReference(backUrl);
    }

    private static Map < String, Schema.SObjectField > mapCampaignItemField = Schema.SObjectType.OpportunityLineItem.fields.getMap();
    //add Fields which are needed for modifying 
    public static Set < String > mainFields = new Set < String > ();
    static {
        mainFields.add('OpportunityId');
        mainFields.add('until_Date__c');
        mainFields.add('from_Date__c');
        mainFields.add('UnitPrice');
        mainFields.add('Targeting_Surcharge__c');
        
        mainFields.add('Auto_Targeting_Surcharge__c');
        mainFields.add('Discount');   
        mainFields.add('SalesPriceNet__c'); // Bunhor @23-04-14 
        mainFields.add('Sales_Price_Target__c'); 
        
        mainFields.add('Check_Inventory__c');
        mainFields.add('Quantity');
       // mainFields.add('TotalPrice');
        mainFields.add('BillingCalc__c');

        mainFields.add('Length_Months__c');

        mainFields.add('FC_Quantity__c');
        mainFields.add('FC_Ad_Served_Every__c');
        mainFields.add('FC_Period__c');
        mainFields.add('AdOperatingSystems__c');

        mainFields.add('AdKeyWords__c');
        mainFields.add('AdHourofDay__c');
        mainFields.add('AdDayofWeek__c');
        mainFields.add('Keywords_KeyValue_combination__c');

        mainFields.add('AdBrowsersMinorVersion__c');
        mainFields.add('AdBrowsersMajorVersion__c');
        mainFields.add('ListPriceCorrection__c');
        mainFields.add('ListPriceCorrectionType__c');

        mainFields.add('Description');
        mainFields.add('Billing_category__c');
        mainFields.add('Availability__c');
        mainFields.add('PricebookEntryId');
        mainFields.add('AdWebBrowsers__c');
        mainFields.add('Rebate_In_Kind_Reason__c');   

        mainFields.add('Rich_Line_Description__c');
        mainFields.add('Targeting__c');
        mainFields.add('KeyValueString__c');
        mainFields.add('Countries_Description__c');
        mainFields.add('City_Description__c');
        mainFields.add('Regions_Description__c');
        mainFields.add('Surcharge_Type__c');
        mainFields.add('Discount_Type__c');
        mainFields.add('Budget_NetNetNet__c');
        //------------end------------------//
        // Add placement targeting on 18-12-2013 by Sreymol
        mainFields.add('Placement_Targeting__c');
        // @vitou 25-08-2015 : Add device targeting
        mainFields.add('Device_Targeting__c');
    }
    //To enable addError for cloned sobject,this method is used instead of clone() method 
    //addError bug should be fixed?
    private OpportunityLineItem createClone(String productName, OpportunityLineItem srcObj, String idOpli) {
        OpportunityLineItem cItm;
        if (srcObj.Id == null || idOpli == '') {
            cItm = new OpportunityLineItem();
        } else {
            cItm = new OpportunityLineItem(id = idOpli);
        }
        for (String fn: mainFields) {

            if (srcObj.get(fn) == null) continue;
            system.debug('fn======'+ fn);
            if (mapCampaignItemField.get(fn).getDescribe().getType() == Schema.DisplayType.DATETIME) {
                cItm.put(fn, Datetime.valueOfGmt(srcObj.get(fn) + ''));

            } else {

                //Field OpportunityId is not editable 
                if (idOpli != '' && (fn == 'OpportunityId' || fn == 'PricebookEntryId')) continue;
                //if(cItm.OpportunityId != null && fn == 'OpportunityId') continue;
                cItm.put(fn, (srcObj.get(fn)));
            }

        }
        if (!mainFields.contains('PricebookEntry')) { // 2011-01-11 St.Voss - enable Usage of Product Properties while cloning Lines
            cItm.PricebookEntry = srcObj.PricebookEntry;
        }
    cItm.Opportunity = srcObj.Opportunity;// Bunhor @1-May-14
    system.debug('cItm======'+ cItm);
        //OpportunityLineItem cItm = srcObj.clone(false,true);// not preserve id, deep clone
        return cItm;

    }
    
    
    /*
      HCS use poller for save record
      24.07.2014
    */
    List<DtoItem> lstAllRecords = new List<DtoItem>();
    private Integer RECORD_COUNT_FOR_RUN_POLLER = 20;
    private Integer RECORD_SPLIT_COUNT = 10;
    public Boolean isPollerMode{get;set;} 

    public final String X_ACCOUNT_ID = '0017000000jhcnE'; //test='001T000000nkP4W';// 15 char
    //save campaign items to media campaign
    public PageReference saveRecords() {
      	GlobalUtils.LineItemsIsExecutingUpdateRevenues = false;
        reEvaluateAll();
        isSave = true;
        errorMsg = '';
        warningOli = '';
        //UTIL.log('saveRecords: ' + lstRecords);
        if (lstRecords.isEmpty()) {
            errorMsg = system.Label.No_value_to_insert;
            return null;
        }
        
          //HCS fixed Too many DML rows: 10001 and Too many query :101
        //24.07.2014
        //case no more record for process
        if( isPollerMode && lstAllRecords.isEmpty()){
           isPollerMode = false;
           return new Pagereference('/'+id);
        }

        List < OpportunityLineItem > lstCamItem = new List < OpportunityLineItem > ();
        errorFieldStatus = false;
        fromDateError = false;

        String ErrorTab = '';

        BP_Collision = '';
        
        //HCS fixed Too many DML rows: 10001 and too many query 101
        //24.07.2014
        if( !isPollerMode ){
          //generate BPCheckAll rather than soql in the loop
          if ((AccId + 'xxxxxxxxxxxxxxx').substring(0, 15) == X_ACCOUNT_ID && oppProb >= 25 && !forceDateSave) {
              Set < String > siteNames = new Set < String > ();
              Set < String > placementDBNames = new Set < String > ();
              List < Date > fDates = new List < Date > ();
              List < Date > tDates = new List < Date > ();
  
  
              for (DtoItem dto: lstRecords) {
                  siteNames.add(dto.item.PricebookEntry.Product2.Site__r.Name);
                  placementDBNames.add(dto.item.PricebookEntry.Product2.Placement__r.Name);
                  fDates.add(dto.item.from_Date__c);
                  tDates.add(dto.item.until_Date__c);
              }
              fDates.sort();
              tDates.sort();
              Date fd = fDates.get(0);
              Date td = tDates.get((tDates.size() - 1));
  
              siteNames = null;
              placementDBNames = null;
              fDates = null;
              tDates = null;
          }
                  
          
          for (DtoItem dto: lstRecords) {

              //Validate the required fields and addError to the correct fields
              //suy sreymol 21/08/2014 : start date must be the 1st of month when product is a feature package
              if (dto.item.Pricebookentry.Product2.Product_SubType__c != null && dto.item.Pricebookentry.Product2.Product_SubType__c.contains(FEATURE_PACKAGE) && dto.item.from_Date__c != null && dto.item.from_Date__c != dto.item.from_Date__c.toStartOfMonth()) {
                  dto.item.from_Date__c.addError(system.Label.From_Date_feature_package_validation);
                  errorFieldStatus = true;
                  if (ErrorTab == '') {
                      ErrorTab = 'name1';
                  }
              }
  
              if (dto.item.from_Date__c == null) {
                  dto.item.from_Date__c.addError(system.Label.Empty_value);
                  errorFieldStatus = true;
                  if (ErrorTab == '') {
                      ErrorTab = 'name1';
                  }
              }
  
              if (dto.item.until_Date__c == null && (dto.item.Pricebookentry.Product2.RecordType.Name == 'DART5' || dto.item.Pricebookentry.Product2.RecordType.Name == 'DART6')) {
                  dto.item.until_Date__c.addError(system.Label.Empty_value);
                  errorFieldStatus = true;
                  if (ErrorTab == '') {
                      ErrorTab = 'name1';
                  }
              }
  
              if (!forceDateSave) {
                  if (dto.item.from_Date__c != null && dto.item.from_Date__c < System.today()) {
                      dto.item.from_Date__c.addError(system.Label.Error_from_date);
                      fromDateError = true;
                      if (ErrorTab == '') {
                          ErrorTab = 'name1';
                      }
                  }
              }
  
              if (dto.item.until_Date__c != null && dto.item.from_Date__c != null && dto.item.until_Date__c < dto.item.from_Date__c) {
                  dto.item.until_Date__c.addError(system.Label.Error_until_date);
                  errorFieldStatus = true;
                  if (ErrorTab == '') {
                      ErrorTab = 'name1';
                  }
              }
  
              if (dto.item.Billing_category__c == null) {
                  dto.item.Billing_category__c.addError(system.Label.Empty_value);
                  errorFieldStatus = true;
                  if (ErrorTab == '') {
                      ErrorTab = 'name2';
                  }
              }           
   
              if (dto.item.Quantity == null || dto.item.Quantity == 0) {
                  dto.item.Quantity.addError(system.Label.Empty_value);
                  errorMsg = 'Quantity: ' + system.Label.Empty_value;
                  errorFieldStatus = true;
                  if (ErrorTab == '') {
                      ErrorTab = 'name2';
                  }
              }
            
              //@Sreymol 20-Mar-2014
              // if(dto.item.UnitPrice==null ||  dto.item.UnitPrice == 0)
              if (dto.item.UnitPrice == null) {
                  //--------------end------------------//
                  dto.item.UnitPrice.addError(system.Label.Empty_value);
                  errorFieldStatus = true;
                  if (ErrorTab == '') {
                      ErrorTab = 'name2';
                  }
              } 
              
              // Bunhor(01-Apr-14):
            if( dto.getErrDiscountReason() != ''){
            //if(dto.item.Rate_Discount_II__c > 0 && dto.item.Rebate_In_Kind_Reason__c ==null) 
              dto.item.Rebate_In_Kind_Reason__c.addError(system.Label.Error_Discount_Reason);
              errorFieldStatus=true;
              if (ErrorTab=='') {
                ErrorTab='name2';
              }
            } 
          
              //@Sochanra 26-03-2014
              //dcc 2014-03-26 added so that rich line description OR placement targeting are required, but not both.
            if (((!dto.isFixedSite && dto.isHasSite) && (dto.item.Rich_Line_Description__c=='' || dto.item.Rich_Line_Description__c==null)) && (dto.item.Placement_Targeting__c=='' || dto.item.Placement_Targeting__c==null))
            {
              dto.item.Rich_Line_Description__c.addError('Category Targeting or Placement Targeting are required in order to save a record.');
              errorFieldStatus=true;
              if (ErrorTab=='') {
                  ErrorTab='tabname6';
              }
            } 
    
       
              if (ErrorTab != '') {
                  ActiveTab = ErrorTab;
              }
  
              if (dto.item.UnitPrice > 0 && dto.item.Quantity > 0) {
                  //dto.item.Net_Net_Net__c = dto.item.UnitPrice * dto.item.Quantity;
              }
              
        }
          
        }
        
        
        if (errorFieldStatus || fromDateError) {
            return null;
        }

       //HCS fixed Too many DML rows: 10001 and Too many Query :101
      //24.07.2014
       Map<String, OpportunityLineItem> mapOpliMain = new Map<String, OpportunityLineItem>();  
      if( lstRecords.size() > RECORD_COUNT_FOR_RUN_POLLER ){
        isPollerMode = true;
        lstAllRecords = lstRecords;      
      }
      if( isPollerMode ){
        lstRecords = new List<DtoItem>();
        for(Integer i= lstAllRecords.size()-1 ;i >= 0 ; i-- ){
            if( lstRecords.size() >= RECORD_SPLIT_COUNT ) break;
            DtoItem dto = lstAllRecords.get(i);
            lstRecords.add( dto );
            lstAllRecords.remove(i);               
        }
      }
      
       for(DtoItem dto:lstRecords){  
         mapOpliMain.put(dto.dtoId+'', dto.item); 
       }   
       
       
        lstCamItem.addall(mapOpliMain.values());
       
        createTargeting4ProFixedSite(lstRecords);
        
        createTargetingFromPredifined(mapOpliMain.values());

        //get all package component related package main
        //set the calculated price for each package component (during the saving process of the visualforce page) to the new field "component_price__c" and set the standard field salesprice to 0

        //Map < String, OpportunityLineItem > mapOli = new Map < String, OpportunityLineItem > ();

        //  mapOli = createPackageComponent(mapOpliMain);
        //mapOli = createUpdatePackCom(mapOpliMain);

        //add all product package component to main list to save
        //lstCamItem.addall(mapOli.values());
        try {

            if (!delItem.isEmpty()) {
                delete[Select Id From OpportunityLineItem Where Id In: delItem];
            }
            
            //Sreymol 08/04/2014 - #3090:KCA-7345 Free Features for Compensation
            List<OpportunityLineItem> existingOli = new List<OpportunityLineItem>();
            // If add new Product, select all the existing line item to check if they are free product or not
            if (!isEdit) {
              for (OpportunityLineItem existingitem : existingItems) existingOli.add(existingitem); //@suy sreymol 11/3/15 //[Select Id, PricebookEntry.Product2.FreeProduct__c From OpportunityLineItem Where OpportunityId = : id]) {
            }
            existingOli.addAll(lstCamItem);
            
            Integer freeProductCounter = 0;
            Integer nonFreeProductCounter = 0;
            for (OpportunityLineItem oli : existingOli) {
               if (oli.PricebookEntry.Product2.FreeProduct__c) freeProductCounter++;
               else nonFreeProductCounter++;
            }
            
            /**
             For each Opportunity, if a Product is added to the Opportunity and it has the checkbox checked on the related Product2, 
             then ONLY Opportunity Line Items with this checkbox can be used. This means that:
       a) If OpportunityLineItem #1 with Product2__r.FreeProduct__c = true and 
       b) If OpportunityLineItem #2 with Product2__r.FreeProduct__c = false
       This throws an error and the user must select either another product which is a free product or remove the free products to add a new non-free product to the Opportunity.
            */
            if (freeProductCounter != 0 && nonFreeProductCounter != 0) {
              errorMsg = system.Label.Free_Product_Error_Message;
              return null;
            }
            //----------------------------08/04/2014-------------------------------//
            system.debug('lstCamItem========'+ lstCamItem);
            upsert lstCamItem;
      
            // updatePackageComponent(mapOli, mapOpliMain);

            Integer days = 0;
            Boolean asyncRevenues = false;
            //        Set<Id> oliIds = new Set<Id>();

            Set < Id > countTargetingId = new Set < Id > ();

            for (OpportunityLineItem ols: lstCamItem) {
                String s = String.valueOf(ols.Targeting__c);
                if (s != null && ((s + '') != '')) {
                    countTargetingId.add(ols.Targeting__c);
                }

                days += ols.from_Date__c.daysBetween(ols.until_Date__c);
               
                if (days > 50 && !asyncRevenues) {
                    asyncRevenues = true;
                }
                
            }

         
          
           

            //Clear the basket after saving Campaign Items to Media Campaign  
            if (camItems == null) {
                delete[Select Id, AdPriceIdText__c From Media_Basket__c where UserId__c = : System.userInfo.getUserId() AND OpportunityId__c = : id];
            }


        } catch (Exception e) {
            System.debug('========error : ' + e);
            errorMsg = e + '';
            Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, errorMsg);
            Apexpages.addMessage(msg);
             if( isPollerMode ){ // Bunhor @19-Mar-15: adding IF to avoid error "system.Label.No_value_to_insert" 
                isPollerMode = false;
                lstRecords  = lstAllRecords; 
            }
            return null;
        }

        //refresh Targeting__c for each LineItem
        Set < String > savedTar = new Set < String > ();
        for (OpportunityLineItem item: lstCamItem) {
            savedTar.add(item.Targeting__c);
        }

        List < Targeting__c > ltar = new List < Targeting__c > ();
        for (Targeting__c tar: [Select Id, TempBinder__c From Targeting__c Where Id In: savedTar]) {
            tar.TempBinder__c = false;
            ltar.add(tar);
        }
        update ltar;

         //Imediately return to Media Campaign detail page
      return  isPollerMode ? null : new Pagereference('/'+id);  
    }


    /**
     *   Method for check product that is fixed site to create targeting
     */
    private void createTargeting4ProFixedSite(List < DtoItem > lstRec) {


        Map < String, String > mTargeting = new Map < String, String > (); //for store all targeting Id from product that is fixed site
        Map < String, List < String >> mAvilableSite = new Map < String, List < String >> (); //for store all available sites from product that is fixed site
        Map < String, Targeting__c > mTarNotExsit = new Map < String, Targeting__c > (); //for store all targeting not exist from product that is fixed site
        Set < String > sAvaiSiteName = new Set < String > (); //store all available site name

        //get targeting from opli which product is Fixed site
        for (DtoItem dto: lstRecords) {
            //HCS 22.01.2015
            if( String.isEmpty( dto.item.Targeting__c ) ){
                 Targeting__c t = new Targeting__c(TempBinder__c = true, Description__c = 'TargetingTreeProduct');
                 mTarNotExsit.put(dto.dtoId + '', t);
                 if( String.isNotEmpty(dto.item.Rich_Line_Description__c) ){
                      String strTmp = dto.item.Rich_Line_Description__c;
                           String keyMap = dto.dtoId + '';
                           //check has 1 or more available site
                        if (strTmp.contains(' , ')) {
                            
                            //split string available site 
                            for (String avSite: strTmp.split(' , ')) {
                                sAvaiSiteName.add(avSite);
    
                                if (!mAvilableSite.containsKey(keyMap)) {
                                    mAvilableSite.put(keyMap, new List < String > ());
                                }
                                mAvilableSite.get(keyMap).add(avSite);
                            }
                        } else {
                            mAvilableSite.put(keyMap, new List < String > {
                                strTmp
                            });
                            sAvaiSiteName.add(strTmp);
                        }
                    
                 }
            }else{
                 mTargeting.put(dto.dtoId + '', dto.item.Targeting__c);
            }
            //End
            if (dto.isFixedSite) {
                //put avialable site to map
                String avaiSite = (dto.availableSite + '' != '' ? dto.availableSite : '');
                if (avaiSite != '') {
                    //check has targeting or not. If not create new one
                    //HCS 22.01.2015
                   /* if (dto.item.Targeting__c + '' == '') {
                        Targeting__c t = new Targeting__c(TempBinder__c = true, Description__c = 'TargetingTreeProduct');
                        mTarNotExsit.put(dto.dtoId + '', t);
                    } else {
                        mTargeting.put(dto.dtoId + '', dto.item.Targeting__c);
                    }*/

                    String keyMap = dto.dtoId + '';

                    //remove last "." from available site name 
                    String strTmp = avaiSite.substring(0, avaiSite.length() - 1);

                    //check has 1 or more available site
                    if (strTmp.contains(' , ')) {



                        //split string available site 
                        for (String avSite: strTmp.split(' , ')) {
                            sAvaiSiteName.add(avSite);

                            if (!mAvilableSite.containsKey(keyMap)) {
                                mAvilableSite.put(keyMap, new List < String > ());
                            }
                            mAvilableSite.get(keyMap).add(avSite);
                        }
                    } else {
                        mAvilableSite.put(keyMap, new List < String > {
                            strTmp
                        });
                        sAvaiSiteName.add(strTmp);
                    }
                }
            }
            
            
        }



        //create new targeting
        try {
            if (!mTarNotExsit.isEmpty()) {
                insert mTarNotExsit.values();
            }
        } catch (Exception ex) {
            Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, ex.getMessage());
            Apexpages.addMessage(msg);
        }

        //put new targeting to all product that is fixed site
        for (DtoItem dto: lstRecords) {
            //HCS 22.01.2015
            if(String.isEmpty(dto.item.Targeting__c ) ){
                 if (!mTarNotExsit.containsKey(dto.dtoId + '')) continue;
                 dto.item.Targeting__c = mTarNotExsit.get(dto.dtoId + '').Id;
            }
            
           /* if (dto.isFixedSite) {
                if (dto.item.Targeting__c + '' == '') {
                    if (!mTarNotExsit.containsKey(dto.dtoId + '')) continue;
                    dto.item.Targeting__c = mTarNotExsit.get(dto.dtoId + '').Id;
                }
            }*/
        }

        //put all targeting ids in one list
        for (String keymap: mTarNotExsit.keySet()) {
            mTargeting.put(keymap, mTarNotExsit.get(keymap).Id);
        }


        List < String > idTar = new List < String > (); //store id targeting 
        Map < String, String > mTmp = new Map < String, String > (); //store all targeting that has no content targeting


        for (String keyMap: mTargeting.keySet()) {
            idTar.add(mTargeting.get(keyMap));
            mTmp.put(mTargeting.get(keyMap), keyMap);
        }

        //check targeting has targetingContentAssociate or not 
        //if has content Associate already, don create
        for (Targeting__c lTar: [select Id, (Select Id From TargetingContentAssociations__r limit 1) from Targeting__c where id in : idTar]) {
            if (lTar.TargetingContentAssociations__r.size() > 0) {
                mTmp.remove(lTar.Id);
            }
        }

        Map < String, String > mContent = new Map < String, String > (); //store id Content
        for (Content__c content: [Select id, Name, DartName__c from Content__c where DartName__c in : sAvaiSiteName]) {
            mContent.put(content.DartName__c, content.Id);
        }

        List < TargetingContentAssociation__c > lstTarCon = new List < TargetingContentAssociation__c > ();
        Set < String > tarId = new Set < String > ();
        Set < String > assoNotToDelete = new Set < String > ();

        //create content targeting
        for (String keyIdDTO: mTmp.values()) {
            if (!mAvilableSite.containsKey(keyIdDTO)) continue;
            for (String avaiSiteName: mAvilableSite.get(keyIdDTO)) {
                String ex_key = ''; //targeting id + Content ID
                String targetingId = mTargeting.get(keyIdDTO);

                String contentName = avaiSiteName;

                String contentId = mContent.get(contentName);
                ex_key = targetingId + contentId;
                TargetingContentAssociation__c tarCon = new TargetingContentAssociation__c(Targeting__c = targetingId, TargetingContent__c = contentId, Exclude__c = false, Target_Content_Key__c = ex_key);
                lstTarCon.add(tarCon);
                tarId.add(targetingId);
                assoNotToDelete.add(ex_key);
            }
        }
        try {
            if (!lstTarCon.isEmpty()) {
                upsert lstTarCon;
                delete[Select Id From TargetingContentAssociation__c Where Targeting__c in : tarId And Target_Content_Key__c Not In: assoNotToDelete];

            }
        } catch (Exception ex) {
            Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, ex.getMessage());
            Apexpages.addMessage(msg);
        }



    }

   

    private void createKeyValue4PC(Map < String, OpportunityLineItem > mapOli) {
        Map < String, Targeting__c > mapTarId = new Map < String, Targeting__c > ();

        //get all Dart Key value 2 that is parent
        //Map<String, String> mapNodeId = new Map<String, String>();

        // Every Dart KeyValue that have Node_ID__c = null 
        // => key_Value__c = Key__c
        //for(DART_KeyValue_2__c d: [select id, key__c, Key_Value__c from DART_KeyValue_2__c where Node_ID__c = null]){
        //  mapNodeId.put(d.key_Value__c, d.Id);
        //}

        Set < String > kv = new Set < String > ();

        for (String keyMap: mapOli.keySet()) {

            //check has targeting or not 
            //if not, create new 
            if (mapOli.get(keyMap).Targeting__c + '' == '') {
                Targeting__c tmpTar = new Targeting__c(TempBinder__c = true, Description__c = keyMap.split('_##_')[0] + ' targeting');
                mapTarId.put(keyMap, tmpTar);
            }

            OpportunityLineItem opli = mapOli.get(keyMap);
            String preKeyValue = opli.KeyValueString__c + '';

            //check KeyValueString is null or not
            if (preKeyValue != '') {

                //KeyValue: '((fse=353) OR (fse=9800) (fse=2032) OR (fse=15032)) OR (cat=293 OR tcat=293))

                List < String > lstKeyValues = getValueExp(EXP_GETKEYVALUE, preKeyValue);

                for (String s: lstKeyValues) {
                    //kv.add('%' + s + '%');
                    kv.add(s);
                }

            }

        }

        //List<DART_KeyValue_2__c> lstDart = new List<DART_KeyValue_2__c>([select id, Node_ID__c,Node_ID__r.Key__c, Name, Key_Value__c from DART_KeyValue_2__c where Key_Value__c like : kv ]);
        List < DART_KeyValue_2__c > lstDart = new List < DART_KeyValue_2__c > ([select id, Node_ID__c, Node_ID__r.Key__c, Name, Key_Value__c from DART_KeyValue_2__c where Key_Value__c IN: kv]);

        //Map<String, List<DART_KeyValue_2__c>> mapNodeDart = new Map<String, List<DART_KeyValue_2__c>>();
        Map < String, List < KeyValueDTO >> mapNodeDart = new Map < String, List < KeyValueDTO >> ();


        // Sochanra Yos: 13-09-2013
        // Mapping key+keyValue and NodeId to get unique record with parent's key and child's KeyValue 
        Map < String, String > mapKeyNodeDartId = new Map < String, String > ();

        for (DART_KeyValue_2__c d: lstDart) {
            if (!mapNodeDart.containsKey(d.Node_ID__c)) {
                mapNodeDart.put(d.Node_ID__c, new List < KeyValueDTO > ());
            }

            mapNodeDart.get(d.Node_ID__c).add(new KeyValueDTO(d.Id, d.Key_Value__c));
            mapKeyNodeDartId.put(d.Node_ID__r.Key__c + '' + d.Key_Value__c, d.Node_ID__c + '');
        }



        //NK:06/07/2012: from List<String> to Set<String> to fixed  duplicate value when KeyValue = DE Postal Code
        //Bug fixed:  DE Postal Codes(uz):((uz=10*,uz=12*,uz=13*,uz=14* OR uz=20*,uz=21*,uz=22*))
        Map < String, Set < String >> mapDartKeyId = new Map < String, Set < String >> ();

        for (String keyMap: mapOli.keySet()) {
            OpportunityLineItem opli = mapOli.get(keyMap);
            String preKeyValue = opli.KeyValueString__c + '';

            if (preKeyValue != '') {

                // Sochanra Yos: 12-09-2012: Fixed when keyvalues contain "="
                // by using regular expression instead of split by(=)
                // Ex: preKeyValue = '((fse=353) OR (fse=9800) (fse=2032) OR (fse=15032)OR (cat=293 OR tcat=293))
                // => lstKeyValues = (353, 9800, 2032, 15032, 293 OR tcat=293) ex: 353 is keyValue of child node
                // => lstKeys = (fse, fse, fse, fse, cat) ex: fse is key of parent node

                // EXP_GETKEYVALUE = '(\\(.*?=(.*?)\\))';
                // EXP_GETKEY = '(\\((.*?)\\=.*?)\\)';

                List < String > lstKeyValues = getValueExp(EXP_GETKEYVALUE, preKeyValue);
                List < String > lstKeys = getValueExp(EXP_GETKEY, preKeyValue.replace('((', '('));

                Integer i = 0;

                for (String strTmp: lstKeys) {
                    String newK = strTmp + lstKeyValues.get(i);
                    String nodeId = mapKeyNodeDartId.get(newK); // newK= parentKey+keyvalue of child
                    if (mapNodeDart.containsKey(nodeId)) {
                        for (KeyValueDTO d: mapNodeDart.get(nodeId)) {
                            //for(DART_KeyValue_2__c d : mapNodeDart.get(nodeId)){
                            //if(d.Key_Value__c.contains(lstKeyValues.get(i))){
                            if (d.dartKeyValue.contains(lstKeyValues.get(i))) {
                                if (!mapDartKeyId.containsKey(keyMap)) {
                                    mapDartKeyId.put(keyMap, new Set < String > ());
                                }
                                //mapDartKeyId.get(keyMap).add(d.Id);
                                mapDartKeyId.get(keyMap).add(d.dartKeyId);
                            }
                        }
                    }

                    i++;
                }

            }
        }

        if (mapTarId.size() > 0) {
            insert mapTarId.values();
        }

        List < TargetingKeyValueAssociation__c > lstTarKey = new List < TargetingKeyValueAssociation__c > ();
        Set < String > lstKeyMap = new Set < String > ();
        Set < String > assoNotToDelete = new Set < String > ();
        // only child product of Package Component
        //(mapPbeChild.get(strTmp).Product2.Name + '_##_'+ mapPbeChild.get(strTmp).Id + '_' + keyMap, opli);
        for (String keyMap: mapOli.keySet()) {
            //  if(mapOli.get(keyMap).Id != null) continue;
            String ex_key = '';
            String tarId = '';
            if (!mapDartKeyId.containsKey(keyMap)) continue;
            OpportunityLineItem opli = mapOli.get(keyMap);
            if (opli.KeyValueString__c + '' == '') continue;
            if (opli.Targeting__c + '' == '') {
                opli.Targeting__c = mapTarId.get(keyMap).Id;
            }
            lstKeyMap.add(opli.Targeting__c);
            for (String s: mapDartKeyId.get(keyMap)) {
                ex_key = opli.Targeting__c + s; //Targeting + DART KeyValue
                lstTarKey.add(new TargetingKeyValueAssociation__c(Targeting__c = opli.Targeting__c, Operator__c = 'OR', DART_KeyValue__c = s, targetkeyvalue__c = ex_key));
                assoNotToDelete.add(ex_key);
            }

        }

        if (lstTarKey.size() > 0) {
            upsert lstTarKey targetkeyvalue__c;
            delete[Select Id From TargetingKeyValueAssociation__c Where Targeting__c in : lstKeyMap And targetkeyvalue__c Not In: assoNotToDelete];
        }

    }


    /**
     * @param strExp: String regular expression
     * @param strKeyValues: String keyValue
     * @return lstKeyVals
     */
    // Sochanra Yos: 10-09-2012
    private List < String > getValueExp(String strExp, String strKeyValues) {
        List < String > lstKeyVals = new List < String > ();
        Matcher m = Pattern.compile(strExp).matcher(strKeyValues);

        while (m.find()) {
            lstKeyVals.add(m.group(2));
        }
        return lstKeyVals;
    }


    private void createTarCont4PC(Map < String, OpportunityLineItem > mapOli, Map < String, String > mapDartContent) {
        Map < String, Targeting__c > mapTarId = new Map < String, Targeting__c > ();

        for (String keyMap: mapOli.keySet()) {
            if (mapOli.get(keyMap).Targeting__c + '' == '') {
                Targeting__c tmpTar = new Targeting__c(TempBinder__c = true, Description__c = keyMap.split('_##_')[0] + ' targeting');
                mapTarId.put(keyMap, tmpTar);
            }
        }

        if (mapTarId.size() > 0) {
            insert mapTarId.values();
        }

        List < TargetingContentAssociation__c > lstTarCon = new List < TargetingContentAssociation__c > ();
        Set < String > lstKeyMap = new Set < String > ();
        Set < String > assoNotToDelete = new Set < String > ();

        for (String keyMap: mapOli.keySet()) {
            //  if(mapOli.get(keyMap).Id != null) continue;
            String ex_key = '';
            String tarId = '';
            if (mapOli.get(keyMap).Targeting__c + '' == '') {
                mapOli.get(keyMap).Targeting__c = mapTarId.get(keyMap).Id;
            }
            ex_key = mapOli.get(keyMap).Targeting__c + mapDartContent.get(keyMap);
            if (mapDartContent.get(keyMap) != null) {
                TargetingContentAssociation__c tarCon = new TargetingContentAssociation__c(Targeting__c = mapOli.get(keyMap).Targeting__c, TargetingContent__c = mapDartContent.get(keyMap), Target_Content_Key__c = ex_key, Exclude__c = false);
                lstTarCon.add(tarCon);
            }
            lstKeyMap.add(mapOli.get(keyMap).Targeting__c);
            assoNotToDelete.add(ex_key);
        }

        if (lstTarCon.size() > 0) {
            upsert lstTarCon Target_Content_Key__c;
            delete[Select Id From TargetingContentAssociation__c Where Targeting__c in : lstKeyMap And Target_Content_Key__c Not In: assoNotToDelete];
        }
    }


    /*
  Split record according to input start date and end date that available to split by calendar week, 2 calendar week, number of months .  
  */

    public PageReference splitRecord() {
        errorMsg = '';
        warningOli = '';
        fromDateError = false;
        forceDateSave = false;
        errorFieldStatus = false;
        decimal newquantity;
        List < DtoItem > splitRecs;
        for (Integer i = 0; i < lstRecords.size(); i++) { //not realy for 
            DtoItem tmp = lstRecords.get(i);
            if (tmp.position == Integer.valueOf(selPosition)) {
                OpportunityLineItem camItem = tmp.item;
                if (camItem.Quantity == null) camItem.Quantity = 0;
                Date startDate = camItem.from_Date__c;
                Date endDate = camItem.until_Date__c;
                if (startDate == null || endDate == null) return null;
                Date initWeek = startDate;
                Date lastSun = startDate;
                Date startTmp = startDate;
                Date lastDate;
                splitRecs = new List < DtoItem > ();
                List < Media_Basket__c > newBaskets = new List < Media_Basket__c > ();

                //Calendar week split         
                if (selShare == 'week') {
                    Integer numWeeks = getNumWeeks(startDate, endDate, false);
                    if (numWeeks > 1) {
                        while (startTmp <= endDate) {
                            if (getDayInWeek(startTmp) == 'Sun') {
                                newquantity = camItem.Quantity / numWeeks;
                                if (newquantity < 1) {
                                    newquantity = 1;
                                }
                                DtoItem newItem = new DtoItem(tmp.productName, getNewCamItem(tmp.productName, camItem, (newquantity).setScale(2), initWeek, startTmp), tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
                                newItem.listBilling = tmp.listBilling; // To copy Billing Category
                                splitRecs.add(newItem);
                                dtoIdRunner = newItem.dtoId;
                                newBaskets.add(createNewBasket(camItem));

                                lastSun = startTmp;
                                initWeek = startTmp.addDays(1);
                            }
                            startTmp = startTmp.addDays(1);
                        }
                        if (lastSun < endDate) {
                            newBaskets.add(createNewBasket(camItem));
                            newquantity = camItem.Quantity / numWeeks;
                            if (newquantity < 1) {
                                newquantity = 1;
                            }
                            DtoItem newItem = new DtoItem(tmp.productName, getNewCamItem(tmp.productName, camItem, (newquantity).setScale(2), initWeek, endDate), tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
                            newItem.listBilling = tmp.listBilling; // To copy Billing Category
                            splitRecs.add(newItem);
                            dtoIdRunner = newItem.dtoId;
                        }
                        lstRecords.remove(i);
                        removeBasket(camItem.PricebookEntryId);
                        lstRecords.addAll(splitRecs);
                        if (camItems == null) {
                            insert newBaskets;
                        }

                        refreshPosition(lstRecords);
                        break;
                    }
                } else if (selShare == 'week2') { //2 Calendar weeks split 
                    Integer numWeeks2 = getNumWeeks(startDate, endDate, true);
                    Integer k = 0;
                    if (numWeeks2 > 1) {
                        while (startTmp <= endDate) {
                            if (getDayInWeek(startTmp) == 'Sun') {
                                k = k + 1;
                                if (Math.mod(k, 2) == 0) {
                                    newquantity = camItem.Quantity / numWeeks2;
                                    if (newquantity < 1) {
                                        newquantity = 1;
                                    }
                                    DtoItem newItem = new DtoItem(tmp.productName, getNewCamItem(tmp.productName, camItem, (newquantity).setScale(2), initWeek, startTmp), tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
                                    newItem.listBilling = tmp.listBilling; // To copy Billing Category
                                    splitRecs.add(newItem);
                                    dtoIdRunner = newItem.dtoId;
                                    newBaskets.add(createNewBasket(camItem));
                                    lastSun = startTmp;
                                    initWeek = startTmp.addDays(1);
                                }
                            }
                            startTmp = startTmp.addDays(1);
                        }
                        if (lastSun < endDate) {
                            newquantity = camItem.Quantity / numWeeks2;
                            if (newquantity < 1) {
                                newquantity = 1;
                            }
                            newBaskets.add(createNewBasket(camItem));
                            DtoItem newItem = new DtoItem(tmp.productName, getNewCamItem(tmp.productName, camItem, (newquantity).setScale(2), initWeek, endDate), tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
                            newItem.listBilling = tmp.listBilling; // To copy Billing Category
                            splitRecs.add(newItem);
                            dtoIdRunner = newItem.dtoId;
                        }
                        lstRecords.remove(i);
                        removeBasket(camItem.PricebookEntryId);
                        lstRecords.addAll(splitRecs);
                        if (camItems == null) {
                            insert newBaskets;
                        }

                        refreshPosition(lstRecords);
                        break;
                    }
                } else if (selShare == 'month') { //Calendar month split  
                    Integer months = getNumMonths(startDate, endDate);
                    If(months > 1) {
                        while (startTmp <= endDate) {
                            lastDate = Date.newInstance(startTmp.year(), startTmp.month(), date.daysInMonth(startTmp.year(), startTmp.month()));
                            if (startTmp == lastDate) {
                                newquantity = camItem.Quantity / months;
                                if (newquantity < 1) {
                                    newquantity = 1;
                                }
                                DtoItem newItem = new DtoItem(tmp.productName, getNewCamItem(tmp.productName, camItem, (newquantity).setScale(2), initWeek, startTmp), tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
                                newItem.listBilling = tmp.listBilling; // To copy Billing Category
                                splitRecs.add(newItem);
                                dtoIdRunner = newItem.dtoId;
                                newBaskets.add(createNewBasket(camItem));
                                initWeek = startTmp.addDays(1);
                                lastSun = startTmp;
                            }
                            startTmp = startTmp.addDays(1);
                        }
                        If(lastSun < endDate) {
                            newBaskets.add(createNewBasket(camItem));
                            newquantity = camItem.Quantity / months;
                            if (newquantity < 1) {
                                newquantity = 1;
                            }
                            DtoItem newItem = new DtoItem(tmp.productName, getNewCamItem(tmp.productName, camItem, (newquantity).setScale(2), initWeek, endDate), tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
                            newItem.listBilling = tmp.listBilling; // To copy Billing Category
                            splitRecs.add(newItem);
                            dtoIdRunner = newItem.dtoId;
                        }
                        lstRecords.remove(i);
                        removeBasket(camItem.PricebookEntryId);
                        lstRecords.addAll(splitRecs);
                        if (camItems == null) {
                            insert newBaskets;
                        }

                        refreshPosition(lstRecords);
                        break;
                    }
                }
            }

        }

        Map < String, OpportunityLineItem > mapOli = new Map < String, OpportunityLineItem > (); //k=product name
        integer pi = 0; //make it unique to bindTreeConfigurator(map)
        for (DtoItem it: splitRecs) {
            mapOli.put(it.productName + '_##_' + pi + '_' + it.dtoId, it.item);
            pi++;
        }

        bindTreeConfigurator(mapOli, false);
        warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';

        gotoPage();
        return null;
    }
    /*
    Delete record from the list
  */
    private Set < Id > delItem = new Set < Id > ();
    public PageReference deleteRecord() {
        errorMsg = '';
        warningOli = '';
        fromDateError = false;
        forceDateSave = false;
        for (Integer i = 0; i < lstRecords.size(); i++) {
            DtoItem tmp = lstRecords.get(i);
            if (tmp.position == Integer.valueOf(selPosition)) {
                OpportunityLineItem camItem = tmp.item;
                removeBasket(camItem.PricebookEntryId);
                lstRecords.remove(i);
                //mapPbe2Id.remove(tmp.dtoId + '');
                mapPackageMain.remove(tmp.dtoId + '');

                if (camItem.Id != null) {
                    delItem.add(camItem.Id);
                }
                break;
            }
        }

        refreshPosition(lstRecords);
        warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
        gotoPage();
        return null;
    }

    //record for display per page
    public static final Integer MAXRECORD = 15;

    public Integer getMAXRECORD() {
        return MAXRECORD;
    }
    public Integer pageNum { get; set; }
    public Boolean disableNext { get; set; }
    public Boolean disablePre { get; set; }

    public Set < Integer > numBtn { get; set; }
    public List < DtoItem > lDisplayRec { get; set; }
    public String disNumOfRecPerPage { get; set; }

    private Decimal getMaxPage() {
        Decimal d = lstRecords.size() / Decimal.valueOf(MAXRECORD);
        return d.round(System.Roundingmode.CEILING);
    }

    private Integer getStartIndexRec(Integer pageNumber) {
        return (pageNumber * MAXRECORD) - MAXRECORD;
    }

    private void setListToDisplay(Integer indexStart, List < DtoItem > lRec) {
        if (indexStart < 0) indexStart = 0;
        lDisplayRec = new List < DtoItem > ();

        Integer lastNumOfRec = lRec.size();
        Integer indexRec = indexStart + 1;
        Integer lastRecPerPage = indexStart + MAXRECORD;

        if (lastRecPerPage > lastNumOfRec) lastRecPerPage = lastNumOfRec;
        disNumOfRecPerPage = system.label.Record + ' ' + indexRec + ' - ' + lastRecPerPage + ' ' + system.label.of + ' ' + lastNumOfRec;
        for (Integer i = indexStart; i < (indexStart + MAXRECORD); i++) {
            if (lRec.size() <= i) break;
            lDisplayRec.add(lRec.get(i));
        }
        system.debug('lDisplayRec>>>>>>' + lDisplayRec);
    }


    public Pagereference gotoPage() {
        numbtn = new Set < Integer > ();

        for (Integer i = 1; i <= Integer.valueOf(getMaxPage()); i++) {
            numbtn.add(i);
        }
        if (pageNum > Integer.valueOf(getMaxPage())) pageNum = Integer.valueOf(getMaxPage());
        if (pageNum == 1 && getMaxPage() > 1) {
            disablePre = true;
            disableNext = false;
        } else if (pageNum >= getMaxPage() && getMaxPage() > 1) {
            disableNext = true;
            disablePre = false;
        } else if (pageNum > 1 && pageNum <= getMaxPage()) {
            disableNext = false;
            disablePre = false;
        } else if (getMaxPage() == 1) {
            disableNext = true;
            disablePre = true;
        }
        setListToDisplay(getStartIndexRec(pageNum), lstRecords);
        return null;
    }

    //go next page
    public Pagereference goNext() {
        pageNum++;
        if (pageNum >= getMaxPage()) {
            pageNum = Integer.valueOf(getMaxPage());
        }
        gotoPage();
        return null;
    }

    //go previous Page
    public Pagereference goPrevious() {
        pageNum--;
        if (pageNum <= 1) {
            pageNum = 1;
        }
        gotoPage();
        return null;
    }



    //SP: 8-8-2011 5.00PM
    public PageReference duplicateRecord() {
        errorMsg = '';
        warningOli = '';
        fromDateError = false;
        forceDateSave = false;
        Map < String, OpportunityLineItem > mapOli = new Map < String, OpportunityLineItem > ();
        DtoItem tmp = lstRecords.get(Integer.valueOf(selPosition));
        for (Integer j = 0; j < Integer.valueOf((SelCopies != null && SelCopies != '' ? SelCopies : '1')); j++) {
            OpportunityLineItem tmpCamItem = createClone(tmp.productName, tmp.item, '');
            mapOli.put(tmp.productName + '_##_' + j, tmpCamItem);
        }

        bindTreeConfigurator(mapOli, false);




        List < Media_Basket__c > lstNBasket = new List < Media_Basket__c > ();
        //15MB response size org limit (>=200)
        for (String keymap: mapOli.keySet()) {
            //DtoItem dt = new DtoItem(keyMap.substring(0, keyMap.length()-2),mapOli.get(keymap));
            //lst2.add(dt);
            //lstRecords.add(new DtoItem(keyMap.split('_##_')[0],mapOli.get(keymap)));

            DtoItem newItem = new DtoItem(keyMap.split('_##_')[0], mapOli.get(keymap), tmp.isFixedSite, tmp.proId, tmp.availableSite, tmp.isHasSite, tmp.availableKV, tmp.billCategory2, tmp.pro, tmp.isHasPreDefine, dtoIdRunner);
            newItem.listBilling = tmp.listBilling; // To copy Billing Category
            dtoIdRunner = newItem.dtoId;
            lstRecords.add(newItem);

            mapPackageMain.put(newItem.dtoId + '', newItem);
            // add new item to basket
            Media_Basket__c nBasket = new Media_Basket__c(adPriceIdText__c = mapOli.get(keymap).PricebookEntryId, OpportunityId__c = id, UserId__c = System.Userinfo.getUserId());
            if (camItems == null) {
                lstNBasket.add(nBasket);
            }
            baskets.add(nBasket);
        }
        insert lstNBasket;
        SelCopies = null;
        refreshPosition(lstRecords);
        warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
        gotoPage();
        return null;
    }

    //Copy current item X times
    public PageReference copyRecords() {
        try {
            warningOli = '';
            duplicateRecord();
            warningOli = lstRecords.size() > 100 ? system.Label.Warning_OppLine : '';
        } catch (Exception e) {
            Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e + '');
            Apexpages.addMessage(msg);
        }
        return null;
    }

    //SP: 8-8-2011 5.00PM
    //Converted to handle Mass Operation
    private void bindTreeConfigurator(Map < String, OpportunityLineItem > mapOli, Boolean isChild) {
        Map < String, Targeting__c > mapTmpOli = new Map < String, Targeting__c > ();
        Map < String, Targeting__c > mapIdTarNTmpTar = new Map < String, Targeting__c > ();
        List < Targeting__c > lstTar = new List < Targeting__c > ();
        Set < String > idTar = new Set < String > ();


        //work on oli.targeting != '', If null, return
        Integer i = 0;
        for (String keyMap: mapOli.keySet()) {

            if ((mapOli.get(keyMap).Targeting__c + '') != '') {
                Targeting__c tmpTar;
                //create new Targeting
                tmpTar = new Targeting__c(TempBinder__c = true, Description__c = keyMap.split('_##_')[0] + ' targeting');
                lstTar.add(tmpTar);
                //get original targeting id
                idTar.add(mapOli.get(keyMap).Targeting__c);

                //map original targeting id and new targeting
                mapIdTarNTmpTar.put(mapOli.get(keyMap).Targeting__c + '_' + i, tmpTar);
                i++;
                mapTmpOli.put(keyMap, tmpTar);
            }
        }

        if (idTar.size() <= 0) return;

        if (lstTar.size() > 0) {
            insert lstTar;
        }
        //Select original targeting
        //Target id have only one after select
        List < Targeting__c > srcTar = [Select Id, 
                          (Select Operator__c, Targeting__c, DART_KeyValue__c, targetkeyvalue__c From TargetingKeyValueAssociations__r), 
                          (Select Targeting__c, Country__c, TargetCountry__c From TargetingCountryAssociations__r), 
                          (Select Targeting__c, TargetingContent__c, Exclude__c, Target_Content_Key__c From TargetingContentAssociations__r), 
                          (Select Targeting__c, City__c, targetcity__c From TargetingCityAssociations__r), 
                          (Select Targeting__c, AreaCode__c, Target_Areacode_Key__c From TargetingAreaCodeAssociations__r), 
                          (Select Name, Targeting__c, PlacementTargeting__c From PlacementTargetingAssociations__r), 
                          (Select Region__c, Targeting__c, TargetRegion__c From TargetingRegionAssociation__r), //Sreymol 02/04/2014
                          (Select Device__c, Targeting__c, TargetDevice__c From TargetingDeviceAssociations__r) //@vitou 25-08-2015
                          From Targeting__c t Where Id in : idTar];

        Map < String, Targeting__c > mapTmp = new Map < String, Targeting__c > ();
        for (Targeting__c t: srcTar) {
            mapTmp.put(t.Id, t);
        }

        Map < String, Targeting__c > mapTarget = new Map < String, Targeting__c > ();

        for (String keymap: mapIdTarNTmpTar.keySet()) {
            String tm = keymap.split('_')[0];
            mapTarget.put(mapIdTarNTmpTar.get(keymap).Id, mapTmp.get(tm));


        }

        //if create by product component(child), not create targetContent and Keyvalue
        if (!isChild) {
            copyTargetContent(mapTarget);
            copyTargetKeyValue(mapTarget);
        }
        copyTargetCountry(mapTarget);
        copyTargetCity(mapTarget);
        copyTargetAreacode(mapTarget);
        copyPlacementTargeting(mapTarget);
        copyTargetRegion(mapTarget); //Sreymol 02/04/2014
        copyTargetingDevices(mapTarget); //@vitou 25-08-2015

        for (String keymap: mapOli.keySet()) {
            if ((mapOli.get(keyMap).Targeting__c + '') != '') {
                if (mapOli.containsKey(keymap)) {
                    mapOli.get(keymap).Targeting__c = mapTmpOli.get(keyMap).Id;
                }
            }
        }

    }


    
    
    //Converted to handle Mass Operation
    private void copyTargetContent(Map < String, Targeting__c > mapTarget) {
        Set < String > assoNotToDelete = new Set < String > ();
        List < TargetingContentAssociation__c > lcontent = new List < TargetingContentAssociation__c > ();
        Set < String > lstKeyMap = mapTarget.keySet();

        for (String keyMap: mapTarget.keySet()) {
            Targeting__c tar = mapTarget.get(keyMap);
            for (TargetingContentAssociation__c con: tar.TargetingContentAssociations__r) {
                String ex_key = keyMap + '' + con.TargetingContent__c;
                lcontent.add(new TargetingContentAssociation__c(Targeting__c = keyMap, TargetingContent__c = con.TargetingContent__c, Exclude__c = con.Exclude__c, Target_Content_Key__c = ex_key));
                assoNotToDelete.add(ex_key);
            }
        }

        upsert lcontent Target_Content_Key__c;
        delete[Select Id From TargetingContentAssociation__c Where Targeting__c in : lstKeyMap And Target_Content_Key__c Not In: assoNotToDelete];
    }

    //Converted to handle Mass Operation
    private void copyTargetKeyValue(Map < String, Targeting__c > mapTarget) {
        Set < String > assoNotToDelete = new Set < String > ();
        List < TargetingKeyValueAssociation__c > lkeyval = new List < TargetingKeyValueAssociation__c > ();
        Set < String > lstKeyMap = mapTarget.keySet();

        for (String keyMap: mapTarget.keySet()) {
            Targeting__c tar = mapTarget.get(keyMap);
            for (TargetingKeyValueAssociation__c key: tar.TargetingKeyValueAssociations__r) {
                String ex_key = keyMap + '' + key.DART_KeyValue__c;
                lkeyval.add(new TargetingKeyValueAssociation__c(Targeting__c = keyMap, Operator__c = key.Operator__c, DART_KeyValue__c = key.DART_KeyValue__c, targetkeyvalue__c = ex_key));
                assoNotToDelete.add(ex_key);
            }
        }
        upsert lkeyval targetkeyvalue__c;
        delete[Select Id From TargetingKeyValueAssociation__c Where Targeting__c = : lstKeyMap And targetkeyvalue__c Not In: assoNotToDelete];
    }

    /**
     * To copy Placement Targeting to other opp line item. It Converted to handle Mass Operation.
     * @param : mapTarget, Map<String, Targeting__c>
     * @createddate : 18-Dec-2013
     * @author : SUY Sreymol
     */
    private void copyPlacementTargeting(Map < String, Targeting__c > mapTarget) {
        //Set<String> assoNotToDelete = new Set<String>();
        List < PlacementTargetingAssociation__c > lplaceTars = new List < PlacementTargetingAssociation__c > ();
        Set < String > lstKeyMap = mapTarget.keySet();

        for (String keyMap: mapTarget.keySet()) {
            Targeting__c targeting = mapTarget.get(keyMap);
            for (PlacementTargetingAssociation__c pt: targeting.PlacementTargetingAssociations__r) {
                // String ex_key = desTar + '' + pt.PlacementTargeting__c;
                lplaceTars.add(new PlacementTargetingAssociation__c(Targeting__c = keyMap, PlacementTargeting__c = pt.PlacementTargeting__c));
                //assoNotToDelete.add(ex_key);
            }
        }
        if (!lplaceTars.isEmpty()) upsert lplaceTars;

        delete[Select Id From PlacementTargetingAssociation__c Where Targeting__c = : lstKeyMap And Id Not IN: lplaceTars];
    }

    //Converted to handle Mass Operation
    private void copyTargetCountry(Map < String, Targeting__c > mapTarget) {
        Set < String > assoNotToDelete = new Set < String > ();
        List < TargetingCountryAssociation__c > lcountry = new List < TargetingCountryAssociation__c > ();
        Set < String > lstKeyMap = mapTarget.keySet();
        for (String keyMap: mapTarget.keySet()) {
            Targeting__c tar = mapTarget.get(keyMap);
            for (TargetingCountryAssociation__c cou: tar.TargetingCountryAssociations__r) {
                String ex_key = keyMap + '' + cou.Country__c;
                lcountry.add(new TargetingCountryAssociation__c(Targeting__c = keyMap, Country__c = cou.Country__c, TargetCountry__c = ex_key));
                assoNotToDelete.add(ex_key);
            }
        }
        upsert lcountry TargetCountry__c;
        delete[Select Id From TargetingCountryAssociation__c Where Targeting__c = : lstKeyMap And TargetCountry__c Not In: assoNotToDelete];
    }

    //Converted to handle Mass Operation
    private void copyTargetCity(Map < String, Targeting__c > mapTarget) {

        //use future cos Heapsize error 
        Map < String, String > mapTem = new Map < String, String > ();
        for (String keymap: mapTarget.keySet()) {
            mapTem.put(keymap, mapTarget.get(keymap).Id);
        }
        copyTargetCity_ASYN(mapTem);

    }

    @
    future
    public static void copyTargetCity_ASYN(Map < String, String > mapTarget) {

        Map < String, List < TargetingCityAssociation__c >> mapTarCity = new Map < String, List < TargetingCityAssociation__c >> ();
        for (TargetingCityAssociation__c srcTar: [Select Targeting__c, City__c, targetcity__c From TargetingCityAssociation__c Where Targeting__c in : mapTarget.values()]) {
            if (!mapTarCity.containsKey(srcTar.Targeting__c)) {
                mapTarCity.put(srcTar.Targeting__c, new List < TargetingCityAssociation__c > ());
            }
            mapTarCity.get(srcTar.Targeting__c).add(srcTar);

        }

        Set < String > assoNotToDelete = new Set < String > ();
        List < TargetingCityAssociation__c > lcity = new List < TargetingCityAssociation__c > ();
        Set < String > lstKeyMap = mapTarget.keySet();

        for (String keyMap: mapTarget.keySet()) {

            String idTar = mapTarget.get(keyMap);
            if (!mapTarCity.containsKey(idTar)) continue;
            for (TargetingCityAssociation__c cit: mapTarCity.get(idTar)) {

                if (cit == null) continue;
                String ex_key = keyMap + '' + cit.City__c;
                lcity.add(new TargetingCityAssociation__c(Targeting__c = keyMap, City__c = cit.City__c, targetcity__c = ex_key));
                assoNotToDelete.add(ex_key);

            }
        }
        if (lcity.size() > 0) {
            upsert lcity targetcity__c;
        }
        if (assoNotToDelete.size() > 0) {
            delete[Select Id From TargetingCityAssociation__c Where Targeting__c = : lstKeyMap And targetcity__c Not In: assoNotToDelete];
        }


    }

    //Converted to handle Mass Operation
    //SP: 8-8-2011 5.00PM
    private void copyTargetAreacode(Map < String, Targeting__c > mapTarget) {
        Set < String > assoNotToDelete = new Set < String > ();
        List < TargetingAreaCodeAssociation__c > lareacode = new List < TargetingAreaCodeAssociation__c > ();
        //Set<String> lstKeyMap =  mapTarget.keySet();

        for (String keyMap: mapTarget.keySet()) {
            Targeting__c tar = mapTarget.get(keyMap);

            for (TargetingAreaCodeAssociation__c are: tar.TargetingAreaCodeAssociations__r) {
                String ex_key = keyMap + '' + are.AreaCode__c;
                lareacode.add(new TargetingAreaCodeAssociation__c(Targeting__c = keyMap, AreaCode__c = are.AreaCode__c, Target_Areacode_Key__c = ex_key));
                assoNotToDelete.add(ex_key);
            }
        }
        upsert lareacode Target_Areacode_Key__c;

        delete[Select Id From TargetingAreaCodeAssociation__c Where Targeting__c IN: mapTarget.keySet() And Target_Areacode_Key__c Not In: assoNotToDelete];

    }
  
  /**
     * To copy regions 
     * @param : mapTarget, Map<String, Targeting__c>
     * @author : Sreymol
     * @createddate : 02/04/2014
     */
  private void copyTargetRegion(Map<String, Targeting__c> mapTarget){
      Set<String> assoNotToDelete = new Set<String>();
      List<TargetingRegionAssociation__c> lregion =  new List<TargetingRegionAssociation__c>();
      for (String keyMap: mapTarget.keySet()) {
        Targeting__c srcTar = mapTarget.get(keyMap);
          for(TargetingRegionAssociation__c  regn : srcTar.TargetingRegionAssociation__r){
                String ex_key = keyMap + '' + regn.Region__c;
                lregion.add(new TargetingRegionAssociation__c(Targeting__c = keyMap, Region__c = regn.Region__c, targetRegion__c = ex_key ));
                assoNotToDelete.add(ex_key);
          }
      }
        upsert lregion targetRegion__c;
        
        delete [Select Id From TargetingRegionAssociation__c Where Targeting__c IN : mapTarget.keySet() And targetRegion__c Not In :assoNotToDelete ];
  }
  
   //MS 08-09-2014 : for JS tree
    private void copyTargetGeography(Map<String, Targeting__c> mapTarget)
    {
    
        Set<String> assoNotToDelete = new Set<String>();
        List<TargetingGeographyAssociation__c> lgeography = new List<TargetingGeographyAssociation__c>();
        Set<String> lstKeyMap = mapTarget.keySet();
        for(String keyMap: mapTarget.keySet())
        {
            Targeting__c tar = mapTarget.get(keyMap);
            for(TargetingGeographyAssociation__c geo : tar.TargetingGeographyAssociations__r )
            {
                String ex_key = keyMap + '' + geo.Geography__c;
                lgeography.add(new TargetingGeographyAssociation__c(Targeting__c = keyMap, Geography__c = geo.Geography__c, TargetGeography__c = ex_key));
                assoNotToDelete.add(ex_key);
            }
        }
        upsert lgeography TargetGeography__c;
        delete [Select Id From TargetingGeographyAssociation__c Where Targeting__c=: lstKeyMap And TargetGeography__c Not In : assoNotToDelete];
  }

  //Devices Targeting
  private void copyTargetingDevices(Map<String, Targeting__c> mapTarget)
  {
        Set<String> assNotToDelete = new Set<String>();
        List<TargetingDeviceAssociation__c > lstTargDevices = new List<TargetingDeviceAssociation__c>();
        
        for(String keyMap: mapTarget.keySet()){
            Targeting__c tar = mapTarget.get(keyMap);
          
            for(TargetingDeviceAssociation__c dev : tar.TargetingDeviceAssociations__r){
                String ex_key = keyMap + '' +dev.Device__c;
                lstTargDevices.add(new TargetingDeviceAssociation__c(Targeting__c = keyMap, Device__c = dev.Device__c, TargetDevice__c  = ex_key ));
                assNotToDelete .add(ex_key);
            }
        }
        upsert lstTargDevices TargetDevice__c;        
        delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c IN : mapTarget.keySet() And TargetDevice__c Not In :assNotToDelete ];
        
  }
  
  // Connections Targeting
  private void copyTargetingConnections(Map<String, Targeting__c> mapTarget)
  {
        Set<String> assNotToDelete = new Set<String>();
        List<TargetingConnectionAssociation__c  > lstTargConns = new List<TargetingConnectionAssociation__c>();
        
        for(String keyMap: mapTarget.keySet()){
            Targeting__c tar = mapTarget.get(keyMap);
          
            for(TargetingConnectionAssociation__c con : tar.TargetingConnectionAssociations__r){
                String ex_key = keyMap + '' +con.Connection__c;
                lstTargConns.add(new TargetingConnectionAssociation__c(Targeting__c = keyMap, Connection__c = con.Connection__c, TargetConnection__c  = ex_key ));
                assNotToDelete .add(ex_key);
            }
        }
        upsert lstTargConns TargetConnection__c;
         delete [Select Id From TargetingConnectionAssociation__c Where Targeting__c IN : mapTarget.keySet() And TargetConnection__c Not In :assNotToDelete ];
  }
  //end of MS

    public class KeyValueDTO {
        String dartKeyId; //{get; set;}
        String dartKeyValue; //{get; set;}
        public KeyValueDTO(String dartKeyId, String dartKeyValue) {
            this.dartKeyId = dartKeyId;
            this.dartKeyValue = dartKeyValue;
        }
    }

  
    public static String PERCENT_TYPE {
        get {
            return 'Percent';
        }
    }
    public static String GBP_TYPE {
        get {
            return 'GBP';
        }
    }

    public class DtoItem {

       
        //NK:22/03/2014: Allows Profiles that do not have Edit/Create on Product to save
        public String preDefinedKVFromProduct {
            get{
                return this.item.PriceBookEntry.Product2.AdServer_Keywords_Key_Values__c;
        
        }set;}  
        
        public Double randomNr {
            get;
            set;
        }
        
        //HCS 18.12.2014
        public  String totalSurchangeDiscount{get;set;}
         
        //SP. 30-Sep-2011
        public DtoItem(String productName, OpportunityLineItem item, Boolean isFixSite, String proId, String availableSite, Boolean isHasSite, String availableKV, String billCategory2, Product2 pro, Boolean isHasPreDefine, Integer dtoIdRunner) {

            this.productName = productName;
            this.item = item;
            this.isFixedSite = isFixSite;
            this.proId = proId;
            this.availableSite = availableSite;
            this.isHasSite = isHasSite;
            this.availableKV = availableKV;
            this.billCategory2 = billCategory2;
            this.pro = pro;
            this.isHasPreDefine = isHasPreDefine;
            dtoId = dtoIdRunner + 1;
            initBillings();
            
            this.item.Surcharge_Type__c = (item.Surcharge_Type__c == null ? PERCENT_TYPE: item.Surcharge_Type__c);
          	this.item.Discount_Type__c = (item.Discount_Type__c == null ? PERCENT_TYPE: item.Discount_Type__c);
        }
		
		/**
		 * Initialize billing related: SelectOption, Field, DTO var.
		 * @Author Bunhor
		 * @CreatedDate 12-Feb-15 
		 */
		private void initBillings(){
			this.listBilling = getListBillingValue();
            
            if(this.item.Billing_category__c==null){
            	this.item.Billing_category__c = BILLING_CPM;
            	this.billCatAndCalc = listBilling[0].getValue();
            }else{
            	this.billCatAndCalc =  this.item.Billing_category__c +'_'+ this.item.BillingCalc__c ;
            }  
		}
		
		
        //------Sreymol 2-Jan-2014(updated)----
        public String adKV {
            get;
            set;
        }
        public DtoItem(String adKV, OpportunityLineItem item) {
            this.adKV = adKV;
            this.item = item;
            setAdKV();
        }
        public String getAdKV() {
            return this.adKV;
        }
        public void setAdKV() {
            String kv = getAdKV();
            if ((kv != null) && (kv != '')) {
                if (item.KeyValueString__c != null && item.KeyValueString__c != '') { // Edit mode
                    if (item.KeyValueString__c.contains(kv)) {
                        item.KeyValueString__c = item.KeyValueString__c; //'('+item.KeyValueString__c+')';                      
                    } else {
                        item.KeyValueString__c = '(' + kv + ') and ' + item.KeyValueString__c; //+')';
                    }
                } else {
                    item.KeyValueString__c = '(' + kv + ')'; // Add mode
                }
            }
        }
        //-------------------------

        public String billCategory2 {
            get;
            set;
        } //use for get value from object
		/*
        public String billingCategory2; //use for assign value to opli billing category

        public void setBillingCategory2(String val) {
            this.item.Billing_category__c = val;
            billingCategory2 = val;
        }
        public String getBillingCategory2() { 
            //return billingCategory2;
            return item.Billing_category__c; //NK:21/03/2014: fixed ALWAYS CPM!, assigned the righ BillingCat here!
        }
        */
        public List < SelectOption > listBilling {
            get;
            set;
        }
        
        //Bunhor 11-Feb-15: It is List Price correction, and not to be saved.	
        public Decimal lpc_tem {get;set;}
        //Bunhor 11-Feb-15: storing BillingCategory and BillingCalculation which is underscore as separator. ex: CPM_Delivery
        Public String billCatAndCalc{get;set;}
        public boolean isLockedQTY{get;set;}
         
        public Decimal listPrice2{ get{ return getListPriceByBillingCat();}}
        /** 
       * Bunhor (issues/3235) : 9-May-2014
       * TODO : Get List Price By BillingCategory
       *   IF      "CPM" -- Product2.CPM_Price__c  
       *  ELSE IF "CPD" -- Product2.CPD_Price__c  
       *  ELSE IF "CPC" -- Product2.CPC_Price__c  
       *  ELSE    pricebook entry currency value 
       */
      private Decimal getListPriceByBillingCat(){  
        
        Map<String, Decimal> mapBC2LP = new Map<String, Decimal>();
        mapBC2LP.put(BILLING_CPM.toLowerCase(), this.item.PricebookEntry.Product2.CPM_Price__c == null ? 0 : this.item.PricebookEntry.Product2.CPM_Price__c);
        mapBC2LP.put(BILLING_CPD.toLowerCase(), this.item.PricebookEntry.Product2.CPD_Price__c == null ? 0 : this.item.PricebookEntry.Product2.CPD_Price__c); 
        mapBC2LP.put(BILLING_CPC.toLowerCase(), this.item.PricebookEntry.Product2.CPC_Price__c == null ? 0 : this.item.PricebookEntry.Product2.CPC_Price__c);
        mapBC2LP.put(''                       , this.item.PricebookEntry.UnitPrice             == null ? 0 : this.item.PricebookEntry.UnitPrice); 
        String bc = this.item.Billing_Category__c == null ? '' : (this.item.Billing_Category__c+'').toLowerCase();
        return mapBC2LP.keyset().contains(bc)? mapBC2LP.get(bc) : mapBC2LP.get('');
      }
    
        private List < SelectOption > getListBillingValue() { 
            // Bunhor @30-Jan-15: repleace the logic
            List <SelectOption> returner = new List <SelectOption>(); 
            
            if(this.item.PricebookEntry.Product2.Billing_Category__c!=null){ 
                for(String cat : this.item.PricebookEntry.Product2.Billing_Category__c.split(';')){ 
                    returner.add(new SelectOption(cat, cat));
                }
            }
            
            if(returner.isEmpty()){ 
                returner.add(new SelectOption(BILLING_CPM, BILLING_CPM)); // the default if Product2.Billing_Category__c==null 
                returner.add(new SelectOption(BILLING_CPA, BILLING_CPA)); 
                returner.add(new SelectOption(BILLING_CPC, BILLING_CPC)); 
                returner.add(new SelectOption(BILLING_CPD, BILLING_CPD)); 
            }
            
            return returner;
        }
     
        public String proId {
            get;
            set;
        }
        public Integer position {
            get;
            set;
        }
        public String productName {
            get;
            set;
        }
        public OpportunityLineItem item {
            get;
            set;
        }
        public String quantity;

        public String salesPrice; //@Sreymol 20-Mar-2014

        public Integer dtoId {
            get;
            set;
        } //Use as unique Id for Package Product(main Product)

        public Boolean isHasPreDefine {
            get;
            set;
        }
        public String availableKV {
            get;
            set;
        }
        public Boolean isHasSite {
            get;
            set;
        }
        public String availableSite {
            get;
            set;
        }
        public Boolean isFixedSite {
            get;
            set;
        }
        public String fromDate;
        public String unitlDate;
        public String targeting_c;
        public String descr;
        public String keyWords {
            get;
            set;
        }
        public Product2 pro {
            get;
            set;
        }
        public String errQty;
        public String getErrQty() {
            if (this.item.Quantity == null || this.item.Quantity == 0) {
                return system.Label.Empty_value;
            }
            return '';
        }

        public String errSalePrice;
        public String getErrSalePrice() {
            //@Sreymol 20-Mar-2014
            //if(this.item.UnitPrice == null || this.item.UnitPrice == 0){
            if (this.item.UnitPrice == null) {
                //---------------------------end-----------------//
                return system.Label.Empty_value;
            }
            return '';

        }

        public String errBillin;
        public String getErrBillin() {
            if (this.item.Billing_category__c == null || this.item.Billing_category__c == '') {
                return system.Label.Empty_value;
            }
            return '';
        }
    
    // Bunhor(01-Apr-14): Reqired discount reason if discount is maintained.
      public String errDiscountReason;
      public String getErrDiscountReason(){
        //if((this.item.Rebate_In_Kind_Reason__c == null || this.item.Rebate_In_Kind_Reason__c == '') && this.item.Discount > 0){ return system.Label.Empty_value; }
        // Bunhor @16-Feb-15: comment out existing and add new
        if(String.isBlank(this.item.Rebate_In_Kind_Reason__c) && this.item.SalesPriceNet__c < this.listPrice2){
          return system.Label.Empty_value; 
        }
        return '';
      }
    
        public String getDescr() {
            return String.valueOf(item.Description == null ? '' : item.Description + '');
        }
        public String getFromDate() {
            return String.valueOf(item.from_Date__c == null ? '' : Date.valueOf(item.from_Date__c).format() + '');
        }
        public String getUntilDate() {
            return String.valueOf(item.until_Date__c == null ? '' : Date.valueOf(item.until_Date__c).format() + '');
        }
        public String getTargeting_c() {
            return String.valueOf(item.Targeting__r.Name == null ? '' : item.Targeting__r.Name + '');
        }
        public String getquantity() {
            return String.valueOf(formatCurrency(this.item.Quantity, 2));
        }
       
    public void setquantity(String v) {
          if (v!=null && v!='') { 
              this.item.Quantity = Decimal.valueOf(v); 
          } else {
            this.item.Quantity = null;
          }
           Quantity = v;
        }
           
        //@Sreymol 20-Mar-2014 : to display error messages when Sale Price is empty
        public String getsalesPrice() {
            return String.valueOf(formatCurrency(this.item.UnitPrice, 2)); //NK:21/03/2014: fixed zero scale of SalePrice
        }

        public void setsalesPrice(String val) {
            this.item.UnitPrice = val != null && val != '' ? Decimal.valueOf(val) : null;
            salesPrice = val;
        }
        //-------------------------end---------------------------------//
    }

    public static Decimal formatCurrency(Decimal val, Integer scale) {

        if (val != null && scale != null) {
            return val.setScale(scale);
        } else {
            return null;
        }
    }


    /** block calculate SalesPrice **/
    private Map < Integer, Integer > mapMinValQty = new Map < Integer, Integer > {
        0 => 5,
        6 => 9,
        10 => 14,
        15 => 24,
        25 => 44,
        45 => 64,
        65 => 109,
        110 => 149,
        150 => 189,
        190 => 249,
        250 => 299,
        300 => 349,
        350 => 399,
        400 => 499,
        500 => 599,
        600 => 799,
        800 => 999,
        1000 => 1000
    };
    private Map < Integer, String > mapMaxValQty = new Map < Integer, String > {
        5 => 'Up to 5',
        9 => '6 to 9',
        14 => '10 to 14',
        24 => '15 to 24',
        44 => '25 to 44',
        64 => '45 to 64',
        109 => '65 to 109',
        149 => '110 to 149',
        189 => '150 to 189',
        249 => '190 to 249',
        299 => '250 to 299',
        349 => '300 to 349',
        399 => '350 to 399',
        499 => '400 to 499',
        599 => '500 to 599',
        799 => '600 to 799',
        999 => '800 to 999',
        1000 => '1000+'
    };


    public void reCalculateAll() {
        
        reEvaluateAll();
       
    }

    private void reEvaluateAll() {
        try{
        calculatePrice();//HCS 18.12.2014
       // reCalculatePrices(); // Bunhor : 25-Mar-2014
        //reEvaluateQtyByBudget();
        reEvaluateSalesPrice();
        //reEvaluateSalesPriceTarget();
        //reEvaluateSurchargeAndDiscount();
        //reEvaluateNetNetNet();
         
        }catch(Exception e){
             Apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR, e.getMessage() + e.getStackTraceString());
            Apexpages.addMessage(msg);
            system.debug('Error======' + e.getMessage() + e.getStackTraceString());
        }
    }
     
    /**HCS 19.12.2014
    //change from javascript when Billing Category have changed becos it was depending picklist
    public void changeBillingcategory(){
         for(Integer i=0; i<lstRecords.size(); i++){ 
             DtoItem item = lstRecords[i];
             item.setBillingCategory2( item.billingCategory2 );  
         }
        reCalculateAll();
    }
    */
    
    /**
     Bunhor 11-Feb-15: These methods is for refreshing the page, and it is called from actionsupport. 
     */
    private boolean isSPNchanged = true; 
    public void spnChanged(){ isSPNchanged = true; reCalculateAll(); } 
    public void lpcChanged(){ isSPNchanged = false; reCalculateAll(); }
    //Bunhor-end-
    
   /**
    *  HCS 17.12.2014
    *  Targeting_Surcharge__c/Surcharge_Type__c & Discount__c/Discount_Type__c can be replace with 2 new fields, ListPriceCorrection__c and ListPriceCorrectionType__c.
    *  Instead of having 2 fields, 1 for positive values and 1 for negative, the ListpriceCorrection can become positive or negative. You may create the new fields.
    *   
    *   Definitions:
    *   SalesPriceNet__c (Sales Price Net, SPN)
    *   ListPrice (Price as listed on Product for CPM/CPD/CPC, LP)
    *   ListPriceCorrection (Deviation from Listprice in $ or %, LPC)
    *   BillingAccount Discount (BD) == Agency commision for Indirect Sales => Opportunity.Billing_Account__r.AccountDiscount__c
    *   Quantity (Q) => #Days for CPD, #Clicks for CPC, #AdImpressions/1000 for CPM
    *  
    *   Oli.TotalPrice should be set to SPN*Q. This way Opportunity Amount field will become usuable again. (Should be done in HDNL_OpportunityLineItem) I can handle this, once the other logic is working.
    *
    */
    
    private void calculatePrice(){
        
        for(Integer i=0; i<lstRecords.size(); i++){  //lDisplayRec
            DtoItem dtoItem = lstRecords[i];
            OpportunityLineItem item = dtoItem.item;
            
            Decimal lp = dtoItem.listPrice2==null? 0 : dtoItem.listPrice2; 
            item.SalesPriceNet__c = item.SalesPriceNet__c==null? dtoItem.listPrice2 : item.SalesPriceNet__c;
             
            // calculate AutoTargetingSurcharge 
            setAutoTargetingSurcharge(dtoItem);  
            // calc SalePriceNet Or SalePriceCorrection
            calcSalePriceNetOrSalePriceCorrection(dtoItem);
            // calc billing cat and calc, and Qty from billcat
            initBillingsAndQty(dtoItem); 
              
            //Oli.TotalPrice should be set to SPN*Q.
            //item.TotalPrice = spn * item.Quantity;//we can't assign value to totalprice it will show error when saving record "field integrity exception: UnitPrice (only one of unit price or total price may be specified)   "
            item.Budget_NetNetNet__c = item.SalesPriceNet__c * item.Quantity;
            //first value ($) can be calculated as: SalesPriceNet - ListPrice.
            Decimal firstCol = item.SalesPriceNet__c - lp;
            //The second value (%) can be calculated as: (SalesPriceNet - ListPrice)/ListPrice
            Decimal secondCol = lp == 0 ? firstCol : ( firstCol / lp ); 
            secondCol = secondCol * 100;
            firstCol = firstCol == null ? 0 : firstCol.setScale(2);
            dtoItem.totalSurchangeDiscount = firstCol +' ('+ secondCol.setScale(2)+'%)';
        }
        
    } 
    
    /** 
     * 	In editor user can change either LPC or SPN:
 	 *		- if LPC is changed (only $) => recalc: SPN = ( LP + LPC ) * (1 - BD)  
 	 *		- if SPN is changed => recalc: LPC = (SPN/(1-BD))-LP
 	 *
     * @Author : Bunhor
	 * @CreatedDate: 11-Feb-15
     */
    private void calcSalePriceNetOrSalePriceCorrection(DtoItem dtoItem){
    	OpportunityLineItem item = dtoItem.item;
    	
    	Decimal lp = dtoItem.listPrice2==null? 0 : dtoItem.listPrice2;
        Decimal bd = accountDiscount == null ? 0 : accountDiscount; 
        
        if(isSPNchanged){
        	Decimal lpc = (item.SalesPriceNet__c/(1-bd))-lp; 
        	dtoItem.lpc_tem = lpc.setScale(2) ;
        }else{
        	Decimal spn = (lp  +  dtoItem.lpc_tem )* (1 - bd);  
            item.SalesPriceNet__c =   spn.setScale(2) ;
        }
    } 
    
    /** 
     * Todo:
     * 1- Initial item.Billing_Category__c and item.BillingCalc__c
     * 2- Set item.Quantity based on item.Billing_Category__c
     * 		- CPD ==> number of days
	 *		- item.Billing_Category__c==ServiceFee && item.BillingCalc__c==MonthlyFixed ==> number of months 
	 *		- item.Billing_Category__c==ServiceFee && item.BillingCalc__c==OneTime ==> 1
	 *
     * @Author : Bunhor
	 * @CreatedDate: 12-Feb-15
     */
    private void initBillingsAndQty(DtoItem dtoItem){
    	OpportunityLineItem item = dtoItem.item;
    	
    	if(dtoItem.billCatAndCalc != null){
            item.Billing_Category__c = dtoItem.billCatAndCalc.split('_')[0];
            item.BillingCalc__c = dtoItem.billCatAndCalc.split('_')[1];
        } 
        item.Quantity = item.Billing_Category__c==BILLING_CPD ? (item.from_Date__c.daysBetween(item.until_Date__c)+1) : item.Quantity;
        item.Quantity = (item.Billing_Category__c==BILLING_SERVICE_FEE && item.BillingCalc__c==BILLING_CALC_1TIME) ?  1 : item.Quantity;
        item.Quantity = (item.Billing_Category__c==BILLING_SERVICE_FEE && item.BillingCalc__c==BILLING_CALC_MFIXED) ?  (item.from_Date__c.monthsBetween(item.until_Date__c)+1)  : item.Quantity;
        item.Quantity = item.Quantity == null ? 0 : item.Quantity; 
        
        dtoItem.isLockedQTY = item.Billing_Category__c==BILLING_CPD || (item.Billing_Category__c==BILLING_SERVICE_FEE && item.BillingCalc__c==BILLING_CALC_1TIME) || (item.Billing_Category__c==BILLING_SERVICE_FEE && item.BillingCalc__c==BILLING_CALC_MFIXED);
    } 
    
    /** 
     * Bunhor : 25-Mar-2014
     * TODO : calculate AutoTargetingSurcharge 
     * -------------------------------------------  
     * The calculation will based on tabs: tab6, tab3, tab4, tab5, tab7.
     * If a field of each tab containing a value, AutoTargetingSurcharge will increase by tab-value.  
     * (tab-values are stored in custome setting DevSettings__c)  
     */
    private void setAutoTargetingSurcharge(DtoItem dto){
      Decimal val = 0; 
    
    // Category & KeyValue Targeting
    Decimal temTab6 = getSurchargeFromCS('TabSix');
    val += getSurcharge4ThisTap(dto.item, new Set<String>{'KeyValueString__c'}, temTab6); // 'Rich_Line_Description__c', 'Placement_Targeting__c', 
    
    // Frequency Cap
    Decimal temTab3 = getSurchargeFromCS('TabThree');
    val += getSurcharge4ThisTap(dto.item, new Set<String>{'FC_Quantity__c', 'FC_Ad_served_every__c', 'FC_Period__c'}, temTab3);
    
    // Time & Keyword
    Decimal temTab4 = getSurchargeFromCS('TabFour');
    Decimal temVal = getSurcharge4ThisTap(dto.item, new Set<String>{'AdDayOfWeek__c', 'AdHourOfDay__c','AdKeywords__c'}, temTab4);
    //if(dto.keyWords != null && dto.keyWords != '') temVal = temTab4; // This tab containing dto field, not item field.
    val += temVal;  
    
    // OS & Browser
    Decimal temTab5 = getSurchargeFromCS('TabFive');
    val += getSurcharge4ThisTap(dto.item, new Set<String>{'AdOperatingSystems__c', 'AdWebBrowsers__c', 'AdBrowsersMinorVersion__c', 'AdBrowsersMajorVersion__c'}, temTab5);
    
    // Geo-targeting (IP)
    Decimal temTab7 = getSurchargeFromCS('TabSeven');
      val += getSurcharge4ThisTap(dto.item, new Set<String>{'Regions_Description__c', 'City_Description__c'}, temTab7); // 'Countries_Description__c', 
       
      dto.item.Auto_Targeting_Surcharge__c = val;
    }
    
    /** 
     * Bunhor : 25-Mar-2014
     * TODO : Logic for AutoTargetingSurcharge value of each tap   
     */
    private Decimal getSurcharge4ThisTap(OpportunityLineItem item, Set<String> fields, Decimal val){
      for(String f : fields){
        if(item.get(f) != null && item.get(f) != '') return val;
      }
      return 0;
    }
    
    /** 
     * Bunhor : 25-Mar-2014
     * TODO : Get AutoTargetingSurcharge value of the tap from custom setting  
     */
    public Decimal getSurchargeFromCS(String tapName){   
      if(DevSettings__c.getInstance(tapName) == null || DevSettings__c.getInstance(tapName).Value__c == null) 
      return 0;
      return Decimal.valueOf(DevSettings__c.getInstance(tapName).Value__c);
    }
     
    /**
     * Method to check SalesPrice is get from RateCard object or not
     * @author Sopha Pum
     */
    private Boolean isGetRateCardPrice(Product2 pro) {
        if (pro.Rate_Card__c == false || pro.Fixed_price__c == false) return false;
        return true;
    }

    /**
     * Method get Quantity rang
     * @author Sopha Pum
     */
    public String getQuantityRang(Integer quantity) {
        String qtyRang = '';
        for (Integer min: mapMinValQty.keySet()) {
            if ((min <= quantity && mapMinValQty.get(min) >= quantity) || (min <= quantity && mapMinValQty.get(min) <= quantity && quantity >= 1000)) {
                qtyRang = mapMaxValQty.get(mapMinValQty.get(min));
                break;
            }
        }
        return qtyRang;
    }

    /**
     * Method reEvaluate SalePrice by Length, Qty
     * @createdDate 24-May-2013
     * @author Sopha Pum
     */
    private void reEvaluateSalesPrice() {
        //System.debug('>>>>>>>>>>>>>>>>>>>>>reEvaluateSalesPrice:1');
        Set < ID > proIds = new Set < ID > ();
        Set < String > lengthMonths = new Set < String > ();
        Set < Integer > qtys = new Set < Integer > ();

        for (DTOItem rec: lstRecords) {
            if (!isGetRateCardPrice(rec.pro)) continue;

            proIds.add(rec.pro.Id);
            lengthMonths.add(String.valueof(rec.item.Length_Months__c));
            qtys.add(Integer.valueof(rec.quantity == null ? '0' : rec.quantity));
        }
        //get quantity rang that match quantity
        Set < String > sQtyRang = new Set < String > ();
        Map < Integer, String > mapQtyAndQtyRang = new Map < Integer, String > ();

        for (Integer min: mapMinValQty.keySet()) {
            for (Integer quantity: qtys) {
                if ((min <= quantity && mapMinValQty.get(min) >= quantity) || (min <= quantity && mapMinValQty.get(min) <= quantity && min >= 1000)) {
                    sQtyRang.add(mapMaxValQty.get(mapMinValQty.get(min)));
                    mapQtyAndQtyRang.put(quantity, mapMaxValQty.get(mapMinValQty.get(min)));
                }
            }
        }
        //get default pricebook
        Map < String, Decimal > mapDefaultPrice = new Map < String, Decimal > (); //<ProductID_Pricebook2Id, SalesPrice>
        for (PricebookEntry pbe: [Select UnitPrice, Product2Id, Pricebook2Id
            From PricebookEntry Where Product2Id in : proIds And Pricebook2Id = : mcPBId
        ]) {

            mapDefaultPrice.put(pbe.Product2Id + '_' + pbe.Pricebook2Id, pbe.UnitPrice);
        }
        //get sale price value fro Rate card
        Map < String, Decimal > mapSalesPrice = new Map < String, Decimal > (); //<ProductID_Length_Quantity, SalesPrice>
        for (Rate_Card__c rc: [select Sales_Price__c, Length__c, Quantity__c, Product__c
            from Rate_Card__c
            where Length__c in : lengthMonths and Quantity__c in : sQtyRang and Product__c in : proIds
        ]) {

            mapSalesPrice.put(rc.Product__c + '_' + rc.Length__c + '_' + rc.Quantity__c, rc.Sales_Price__c);
        }
        for (DTOItem rec: lstRecords) {
            if (!isGetRateCardPrice(rec.pro) || !mapQtyAndQtyRang.containsKey(Integer.valueof(rec.quantity == null ? '0' : rec.quantity))) continue;

            String keyMapSalesPrice = rec.pro.Id + '_' + rec.item.Length_Months__c + '_' + mapQtyAndQtyRang.get(Integer.valueof(rec.quantity == null ? '0' : rec.quantity));

            Decimal unitPrice = (mapSalesPrice.containsKey(keyMapSalesPrice) ? mapSalesPrice.get(keyMapSalesPrice) : mapDefaultPrice.get(rec.pro.Id + '_' + mcPBId));

            rec.item.UnitPrice = unitPrice;
        }
        
        // reEvaluateNetNetNet();
    }

  

    /**
     * Method get sales price and quantity
     * @author Sopha Pum
     */
    public Map < String, List < Rate_Card__c >> mappingProAndRateCard(List < Rate_Card__c > lstRateCards) {
        Map < String, List < Rate_Card__c >> mapRateCards = new Map < String, List < Rate_Card__c >> (); //<ProductId_Length, List<Rate Card>>

        for (Rate_Card__c rc: lstRateCards) {
            String proIdLength = String.valueOf(rc.Product__c).subString(0, 15) + '_' + rc.Length__c;

            if (!mapRateCards.containsKey(proIdLength)) {
                mapRateCards.put(proIdLength, new List < Rate_Card__c > ());
            }
            mapRateCards.get(proIdLength).add(rc);
        }

        return mapRateCards;
    }

    /**
     * Method to get SalesPrice from RateCard
     * @author Sopha Pum
     */
    public Decimal getSalesPriceFromRateCard(List < Rate_Card__c > lstRateCards, Decimal budget) {
        Decimal salePrice = 0;

        for (Rate_Card__c rc: lstRateCards) {

            String quantityRang = rc.Quantity__c;
            quantityRang = quantityRang.replace('+', '').replace('Up to', '0').replace('to', ','); //String can be 'Up to 5', '100 to 200', '1000+'

            //get min price
            String min = String.valueOf((quantityRang.contains(',') ? quantityRang.split(',')[0] : quantityRang)).trim();
            Decimal minPrice = Decimal.valueOf(min) * rc.Sales_Price__c;

            //get max price
            String max = String.valueOf((quantityRang.contains(',') ? quantityRang.split(',')[1] : quantityRang)).trim();
            Decimal maxPrice = Decimal.valueOf(max) * rc.Sales_Price__c;

            if ((minPrice <= budget && maxPrice >= budget) || (budget > maxPrice && budget > minPrice && min >= '1000')) {
                salePrice = rc.Sales_Price__c;
                break;
            }
        }

        return salePrice;
    }

   
    /**
     * Method to get quantity by budget and salesprice
     * @author Sopha Pum
     */
    public Integer getQuantityFromSalePrice(Decimal budget, Decimal salesPrice) {
        Decimal qty = budget / salesPrice;
        qty = qty.setScale(0, System.Roundingmode.DOWN);

        return Integer.valueOf(qty);
    }

    /** 
     * Initially item.Billing_category__c default value from Product2.Billing_Category__c
     * @Author Bunhor
     * @CreatedDate 2-Feb-15
     
    public static void setDefaultBillCat(OpportunityLineItem item, Product2 pro){  
        if(pro.Billing_Category__c!=null && !pro.Billing_Category__c.containsIgnoreCase(item.Billing_category__c)){ 
            item.Billing_category__c = pro.Billing_Category__c.split(';')[0];
        }
    }
	*/
}