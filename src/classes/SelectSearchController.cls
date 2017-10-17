/** Controller of SelectSearch Page
        Main Functions:
                + Search Ad Spec bases on criteria, Ad Spec Name, Site, Placement, and Ad Type.
                + Create media baskets (Ad to Basket) to store desire Ad Spec (results) to start Product Configuration.
        Aditional Functions:
                + Sort search results
                + Next/Previous 10 records.
        Where is it used?
                + The reference page is called from the list button, "Ad Items" on object Campaign Item where it is as the related list of Media Campaign.
@Revision:
	- Author: suy sreymol
	- Description: #4884 Add product error => VF page "Select Search"
	- Modified method: initBasket() to fix index out of bound
	- Modified Date: 12/2/15
*/

public class SelectSearchController{


        private final Integer NUMBER_ROW_VIEW_PER_PAGE = 30; //Number of records to be displayed
        public  String mcId { set; get;}
        public  Boolean isResultNone { set; get;}
        public  String mcName {set;get;}
        public  String mcPBId {set;get;}
        public  String mcCurr {set;get;}
        public  String accName {set;get;}

        //added for pricebook check
        private Boolean forcePricebookSelection = false;
        public Pricebook2 theBook {get;set;}



        public static String Label_Alle = System.Label.Alle;
        public static String Label_No_Result = System.Label.No_Result;
        public static String Label_Empty_Basket = System.Label.EmptyBasket;

        //Criterial variables
        public  String sWord {get;set;}
        public  String siteName { get; set; }
        public  List<SelectOption> lstSiteName { get; set; }
        public  String placement { get; set; }
        public  List<SelectOption> lstPlacement { get; set; }
        public  String adType { get; set; }
        public  List<SelectOption> lstAdType { get; set; }
        public	Product2 pro{get; set;}

        private static String   MODIFYPRODUCTNONBANNERURL='/apex/ModifyProduct3?mcId=%&retURL=/apex/SelectSearch?Id=%';
        private static String   MODIFYPRODUCTURL='/apex/ModifyProduct3?mcId=%&retURL=/apex/SelectSearch?Id=%'; //'/apex/ModifyProduct?mcId=%&retURL=/apex/SelectSearch?Id=%';
        private static String   MODIFYPRODUCTURLCLASSIFIEDS='/apex/ModifyProductClassifieds?mcId=%&retURL=/apex/SelectSearch?Id=%';
        private static String   MODIFYPRODUCTURLDAILYDEALS='/apex/ModifyProductDailyDeals?mcId=%&retURL=/apex/SelectSearch?Id=%';
        public Boolean isSingleInvoice{get;set;}

    //Store all product criterias. When any item in each comboboxes changed, lpro need to be used

   //private List<PricebookEntry> lAD_Pri;
   private List<PricebookEntry> lAD_Pri;

    public SelectSearchController(ApexPages.Standardcontroller controller) {
        this('limit 900',null,null);//this('limit 9000',null,null);
    }

    public SelectSearchController(){

        this('',null,null);
    }



    //To avoid SF Limitation , these are for test method purpose
    private String testRecordLimitation;
    private Set<String> testScopeId;

    public SelectSearchController(String tLimit, Set<String> tScopeId,ApexPages.StandardController  controller) {
    	isSingleInvoice=false;

        testRecordLimitation = tLimit;
        testScopeId = tScopeId;
        // get Parameters from currentPage.
        mcId = Apexpages.currentPage().getParameters().get('Id');

        List<Opportunity> mcs = [Select Id,Name, Account.Name,Pricebook2Id From Opportunity  Where Id=: mcId];
        if(mcs.size() == 0){
                return;
        }

        Opportunity mc = mcs.get(0);
        mcName = mc.Name;
        accName = mc.Account.Name;
        mcId = mc.Id;
        mcPBId = mc.Pricebook2Id;
  //    mcCurr = mc.CurrencyIsoCode;


        if (mcPBId == null) {
        system.debug('***HB: Opp has no pricebook!');



   //This is a check to set the default pricebook

            User user = [Select default_price_book__c From User Where Id=:UserInfo.getUserId()];

            Pricebook2[] activepbs = [select Id, Name from Pricebook2 Where Name=:User.Default_Price_Book__c];
            system.debug('activepbs ========================== ' + activepbs);
            //#2646: KCA-6693 Edit All Screen Throwing Index Out of Bounds
            // update by sreymol on 20-Feb-2014 : to avoid the error index out of bound
            if (!activepbs.isEmpty()) { theBook = activepbs[0];mcPBId = !Test.isRunningTest() ? theBook.Id : Test.getStandardPricebookId();}

            //------------------------end--------------------------//
      }

        isResultNone = false;

        siteName=Label_Alle;
        placement=Label_Alle;
        adType=Label_Alle;

        lstSiteName = new List<SelectOption>();
        lstPlacement = new List<SelectOption>();
        lstAdType = new List<SelectOption>();
        pro = new Product2();

        //initial dependential criterias
        initSelectListWith3Alle();

        //MS

        if(Apexpages.currentPage().getParameters().get('isClone') != 'true'){
        	/*map<String,List<String>> mPackageProductsID=new map<String,List<String>>();
        	for(Packagecomponent__c pro:[Select p.Singleproduct__c, p.Package_product__c From Packagecomponent__c p where Package_product__c in:sProductID]){
        		if(mPackageProductsID.get(pro.Package_product__c)==null) mPackageProductsID.put(pro.Package_product__c,new List<String>());
        		mPackageProductsID.get(pro.Package_product__c).add(pro.Singleproduct__c+'');
        	}
        	*/
		    /*Set<String> sProductID=new Set<String>();
		 	for(OpportunityLineItem oppProduct: [Select o.PricebookEntry.Product2Id From OpportunityLineItem o where OpportunityId=:mcId]){
		 		system.debug('===================OpportunityLineItem:'+oppProduct.PricebookEntry.Product2Id);
		 		sProductID.add(oppProduct.PricebookEntry.Product2Id);
		 	}
		 	String opliIds = Apexpages.currentPage().getParameters().get('opliIds');
		 	Set<String> opliId = new Set<String>(opliIds.split('%'));

		 	//List<Product2> lstPro2 = Database.query('Select Id from Product2 where Id IN :sProductID');
        	List<DtoRsltSrch> ldto = new List<DtoRsltSrch>();
        	//DtoRsltSrch dto = new DtoRsltSrch(1, true, lstPro2.get(0));
        	//dd(new DtoRsltSrch(i,false,pbe,mAdSpec.get(pbe.Product2.Id)));
        	System.debug('=======lAD_Pri '+ lAD_Pri);*/
        	/*mAdSpec=getAd_Specs(lAD_Pri);
        	List<DtoRsltSrch>  ldto1 = convtPBEntryToDtoRsltSrch(lAD_Pri);

	        //default sort after search is Order By p.Product2.Name ASC; mSrchRsltPages contains all search results
	        System.debug('=======ldto '+ ldto1);
	        createPricebookListPages(ldto1);
	        System.debug('=======mSrchRsltPages '+ mSrchRsltPages);
        	for(List<DtoRsltSrch> l : mSrchRsltPages.values()){
                for(DtoRsltSrch d : l){
                        //if(d.spec.Id == '01t40000001OsTLAA0'){
                                //d.isChecked=true;
                                break;

                        //}
                }
        	}*/
         //lstBasket = new List<DtoRsltSrch> ();
         //viewBasket();
          //initBasket();
        }


        initBasket();



    }

    // Bunhor @25-Feb-15: recode this method to make sure all records are selected for selectOptions, reduce some fields in the query to avoid Heapsize, and clean code.
    private void initSelectListWith3Alle(){
    	lAD_Pri = new List<PricebookEntry>();

    	String query= 	' Select id, Product2.Site__r.Name, Product2.Placement__r.Name, Product2.Advertising_Medium__r.Name '+
    					' From PricebookEntry '+
    					' Where IsActive=true '+
							' and Pricebook2Id=:mcPBId '+
							' and Product2.IsActive=true Order By Product2.Name ASC ';

        Set<String> sSiteName = new Set<String>();
        Set<String> sPlacement = new Set<String>();
        Set<String> sAdType = new Set<String>();

        for(PricebookEntry ad : Database.query(query)){
        	Product2 pp = ad.Product2;
        	sSiteName.add(pp.Site__r.Name);
        	sPlacement.add(pp.Placement__r.Name);
        	sAdType.add(pp.Advertising_Medium__r.Name);
        }

        lstSiteName = createListSelectOption(sSiteName);
        lstPlacement = createListSelectOption(sPlacement);
        lstAdType = createListSelectOption(sAdType);
    }

