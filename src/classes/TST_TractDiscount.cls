@isTest
private class TST_TractDiscount {
    
    public static DF factory;

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;
    
    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'EBAYKRE_Rep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'EBAYKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'Opportunity'
            }
            
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('EBAYKRE-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'RE',
                DF_Scenario.CONF_USERS               => new List<String> { 'EBAYKRE_Rep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser',
                DF_Scenario.CONF_PRICEBOOK           => 'EBAYKRE_DBA_2017',
                DF_Scenario.CONF_PRODUCTS => new List<Map<String, Object>> {
                    new Map<String, Object> {
                        DF_Scenario.CONF_PRODUCT_QUANTITY => 2,
                        DF_Scenario.CONF_PRODUCT_AD_ID => '12345678901234567890',
                        DF_Scenario.CONF_PRODUCT_DATA => new List<SObject> {
                            new Product2(
                                Name = 'Test Prod-1',
                                ProductCode = 'DBA_BAN',
                                Billing_Category__c = 'CPM_Delivery',
                                ScheduleAheadTerm__c = 12,
                                ContractPeriodInMonths__c = null,
                                BillingScheme__c = 'Monthly in Arrears',
                                CPC_Price__c = 1.00,
                                CPM_Price__c = 115.00,
                                Description = 'This is test.',
                                Product_SubType__c = 'RE'
                            ),
                            new PricebookEntry(
                                PriceCalculator__c = null,
                                Tiered_OffsetPrice__c = 0.00,
                                Tiered_AdditionalPrice__c = 0.00,
                                Fixed_PricePerMonth__c = 0.00,
                                Tiered_Tiersize__c = 0.00,
                                Tiered_FinalAdjustment__c = 0.00,
                                UnitPrice = 1.00,
                                MaxDiscountPercent__c = 73.00,
                                UseStandardPrice = false,
                                IsActive = true
                            )
                        }
                    }
                },
                DF_Scenario.CONF_OPPORTUNITY         => new Map<String, String> {
                    DF_Scenario.CONF_OPPORTUNITY_COUNT      => '1',
                    DF_Scenario.CONF_OPPORTUNITY_START_DATE => String.valueOf(Date.today().addMonths(-1))
                }
            })
        };
    }
    
	@testSetup
    public static void setup() {
         
        //Use DF instead
        //TST_TractGeneric.setup();
        
        UTIL.isRunningTestSetup = true;
        factory = new DF(scenarios, scenarioUsers);
        factory.setup();
        
        List<Webservice_Settings__c> wss = new List<Webservice_Settings__c>();
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_UAT', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        wss.add(new Webservice_Settings__c(Name = 'WSC_Tract_PROD', UseProxy__c=false, EndpointProxy__c='xxxxxx', Endpoint__c='yyyyyy', User__c='test_user'));
        insert wss;
        
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String>{'products'});
        Product2 pro = result.products.values().get(0);
        pro.Tract_Id__c = 'Tract12345';
        update pro;
        
        UTIL_CustomJob.createMissingCustomJobs();
        
        UTIL.isRunningTestSetup = false;
        
    	
    }
    
    /** Test for BAT_DiscountContentImportFromTRACT.cls **/
	@isTest static void test_BAT_DiscountContentImportFromTRACT() {

		Test.startTest();
			UTIL_CustomJob.startCustomJob('BAT_DiscountContentImportFromTRACT');
		Test.stopTest(); 

		//Assert
		UTIL_CustomJob.CustomJobDef cjDef = UTIL_CustomJob.getJobDef('BAT_DiscountContentImportFromTRACT');
		System.debug('### cjDef :: ' + cjDef);

		List<WS_ScheduledCallout__c> wsscsToUpsert = [SELECT UniqueKey__c FROM WS_ScheduledCallout__c WHERE RecordId__c=:cjDef.setting.Id];
		System.debug('### wsscsToUpsert :: ' + wsscsToUpsert);

		System.assertEquals(1, wsscsToUpsert.size(), 'There should be a record of WS_ScheduledCallout__c.');
		System.assert( String.isNotBlank(wsscsToUpsert.get(0).UniqueKey__c), 'Unique Key should have value.' );
		System.assert( wsscsToUpsert.get(0).UniqueKey__c.containsIgnoreCase('DiscountContentSync'), 'Unique Key should contain "DiscountContentSync" string.' );
		System.assert( wsscsToUpsert.get(0).UniqueKey__c.containsIgnoreCase( cjDef.setting.Id ), 'Unique Key should contain BAT_DiscountContentImportFromTRACT - Custom Job Id.' );

	}
	
	/** Test for BAT_DiscountResourceImportFromTRACT **/
	@isTest static void test_BAT_DiscountResourceImportFromTRACT () {

		Test.startTest();
			UTIL_CustomJob.startCustomJob('BAT_DiscountResourceImportFromTRACT');
		Test.stopTest();

		//Assert
		UTIL_CustomJob.CustomJobDef cjDef = UTIL_CustomJob.getJobDef('BAT_DiscountResourceImportFromTRACT');
		System.debug('### cjDef :: ' + cjDef);

		List<WS_ScheduledCallout__c> wsscsToUpsert = [SELECT UniqueKey__c FROM WS_ScheduledCallout__c WHERE RecordId__c=:cjDef.setting.Id];
		System.debug('### wsscsToUpsert :: ' + wsscsToUpsert);

		
		System.assertEquals(1, wsscsToUpsert.size(), 'There should be a record of WS_ScheduledCallout__c.');
		System.assert( String.isNotBlank(wsscsToUpsert.get(0).UniqueKey__c), 'Unique Key should have value.' );
		System.assert( wsscsToUpsert.get(0).UniqueKey__c.containsIgnoreCase('DiscountResourceSync'), 'Unique Key should contain "DiscountResourceSync" string.' );
		System.assert( wsscsToUpsert.get(0).UniqueKey__c.containsIgnoreCase( cjDef.setting.Id ), 'Unique Key should contain BAT_DiscountResourceImportFromTRACT - Custom Job Id.' );
	}

	/** Test for BAT_ProductDiscountImportFromTRACT **/
	@isTest static void test_BAT_ProductDiscountImportFromTRACT () {
		
		Test.startTest();
			UTIL_CustomJob.startCustomJob('BAT_ProductDiscountImportFromTRACT');
		Test.stopTest();

		//Assert
		List<Product2> lstProd = [SELECT Name, Tract_NeedsDiscountRelationsSync__c FROM Product2 WHERE Name='Test Prod-1' AND Tract_Id__c <> NULL LIMIT 1];
		System.debug('### lstProd :: ' +  lstProd);

		System.assertEquals( 1, lstProd.size(), 'There should be 1 tract product.' );
		System.assertEquals( true, lstProd.get(0).Tract_NeedsDiscountRelationsSync__c, 'This product should have Tract_NeedsDiscountRelationsSync__c equal TRUE.' );
	}
	
	/** Test for GW_ProductDiscountRelation.cls  **/
	@isTest
	static void test_GW_ProductDiscountRelation(){

		Test.startTest();

		// query created product
		Product2 createdProduct = [ SELECT Id FROM Product2 LIMIT 1 ];

		// create Discount__c record
		Discount__c newDiscount = new Discount__c();
		newDiscount.Amount__c = 100;
		newDiscount.IsActive__c = true;
		newDiscount.Name = 'newDiscount';
		insert newDiscount;

		// create ProductDiscountRelation__c record
		ProductDiscountRelation__c newProductDiscountRelation = new ProductDiscountRelation__c();
		newProductDiscountRelation.Discount__c = newDiscount.Id;
		newProductDiscountRelation.IsActive__c = true;
		newProductDiscountRelation.Product__c = createdProduct.Id;
		insert newProductDiscountRelation;

		// cover for method getRecord
		ProductDiscountRelation__c result = GW_ProductDiscountRelation.getRecord( newProductDiscountRelation.Id );
		System.assertEquals( newProductDiscountRelation.Id, result.Id );

		// cover for method getMap, getList
		Map<id,ProductDiscountRelation__c> resultMap = GW_ProductDiscountRelation.getMap( new Set<Id>{ newProductDiscountRelation.Id } );
		System.assertEquals( newProductDiscountRelation.Id, resultMap.get( newProductDiscountRelation.Id ).Id );

		// cover for method getListFromRelated, getIdSetFromRelated
		List<ProductDiscountRelation__c> resultList = GW_ProductDiscountRelation.getListFromRelated( newDiscount.Id );
		System.assertEquals( 1, resultList.size() );  
		
		resultList = GW_ProductDiscountRelation.getListFromRelated( new Set<Id>{ newDiscount.Id } );
		System.assertEquals( 1, resultList.size() );
		
		Set<Id> resultSet = GW_ProductDiscountRelation.getIdSetFromRelated( new Set<Id>{ newDiscount.Id } );
		System.assertEquals( 1, resultSet.size() );

		Test.stopTest();
	}
	
	/** Test for HNDL_Discount **/
	@isTest static void test_HNDL_Discount () {

		Test.startTest();

			//Scenario-1 : Insert
			Discount__c dis1 = new Discount__c( Name = 'Test-Dis', Tract_NeedsCodeSync__c = true, Tract_ResourceId__c = 'Tract12345' );
			insert dis1;

			//Assert
			List<WS_ScheduledCallout__c> wsscsToUpsert = [SELECT UniqueKey__c, RecordId__c FROM WS_ScheduledCallout__c WHERE RecordId__c=:dis1.Id];
			System.debug('### dis1 - wss :: ' + wsscsToUpsert);
			System.assert( String.isNotBlank(wsscsToUpsert.get(0).UniqueKey__c), 'Unique Key should have value.' );
			System.assert( wsscsToUpsert.get(0).UniqueKey__c.containsIgnoreCase('DiscountCodesSync'), 'Unique Key should contain "DiscountCodesSync" string.' );
			System.assert( wsscsToUpsert.get(0).UniqueKey__c.containsIgnoreCase( dis1.Id ), 'Unique Key should contain Discount Id.' );

			//Scenario-1 : Update Tract_NeedsCodeSync__c from FALSE to TRUE
			Discount__c dis2 = new Discount__c( Name = 'Test-Dis', Tract_NeedsCodeSync__c = false, Tract_ResourceId__c = 'Tract12346' );
			insert dis2;

			dis2.Tract_NeedsCodeSync__c = true;
			update dis2;

			//Assert
			wsscsToUpsert = [SELECT UniqueKey__c, RecordId__c FROM WS_ScheduledCallout__c WHERE RecordId__c=:dis2.Id];
			System.debug('### dis2 - wss :: ' + wsscsToUpsert);
			System.assert( String.isNotBlank(wsscsToUpsert.get(0).UniqueKey__c), 'Unique Key should have value.' );
			System.assert( wsscsToUpsert.get(0).UniqueKey__c.containsIgnoreCase('DiscountCodesSync'), 'Unique Key should contain "DiscountCodesSync" string.' );
			System.assert( wsscsToUpsert.get(0).UniqueKey__c.containsIgnoreCase( dis2.Id ), 'Unique Key should contain Discount Id.' );

		Test.stopTest();

	}
}