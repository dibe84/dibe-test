/**
 * Schedualable to run Adx import
 *  - Type Metric
 *  - SobjectType Metric(Metric__c)
 */
global class SchAdxImportMetrics implements Schedulable{
	 global void execute(SchedulableContext sc) {
        DeliveryController.start(DeliveryController.SCH_TYPE_DAILY, DeliveryController.SOBJECT_METRIC, DeliveryController.ADX_IMPORT);
    }
    
    global static void start(){
        SchAdxImportMetrics s = new SchAdxImportMetrics();
        String sch = '0 0 12 * * ?'; // '0 0 12 * * ?' == every day @12:00 Should consider Time Zone's for specific site... (AU = +10h)
        String jobID;
        if (!Test.IsRunningTest() ) jobID = system.schedule('SchAdxImportMetrics', sch, s);
        else                        jobID = system.schedule('SchAdxImportMetrics TEST', sch, s); // running test
    }
}