    /**
    //initialize available criterias to be used
    private void initSelectListWith3Alle(){
        //HCS 03.06.2014
        	//KCA-8483 Inactive products being added to Opportunities
        	//When using the "Edit All" screens and the "Add Product" buttons in Opportunities, the users are able to select Products that are Inactive, just because the Pricebook Entry is Active.
        	//Please make a tweak to all of the queries that use the custom "Edit All/Add Product" screens so that only products are are "Active = True" on the Product2 table AND also "Active = True" on the Pricebook Entry are visible in the configuration screen.

        system.debug('***HB Select Product2Id, Product2.Site__c,Product2.Advertising_Medium___r.Name ,Product2.Placement__r.Name,Product2.Advertising_Medium___c,IsActive from PricebookEntry where IsActive=true ' + testRecordLimitation);
        String query= 'Select UnitPrice, Product2.AdServer_Keywords_Key_Values__c, Product2.Name, Product2Id, Product2.Site__r.Name,Product2.Advertising_Medium__r.Name ,Product2.Placement__r.Name,Product2.Advertising_Medium__c,Product2.Device_Category__c, IsActive from PricebookEntry where IsActive=true And Pricebook2Id=:mcPBId and Product2.IsActive=true Order By Product2.Name ASC '+ testRecordLimitation ;

        lAD_Pri = Database.query( query );

        system.debug('***HB COUNT: ' + lAD_Pri.size());

        Set<String> sSiteName = new Set<String>();
        Set<String> sPlacement = new Set<String>();
        Set<String> sAdType = new Set<String>();
        //Set<String> sDeviceCategory = new Set<String>();

         for(PricebookEntry ad : lAD_Pri){

                system.debug('***HB: ' + ad.Product2.Site__c);
                if(ad.Product2.Site__r.Name!=null){
                        sSiteName.add(ad.Product2.Site__r.Name);
                }
                if(ad.Product2.Placement__r.Name!=null){
                                sPlacement.add(ad.Product2.Placement__r.Name);
                }
                if(ad.Product2.Advertising_Medium__c!=null){
                                sAdType.add(ad.Product2.Advertising_Medium__r.Name);
                }

        }

        pro.Device_Category__c = pro.Device_Category__c;
        lstSiteName = createListSelectOption(sSiteName);
        lstPlacement = createListSelectOption(sPlacement);
        lstAdType = createListSelectOption(sAdType);

         //HCS 16.01.2015
        //fixed reducing view state
        lAD_Pri = new List<PricebookEntry>();

    }
    */

    //Set all criterias to default status
    public PageReference resetAction(){

        sWord='';

        siteName = Label_Alle;
        Placement =Label_Alle;
        adType = Label_Alle;
   //      doSearch();

         selectListChanged();

        return null;
    }


    //criterias changed dynamically after comboboxes changed
    public String changeOn {get; set;}

