public with sharing class GW_Agreement {

    private static final Schema.sObjectType GW_BASEOBJECT = echosign_dev1__SIGN_Agreement__c.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'echosign_dev1__SIGN_Agreement__c';
    
    public static Set<String> activeAgreementStati  = new Set<String>{'Draft','Out for Signature','Waiting for Counter-Signature','Signed'};
    public static final String TRANSITION_CREATION  = 'CREATION';
    public static final String TRANSITION_DISPATCH  = 'DISPATCH';
    public static final String TRANSITION_SIGNING   = 'SIGNING';
    public static final String TRANSITION_CANCELLED = 'CANCELLED';
    public static final String TRANSITION_EXPIRED   = 'EXPIRED';
    public static final String TRANSITION_DELETION  = 'DELETION';

    private static final Integer SIGN_AGREEMENT_NAME_MAX_SIZE = 80;

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // public query methods
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    public static echosign_dev1__SIGN_Agreement__c           getRecord(Id id)                                       { return (echosign_dev1__SIGN_Agreement__c) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,echosign_dev1__SIGN_Agreement__c>   getMap(Set<id> ids)                                    { return new Map<id,echosign_dev1__SIGN_Agreement__c>( getList(ids) ); }
    public static List<echosign_dev1__SIGN_Agreement__c>     getList(Set<id> ids)                                   { return (List<echosign_dev1__SIGN_Agreement__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }
    //To get related Pending Mandate 
    public static List<echosign_dev1__SIGN_Agreement__c>     getRelatedMandate(String sObjType, String whereClause, Set<String> soNames)        { return (List<echosign_dev1__SIGN_Agreement__c>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, 'echosign_dev1__Account__c', soNames); }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    public static String getLocale(String language) {
        //default
        String locale = 'English (United States)';

        if ('NL'.equals(language)){
            locale = 'Dutch (Netherlands)' ;
        }
        else if ('FR'.equals(language)){
            locale = 'French (France)' ;
        }
        else if ('IT'.equals(language)){
            locale = 'Italian (Italy)' ;
        }
        else if ('DE'.equals(language)){
            locale = 'German (Germany)';
        }
        else if ('DA'.equals(language)){
            locale = 'Danish (Denmark)';
        }

        return locale;
    }

    public static String formatName(String name){
        if (name.length() > SIGN_AGREEMENT_NAME_MAX_SIZE) {
            name = name.substring (0, SIGN_AGREEMENT_NAME_MAX_SIZE);
        }
        return name;
    }

     /////////////////////////////////////////////////////////////////
     //
     // Atach IO to Agreement
     //
     /////////////////////////////////////////////////////////////////
    public static Attachment attachIO(echosign_dev1__SIGN_Agreement__c agreement, MemberUnit__c memberUnit, Opportunity opp, Boolean discountSet) {

        PriceBook2 pb = (PriceBook2) UTIL.getCached(opp.Pricebook2Id);
        Member__c member = (Member__c) UTIL.getCached(memberUnit.Member__c);

        String language = (opp != null) ? opp.Language_Preference__c : '';

        UTIL_Customizer customizer = new UTIL_Customizer(member, memberUnit, opp, language);

        PageReference IOPdf = customizer.getVFTemplate('IO');

        IOPdf.getParameters().put('id', (String)opp.id);
        IOPdf.getParameters().put('isDiscountSet', (discountSet ?'true':'false') ) ;
        IOPdf.setRedirect(true);
        Blob b = null;

        if (Test.IsRunningTest()) {
            b = Blob.valueof('test pdf contents');
        } else {
            b = IOPdf.getContent();
        }

        // insert IO attachment
        Attachment attachment = new Attachment();
        attachment.Description = 'Attachment created from opportunity through VF';
        attachment.ParentId = agreement.id;
        attachment.Body = b;
        attachment.Name = customizer.getLabel('IOName', opp) + '.pdf';
        insert attachment;
        return attachment;
    }

    /////////////////////////////////////////////////////////////////
     //
     // Atach Mandate to Agreement
     //
     /////////////////////////////////////////////////////////////////
    public static Attachment attachMandate( echosign_dev1__SIGN_Agreement__c agreement, MemberUnit__c memberUnit){

        UTIL_Customizer customizer = new UTIL_Customizer(null, memberUnit, null, agreement.AccountLanguagePreference__c);

        PageReference pdf = customizer.getVFTemplate('Mandate');

        pdf.getParameters().put('id',(String)agreement.id);
        pdf.setRedirect(true);

        Blob b = null;
        if ( Test.IsRunningTest() )
            b = Blob.valueof('test pdf contents');
        else {
            b = pdf.getContent();
        }

        // insert Mandate attachment
        Attachment attachment = new Attachment();
        attachment.Description = 'Attachment created from Account through VF';
        attachment.ParentId = agreement.id;
        attachment.Body = b;
        attachment.Name = customizer.getLabel('MandateSubject', agreement) + '.pdf';
        insert attachment;
        return attachment;
    }

    /////////////////////////////////////////////////////////////////
     //
     // Atach Terms and Conditions to Agreement
     //
     /////////////////////////////////////////////////////////////////
    public static Attachment attachTAndC(echosign_dev1__SIGN_Agreement__c agreement, MemberUnit__c memberUnit, Opportunity opp, String languagePreference) {

        Attachment attachment = null; 
        try {
            UTIL_Customizer customizer = new UTIL_Customizer(null, memberUnit, opp, languagePreference);
            UTIL_Customizer.VersionedDocumentItem versionedDocItem = customizer.getVersionedDocument('SalesTermsAndConditions', Date.today());

            attachment = new Attachment();
            attachment.Description = versionedDocItem.doc.Description;
            attachment.ParentId = agreement.id;
            attachment.Body = versionedDocItem.doc.Body;
            attachment.Name = versionedDocItem.doc.Name;
            insert attachment;

            agreement.IOTermsAndConditionsVersion__c = versionedDocItem.docVersion.Id;
            update agreement;
                        
        } catch (Exception e) {
            UTIL.log('No SalesTermsAndConditions to be added.');
        }
        return attachment;
    }    

    /////////////////////////////////
    //      Create Agreemement 
    ////////////////////////////////
    public static echosign_dev1__SIGN_Agreement__c createAgreement(String accounId, String oppId, String agrType) {
        echosign_dev1__SIGN_Agreement__c agm = new echosign_dev1__SIGN_Agreement__c();
        agm.Name = 'AGM - '+System.now().format('dd-mm-yy');
        agm.echosign_dev1__Account__c = accounId;
        agm.echosign_dev1__Opportunity__c = oppId;
        agm.Type__c = agrType;
        agm.Billing_Preference__c = accounId;
        
        return agm;
    }

    /////////////////////////////////
    //      Send Agreement
    ////////////////////////////////
    /**
    *   @description This method sends an agreement to the recipient specified.
    *   @param agreement
    *   @return returns true when the agreement has been sent successfully, else it send false 
    */
    public static Boolean sendAgreement( Id agreementIdToBeSent ){
        Boolean hasSent = false;
        
        if ( agreementIdToBeSent == null ) return hasSent;

        // send the agreement
        try{
            
            echosign_dev1.EchoSignApiService.SendDocumentResult result = echosign_dev1.EchoSignApiService.sendDocument(agreementIdToBeSent);
            UTIL.log('Document Key: ' + result.documentKey );
            UTIL.log('Error: ' + result.error );
            UTIL.log('URL:  ' + result.url );
            hasSent = true; 

        } catch (Exception ex){
            UTIL.log('Error: Agreement not sent ' + ex.getMessage());
            return hasSent;            
        }

        return hasSent;
    }
    
    public static String getTransition( String newStatus , String oldStatus ){
        
        String transition = null;
        if( oldStatus != 'Signed' && newStatus == 'Signed' ){
            transition = TRANSITION_SIGNING;
        } else if( oldStatus != 'Out for Signature' && newStatus == 'Out for Signature' ){
            transition = TRANSITION_DISPATCH;
        } else if( oldStatus != 'Cancelled / Declined' && newStatus == 'Cancelled / Declined' ){
            transition = TRANSITION_CANCELLED;
        } else if( oldStatus != 'Expired' && newStatus == 'Expired' ){
            transition = TRANSITION_EXPIRED;
        }
        return transition;
    }
    
    public static Boolean isMandateRequired( echosign_dev1__SIGN_Agreement__c agm ){
        
        Boolean isMandateRequired = false;
        
        // If there is no opportunity then it means it comes from a Mandate Request
        if( agm.echosign_dev1__Opportunity__c == null ){
            isMandateRequired = true; 
        } else {
            Account billingAcc = (Account) UTIL.getCached( agm.echosign_dev1__Account__c );
            Opportunity opp = (Opportunity) UTIL.getCached( agm.echosign_dev1__Opportunity__c );
            // Checks if the Opportunity is from a Member Unit subscribed to TRACT
            if( UTIL_WSC_Subscription.isSubscribedToTRACT( opp ) ){
                if( agm.Type__c == 'IO' && opp.Include_SEPA_mandate__c ){
                    isMandateRequired = true;
                }
            } else if( 'Direct Debit'.equalsIgnoreCase( billingAcc.Billing_Preference__c ) 
                       && ( billingAcc.Mandate__c == null || 'Failed'.equalsIgnoreCase( agm.Mandate_Status__c ) ) ){
                isMandateRequired = true;           
            }
        }       
        return isMandateRequired;
    }
}