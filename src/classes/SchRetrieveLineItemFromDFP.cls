/**
 *@created 16-06-2015
 *@autor: Chr
 *@desc: Scheudule to run bach BatchRetrieveLineItemValFromDFPToSF to retrieve some lineItem's fields from DFP and update to SF
 */
global class SchRetrieveLineItemFromDFP implements Schedulable{
	global void execute(SchedulableContext sc) {
    	BatchRetrieveLineItemFromDFP bt = new BatchRetrieveLineItemFromDFP();
		Database.executeBatch(bt,1);
    }
    
    global static void start(){
        SchRetrieveLineItemFromDFP s = new SchRetrieveLineItemFromDFP();
        String sch = '0 0 12 * * ?'; // '0 0 12 * * ?' == every day @12:00 Should consider Time Zone's for specific site... (AU = +10h)
        String jobID;
        if (!Test.IsRunningTest() ) jobID = system.schedule('SchRetrieveLineItemFromDFP', sch, s);
        else                        jobID = system.schedule('SchRetrieveLineItemFromDFP TEST', sch, s); // running test
    }
}