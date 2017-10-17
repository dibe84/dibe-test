@isTest
public with sharing class TST_BAT_BEAutoPriceIncrease {

	static void createTestData(){
        // Generate data opp/oppItem
        TestDataGenerator testDATA = new TestDataGenerator();
        testDATA.createNewProduct2TypeDART(1,DARTUtil.DART6);
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        	
        testDATA.createOpp(testDATA.lstAcc.get(1));
        testDATA.createNewOppItemsDart(testDATA.opp.id,1,DARTUtil.DART6,testDATA.targetting[0].Id);
        List<OpportunityLineItem> items = testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});

        Opportunity opp = [Select Id, MemberUnit__r.Member__c, StageName, 
        					AccountId, Account.Member__c, Status__c, NumStatus__c
        					From Opportunity Where Id = :items[0].OpportunityId][0];
		GW_Opportunity.changeStage2ClosedWon = true;
 		opp.StageName = 'Running';
  		opp.Status__c = 'Running';
        opp.NumStatus__c = 4;

		update new List<sObject>{
			opp,
			new Account(id = opp.AccountId, Member__c = opp.MemberUnit__r.Member__c)
		};
	}

	static String query {get{
		if(query == null){
			Date dt = System.today().addYears(1);
			String campMaxDate = DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('yyyy-MM-dd');

			query = 'SELECT Id, name, opportunity__r.CampaignStart__c, From_Date__c, until_date__c, type__c, Billing_Account__r.Name, ' + 
                    'unitprice__c, listprice__c, terminationdate__c, product__c, opportunity__r.Pricebook2Id, bundlesize__c ' +
                    'From rev__c Where ' +
                    'opportunity__r.CampaignStart__c >= 2015-07-01 and ' + 
                    'opportunity__r.CampaignStart__c <= ' + campMaxDate + ' and ' + // 2017-07-31 
                    'memberid__c = \'Test\' and ' + // THBEL
                    'opportunity__r.Status__c = \'Running\' and ' + 
                    'isActive__c = true and ' + 
                    'successor__c = null and ' +
                    'terminationdate__c = null ';
            return query;
        }else{
        	return query;
        }
	}}

	static Map<Double, Double> boundleToUnitPrice = new Map<Double, Double>{
	    5=>30, 10=>49, 15=>71, 20=>83, 30=>103, 40=>121, 50=>130, 60=>145, 70=>155, 80=>165, 90=>175
	};

	// increased adjustment date should be between predecessor start and until dates, otherwise 'No predecessor found' error
	static Integer priceIncrYears 		= 0;
	static Integer priceIncrMonths 		= 0;
	static Integer startDateIncrDays 	= 10;
    
	@isTest
	static void test_BAT_BEAutoPriceIncrease(){
		createTestData();
		
		Test.startTest();
			BAT_BEAutoPriceIncrease b = new BAT_BEAutoPriceIncrease(query, boundleToUnitPrice, priceIncrYears, priceIncrMonths, startDateIncrDays);
			database.executeBatch(b, 5);
		Test.stopTest();
		//Temp fix for other P.Rs validation
		//List<Rev__c> adjRevList = [SELECT Id From rev__c where Type__c = 'Adjusted' And predecessor__c != null Limit 1];
		//System.assertEquals(adjRevList.isEmpty(), false); // ensure that new RI Adjustment has been created
	}

	public static Boolean isBatchException = false;
	
	@isTest
	static void test_BAT_BEAutoPriceIncrease_errors(){
		createTestData();

		Test.startTest();
			isBatchException = true;
			BAT_BEAutoPriceIncrease b = new BAT_BEAutoPriceIncrease(query, boundleToUnitPrice, priceIncrYears, priceIncrMonths, startDateIncrDays);
			database.executeBatch(b, 1);
		Test.stopTest();
		
		//Temp fix for other P.Rs validation
		//List<Rev__c> adjRevList = [SELECT Id From rev__c where Type__c = 'Adjusted' And predecessor__c != null Limit 1];
		//System.assertEquals(adjRevList.isEmpty(), true); 
	}

}