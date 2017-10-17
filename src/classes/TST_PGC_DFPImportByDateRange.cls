@isTest
private class TST_PGC_DFPImportByDateRange {
    
    @isTest static void testDFPImportByDateRange() {
        Test.startTest();
        PageReference pgRef = Page.PG_DFPImportByDateRange;
        Test.setCurrentPageReference (pgRef);
        PGC_DFPImportByDateRange control = new PGC_DFPImportByDateRange();
        control.getsObjectTypeOptions();
        control.getimportTypeOptions();
        control.doSchImport();
        System.assert(ApexPages.getMessages()[0].getDetail().startsWith('SUCCESS'), 'Job must be started');
        ApexPages.getMessages().clear();
        control.startDate = control.endDate.addDays(7);
        control.doSchImport();
        System.assert(!ApexPages.getMessages()[1].getDetail().startsWith('SUCCESS'), 'Job must be failed to get starts');
        Test.stopTest();
    }
}