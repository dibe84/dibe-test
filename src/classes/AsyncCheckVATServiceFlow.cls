public class AsyncCheckVATServiceFlow implements Queueable, Database.AllowsCallouts {
	
	private String oppId;

	public AsyncCheckVATServiceFlow ( String oppId ) {
		this.oppId = oppId;
	}

	public void execute(QueueableContext context) {

		Opportunity opp = GW_Opportunity.getRecord(oppId);
        Account acc = GW_Account.getRecord(opp.AccountId);

		if ( GW_Account.isVIESValidationApplicable( acc ) ) {

	        UTIL_WSC.WSC_Request req;
	        UTIL_WSC.WSC_Result res;
	        req = UTIL_WSC.getWSC_Request('WSC_VIES.Query');
	        req.init(acc.Id);
	        res = req.call();
	        if (res.statusCode == 200 || res.statusCode == 201) {
	            
	            System.enqueueJob( new AsyncAccCreateTractFlow(oppId) );

	        } else {
	           Map<String, Object> response = (Map<String, Object>) res.getResponseData().get('results');
	        }
		} else {

			System.enqueueJob( new AsyncAccCreateTractFlow(oppId) );

		}

	}
}