    public PageReference selectListChanged(){

        if(siteName == Label_Alle && Placement == Label_Alle && adType == Label_Alle && pro.Device_Category__c == null){
                initSelectListWith3Alle();
                isResultNone = false;
                searchMessage = '';
                return null;
        }

                searchJob();
         if(lAD_Pri.isEmpty()) return null;

        Set<String> sSiteName = new Set<String>();
        Set<String> sPlacement = new Set<String>();
        Set<String> sAdType = new Set<String>();
                for(PricebookEntry ad : lAD_Pri){
                		String deviceCategory = pro.Device_Category__c;
                        if(siteName != Label_Alle && placement == Label_Alle && adType == Label_Alle && deviceCategory == null){
                        if(ad.Product2.Site__r.Name == siteName){
                                        addToSelectList(ad,sSiteName,sPlacement,sAdType);
                        }

                        }else if(siteName == Label_Alle && placement != Label_Alle && adType == Label_Alle && deviceCategory == null){
                            if(ad.Product2.Placement__r.Name == placement ){
                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
                            }
                        }else if(siteName == Label_Alle && Placement == Label_Alle && adType != Label_Alle && deviceCategory == null){
                            if(ad.Product2.Advertising_Medium__r.Name == adType ){
                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
                            }
                        }else if(siteName == Label_Alle && Placement == Label_Alle && adType == Label_Alle && deviceCategory != null){
                            if(deviceCategory.contains(ad.Product2.Device_Category__c)){
                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
                            }
                        }else if(siteName != Label_Alle && Placement != Label_Alle && adType == Label_Alle && deviceCategory == null){
	                        if(ad.Product2.Site__r.Name == siteName && ad.Product2.Placement__r.Name == Placement){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }else if(siteName != Label_Alle && Placement == Label_Alle && adType != Label_Alle && deviceCategory == null){
	                        if(ad.Product2.Site__r.Name == siteName && ad.Product2.Advertising_Medium__r.Name == adType){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }else if(siteName != Label_Alle && Placement == Label_Alle && adType == Label_Alle && deviceCategory != null){
	                        if(ad.Product2.Site__r.Name == siteName && deviceCategory.contains(ad.Product2.Device_Category__c)){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }else if(siteName == Label_Alle && Placement != Label_Alle && adType != Label_Alle && deviceCategory == null){
	                        if(ad.Product2.Placement__r.Name == Placement && ad.Product2.Advertising_Medium__r.Name == adType){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }else if(siteName == Label_Alle && Placement != Label_Alle && adType == Label_Alle && deviceCategory != null){
	                        if(ad.Product2.Placement__r.Name == Placement && deviceCategory.contains(ad.Product2.Device_Category__c)){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }else if(siteName == Label_Alle && Placement == Label_Alle && adType != Label_Alle && deviceCategory != null){
	                        if(ad.Product2.Advertising_Medium__r.Name == adType && ad.Product2.Device_Category__c == deviceCategory){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }

                        }else if(siteName != Label_Alle && Placement != Label_Alle && adType != Label_Alle && deviceCategory == null){
	                        if(ad.Product2.Site__r.Name == siteName && ad.Product2.Placement__r.Name == Placement && ad.Product2.Advertising_Medium__r.Name == adType){
	                                        addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }else if(siteName != Label_Alle && Placement == Label_Alle && adType != Label_Alle && deviceCategory != null){
	                        if(ad.Product2.Site__r.Name == siteName && ad.Product2.Advertising_Medium__r.Name == adType && deviceCategory.contains(ad.Product2.Device_Category__c)){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }else if(siteName != Label_Alle && Placement == Label_Alle && adType == Label_Alle && deviceCategory != null){
	                        if(ad.Product2.Site__r.Name == siteName && ad.Product2.Placement__r.Name == Placement && deviceCategory.contains(ad.Product2.Device_Category__c)){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }else if(siteName == Label_Alle && Placement != Label_Alle && adType != Label_Alle && deviceCategory != null){
	                        if(ad.Product2.Placement__r.Name == Placement && ad.Product2.Advertising_Medium__r.Name == adType && deviceCategory.contains(ad.Product2.Device_Category__c)){
	                                    addToSelectList(ad,sSiteName,sPlacement,sAdType);
	                        }
                        }
                }

        if(changeOn != 'site') lstSiteName = createListSelectOption(sSiteName);
        if(changeOn != 'placement') lstPlacement = createListSelectOption(sPlacement);
        if(changeOn != 'adtype') lstAdType = createListSelectOption(sAdType);

         //HCS 16.01.2015
        //fixed reducing view state
        lAD_Pri = new List<PricebookEntry>();
        return null;
    }

    //Add corresponding options to 3 list SelectOption
    private void addToSelectList(PricebookEntry ad , Set<String> sSiteName,Set<String> sPlacement,Set<String> sAdType){
        if(ad.Product2.Site__r.Name!=null){
                        sSiteName.add(ad.Product2.Site__r.Name);
        }
        if(ad.Product2.Placement__r.Name!=null){
                sPlacement.add(ad.Product2.Placement__r.Name);
        }
        if(ad.Product2.Advertising_Medium__c!=null){
                sAdType.add(ad.Product2.Advertising_Medium__r.Name);
        }
    }


   //convert list string to list SelectOption
    private List<SelectOption> createListSelectOption(Set<String> sValues){
        List<SelectOption> lopts = new List<SelectOption>();
        List<String> lst = new List<String>(sValues);
        lst.sort();
        lopts.add(new SelectOption(Label_Alle , Label_Alle));
        for(String val : lst){
                if (val!=null) {
                        lopts.add(new SelectOption(val,val));
                }
        }
        return lopts;
    }



    //Temporary limited results for showing
    public List<DtoRsltSrch> lsrchRslt { get;set; }
    private Map<Integer,List<DtoRsltSrch>> mSrchRsltPages;
    public Integer pageNo {get;set;}
    public Integer totalPages { get;set;}
    public String searchMessage { get; set;}
        //Default sorting by Product Name ASC
    private String sortCriteria ;
        private String condition;

        //search and display found results base on input criterias
    public PageReference doSearch(){

                searchJob();
         //HCS 16.01.2015
        //fixed reducing view state
        lAD_Pri = new List<PricebookEntry>();
        return null;
    }

    private void searchJob(){
    	 /*HCS 03.06.2014
        	KCA-8483 Inactive products being added to Opportunities
        	When using the "Edit All" screens and the "Add Product" buttons in Opportunities, the users are able to select Products that are Inactive, just because the Pricebook Entry is Active.
        	Please make a tweak to all of the queries that use the custom "Edit All/Add Product" screens so that only products are are "Active = True" on the Product2 table AND also "Active = True" on the Pricebook Entry are visible in the configuration screen.
        	Added Product2.IsActive=true to the query
        */
        condition = 'Select UnitPrice, Id, Product2.AdServer_Keywords_Key_Values__c, Product2.Advertising_Medium__r.Name, Product2.Placement__r.Name, Product2.Name, Product2.Id, IsActive,Product2.Site__r.Name, Product2.Advertising_Medium__r.Dart_AdSlotSize__c, Product2.Device_Category__c From PricebookEntry Where IsActive=true AND Product2.Name!=null AND Pricebook2Id=:mcPBId And Product2.IsActive=true';

        if(sWord != '' || siteName != Label_Alle || Placement != Label_Alle|| adType != Label_Alle || pro.Device_Category__c != null){

            if(sWord != ''){

                sWord = '%'+sWord + '%';

                condition = condition + ' And Product2.Name Like: sWord ';  //word to search

            }

            if(siteName != Label_Alle){
                condition = condition + ' And Product2.Site__r.Name =:siteName ';
             }
            if(Placement != Label_Alle){
                condition = condition + ' And Product2.Placement__r.Name =:Placement ';
            }
            if(adType != Label_Alle){
                condition = condition + ' And Product2.Advertising_Medium__r.Name =:adType ';
            }
            if(pro.Device_Category__c != null){
            	String device = pro.Device_Category__c;
            	List<String> lstDevice = device.split(';');
            	//condition = condition + ' And (Product2.Device_Category__c In:lstDevice Or Product2.Device_Category__c =:device) ';

            	// Bunhor @24-Feb-15:
            	String strIncl = ''; 			// 'aa','bb','cc'
            	for(String dv : lstDevice){
            		strIncl += 	'\'' +dv +'\',';
            	}
            	strIncl = strIncl.left(strIncl.length()-1); // cut comma

                condition += ' And (Product2.Device_Category__c includes ('+strIncl+') OR Product2.Device_Category__c =:device) ';
            }
        }

        sortCriteria = !Test.isRunningTest() ?     ' Order By Product2.Name ASC ' + testRecordLimitation  : 'Order By Product2.Name ASC '  ;
              system.debug('query ==='+ condition + sortCriteria);
        lAD_Pri = Database.query(condition + sortCriteria);
        system.debug('=================lAD_Pri===='+ lAD_Pri);
        if(sWord != ''){
                sWord = sWord.substring(1,sWord.length()-1);
        }
        mAdSpec=getAd_Specs(lAD_Pri);
        List<DtoRsltSrch>  ldto = convtPBEntryToDtoRsltSrch(lAD_Pri);

        //default sort after search is Order By p.Product2.Name ASC; mSrchRsltPages contains all search results
        createPricebookListPages(ldto);

        pageNo = 1;

        totalPages = mSrchRsltPages.size();


        //first page with maximum NUMBER_ROW_VIEW_PER_PAGE records were shown when search finished
        lsrchRslt =  mSrchRsltPages.get(pageNo);

        if(lsrchRslt == null){
                searchMessage = Label_No_Result;
                isResultNone = false;
                return;
        }
        searchMessage = '';
        sortOnFldNo = '1';
        isNameAsc = true;
        isSiteAsc = false;
        isAdverAchiAsc = false;
        isAdverAdSlotAsc= false;
        isPlcAsc = false;
        isPrceAsc = false;
        isResultNone = (lsrchRslt.size()>0);
    }

    /*
    Sort List result depend on selected column.
    input List DtoRsltSrch , column number {1 => pName,2 => siteName,3 => Placement,4 => adType,5 => price } and order {'ASC','DESC'}; return new sorted List
    */

    private List<DtoRsltSrch> sortDtoRsltSrchAsc(List<DtoRsltSrch> l , Integer col , String oby){
        Set<String> adPriceIds = new Set<String>();
        for(DtoRsltSrch i : l){
                adPriceIds.add(i.price.Id);
        }
        String sortedFld = (1 == col ? 'Product2.Name' :
                                            (2 == col ? 'Product2.Site__r.Name' :
                                            (3 == col ? 'Product2.Placement__r.Name' :
                                            (4 == col ? 'Product2.Advertising_Medium__r.Name':
                                            (5 == col ? 'Product2.Advertising_Medium__r.Dart_AdSlotSize__c':
                                            'Unitprice')))));
        String querySort = 'Select UnitPrice, Id, Product2.AdServer_Keywords_Key_Values__c, Product2.Advertising_Medium__r.Name, Product2.Placement__r.Name, Product2.Name, Product2.Id, IsActive,Product2.Site__r.Name, Product2.Advertising_Medium__r.Dart_AdSlotSize__c From PricebookEntry Where Id In :adPriceIds Order By ';

        List<PricebookEntry> lpbe = Database.query(querySort + sortedFld + ' ' + oby);
        l = convtPBEntryToDtoRsltSrch(lpbe);

        for(Integer i = 0 ; i < l.size() ; i++){
                DtoRsltSrch tmp = l.get(i);
                tmp.rowInd = i+1;
                //l.set(i,tmp);
        }
        return l;
    }

    //convert data from object to Dto data
    private List<DtoRsltSrch> convtPBEntryToDtoRsltSrch(List<PricebookEntry> lpbe){

        List<DtoRsltSrch> l = new List<DtoRsltSrch> ();
        Integer i = 1;
        for(PricebookEntry pbe : lpbe){
                l.add(new DtoRsltSrch(i,false,pbe,mAdSpec.get(pbe.Product2.Id)));
                i = i + 1;
        }
        return l;

    }

    //initiate Pages Content and PageNumber; store in mSrchRsltPages
    private void createPricebookListPages(List<DtoRsltSrch> l){

        mSrchRsltPages = new Map<Integer,List<DtoRsltSrch>> ();
        List<DtoRsltSrch> ldto = new List<DtoRsltSrch>();
        Integer pageNumber = 1;
        for(DtoRsltSrch dto : l){
                ldto.add(dto);
                if(ldto.size()== NUMBER_ROW_VIEW_PER_PAGE){
                        mSrchRsltPages.put(pageNumber,ldto);
                        ldto = new List<DtoRsltSrch>();
                        pageNumber = pageNumber + 1;
                }
        }
        if(ldto.size() > 0 ){
                mSrchRsltPages.put(pageNumber,ldto);
        }

        if(mSrchRsltPages.size() <= 1){
                enabledfirst = false;
                enabledpre = false;
                enablednext = false;
                enabledlast = false;
        }else{
            enabledfirst = false;  enabledpre = false; enablednext = true;  enabledlast = true;
        }
    }

    //sort and return a set of records to be displayed
private List<DtoRsltSrch> doSortResult(String fldNo , Boolean isAsc){
      List<DtoRsltSrch> l = new List<DtoRsltSrch>();
      for(List<DtoRsltSrch> ldt : mSrchRsltPages.values() ){
        l.addAll(ldt);
      }
      l = sortDtoRsltSrchAsc (l,Integer.valueOf(fldNo),isAsc?'ASC':'DESC');

      createPricebookListPages(l);

      pageNo = 1;
      //first page with maximum NUMBER_ROW_VIEW_PER_PAGE records were shown when search finished
      return mSrchRsltPages.get(pageNo);

    }


  //Do sorting by Column header Name in list results
    public Boolean isNameAsc { set; get;}
    public String sortOnFldNo {set; get;}
    public PageReference sortByName(){
    	if( isNameAsc== null) isNameAsc= false;
      isNameAsc = (!isNameAsc);
      sortOnFldNo = '1';
      lsrchRslt = doSortResult(sortOnFldNo,isNameAsc);
      return null;
    }

    //Do sorting by Column header site in list results
    public Boolean isSiteAsc { set; get;}
    public PageReference sortBySite(){
    	if( isSiteAsc== null) isSiteAsc= false;
      isSiteAsc = (!isSiteAsc);
      sortOnFldNo = '2';
      lsrchRslt = doSortResult(sortOnFldNo,isSiteAsc);
      return null;
    }

    //Do sorting by Column header Placement in list results
    public Boolean isPlcAsc { set; get;}
    public PageReference sortByPlacement(){
    	if( isPlcAsc== null) isPlcAsc= false;
      isPlcAsc = (!isPlcAsc);
      sortOnFldNo = '3';
      lsrchRslt = doSortResult(sortOnFldNo,isPlcAsc);
      return null;
    }



    //Do sorting by Column header Adver.Achievement in list results
    public Boolean isAdverAchiAsc { set; get;}
    public PageReference sortByAdverAchi(){
    	if( isAdverAchiAsc== null) isAdverAchiAsc= false;
      isAdverAchiAsc = (!isAdverAchiAsc);
      sortOnFldNo = '4';
      lsrchRslt = doSortResult(sortOnFldNo,isAdverAchiAsc);
      return null;
    }

    //Do sorting by Column header Adver.AdSlot in list results
    public Boolean isAdverAdSlotAsc { set; get;}
    public PageReference sortByAdverAdSlot(){
     if( isAdverAdSlotAsc== null) isAdverAdSlotAsc= false;
      isAdverAdSlotAsc = (!isAdverAdSlotAsc);
      sortOnFldNo = '5';
      lsrchRslt = doSortResult(sortOnFldNo,isAdverAdSlotAsc);
      return null;
    }

    // Do sorting by Column header Price in list results
    public Boolean isPrceAsc { set; get;}
    public PageReference sortByPrice(){
      if( isPrceAsc== null) isPrceAsc= false;
      isPrceAsc =  (!isPrceAsc);
      sortOnFldNo = '6';
      lsrchRslt = doSortResult(sortOnFldNo,isPrceAsc);
      return null;
    }

    public Boolean enabledfirst { set; get;}
    public Boolean enabledpre { set; get;}
    public Boolean enablednext { set; get;}
    public Boolean enabledlast { set; get;}

    //Switch list results to next page
    public PageReference nextPage(){
        enabledfirst = true;
        enabledpre = true;
        enablednext = true;
        enabledlast = true;
        pageNo = pageNo + 1;
        if(pageNo >= mSrchRsltPages.size()){
                pageNo = mSrchRsltPages.size();
                enablednext = false;
                enabledlast = false;
        }
        lsrchRslt =  mSrchRsltPages.get(pageNo);

        return null;
    }

    //Switch list results to last page
    public PageReference lastPage(){
        enabledfirst = true;
        enabledpre = true;
        enablednext = false;
        enabledlast = false;
        pageNo = mSrchRsltPages.size();
        lsrchRslt =  mSrchRsltPages.get(pageNo);
        return null;
    }

    //Switch list results to previous page
    public PageReference prePage(){
        enabledfirst = true;
        enabledpre = true;
        enablednext = true;
        enabledlast = true;
        pageNo = pageNo - 1;
        if(pageNo <= 1 ){
                pageNo = 1;
                enabledpre = false;
                enabledfirst = false;
        }
        lsrchRslt =  mSrchRsltPages.get(pageNo);

        return null;
    }

    //Switch list results to first page
    public PageReference firstPage(){
        enabledfirst = false;
        enabledpre = false;
        enablednext = true;
        enabledlast = true;
        pageNo = 1;
        lsrchRslt =  mSrchRsltPages.get(pageNo);
        return null;
    }
    /***Basket Action***/

    private Map<Id,Product2> mAdSpec;
    //Initiate corresponding existing baskets
    private void initBasket(){
        lstBasket = new List<DtoRsltSrch> ();
        isViewBasket = false;
        List<Media_Basket__c> lmbsk= [Select Id,AdPriceIdText__c From Media_Basket__c Where UserId__c =: System.Userinfo.getUserId() And OpportunityId__c =: mcId ];

        if(!lmbsk.isEmpty()){
                isViewBasket = true;
                //List<String> sAdPriceId = new List<String>();//@suy sreymol 12/2/15
                Map<String, Media_Basket__c> mPbeIdMB = new Map<String, Media_Basket__c>();
                for(Media_Basket__c mbsk : lmbsk){
                        //sAdPriceId.add(mbsk.AdPriceIdText__c); //@suy sreymol 12/2/15
                        if (mbsk.AdPriceIdText__c != null) mPbeIdMB.put(mbsk.AdPriceIdText__c, mbsk);
                }
                Map<Id,PricebookEntry> mActivePBE = new Map<Id,PricebookEntry>([Select Unitprice, Id, Product2.Name, Product2.Id, IsActive,Product2.Site__r.Name From PricebookEntry  Where IsActive=true And Id In: mPbeIdMB.keySet()]);
                /* @suy sreymol 12/2/15
                List<PricebookEntry> l = new List<PricebookEntry>();
                for(String adPriceId : sAdPriceId){
                	// some pricebook entry not active anymore, so if we add all from sAdPriceId we can add null
                	if (m.get(adPriceId)!=null) {
                        l.add(m.get(adPriceId));
                	}
                }
                mAdSpec=getAd_Specs(l);*/
                mAdSpec=getAd_Specs(mActivePBE.values());
                isBskNameAsc = true;
                sortOnBskFldNo = '1';
                //List<DtoRsltSrch> ltmp = convtPBEntryToDtoRsltSrch(l);//@suy sreymol 12/2/15
                List<DtoRsltSrch> ltmp = convtPBEntryToDtoRsltSrch(mActivePBE.values());

              	//@suy sreymol 12/2/15
                /*for(Integer i = 0 ;i < lmbsk.size();i ++ ){
                        ltmp.get(i).mbskId=lmbsk.get(i).Id;
                }*/
                for (DtoRsltSrch dto : ltmp) dto.mbskId = mPbeIdMB.get(dto.price.Id) == null ? null : mPbeIdMB.get(dto.price.Id).Id;
                //------------ 12/2/15 -------------//
                lstBasket = sortDtoBasketAsc(ltmp,Integer.valueOf(sortOnBskFldNo),isBskNameAsc?'ASC':'DESC');
                isBskSiteAsc = false;
                isBskAdverAchiAsc = false;
                isBskAdverAdSlotAsc = false;
                isBskPlcAsc = false;
                isBskPrceAsc = false;
        }
    }

    //Retrieve corresponding Ad_Specs__c
    private Map<Id,Product2> getAd_Specs(List<PricebookEntry> l){
        Set<String> sAdSpecId=new Set<String>();
        for(PricebookEntry pr:l){
        	sAdSpecId.add(pr.Product2Id);
        }

        return new Map<Id,Product2>([Select RecordTypeId,Placement__r.Name, Placement__c, Name, AdServer_Keywords_Key_Values__c, Advertising_Medium__r.Name, Advertising_Medium__c,Site__r.Name, Advertising_Medium__r.Dart_AdSlotSize__c From Product2 Where Id In: sAdSpecId]);

    }

    public List<DtoRsltSrch> lstBasket { set; get;}
    public Boolean isViewBasket { set; get;}
    /*
    * Comment for Update Code:Package products (package component) functionality for opportunity line items
    * @date:20-06-2013
    * @author:skyvva
    */

    /*
    //Insert selected item to Basket and show the list basket
    public PageReference viewBasket(){
        isViewBasket = true;

        for(List<DtoRsltSrch> l : mSrchRsltPages.values()){
                for(DtoRsltSrch d : l){
                        if(d.isChecked){
                                d.isChecked=false;
                                //lstBasket.add(d.createClone());
                                lstBasket.add(d);
                        }
                }
        }
         //condition = 'Select UnitPrice, Id, Product2.AdServer_Keywords_Key_Values__c, Product2.Advertising_Medium__r.Name, Product2.Placement__r.Name, Product2.Name, Product2.Id, IsActive,Product2.Site__r.Name, Product2.Advertising_Medium__r.Dart_AdSlotSize__c From PricebookEntry Where IsActive=true AND Product2.Name!=null AND Pricebook2Id=:mcPBId';


        //Refresh baskets : delete all existing baskets and copy selected Item from DtoBasket
        delete [Select Id From Media_Basket__c Where UserId__c =: System.Userinfo.getUserId() And OpportunityId__c =: mcId ];
        List<Media_Basket__c> lmbsk = new List<Media_Basket__c>();
        for(DtoRsltSrch dto : lstBasket){
                lmbsk.add(new Media_Basket__c(UserId__c = System.Userinfo.getUserId() , AdPriceIdText__c = dto.Price.Id , OpportunityId__c = mcId ));
        }
        insert lmbsk;

        for( Integer i = 0 ;i < lstBasket.size() ;i ++ ){
                lstBasket.get(i).mbskId = lmbsk.get(i).Id;
        }


                lstBasket = sortDtoBasketAsc(lstBasket,1,'ASC');
                sortOnBskFldNo = '1';
        isBskNameAsc = true;
        isBskSiteAsc = false;
        isBskAdverAchiAsc = false;
        isBskAdverAdSlotAsc = false;
        isBskPlcAsc = false;
        isBskPrceAsc = false;

        doSearch();

        return null;
    }*/

     /*
    * Update:Package products (package component) functionality for opportunity line items
    * @date:20-06-2013
    * @author:skyvva
    */


    public Boolean isPackageAdding{get;set;}

    //Insert selected item to Basket and show the list basket
    public PageReference viewBasket(){
        isViewBasket = true;
        List<DtoRsltSrch> lstBasketTmp=new List<DtoRsltSrch>(lstBasket);
        set<String> sProductID=new set<String>();
        for(List<DtoRsltSrch> l : mSrchRsltPages.values()){
                for(DtoRsltSrch d : l){
                        if(d.isChecked){
                                d.isChecked=false;
                                //lstBasket.add(d.createClone());
                                lstBasket.add(d);
                                sProductID.add(d.spec.id);

                        }
                }
        }
        System.debug('>>>>>>>>>>>>>>>>>>>>>>'+lstBasket);
        //Define Package Products
        map<String,List<String>> mPackageProductsID=new map<String,List<String>>();
        for(Packagecomponent__c pro:[Select p.Singleproduct__c, p.Package_product__c From Packagecomponent__c p where Package_product__c in:sProductID]){
        	if(mPackageProductsID.get(pro.Package_product__c)==null) mPackageProductsID.put(pro.Package_product__c,new List<String>());
        	mPackageProductsID.get(pro.Package_product__c).add(pro.Singleproduct__c+'');
        }

        isPackageAdding=false;
        System.debug('>>>>>>>>>>>>>>>>>>>>>>'+lstBasket);
        System.debug('>>>>>>>>>>>>>>>>>>>>>>'+mPackageProductsID);
        if(lstBasket.size()==1 && mPackageProductsID.keySet().size()>0){
        	List<String> lstPackageProductsID=mPackageProductsID.get(lstBasket.get(0).spec.id);
        	List<DtoRsltSrch>  ldto = convtPBEntryToDtoRsltSrch([Select UnitPrice, Id, Product2.AdServer_Keywords_Key_Values__c, Product2.Advertising_Medium__r.Name, Product2.Placement__r.Name, Product2.Name, Product2.Id, IsActive,Product2.Site__r.Name, Product2.Advertising_Medium__r.Dart_AdSlotSize__c From PricebookEntry Where Product2.Id in:lstPackageProductsID AND  IsActive=true AND Pricebook2Id=:mcPBId]);
        	lstBasket=ldto;
        	if(lstBasket.isEmpty())  {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.warning, 'Package Product not found')); return null;}

        	isPackageAdding=true;
        }else if(lstBasket.size()>1 && mPackageProductsID.keySet().size()>0){
        	lstBasket=lstBasketTmp;
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Only create a single invoice line with the Package product.'));
        	return null;
        }



        //condition = ';


        //Refresh baskets : delete all existing baskets and copy selected Item from DtoBasket
        delete [Select Id From Media_Basket__c Where UserId__c =: System.Userinfo.getUserId() And OpportunityId__c =: mcId ];
        List<Media_Basket__c> lmbsk = new List<Media_Basket__c>();
        for(DtoRsltSrch dto : lstBasket){
                lmbsk.add(new Media_Basket__c(UserId__c = System.Userinfo.getUserId() , AdPriceIdText__c = dto.Price.Id , OpportunityId__c = mcId ));
        }
        insert lmbsk;

        for( Integer i = 0 ;i < lstBasket.size() ;i ++ ){
                lstBasket.get(i).mbskId = lmbsk.get(i).Id;
        }


        lstBasket = sortDtoBasketAsc(lstBasket,1,'ASC');
        sortOnBskFldNo = '1';
        isBskNameAsc = true;
        isBskSiteAsc = false;
        isBskAdverAchiAsc = false;
        isBskAdverAdSlotAsc = false;
        isBskPlcAsc = false;
        isBskPrceAsc = false;

        //if(isPackageAdding) productConfig();
        doSearch();

        return null;
    }

     /*
        Sort List Basket depend on selected column.
        input List DtoRsltSrch , column number {1 => pName,2 => siteName,3 => Placement,4 => adType,5 => price } and order {'ASC','DESC'}; return new sorted List
        */
    private List<DtoRsltSrch> sortDtoBasketAsc(List<DtoRsltSrch> l , Integer col , String oby){
        for(Integer i = 0; i< l.size()-1 ; i ++){
        for(Integer j = i ; j < l.size(); j ++){

                        //DtoRsltSrch tmp = l.get(i).createClone();
                        DtoRsltSrch tmpi = l.get(i);
                        DtoRsltSrch tmpj = l.get(j);
                        if(col != 5){
                                String sVali = (1 == col ? tmpi.spec.Name :
                                                    (2 == col ? tmpi.spec.Site__r.Name :
                                                    (3 == col ? tmpi.spec.Placement__r.Name :
                                                    (4 == col ? tmpi.spec.Advertising_Medium__r.Dart_AdSlotSize__c :
                                                    tmpi.spec.Advertising_Medium__r.Name))));

                                String sValj = (1 == col ? tmpj.spec.Name :
                                                    (2 == col ? tmpj.spec.Site__r.Name :
                                                    (3 == col ? tmpj.spec.Placement__r.Name  :
                                                    (4 == col ? tmpj.spec.Advertising_Medium__r.Dart_AdSlotSize__c :
                                                    tmpj.spec.Advertising_Medium__r.Name))));

                                if((oby == 'ASC' && sVali > sValj) ||(oby == 'DESC' && sVali < sValj)){
                                        l.set(i,tmpj);
                                        l.set(j,tmpi);
                                }
                        }else{
                                Decimal dVali = tmpi.price.Unitprice;
                                Decimal dValj = tmpj.price.Unitprice;

                                if((oby == 'ASC' && dVali > dValj) ||(oby == 'DESC' && dVali < dValj)){
                                        l.set(i,tmpj);
                                        l.set(j,tmpi);
                                }
                        }

        }
        }
        for(Integer i = 0 ; i < l.size() ; i++){
                DtoRsltSrch tmp = l.get(i);
                tmp.rowInd = i+1;
                //l.set(i,tmp);
        }
        return l;
    }

    //Do sorting by Column header ProductName in list Basket
    public Boolean isBskNameAsc { set; get;}
    public String sortOnBskFldNo {set; get;}
    public PageReference sortByBskName(){
        isBskNameAsc = (!isBskNameAsc);
        sortOnBskFldNo = '1';

        lstBasket = sortDtoBasketAsc(lstBasket,Integer.valueOf(sortOnBskFldNo),isBskNameAsc?'ASC':'DESC');

        return null;
    }

    //Do sorting by Column header site in list Basket
    public Boolean isBskSiteAsc { set; get;}
    public PageReference sortByBskSite(){
        isBskSiteAsc = (!isBskSiteAsc);
        sortOnBskFldNo = '2';

        lstBasket = sortDtoBasketAsc(lstBasket,Integer.valueOf(sortOnBskFldNo),isBskSiteAsc?'ASC':'DESC');
        return null;
    }

    //Do sorting by Column header Placement in list Basket
    public Boolean isBskPlcAsc { set; get;}
    public PageReference sortByBskPlacement(){
        isBskPlcAsc = (!isBskPlcAsc);
        sortOnBskFldNo = '3';
        lstBasket = sortDtoBasketAsc(lstBasket,Integer.valueOf(sortOnBskFldNo),isBskPlcAsc?'ASC':'DESC');

        return null;
    }



    //Do sorting by Column header Adver.Achievement in list Basket
    public Boolean isBskAdverAchiAsc { set; get;}
    public PageReference sortByBskAdverAchi(){
        isBskAdverAchiAsc = (!isBskAdverAchiAsc);
        sortOnBskFldNo = '4';


        lstBasket = sortDtoBasketAsc(lstBasket,Integer.valueOf(sortOnBskFldNo),isBskAdverAchiAsc?'ASC':'DESC');

        return null;
    }

    //Do sorting by Column header Adver.AdSlot in list Basket
    public Boolean isBskAdverAdSlotAsc { set; get;}
    public PageReference sortByBskAdverAdSlot(){
      isBskAdverAdSlotAsc = (!isBskAdverAdSlotAsc);
      sortOnBskFldNo = '5';


      lstBasket = sortDtoBasketAsc(lstBasket,Integer.valueOf(sortOnBskFldNo),isBskAdverAdSlotAsc?'ASC':'DESC');


      return null;
    }

    //Do sorting by Column header Price in list Basket
    public Boolean isBskPrceAsc { set; get;}
    public PageReference sortByBskPrice(){
        isBskPrceAsc = (!isBskPrceAsc);
        sortOnBskFldNo = '5';


        lstBasket = sortDtoBasketAsc(lstBasket,Integer.valueOf(sortOnBskFldNo),isBskPrceAsc?'ASC':'DESC');


        return null;
    }

    public String delItemId { set; get;}
    // Remove selected items from basket
    public PageReference removeBskItem(){
        List<DtoRsltSrch> tmps=new List<DtoRsltSrch>();
        Set<String> smbskId = new Set<String>();
                        for(Integer i = 0 ; i < lstBasket.size(); i++){
                        if(!lstBasket.get(i).isChecked){
                                tmps.add(lstBasket.get(i));
                                smbskId.add(lstBasket.get(i).mbskId);
                        }
                }
                lstBasket=tmps;
                for(Integer i = 0 ; i < lstBasket.size(); i++){
                                lstBasket.get(i).rowInd = i + 1;
                }
                delete [Select Id From Media_Basket__c Where UserId__c =: System.Userinfo.getUserId() And OpportunityId__c =: mcId And Id Not In : smbskId];
        return null;
    }

     private void showError(String err){
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Info,err);
           ApexPages.addMessage(myMsg);
        }



    //Transfer all items in Basket to ModifyProduct page
    public PageReference productConfig(){
    	//System.debug('==========:Run productConfig');
        /*//Delete all the existing baskets  before starting product configuration (if any)
        delete [Select Id From Media_Basket__c Where UserId__c =: System.Userinfo.getUserId() And Media_Campaign__c =: mcId ];

        //Reconstruct the baskets and go to product configuration page
        List<Media_Basket__c> lmbsk = new List<Media_Basket__c>();
        for(DtoRsltSrch dto : lstBasket){
                lmbsk.add(new Media_Basket__c(UserId__c = System.Userinfo.getUserId() , AdPriceIdText__c = dto.Price.Id , Media_Campaign__c = mcId ));
        }*/
        if(lstBasket.isEmpty()){
                isViewBasket = true;
                showError(Label_Empty_Basket);
                return null;
        }
        //insert lmbsk;
       String tmpmcPBId=mcPBId;
       if(tmpmcPBId!=null && tmpmcPBId.length()>15)  tmpmcPBId=tmpmcPBId.substring(0, 15);
       //System.debug('==============tmpmcPBId:'+tmpmcPBId);
      if(tmpmcPBId!=null && (tmpmcPBId=='01s40000000QlNl' || tmpmcPBId=='01s40000000Qi3T' || tmpmcPBId=='01s40000000FWsL')){

      	if(isExistingDART6Part(mcId,lstBasket)){
        	return new PageReference(MODIFYPRODUCTURL.replace('%', mcId)+'&mcPBId='+mcPBId);
        }else{
        	return new PageReference(MODIFYPRODUCTNONBANNERURL.replace('%', mcId)+'&mcPBId='+mcPBId);
        }
      }

      else if(mcPBId == '01s40000000QjhAAAS')   // Advertising Sales
      {

        	return new PageReference(MODIFYPRODUCTURL.replace('%', mcId)+'&mcPBId='+mcPBId);

      }
      else {
      	return new PageReference(MODIFYPRODUCTNONBANNERURL.replace('%', mcId)+'&mcPBId='+mcPBId);
      }
    }




 public static Boolean isExistingDART6Part(String mcId,List<DtoRsltSrch> lstBasket){

 	String dart6RecordTypeID=getRecordTypeID('Product2',DART6_RECORDTYPE);
 	if(dart6RecordTypeID==null|| mcId==null) return false;
 	//Check on existing Opportunity product
 	Set<String> sProductID=new Set<String>();
 	for(OpportunityLineItem oppProduct: [Select o.PricebookEntry.Product2Id From OpportunityLineItem o where OpportunityId=:mcId]){
 		//system.debug('===================OpportunityLineItem:'+oppProduct.PricebookEntry.Product2Id);
 		sProductID.add(oppProduct.PricebookEntry.Product2Id);
 	}
 	//from product2
 	for(Product2 product: [Select p.RecordTypeId From Product2 p where Id=:sProductID]){
 		//system.debug('===================Product2:'+product.RecordTypeId);
 		if(dart6RecordTypeID==product.RecordTypeId){
 			return true;
 		}
 	}
 	// check product in the ?media basket?
 	for(DtoRsltSrch dto:lstBasket){
 		//system.debug('===================DtoRsltSrch:'+dto.spec.RecordTypeId);
 		//system.debug('===================dart6RecordTypeID:'+dart6RecordTypeID);
 		if(dart6RecordTypeID==dto.spec.RecordTypeId){
 			return true;
 		}
 	}
 	return false;

 }


 public final static String DART6_RECORDTYPE='DART6';
 /*
 *
 *
 */
 public static String getRecordTypeID(String sObjectType,String name){
 	String tmp;
 	for(RecordType rec:[Select r.SobjectType, r.Name, r.Id, r.Description From RecordType r where SobjectType=:sObjectType AND name=:Name limit 1]){
 		tmp=rec.id;
 	}
 	return tmp;

 }



 /*
  *
  * Element class definition
  *     rowInd         Returns  row index
  *     isChecked      Returns  true or false
  *     spec           Returns  Ad_Specs__c
  *     price          Returns  Ad_price__c
  *
  *
  */



    public Class DtoRsltSrch{
        public Integer rowInd { set; get; }
        public Boolean isChecked { set;get;}
        public Product2 spec {set;get;}
        public PricebookEntry price {set;get;}
        public decimal tkp;

                public decimal gettkp() {

                        return this.price.Unitprice;

        }

        public String mbskId;
        //clone DtoRsltSrch
       /* public DtoRsltSrch createClone(){
                return new DtoRsltSrch(this.rowInd,this.isChecked,this.price,this.spec);
        } */
        //constructor
        public DtoRsltSrch(Integer ri , Boolean ic ,PricebookEntry it,Product2 sp){
                rowInd = ri;
                isChecked = ic;
                price=it;
                spec=sp;
        }


    }

    //MS
   /* public PageReference createBaskToCloneOPLI(){
    	String isClone = ApexPages.currentPage().getParameters().get('isClone');

    	if(isClone == 'true'){
    		String opliId = ApexPages.currentPage().getParameters().get('opliIds');
	    	List<String> lstOpliIds = new List<String>(opliId.split(','));

	    	List<OpportunityLineItem> lstOpli = new List<OpportunityLineItem>([select Id, PricebookEntryId from OpportunityLineItem where Id IN :lstOpliIds]);

	    	set<String> setPBE = new set<String>();
	    	for(OpportunityLineItem opli : lstOpli){
    			setPBE.add(opli.PricebookEntryId);
    		}
    		List<PricebookEntry> lstPBE = new List<PricebookEntry>([select Id from PricebookEntry where Id IN :setPBE]);

    		//Refresh baskets : delete all existing baskets and create new from lstPBE
        	List<Media_Basket__c> lstBasket_Old = new List<Media_Basket__c>([Select Id, AdPriceIdText__c From Media_Basket__c Where UserId__c =: System.Userinfo.getUserId() And OpportunityId__c =: mcId]);
        	delete [Select Id From Media_Basket__c Where UserId__c =: System.Userinfo.getUserId() And OpportunityId__c =: mcId];

   			Map<String, Media_Basket__c> mapBasket = new Map<String, Media_Basket__c>();
    		for(PricebookEntry pbe : lstPBE){
    			Media_Basket__c mediaBasket=new Media_Basket__c();
                        mediaBasket.OpportunityId__c=mcId;
                        mediaBasket.UserId__c=System.Userinfo.getUserId();
                        mediaBasket.AdPriceIdText__c=pbe.Id;
                mapBasket.put(pbe.Id, mediaBasket);
    		}
    		//add existing Media_Basket__c to lstBasket
    		for(Media_Basket__c bkt : lstBasket_Old){
    			Media_Basket__c mediaBasket=new Media_Basket__c();
                        mediaBasket.OpportunityId__c=mcId;
                        mediaBasket.UserId__c=System.Userinfo.getUserId();
                        mediaBasket.AdPriceIdText__c=bkt.AdPriceIdText__c;
                mapBasket.put(bkt.AdPriceIdText__c, mediaBasket);
    		}

            insert mapBasket.values();
    		initBasket();
    		return productConfig();
    		//return null;

    	}
    	return null;
    }*/
    //end of MS
     public static testmethod void TestselectSearchController(){
        Profile p=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
                User u=GW_User.createTestUser(p);
                u.Username='testUser1@boco.com';
                u.LastName='testLastName1';
                u.Email='testEmail1@boco.com';
                u.Alias='test1';
//              u.CommunityNickname='testCommun1';
                u.TimeZoneSidKey='Pacific/kiritimati';
                u.LocaleSidKey='ar';
                u.EmailEncodingKey='UTF-8';
                u.ProfileId=p.Id;
                u.LanguageLocaleKey='en_US';
                insert u;


                System.runAs(u){

                                Account acc = new Account();
                        acc.Name='Test Account Quote';
                        acc.OwnerId=u.id;
                        acc.BillingStreet='12345';
                        acc.BillingCity='Test';
                        acc.Phone='+12456796';
                        acc.BillingCountryCode='NL';
                        acc.BillingPostalCode='134697';
                        insert acc;

                        Account acc1 = new Account();
                        acc1.Name='Another Test Account';
                        acc1.OwnerId=u.id;
                        acc1.BillingStreet='67890';
                        acc1.BillingCity='Another Test';
                        acc1.Phone='+56785678';
                        acc1.BillingCountryCode='BE';
                        acc1.BillingPostalCode='234554';
                        insert acc1;

                        Contact con=new Contact();
                        con.LastName='TestContact';
                        con.AccountId=acc.Id;
                        con.Fax='1234567';
                        con.Email='Test@test.com';
                        con.MobilePhone='+134697589';

                        insert con;



                        Site__c site=new Site__c(Name='siteTest');
                        insert site;

                        Placement__c placement=new Placement__c(Name='TestPlacements');
                        insert placement;

                         // Create a custom price book
				        Pricebook2 pb = new Pricebook2(Name='Custom Pricebook', isActive=true);
				        insert pb;



                     	Id pricebookId = Test.getStandardPricebookId();


                        //Pricebook2 pb =  [select Id from Pricebook2 where IsStandard=false and IsActive=true limit 1];
                        //Pricebook2 pbstd = [select Id from Pricebook2 where IsStandard=true];
                        // HB
                        DART_ID_Placement_assignment__c spassign=new DART_ID_Placement_assignment__c(Placement__c=placement.id,Site__c=site.id);
                        insert spassign;
                        // HB

                        //@sreymol 10/03/2014
                        List<Site__c> lsites = new List<Site__c>();
                        for (Integer i = 0; i < 10; i++ ) {
                        	lsites.add(new Site__c(Country__c = 'Afganistan'));
                        }
                        insert lsites;

                        Advertising_Medium__c adType=new Advertising_Medium__c(Name='AdType');
                        insert adType;

                        Product2 adSpec=new Product2(Site__c = lsites[0].Id, Name='Test Ad Spec',placement__c=placement.id,AdServer_Keywords_Key_Values__c='AAA',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec;

                        Product2 adSpec1=new Product2(Site__c = lsites[1].Id, Name='Test Ad Spec1',placement__c=placement.id,AdServer_Keywords_Key_Values__c='BBB',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec1;

                        Product2 adSpec2=new Product2(Site__c = lsites[2].Id, Name='Test Ad Spec',placement__c=placement.id,AdServer_Keywords_Key_Values__c='AAA',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec2;

                        Product2 adSpec3=new Product2(Site__c = lsites[3].Id, Name='Test Ad Spec1',placement__c=placement.id,AdServer_Keywords_Key_Values__c='BBB',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec3;

                        Product2 adSpec4=new Product2(Site__c = lsites[4].Id, Name='Test Ad Spec',placement__c=placement.id,AdServer_Keywords_Key_Values__c='AAA',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec4;

                        Product2 adSpec5=new Product2(Site__c = lsites[5].Id, Name='Test Ad Spec1',placement__c=placement.id,AdServer_Keywords_Key_Values__c='BBB',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec5;

                        Product2 adSpec6=new Product2(Site__c = lsites[6].Id, Name='Test Ad Spec',placement__c=placement.id,AdServer_Keywords_Key_Values__c='AAA',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec6;

                        Product2 adSpec7=new Product2(Site__c = lsites[7].Id, Name='Test Ad Spec1',placement__c=placement.id,AdServer_Keywords_Key_Values__c='BBB',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec7;

                        Product2 adSpec8=new Product2(Site__c = lsites[8].Id, Name='Test Ad Spec',placement__c=placement.id,AdServer_Keywords_Key_Values__c='AAA',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec8;

                        Product2 adSpec9=new Product2(Site__c = lsites[9].Id, Name='Test Ad Spec1',placement__c=placement.id,AdServer_Keywords_Key_Values__c='BBB',Advertising_Medium__c=adType.id,IsActive=true);
                        insert adSpec9;

                        List<PricebookEntry> ladPriceStd = new  List<PricebookEntry>();
                        PricebookEntry adPriceStd=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec.id,UnitPrice=100,IsActive=true);
                        ladPriceStd.add(adPriceStd);

                        PricebookEntry adPrice1Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec1.id,UnitPrice=200,IsActive=true);
                        ladPriceStd.add(adPrice1Std);

                        PricebookEntry adPrice2Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec2.id,UnitPrice=300,IsActive=true);
                        ladPriceStd.add(adPrice2Std);

                        PricebookEntry adPrice3Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec3.id,UnitPrice=400,IsActive=true);
                        ladPriceStd.add(adPrice3Std);

                        PricebookEntry adPrice4Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec4.id,UnitPrice=500,IsActive=true);
                        ladPriceStd.add(adPrice4Std);

                        PricebookEntry adPrice5Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec5.id,UnitPrice=600,IsActive=true);
                        ladPriceStd.add(adPrice5Std);

                        PricebookEntry adPrice6Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec6.id,UnitPrice=700,IsActive=true);
                        ladPriceStd.add(adPrice6Std);

                        PricebookEntry adPrice7Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec7.id,UnitPrice=800,IsActive=true);
                        ladPriceStd.add(adPrice7Std);

                        PricebookEntry adPrice8Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec8.id,UnitPrice=900,IsActive=true);
                        ladPriceStd.add(adPrice8Std);

                        PricebookEntry adPrice9Std=new PricebookEntry(Pricebook2Id=pricebookId,Product2Id=adSpec9.id,UnitPrice=1000,IsActive=true);
                        ladPriceStd.add(adPrice9Std);

                        List<PricebookEntry> ladPrice = new  List<PricebookEntry>();

                        PricebookEntry adPrice=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec.id,UnitPrice=100,IsActive=true);
                        ladPrice.add(adPrice);

                        PricebookEntry adPrice1=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec1.id,UnitPrice=200,IsActive=true);
                        ladPrice.add(adPrice1);

                        PricebookEntry adPrice2=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec2.id,UnitPrice=300,IsActive=true);
                        ladPrice.add(adPrice2);

                        PricebookEntry adPrice3=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec3.id,UnitPrice=400,IsActive=true);
                        ladPrice.add(adPrice3);

                        PricebookEntry adPrice4=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec4.id,UnitPrice=500,IsActive=true);
                        ladPrice.add(adPrice4);

                        PricebookEntry adPrice5=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec5.id,UnitPrice=600,IsActive=true);
                        ladPrice.add(adPrice5);

                        PricebookEntry adPrice6=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec6.id,UnitPrice=700,IsActive=true);
                        ladPrice.add(adPrice6);

