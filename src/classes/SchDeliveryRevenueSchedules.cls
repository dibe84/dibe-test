/**
 * Schedualable to run Delivery import
 *  - Type Monthly
 *  - SobjectType Revenue Items(Rev__c)
 */
global class SchDeliveryRevenueSchedules implements Schedulable{
    global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_MONTHLY, DeliveryController.SOBJECT_REVENUE_ITEM);
    }
    
    global static void start(){
        SchDeliveryRevenueSchedules s = new SchDeliveryRevenueSchedules();
        String sch = '0 0 * * * ?'; // '0 0 * * * ?' == every hour
        String jobID;
        if (!Test.IsRunningTest() ) jobID = system.schedule('SchDeliveryRevenueSchedules', sch, s);
        else                        jobID = system.schedule('SchDeliveryRevenueSchedules TEST', sch, s); // running test
    }
    
    static testMethod void testSch()
    {
        Test.startTest();
        start();
        Test.stopTest();
    }
}