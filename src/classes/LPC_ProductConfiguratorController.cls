/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description:
 *  - Adding Products to List
 *  - Products List Modification
 * @references:
 *  - LPC_MainWindow lightning component
 * @changeLog:
 *
 */
public without sharing class LPC_ProductConfiguratorController {
	public static final String ALREADY_INVOICED_REV_ERROR = 'Revenue already invoiced, you are not allowed to change the revenue numbers';
    public static final Set<String> OPP_STAGENAME = new Set<String>{'Signed', 'Scheduled', 'Running', 'Finished'};
    public static final List<String> OPPITEM_ADDITIONALFIELDS = new List<String>{
        'PricebookEntry.Product2.Name',
        'PricebookEntry.Product2.AdServer_Keywords_Key_Values__c',
        'PricebookEntry.Product2.RecordType.Name',
        'PricebookEntry.Product2.Site__r.Country__c',
        'PricebookEntry.Product2.OperatingSystem__c',
        'PricebookEntry.Product2.Geo_IP__c',
        'PricebookEntry.Product2.FC__c',
        'PricebookEntry.Product2.Content__c',
        'PricebookEntry.Product2.Connection__c',
        'PricebookEntry.Product2.Device__c',
        'PricebookEntry.Product2.Browser__c',
        'PricebookEntry.Product2.Bandwidth__c',
        'PricebookEntry.Product2.Keywords__c',
        'PricebookEntry.Product2.Billing_Category__c',
        'PricebookEntry.Product2.PredifinedAdunit__r.DartName__c',
        'PricebookEntry.Product2.Time__c',
        'Predefined_Adunit__r.DartName__c',
        'PricebookEntry.Product2.RecordType.Name',
        'PricebookEntry.Product2.Rate_Card__c',
        'PricebookEntry.Product2.Tract_ProductType__c',
        'Opportunity.Account.AccountDiscount__c'
    },
    PBE_ADDITIONAL_FIELDS = new List<String>{
                                            'Product2.Name',
                                            'Product2.Placement__c', 
                                            'Product2.Billing_Category__c', 
                                            'Product2.AdServer_Keywords_Key_Values__c',
                                            'Product2.PredifinedAdunit__c', 
                                            'Product2.Device_Category__c', 
                                            'Product2.Advertising_Medium__r.FC_Quantity__c',
                                            'Product2.Advertising_Medium__c', 
                                            'Product2.Advertising_Medium__r.FC_Period__c', 
                                            'Product2.Advertising_Medium__r.FC_Ad_served_every__c'
                                        };

    @AuraEnabled
    public static List<OpportunityLineItem> updateLineItems(string lineItems){
        List<OpportunityLineItem> lstOppLineItem = (List<OpportunityLineItem>)System.JSON.deserialize(lineItems, List<OpportunityLineItem>.class);
        for(OpportunityLineItem oppli: lstOppLineItem){
            //follow GW_OpportunityLineItem.css line 52 until_Date__c = startDate.addMonths(1)
            Boolean isTrialPro = (String.isNotBlank(oppli.Product2.Name) && oppli.Product2.Name.containsIgnoreCase(TRIAL));
            if(!oppli.SetEndDate__c) oppli.until_Date__c = oppli.from_date__c.addMonths(1);
            if(isTrialPro) oppli.until_Date__c = oppli.from_date__c.addDays(-1);
        }
        update lstOppLineItem;
        return lstOppLineItem;
    }

    @AuraEnabled
    public static Decimal getAccountDiscount(String oppId, String accountId) {
        List<String> additionalFields = new List<String>();
        if(!String.isEmpty(oppId)){
            Opportunity opp = new Opportunity();
            additionalFields.add('Account.AccountDiscount__c');
            opp = (Opportunity) GW_sObject.queryRecord('Opportunity', oppId, additionalFields);
            return opp.Account.AccountDiscount__c;
        }
        else if(!String.isEmpty(accountId)){
            Account acc = new Account();
            acc = (Account) GW_sObject.queryRecord('Account', accountId);
            return acc.AccountDiscount__c;
        }
        return NULL;
    }
    /**
     * Available discounts for product.
     * @param productId - id of product.
     * @return JSON string.
     */
     @AuraEnabled
    public static List<Map<String, Object>> getAvailableDiscounts(String lineItemId) {
        List<Map<String, Object>> discountsList = new List<Map<String, Object>>();
        OpportunityLineItem oppLineItem = (OpportunityLineItem) GW_sObject.queryRecord('OpportunityLineItem', lineItemId, new List<String>{'Opportunity.Pricebook2Id'});
        Product2 masterProduct = (Product2) GW_sObject.queryRecord('Product2', oppLineItem.Product2Id);


        //List<ProductDiscountRelation__c> discountsList = new List<ProductDiscountRelation__c>();
        for(ProductDiscountRelation__c item:[SELECT Id, Discount__c, Discount__r.Name, Discount__r.Amount__c, Discount__r.Percentage__c  FROM ProductDiscountRelation__c
                                            WHERE Product__c =:masterProduct.Parent__c
                                            AND  Discount__r.IsActive__c = TRUE]){
            //discountsList.add(item);

            discountsList.add(new Map<String, Object>{'Id' => item.Discount__c,
                                                    'Name' => item.Discount__r.Name,
                                                    'LineItemId' => lineItemId});
        }
        return discountsList;
    }
    /**
     * Available products(add-ons) for Master Product.
     * @param productId - id of master product.
     * @return JSON string.
     */
    @AuraEnabled
    public static List<Map<String, Object>> getAvailableProducts(List<String> productsTypes, String lineItemId) {
        List<Map<String, Object>> lstAddOnsPro = new List<Map<String, Object>>();
        OpportunityLineItem oppLineItem = (OpportunityLineItem) GW_sObject.queryRecord('OpportunityLineItem', lineItemId, new List<String>{'Opportunity.Pricebook2Id'});
        Product2 masterProduct = (Product2) GW_sObject.queryRecord('Product2', oppLineItem.Product2Id);


        Set<Id> childrenMasterProductsIds = new Set<Id>();
        for(ProductRelation__c item:[SELECT Id, Child__c FROM ProductRelation__c WHERE Parent__c =:masterProduct.Parent__c ]){
            childrenMasterProductsIds.add(item.Child__c);
        }

        for(PricebookEntry item:[SELECT CurrencyIsoCode, Product2.Name, Product2.Parent__c, Product2Id, UnitPrice, Pricebook2Id, Product2.Tract_PriceId__c, Product2.Tract_RecurrencePeriod__c
                                FROM  PricebookEntry
                                WHERE Pricebook2Id = :oppLineItem.Opportunity.Pricebook2Id
                                AND isActive = TRUE
                                AND Product2.IsActive = true 
                                AND Product2.Parent__c IN :childrenMasterProductsIds
                                AND ( Product2.Tract_RecurrencePeriod__c = :masterProduct.Tract_RecurrencePeriod__c OR Product2.Name LIKE '%[ONE-TIME]') 
                                AND Product2.Tract_ProductType__c IN :productsTypes])
                                {
                                    lstAddOnsPro.add(new Map<String, Object>{'Id' => item.Product2Id,
                                                                            'Name' => item.Product2.Name,
                                                                            'ListPrice' => item.UnitPrice,
                                                                            'CurrencyCode' => item.CurrencyIsoCode
                                                                            });
                                }
        return lstAddOnsPro;
    }
    
    @AuraEnabled
    public static RemoteResponse doSetFilterBillCycle(List<String> proTyps, String oppId){
        Opportunity opp = (Opportunity) UTIL.getCached(oppId);
        String pbid = opp.Pricebook2Id;
        List<Object> lstObjs = new List<Object>();
        lstObjs.add(new Map<String, Object>{'label' => 'None', 'value' => '', 'selected' => true});
        for(AggregateResult aggResult: [Select Product2.Tract_RecurrencePeriod__c billCycle
                                            From PriceBookEntry
                                            Where Pricebook2Id =:pbid 
                                                AND isActive = TRUE
                                                AND Product2.IsActive = true 
                                                AND CurrencyIsoCode =:opp.CurrencyIsoCode
                                                AND product2.Tract_ProductType__c IN :proTyps
                                                AND product2.Parent__c != NULL
                                            Group By Product2.Tract_RecurrencePeriod__c])
        {
            String billCycle = String.valueOf(aggResult.get('billCycle'));
            lstObjs.add(new Map<String, Object>{'label' => billCycle, 'value' => billCycle});
        }
         
        RemoteResponse response = new RemoteResponse();
        response.contents = lstObjs;
        response.statusCode = RemoteResponse.STATUSCODE_OK;
        return response;
    }
    
    /**
    * This method to all product without existed product in Opportunity
    * @param oppid  Opportunity Id
    */
    @AuraEnabled
    public static String getAllProducts(List<String> productsTypes, String oppId){

                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartArray();

                Opportunity opp = (Opportunity) GW_sObject.queryRecord('Opportunity', oppId);
                String pbid = opp.Pricebook2Id;

                List<OpportunityLineItem> lstExistedLineItems = getExistedOpli(oppId);
                Set<ID> existedProducts = new Set<ID>();
                for(OpportunityLineItem existedItem: lstExistedLineItems){
                    existedProducts.add(existedItem.Product2Id);
                }


                for(PriceBookEntry item : [SELECT id, Product2Id,product2.Name, Name, Pricebook2Id,UnitPrice, Product2.Tract_RecurrencePeriod__c, CurrencyIsoCode
                                        FROM PriceBookEntry
                                        WHERE Pricebook2Id =:pbid AND isActive = TRUE
                                        AND Product2.IsActive = true 
                                        AND CurrencyIsoCode =:opp.CurrencyIsoCode
                                        AND product2.Tract_ProductType__c IN :productsTypes
                                        AND product2.Parent__c != NULL
                ]){
                    if(!existedProducts.contains(item.Product2Id)){
                        gen.writeStartObject();
                            gen.writeStringField('Id', item.Product2Id);
                            gen.writeStringField('Name', item.product2.Name);
                            gen.writeNumberField('ListPrice', item.UnitPrice);
                            gen.writeStringField('CurrencyCode', item.CurrencyIsoCode);
                            gen.writeStringField('filter1', String.isBlank(item.Product2.Tract_RecurrencePeriod__c) ? '':item.Product2.Tract_RecurrencePeriod__c);
                        gen.writeEndObject();
                    }

                }
                gen.writeEndArray();
                gen.close();
                return  gen.getAsString();
    }

    /**
     * Availables opportunities for selection
     * @param oppId, opportunity Id
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse getSelectedAndMostRecentOpportunities(String oppId) {
        try{
            List<String> additionalFields = new List<String>{'Account.Name','Agency__r.Name','Billing_Account__r.Name','Owner.Name'};
            List<Opportunity> selectedAndMostrecentOpportunities = new List<Opportunity>();
            if (!String.isEmpty(oppId)){

                Opportunity selectedOpportunity = getOpportunityById(oppId);
                selectedAndMostrecentOpportunities.add(selectedOpportunity);
                selectedAndMostrecentOpportunities.addAll(GW_Opportunity.getList('Name <> null AND Id <> \''+selectedOpportunity.Id+'\' ORDER BY LastModifiedDate DESC LIMIT 10', additionalFields));
            }
            else{
                selectedAndMostrecentOpportunities.addAll(GW_Opportunity.getList('Name <> null ORDER BY LastModifiedDate DESC LIMIT 10', additionalFields));
            }

            RemoteResponse response = new RemoteResponse();
            response.content = selectedAndMostrecentOpportunities;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    /**
     * Check if doesn't exist PushTopic it will auto create the PushTopic
     * @param jsonPushTopic is a string JSON as list of PushTopic
     * @return RemoteResponse
     */
    static Map<String, PushTopic>mTopic = new Map<String, PushTopic>{
        'OpportunityUpdate' => new PushTopic(Name = 'OpportunityUpdate', Query = 'Select Id From Opportunity', ApiVersion = 37.0, NotifyForOperationUpdate = true, NotifyForFields = 'All'),
        'LineItemUpdate' => new PushTopic(Name = 'LineItemUpdate', Query = 'Select Id, Action__c, RecordId__c, SobjectType__c, ParentId__c From Streaming_Api_Support__c', ApiVersion = 37.0, NotifyForOperationCreate=true, NotifyForOperationUpdate=true, NotifyForFields = 'All')
    };
    @AuraEnabled
    public static RemoteResponse checkExistingTopic() {
        try{

            Map<String, PushTopic>mExistTopic = new Map<String, PushTopic>();
            for(PushTopic pt : [Select Id, Name, NotifyForOperationUpdate From PushTopic Where Name IN :mTopic.keySet()]){
                if(!mTopic.containsKey(pt.Name)) continue;

                PushTopic topic = mTopic.get(pt.Name);
                topic.Id = pt.Id;
            }

            upsert mTopic.values() Id;

            RemoteResponse response = new RemoteResponse();
            response.content = mTopic.values();
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    /**
     * Do query records from streaming api nitification catch
     * @param query, soql select query statement
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse getStreamingOppLineItems(String oppId) {
        try{
            Map<Id, OpportunityLineItem>mNewOli = new Map<Id, OpportunityLineItem>(getOpportunityLineItems(oppId));
            RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
                'oppLineList' => mNewOli.values(),
                'invOppLineList' => getInventoryList(oppId),
                'mapOliProduct' => mNewOli
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    /**
     * Availables products for assigning to Opportunity
     * @param oppId, opportunity Id
     * @return OpportunityLineItem List
     */
    @AuraEnabled
    public static List<OpportunityLineItem> getOpportunityLineItems(String oppId) {
        List<OpportunityLineItem> olis = (List<OpportunityLineItem>)GW_sObject.queryRecords('OpportunityLineItem', 'OpportunityId = \'' + oppId + '\'', OPPITEM_ADDITIONALFIELDS);
        return olis;
    }

    /**
    * Get Line Item that related Opportunity
    * @param oppId      Opportunity Id
    */
    @AuraEnabled
    public static List<OpportunityLineItem> getExistedOpli(String oppId){
        return getExistedOpli(oppId, null);
    }
    
    /**
    * Overloading getExistedOpli(string)
    * @param oppId      Opportunity Id
    * @param isOppSigned 
    */
    @AuraEnabled
    public static List<OpportunityLineItem> getExistedOpli(String oppId, Boolean isNotEditable){
        String[] additionalFields = new String[]{   'PricebookEntry.Product2.Name',
                                                    'PricebookEntry.UnitPrice',
                                                    'PricebookEntry.Product2.Tract_ProductId__c',
                                                    'PricebookEntry.Product2.Tract_PriceId__c',
                                                    'PricebookEntry.Product2.Billing_Category__c',
                                                    'PricebookEntry.Product2.PredifinedAdunit__r.DartName__c',
                                                    'PricebookEntry.Product2.AdServer_Keywords_Key_Values__c',
                                                    'Predefined_Adunit__r.DartName__c',
                                                    'PricebookEntry.Product2.RecordType.Name',
                                                    'PricebookEntry.Product2.Site__r.Country__c',
                                                    'PricebookEntry.Product2.Device__c',
                                                    'PricebookEntry.Product2.Browser__c',
                                                    'PricebookEntry.Product2.Bandwidth__c',
                                                    'PricebookEntry.Product2.OperatingSystem__c',
                                                    'PricebookEntry.Product2.Connection__c',
                                                    'PricebookEntry.Product2.Time__c',
                                                    'PricebookEntry.Product2.Keywords__c',
                                                    'PricebookEntry.Product2.Geo_IP__c',
                                                    'PricebookEntry.Product2.FC__c',
                                                    'PricebookEntry.Product2.Content__c',
                                                    'PricebookEntry.Product2.Tract_ParentId__c',
                                                    'PricebookEntry.Product2.Tract_PriceId__c',
                                                    'Opportunity.Account.Tract_AccountId__c',
                                                    'Opportunity.Original_Opportunity__c',
                                                    'Product2.Tract_PriceId__c',
                                                    'Product2.Tract_ProductId__c',
                                                    'Product2.Name',
                                                    'Product2.Description',
                                                    'Opportunity.Account.AccountDiscount__c',
                                                    'Product2.Tract_ProductType__c'};
        oppId = String.escapeSingleQuotes(oppId);
        String whereClouse = ' OpportunityId =\'' + oppId + '\'';
        if(!(isNotEditable != null && isNotEditable)){
        	 whereClouse += ' AND (Status__c=\'Approved\' OR Status__c=\'draft\')';

        }
        return GW_sObject.queryRecords('OpportunityLineItem',whereClouse , additionalFields);
	}
	
    private static List<OpportunityLineItem> doSortListItem(List<OpportunityLineItem> lstItems) {
    	List<OpportunityLineItem> lstSortItems = new List<OpportunityLineItem>();
    	List<OpportunityLineItem> lstTrialProduct = new List<OpportunityLineItem>();
    	List<OpportunityLineItem> lstNormalProduct = new List<OpportunityLineItem>();
    	for(OpportunityLineItem item: lstItems) {
    		if((String.isNotBlank(item.Product2.Name) && item.Product2.Name.containsIgnoreCase(TRIAL))) {
    			lstTrialProduct.add(item);
    		} else {
    			lstNormalProduct.add(item);
    		}
    	}
    	if(!lstTrialProduct.isEmpty()) {
    		for(OpportunityLineItem item: lstTrialProduct) {
    			lstSortItems.add(item);
    			if(!lstNormalProduct.isEmpty()) {
    				Integer index = (lstNormalProduct.size()-1) ;
    				lstSortItems.add(lstNormalProduct.get(index));
    				lstNormalProduct.remove(index);
    			}
    		}
    	}
    	
    	if(!lstNormalProduct.isEmpty()) {
    		lstSortItems.addAll(lstNormalProduct);
    	}
    	
    	return lstSortItems;
    }

    @AuraEnabled
    public static List<Map<String, Object>> getExistedOpli2DisplayInUI(String oppId){
        if(oppId == null) {
            return new List<Map<String, Object>>();
        }

        List<OpportunityLineItem> lstOplis = getExistedOpli(oppId);
        //return convertLstLineItem2JsonForm(lstOplis);
        return convertLstLineItem2JsonForm(getLineItemByProductTags(lstOplis, false));
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getExistedAllOpli2DisplayInUI(String oppId){
        if(oppId == null) {
            return new List<Map<String, Object>>();
        }
        Boolean isNotEditable = getIsOpportunityNotEditable(oppId);
        List<OpportunityLineItem> lstOplis = getExistedOpli(oppId, isNotEditable);
        return convertLstLineItem2JsonForm(lstOplis);
    }
    
    @AuraEnabled
    public static Boolean getIsOpportunityNotEditable(String oppId){
        if(oppId != null) {
        	oppId = String.escapeSingleQuotes(oppId);
			List<Opportunity> lstOpp = GW_sObject.queryRecords('Opportunity', ' Id =\''+ oppId +'\'');
			
			Boolean res = lstOpp.isEmpty()? false : (lstOpp[0].NumStatus__c >= 2);
			return res;
        }
        return false;
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getExistedLineItem2DisplayInUI(String oppId){
        if(oppId == null) {
            return new List<Map<String, Object>>();
        }

        List<OpportunityLineItem> lstOplis = getExistedOpli(oppId);
        //return convertLstLineItem2JsonForm(lstOplis);
        return convertLstLineItem2JsonForm(lstOplis);
    }
    
    public static final String TRIAL = 'ProbeMonat';

    /**
    * Method to convert List Line Item to JSON Form
    * @param lstOplis   List Opportunity Line Item to convert
    * @return List of JSON form
    */
    private static List<Map<String, Object>> convertLstLineItem2JsonForm(List<OpportunityLineItem> lstOplis){
        List<Map<String, Object>> lstJSONs = new List<Map<String, Object>>();
        Map<String, Map<String, Object>> mParentLineItem = new Map<String, Map<String, Object>>(); //key line item id
        Map<String, List<Map<String, Object>>> mChildLineItem = new Map<String, List<Map<String, Object>>>();//key ParentOpportunityLineItemId__c
		Boolean isTrialProduct = false;
		Boolean isFirstProduct = false;
		Date trialProStartDate = system.today().addMonths(1);
		lstOplis = doSortListItem(lstOplis);
        for(OpportunityLineItem opli: lstOplis){
            Boolean isOriginal = (opli.Opportunity.Original_Opportunity__c == null);
            isTrialProduct = !isFirstProduct ? (String.isNotBlank(opli.Product2.Name) && opli.Product2.Name.containsIgnoreCase(TRIAL)) : isTrialProduct;
            Boolean setEndDate = (String.isNotBlank(opli.Product2.Name) && opli.Product2.Name.containsIgnoreCase(TRIAL)) ? true : opli.SetEndDate__c;
          	//Date endDate = isTrialProduct ? opli.until_Date__c.addDays(-1) :  opli.until_Date__c;
          	Date endDate = opli.until_Date__c;
          	if(isFirstProduct && isTrialProduct) {
          		//opli.from_Date__c = trialProStartDate.addMonths(1);
          		isFirstProduct = false;
          		isTrialProduct = false;
          	}
          	
          	if(isTrialProduct) {
          		 isFirstProduct = true;
          		 trialProStartDate = opli.from_Date__c;
          	}
            //parent line item
            if(opli.ParentOpportunityLineItemId__c == null){
                mParentLineItem.put(opli.id, new Map<String, Object>{'Id'           => opli.Product2Id,
                                                                    'Name'          => opli.PricebookEntry.Product2.Name,
                                                                    'ListPrice'     => opli.PricebookEntry.UnitPrice,
                                                                    'CurrencyCode'  => opli.CurrencyIsoCode,
                                                                    'Quantity'      => opli.Quantity,
                                                                    'LineItemId'    => opli.id,
                                                                    'ServiceDate'   => opli.from_Date__c,
                                                                    'EndDate'       => endDate,
                                                                    'Description'   => opli.Description,
                                                                    'BillingType'   => opli.BillingCalc__c,
                                                                    'Discount'      => opli.AccountDiscount__c,
                                                                    'TotalPrice'    => opli.TotalPrice,
                                                                    'hasNoChild'    => true,
                                                                    'isSelected'    => true,
                                                                    'isOriginal'    => isOriginal,
                                                                    'TractProductType' => opli.Product2.Tract_ProductType__c,
                                                                    'Rebate_In_Kind_Reason__c' => opli.Rebate_In_Kind_Reason__c,
                                                                    'SetEndDate__c' => setEndDate,
                                                                    'isTrialProduct'=> isTrialProduct,
                                                                    'TotalAmountNet__c'=> opli.TotalAmountNet__c});
                continue;
            }

            //child line item
            String keyParentId = opli.ParentOpportunityLineItemId__c;
            if(!mChildLineItem.containsKey(keyParentId)){
                mChildLineItem.put(keyParentId, new List<Map<String, Object>>());
            }
            Map<String, Object> mchild = new Map<String, Object>{'Id'           => opli.Product2Id,
                                                                'Name'          => opli.PricebookEntry.Product2.Name,
                                                                'ListPrice'     => opli.PricebookEntry.UnitPrice,
                                                                'CurrencyCode'  => opli.CurrencyIsoCode,
                                                                'Quantity'      => opli.Quantity,
                                                                'LineItemId'    => opli.id,
                                                                'ServiceDate'   => opli.from_Date__c,
                                                                'EndDate'       => endDate,
                                                                'Description'   => opli.Description,
                                                                'BillingType'   => opli.BillingCalc__c,
                                                                'Discount'      => opli.AccountDiscount__c,
                                                                'TotalPrice'    => opli.TotalPrice,
                                                                'hasNoChild'    => true,
                                                                'isSelected'    => true,
                                                                'TractProductType' => opli.Product2.Tract_ProductType__c,
                                                                'Rebate_In_Kind_Reason__c' => opli.Rebate_In_Kind_Reason__c,
                                                                'SetEndDate__c' => setEndDate,
                                                                'isTrialProduct'=> isTrialProduct};
            mChildLineItem.get(keyParentId).add(mchild);
        }

        //merge child line item to parent
        for(String keyParentId: mParentLineItem.keySet()){
            if(mChildLineItem.containsKey(keyParentId)){
                mParentLineItem.get(keyParentId).put('hasNoChild', false);
                mParentLineItem.get(keyParentId).put('RelatedProducts', mChildLineItem.get(keyParentId));
            }

            lstJSONs.add(mParentLineItem.get(keyParentId));
    }

        return lstJSONs;
    }

    /**
     * Products which were configured
     * @param oppId, opportunity Id
     * @return OpportunityLineItem List
     */
    @AuraEnabled
    public static List<Object> getAddedProductsLPC (String oppId) {
        return getAddedProductsLPC_optimize(oppId);
    }
    
    //////////SOQL 101 /////////////
    @AuraEnabled
    public static List<Object> getAddedProductsLPC_optimize(String oppId) {
        List<SObject> olis = new List<SObject>(); 
        Opportunity opp = (Opportunity) GW_Opportunity.getRecord(oppId, new List<String>{'Account.AccountDiscount__c', 'MemberUnit__r.EnableTRACT__c'});
        
        Map<Id, Media_Basket__c> mpbeIdvsMediaBasket = new Map<Id, Media_Basket__c>();
        for (Media_Basket__c mb : [Select AdPriceIdText__c From Media_Basket__c Where OpportunityId__c =: oppId]) {
            mpbeIdvsMediaBasket.put(mb.AdPriceIdText__c, mb);
        }
        
        List<PriceBookEntry> priceBookEntry = GW_PriceBookEntry.getList(mpbeIdvsMediaBasket.KeySet(), PBE_ADDITIONAL_FIELDS);
        
        //catch price book entry & product to use next step
        Set<Id> productIds = new Set<Id>();
        for (PriceBookEntry pbe : priceBookEntry) productIds.add(pbe.Product2Id);
        UTIL.cache(GW_Product.getList(productIds));
        UTIL.cache(priceBookEntry);
        
        for (PriceBookEntry pbe : priceBookEntry) {
            Map<String, SObject> objInstances = createOpportunityLineItemInstance_optimize(opp, pbe);
            SObject oli = objInstances.get('OpportunityLineItem');
            oli.put('Id', mpbeIdvsMediaBasket.get(pbe.Id).Id);
            olis.add(oli);
        }
        olis.addAll( (List<SObject>) getOpportunityLineItems(oppId) );
        return olis;
    }
    
     private static Map<String, SObject> createOpportunityLineItemInstance_optimize(Opportunity opp, PriceBookEntry pbe) {
        OpportunityLineItem oli = generateLineItemInstance(opp, pbe, null, 10);
        oli.Predefined_Placement__c = String.isNotBlank(pbe.Product2.Placement__c) ? (pbe.Product2.Placement__c+'').subString(0, 15) : null;
        oli.ListPrice__c = oli.ListPrice__c == 0 ? pbe.UnitPrice : oli.ListPrice__c;
        return new Map<String, SObject>{'OpportunityLineItem' => oli, 'Opportunity' => opp, 'PricebookEntry' => pbe};
    }
    
    public static OpportunityLineItem generateLineItemInstance(Opportunity opp, PricebookEntry pbe, Decimal quantity, Decimal unitPrice) {
        Date startDate = Date.today();
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.PricebookEntryId = pbe.Id;
        oli.PricebookEntry = pbe;
        oli.Quantity = quantity;
        oli.from_date__c = startDate;
        if(!oli.SetEndDate__c) oli.until_Date__c = startDate.addMonths(1);
        
        Decimal totalPrice = ( opp.Account.AccountDiscount__c == null ) ? unitPrice : unitPrice*(100 - opp.Account.AccountDiscount__c)/100;
        
        if (opp.MemberUnit__c != null && opp.MemberUnit__r.EnableTRACT__c) {
            oli.TotalPrice = totalPrice;
            oli.AccountDiscount__c = opp.Account.AccountDiscount__c;
            oli.UPCF__c = 1;
            oli.ListPrice__c = unitPrice;
            oli.SalesPriceNet__c = totalPrice;
        } else {
            String firstBillingCatCalc = '';
            String bCat = '';
            String bCalc = '';
            if (String.isNotBlank(pbe.Product2.Billing_Category__c)) {
                firstBillingCatCalc = pbe.Product2.Billing_Category__c.split(';')[0];
                bCat = firstBillingCatCalc.split('_')[0];
                bCalc = firstBillingCatCalc.split('_')[1];
            }
            
            oli.Billing_Category__c = bCat;
            oli.BillingCalc__c = bCalc;
            oli.FC_Quantity__c = ( pbe.Product2.Advertising_Medium__c != null && pbe.Product2.Advertising_Medium__r.FC_Quantity__c != null) ? pbe.Product2.Advertising_Medium__r.FC_Quantity__c : 0;
            oli.FC_Period__c = ( pbe.Product2.Advertising_Medium__c != null && pbe.Product2.Advertising_Medium__r.FC_Period__c != null ) ? pbe.Product2.Advertising_Medium__r.FC_Period__c : '';
            oli.FC_Ad_served_every__c = pbe.Product2.Advertising_Medium__c != null ? pbe.Product2.Advertising_Medium__r.FC_Ad_served_every__c : null;
            oli.AdKeywords__c = pbe.Product2.AdServer_Keywords_Key_Values__c;
            //16-09-2016 - GIS team predefined keyvalue should be add to AdKeywords__c only & added two new predefined fields (Predefined_DeviceCategory__c, Predifined_Adunit__c)
            //KeyValueString__c = String.isBlank(prod.AdServer_Keywords_Key_Values__c)?'':prod.AdServer_Keywords_Key_Values__c,
            oli.Predefined_Adunit__c = String.isNotBlank(pbe.Product2.PredifinedAdunit__c) ? (pbe.Product2.PredifinedAdunit__c+'').subString(0, 15) : null;
            oli.Predefined_DeviceCategory__c = pbe.Product2.Device_Category__c;
            oli.Check_Inventory__c = true;
            oli.AccountDiscount__c = (opp.Account.AccountDiscount__c == null ? 0 : opp.Account.AccountDiscount__c);
            oli.ContractDiscount__c = (opp.ContractDiscount__c == null ? 0 : opp.ContractDiscount__c);

            PriceCalculator.applyPriceModel_optimize(oli, opp, pbe);

            // TBFIXED JC - MOVE TO PRICE CALCULATOR
            // It's related to LCC pricing calculator, figure out how and why and move to price calculator
            Decimal partnerShare = opp.IndirectDiscount__c == null ? 0 : opp.IndirectDiscount__c;
            Decimal ebayShare = 100 - partnerShare;

            if(oli.CustomListPrice__c != NULL && oli.CustomListPrice__c != 0) {
                oli.SalesPriceNet__c = oli.CustomListPrice__c * (ebayShare / 100);
                oli.UnitPrice = oli.CustomListPrice__c;
            } else {
                oli.SalesPriceNet__c = oli.ListPrice__c * (ebayShare / 100);
                oli.UnitPrice = oli.ListPrice__c;
            }
        }

        return oli;
    }
    ///////END FIX SOQL 101////////////
 
       
    /**
     * Products which were configured
     * @param oppId, opportunity Id
     * @return OpportunityLineItem List
     */
    @AuraEnabled
    public static List<Object> getAddedProducts (String oppId, Boolean isTract) {
        return getMediaSalesProduct(getOpportunityLineItems(oppId));
    }
    
    @AuraEnabled
    public static Map<String, Boolean> getMapIsImpressionType(String oppId) {
        Map<String, Boolean> theMap = new Map<String, Boolean>();
		/**
        Set<String> pbeIds = new Set<String>();
        for (Media_Basket__c mb : [Select AdPriceIdText__c From Media_Basket__c Where OpportunityId__c =: oppId]) {
            pbeIds.add(mb.AdPriceIdText__c);
        }
        for(OpportunityLineItem item : [select PriceBookEntryId from OpportunityLineItem where OpportunityId = :oppId]) {
            pbeIds.add(item.PriceBookEntryId);
        }
        Set<String> setAdTypes = new Set<String> {'Sponsorship', 'Network', 'House'};
        for(PriceBookEntry pbe : [Select Id from PriceBookEntry
            where   id in :pbeIds and
                    Product2.Advertising_Medium__r.DART_AdType__c in :setAdTypes]) {
            theMap.put(pbe.Id, true);
        }
		*/
        return theMap;
    }

    /**
     * Products which are available for Inventory forecasting
     * @param oppId, opportunity Id
     * @return OpportunityLineItem List
     */
    @AuraEnabled
    public static List<OpportunityLineItem> getInventoryList(String oppId) {
        List<OpportunityLineItem> olis = (List<OpportunityLineItem>)GW_sObject.queryRecords('OpportunityLineItem', 'OpportunityId = \'' + oppId + '\' And Check_Inventory__c = true', OPPITEM_ADDITIONALFIELDS);
        UTIL.log('Lightning request: '+olis);
        return olis;
    }

    /**
     * Products which are available for Delivery
     * @param oppId, opportunity Id
     * @return OpportunityLineItem List
     */
    @AuraEnabled
    public static RemoteResponse getListAdsDelivery(String oppId){
        try{
            List<OpportunityLineItem> lstItems = getOpportunityLineItems(oppId);
            Map<String, OpportunityLineItem> mapOppItems  = new Map<String, OpportunityLineItem>();
            Map<String, Rev__c> mapRevItems = new Map<String, Rev__c>();
            for(OpportunityLineItem item : lstItems){
                mapOppItems.put(item.id, item);
                mapRevItems.put(item.id, new Rev__c());
            }

            for(Rev__c rv : [Select ExtLineItemId__c, AD_Click_Rate__c, Last_Delivery_import__c, ExtOrderId__c, AD_Clicks__c, AD_Impressions__c, AD_OSI__c, From_Date__c, Product__r.Site__r.Country__c, OrigOpportunityLineItemId__c, AD_Active_View_Viewable_Impressions__c, AD_Active_View_Measurable_Impressions__c, AD_Active_View_Viewable_Impressions_Rate__c From Rev__c Where OrigOpportunityLineItemId__c IN: mapOppItems.keySet()]){
                mapRevItems.put(rv.OrigOpportunityLineItemId__c, rv);
            }

            return new RemoteResponse(mapRevItems);
        }catch(exception e){
            return new RemoteResponse('Error: '+e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
	
	@AuraEnabled // for both Adsales and Subcribtion
    public static void syncTractItemStartDate(String itemId) {
    		for(OpportunityLineItem oli : [select id, OpportunityId, Opportunity.Tract_OrderId__c, from_Date__c from OpportunityLineItem 
    																											where id=:itemId 
    																											and Opportunity.NumStatus__c > 2 
    																											and Opportunity.NumStatus__c < 5
    																											and Opportunity.Tract_Order_Number__c != null]) {
    			UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(new Set<Id> {oli.OpportunityId});
    			Map<Id, TractObject.OrderItem> mapOrder = WSC_Tract.getMapOliId2OrderItem(oli.OpportunityId);
			TractObject.OrderItem item = mapOrder.get(oli.id);
			if(item != null) {
				UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.OrderItemStartDateUpdate');
		        req.mAdditionalParams.put('opp.Tract_Order_Id', oli.Opportunity.Tract_OrderId__c);
		        req.mAdditionalParams.put('OrderItem.id', item.id);
		        req.mAdditionalParams.put('oli.from_Date', String.valueOf(oli.from_Date__c));
		        req.mAdditionalParams.put('item.operation_run_attribute.id', item.operation_run_attributes[0].id);
		        req.mAdditionalParams.put('item.operation_run_attribute.type', item.operation_run_attributes[0].operation_run_attribute_type);
		        req.init(oli.OpportunityId);
		        req.call();
			}
			UTIL_WSC.bulkHandler.commitAll();
    		}
    }
	@AuraEnabled // Adsales
    public static void syncDeactivateServTract(String itemId) {
    		OpportunityLineItem item;
    		for(OpportunityLineItem oli : [select id, OpportunityId, Tract_ServiceId__c, Tract_ServiceAgreementId__c, until_Date__c from OpportunityLineItem 
    																																where id=:itemId 
    																																and Opportunity.NumStatus__c > 2 
    																																and Opportunity.NumStatus__c < 5
    																																and Opportunity.LineOfBusiness__c = 'AdSales'
    																																and Opportunity.Tract_Order_Number__c != null]) {
    			UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(new Set<Id> {oli.OpportunityId});
    			if(oli.Tract_ServiceId__c == null) {
    				Map<Id, TractObject.OrderItem> mapOrder = WSC_Tract.getMapOliId2OrderItem(oli.OpportunityId);
    				oli.Tract_ServiceId__c = mapOrder.containsKey(oli.id) ? mapOrder.get(oli.id).service.id : null;
    				item = oli;
    			}
    			
    			if(oli.Tract_ServiceId__c != null) {
    				if(oli.Tract_ServiceAgreementId__c == null) {
    					TractObject.Service tractServ = WSC_Tract.getMapService(oli.OpportunityId, oli.Tract_ServiceId__c);
    					oli.Tract_ServiceAgreementId__c = tractServ == null ? null : tractServ.current_agreement_service.id;
    					item = oli;
    				}
    				if(oli.Tract_ServiceAgreementId__c != null) {
    					doDeactivateServTract(oli.OpportunityId, oli.Tract_ServiceId__c, oli.Tract_ServiceAgreementId__c, oli.until_Date__c);
    				}
    			}
    			UTIL_WSC.bulkHandler.commitAll();
    		}
    		if(item != null) update item;
    }
    @AuraEnabled
    public static void syncTractPrices(String itemId) {
    		OpportunityLineItem item;
    		for(OpportunityLineItem oli : [select id, OpportunityId, Tract_ServiceId__c from OpportunityLineItem 
    																					where id=:itemId 
    																					and Opportunity.NumStatus__c > 2 
    																					and Opportunity.NumStatus__c < 5
    																					and Opportunity.LineOfBusiness__c = 'AdSales'
    																					and Opportunity.Tract_Order_Number__c != null]) {
    			UTIL_WSC.bulkHandler = new UTIL_WSC_Bulk(new Set<Id> {oli.OpportunityId});
    			if(oli.Tract_ServiceId__c == null) {
    				Map<Id, TractObject.OrderItem> mapOrder = WSC_Tract.getMapOliId2OrderItem(oli.OpportunityId);
    				oli.Tract_ServiceId__c = mapOrder.containsKey(oli.id) ? mapOrder.get(oli.id).service.id : null;
    				item = oli;
    			}
    			
    			if(oli.Tract_ServiceId__c != null) {
    				UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.UsageRuleGetByService');
		        req.mAdditionalParams.put('id', oli.Tract_ServiceId__c);
		        req.init(oli.OpportunityId);
		        UTIL_WSC.WSC_Result res = req.call();
        			if (res.statusCode == 200) {
        				for(Object obj : (List<Object>) res.getResponseData().get('results') ) {
        					TractObject.UsageRule usageRule = (TractObject.UsageRule) JSON.deserialize(JSON.serialize(obj), TractObject.UsageRule.class);
        					if(usageRule.name == 'CPM Usage') {
        						UTIL_WSC.WSC_Request req2 = UTIL_WSC.getWSC_Request('WSC_Tract.OrderAdSalesUpdate');
					        req2.mAdditionalParams.put('oppItemid', oli.id);
					        req2.mAdditionalParams.put('id', oli.Tract_ServiceId__c);
					        req2.mAdditionalParams.put('usage_rule/id', usageRule.id);
					        req2.mAdditionalParams.put('usage_rate/id', usageRule.usage_rate.id);
					        req2.mAdditionalParams.put('usage_rate/charge_category/id', usageRule.usage_rate.charge_category.id);
					        req2.mAdditionalParams.put('order_item_usage_rule/id', usageRule.order_item_usage_rule.id);
					        req2.init(oli.OpportunityId);
					        req2.call();
        					}
        				}
        				
        			}
    				
    			}
    			UTIL_WSC.bulkHandler.commitAll();
    		}
    		if(item != null) update item;
    }
	/**
     * Allow user to update oli of Adsale Running opp (NumStatus__c = 2 )
     * It is called: 
     * - Click on Save icon in action column of SalePath UI
     * - Click os Save Lines (Blue button). JS is checking and called this method only 1 time in case 1 or multi-items
     */
    @AuraEnabled
    public static RemoteResponse syncToTractAfterUpdateOlis(String oppId) {
	    	RemoteResponse response = new RemoteResponse();
	    	response.statusCode = RemoteResponse.STATUSCODE_OK;
        response.content = '';
        try {
        		String oId = oppId;            
	    		for(Opportunity opp : [select id from Opportunity 
	    												where id = :oId 
	    												and Tract_Order_Number__c != null 
	    												and NumStatus__c = 2 
	    												and LineOfBusiness__c = 'AdSales']) {
	    			UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.DraftOrderAdSalesCreate');
		        req.init(opp.Id);
		        req.call();
	    		}
        } catch (exception e) {
        		return new RemoteResponse('Error syncToTractAfterUpdateOlis: '+e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    		return response;
    }
    /**
     * Save modified OpportunityLineItem
     * @param oli, OpportunityLineItem
     * @return OpportunityLineItem
     */
    @AuraEnabled
    public static RemoteResponse saveOpportunityLineItem(OpportunityLineItem oli) {
        try{
        	// Bunhor @10-Dec-15: W-000129: creating default Targetings
            GW_OpportunityLineItem.configureDFPTargeting(new List<OpportunityLineItem>{oli});
            upsert oli;

            // Dmitry CD-3680: upsert oli before querying the opp to populate properly opp rollup fields when returned
            Opportunity opp = getOpportunityById(oli.OpportunityId);
            GW_Opportunity.isTractRunningToSinged = opp.MemberUnit__r.EnableTRACT__c && opp.NumStatus__c == 4;
 
            //Clear the basket after saving Campaign Items to Media Campaign
            if (oli.PricebookEntryId != null) {
                delete [Select Id From Media_Basket__c where AdPriceIdText__c = : oli.PricebookEntryId AND UserId__c = : System.userInfo.getUserId() AND OpportunityId__c = : opp.Id];
            }

            RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{'oli' => oli, 'opp' => opp};
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }catch (System.DmlException dmle){
            String friendlyErr = dmle.getDmlMessage(0).contains(ALREADY_INVOICED_REV_ERROR) ? ALREADY_INVOICED_REV_ERROR : dmle.getDmlMessage(0);
            return new RemoteResponse(friendlyErr, RemoteResponse.STATUSCODE_FATAL);
        }
        catch (Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    public static Integer getDaysOfMonth(date dt){
        return  Date.daysInMonth(dt.year(), dt.month());
    }
    /**
     * Set OpportunityLineItem PriceModel
     * @param oli, OpportunityLineItem
     * @return OpportunityLineItem
     */
    @AuraEnabled
    public static RemoteResponse applyPriceModel(OpportunityLineItem oli) {
        try{
            PriceCalculator.applyPriceModel(oli);

            RemoteResponse response = new RemoteResponse();
            response.content = oli;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }
        catch(Exception e){
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }

    }

    @AuraEnabled
    public static RemoteResponse massDeleteOpportunityLineItem(Map<Id, Object> opliIds){
        /*try{
            List<OpportunityLineItem> lstLineItems = [Select OpportunityId

                                                                From OpportunityLineItem
                                                                Where Id in: opliIds.keySet() OR ParentOpportunityLineItemId__c in: opliIds.keySet()];
            delete lstLineItems;

            RemoteResponse response = new RemoteResponse();
            response.content = 'delete completed';
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;

        }catch(System.DMLException dmle){
            return new RemoteResponse('Unable to delete line in status: ' + dmle.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        catch(Exception e){
            return new RemoteResponse('Unable to delete line: '+e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }*/
        return null;

    }

    /**
     * Delete OpportunityLineItem
     * @param procId, OpportunityLineItem/Media_Basket__c Id
     * @return OpportunityLineItem/Media_Basket__c Id
     */
    @AuraEnabled
    public static RemoteResponse deleteOpportunityLineItem(Id procId) {
        // Perform isDeletable() check here
        try{
            Opportunity opp = null;
            Schema.sObjectType entityType = procId.getSObjectType();
            if (entityType == OpportunityLineItem.sObjectType) {
               // String oppId = [Select OpportunityId From OpportunityLineItem Where Id =: procId].OpportunityId;
               // delete new OpportunityLineItem(Id = procId);
               // opp = getOpportunityById(oppId);

                List<OpportunityLineItem> lstLineItems = [Select OpportunityId, Opportunity.StageName, Opportunity.LineOfBusiness__c, Opportunity.Tract_Order_Number__c, Tract_ServiceId__c, Tract_ServiceAgreementId__c
                                                            From OpportunityLineItem
                                                            Where Id =: procId OR ParentOpportunityLineItemId__c =: procId];
                String oppId = lstLineItems[0].OpportunityId;//Opportunity will be the same
                
                OpportunityLineItem item = (new Map<Id, OpportunityLineItem>(lstLineItems)).get(procId);
                
                String servId;
                String agreementId;
                if(item.Opportunity.StageName == 'Running' && item.Opportunity.LineOfBusiness__c == 'AdSales' && Opportunity.Tract_Order_Number__c != null) {
                		servId = item.Tract_ServiceId__c;
                		if(servId == null) {
		    				Map<Id, TractObject.OrderItem> mapOrder = WSC_Tract.getMapOliId2OrderItem(item.OpportunityId);
		    				servId = mapOrder.containsKey(item.id) ? mapOrder.get(item.id).service.id : null;
		    			}
		    			if(servId != null) {
		    				agreementId = item.Tract_ServiceAgreementId__c;
		    				if(agreementId == null) {
		    					TractObject.Service tractServ = WSC_Tract.getMapService(item.OpportunityId, servId);
				    			agreementId = tractServ == null ? null : tractServ.current_agreement_service.id;
		    				}
		    			}
                }

                delete lstLineItems;
                opp = getOpportunityById(oppId);
                
                if(String.isNotBlank(servId) && String.isNotBlank(agreementId)) {
                		futureHandleDeleteToTract(oppId, item.id, servId, agreementId);
                }
            } else if (entityType == Media_Basket__c.sObjectType) {
                delete new Media_Basket__c(Id = procId);
            }
            RemoteResponse response = new RemoteResponse();
            response.content = opp;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }
        catch(System.DMLException dmle){
            return new RemoteResponse('Unable to delete line in status: ('+ procId + ')' + dmle.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        catch(Exception e){
            return new RemoteResponse('Unable to delete line: '+e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
	@future (callout=true)
    private static void futureHandleDeleteToTract(String oppId, String itemId, String serviceId, String serviceAgreementId) {
    		for(OpportunityLineItem item : [select id from OpportunityLineItem where id = :itemId] ) {
    			return; // In case delete failed, skip below codes.
    		}
    		doDeactivateServTract(oppId, serviceId, serviceAgreementId, system.today());
    }
	private static void doDeactivateServTract (String oppId, String servId, String argreementId, Date endDate) {
		UTIL_WSC.WSC_Request req = UTIL_WSC.getWSC_Request('WSC_Tract.DeactivateServiceTract');
        req.mAdditionalParams.put('endDate', String.valueOf(endDate));
        req.mAdditionalParams.put('agreementId', argreementId);
        req.mAdditionalParams.put('serviceId', servId);
        req.init(oppId);
        req.call();
	}

    /**
    * Mehtod to remove OpportunityLineItem and return the remind items
    * @param opliId     OpportunityLineItem
    * @param oppId      OpportunityId
    * @return list of remind line item if success
    */
    @AuraEnabled
    public static RemoteResponse delOppLineItem(String opliId, String oppId){

        //delete OpportunityLineItem from database and return result if there are any issue
        RemoteResponse result = deleteOpportunityLineItem(opliId);
        if(result.statusCode != RemoteResponse.STATUSCODE_OK){
            return result;
        }

        //TODO: detele draft Order in TRACT (next implement)

        //if there are no issue, get existed Line Items to re-render line item
        List<Map<String, Object>> lstExistedLineItems = getExistedOpli2DisplayInUI(oppId);
        result.contents = lstExistedLineItems;
        return result;
    }
    
    private static Map<Id,Product2> getMapProduct2Details(Set<Id> setProIds){
         
        return new Map<Id,Product2>([ Select id,Billing_Category__c from Product2 where id in :setProIds ]);
    }
    
    /**
     * Create new Media_Basket__c instance
     * @param oppId, Opportunity Id
     * @param pbeId, PriceBookEntry Id
     * @return OpportunityLineItem/Media_Basket__c/Opportunity
     */
    @AuraEnabled
    public static RemoteResponse getNewOpportunityLineItem(Id oppId, Id pbeId) {
        try{
            Media_Basket__c mb = new Media_Basket__c(UserId__c = System.Userinfo.getUserId() , AdPriceIdText__c = pbeId , OpportunityId__c = oppId );
            insert mb;
            Map<String, SObject> objInstances = createOpportunityLineItemInstance(oppId, pbeId);
            OpportunityLineItem oli = (OpportunityLineItem)objInstances.get('OpportunityLineItem');
            Opportunity opp = (Opportunity)objInstances.get('Opportunity');
            List<sObject> content = new List<sObject>();
            content.add(oli);
            content.add(mb);
            content.add(opp);
            return new RemoteResponse(content);
        }
        catch (Exception e) {
            return new RemoteResponse('Unable to add line: '+ oppId + '--' + pbeId + '--' + e.getMessage()+e.getStackTraceString(), RemoteResponse.STATUSCODE_ERROR);
        }

    }

    /**
     * Create new OpportunityLineItem instance
     * @param oppId, Opportunity Id
     * @param pbeId, PriceBookEntry Id
     * @return OpportunityLineItem/Opportunity/PricebookEntry
     */
    private static Map<String, SObject> createOpportunityLineItemInstance(Id oppId, Id pbeId) {
        PricebookEntry pbe = (PricebookEntry) GW_sObject.queryRecord('PricebookEntry', pbeId);
        Opportunity opp = (Opportunity) GW_sObject.queryRecord('Opportunity', oppId);
        OpportunityLineItem oli = GW_OpportunityLineItem.createSObject(opp, pbe, null, 10);

        //Add Predefined_Placement__c when create oppline
        Product2 prod = (Product2) GW_sObject.queryRecord('Product2', pbe.Product2Id);
        oli.Predefined_Placement__c = prod.Placement__c !=null?(prod.Placement__c+'').subString(0, 15):null;
        oli.ListPrice__c = oli.ListPrice__c == 0 ? pbe.UnitPrice : oli.ListPrice__c;
        return new Map<String, SObject>{'OpportunityLineItem' => oli, 'Opportunity' => opp, 'PricebookEntry' => pbe};
    }

    /**
    * Create new OpportunityLineItem
    * @param oppId      Opportunity Id
    * @param obj    JSON object to create Line Item
    * @return key: status, value: JSON string
    */
    @AuraEnabled
    public static RemoteResponse createOpportunityLineItem(String oppId, Map<String, Object> obj){
        //fix standard pricebook for temporary use (THBELAU_2016)
        //String pbid = '01s900000068L4dAAE';
        Opportunity opp = (Opportunity) GW_sObject.queryRecord('Opportunity', oppId);
        String pbid = opp.Pricebook2Id;
        PricebookEntry pbe = GW_PriceBookEntry.getPbeFromCache((ID)obj.get('Id'), (ID)pbid);
        String productId = pbe.Product2Id;
        Map<Id,Product2> mapParentPro = getMapProduct2Details(new Set<Id>{productId});
        OpportunityLineItem parentLineItem = GW_OpportunityLineItem.createSObject(opp, pbe, 1, (Decimal)obj.get('ListPrice'));
        parentLineItem.Status__c = 'draft';
        if(mapParentPro.containskey(productId) &&  String.isNotBlank(mapParentPro.get(productId).Billing_Category__c)) {
            Product2 prod = mapParentPro.get(productId);
            parentLineItem.Billing_Category__c = prod.Billing_Category__c.split('_')[0];
            parentLineItem.BillingCalc__c = prod.Billing_Category__c.split('_')[1];
        }

        if(obj.containsKey('ParentId')){
            parentLineItem.ParentOpportunityLineItemId__c = String.valueOf(obj.get('ParentId'));
        }

        Map<String, String> mapReturn = new Map<String, String>();
        try{
            insert parentLineItem;

            //create child line item
            if(obj.containsKey('RelatedProducts')){
                List<Object> lstChildren = (List<Object>)obj.get('RelatedProducts');
                createChildLineItem(opp, pbid, parentLineItem.Id, lstChildren);
            }

            //get all existed Line item to re-render
            List<OpportunityLineItem> lstOplis = getExistedOpli(oppId);
            List<Map<String, Object>> lstExistedLineItems = convertLstLineItem2JsonForm(lstOplis);

            RemoteResponse response = new RemoteResponse();
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            response.contents = lstExistedLineItems;
            return response;
        }catch(System.DMLException dmle){
            return new RemoteResponse('Unable to create line in status: ' + dmle.getDmlMessage(0), RemoteResponse.STATUSCODE_ERROR);
        }catch(Exception ex){
            return new RemoteResponse('Unable to create line: ' + ex.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }

    }

    /**
    * create sub line item from its parent
    * @param opp                object Opportunity
    * @param parentLineItem     Parent Line Item Id
    * @param lstChildren        list sub line items to create
    */
    private static void createChildLineItem(Opportunity opp,
                                            Id pbid,
                                            Id parentLineItem,
                                            List<Object> lstChildren){

        List<OpportunityLineItem> lstLineItems = new List<OpportunityLineItem>();
        Set<ID> proIds = new Set<ID>();
        for(Object objLineItem: lstChildren){
            Map<Object, Object> mLineItem = (Map<Object, Object>)objLineItem;
            proIds.add((ID)mLineItem.get('Id'));
        }

        List<PricebookEntry> lstPbes = GW_sObject.queryRecords('PricebookEntry',
                                                                'Pricebook2Id = \'' + pbid + '\' AND Product2Id in: idSet1',
                                                                new Map<String, Set<ID>>{'idSet1' => proIds});

        Map<String, PricebookEntry> mapPbes = new Map<String, PricebookEntry>();//Key Product + Pricebook
        Set<Id> setProductIds = new Set<Id>();
        for(PricebookEntry pbe: lstPbes){
            mapPbes.put(String.valueOf(pbe.Product2Id).substring(0, 15) + '_' + String.valueOf(pbe.Pricebook2Id).substring(0, 15), pbe);
            setProductIds.add(pbe.Product2Id);
        }
        
        Map<Id,Product2> mapProDetails = getMapProduct2Details(setProductIds);
        for(Object objLineItem: lstChildren){
            Map<Object, Object> mLineItem = (Map<Object, Object>)objLineItem;

            String keyProPb = String.valueOf(mLineItem.get('Id')).substring(0, 15) + '_' + String.valueOf(pbid).substring(0, 15);
            if(!mapPbes.containsKey(keyProPb)) continue;

            String productId = mapPbes.get(keyProPb).Product2Id;
            
            OpportunityLineItem lineItem = GW_OpportunityLineItem.createSObject(opp, mapPbes.get(keyProPb), 1, (Decimal)mLineItem.get('ListPrice'));
            lineItem.Status__c = 'draft';
            lineItem.ParentOpportunityLineItemId__c = parentLineItem;
            
            if(mapProDetails.containskey(productId) &&  String.isNotBlank(mapProDetails.get(productId).Billing_Category__c)) {
                Product2 prod = mapProDetails.get(productId);
                lineItem.Billing_Category__c = prod.Billing_Category__c.split('_')[0];
                lineItem.BillingCalc__c = prod.Billing_Category__c.split('_')[1];
            }

            lstLineItems.add(lineItem);
        }

        if(!lstLineItems.isEmpty()){
            insert lstLineItems;
        }
    }
    /**
     * Copy record OpportunityLineItem
     * @param oli, OpportunityLineItem
     * @return OpportunityLineItem
     */
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
            //copy.Availability__c = oli.Availability__c;
            //copy.Last_Availability_Forecast__c = oli.Last_Availability_Forecast__c;
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
            // Avoiding: field integrity exception: UnitPrice (only one of unit price or total price may be specified): [UnitPrice]
            if( copy.TotalPrice == null ) copy.UnitPrice = copy.SalesPriceNet__c;


            return new RemoteResponse(copy);
        }
        catch (Exception e){
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }

    }

    public static Integer NUM_REC_PER_PAGE = 30;
    public static Integer NUM_PRODUCT_LIMIT = 10000;
    /**
     * Get Product for selection
     * @param pricebookId, PricebookEntry Id
     * @param option, filter query {'limit'=>0, 'offset'=>0, 'category1'=>'', 'category2'=>'', 'category3'=>'', 'searchStr'=>''}
     * @return PricebookEntry List
     */
    @AuraEnabled
    public static List<PricebookEntry> getProducts(Id pricebookId, Map<String, Object> option) {
        Integer numLimit = option.containsKey('limit') && Integer.valueOf(option.get('limit'))!=0? Integer.valueOf(option.get('limit')) : 10000;

        String whereStr = '';
        if(option.containsKey('category1') && (String)option.get('category1')!='') whereStr += ' AND Product2.FilterCategory1__c LIKE \'%'+(String)option.get('category1')+'%\' ';
        if(option.containsKey('category2') && (String)option.get('category2')!='') whereStr += ' AND Product2.FilterCategory2__c LIKE \'%'+(String)option.get('category2')+'%\' ';
        if(option.containsKey('category3') && (String)option.get('category3')!='') whereStr += ' AND Product2.FilterCategory3__c LIKE \'%'+(String)option.get('category3')+'%\' ';

        if(option.containsKey('searchStr') && (String)option.get('searchStr')!='') whereStr += ' AND Product2.Name LIKE \'%'+(String)option.get('searchStr')+'%\' ';

        String firstId = option.containsKey('firstId') ? option.get('firstId') + '' : null;
        String lastId = option.containsKey('lastId') ? option.get('lastId') + '' : null;

        if(firstId != null) whereStr += ' AND Id >= :firstId';
        if(lastId != null) whereStr += ' AND Id <= :lastId';

        //dynamic query
        String queryStr = 'SELECT  Id,  Name,  Product2Id,  UnitPrice, CurrencyIsoCode, IsActive,  ProductCode, Product2.FilterCategory1__c, Product2.FilterCategory2__c, Product2.FilterCategory3__c, '+
                            'Product2.Rate_Card__c, Product2.Name, Product2.Description, Product2.Device_Category__c, Product2.Billing_Category__c, Product2.CPM_Price__c, '+
                            'Product2.CPD_Price__c, Product2.CPC_Price__c, Product2.Product_Type__c, Product2.Product_SubType__c, '+
                            'Product2.Advertising_Medium__r.Name '+
                            'FROM PricebookEntry '+
                            'WHERE Product2.RecordType.Name=\'DART6\' AND IsActive=true AND Pricebook2Id=:pricebookId '+whereStr+
                            ' order by Id LIMIT :numLimit';

        return Database.query(queryStr);
    }
    /*@AuraEnabled
    public static List<PricebookEntry> getProducts(Id pricebookId, Map<String, Object> option) {
        Integer numLimit = option.containsKey('limit') && Integer.valueOf(option.get('limit'))!=0? Integer.valueOf(option.get('limit')) : 10000;

        Integer numOffset = option.containsKey('offset')? Integer.valueOf(option.get('offset')) : 0;

        String whereStr = '';
        if(option.containsKey('category1') && (String)option.get('category1')!='') whereStr += ' AND Product2.FilterCategory1__c LIKE \'%'+(String)option.get('category1')+'%\' ';
        if(option.containsKey('category2') && (String)option.get('category2')!='') whereStr += ' AND Product2.FilterCategory2__c LIKE \'%'+(String)option.get('category2')+'%\' ';
        if(option.containsKey('category3') && (String)option.get('category3')!='') whereStr += ' AND Product2.FilterCategory3__c LIKE \'%'+(String)option.get('category3')+'%\' ';

        if(option.containsKey('searchStr') && (String)option.get('searchStr')!='') whereStr += ' AND Product2.Name LIKE \'%'+(String)option.get('searchStr')+'%\' ';

        //dynamic query
        String queryStr = 'SELECT  Id,  Name,  Product2Id,  UnitPrice, CurrencyIsoCode, IsActive,  ProductCode, Product2.FilterCategory1__c, Product2.FilterCategory2__c, Product2.FilterCategory3__c, '+
                            'Product2.Name, Product2.Description, Product2.Device_Category__c, Product2.Billing_Category__c, Product2.CPM_Price__c, '+
                            'Product2.CPD_Price__c, Product2.CPC_Price__c, Product2.Product_Type__c, Product2.Product_SubType__c, '+
                            'Product2.Advertising_Medium__r.Name '+
                            'FROM PricebookEntry '+
                            'WHERE IsActive=true AND Pricebook2Id=:pricebookId '+whereStr+
                            'LIMIT :numLimit '+
                            'OFFSET :numOffset ';

        return Database.query(queryStr);

    }*/

    /**
     *  Divide records into pageNum with first & last record Id per pageNum
     *  @param lstRecords, list sobject records for divide by page num
     *  @return Map<Integer, Map<String, String>>, map page number with first & last record Id per page
     */
    public static Map<Integer, Map<String, String>> loadMapPageNum(List<Sobject>lstRecords){

        Map<Integer, Map<String, String>>mPagniation = new Map<Integer, Map<String, String>>();
        Integer pageNum = 1;
        for(Integer i=0;i<lstRecords.size();i=i+NUM_REC_PER_PAGE){
            if(!mPagniation.containsKey(i)) mPagniation.put(pageNum, new Map<String, String>());

            String firstId = lstRecords[i].get('Id') + '';

            Integer nextPageIndex = i + (NUM_REC_PER_PAGE-1);
            Integer lastIndex = nextPageIndex > lstRecords.size()-1 ? lstRecords.size()-1 : nextPageIndex;

            String lastId = lstRecords[lastIndex].get('Id') + '';

            mPagniation.get(pageNum).put('firstId', firstId);
            mPagniation.get(pageNum).put('lastId', lastId);
            pageNum++;
        }

        return mPagniation;
    }

    /**
     * Get Product for selection
     * @param pricebookId, PricebookEntry Id
     * @return PricebookEntry List
     */
    @AuraEnabled
    public static List<PricebookEntry> getProducts(Id pricebookId) {
        return getProducts(pricebookId, new Map<String, Object>());
    }

    /**
     * Get Selected Products of Opportunity
     * @param oppId, Opportunity Id
     * @return PricebookEntry List
     */
    @AuraEnabled
    public static RemoteResponse getProductsByOpportunitypId(String oppId) {
        try{
            Opportunity selectedOpportunity = getOpportunityById(oppId);
            Map<String, Object> Option = new Map<String, Object>();
            //Option.put('limit', 5000);
            //Option.put('offset', 0);
            List<PricebookEntry> lpbe = getProducts(selectedOpportunity.Pricebook2Id, Option);
            Map<Integer, Map<String, String>>mPageNum = loadMapPageNum(lpbe);

            //distinct record by "Product2.FilterCategory1__c","Product2.FilterCategory2__c","Product2.FilterCategory3__c"
            Map<String, PricebookEntry> filterLstResult = new Map<String, PricebookEntry>();
            List<PricebookEntry> lpbeResult = new List<PricebookEntry>();

            for(PricebookEntry pbe : lpbe){
                if(lpbeResult.size() < NUM_REC_PER_PAGE){
                    lpbeResult.add(pbe);
                }
                String strCategoryJoin = pbe.Product2.FilterCategory1__c+'-'+pbe.Product2.FilterCategory2__c+'-'+pbe.Product2.FilterCategory3__c;
                if(!filterLstResult.containsKey(strCategoryJoin)){
                    filterLstResult.put(strCategoryJoin, pbe);
                }
            }

            List<PricebookEntry> lpbeFilter = new List<PricebookEntry>();
            lpbeFilter = filterLstResult.values();

            RemoteResponse response = new RemoteResponse();
            //response.content = new List<Object>{lpbeResult};

            response.content = new Map<String, Object>{
                                    'lstProduct' => lpbeResult,
                                    'totalProduct' => lpbe.size(),
                                    'lstFilter' => lpbeFilter,
                                    'mapPageNum' => mPageNum
                                };
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        return new RemoteResponse();
    }

    /**
     * Get Selected Products of Opportunity
     * @param pricebookId, Pricebook2Id
     * @param cat1, Product2.FilterCategory1__c
     * @param cat2, Product2.FilterCategory2__c
     * @param cat3, Product2.FilterCategory3__c
     * @param searchstr, Product2.Name
     * @param lstLimit, limti record select
     * @param lstOffset, offset record select
     * @return PricebookEntry List
     */
    @AuraEnabled
    public static RemoteResponse getProductsByFilter(String pricebookId, String cat1, String cat2, String cat3, String searchstr, Integer lstLimit, String firstId, String lastId) {
        try{
            Map<String, Object> Option = new Map<String, Object>();
            Option.put('limit', lstLimit);
            //Option.put('offset', lstOffset);
            Option.put('category1', cat1);
            Option.put('category2', cat2);
            Option.put('category3', cat3);
            Option.put('searchStr', searchstr);
            if(firstId != null) Option.put('firstId', firstId);
            if(lastId != null) Option.put('lastId', lastId);

            List<PricebookEntry> lpbe = getProducts(pricebookId, Option);
            Map<Integer, Map<String, String>>mPageNum = loadMapPageNum(lpbe);
            RemoteResponse response = new RemoteResponse();

            if(Integer.valueOf(Option.get('limit')) == 0) {//first filter
                List<PricebookEntry> lpbeResult = new List<PricebookEntry>();
                for(PricebookEntry pbe : lpbe){
                    if(lpbeResult.size() < 30){
                        lpbeResult.add(pbe);
                    }
                }
                response.content = new Map<String, Object>{
                                    'lstProduct' => lpbeResult,
                                    'totalProduct' => lpbe.size(),
                                    'mapPageNum' => mPageNum
                                };
            }else{//pagenation filter
                response.content = new Map<String, Object>{
                                    'lstProduct' => lpbe
                                };
            }

            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
        return new RemoteResponse();
    }

    /**
     * Get Detailed Opportunity Record
     * @param oppId, Opportunity Id
     * @return Opportunity record
     */
    private static Opportunity getOpportunityById(String oppId) {
        List<String> additionalFields = new List<String>{'Campaign.Name', 'Primary_Contact__r.Name', 'Account.Name','Agency__r.Name','Billing_Account__r.Name','Owner.Name','MemberUnit__r.Name','MemberUnit__r.LineOfBusiness__c', 'MemberUnit__r.EnableTRACT__c'};
        Opportunity selectedOpportunity;
        if (!String.isEmpty(oppId)){
            selectedOpportunity = GW_Opportunity.getRecord(oppId, additionalFields);
            if (selectedOpportunity.PriceBook2Id == null && selectedOpportunity.MemberUnit__c != null){
                List<Pricebook2> pricebooks = [SELECT Id FROM PriceBook2 WHERE MemberUnit__c =: selectedOpportunity.MemberUnit__c];
                if (pricebooks != null && !pricebooks.isEmpty()){
                    selectedOpportunity.PriceBook2Id = pricebooks[0].Id;
                    update selectedOpportunity;
                }
            }
        }
        return selectedOpportunity;
    }

    /**
     * Get Selected Opportunity Record
     * @param oppId, Opportunity Id
     * @return Opportunity record
     */
    @AuraEnabled
    public static RemoteResponse getSelectedOpportunity(String oppId) {
        try{
            RemoteResponse response = new RemoteResponse();
            response.content = getOpportunityById(oppId);
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }
        catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
    
    /**
     * Do Available Forecasting OpportunityLineItem Record
     * @param oppItem, OpportunityLineItem
     * @param ind, Integer
     * @return Map<Integer, OpportunityLineItem>
     */
    @AuraEnabled
    public static RemoteResponse performAvailForecast(OpportunityLineItem oppItem, Integer ind) {
        RemoteResponse responseObj;
        Map<Integer, OpportunityLineItem> mapOppItem = new Map<Integer, OpportunityLineItem>();
        String dartMethod;

        try
        {
            responseObj = new RemoteResponse();
            responseObj.content = ind;
            responseObj.message = oppItem.Id + ' - OK';
            responseObj.statusCode = RemoteResponse.STATUSCODE_OK;
            
            
            BatchAvailabilityForecastProcess batchQueryOnly = new BatchAvailabilityForecastProcess(oppItem.OpportunityId, new Set<String>{ oppItem.Id });
            OpportunityLineItem [] todoList = Database.query(batchQueryOnly.soqlItems);
            
            if (todoList.isEmpty()){
                responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                responseObj.message =  'This lineItem does not match with the criteria for forecasting.';
                
                //record error message as Parent attachment
                LPC_ProductConfiguratorController.generateErrorLogasAttachment(oppItem, DARTLogger.OPPERATION_FORECAST, '', oppItem.PricebookEntry.Product2.RecordType.Name, responseObj.message, responseObj.message); 

                return responseObj;
            }
			// Validate DFP required feilds
            String validateDfpErr = VAL_Global.checkDfpReuiredFields(todoList[0]);

            if( validateDfpErr != null ) {
                responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                responseObj.message =  validateDfpErr;
                return responseObj;
            }
            
            oppItem = todoList[0];
            ForecastController forecastCont = new ForecastController(oppItem);
            // call execute forecast from Dfp
            forecastCont.forecastProcess();
            dartMethod = forecastCont.getInvokedMethod();
            List<DARTObject.DARTForecast> lstFC = forecastCont.getObjectForecast();
            if(lstFC != null)
            {
                DARTObject.DARTForecast fc = lstFC[0];
                oppItem.Availability__c = DARTUtil.toDouble(fc.getAvailableUnits());//(fc.getAvailableUnits()==null?0: Double.valueOf(fc.getAvailableUnits()+''));
                oppItem.Share_of_voice__c = DARTUtil.toDouble(fc.getShareOfVoice());
                oppItem.Last_Availability_Forecast__c = DateTime.Now();
                update oppItem;
                oppItem = [Select Id, Availability__c, Share_of_voice__c, Last_Availability_Forecast__c, Availability_Flag__c From OpportunityLineItem Where id=:oppItem.id];
            }

            mapOppItem.put(Integer.valueOf(ind), oppItem);
            responseObj = new RemoteResponse(mapOppItem);

        }catch(Exception ex) {
            System.debug(ex+'error:' + ex.getStackTraceString());
            mapOppItem.put(Integer.valueOf(ind), oppItem);
            responseObj = new RemoteResponse(mapOppItem);
            responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
            Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
            responseObj.message =  mapErrMsg.get(ex.getMessage())!=null? mapErrMsg.get(ex.getMessage()) : ex.getMessage();
            
            //record error message as Parent attachment
            LPC_ProductConfiguratorController.generateErrorLogasAttachment(oppItem, DARTLogger.OPPERATION_FORECAST, dartMethod, oppItem.PricebookEntry.Product2.RecordType.Name, ex.getMessage(), ex.getStackTraceString());
            return responseObj;
        }
        return responseObj;
    }

    /**
     * Do Booking OpportunityLineItem Record
     * @param oppItem, OpportunityLineItem
     * @return OpportunityLineItem
     */
    @AuraEnabled
    public static RemoteResponse performBookingProcess(OpportunityLineItem oppItem) {
         RemoteResponse responseObj = new RemoteResponse();
         //response lineItem to client
         OpportunityLineitem resLineItem = new OpportunityLineitem();
         //update AdvertiserId & orderId to SF
         Map<String, Advertiser__c> mapAdverUpsert = new Map<String, Advertiser__c>();
         //map opportunityItem tobe updated
         Map<String, OpportunityLineItem> mapOppItemToBeupdated = new Map<String, OpportunityLineItem>();
         //mapping existing advertiser
         Map<String, Advertiser__c> mapAdvertiser = new Map<String, Advertiser__c>();
         //mapping dartVersion and order in a network
         Map<String, DARTObject.IDARTObjectOrder> mapNetworkOrder = new Map<String, DARTObject.DARTOrder>();
         // Store list Advertiser/Company (DART)
         List<DARTObject.IDARTObjectAdvertiser> lstDartAdvertiser = new List<DARTObject.IDARTObjectAdvertiser>();

         OpportunityLineItem [] todoList = new List<OpportunityLineItem>();
         try{
            GW_Opportunity.isFromBooking = true;
            BatchDARTBookingProcess batchQueryOnly = new BatchDARTBookingProcess(oppItem.OpportunityId, new Set<String>{ oppItem.Id });
            List<String> additionalOppFields = new List<String>{'Owner.Dart_User_Name__c', 'Owner.Name', 'Owner.id', 'Owner.Email'};
            List<Opportunity> lstOpps =  (List<Opportunity>)GW_Sobject.queryRecords('Opportunity', 'Id = \'' + oppItem.opportunityId + '\'', additionalOppFields);
            Opportunity opp = lstOpps[0];
            if(!OPP_STAGENAME.contains(opp.StageName)){
                responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                responseObj.message =  'The opportunity is not yet signed. You can not submit to DFP.';

                //record error message as Parent attachment
                LPC_ProductConfiguratorController.generateErrorLogasAttachment(oppItem, DARTLogger.OPPERATION_SUBMIT_ORDER, null, oppItem.PricebookEntry.Product2.RecordType.Name, responseObj.message, responseObj.message);
                return responseObj;
            }
            todoList = Database.query(batchQueryOnly.soqlItems);
            if (todoList.isEmpty()){
                responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                responseObj.message =  'This lineItem does not match with the criteria for booking.';
                //record error message as Parent attachment
                LPC_ProductConfiguratorController.generateErrorLogasAttachment(oppItem, DARTLogger.OPPERATION_SUBMIT_ORDER, null, oppItem.PricebookEntry.Product2.RecordType.Name, responseObj.message, responseObj.message);
                return responseObj;
            }

            oppItem = todoList[0];
            
            // Validate DFP required feilds
            String validateDfpErr = VAL_Global.checkDfpReuiredFields(oppItem);
            if( validateDfpErr != null ) {
                responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                responseObj.message =  validateDfpErr;
                LPC_ProductConfiguratorController.generateErrorLogasAttachment(oppItem, DARTLogger.OPPERATION_SUBMIT_ORDER, null, oppItem.PricebookEntry.Product2.RecordType.Name, responseObj.message, responseObj.message);
                return responseObj;
            }
            
            String dartVerCountry = oppItem.PricebookEntry.Product2.RecordType.Name+'_'+oppItem.PriceBookEntry.Product2.Site__r.Country__c;

            //mapping network & DFP order
            for(OpportunityLineItem item: getOpportunityLineItems(oppItem.opportunityId)){
                if(item.Adserver_ID_Order_ID__c != null && item.Adserver_Adv_Advertiser_ID__c != null){
                    DARTObject.DARTOrder ord = new DARTObject.DARTOrder(item.Adserver_ID_Order_ID__c, item.Adserver_Adv_Advertiser_ID__c);
                    mapNetworkOrder.put(item.PricebookEntry.Product2.RecordType.Name+'_'+item.PriceBookEntry.Product2.Site__r.Country__c,ord);
                }
            }

            //find Advertiser in SF
            List<Advertiser__c> listAdvertiser = DARTUtil.getAdvertiser(opp.AccountId, opp.Agency__c);

            for(Advertiser__c adv : listAdvertiser){
                if(adv.Dart6_Advertiser_Id__c != null){
                    mapAdvertiser.put(DARTUtil.DART6+'_'+adv.AdServer_Login_Name__c, adv);
                }
            }
            BookingController bookingCon  = new BookingController(opp,oppItem);
            //if there is no Advertiser found in SF => Search in DFP
            if(mapAdvertiser.get(dartVerCountry) == null){
                //1-searching Advertiser from DFP
                bookingCon.processSearchAdvertiser();
                List<DARTObject.IDARTObjectAdvertiser> lstExistingAdvs = bookingCon.getListAdvertiserExist();

                //if no advertiser found in DFP => create one in DFP
                if(lstExistingAdvs.isEmpty()){
                    bookingCon.requestCreateAdvertiser();
                    lstDartAdvertiser = bookingCon.getListAdvertiser();
                }else{
                    lstDartAdvertiser.addAll(lstExistingAdvs);
                }

                String dartType = oppItem.PricebookEntry.Product2.RecordType.Name;
                Advertiser__c adv = new Advertiser__c();
                if(dartType.equals(DARTUtil.DART6)) adv.Dart6_Advertiser_Id__c = lstDartAdvertiser.get(0).getDartId();
                mapAdvertiser.put(dartVerCountry, adv);
            }



            // Store all ads/lineItems request success
            List<DARTObject.IDARTObjectAds> listAds = new List<DARTObject.IDARTObjectAds>();
            List<DARTObject.IDARTObjectOrder> listOrders = new List<DARTObject.IDARTObjectOrder>();

            //populate response's DFP fields to SF's fields
            for(String str:mapAdvertiser.keySet()){
                String dartVerNetwork=oppItem.PricebookEntry.Product2.RecordType.Name+'_'+oppItem.PriceBookEntry.Product2.Site__r.Country__c;

                if(str.equals(dartVerNetwork)){
                    Advertiser__c advToUpsert;
                    Advertiser__c advertiser = mapAdvertiser.get(str);
                    if(advertiser.Id==null){
                        advToUpsert = new Advertiser__c();
                        advToUpsert.Account__c=opp.AccountId;
                        advToUpsert.Agency__c=opp.Agency__c;
                        advToUpsert.AdServer_Login_Name__c = oppItem.PriceBookEntry.Product2.Site__r.Country__c;
                    }else{
                        advToUpsert = new Advertiser__c(id=advertiser.Id);
                    }

                    if((oppItem.PricebookEntry.Product2.RecordType.Name).equals(DARTUtil.DART6))
                    advToUpsert.Dart6_Advertiser_Id__c = advertiser.Dart6_Advertiser_Id__c;
                    mapAdverUpsert.put(str,advToUpsert);
                }
            }

            //

            //case to create order in DFP
            if(mapNetworkOrder.get(dartVerCountry) == null){
                // Get existing order by opp's name
                List<DARTObject.IDARTObjectOrder> lstExistOrder = bookingCon.getExistOrder();
                if(!lstExistOrder.isEmpty()){
                    listOrders.addAll(lstExistOrder);
                }else{
                    try{
                        //request to create order in DFP
                        bookingCon.processAndSendOrder(mapAdvertiser);
                        listOrders = bookingCon.getListOrder();
                    }catch(exception e){
                        if(!mapAdverUpsert.isEmpty()) upsert mapAdverUpsert.values();
                        responseObj.content = 0;
                        responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                        Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
                        responseObj.message =  mapErrMsg.get(e.getMessage())!=null? mapErrMsg.get(e.getMessage()) : e.getMessage();
                       
                        //record error message as Parent attachment
                        LPC_ProductConfiguratorController.generateErrorLogasAttachment(oppItem, DARTLogger.OPPERATION_SUBMIT_ORDER, null, oppItem.PricebookEntry.Product2.RecordType.Name, responseObj.message, e.getStackTraceString());
                        return responseObj;
                    }
                }
                mapNetworkOrder.put(dartVerCountry, listOrders.get(0));
            }else listOrders.add(mapNetworkOrder.get(dartVerCountry));

            //populate response's DFP fields to SF's fields - OpportunityLineItem
            if(!mapNetworkOrder.isEmpty()){
                for(String ordKey : mapNetworkOrder.keySet()){
                    String networkType = oppItem.PricebookEntry.Product2.RecordType.Name+'_'+oppItem.PriceBookEntry.Product2.Site__r.Country__c;
                    if(networkType.equals(ordKey)){
                        DARTObject.IDARTObjectOrder ord = mapNetworkOrder.get(networkType);
                        oppItem.Adserver_ID_Order_ID__c = (ord==null?'':ord.getDartId());
                        oppItem.Adserver_Adv_Advertiser_ID__c = (ord==null?'':ord.getOrderAvertiserId());
                        mapOppItemToBeupdated.put(oppItem.Id, oppItem);
                    }
                }
            }

            try{
                //process send lienItem to DFP
                bookingCon.processAndSendLineItem(listOrders.get(0), mapAdvertiser);
                listAds = bookingCon.getListAds();
            }catch(exception e){
                if(!mapOppItemToBeupdated.isEmpty()) update mapOppItemToBeupdated.values();
                responseObj.content = mapOppItemToBeupdated.values()[0];
                responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
                Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
                responseObj.message =  mapErrMsg.get(e.getMessage())!=null? mapErrMsg.get(e.getMessage()) : e.getMessage();
                //record error message as Parent attachment
                LPC_ProductConfiguratorController.generateErrorLogasAttachment(oppItem, DARTLogger.OPPERATION_SUBMIT_ORDER, null, oppItem.PricebookEntry.Product2.RecordType.Name, responseObj.message, e.getStackTraceString());
                return responseObj;
            }

            if(!mapAdverUpsert.isEmpty()) upsert mapAdverUpsert.values();
            if(!mapOppItemToBeupdated.isEmpty()) update mapOppItemToBeupdated.values();

            if(!listAds.isEmpty()){
                for(DARTObject.IDARTObjectAds ads : listAds){
                    if(ads.getDartId() != null){
                        mapOppItemToBeupdated.get(ads.getOppItemID()).Ad_Id__c = ads.getDartId();
                    }
                }
                Database.SaveResult[] results = Database.Update(mapOppItemToBeupdated.values(), false);
            }
            resLineItem =  mapOppItemToBeupdated.values()[0];
            responseObj.statusCode = RemoteResponse.STATUSCODE_OK;
            responseObj.content = resLineItem;

        } catch(Exception ex) {
            responseObj = new RemoteResponse();
            responseObj.statusCode = RemoteResponse.STATUSCODE_ERROR;
            Map<String, String> mapErrMsg = DART6Message.getMapFriendlyMsg();
            responseObj.message =  mapErrMsg.get(ex.getMessage())!=null? mapErrMsg.get(ex.getMessage()) : ex.getMessage();
            //record error message as Parent attachment
            LPC_ProductConfiguratorController.generateErrorLogasAttachment(oppItem, DARTLogger.OPPERATION_SUBMIT_ORDER, null, oppItem.PricebookEntry.Product2.RecordType.Name, responseObj.message, ex.getStackTraceString());
            return responseObj;
        }
        return responseObj;
    }

    /**
     * Get Opportunity Stage Picklist
     * @return List<String>
     */
    @AuraEnabled
    public static List<String> getOppStagePicklist() {
        List<String> options = new List<String>();
        //String opts;
        //Getting The Object's Picklist's Values
        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        //Adding the Picklist Values into An Array
        for(Schema.PicklistEntry f : ple){
           options.add(f.getLabel());
         }
        //Stringifying The Array and Assigning It To A String
        //opts = JSON.serialize(options);
        return options;
    }

    /**
    * Get Product Rate Card
    * @return map<String, list<Rate_Card__c>>
    */
    @AuraEnabled
    public static RemoteResponse getProductRateCard(String jsonProId){
        try{
            Map<String, list<Rate_Card__c>> mpProRateCard = new Map<String, list<Rate_Card__c>>();
            Set<Id> stProId = new Set<Id>();
            stProId.addAll((List<Id>) JSON.deserialize(jsonProId, List<Id>.class));

            List<Rate_Card__c> lstRateCards = (List<Rate_Card__c>)GW_sObject.queryRecords('Rate_Card__c', stProId, 'Product__r.Id');
            System.debug('lstRateCards = ' + lstRateCards);

            for(Rate_Card__c rc: lstRateCards){
                if(mpProRateCard.get(rc.Product__c) == null)mpProRateCard.put(rc.Product__c, new List<Rate_Card__c>());
                mpProRateCard.get(rc.Product__c).add(rc);
            }

            return new RemoteResponse(mpProRateCard);
        }catch(exception e){
            return new RemoteResponse('Error: '+e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    /**
     * To generate Error Log as attachment, then linking to parent record
     * @param : lineItem an Opportunity product record which will be forcasred/booked
     * @param : operation an operation name
     * @param : dartmethod name of dart method 
     * @param : dartVersion stat version of dart
     * @param : msg a message error which generate from any operation failed
     * @param : detail a detail message error which generate from any operation failed
     * @return 
     */
    private static void generateErrorLogasAttachment(OpportunityLineItem lineItem, String operation, String dartmethod, String dartVersion, String msg,String detail) {
        DARTLogger.LogMessage errorLog = new DARTLogger.LogMessage(
                                                        lineItem.Id, 
                                                        operation,
                                                        dartmethod,
                                                        dartVersion,
                                                        DARTLogger.TYPE_ERROR, msg, detail
                                          );
        DARTLogger.getInstance().log(lineItem.OpportunityId, new List<DARTLogger.LogMessage>{errorLog});
    }
	public static Boolean isCalculated = false;
	
	
    @AuraEnabled
    public static RemoteResponse recalculateFromTRACT(ID oppId, String lineItems){
        try{
			//TMP for avoid run recalculate twice 
			if(isCalculated) {
        		RemoteResponse resp = new RemoteResponse();
                resp.statusCode = RemoteResponse.STATUSCODE_OK; 
                resp.message = 'Twice callout';
                return resp;
        	}
        	
        	isCalculated = true;
			
            UTIL_WSC.WSC_Request req;
            UTIL_WSC.WSC_Result res;
            
            List<OpportunityLineItem> lstOppLineItem = (List<OpportunityLineItem>)System.JSON.deserialize(lineItems, List<OpportunityLineItem>.class);
	            
            Opportunity opp = [select NumStatus__c, MemberUnit__r.LineOfBusiness__c, MemberUnit__r.EnableTRACT__c from Opportunity where id =:oppId];
            Boolean isAdSale = opp.MemberUnit__r.LineOfBusiness__c == 'AD';
            
            if (isAdSale) {
            	if(opp.NumStatus__c >= 2) {
            		RemoteResponse resp = new RemoteResponse();
	                resp.statusCode = RemoteResponse.STATUSCODE_CUSTOM; 
	                return resp;
            	}
            	req = UTIL_WSC.getWSC_Request('WSC_Tract.DraftOrderAdSalesCreate');
		        req.init(oppId);
		        res = req.call();
            } else {
            	req = UTIL_WSC.getWSC_Request('WSC_Tract.DraftOrderCreate');
	            req.mAdditionalParams.put('lstLineItem', lstOppLineItem);
	            req.init(oppId);
	            res = req.call();
            }
            if ( res.statusCode == 200 || res.statusCode == 201) {
                //Start update OLI Tract service id
                updateOLITractServiceId(req.mapper.getOutputMap());
                String respBody = res.getFormattedBody();
                RemoteResponse resp = new RemoteResponse();
                resp.statusCode = RemoteResponse.STATUSCODE_OK;
                resp.contents = new List<Object>{respBody, lstOppLineItem}; 
                return resp;
            } else {
                Map<String, Object> response = res.getResponseData() != null && res.getResponseData().containsKey('results')? (Map<String, Object>) res.getResponseData().get('results') : null;
                RemoteResponse resp = new RemoteResponse();
                resp.message = response == null ? res.errorMsg : response.containsKey('error') ? (String) response.get('error') : response.containsKey('message') ? (String) response.get('message') : String.isBlank(res.status) ? res.errorMsg : res.status;
                resp.statusCode = RemoteResponse.STATUSCODE_ERROR;
                return resp;
            }
        }catch(DMLException dmlex){
            return new RemoteResponse(dmlex.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }catch(Exception ex){
            return new RemoteResponse(ex.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }
    
    @AuraEnabled
    public static RemoteResponse doGetAgreementFromTract(Id oppId) {
        Opportunity opp = GW_Opportunity.getRecord(oppId);
        if(String.isBlank(opp.Tract_AgreementId__c)) {
            RemoteResponse resp = WSC_Tract.getTractAgreementId(oppId);
            if (resp.statusCode == RemoteResponse.STATUSCODE_ERROR)  return resp;
            resp.content = GW_Opportunity.getRecord(oppId);
            resp.statusCode = RemoteResponse.STATUSCODE_OK;
            return resp;
        }
        return new RemoteResponse(opp);
    }

    private  static  void updateOLITractServiceId( Map<String,Object> mapRecord) {

        if(!mapRecord.isEmpty() && mapRecord.containskey('order_items')) {
                List<OpportunityLineItem> lstUpdates = new List<OpportunityLineItem>();
                Object orderItems = mapRecord.get('order_items');
                List<Object> lstOrders = (List<Object>)orderItems;

                map<Id, String> mapOLIIdentifier = new map<Id, String>();
                for (integer i = 0; i < lstOrders.size(); i++ ){
                    Map<String,Object> objOrder = (Map<String,Object>)lstOrders.get(i);
                    if( objOrder.containsKey('service_resources')) {
                        Object objSerItem =  objOrder.get('service_resources');
                        List<Object> lstService = (List<Object>)objSerItem;
                        Map<String,Object> objService = (Map<String,Object>)lstService.get(0);
                        if(objService.containsKey('identifier')){
                            String identifier = (String)objService.get('identifier');//'00kxxxxxxxxxxxxxx1491709904752';
                            ID oliID = identifier.left(18);
                            mapOLIIdentifier.put(oliID , identifier);
                        }
                    }
                }

                if (mapOLIIdentifier.isEmpty()) return;
                List<OpportunityLineItem> lstItems = GW_sObject.queryRecords('OpportunityLineItem', new List<String>{'id', 'Tract_ServiceId__c'}, mapOLIIdentifier.keySet());
                for (OpportunityLineItem oli : lstItems ){
                    oli.Tract_ServiceId__c = mapOLIIdentifier.get(oli.id);
                    lstUpdates.add(oli);
                }

                if(!lstUpdates.isEmpty()) {
                    update lstUpdates;
                }
        }
    }

    /*
     * This is updating the OLI
     * */
    @AuraEnabled
    public static string setOppAndOLIValues(ID oppId, String resJSON){

        // generate data from Json to Update opportunity / OLI
        Map<String, Object> mapJSON = (Map<String, Object>) JSON.deserializeUntyped(resJSON);
        String strResult = JSON.serialize(mapJSON.get('results'));
        Map<String, Object> mapResult = (Map<String, Object>) JSON.deserializeUntyped(strResult);
        //Integer orderNum = Integer.valueOf(mapResult.get('order_num'));
        String orderNum = (String) mapResult.get('order_num');
        Integer tractOrderId = Integer.valueOf(mapResult.get('id'));

        list<Object> lstOrderITems = (list<Object>) mapResult.get('order_items');  //JSON can have more then 1 order Item
        if ( lstOrderITems ==  null ) return 'FAILED';

        map<String, Decimal> mapProNameWithSalesprice = getProductNameWithSalePriceFromObjectJSON(lstOrderITems);

        try {
            Opportunity o = [select id,Tract_Order_Number__c from opportunity where id = :oppId];
            o.Tract_OrderId__c = tractOrderId;
            o.Tract_Order_Number__c = orderNum;
            Update o;

            // - update OPLI level
            if ( mapProNameWithSalesprice.isEmpty() ) return 'FAILED';

            List<OpportunityLineItem> oplLst = GW_sObject.queryRecords('OpportunityLineItem', new List<String>{ 'id', 'name', 'OpportunityId', 'product2.Name', 'UnitPrice' },'OpportunityId =' + oppId);
            if ( oplLst.isEmpty() ) return 'FAILED';

            List<OpportunityLineItem> lstOPLItoUpdate = new List<OpportunityLineItem>();
            for (OpportunityLineItem OLI : oplLst){
                if ( mapProNameWithSalesprice.containsKey (OLI.product2.Name) ){
                    OLI.TotalPrice = mapProNameWithSalesprice.get(OLI.product2.Name);
                    lstOPLItoUpdate.add(OLI);
                }
            }
            if ( !lstOPLItoUpdate.isEmpty() ) update lstOPLItoUpdate;

            return 'SUCCESS';

        }
        catch (System.DmlException dmle){
            return dmle.getMessage();
        }
        catch (Exception e) {
            return e.getMessage();
        }
    }
    
    private static map<String,Decimal> getProductNameWithSalePriceFromObjectJSON(list<Object> lstObjectOrderItem){
        map<String,Decimal> mapReturn = new map<String,Decimal>();

        for ( integer i=0; i < lstObjectOrderItem.size(); i++ ){

            String strOrderItemJSON = JSON.serialize(lstObjectOrderItem[i]);
            Map<String, Object> mapOrderItemJSON = (Map<String, Object>) JSON.deserializeUntyped(strOrderItemJSON);
            Decimal Salesprice = (Decimal)mapOrderItemJSON.get('extendedPrice');

            String strProJSON = JSON.serialize(mapOrderItemJSON.get('product'));
            Map<String, Object> mapProJSON = (Map<String, Object>) JSON.deserializeUntyped(strProJSON);
            String ProName =  String.valueOf(mapProJSON.get('name'));

            mapReturn.put(ProName,Salesprice);
    }
        return mapReturn;
    }

    @AuraEnabled
    public static RemoteResponse updateLineItem(Map<String, Object> mLineItem){
        try{
            String sDateStr = (String)mLineItem.get('StartDate');
            List<String> lstDateSplited = sDateStr.split('-');
            Date sDate = Date.newInstance(Integer.valueOf(lstDateSplited[0]),
                                            Integer.valueOf(lstDateSplited[1]),
                                            Integer.valueOf(lstDateSplited[2]));
            OpportunityLineItem opli = new OpportunityLineItem(id= (ID)mLineItem.get('LineItemId'),
                                                                Quantity = (Decimal)mLineItem.get('Quantity'),
                                                                from_Date__c = sDate,
                                                                TotalPrice = (Decimal)mLineItem.get('TotalPrice'));
            update opli;

            return new RemoteResponse('success', RemoteResponse.STATUSCODE_OK);

        }catch(DMLException dml){
            system.debug('======' + dml.getMessage());
            return new RemoteResponse(dml.getDmlMessage(0), RemoteResponse.STATUSCODE_ERROR);
        }catch(Exception ex){
            return new RemoteResponse(ex.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

    /**
    * This method will get logic from IODisplayController
    */
    @AuraEnabled
    public static RemoteResponse generateIO(String oppId){
        System.debug('======oppId'+ oppId);
        try{

            Opportunity opp = getOpportunityById(oppId);
            ApexPages.StandardController generateIOCtrler = new ApexPages.StandardController(opp);
            IODisplayController displayIO = new IODisplayController(generateIOCtrler);

            PageReference createIO = displayIO.createIO();

            Map<String, Object> mReturnIfNoIO = new Map<String, Object>();
            Boolean isNoIO = (createIO == null);

            if(isNoIO){
                mReturnIfNoIO = new Map<String, Object>{'agreementId' => displayIO.agreement.Id,
                                                        'memberUnitId' => displayIO.memberUnit.Id,
                                                        'isDiscountSet' => displayIO.getIsDiscountSet(),
                                                        'mandateNeedsToBeAttached' => displayIO.mandateNeedsToBeAttached,
                                                        'accLanguage' => displayIO.acc.Language_Preference__c};
            }


            RemoteResponse resp = new RemoteResponse('', RemoteResponse.STATUSCODE_OK);
            resp.content = isNoIO ? null : createIO.getUrl();
            resp.contents = new List<Object>{mReturnIfNoIO};
            return resp;
        }catch(DMLException dml){
            return new RemoteResponse(dml.getDmlMessage(0), RemoteResponse.STATUSCODE_ERROR);
        }catch(Exception ex){
            return new RemoteResponse(ex.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }

    }

    @AuraEnabled
    public static RemoteResponse attachRequiredPDFs(String agreementId, String memberUnitId,
                                                    String oppId, String accLanguage,
                                                    Boolean isDiscountSet,
                                                    Boolean mandateNeedsToBeAttached)
    {
        try{

            echosign_dev1__SIGN_Agreement__c agreement = GW_Agreement.getRecord(agreementId);
            MemberUnit__c memberUnit = GW_MemberUnit.getMemberUnitById(memberUnitId);
            Opportunity opp = getOpportunityById(oppId);

            GW_Agreement.attachIO(agreement, memberUnit, opp, isDiscountSet);
            if (mandateNeedsToBeAttached) {
                GW_Agreement.attachMandate(agreement, memberUnit);
            }
            GW_Agreement.attachTAndC(agreement, memberUnit, opp, accLanguage);

            RemoteResponse resp = new RemoteResponse('', RemoteResponse.STATUSCODE_OK);
            resp.content = '/' + agreementId;
            return resp;
        }
        catch(Exception ex){
            return new RemoteResponse(ex.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }

    }

    /**
     * To submit Opportunity record for approval. It's invoked by Request Approval button on sales path screen.
     * https://jira.corp.ebay.com/browse/CD-2234
     * @param: oppId is Opportunity record Id
     * @return RemoteResponse a response to the action
     */
    @AuraEnabled
    public static RemoteResponse requestApproval( String oppId ) {
        try {
            //send Opportunity to Approval Process
            String approvalStatus = WSI_Opportunity.sendForApproval(oppId); 
            //approval process status SUCESS
            if ( approvalStatus.equalsIgnoreCase('OK') ) {
                return new RemoteResponse( approvalStatus, RemoteResponse.STATUSCODE_OK );
            //approval process status ERROR
            } else {
                return new RemoteResponse( approvalStatus, RemoteResponse.STATUSCODE_ERROR );
            }
        } catch (Exception ex) {
            return new RemoteResponse( ex.getMessage(), RemoteResponse.STATUSCODE_ERROR );
        }
    }
    

    /*
    * @GIS-TEAM
    * @18-06-20178
    * @Task #11411 | CD-2540 Sales Path - UEX - Update LDS process component to allow users to change stage & validate
    */
    @AuraEnabled
    public static void updateOppStage(String oppId, String stageName){
        update new Opportunity(Id = oppId, StageName = stageName);
    }

    /**
     * @GIS-TEAM
     * 20-05-2017
     * Collect Product Tags Info
     */
    @AuraEnabled
    public static RemoteResponse getMapProductTags(List<Id> pIds, String textFilter) {
        try {
            /*String whereClause = ' AND Name = \'' + textFilter +'\'';
            Set<Id> parIds = new Set<Id>(pIds);
            RemoteResponse res = new RemoteResponse( 'Success', RemoteResponse.STATUSCODE_OK );
            res.content = getChildrenMapByWhereClause(parIds, 'ProductTags__r', '', whereClause);*/
            RemoteResponse res = new RemoteResponse( 'Success', RemoteResponse.STATUSCODE_OK );
            Map<String, ProductTag__c> mpPt = New Map<String, ProductTag__c>();
            List<ProductTag__c> lstPt = [select Name, Id, Product__c from ProductTag__c where Product__c in :pIds and Name =:textFilter ];
            for(ProductTag__c pt : lstPt){
                mpPt.put(pt.Product__c, pt);
            }
            res.content = mpPt;
            return res;
            
        } catch (Exception ex) {
            return new RemoteResponse( ex.getMessage(), RemoteResponse.STATUSCODE_ERROR );
        }
    }
    
    /**
     * To get Opportunity Product by product tags
     * https://jira.corp.ebay.com/browse/CD-2556
     * @param: lineItems a list of Opportunity Product
     * @param: isMediaSales to tell the method to get only Media Sales Opportunity Product or not
     *          TRUE > return only Opportunity Product which contain child Product Tags with Name 'Media Sales'
     *          FALSE > return all Opportunity Product which does not contain child Product Tags with Name 'Media Sales'
     * @return: list of Opportunity Product
     */
    public static List<OpportunityLineItem> getLineItemByProductTags(List<OpportunityLineItem> lineItems, Boolean isMediaSales) {
        Map<Id, List<OpportunityLineItem>> mProductvsLineItems = new Map<Id, List<OpportunityLineItem>>();

        for (OpportunityLineItem item : lineItems) {
            if (!mProductvsLineItems.containsKey(item.Product2Id)) mProductvsLineItems.put(item.Product2Id, new List<OpportunityLineItem>());
            mProductvsLineItems.get(item.Product2Id).add(item);
        }
        UTIL.log('mProductvsLineItems___xxx: '+mProductvsLineItems);
        
        List<OpportunityLineItem> prod2display = new List<OpportunityLineItem>();
        for (Product2 p2 : [Select Id, InternalBookingEnabled__c, (Select Id, Name From ProductTags__r Where Name = 'Media Sales' limit 1) From Product2 Where ID IN: mProductvsLineItems.keySet()]) {
            if (isMediaSales && !p2.ProductTags__r.isEmpty() && !p2.InternalBookingEnabled__c) {
                prod2display.addAll(mProductvsLineItems.get(p2.Id));
                continue;
            }
            if (!isMediaSales && (p2.ProductTags__r.isEmpty() || (!p2.ProductTags__r.isEmpty() && p2.InternalBookingEnabled__c))) prod2display.addAll(mProductvsLineItems.get(p2.Id));
        }
        
        UTIL.log('addSalesProd2display > '+prod2display + ' isMediaSales ___X: '+ isMediaSales);
        return prod2display;
    }
    
    /**
     * To get only Media Sales Opportunity Product by product tags. Opportunity Product is Media Sales when it contains child Product Tags with Name 'Media Sales'
     * https://jira.corp.ebay.com/browse/CD-2556
     * @param: lineItems a list of Opportunity Product
     * @return: list of Opportunity Product
     */
    public static List<OpportunityLineItem> getMediaSalesProduct(List<OpportunityLineItem> productlines) {
        UTIL.log('getMediaSalesProduct_xxxx ');
        return LPC_ProductConfiguratorController.getLineItemByProductTags(productlines, true);
    }
}