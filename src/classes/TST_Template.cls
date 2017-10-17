@isTest
private class TST_Template {
    @testSetup static void setup() { 
        UTIL.isRunningTestSetup = true;
        TSTDF_Base fac = new TSTDF_Base();
        fac.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void checkTestDataSet() {
        TSTDF_Base fac = new TSTDF_Base();
        fac.queryResults(); // will store results in result lists (inside factory)
        TST_Coverage.giveMeCoverage();
    } 
}