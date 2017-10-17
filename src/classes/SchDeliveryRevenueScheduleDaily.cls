/**
* Schedualable to run Delivery import
*  - Type Dialy
*  - SobjectType Metric(Metric__c)
*/
global class SchDeliveryRevenueScheduleDaily implements Schedulable{
    global void execute(SchedulableContext sc) {
    	//Import DFP Delivery
        DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_METRIC);
        //Import Adx report
        DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_METRIC, DeliveryController.ADX_IMPORT);
    }
    
    global static void start(){
        SchDeliveryRevenueScheduleDaily s = new SchDeliveryRevenueScheduleDaily();
        String sch = '0 0 12 * * ?'; // '0 0 12 * * ?' == every day @12:00 Should consider Time Zone's for specific site... (AU = +10h)
        String jobID;
        if (!Test.IsRunningTest() ) jobID = system.schedule('SchDeliveryRevenueScheduleDaily', sch, s);
        else                        jobID = system.schedule('SchDeliveryRevenueScheduleDaily TEST', sch, s); // running test
    }
    
    static testMethod void testSch()
    {
        Test.startTest();
        start();
        Test.stopTest();
    }
}