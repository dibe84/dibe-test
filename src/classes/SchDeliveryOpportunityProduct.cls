/**
 * Schedualable to run Delivery import
 *  - Type Dialy
 *  - SobjectType OpportunityProduct
 */
global class SchDeliveryOpportunityProduct implements Schedulable{
    global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_OPPPRODUCT);
    }
    
    global static void start(){
        SchDeliveryOpportunityProduct s = new SchDeliveryOpportunityProduct();
        String sch = '0 0 * * * ?'; // '0 0 * * * ?' == every hour
        String jobID;
        if (!Test.IsRunningTest() ) jobID = system.schedule('SchDeliveryOpportunityProduct', sch, s);
        else                        jobID = system.schedule('SchDeliveryOpportunityProduct TEST', sch, s); // running test
    }
    
    static testMethod void testSch()
    {
        Test.startTest();
        start();
        Test.stopTest();
    }
}