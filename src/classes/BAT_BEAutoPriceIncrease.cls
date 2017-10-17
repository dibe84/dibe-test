global with sharing class BAT_BEAutoPriceIncrease implements Database.Batchable<sObject>{

	/**
	*   @description: This batch created for https://jira.corp.ebay.com/browse/CD-3104. 
	*					Should be deleted from production when we do not use current process
	*   @parameters: query string, boundle prices map, numbers of years/months/days to increase RI adjustment start date.
	*/

	private String query;
	private Map<Double, Double> boundleToUnitPrice;
	private Integer priceIncrMonths;
	private Integer priceIncrYears;
	private Integer priceIncrDays;

	global BAT_BEAutoPriceIncrease(String q, Map<Double, Double> riBoundlePrices, Integer startDateIncrYears, Integer startDateIncrMonths, Integer startDateIncrDays){
		this.query 				= q;
		this.boundleToUnitPrice = riBoundlePrices;
		this.priceIncrYears 	= startDateIncrYears;
		this.priceIncrMonths 	= startDateIncrMonths;
		this.priceIncrDays 		= startDateIncrDays;
	}

	global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
 
    global void execute(Database.BatchableContext BC, List<sObject> scope){
		List<Rev__c> masterRevList = (List<Rev__c>) scope;
		List<Rev__c> adjToCreateList = new List<Rev__c>();

		for(Rev__c masterRev : masterRevList) {
		    Subscription sub = new Subscription(masterRev.Id);
		    Rev__c adjustmentRev = sub.createNewAdjustment();
		    
		    Double boundle = masterRev.BundleSize__c;
		    adjustmentRev.BundleSize__c = boundle;

		    // set RI adj unit price ---------------
		    if(!boundleToUnitPrice.containsKey(boundle) || (masterRev.Billing_Account__r.Name == 'FusionIT' && masterRev.BundleSize__c != 10)) continue;

		    Double unPrice;
		    if(boundleToUnitPrice.containsKey(boundle)){
		        unPrice = (masterRev.Billing_Account__r.Name == 'FusionIT' && masterRev.BundleSize__c == 10)?
		        			45 : boundleToUnitPrice.get(boundle);
		    }

		    adjustmentRev.unitprice__c = unPrice;
		    
		    // set RI adj start date ---------------
		    if(priceIncrDays 	!= 0) adjustmentRev.from_date__c 	= masterRev.from_date__c.addDays(priceIncrDays);
		    if(priceIncrMonths 	!= 0) adjustmentRev.from_date__c 	= masterRev.from_date__c.addMonths(priceIncrMonths);
		    if(priceIncrYears 	!= 0) adjustmentRev.from_date__c 	= masterRev.from_date__c.addYears(priceIncrYears);

		    adjustmentRev.touch__c = 'PriceAdjustmentTo_01-08-2017';
		    adjustmentRev.autoExtend__c = true;
		    
		    sub.calculate(adjustmentRev);
		    UTIL.log('XX adjustmentRev: ' + adjustmentRev);
		    adjToCreateList.add(adjustmentRev);
		}

		Savepoint sp = Database.setSavepoint();
		try {
			System.debug('adjToCreateList ----- ' + adjToCreateList);
			if(Test.isRunningTest() && TST_BAT_BEAutoPriceIncrease.isBatchException) adjToCreateList.get(0).predecessor__c = 'X';
			insert adjToCreateList;
		    for(Rev__c rev : adjToCreateList) {
		      	GW_Revenue.recalcAndUpdateRevChain(rev.Id);  
		    }
		} catch (Exception ex) {
		    Database.rollback(sp);
		    //UTIL.postExceptionInfoToSlack('Ex happened: ' + ex); // cannot call future method from batch
		    UTIL.Log('XX Failed to create adjustments: ' + ex);
		}
    }
     
    global void finish(Database.BatchableContext BC){
       AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email
            			 FROM AsyncApexJob WHERE Id =:BC.getJobId()];
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       String[] toAddresses = new String[] {a.CreatedBy.Email};
       mail.setToAddresses(toAddresses);
       mail.setSubject('Status: ------> ' + a.Status);
       mail.setPlainTextBody
       ('The batch Apex job processed ' + a.TotalJobItems +
       ' batches with '+ a.NumberOfErrors + ' failures.');
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
