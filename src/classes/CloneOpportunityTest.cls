/**
 * @created by Chr: 04-09-2015
 * @desc: test logic on CloneOpportunity.cls
 */

@isTest
public with sharing class CloneOpportunityTest {
    static TestDataGenerator testDATA = new TestDataGenerator();
    //start test clone

    static{
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id); 
    }

    static testMethod void testCloneOpp1(){
        Test.startTest();
            Boolean areProdsAllowed     = CloneOpportunity.isOppCloningWithProductsAllowed(testDATA.opp.id);
            Boolean cloneWithAttachment = false; // set from different clone buttons

            String result = CloneOpportunity.cloneOpp(testDATA.opp.id , areProdsAllowed, cloneWithAttachment);
            
        Test.stopTest();
        System.assertEquals(result.substring(0,3), '006', 'Returns cloned opportunity Id');
    }

    static testMethod void testCloneOpp2(){
        Test.startTest();
            Boolean areProdsAllowed     = CloneOpportunity.isOppCloningWithProductsAllowed(testDATA.opp.id);
            Boolean cloneWithAttachment = true; // set from different clone buttons

            List<Attachment> lstNewAtts  = new List<Attachment>{
               new Attachment(parentId   = testDATA.opp.id, name = 'test', body = Blob.valueOf('Test content'))
            };
            insert lstNewAtts;
            
            String result = CloneOpportunity.cloneOpp(testDATA.opp.id , areProdsAllowed, cloneWithAttachment);
        Test.stopTest();
        System.assertEquals(result.substring(0,3), '006', 'Returns cloned opportunity Id');
    }
}