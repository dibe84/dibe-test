public class LCC_ProductConfigurator {
    
    public static Boolean isCalled = false;

    @Auraenabled
    public static RemoteResponse getSelectedAndMostRecentOpportunities(String oppId) {
        try{
            List<Opportunity> selectedAndMostrecentOpportunities = new List<Opportunity>();
            List<String> additionalFields = new List<String>{'Account.Name'};

            
            if (!String.isEmpty(oppId)){
                
                 Opportunity selectedOpportunity = GW_Opportunity.getRecord(oppId, additionalFields);
            
                    if (selectedOpportunity.PriceBook2Id == null && selectedOpportunity.MemberUnit__c != null){
                        List<Pricebook2> pricebooks = [SELECT Id FROM PriceBook2 WHERE MemberUnit__c =: selectedOpportunity.MemberUnit__c];
                        if (pricebooks != null && !pricebooks.isEmpty()){
                            selectedOpportunity.PriceBook2Id = pricebooks[0].Id;
                            update selectedOpportunity;
                        }
                    }
            
                selectedAndMostrecentOpportunities.add(selectedOpportunity);
                selectedAndMostrecentOpportunities.addAll(GW_Opportunity.getList('Name <> null AND Id <> \''+selectedOpportunity.Id+'\' ORDER BY LastModifiedDate DESC LIMIT 10', additionalFields));
            }
            else{
            	selectedAndMostrecentOpportunities.addAll(GW_Opportunity.getList('Name <> null ORDER BY LastModifiedDate DESC LIMIT 10', additionalFields));   
            }

            RemoteResponse response = new RemoteResponse();
            response.content = selectedAndMostrecentOpportunities;
            response.statusCode = STATUSCODE_OK;

            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getMessage(), STATUSCODE_ERROR);
        }
    }
    
    @auraenabled
    public static List<OpportunityLineItem> getOpportunityLineItems(String oppId) {
        //return GW_OpportunityLineItem.getListFromRelated(new Set<Id>{oppId});    
        List<OpportunityLineItem> olis = [Select Id,  OpportunityId,  PricebookEntryId,  Product2Id,  ProductCode,  Name,  
                Quantity,  Description,  Ad_Id__c,  Ad_Name__c,  Adserver_ID_Order_ID__c, BillingCalc__c,  
                Billing_Category__c,  Discount__c,  SalesPriceNet__c,  TotalAmountNet__c,  from_Date__c,  until_Date__c,  
                Budget_NetNetNet__c,  IndirectDiscountAmount__c,  IndirectDiscount__c, UPCF__c, NumStatus__c,  Status__c,  
                LineOfBusiness__c,  DefaultLineDescription__c,  ListPrice__c,  BundleSize__c,  PricebookEntry.Product2.Name, 
                PricebookEntry.Product2.Billing_Category__c, AdOpsComments__c, Rebate_In_Kind_Reason__c, SalesPriceBeforeID__c, TotalAmountBeforeID__c From OpportunityLineItem Where OpportunityId =: oppId];
        UTIL.log('Lightning request: '+olis);
        return olis;
    }
    
    @AuraEnabled
    public static RemoteResponse saveOpportunityLineItem(OpportunityLineItem oli) {
        try{
            LCC_ProductConfigurator.isCalled = true;
        
            Opportunity opp = [SELECT Id FROM Opportunity WHERE id=:oli.OpportunityId LIMIT 1 FOR UPDATE];
            
            // Bunhor @10-Dec-15: W-000129: creating default Targetings
            GW_OpportunityLineItem.configureDFPTargeting(new List<OpportunityLineItem>{oli});
            
            upsert oli;
            return new RemoteResponse(oli);
        }
        catch (System.DmlException dmle){
            return new RemoteResponse(dmle.getMessage(), STATUSCODE_FATAL);
        }
        catch (Exception e) {
            return new RemoteResponse(e.getMessage(), STATUSCODE_ERROR);
        }
        
    }
    
    @AuraEnabled
    public static RemoteResponse applyPriceModel(OpportunityLineItem oli) {
        try{
            PriceCalculator.applyPriceModel(oli);
            
            RemoteResponse response = new RemoteResponse();
            response.content = oli;
            response.statusCode = STATUSCODE_OK;

            return response;
        }
        catch(Exception e){
            return new RemoteResponse(e.getMessage(), STATUSCODE_ERROR);  
        }
        
    }
    
    @AuraEnabled
    public static RemoteResponse deleteOpportunityLineItem(OpportunityLineItem oli) {
        // Perform isDeletable() check here 
        try{
            delete oli;
            
            RemoteResponse response = new RemoteResponse();
            response.content = oli;
            response.statusCode = STATUSCODE_OK;

            return response;
        }
        catch(System.DMLException dmle){
            return new RemoteResponse('Unable to delete line in status: '+oli.Status__c, STATUSCODE_ERROR);
        }
        catch(Exception e){
            return new RemoteResponse('Unable to delete line: '+e.getMessage(), STATUSCODE_ERROR); 
        }
    }
    
    @AuraEnabled
    public static RemoteResponse getNewOpportunityLineItem(Id oppId, Id pbeId) { 
        try{
            PricebookEntry pbe = (PricebookEntry) GW_sObject.queryRecord('PricebookEntry', pbeId);
            Opportunity opp = (Opportunity) GW_sObject.queryRecord('Opportunity', oppId);
            List<sObject> content = new List<sObject>();
            
            OpportunityLineItem oli = GW_OpportunityLineItem.createSObject(opp, pbe, null, 10);
            
            content.add(oli);
            content.add(opp);
            
            return new RemoteResponse(content);
        }
        catch (Exception e) {
            return new RemoteResponse('Unable to add line: '+e.getMessage()+e.getStackTraceString(), STATUSCODE_ERROR); 
        }
        
    }
    
    @AuraEnabled
    public static RemoteResponse copyOpportunityLineItem(OpportunityLineItem oli) {

        try{
            Id oppId = oli.OpportunityId;
            Id pbeId = oli.pricebookEntryId;
            
            PricebookEntry pbe = (PricebookEntry) GW_sObject.queryRecord('PricebookEntry', pbeId);
            Opportunity opp = (Opportunity) GW_sObject.queryRecord('Opportunity', oppId);
            
            OpportunityLineItem copy = GW_OpportunityLineItem.createSObject(opp, pbe, null, 10);
            
            copy.Quantity = oli.Quantity; 
            copy.from_Date__c = oli.from_Date__c; 
            copy.until_Date__c = oli.until_Date__c; 
            copy.Description = oli.Description; 
            copy.SalesPriceNet__c = oli.SalesPriceNet__c; 
            copy.Billing_Category__c = oli.Billing_Category__c; 
            copy.BillingCalc__c = oli.BillingCalc__c; 
            copy.AdOpsComments__c = oli.AdOpsComments__c; 
            copy.Rebate_In_Kind_Reason__c = oli.Rebate_In_Kind_Reason__c; 
            copy.ListPrice__c = oli.ListPrice__c;
            
            PriceCalculator.applyPriceModel(copy);
            
            Decimal partnerShare = opp.IndirectDiscount__c == null ? 0 : opp.IndirectDiscount__c;
       		Decimal ebayShare = 100 - partnerShare;

            //copy.SalesPriceNet__c = copy.ListPrice__c*(ebayShare/100);
            //copy.UnitPrice = copy.ListPrice__c;
            
            if (oli.SalesPriceNet__c != null) {
                copy.SalesPriceNet__c = oli.SalesPriceNet__c;
            }
            else{
                copy.SalesPriceNet__c = copy.ListPrice__c*(ebayShare/100);
            }
            //copy.SalesPriceNet__c = 500;
            copy.UnitPrice = copy.SalesPriceNet__c;
            
            return new RemoteResponse(copy);
        }
        catch (Exception e){
            return new RemoteResponse(e.getMessage(), STATUSCODE_ERROR);
        }
        
    }
    
    @AuraEnabled
    public static List<PricebookEntry> getProducts(Id pricebookId) {
        return
        [   SELECT  Id,  Name,  Product2Id,  UnitPrice,  IsActive,  ProductCode, Product2.FilterCategory1__c, Product2.FilterCategory2__c, Product2.FilterCategory3__c,
            Product2.Name, Product2.Description, Product2.Device_Category__c, Product2.Billing_Category__c, Product2.CPM_Price__c,
            Product2.CPD_Price__c, Product2.CPC_Price__c, Product2.Product_Type__c, Product2.Product_SubType__c
            FROM PricebookEntry
            WHERE IsActive=true AND Pricebook2Id=:pricebookId
            LIMIT 10000
        ];
    }  
    
    ////////////////////////////////// response object ///////////////////////////////////////////
    // Error codes  
    public static final integer STATUSCODE_OK = 0;
    public static final integer STATUSCODE_ERROR = 1;
    public static final integer STATUSCODE_WARNING = 2;
    public static final integer STATUSCODE_FATAL = 3;
    
    
    public class RemoteResponse 
    {
        @AuraEnabled
        public integer statusCode = STATUSCODE_OK; // ==> 0 = ok, 1 = ERROR, 2 = succes, but... (with warning message)
        @AuraEnabled
        public String message = ''; // message for display to user
        @AuraEnabled
        public Object content; 
        
        public  RemoteResponse() { 
            content = 0; 
            message = 'Default message';    
        }
        
        public RemoteResponse(String msg, integer status)
        {
            this.message = msg;
            this.statusCode = status; 
            UTIL.log('Remote call returned an error: ' + this.statusCode + ' (' + this.message + ')'); 
        }
        
        public RemoteResponse (Object content)
        {
            this.content = content;
        }

    }
    
}