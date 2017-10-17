global class BAT_LostOpportunityAfterDays implements Database.Batchable<sObject>, Database.AllowsCallouts, UTIL_CustomJob.ICustomJob, Database.Stateful {

    global Datetime executeStart;
    global List<Invoice__c> invsInput;
    global final String query;
    global String output = '';

    private String relName;

    global BAT_LostOpportunityAfterDays(){
        
        UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('BAT_LostOpportunityAfterDays');
        Map<String,String> childRelationshipsMap;
        childRelationshipsMap = GW_sObject.getChildRelationshipsMap( 'Opportunity' , 'echosign_dev1__SIGN_Agreement__c' );
        relName = childRelationshipsMap.get( 'echosign_dev1__Opportunity__c' );

        String preQuery = 'SELECT Id , StageName, ( SELECT CreatedDate, StageName FROM OpportunityHistories ORDER BY CreatedDate DESC ) FROM Opportunity';
        query = preQuery + ' WHERE ' + jobDef.setting.WhereClause__c;
                    
        output = '';
        ReadyForRun = true;
    }

    global Database.QueryLocator start( Database.BatchableContext BC ) {
        return Database.getQueryLocator( query );
    }

    global void execute( Database.BatchableContext BC , List<sObject> scope ) {

        this.numRecords = scope.size();

        List<Opportunity> opps = ( List<Opportunity> ) scope;
        List<Opportunity> updOpps = new List<Opportunity>();
        OpportunityHistory oppHist;

        // Prepares the threshold timestamp for the last Stage change of the opportunity
        String maxStatInactDaysStr = UTIL.getConfig('OppLostMaxStatusInactivityInDays');
        Integer maxStatInactDays = maxStatInactDaysStr == null ? 60 : Integer.valueOf( maxStatInactDaysStr ); 
        Datetime thresholdTS = System.now().addDays( -1 * maxStatInactDays );
         
        for( Opportunity opp : opps ) {
            
            if( opp.OpportunityHistories.size() > 0 ){
            
                oppHist = opp.OpportunityHistories[0];
                
                // Checks if the Opportunity is stuck in a lesser Stage for longer then X days 
                if( ( opp.StageName == oppHist.StageName ) && ( oppHist.CreatedDate < thresholdTS ) ){

                    // Sets the opportunity as Lost
                    opp.LostReason__c = 'Opportunity expired';
                    opp.SyncChildStatus__c = true;
                    updOpps.add( opp );
                } 
            }    
        }

        Savepoint sp = Database.setSavepoint();
        try {
            update updOpps;
        } catch(Exception ex) {
            Database.rollback(sp);
            UTIL.throwError('BAT_LostOpportunityAfterDays: Error updating Opps: ',ex);
        } 
    }

    global void finish(Database.BatchableContext BC) {
        UTIL_CustomJob.updateJobExecuteStartTime(BC.getJobId(), executeStart);
        UTIL_CustomJob.markJobFinished('BAT_LostOpportunityAfterDays', BC.getJobId());
    }

    // interface implementation
    private Boolean readyForRun = true;
    private Integer numRecords = 0;
    global Boolean readyForRun() { return this.readyForRun; }
    global integer getNumRecords() { return this.numRecords; }
}