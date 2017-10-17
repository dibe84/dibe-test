public with sharing class Q_SyncAgreementStatus implements System.Queueable {

    private Set<Id> syncAggsIds = new Set<Id>();

    public Q_SyncAgreementStatus( Set<Id> syncAggsIds ) {
        this.syncAggsIds = syncAggsIds;
    }

    public void execute(QueueableContext qc) {

        List<echosign_dev1__SIGN_Agreement__c> aggsToSync;
        try {
            aggsToSync = GW_Agreement.getList( syncAggsIds );
            update aggsToSync;
        } catch(Exception ex) {
            UTIL.throwError('Q_SyncAgreementStatus: ',ex);
        } 
    }
}