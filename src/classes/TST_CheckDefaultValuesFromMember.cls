@isTest
public class TST_CheckDefaultValuesFromMember extends TSTDF_Base {

    public TST_CheckDefaultValuesFromMember(TSTDF_Dataset dataset) {
            super(dataset);
    }

    public static TST_CheckDefaultValuesFromMember factory = new TST_CheckDefaultValuesFromMember(new TSTDF_Dataset());


    public class TSTDF_Dataset extends TSTDF_BaseDataSet {

        public override Member__c constructMember(Member__c member) {
            member.DefaultAgencyDiscount__c = 50;
            return member;
        }

    }

    public override void queryAdditionalResults() {}

    @testSetup static void setup(){
        UTIL.isRunningTestSetup = true;
        factory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }

	@isTest static void TST_CorrectAgencyDiscount() {
		factory.queryResults();

        Account advertiser = factory.data.accounts[0];

        Account agency = new Account(Name='Agency',
                                Member__c=advertiser.Member__c,
                                RecordTypeId = UTIL_RecordType.getRecordTypeByName('Account', 'Agency').Id,
                                OwnerId = advertiser.OwnerId);

        insert agency;

        agency = [SELECT Id, Name, AccountDiscount__c, RecordTypeId FROM Account WHERE Id =: agency.Id];

        System.assertEquals(agency.RecordTypeId, UTIL_RecordType.getRecordTypeByName('Account', 'Agency').Id);
        System.assertEquals('Agency', agency.name);
        System.assertEquals(50, agency.AccountDiscount__c);
        System.assertEquals(0,  advertiser.AccountDiscount__c);
	}

    @isTest static void TST_CorrectMemberUnitOnLead() {

        factory.queryResults();
        Lead l = factory.data.leads[0];

        System.assertNotEquals(null, l.MemberUnit__c);
        System.assertNotEquals(null, l.Member__c);

    }

}