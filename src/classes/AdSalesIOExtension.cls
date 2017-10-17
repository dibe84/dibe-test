/**
 * Controller extension for the AdSales IO contract page
 * 
 * @author  Jochem van den Heuvel
 * @date    Sep 2014
 */
public with sharing class AdSalesIOExtension {

    private Opportunity opp;
    private List <opportunityLineItem> oppLines;

    public boolean isDiscountSet {get;set;}
    public Set<String> availableEmails {get;set;}

    public MemberUnit__c memberUnit {
        get { return GW_MemberUnit.getMemberUnitById(opp.MemberUnit__c); }
        private set;
    }

    public String memberUnitId {
        get { return memberUnit.MemberUnitId__c; }
        private set;
    }

    public AdSalesIOExtension(ApexPages.StandardController stdController) {
        this.opp = (Opportunity)stdController.getRecord();
        this.opp = [Select Id, Name, Account.Member__r.MemberId__c, MemberUnit__c, IOnumber__c, IndirectDiscount__c, TotalAmountBeforeID__c,VatAmount__c,
            TotalAmountGross__c, Primary_Contact__c, Primary_Contact__r.FirstName, Account.OwnerId, Owner.Firstname, Owner.LastName, 
            Owner.Phone, Owner.Email, StageName, IsWon, IsClosed, CloseDate, Amount, AccountId, Account.Name, RecordTypeId    
            from Opportunity where Id = :opp.Id];
        
        loadLines();
        
        if( this.opp.Account.Member__r.MemberId__c == 'EBAYK' ){
            prepareLines();   
        }
        
        String isDiscountSetString = Apexpages.currentPage().getParameters().get('isDiscountSet');
        isDiscountSet = ( isDiscountSetString == null || 'false'.equals(isDiscountSetString)) ? false : true;
    }

    public Account getmemberAcc(){
        Account acc;
        if(opp.AccountId != null){
            Account parent = (Account) UTIL.getCached(opp.AccountId);
            if(parent.Member__c != null){
                Member__c mem = (Member__c) UTIL.getCached(parent.Member__c);
                if(mem.Account__c != null)
                    acc = (Account) UTIL.getCached(mem.Account__c);
            }
        }
        return acc;
    }


    private void loadLines() {
    
        this.oppLines = [ SELECT PriceBookEntry.Product2.Name, 
        AdOpsComments__c,
        from_Date__c,
        until_Date__c,
        Billing_Category__c,
        Quantity,
        Unitprice,
        ListPrice__c,
        ListPriceCorrectionForm__c,
        ListPriceCorrectionPercentage__c,
        SalesPriceBeforeID__c,
        SalesPriceNet__c,
        TotalAmountGross__c, 
        TotalAmountBeforeID__c,
        IndirectDiscount__c, 
        TotalAmountNet__c,
        Description,
        DefaultLineDescription__c,
        PriceBookEntry.Product2.Description,
        PriceBookEntry.Product2.Product_SubType__c,
        PriceBookEntry.Product2.Advertising_Medium__r.Dart_AdSlotSize__c,
        PriceBookEntry.Product2.Advertising_Medium__r.Max_file_size__c,
        PriceBookEntry.Product2.Advertising_Medium__r.File_type__c,
        PriceBookEntry.Product2.Advertising_Medium__r.File_type_version__c,
        PriceBookEntry.Product2.Advertising_Medium__r.Notes__c,
        PriceBookEntry.Product2.Advertising_Medium__r.name,
        PriceBookEntry.Product2.Site__r.Name,
        BundleSize__c      
        FROM OpportunityLineItem 
        WHERE OpportunityId =:this.opp.Id
        ORDER BY from_Date__c ASC];  
    }


    /**
     * Description
     * 
     * @author    -
     * @param   none
     * @return  sorted list of opportunityLineItems  
     */
    public List <opportunityLineItem> getsortrecord() {
        return this.oppLines;  
    }
    
    
    private void prepareLines(){
        
        String productDesc;
        availableEmails = new Set<String>();
        for( OpportunityLineItem oppLine : oppLines ){
            
            productDesc = oppLine.PriceBookEntry.Product2.Description;
            if( String.isNotBlank( productDesc ) ){
                oppLine.PriceBookEntry.Product2.Description = productDesc.replaceAll('\\r\\n', '<br/>');
            }    
            
            System.debug( oppLine.PriceBookEntry.Product2.Product_SubType__c );
            if( oppLine.PriceBookEntry.Product2.Product_SubType__c == 'PRO' ){
                availableEmails.add('pro@ebay-kleinanzeigen.de');
            } else if( oppLine.PriceBookEntry.Product2.Product_SubType__c == 'RE' ){
                availableEmails.add('immobilien@ebay-kleinanzeigen.de');
            }
        }
        
        if( availableEmails.isEmpty() ){
            availableEmails.add('immobilien@ebay-kleinanzeigen.de');
        }   
    }

}