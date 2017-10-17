public with sharing class Q_CreateDirectDebitPaymentMethod implements System.Queueable , Database.AllowsCallouts {

    private Id accountId;
    private Id agreementId;

    public Q_CreateDirectDebitPaymentMethod( Id accountId , Id agreementId ) {
    	this.accountId = accountId;
    	this.agreementId = agreementId;
    }

    public void execute(QueueableContext qc) {

        UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.RecurringPaymentCreate');
        req.init( accountId );

        echosign_dev1__SIGN_Agreement__c agm = (echosign_dev1__SIGN_Agreement__c) UTIL.getCached( agreementId );
        Map<String, String> cardMapper = new Map<String, String>{   
                                                'payment_method_type' => 'sepa-dd-em', 
                                                'iban' => agm.Bank_AccountNumber__c, 
                                                'mandate_id' => agm.Mandate_Id__c, 
                                                'mandate_signature_date' => agm.echosign_dev1__DateSigned__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''), 
                                                'owner_name' => agm.Bank_Account_Holder_Name__c,
                                                'auto_payment' => 'true'
                                            };
        req.mapper.mappingElements = WSC_Tract.getMapper_RecurringPaymentCreate(cardMapper);
        try {
            UTIL_WSC.WSC_Result res = req.call();
        } catch (Exception e) {
            System.debug('createDirectDebitPaymentMethod error ' + e.getMessage());
        }
    }
}