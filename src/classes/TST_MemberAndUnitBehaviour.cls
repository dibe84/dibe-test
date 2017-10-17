@isTest
private class TST_MemberAndUnitBehaviour {

    @testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
    	UTIL.isRunningTestSetup = false;
    }	

	@isTest static void test_BeforeInsertOppSetMemberUnitUserInMemberUnitRole() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        
        System.runAs(fac.testUser){
			MemberUnit__c TestUserMemberUnit = GW_MemberUnit.getUserMemberUnit();
            System.assertNotEquals(null,TestUserMemberUnit);
			System.assertEquals(fac.opp.MemberUnit__c, TestUserMemberUnit.Id);
		}
	}
/*
	@isTest static void test_BeforeUpdateOppSetMemberUnitUserInMemberUnitRole() {

		System.runAs(df.testUser){
			
			df.initBaseElements();
			df.createOpportunity();

			Opportunity opp = [SELECT Id, MemberUnit__c FROM Opportunity WHERE Id=:df.opportunity.id];

			Test.startTest();
			
			opp.MemberUnit__c = null;
			update opp;

			Test.stopTest();
			
			opp = [SELECT Id, MemberUnit__c FROM Opportunity WHERE Id=:df.opportunity.id];
			System.assertEquals(opp.MemberUnit__c, memberUnits[0].Id);

		}
	}
	
	@isTest static void test_BeforeInsertSetMemberUnitUserInCountryLevelRole() {

		System.runAs(df.testUser){
			df.initBaseElements();

			Test.startTest();
				df.createOpportunity();
			Test.stopTest();
			
			Opportunity opp = [SELECT Id, MemberUnit__c FROM Opportunity WHERE Id=:df.opportunity.id];
			System.assertEquals(opp.MemberUnit__c, memberUnits[0].Id);
		}
	}
	
	@isTest static void test_BeforeUpdateSetMemberUnitUserInCountryLevelRole() {

		System.runAs(df.testUser){
			df.initBaseElements();
			df.createOpportunity();

			Opportunity opp = [SELECT Id, MemberUnit__c FROM Opportunity WHERE Id=:df.opportunity.id];

			Test.startTest();
				opp.MemberUnit__c = null;
				update opp;

			Test.stopTest();
			
			opp = [SELECT Id, MemberUnit__c FROM Opportunity WHERE Id=:df.opportunity.id];
			System.assertEquals(opp.MemberUnit__c, memberUnits[0].Id);
		}
	}*/
}