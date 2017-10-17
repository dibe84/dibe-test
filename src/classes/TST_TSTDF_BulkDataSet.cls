/**
 * Test class for TSTDF_BulkDataSet.cls
 * @author: Gaeasys Team
 * @createdDate: 18-Jul-2017
 */
@isTest
public class TST_TSTDF_BulkDataSet {
	
	@isTest
    static void test_TSTDF_BulkDataSet() {
    	
    		TSTDF_BulkDataSet.ConfigItem item = new TSTDF_BulkDataSet.ConfigItem();
        item.member = 'test';
        item.memberUnit = 'test';
		item.accountCount = 1;
        item.pricebookCount = 1;
        item.productSetCount = 1;
        item.productsInProductSetCount = 1; 
        
        TSTDF_BulkDataSet.Config conf = new TSTDF_BulkDataSet.Config();
        conf.add(item);
    	
        Test.startTest();
            TSTDF_BulkDataSet df = new TSTDF_BulkDataSet(conf);
            df.getSObjectByRef('test');
            TST_DataSet ds = new TST_DataSet();
        Test.stopTest();
    }
    
}