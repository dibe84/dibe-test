/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *  - test class of LPC_ProductConfigureRedirectorController
 * @references: 
 * 
 * @changeLog:
 *
 */
@isTest
public class LPC_ProductConfigureRedirectorConTest {
    
    static TestDataGenerator testDATA = new TestDataGenerator();
    @testSetup static void setup() {
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
    }
    
    @isTest static void testRedirectURL(){
        
		Opportunity opp = [Select Id From Opportunity limit 1];        
        
        ApexPages.StandardController stdCon = new ApexPages.StandardController(opp);
        LPC_ProductConfigureRedirectorController redir = new LPC_ProductConfigureRedirectorController(stdCon);
        String baseURL = redir.getBaseURL();
        System.assert(baseURL != null);
        
    }
    
}