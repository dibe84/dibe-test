@isTest
private class TST_Revenue {
    // Using basic AdSales Test set:
    // Account acc
    // Opportunity opp
    // Oli1: 1/1/2030 - 30/6/2030
    // Oli2: 31/1/2030 - 1/6/2030
    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }

    @isTest
    static void checkTestDataSet() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();

        // assert that correct Rev__c / Metric__c / Invoice__c object are created with correct properties
        fac.queryResults(); // will store results in result lists (inside factory)
        system.assertEquals(2, fac.revs.size(), 'Number of Revenue items should be 0' ); // 2 Olis were inserted
    }

    @isTest
    static void changeAdSalesOliPeriodWider() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
		TST_DataFactory.insertAccountMemberUnitAssociation(fac.opp.AccountId, fac.opp.MemberUnit__c);
        if(GW_MemberUnit.memberUnitCache.get(fac.opp.MemberUnit__c) == null) GW_MemberUnit.memberUnitCache.put(fac.opp.MemberUnit__c, new MemberUnit__c(id=fac.opp.MemberUnit__c));

        Test.startTest();
        UTIL.log('_'); // Log to ensure limits are reset, Spring 16 bug...
        System.runAs ( fac.testUser ) {
            fac.opp.ApprovalStatus__c = 'Previously Approved';
            fac.opp.ContractStatus__c = 'Not Signed';
            update fac.opp;

            fac.queryResults();

            // update OLI with wider period (eg. startdate -/- 2 months, end date +/+ 2 months)
            fac.oli1.from_Date__c = Date.newInstance(2029,11,1);
            fac.oli1.until_Date__c = Date.newInstance(2030,8,31);

            update new List<OpportunityLineItem> { fac.oli1, fac.oli2 };
        }
        System.runAs ( fac.adminUser ) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();

        fac.queryResults();

        for (RS__c rs : fac.rss) {
            UTIL.log('RS: '+rs.From_Date__c+' - '+rs.Until_Date__c+' - '+rs.UniqueKey__c);
        }

        // assert the number of RS__c and Metric__c are added correctly
        system.assertEquals(fac.numMonthsPeriod1 + fac.numMonthsPeriod2, fac.rss.size(), 'Number of Revenue Schedules should be ' + (fac.numMonthsPeriod1 + fac.numMonthsPeriod2) );
        system.assertEquals(fac.numDaysPeriod1 + fac.numDaysPeriod2, fac.metrics.size(), 'Number of Metrics should be '+(fac.numDaysPeriod1 + fac.numDaysPeriod2) );
    }

    @isTest
    static void changeAdSalesOliPeriodSmaller() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
		TST_DataFactory.insertAccountMemberUnitAssociation(fac.opp.AccountId, fac.opp.MemberUnit__c);
        if(GW_MemberUnit.memberUnitCache.get(fac.opp.MemberUnit__c) == null) GW_MemberUnit.memberUnitCache.put(fac.opp.MemberUnit__c, new MemberUnit__c(id=fac.opp.MemberUnit__c));

        Test.startTest();
        UTIL.log('_'); // Log to ensure limits are reset, Spring 16 bug...

        System.runAs ( fac.testUser ) {
            fac.opp.ApprovalStatus__c = 'Previously Approved';
            fac.opp.ContractStatus__c = 'Not Signed';
            update fac.opp;
            fac.queryResults();

            // update OLI with smaller period (eg. startdate +1 months, end date -/- 1 month)
            fac.oli1.from_Date__c = Date.newInstance(2030,2,1);
            fac.oli1.until_Date__c = Date.newInstance(2030,5,31);
            fac.oli2.from_Date__c = Date.newInstance(2030,2,28);
            fac.oli2.until_Date__c = Date.newInstance(2030,5,1);
            update new List<OpportunityLineItem>{fac.oli1, fac.oli2};
        }
        System.runAs ( fac.adminUser ) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();
        fac.queryResults();

        for (RS__c rs : fac.rss) {
            UTIL.log('RS: '+rs.From_Date__c+' - '+rs.Until_Date__c+' - '+rs.UniqueKey__c);
        }

        // assert the number of RS__c and Metric__c are added correctly
        system.assertEquals(fac.numMonthsPeriod1 + fac.numMonthsPeriod2, fac.rss.size(), 'Number of Revenue Schedules should be ' + (fac.numMonthsPeriod1 + fac.numMonthsPeriod2) );
        system.assertEquals(fac.numDaysPeriod1 + fac.numDaysPeriod2, fac.metrics.size(), 'Number of Metrics should be '+(fac.numDaysPeriod1 + fac.numDaysPeriod2) );
    }

    // JC: R2016W38 CD-675 changed how it works
    @isTest
    static void revItemsCreatedWhenOpportunityStageDraft() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
		TST_DataFactory.insertAccountMemberUnitAssociation(fac.opp.AccountId, fac.opp.MemberUnit__c);
        if(GW_MemberUnit.memberUnitCache.get(fac.opp.MemberUnit__c) == null) GW_MemberUnit.memberUnitCache.put(fac.opp.MemberUnit__c, new MemberUnit__c(id=fac.opp.MemberUnit__c));

        Test.startTest();
        UTIL.log('_'); // Log to ensure limits are reset, Spring 16 bug...

        System.runAs ( fac.adminUser ) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();

        fac.queryResults();

        // assert the number of RS__c and Metric__c are added correctly
        system.assertEquals(2, fac.revs.size(), 'Number of Revenue Items should be 2');
    }

    // JC: R2016W38 CD-675 changed how it works
    @isTest
    static void noRevItemsCreatedWhenOpportunityStageApproved() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();

        Test.startTest();
        UTIL.log('_'); // Log to ensure limits are reset, Spring 16 bug...
        System.runAs ( fac.testUser ) {
            fac.opp.ApprovalStatus__c = 'Approved';
            update fac.opp;
        }
        System.runAs ( fac.adminUser ) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();

        fac.queryResults();

        // assert the number of RS__c and Metric__c are added correctly
        system.assertEquals(2, fac.revs.size(), 'Number of Revenue Items should be 2');
    }

    @isTest
    static void revItemsAreCreatedWhenOpportunityStageSigned() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
		TST_DataFactory.insertAccountMemberUnitAssociation(fac.opp.AccountId, fac.opp.MemberUnit__c);
        if(GW_MemberUnit.memberUnitCache.get(fac.opp.MemberUnit__c) == null) GW_MemberUnit.memberUnitCache.put(fac.opp.MemberUnit__c, new MemberUnit__c(id=fac.opp.MemberUnit__c));

        Test.startTest();
        UTIL.log('_'); // Log to ensure limits are reset, Spring 16 bug...
        System.runAs ( fac.testUser ) {
            fac.opp.ApprovalStatus__c = 'Previously Approved';
            fac.opp.ContractStatus__c = 'Signed';
            update fac.opp;
        }
        update new List<OpportunityLineItem> { fac.oli1, fac.oli2 };

        System.runAs ( fac.adminUser ) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();

        fac.queryResults();
        // assert the number of RS__c and Metric__c are added correctly
        system.assertEquals(fac.numMonthsPeriod1 + fac.numMonthsPeriod2, fac.rss.size(), 'Number of Revenue Schedules should be ' + (fac.numMonthsPeriod1 + fac.numMonthsPeriod2) );
        system.assertEquals(fac.numDaysPeriod1 + fac.numDaysPeriod2, fac.metrics.size(), 'Number of Metrics should be '+(fac.numDaysPeriod1 + fac.numDaysPeriod2) );
    }

    // JC: R2016W38 CD-675 changed that below is not true anymore
    @isTest
    static void revItemsDeletedWhenOpportunityStageBelowSigned() {
        Test.startTest();
        TST_DataFactory fac = TST_DataFactory.getInstance();
		TST_DataFactory.insertAccountMemberUnitAssociation(fac.opp.AccountId, fac.opp.MemberUnit__c);
        if(GW_MemberUnit.memberUnitCache.get(fac.opp.MemberUnit__c) == null) GW_MemberUnit.memberUnitCache.put(fac.opp.MemberUnit__c, new MemberUnit__c(id=fac.opp.MemberUnit__c));

		System.runAs ( fac.testUser ) {
            fac.opp.ApprovalStatus__c = 'Previously Approved';
            fac.opp.ContractStatus__c = 'Signed';
            update fac.opp;

            fac.opp.ContractStatus__c = null;
            update fac.opp;
        }
		Test.stopTest();
        fac.queryResults();

        System.assertEquals(1, fac.opp.NumStatus__c, 'NumStatus__c not correct');
        System.assertEquals(2, fac.revs.size(), 'Number of Revenue Items should be 2');
    }

    @isTest
    static void testRevenueCalculators() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
		TST_DataFactory.insertAccountMemberUnitAssociation(fac.opp.AccountId, fac.opp.MemberUnit__c);
        if(GW_MemberUnit.memberUnitCache.get(fac.opp.MemberUnit__c) == null) GW_MemberUnit.memberUnitCache.put(fac.opp.MemberUnit__c, new MemberUnit__c(id=fac.opp.MemberUnit__c));

        Test.startTest();
        UTIL.log('_'); // Log to ensure limits are reset, Spring 16 bug...
        fac.opp.ApprovalStatus__c = 'Previously Approved';
        fac.opp.ContractStatus__c = 'Signed';
        update fac.opp;

        update new List<OpportunityLineItem> { fac.oli1, fac.oli2 };

        System.runAs ( fac.adminUser ) {
            UTIL_CustomJob.startAllCustomJobs();
        }
        Test.stopTest();

        fac.queryResults();
        RS__c rs = fac.rss[0];
        Rev__c rev = GW_Revenue.getRecord(rs.Rev__c);

        RevenueCalculator.AbstractRevenueCalculator revObj = new RevenueCalculator.AbstractRevenueCalculator();
        revObj.init(rs, rev, new List<Metric__c>(), new List<RS__c>());
        revObj.calcQuantityBooked();
        revObj.calcQuantityDelivered();
        revObj.calcQuantityBilled();
        revObj.getProductCode();

        RevenueCalculator.CPD_Delivery_RevenueCalculator cpdDevRev = new RevenueCalculator.CPD_Delivery_RevenueCalculator();
        cpdDevRev.init(rs, rev, new List<Metric__c>(), new List<RS__c>());
        cpdDevRev.calcQuantityBilled();

        RevenueCalculator.CPD_DailyFixed_RevenueCalculator cpdDailFixRev = new RevenueCalculator.CPD_DailyFixed_RevenueCalculator();
        cpdDailFixRev.calcQuantityBilled();

        RevenueCalculator.CPM_Delivery_RevenueCalculator cpmDevRev = new RevenueCalculator.CPM_Delivery_RevenueCalculator();
        cpmDevRev.init(rs, rev, new List<Metric__c>(), new List<RS__c>());
        cpmDevRev.calcQuantityBilled();

        RevenueCalculator.CPM_DailyFixed_RevenueCalculator cpmDailFixRev = new RevenueCalculator.CPM_DailyFixed_RevenueCalculator();
        cpmDailFixRev.calcQuantityBilled();

        RevenueCalculator.ServiceFee_OneTime_RevenueCalculator servFreeOnTimeRev = new RevenueCalculator.ServiceFee_OneTime_RevenueCalculator();
        servFreeOnTimeRev.calcQuantityBilled();
        servFreeOnTimeRev.calcQuantityDelivered();

        RevenueCalculator.ServiceFee_MonthlyFixed_RevenueCalculator servMonthFixRev = new RevenueCalculator.ServiceFee_MonthlyFixed_RevenueCalculator();
        servMonthFixRev.calcQuantityBilled();
        servMonthFixRev.calcQuantityDelivered();
    }

}