                        PricebookEntry adPrice7=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec7.id,UnitPrice=800,IsActive=true);
                        ladPrice.add(adPrice7);

                        PricebookEntry adPrice8=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec8.id,UnitPrice=900,IsActive=true);
                        ladPrice.add(adPrice8);

                        PricebookEntry adPrice9=new PricebookEntry(Pricebook2Id=pb.Id,Product2Id=adSpec9.id,UnitPrice=1000,IsActive=true);
                        ladPrice.add(adPrice9);


                        insert ladPriceStd;
                        insert  ladPrice;
                        Set<String> testScopeId = new Set<String>();
                        for(PricebookEntry li : ladPrice){
                                testScopeId.add(li.Id);
                        }


                        Opportunity mediaCampaign=new Opportunity(Name='Test Media campaign Test',Pricebook2Id=pricebookId,AccountId=acc.id,Description='Test',Agency__c=acc1.id, StageName='Test', Probability=50,CloseDate=system.today());
                        insert mediaCampaign;

                        Media_Basket__c mediaBasket=new Media_Basket__c();
                        mediaBasket.OpportunityId__c=mediaCampaign.id;
                        mediaBasket.UserId__c=u.id;
                        mediaBasket.AdPriceIdText__c=adPrice.id;

                        insert mediaBasket;

                        Media_Basket__c mediaBasket1=new Media_Basket__c();
                        mediaBasket1.OpportunityId__c=mediaCampaign.id;
                        mediaBasket1.UserId__c=u.id;
                        mediaBasket1.AdPriceIdText__c=adPrice1.id;

                        insert mediaBasket1;

                        Pagereference pg=Page.SelectSearch;
                        Test.setCurrentPageReference(pg);
                                pg.getParameters().put('Id',mediaCampaign.Id);

                                List<OpportunityLineItem> cmi = new List<OpportunityLineItem>();
                                cmi.add(new OpportunityLineItem(OpportunityId=mediaCampaign.Id) );
                                SelectSearchController selectSearchcontrol=new SelectSearchController(' limit 10', testScopeId,new ApexPages.StandardController (new OpportunityLineItem(OpportunityId=mediaCampaign.Id))); // And Id In :testScopeId

                                Test.StartTest();


                                //search with key search = 'Test' , number of found records equals to number of object in list ladPrice
                                selectSearchcontrol.sWord='Test Ad Spec';
                                selectSearchcontrol.doSearch();

                                  Boolean  isExistingDart6=SelectSearchController.isExistingDART6Part( pricebookId, selectSearchcontrol.lsrchRslt);
                               // System.assertEquals(ladPrice.size(),selectSearchcontrol.lsrchRslt.size());

                                //Default type of sorting is ASC. The first item in list result is adPrice
                                selectSearchcontrol.sortByPrice();
                               // System.assertEquals(adPrice.Id,selectSearchcontrol.lsrchRslt.get(0).price.Id);

                                //All adPrice related to the same adType . After sorting, result is the same
                                selectSearchcontrol.sortByAdverAchi();
