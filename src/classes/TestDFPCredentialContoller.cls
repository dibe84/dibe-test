/**
 * @author : vitou
 * @Date   : 09-04-2015
 */
@isTest
private class TestDFPCredentialContoller {

    static TestDataGenerator generator = new TestDataGenerator();
    private static testMethod void testCedential()
    {  
        generator.createCredential();
        generator.listLogin[0].RT_Waiting__c = true;
        generator.listLogin[0].Client_Id__c = 'clientidxxxxx';
        generator.listLogin[0].Client_Secret__c = 'secretxxxx';
        update generator.listLogin[0];
        
        PageReference pageCred = Page.DFPCredentialPage;
        pageCred.getParameters().put('code','1234567890');
        Test.setCurrentPage(pageCred);
        
        
        Test.startTest();
        DFPCredentialController con = new DFPCredentialController();
        
        //assert non selected
        con.processCredential();
        
        //select one
        con.selectedValue = generator.listLogin[0].Id+'';
        con.processCredential();
        
        con.saveToken();
        
    
        
        //con.clickTopenRecord();
        
        generator.listLogin[0].RT_Waiting__c = true;
        update generator.listLogin[0];
        
        con.cancel();
                
        
        Test.stopTest();
        
    }

    // when dart5 removed, this dart5 dependency will be removed as well.   
    private static testMethod void testCover()
    {
        Test.startTest();
        generator.createCredential();
        HTTPWrapper http = new HTTPWrapper();
        
        HTTPWrapper.SimpleRequest req = new HTTPWrapper.SimpleRequest('http://test.com/','GET','a=b',new Map<String,String>());
        HTTPWrapper.SimpleResponse res = new HTTPWrapper.SimpleResponse(req);
        
        HTTPWrapper.SimpleRequest req2 = new HTTPWrapper.SimpleRequest('http://test.com/','GET','myBody');
        
        DARTUtil.composeDigestAuthorizationHeader('paramString1', 'paramString2', 'paramString3', 'paramString4');
        
        DARTUtil.getRequestToken('DE');
        
        DARTUtil.getCredential('DART5', 'DE');
        DARTUtil.getCredential('DART6', 'DE');
        
         
        
        Test.stopTest();
    }
}