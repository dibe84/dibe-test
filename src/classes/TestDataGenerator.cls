public class TestDataGenerator {
    
    public Id standardPbId;
    public Map<String, String> mapDartRecordType;
    public List<Product2> lstPrd2;
    public List<PricebookEntry> lstPrdbEnDart;
    public Opportunity opp;
    public List<OpportunityLineItem> lstLineItems;
    public Targeting__c[] targetting;
    public Content__c[] contents;
    public Region__c[] regions;
    //public PlacementTargeting__c[] placementTg; 
    //Chr: @updated 05-09-2014: Comment out this block of code below in order to avoid dependency when deploy to UAT
    public PlacementTargetingDefinition__c[] placementTg; 
    public AreaCode__c[] areaCodes;
    public City__c[] cities;
    public Country__c[] countries;
    public DART_KeyValue_2__c[] keyvalues;
    public AdServer_Login__c[] listLogin;
    public Site__c[] sites;
    public Advertiser__c[] lstAdvertiser;
    public Account[] lstAcc;
    //public OpportunityTeamMember oppTeam;
    private Placement__c[] lstPlacements;
    
    //create below variables to test with Device/Contection/Geography targeting
    public Devices__c[] lstDevices;
    public Connection__c[] lstConns;
    public Geography__c[] lstGeographies;
    public static User userAdmin;
    private User currentUser = [ select Id from User where Id = :UserInfo.getUserId() ]; 
    
    public static final String TESTINGCURRENCY = 'USD';
    public Contact con;
    public MemberUnit__c oppMemberUnit;
    
    /**
     * insert user for testing
     */
    public void createTestUser()
    {
    	System.runAs ( currentUser ) {
	        Profile p=[Select Id, Name From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
	        userAdmin = GW_User.createTestUser(p);
	        userAdmin.Username='testUser1@boco.com';
	        userAdmin.LastName='testLastName1';
	        userAdmin.Email='testEmail1@boco.com';
	        userAdmin.Alias='test1';
	        userAdmin.TimeZoneSidKey='Pacific/kiritimati';
	        userAdmin.LocaleSidKey='ar';
	        userAdmin.EmailEncodingKey='UTF-8';
	        userAdmin.ProfileId=p.Id;
	        userAdmin.LanguageLocaleKey='en_US';   
	        insert userAdmin;
    	}                       
    }
    /**
     * create site test data
     * @param country's code
     */
    public void createSite(Set<String> codes)
    {
    	System.runAs(currentUser){
	        sites = new List<Site__c>();
	        for(String s: codes)
	        {
	            Site__c site = new Site__c(Name='Test1'+s, Country__c=s);
	            sites.add(site);
	        }
	        insert sites;
    	}
        
    }
    
    /**
     * get startdart pricebook from org
     */
    public void getPricebook2()
    {
        this.standardPbId = Test.getStandardPricebookId();
    }
    
    /**
     *  @return mapping of recordType
     */ 
    public  Map<String, String> getMappingRecordType()
    {
          if(mapDartRecordType==null)
          {
            mapDartRecordType = new Map<String, String>();
            List<RecordType> recs = [Select id, name From RecordType Where Name =:DARTUtil.DART5 OR Name=: DARTUtil.DART6];
            for(RecordType rec : recs)
            {
                mapDartRecordType.put(rec.Name, rec.Id);    
            }
          }
            
         return mapDartRecordType;
    }
    
    /**
     * get recordType by sObjectName
     * @param sobject name
     * @return mapping of recordType's name and Id
     */
    public Map<String, String> getMappingRecordType(String objName)
    {
          
            Map<String, String> mapDartRecordType = new Map<String, String>();
            List<RecordType> recs = [Select id, name From RecordType Where SobjectType =:objName];
            for(RecordType rec : recs)
            {
                mapDartRecordType.put(rec.Name, rec.Id);    
            }
         
        //Set<String> setRecName = new Set<String>{DARTUtil.DART5, DARTUtil.DART6};
        return mapDartRecordType;
    }
    
    /**
     * create product2
     * @param number of record to be created
     * @param dartVersion(RecordType)
     */
    public void createNewProduct2TypeDART(Integer numToCreate,String dartVersion)
    {
        System.runAs(currentUser){
	        lstPrd2 = new List<Product2>();
	        
	        Map<String, String> mapRecIds = getMappingRecordType('Product2');
	        createSite(new Set<String>{'DE'});
	        Advertising_Medium__c adM = new Advertising_Medium__c(name='TestadM',   Dart_MasterSize__c='300x250; 300x600',  Dart_CompanionSize__c='300x250; 300x600; 475x250',
	                                    DART_Product_type__c='Companion', DART_AdSlotSize__c='300x250; 300x600'); //Companion
	        insert adM;
	        
	        for(Integer i=0; i<numToCreate; i++)
	        {
	            Product2 prd2 = new Product2(
	                            Name='Test product'+i, 
	                            RecordTypeId=mapRecIds.get(dartVersion) , 
	                            IsActive = true, No_Availability_Forecast__c=false ,
	                            Advertising_Medium__c=adM.id,
	                            Site__c=sites.get(0).id);
	                        
	            lstPrd2.add(prd2);
	        }
	        insert lstPrd2;
        }
    }
    
    /**
     * create test new pricebookEntry
     * @param number of record to be created
     * @param dardVersion
     */
    public void createNewPricebookEntryDART(Integer numToCreate,String dartVersion)
    {
        System.runAs(currentUser){
	        lstPrdbEnDart = new List<PricebookEntry>();
	        getPricebook2();
	        createNewProduct2TypeDART(numToCreate,dartVersion);
	
	        for(integer i=0; i<numToCreate; i++)
	        {
	            PricebookEntry pbEntry2 = new PricebookEntry(
	                        unitPrice=100,
	                        Pricebook2Id = this.standardPbId,
	                        Product2Id = lstPrd2.get(i).Id,
	                        UseStandardPrice = false,
	                        IsActive = true,
                    		CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY
	                        );
	                        
	            lstPrdbEnDart.add(pbEntry2);
	            
	        }
	        
	        insert lstPrdbEnDart;
        }
        
    }
    /** 
     * Create new Opportunity 
     * @param Account
     */
    public void createOpp(Account acc)
    {
   		System.runAs(userAdmin){      //@vitou 24-04-2015 : change from currentUser to userAdmin     
   			createMemberUnit();
	        opp = new Opportunity(
	                                         Name='Test Opp',
	                                         StageName='Out of Date',
	                                         CloseDate=date.newInstance(System.today().year(), System.today().month()+1, 01),
	                                         Type='Existing Business',
	                                         AccountId=acc.Id,
                							 CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY,
	                                     	 Ad_Client_ID__c='123456', // networkID
	                                     	 MemberUnit__c = oppMemberUnit.Id
	                                         );
	        
	        insert opp;
   		}

    }
    
	/** 
     * Create new Contact 
     * @param Account
     */
    public void createContact(Account acc)
    {
   		System.runAs(userAdmin){ 
	        con = new Contact(
                             LastName = 'TestCon', 
                             AccountId = acc.Id,
                             Email = 'test@test.com'
                             );
	        
	        insert con;
   		}

    }
	
    /**
     * create opportunity team member
     * @param opportunityId
     */
    public void createOppTeamMember(String oppId)
    {
        
        System.runAs(currentUser){
	        Profile p = [select id from profile where name='Standard User'];
	        
	        List<User> lstUser = [select id From User where userName='standarduser_TestDart123_sfecg@test.com'];
	        if(lstUser.isEmpty())
	        {
	            User u = new User(alias = 'standt', email='standarduser@test.com', 
	            emailencodingkey='UTF-8', lastname='TestingUser', languagelocalekey='en_US', 
	            localesidkey='en_US', profileid = p.Id, 
	            timezonesidkey='America/Los_Angeles', username='standarduser_TestDart123_sfecg@test.com');
	        
	            insert u;
	            lstUser.add(u);
	        }
	        OpportunityTeamMember oppTeam = new OpportunityTeamMember(UserId = lstUser.get(0).id, TeamMemberRole='Primary Trafficker', opportunityId = oppId);
	        insert oppTeam;
        }
        
    }
    
    /**
     * Create test placemnt__c record
     */
     
     private void createPlacement()
     {
     	System.runAs(currentUser){
	        lstPlacements=new List<Placement__c>();
	        Placement__c plc = new Placement__c(Name='test placement', Dart_ID__c=11111);
	        lstPlacements.add(plc);
	        insert lstPlacements;
     	}
     }
     
    
    /**
     * Create test account record
     */
    public void createAccount()
    {
        System.runAs(currentUser){
        	if(userAdmin==null) createTestUser();
            lstAcc = new List<Account>();
            for(Integer i=0; i<3; i++)
            {
                Account acc = new Account(
                            Name='Test Acc'+i,
                            //Country_Code__c='DE',
                            BillingStreet='Street', 
                            BillingPostalCode='1Nl1', 
                            BillingCountryCode='NL',
                            BillingCity='City',
                            ownerId= userAdmin.Id
                          );
                lstAcc.add(acc);
            }
            insert lstAcc;  
        }
    }
    
    /**
     * create advetiser test records
     */
    public void createAdvertiser()
    {
    	System.runAs(currentUser){
	        lstAdvertiser = new List<Advertiser__c>();
	        Advertiser__c advertiser1 = new Advertiser__c(Account__c=lstAcc.get(0).id, Agency__c=lstAcc.get(0).id);
	        lstAdvertiser.add(advertiser1);
	        Advertiser__c advertiser2 = new Advertiser__c(Account__c=lstAcc.get(1).id, Agency__c=lstAcc.get(1).id, DART5_Advertiser_Id__c='111111', DART6_Advertiser_Id__c='222222');
	        lstAdvertiser.add(advertiser2);
	        
	        insert lstAdvertiser;
    	}
    }
    
    /**
     * Create OpportunityLineItem records
     * @param opportunityId
     * @param number of records to be created
     * @param dartVersion
     * @param targtingId
     */
    public void createNewOppItemsDart(String oppId,Integer numToCreate,String dartVersion,String targetingId)
    {
        System.runAs(currentUser){
	        lstLineItems = new List<OpportunityLineItem>();
	        createNewPricebookEntryDART(numToCreate,dartVersion);
	        for(Integer i=0; i<numToCreate; i++)
	        {
	            
	            String orderId = (i==0?'':'123456');
	            String advertiserId=(i==0?'':'654321');
	            String adId=(i==0?'':'123456');
	            
	            OpportunityLineItem oppItem = new OpportunityLineItem( 
	                              OpportunityId= oppId,
	                              from_Date__c =  date.newInstance(System.now().year(), System.now().month(), 1),
	                              until_Date__c = date.newInstance(System.now().year(), System.now().month(), 30),
	                              Quantity =  200+i,
	                              Billing_category__c='CPM',
	                              //Package__c='Multiformat1',
	                              Description='Test Desc'+i,
	                              Check_Inventory__c=true,
	                              AdDayOfWeek__c='Monday;Sunday',
	                              AdHourOfDay__c='12:00 - 12:59;23:00 - 23:59', //23:00 - 23:59
	                              //TotalPrice=10.0, // Bunhor @20-Jan-Commented out avoiding error: field integrity exception: UnitPrice (only one of unit price or total price may be specified)
	                              AdWebBrowsers__c='Mozilla',
	                              AdOperatingSystems__c='Macintosh',
	                              Adserver_ID_Order_ID__c=orderId,
	                              Adserver_Adv_Advertiser_ID__c=advertiserId,
	                              Ad_ID__c=adId,
	                              FC_Ad_served_every__c=5,
	                              FC_Quantity__c=100,
	                              FC_Period__c='Days',
	                              PricebookEntryId=lstPrdbEnDart.get(i).id,
	                              Targeting__c=targetingId,
	                              Ad_Name__c = 'LineItemTest', 
	                              //13/1/2014 - to aoivd null pointer exception in class HNDL_OpportunityLineItem.beforeUpdate line 25
	                              SalesPriceNet__c = 10 ,
	                              Device_Targeting__c='Test1,Test2,Test3',
	                              UniqueLineDescription__c = 'TestUniqueLineDescription'+i
	                              );
	                              
	            
	            lstLineItems.add(oppItem);
	        } 
	        insert lstLineItems;
        }
    } 
    
    /**
     * create AdserverLogin records
     */
    public void createCredential()
    {
    	System.runAs(currentUser){
	        Map<String,String> mapRecType = getMappingRecordType('AdServer_Login__c');
	        
	        AdServer_Login__c login6 = new AdServer_Login__c(RecordTypeId=mapRecType.get(DARTUtil.DART6),
	            Name = 'DE',
	            Login_URL__c='http://test.com',
	            User_Name__c='dart6testuser@gmail.com',
	            Password__c ='testpwddart6123456',
	            Active__c = true,
	            Network_ID__c='123456',
	            Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
	            Client_Secret__c = 'xxxxxxxxxxxxxxx',
	            Refresh_Token__c = 'xxxxxxxxxxx'
	            );
	            
	            listLogin = new List<AdServer_Login__c>{login6};
	            insert listLogin;
	            //create custom setting Webservice_Settings__c
	            createWebserviceCusSetting();
    	}     
    }
    
    /**
     * create Country test records
     * @param number of records to be created
     */ 
    public void createCountries(Integer numToCreate)
    {
    	System.runAs(currentUser){
	        countries = new List<Country__c>();
	        for(Integer i=0;i<numToCreate;i++)
	        {
	            Country__c c = new Country__c(Name='Test'+i,Country_Code__c='X'+i,Dart_ID__c=1000+i);
	            countries.add(c); 
	        }
	        insert countries;
    	}
    }
    
    /**
     * create City test records
     * @param number of records to be created
     * @param CountryId
     */
    public  void createCities(Integer numToCreate,String countryId)
    {
    	System.runAs(currentUser){
	        cities = new List<City__c>();
	        for(Integer i=0;i<numToCreate;i++)
	        {
	            City__c c = new City__c(Name='Allberto'+i,State_Region__c='BC',Country__c=countryId,Dart_ID__c=2000+i);
	            cities.add(c); 
	        }
	        insert cities; 
    	}
    }
    
   /**
     * create Areacode test records
     * @param number of records to be created
     */
    public void createAreaCodes(Integer numToCreate)
    {
    	System.runAs(currentUser){
	        areaCodes = new List<AreaCode__c>();
	        for(Integer i=0;i<numToCreate;i++)
	        {
	            AreaCode__c a = new AreaCode__c(Name='Area '+i, Dart_ID__c='11000'+i);
	            areaCodes.add(a);
	        }
	        
	        insert areaCodes;
    	}
    }
    
    /**
     * create Region test records
     * @param number of records to be created
     */
    public void createRegions(Integer numToCreate)
    {
    	System.runAs(currentUser){
	        regions = new List<Region__c>();
	        for(Integer i=0;i<numToCreate;i++)
	        {
	            Region__c r = new Region__c(Name='region '+i,   Dart_ID__c=Decimal.valueof('11000'+i), Active__c=true);
	            regions.add(r);
	        }
	        
	        insert regions;
    	}
    }
    /**
     * Type:
     * Dart - Site
     * Dart - Zone
     * Dart - ContentCategory
     * @param number of record to be created
     * @param list type of content
     */
    public void createContents(Integer numToCreate,List<String> ctype)
    {
    	System.runAs(currentUser){
	        contents = new List<Content__c>();
	        for(Integer i=0;i<numToCreate;i++)
	        {
	            Content__c c = new Content__c(Name='4000'+i,DartName__c='DartName'+i,Type__c=ctype[i]);
	            contents.add(c);
	        }
	        insert contents;
    	}
    }

    /**
     * create DartKeyvalue2 test records
     * @param number of records to be created
     */
    public void createKV(Integer numToCreate)
    {
    	System.runAs(currentUser){
	        keyvalues = new List<DART_KeyValue_2__c>();
	        for(Integer i=0;i<numToCreate;i++)
	        {
	            DART_KeyValue_2__c kv = new DART_KeyValue_2__c(Name='DE RTM Targeting'+i,Key__c='seg'+i,Key_Value__c='seg'+i,Key_Value_Name__c='DE RTM Targeting',Active__c=true);
	            keyvalues.add(kv);
	        }
	        insert keyvalues;
    	}
    }
    
    /**
     * create targeting test records
     * @param number of records to be created
     */
    public void createTargetings(Integer numToCreate)
    {
    	System.runAs(currentUser){
	        targetting = new List<Targeting__c>();
	        for(Integer i=0;i<numToCreate;i++)
	        {
	            Targeting__c t = new Targeting__c(Description__c='test',Key_Values__c='key=value');
	            targetting.add(t);
	        }
	        insert targetting;
    	}
    }
    
    //13/01/2015 - to create Devices for testing
    public void createDevices() {
    	System.runAs(currentUser){
            lstDevices = new List<Devices__c>();
            Devices__c dev1 = new Devices__c(Name = 'Test1', Dart_ID__c=123456, DFP_API_Name__c='DeviceManufacturer');
            insert dev1;
            Devices__c dev2 = new Devices__c(Name = 'Test2', Dart_ID__c=555555, Node_ID__c= dev1.Id, DFP_API_Name__c='DeviceCategory');
            insert dev2;
            Devices__c dev3 = new Devices__c(Name = 'Test3', Dart_ID__c=333333, Node_ID__c= dev1.Id, DFP_API_Name__c='DeviceCategory');
            insert dev3;
            lstDevices.add(dev1);
            lstDevices.add(dev2);
            lstDevices.add(dev3);
            //Dev Browser
            Devices__c devDv = new Devices__c(Name = 'Test', Dart_ID__c=09089, Node_ID__c= dev1.Id, DFP_API_Name__c='Browser');
            insert devDv;
            Devices__c devDv1 = new Devices__c(Name = 'Test', Dart_ID__c=12678, Node_ID__c= devDv.Id);
            insert devDv1;
            lstDevices.add(devDv);
            lstDevices.add(devDv1);
            // BrowserLanguage
            Devices__c devBl = new Devices__c(Name = 'Test', Dart_ID__c=555550, Node_ID__c= dev1.Id, DFP_API_Name__c='BrowserLanguage');
            insert devBl;
            Devices__c devBl1 = new Devices__c(Name = 'Test3', Dart_ID__c=555551, Node_ID__c= devBl.Id);
            insert devBl1;
            lstDevices.add(devBl);
            lstDevices.add(devBl1);
            //DeviceCapability
            Devices__c devDc = new Devices__c(Name = 'Test', Dart_ID__c=444440, Node_ID__c= dev1.Id, DFP_API_Name__c='DeviceCapability');
            insert devDc;
            Devices__c devDc1 = new Devices__c(Name = 'Test3', Dart_ID__c=444441, Node_ID__c= devDc.Id);
            insert devDc1;
            lstDevices.add(devDc);
            lstDevices.add(devDc1);
            //OperatingSystem
            Devices__c devOs = new Devices__c(Name = 'Test', Dart_ID__c=333330, Node_ID__c= dev1.Id, DFP_API_Name__c='OperatingSystem');
            insert devOs;
            Devices__c devOs1 = new Devices__c(Name = 'Test3', Dart_ID__c=333331, Node_ID__c= devOs.Id);
            insert devOs1;
            lstDevices.add(devOs);
            lstDevices.add(devOs1);
            //OperatingSystemVersion
            Devices__c devOsv = new Devices__c(Name = 'Test', Dart_ID__c=222220, Node_ID__c= dev1.Id, DFP_API_Name__c='OperatingSystemVersion');
            insert devOsv;
            Devices__c devOsv1 = new Devices__c(Name = 'Test3', Dart_ID__c=222221, Node_ID__c= devOsv.Id);
            insert devOsv1;
            lstDevices.add(devOsv);
            lstDevices.add(devOsv1);
            //MobileDevice
            Devices__c devMd = new Devices__c(Name = 'Test', Dart_ID__c=111110, Node_ID__c= dev1.Id, DFP_API_Name__c='MobileDevice');
            insert devMd;
            Devices__c devMd1 = new Devices__c(Name = 'Test3', Dart_ID__c=111100, Node_ID__c= devMd.Id);
            insert devMd1;
            lstDevices.add(devMd);
            lstDevices.add(devMd1);
            //MobileDeviceSubmodel
            Devices__c devMds = new Devices__c(Name = 'Test', Dart_ID__c=404040, Node_ID__c= dev1.Id, DFP_API_Name__c='MobileDeviceSubmodel');
            insert devMds;
            Devices__c devMds1 = new Devices__c(Name = 'Test3', Dart_ID__c=404041, Node_ID__c= devMds.Id);
            insert devMds1;
            lstDevices.add(devMds);
            lstDevices.add(devMds1);
    	}
     }
    
    //13/01/2015 - to create Connection for testing 
     public void createConnections() {
    	System.runAs(currentUser){
	        lstConns = new List<Connection__c>();
	        Connection__c conn1 = new Connection__c(Name = 'Test1', Dart_ID__c=123456, DFP_API_Name__c='BandwidthGroup');
	        insert conn1;
	        Connection__c conn2 = new Connection__c(Name = 'Test3', Dart_ID__c=111111, DFP_API_Name__c='MobileCarrier');
	        insert conn2;
	        Connection__c conn3 = new Connection__c(Name = 'Test1', Dart_ID__c=666666, Node_ID__c = conn1.Id);
	        insert conn3;
	        
	        Connection__c conn4 = new Connection__c(Name = 'Test1', Dart_ID__c=121213, Node_ID__c = conn2.Id);
	        insert conn4;
	        Connection__c conn5 = new Connection__c(Name = 'Test3', Dart_ID__c=131414, Node_ID__c = conn2.Id);
	        insert conn5;
	
	        lstConns.add(conn1);
	        lstConns.add(conn2);
	        lstConns.add(conn3);
	        lstConns.add(conn4);
	        lstConns.add(conn5);
    	}
    }
    
    
    //13/01/2015 - to create Geography for testing
    public void createGeographies() {
    	System.runAs(currentUser){
	        lstGeographies = new List<Geography__c>();
	        Geography__c geo1 = new Geography__c(Name = 'Test1', Dart_ID__c=123456, Type__c = 'COUNTRY');
	        insert geo1;
	        Geography__c geo2 = new Geography__c(Name = 'Test2', Dart_ID__c=888888, Type__c = 'CITY', Node_ID__c=geo1.Id);
	        insert geo2;
	        Geography__c geo3 = new Geography__c(Name = 'Test3', Dart_ID__c=999999, Type__c = 'CITY', Node_ID__c=geo2.Id);
	        insert geo3;
	        lstGeographies.add(geo1);
	        lstGeographies.add(geo2);
	        lstGeographies.add(geo3);
    	} 
    }
    
    /**
     * create targeting Association
     */ 
    public void createTargetingHierarchy()
    {
    	System.runAs(currentUser){
	        List<Sobject> listObj = new List<SObject>();
	        createTargetings(1);
	        
	        //country + assoc
	        createCountries(1);
	        TargetingCountryAssociation__c countryAssoc = new TargetingCountryAssociation__c(TargetCountry__c='TestCountry', Targeting__c=targetting[0].Id, Country__c=countries[0].Id);
	        listObj.add(countryAssoc);
	        
	        //city +  assoc
	        createCities(1,countries[0].Id);
	        TargetingCityAssociation__c cityAsso =new TargetingCityAssociation__c(targetcity__c='TestCity',Targeting__c=targetting[0].Id,City__c=cities[0].Id);
	        listObj.add(cityAsso);
	        
	        // Regions
	        createRegions(1);
	        TargetingRegionAssociation__c regionAss =new    TargetingRegionAssociation__c(  TargetRegion__c='TestRegion',Targeting__c=targetting[0].Id, Region__c=regions[0].Id);
	        listObj.add(regionAss);
	        
	        //area +  assoc
	        createAreaCodes(1);
	        TargetingAreaCodeAssociation__c tgArea = new TargetingAreaCodeAssociation__c(AreaCode__c=areaCodes[0].Id,Targeting__c=targetting[0].Id);
	        listObj.add(tgArea);
	        
	        //kv +  assoc
	        createKV(1);
	        
	        TargetingKeyValueAssociation__c kvAssoc = new TargetingKeyValueAssociation__c(Name='kvAssocTest',DART_KeyValue__c=keyvalues[0].Id,Targeting__c=targetting[0].Id);
	        listObj.add(kvAssoc);
	        
	        //content +  assoc
	        createContents(3,new List<String>{'Dart - Site','Dart - Zone','Dart - Zone'});
	        TargetingContentAssociation__c contAssoc = new TargetingContentAssociation__c(Target_Content_Key__c='key',Targeting__c=targetting[0].Id,TargetingContent__c=contents[0].Id);
	        TargetingContentAssociation__c contAssoc2 = new TargetingContentAssociation__c(Target_Content_Key__c='key-111',Targeting__c=targetting[0].Id,TargetingContent__c=contents[1].Id);
	        listObj.add(contAssoc);
	        listObj.add(contAssoc2);
	
	        //Placement +  assoc
	        //Chr: @updated 05-09-2014: Comment out this block of code in order to avoid dependency when deploy to UAT
	        createPlacement();
	        PlacementTargetingAssociation__c placementAssoc = new PlacementTargetingAssociation__c(Targeting__c=targetting[0].Id, Placement__c=lstPlacements[0].id);
	        listObj.add(placementAssoc);
	        
	        // 13/01/2015 device + asso
	        createDevices();
	        TargetingDeviceAssociation__c devAssoc = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev', Targeting__c=targetting[0].Id, Device__c = lstDevices[0].id);
	        listObj.add(devAssoc);
	        TargetingDeviceAssociation__c devAssoc2 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[1].id);
	        listObj.add(devAssoc2);
	        TargetingDeviceAssociation__c devAssoc3 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[2].id);
	        listObj.add(devAssoc3);
	        TargetingDeviceAssociation__c devAssoc4 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[3].id);
	        listObj.add(devAssoc4);
	        TargetingDeviceAssociation__c devAssoc5 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[4].id);
	        listObj.add(devAssoc5);
	        TargetingDeviceAssociation__c devAssoc6 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[5].id);
	        listObj.add(devAssoc6);
	        TargetingDeviceAssociation__c devAssoc7 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[6].id);
	        listObj.add(devAssoc7);
	        TargetingDeviceAssociation__c devAssoc8 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[7].id);
	        listObj.add(devAssoc8);
	        TargetingDeviceAssociation__c devAssoc9 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[8].id);
	        listObj.add(devAssoc9);
	        TargetingDeviceAssociation__c devAssoc10 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[9].id);
	        listObj.add(devAssoc10);
	        TargetingDeviceAssociation__c devAssoc11 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[10].id);
	        listObj.add(devAssoc11);
	        TargetingDeviceAssociation__c devAssoc12 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[11].id);
	        listObj.add(devAssoc12);
	        TargetingDeviceAssociation__c devAssoc13 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[12].id);
	        listObj.add(devAssoc13);
	        TargetingDeviceAssociation__c devAssoc114 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[13].id);
	        listObj.add(devAssoc114);
	        TargetingDeviceAssociation__c devAssoc15 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[14].id);
	        listObj.add(devAssoc15);
	        TargetingDeviceAssociation__c devAssoc16 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev2', Targeting__c=targetting[0].Id, Device__c = lstDevices[15].id);
	        listObj.add(devAssoc16);
	        TargetingDeviceAssociation__c devAssoc17 = new TargetingDeviceAssociation__c(TargetDevice__c='TestDev3', Targeting__c=targetting[0].Id, Device__c = lstDevices[16].id);
	        listObj.add(devAssoc17);
	        
	         //Connection + asso
	        createConnections();
	        TargetingConnectionAssociation__c connAssoc = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn', Targeting__c=targetting[0].Id, Connection__c = lstConns[0].id);
	        listObj.add(connAssoc);
	        TargetingConnectionAssociation__c connAssoc2 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn2', Targeting__c=targetting[0].Id, Connection__c = lstConns[1].id);
	        listObj.add(connAssoc2);
	        TargetingConnectionAssociation__c connAssoc3 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn3', Targeting__c=targetting[0].Id, Connection__c = lstConns[2].id);
	        listObj.add(connAssoc3);
	        TargetingConnectionAssociation__c connAssoc4 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn2', Targeting__c=targetting[0].Id, Connection__c = lstConns[3].id);
	        listObj.add(connAssoc4);
	        TargetingConnectionAssociation__c connAssoc5 = new TargetingConnectionAssociation__c(TargetConnection__c='TestConn3', Targeting__c=targetting[0].Id, Connection__c = lstConns[4].id);
	        listObj.add(connAssoc5);
	        
	        //geography + assoc
	        createGeographies();
	        TargetingGeographyAssociation__c geoAssoc = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[0].id);
	        listObj.add(geoAssoc);
	        TargetingGeographyAssociation__c geoAssoc2 = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo2', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[1].id);
	        listObj.add(geoAssoc2);
	        TargetingGeographyAssociation__c geoAssoc3 = new TargetingGeographyAssociation__c(TargetGeography__c='TestGeo3', Targeting__c=targetting[0].Id, Geography__c = lstGeographies[2].id);
	        listObj.add(geoAssoc3);
	        
	        insert listObj;
    	}
    }
    
    /**
     * create DART_KeyValue_2__c test records
     */
    public void createTargetingKVHierarchy()
    {
    	System.runAs(currentUser){
	        //createSite(new Set<String>{'DE'});
	        
	        keyvalues = new List<DART_KeyValue_2__c>(); 
	        
	        // Key Free-form 
	        DART_KeyValue_2__c k1 = new DART_KeyValue_2__c(Dart6_KeyId__c=11111,Name='car test',Key__c='car',Key_Value__c='car',Key_Value_Name__c='car',Active__c=true, Site__c=sites.get(0).id, Key_ValueType_FreeForm__c=true);
	        insert k1;
	        
	
	        DART_KeyValue_2__c val1 = new DART_KeyValue_2__c(Node_ID__c=k1.Id,Dart6_ValueId__c=22222,Name='bmw',Key_Value__c='bmw',Key_Value_Name__c='bmw',Active__c=true);
	        DART_KeyValue_2__c val2 = new DART_KeyValue_2__c(Node_ID__c=k1.Id,Dart6_ValueId__c=null,Name='hummer',Key_Value__c='hummer',Key_Value_Name__c='hummer',Active__c=true);
	        insert new DART_KeyValue_2__c[]{val1,val2};
	        
	        // Key not Free-form
	        DART_KeyValue_2__c k2 = new DART_KeyValue_2__c(Dart6_KeyId__c=123123,Name='color test',Key__c='color',Key_Value__c='color',Key_Value_Name__c='color',Active__c=true, Site__c=sites.get(0).id);
	        insert k2;
	        
	        DART_KeyValue_2__c val21 = new DART_KeyValue_2__c(Node_ID__c=k2.Id,Dart6_ValueId__c=66666,Name='red',Key_Value__c='red',Key_Value_Name__c='red',Active__c=true);
	        DART_KeyValue_2__c val22 = new DART_KeyValue_2__c(Node_ID__c=k2.Id,Dart6_ValueId__c=555555,Name='white',Key_Value__c='white',Key_Value_Name__c='white',Active__c=true);
	        insert new DART_KeyValue_2__c[]{val21,val22};
	        
	        
	        keyvalues.add(k1);
	        keyvalues.add(val1); 
	        keyvalues.add(val2); 
	        keyvalues.add(k2);
	        keyvalues.add(val21); 
	        keyvalues.add(val22);
	        
	        // Create Keyvalue Audience Segment
	        
	        List<DART_KeyValue_2__c> lstKeyAs = [Select id, name, Key_Value__c, Key_Value_Name__c From DART_KeyValue_2__c Where Key_Value__c='Audience Segment'];
	        if(lstKeyAs.size()>0)
	        {
	            
	            DART_KeyValue_2__c asVal11 = new DART_KeyValue_2__c(Node_ID__c=lstKeyAs.get(0).Id,Dart6_ValueId__c=999999,Name='Aud1',Key_Value__c='Aud1',Key_Value_Name__c='Aud1',Active__c=true);
	            DART_KeyValue_2__c asVal12 = new DART_KeyValue_2__c(Node_ID__c=lstKeyAs.get(0).Id,Dart6_ValueId__c=888888,Name='Aud2',Key_Value__c='Aud2',Key_Value_Name__c='Aud2',Active__c=true);
	            insert new DART_KeyValue_2__c[]{asVal11,asVal12};
	            
	            keyvalues.addAll(lstKeyAs);
	            keyvalues.add(asVal11);
	            keyvalues.add(asVal12);
	            
	        }
	        else
	        {
	            DART_KeyValue_2__c kvAs = new DART_KeyValue_2__c(Dart6_KeyId__c=123123,Name='Audience Segment',Key__c='Audience Segment',Key_Value__c='Audience Segment',Key_Value_Name__c='Audience Segment',Active__c=true);
	            insert kvAs;
	            
	            DART_KeyValue_2__c asVal1 = new DART_KeyValue_2__c(Node_ID__c=kvAs.Id,Dart6_ValueId__c=999999,Name='Aud1',Key_Value__c='Aud1',Key_Value_Name__c='Aud1',Active__c=true);
	            DART_KeyValue_2__c asVal2 = new DART_KeyValue_2__c(Node_ID__c=kvAs.Id,Dart6_ValueId__c=888888,Name='Aud2',Key_Value__c='Aud2',Key_Value_Name__c='Aud2',Active__c=true);
	            insert new DART_KeyValue_2__c[]{asVal1,asVal2};
	            
	            keyvalues.add(kvAs);
	            keyvalues.add(asVal1);
	            keyvalues.add(asVal2);
	            
	        }
	        
	        
	          //TargetingKeyValueAssociation__c kvAssoc1 = new TargetingKeyValueAssociation__c(Name='kvAssocTest1',DARTKeyValue__c=val1.Id,Targeting__c=targetting[0].Id);
	          //TargetingKeyValueAssociation__c kvAssoc2 = new TargetingKeyValueAssociation__c(Name='kvAssocTest2',DARTKeyValue__c=val2.Id,Targeting__c=targetting[0].Id);
	          //insert new TargetingKeyValueAssociation__c[]{kvAssoc1,kvAssoc2};
    	}   
	        
        
        
    }
    
    /**
     * @return list of OpportunityLineItems
     * @param OpportunityId
     * @param LineItemIds
     */
    public List<OpportunityLineItem> getOppItem(String oppId, Set<String> lineItemIds)
    {
        
        Set<String> dartRecType = new Set<String>{DARTUtil.DART6};
        BatchAvailabilityForecastProcess batchFc = new BatchAvailabilityForecastProcess(oppId, lineItemIds); 
        //System.debug('----------------> : ' + batchFc.soqlItems);     
        //List<OpportunityLineItem> lstItem = Database.query(batchFc.soqlItems +' Where ID=:oppItemId AND PricebookEntry.Product2.RecordType.Name IN:dartRecType' );
        List<OpportunityLineItem> lstItem = Database.query(batchFc.soqlItems);
        return lstItem; 
    }
    
    /**
     * @return opportunity
     * @param oppId
     */
    public Opportunity getOppty(String oppId)
    {

        Opportunity opp = [Select id, Name, P_O_Number__c, CampaignStart__c, CampaignEnd__c, Owner.Name, Owner.id, Owner.Email
                , Agency__c, AccountId, Owner.Dart_User_Name__c, IOnumber__c From Opportunity Where id =: oppId];
                
         return opp;            
        
        
    }
    
    public static Map<Id, OpportunityLineItem> putLineItemById (List<OpportunityLineItem> opportunityLineItems) {
        
        Map<Id, OpportunityLineItem> opportunityLineItemById = new Map<Id, OpportunityLineItem>();
        
        for (OpportunityLineItem opportunityLineItem : opportunityLineItems) {
            
            opportunityLineItemById.put(opportunityLineItem.Id, opportunityLineItem);
                    
        } 
        
        return opportunityLineItemById;
                
    }
    
    public void createWebserviceCusSetting(){
    	Webservice_Settings__c webseviceSetting 	= Webservice_Settings__c.getInstance('DFP');
    	if(webseviceSetting==null){
    		webseviceSetting = new Webservice_Settings__c(Name = 'DFP', UseProxy__c=true, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user');
    		insert webseviceSetting;
    	}
    }
    
    public void createMemberUnit(){
		//create member
		Member__c mb = new Member__c(Name='Test member', Account__c = lstAcc[0].id, MemberId__c = 'Test');
		insert mb;
		//create memberUnit
		oppMemberUnit = new MemberUnit__c(Name = 'Test member unit', Member__c=mb.Id, LineOfBusiness__c='AD');
		insert oppMemberUnit;
		
	}
    
}