//                              System.assertEquals(adPrice.Id,selectSearchcontrol.lsrchRslt.get(0).price.Id);

                                selectSearchcontrol.sortByPlacement();
//                              System.assertEquals(adPrice.Id,selectSearchcontrol.lsrchRslt.get(0).price.Id);

                                selectSearchcontrol.sortBySite();


                                selectSearchcontrol.sortByName();
                               // System.assertEquals(adSpec1.Name,selectSearchcontrol.lsrchRslt.get(0).spec.Name);

                                //Same process as sorting in lsrchRslt
                                selectSearchcontrol.sortByBskName();

                                selectSearchcontrol.sortByBskSite();

                                selectSearchcontrol.sortByBskPlacement();

                                selectSearchcontrol.sortByBskAdverAchi();

                                selectSearchcontrol.sortByBskPrice();


                                //Result after search contains only 1 page
                                selectSearchcontrol.nextPage();
                                selectSearchcontrol.prePage();
                                selectSearchcontrol.lastPage();
                                selectSearchcontrol.firstPage();
                               // System.assertEquals(1,selectSearchcontrol.pageNo);

                                //Add 2 items to basket. There are 4 items including existing items.
                                selectSearchcontrol.lsrchRslt.get(0).isChecked=true;
                                selectSearchcontrol.lsrchRslt.get(1).isChecked=true;
                                selectSearchcontrol.viewBasket();
                               // System.assertEquals(4, selectSearchcontrol.lstBasket.size());
                                selectSearchcontrol.productConfig();



                                //Remove 2 items from basket. There are 2 items remaining.
                                selectSearchcontrol.lstBasket.get(0).isChecked=true;
                                selectSearchcontrol.lstBasket.get(1).isChecked=true;
                                selectSearchcontrol.removeBskItem();
                                System.assertEquals(2, selectSearchcontrol.lstBasket.size());
                                selectSearchcontrol.productConfig();

                                 selectSearchcontrol.sWord='Test Ad Spec';
                                selectSearchcontrol.siteName= site.name;
                          		selectSearchcontrol.selectListChanged();
                                selectSearchcontrol.doSearch();
                               // System.assertEquals(ladPrice.size(),selectSearchcontrol.lsrchRslt.size());


                                 selectSearchcontrol.pro.Device_Category__c='test';
                                 selectSearchcontrol.adType='test';
                                 selectSearchcontrol.doSearch();
                                //Criterias change to the default values
                	             selectSearchcontrol.resetAction();
                	             selectSearchcontrol=new SelectSearchController();
                	             selectSearchcontrol=new SelectSearchController(new ApexPages.StandardController (new OpportunityLineItem(OpportunityId=mediaCampaign.Id))); // And Id In :testScopeId
                      // 'opliIds'
                                Test.stopTest();

                }
     }

}