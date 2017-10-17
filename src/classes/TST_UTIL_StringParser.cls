@isTest
public class TST_UTIL_StringParser {
    
    @testSetup static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
   
    @isTest static void testStringParser(){
        TST_DataFactory fac = TST_DataFactory.getInstance();
        String res;
        fac.opp.account = fac.acc;
		
        try{  
        	res = UTIL_StringParser.parseAndReplace('{{Test.Name}}', fac.opp);
        }catch(Exception e){
            Boolean expectedExceptionThrown = e.getMessage().contains('Parent: test not found in field:') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        try{  
        	res = UTIL_StringParser.parseAndReplace('{{Names}}', fac.opp);
        }catch(Exception e){
            Boolean expectedExceptionThrown = e.getMessage().contains('Invalid field specified:') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        res = UTIL_StringParser.parseAndReplace('{{Account.Name}}', fac.opp);
        System.AssertEquals(res, fac.acc.name);
     
    }

}