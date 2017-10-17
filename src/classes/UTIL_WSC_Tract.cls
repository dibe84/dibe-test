/**
 * Created by rvannierop on 2/21/2017.
 */
public class UTIL_WSC_Tract {
	//Tract constants
    private static final String STATUS_ACTIVE 				= 'ACTIVE',
        						STATUS_AVAILABLE 			= 'AVAILABLE',
        						STATUS_NOT_AVAILABLE 		= 'NOT_AVAILABLE',
        						TRACT_SYSTEM_PREFIX			= 'TRACT',
								DISCOUNT_TYPE_FLAT 			= 'FLAT',
                                DISCOUNT_TYPE_PERCENTAGE 	= 'PERCENTAGE',
								ONE_TIME_PRODUCT_TYPE 		= 'ONE-TIME';

    public static final String 	ID_SEPARATOR 				= '_',
								LIST_SEPARATOR 				= ';',
    							COMMA_SEPARATOR 			= ',',
    							DOUBLE_QUOTE_SEPARATOR		= '"',
    							DOT_SEPARATOR				= '.',
    							BACK_SLASH_SEPARATOR		= '/',
    							SPACE_SEPARATOR				= '';

    public static Map<String, Id> getTractIdSFDCIdMap(List<SObject> sfdcRecordsWithIds) {
        Map<String, Id> tractIdSFDCIdMap = new Map<String, Id>();
        for (SObject so : sfdcRecordsWithIds) {
            String tractId = (String) so.get('Tract_Id__c');
            Id sfdcId = (Id) so.get('Id');
            tractIdSFDCIdMap.put(tractId, sfdcId);
        }
        return tractIdSFDCIdMap;
    }

    public static Datetime parseTractDatetimeString(String dateTimeString) {
        if (dateTimeString == null) return null;
        Integer year=0,month=1,day=2,hour=3,minute=4,second=5;
        List<String> dateAndTimeSeperated = dateTimeString.split('[-T:.+]');
        Datetime result = null;
        if (dateAndTimeSeperated.size() >= 6 ) {
             result = Datetime.newInstanceGmt(
                    Integer.valueOf(dateAndTimeSeperated[year]),
                    Integer.valueOf(dateAndTimeSeperated[month]),
                    Integer.valueOf(dateAndTimeSeperated[day]),
                    Integer.valueOf(dateAndTimeSeperated[hour]),
                    Integer.valueOf(dateAndTimeSeperated[minute]),
                    Integer.valueOf(dateAndTimeSeperated[second])
            );
        }
        return result;
    }

    public static Decimal parseTractPercentage(Decimal percentage) {
        return (percentage == null) ? percentage : percentage * 100;
    }
    
    /**
     * To convert string to date. String can be  01-08-2017 or 01/08/2017
     */
    public static Date convertDate(String strvalue) {
        if ( String.isBlank(strvalue) ) return null;
        
        if (strvalue.contains('-')) {
            String[] listdates = strvalue.split('-');
            return Date.newInstance(Integer.valueOf(listdates[2]), Integer.valueOf(listdates[1]), Integer.valueOf(listdates[0]));
        } else if (strvalue.contains(BACK_SLASH_SEPARATOR)) {
            return Date.parse(strvalue);
        }
        return null;
    }
    
    public class ProductSync {

        public Map<String, Product2> catalystProductMap = new Map<String, Product2>(); // Parents and childs
        public Map<String, Pricebook2> catalystExternalIdPricebookMap = new Map<String, Pricebook2>(); // Product Categories of TRACT
        public Map<String, PricebookEntry> catalystStdPricebookEntriesMap = new Map<String, PricebookEntry>(); // Child products (incl TRACT price option) with currency and amount.
        public Map<String, PricebookEntry> catalystCustomPricebookEntriesMap = new Map<String, PricebookEntry>();

        private Product2 catalystParentProduct;
        private Product2 catalystChildProduct;
        private PriceBook2 catalystPricebook;

        private Map<String, Object> tractPriceListMap;
        private Map<String, Object> tractProductMap;
        private Map<String, Object> tractPriceMap;
        private Map<String, Object> tractPriceRangeMap;
        private Integer numberOfPriceRanges;

        private Map<String, Id> tractIdPBIdMap;
        private Map<String, Id> tractIdProductIdMap;

        private String priceListId;
        private Map<String, ProductTag__c> mProductTags = new Map<String, ProductTag__c>();
		//private Id stdPbId = UTIL.getStdPriceBook().Id;
		private Id stdPbId = UTIL.getStdPricebookId();
		
		public ProductSync(){}
		
		public ProductSync(String currentTractListId, List<Object> tractProducts) {
			this.priceListId = currentTractListId;
			// Collect all master and child product and pricebookentries.
			collectProductsAndPricebookEntries(tractProducts);
		}
		
        private void collectProductsAndPricebookEntries(List<Object> tractProducts) {
            for (Object tractProduct : tractProducts) {
                collectProductsAndPricebookEntriesPerPricebook(tractProduct);
            }
        }
		
        private void collectProductsAndPricebookEntriesPerPricebook(Object tractProduct) {
            tractProductMap = (Map<String, Object>) tractProduct;
            collectMasterProduct();
            collectChildProductsAndPBEntries();
        }
        
        private void collectChildProductsAndPBEntries() {
            //For each Tract price object create child products and pricebookentries.
            List<Object> tractPrices = (List<Object>) tractProductMap.get('prices');
            for (Object tractPrice : tractPrices) {
                tractPriceMap = (Map<String, Object>) tractPrice;
                List<Object> priceRangeObjects = (List<Object>)tractPriceMap.get('price_ranges');
                priceRangeObjects = (priceRangeObjects == null) ? new List<Object>() : priceRangeObjects;
                numberOfPriceRanges = priceRangeObjects.size();
                for (Object priceRangeObject : priceRangeObjects) {
                    tractPriceRangeMap = (Map<String, Object>) priceRangeObject;
                    collectChildProductsAndPBEntriesPerTractPriceRange();
                }
            }
        }

        private void collectChildProductsAndPBEntriesPerTractPriceRange() {

            catalystChildProduct = new Product2();
            List<PricebookEntry> pbes = new List<PricebookEntry>(); //Standard and custom

            //--Product
            String parentProductName = (String) tractProductMap.get('name');
            String parentProductId = (String) tractProductMap.get('id');
            String parentProductType = (String) tractProductMap.get('product_type');
            String parentState = (String) tractProductMap.get('state');
            String parentSKU = (String) tractProductMap.get('sku');
			String productdescription = (String) tractProductMap.get('description');
            String shortDescription = (String) tractProductMap.get('short_description');

            //--Price
            String priceType = (String) tractPriceMap.get('price_type');//price_type
            String priceId = (String) tractPriceMap.get('id');//id
            String fromDateString = (String) tractPriceMap.get('from_date');//from_date
            Datetime fromDatetime = UTIL_WSC_Tract.parseTractDatetimeString(fromDateString);
            String recurrencePeriod = (String) tractPriceMap.get('recurrence_period');//recurrence_period

            Map<String, Object> priceCategoryMap = ( tractPriceMap.get('price_category') == null) ? new Map<String, Object>() : (Map<String, Object>) tractPriceMap.get('price_category');

            //--PriceCategory
            String priceCategoryStatus = (String) priceCategoryMap.get('status');
            String priceCategoryName = (String) priceCategoryMap.get('name');
            String priceCategoryId = (String) priceCategoryMap.get('id');

            //--PriceRange
            Double price = (Double) tractPriceRangeMap.get('price');
            String priceRangeId = (String) tractPriceRangeMap.get('id');
            Decimal quantityFrom = (Decimal) tractPriceRangeMap.get('quantity_begin_range');//id
            String currencyISOCode =  (String) tractPriceRangeMap.get('currency_code');

            String childProductTractId = getChildProductTractId(parentProductId, priceId, priceRangeId);
            Boolean isActiveInTract = isChildProductActive(parentState, fromDateString, priceCategoryStatus);

            catalystChildProduct = new Product2(
                    Name =  getChildProductName(parentProductName, priceType, recurrencePeriod, quantityFrom),
                    Tract_ParentId__c = parentProductId,
                    Tract_ProductType__c = parentProductType,
                    Tract_SKU__c = parentSKU,
                    Tract_RecurrencePeriod__c = recurrencePeriod,
                    Tract_QuantityFrom__c = quantityFrom,
                    Tract_ValidFromDateTime__c = fromDatetime,
                    Tract_Id__c = childProductTractId,
                    Tract_PriceId__c = priceId,
                    Tract_PriceRangeId__c = priceRangeId,
                    IsActive = isActiveInTract, 
					Description = productdescription,
                    Short_Description__c = shortDescription
            );

            PricebookEntry stdPbe = new PricebookEntry(
                    Pricebook2Id = stdPbId,
                    CurrencyIsoCode = currencyISOCode,
                    Tract_ProductId__c = childProductTractId,
                    Tract_Id__c = getPricebookEntryTractId(priceListId, childProductTractId) + '_std',
                    UnitPrice = price,
                    isActive = isActiveInTract
            ); 

            PricebookEntry customPbe = new PricebookEntry(
                    CurrencyIsoCode = currencyISOCode,
                    Tract_ProductId__c = childProductTractId,
                    Tract_PriceListId__c = priceListId,
                    Tract_Id__c = getPricebookEntryTractId(priceListId, childProductTractId),
                    UnitPrice = price,
                    isActive = isActiveInTract
            );

            catalystProductMap.put(catalystChildProduct.Tract_Id__c, catalystChildProduct );
            if (catalystStdPricebookEntriesMap.get(stdPbe.Tract_Id__c) != null ) {
                UTIL.log('Duplicate found: ' + stdPbe.Tract_Id__c);
            }
            catalystStdPricebookEntriesMap.put(stdPbe.Tract_Id__c, stdPbe);
            catalystCustomPricebookEntriesMap.put(customPbe.Tract_Id__c, customPbe);
        }

        private String getChildProductTractId(String parentProductId, String priceId, String priceRangeId) {
            return String.join(new List<String> {parentProductId, priceId, priceRangeId}, ID_SEPARATOR);
        }

        private String getPricebookEntryTractId(String priceListId, String childProductTractId) {
            return String.join(new List<String> {childProductTractId, priceListId}, ID_SEPARATOR);
        }

        private String getChildProductName(String parentProductName, String priceType, String recurrencePeriod, Decimal quantityFrom ) {
            Boolean isOneTimeProdType = ONE_TIME_PRODUCT_TYPE.equals(priceType.toUpperCase());	
	        String productFlavor = ' ' + (isOneTimeProdType ? '' : priceType);
	        productFlavor += isOneTimeProdType ? ' [' + ONE_TIME_PRODUCT_TYPE + ']' : ( String.isBlank(recurrencePeriod) ? '' : ' [' + recurrencePeriod.capitalize() + ']');
            productFlavor += (numberOfPriceRanges == 1) ? '' : ' Q [' + quantityFrom + ']';
            return parentProductName + productFlavor;
        }


        private Boolean isChildProductActive(String parentState, String fromDate, String priceCategoryStatus) {
            Datetime fromDatetime = parseTractDatetimeString(fromDate);
            return (parentState == STATUS_AVAILABLE) && (fromDatetime <= Datetime.now()) && (priceCategoryStatus == STATUS_ACTIVE);
        }

        private void collectMasterProduct() {
            catalystParentProduct = mapToParentProduct(tractProductMap);
            catalystProductMap.put(catalystParentProduct.Tract_Id__c, catalystParentProduct);
        }

        private Product2 mapToParentProduct (Map<String, Object> tractProduct) {
            String name = (String) tractProduct.get('name');
            String tractId = (String) tractProduct.get('id');
            String state = (String) tractProduct.get('state');
            String productType = (String) tractProduct.get('product_type');
			String productdescription = (String) tractProduct.get('description');
            String shortDescription = (String) tractProduct.get('short_description');
            String serviceResourceCategoryId = null;

            Map<String, Object> serviceResourceCategory = (Map<String, Object>) tractProduct.get('service_resource_category');
            if (serviceResourceCategory != null) {
                serviceResourceCategoryId = (String) serviceResourceCategory.get('id');
            }
			
            Boolean isActive =  (state == UTIL_WSC_TRACT.STATUS_AVAILABLE);
            Product2 product = new Product2(
                    Name = name,
                    Tract_Id__c = tractId,
                    isActive = isActive,
                    Tract_NeedsRelationsSync__c = true,
                    Tract_ProductType__c = productType,
                    Tract_ServiceResourceCategoryId__c = serviceResourceCategoryId, 
					Description = productdescription,
                    Short_Description__c = shortDescription
            );
            
            //Link Product Tag to their Parent Product
            List<Object> productTags = (List<Object>) tractProduct.get('product_tags');
            if ( productTags != null && !productTags.isEmpty() ) addProductTagsToParentProduct(productTags, new Product2(Tract_Id__c = tractId));
            
            return product;
        }
        
        /**
         * Add available Product Tag to Parent Product
         * @param: productTagObjects is a list of product tag to be created/updated
         * @param: parentProduct is a Parent Product (a product is a parent-product if its tract parent id lookup is empty)
         * @return
         */
        private void addProductTagsToParentProduct(List<Object> productTagObjects, Product2 parentProduct) {
            for (Object o : productTagObjects) {
                Map<String, Object> productTagMap = (Map<String, Object>) o;
                String productTagName = (String) productTagMap.get('name');
                String productTagDescription = (String) productTagMap.get('description');
                String productTagId = (String) productTagMap.get('id');
                
                ProductTag__c productTag = new ProductTag__c();
                productTag.Name = productTagName;
                productTag.Product__r = parentProduct; //link to Parent Product by Product External ID
                productTag.Description__c = productTagDescription;
                productTag.ProductTag_External_ID__c = parentProduct.Tract_Id__c + ID_SEPARATOR + productTagId;
                mProductTags.put(productTag.ProductTag_External_ID__c, productTag);
            }
        }

        public void commitAll() {
        	//upsert product
            upsert catalystProductMap.values() Tract_Id__c;
            
            //link product tags to parent product
            upsert mProductTags.values() ProductTag_External_ID__c;
			
			catalystExternalIdPricebookMap = new Map<String, Pricebook2>([Select Id, Tract_Id__c From PriceBook2 Where Tract_Id__c =: priceListId]);
            system.debug('catalystExternalIdPricebookMap = ' + catalystExternalIdPricebookMap);
            
            tractIdPBIdMap = UTIL_WSC_Tract.getTractIdSFDCIdMap(catalystExternalIdPricebookMap.values());
            tractIdProductIdMap = UTIL_WSC_Tract.getTractIdSFDCIdMap(catalystProductMap.values());
            
            system.debug('tractIdPBIdMap = ' + tractIdPBIdMap);
            system.debug('tractIdProductIdMap = ' + tractIdProductIdMap);

            for (PricebookEntry pbe : catalystStdPricebookEntriesMap.values()) {
                pbe.Product2Id = tractIdProductIdMap.get(pbe.Tract_ProductId__c);
            }

            for (PricebookEntry pbe : catalystCustomPricebookEntriesMap.values()) {
                pbe.Pricebook2Id = tractIdPBIdMap.get(pbe.Tract_PriceListId__c);
                pbe.Product2Id = tractIdProductIdMap.get(pbe.Tract_ProductId__c);
            }

            List<Product2> productsToUpdate = new List<Product2>();
            for (Product2 p : catalystProductMap.values()) {
                if (p.Tract_ParentId__c != null) {
                    Id parentSFId = tractIdProductIdMap.get(p.Tract_ParentId__c);
                    p.Parent__c = parentSFId;
                    productsToUpdate.add(p);
                }
            }

            update productsToUpdate;

           Map<String, Id> mPBProd = new Map<String, Id>();//To map pb+prod Id with pricebookentry Id
            Map<Id, PricebookEntry> allTractPbes = new Map<Id, PricebookEntry>([SELECT Id, Tract_Id__c, Pricebook2Id, Pricebook2.IsStandard, Product2Id FROM PricebookEntry WHERE Tract_Id__c <> null]);

            for (Id pbeId : allTractPbes.keySet()) {
                PricebookEntry pbe = allTractPbes.get(pbeId);
                mPBProd.put((pbe.Pricebook2Id+ID_SEPARATOR+pbe.Product2Id), pbe.Id);
            }

            List<PricebookEntry> allPBEToUpsert = new List<PricebookEntry>();
            allPBEToUpsert.addAll(catalystStdPricebookEntriesMap.values());
            allPBEToUpsert.addAll(catalystCustomPricebookEntriesMap.values());

            for (PricebookEntry pbe : allPBEToUpsert) pbe.Id = mPBProd.get((pbe.Pricebook2Id+ID_SEPARATOR+pbe.Product2Id));
			
            upsert catalystStdPricebookEntriesMap.values();
            upsert catalystCustomPricebookEntriesMap.values();
        }
	}//End ProductSync
    
    public class PriceBookSync {
    	public Map<String, Pricebook2> catalystExternalIdPricebookMap = new Map<String, Pricebook2>();
    	private Map<String, Object> tractPriceListMap;
    	
    	public PriceBookSync(List<Object> tractPriceListObjects) {
            for (Object tractPriceListObject : tractPriceListObjects) {
            	tractPriceListMap = (Map<String, Object>) tractPriceListObject;
               	addPriceListToPricebookMap(tractPriceListMap, catalystExternalIdPricebookMap);
            }
        }
        
        private void addPriceListToPricebookMap(Map<String, Object> tractPriceListMap, Map<String, Pricebook2> pricebookMap) {
            String name = (String) tractPriceListMap.get('name');
            String tractId = (String) tractPriceListMap.get('id');

            Pricebook2 pb = new Pricebook2 (
                    Name = name,
                    IsActive = true,
                    Tract_Id__c = tractId
            );

            pricebookMap.put(tractId, pb);
        }
        
        public void commitAll() {
            upsert catalystExternalIdPricebookMap.values() Tract_Id__c;
        }
    }//End Price Book Sync

    public class DiscountSync {

        private Map<String, List<Discount__c>> discountsToUpdateMap = new Map<String, List<Discount__c>>();
        private List<Discount__c> existingDiscounts;

        private List<Discount__c> existingDiscountsPerTractDiscount;
        private List<Discount__c> discountsToUpdatePerTractDiscount;

        private Map<String, Object> discountMap;

        private String tractDiscountId;
        private String tractDiscountName;
        private String tractDiscountType;
        private Decimal tractDiscountPercentage;
        private Decimal tractDiscountAmount;
        private String tractDiscountCurrencyISOCode;

        private String discountName;
        private Decimal discountPercentage;


        public DiscountSync(List<Object> discountObjects) {

            existingDiscounts = GW_sObject.queryRecords('Discount__c', 'Tract_DiscountId__c <> null');

            for (Discount__c existingDiscount : existingDiscounts) {
                existingDiscountsPerTractDiscount = discountsToUpdateMap.get(existingDiscount.Tract_DiscountId__c);
                existingDiscountsPerTractDiscount = (existingDiscountsPerTractDiscount == null) ? new List<Discount__c>() : existingDiscountsPerTractDiscount;
                existingDiscountsPerTractDiscount.add(existingDiscount);
                discountsToUpdateMap.put(existingDiscount.Tract_DiscountId__c, existingDiscountsPerTractDiscount);
            }

            for (Object discountObject : discountObjects) {
                discountMap = (Map<String, Object>) discountObject;
                parseDiscountMap();
                discountsToUpdatePerTractDiscount = discountsToUpdateMap.get(tractDiscountId);
                discountsToUpdatePerTractDiscount = (discountsToUpdatePerTractDiscount == null) ? new List<Discount__c>() : discountsToUpdatePerTractDiscount;
                for(Discount__c discount : discountsToUpdatePerTractDiscount) {
                    discount.Name = getDiscountName(discount.Tract_ResourceIdentifier__c);
                    discount.CurrencyIsoCode = getCurrencyIsoCode(discount.CurrencyIsoCode);
                    discount.Percentage__c = discountPercentage;
                    discount.Amount__c = tractDiscountAmount;
                }
            }
        }

        private void parseDiscountMap() {
            tractDiscountId = (String) discountMap.get('id');
            tractDiscountName = (String) discountMap.get('name');
            tractDiscountType = (String) discountMap.get('discount_type');
            tractDiscountPercentage = (Decimal) discountMap.get('percentage');
            tractDiscountAmount = (Decimal) discountMap.get('amount');
            tractDiscountCurrencyISOCode = (String) discountMap.get('currency_code');

            discountPercentage = UTIL_WSC_Tract.parseTractPercentage(tractDiscountPercentage);
        }

        private String getDiscountName(String resourceIdentifier) {
            return (tractDiscountName + ' (' + getTypeNamePart() + ')' + ' : ' + resourceIdentifier).left(80);
        }

        private String getTypeNamePart() {
            String typeNamePart = '';
            if (tractDiscountType == UTIL_WSC_Tract.DISCOUNT_TYPE_FLAT) {
                typeNamePart = tractDiscountAmount + ' ' + tractDiscountCurrencyISOCode;
            }
            else if (tractDiscountType == UTIL_WSC_Tract.DISCOUNT_TYPE_PERCENTAGE) {
                typeNamePart = discountPercentage.intValue() + '%';
            }
            return typeNamePart;
        }

        private String getCurrencyIsoCode(String currencyIsoCode) {
            return (tractDiscountCurrencyISOCode != null) ? tractDiscountCurrencyISOCode : currencyIsoCode;
        }

        public void commitAll() {

            List<Discount__c> allDiscountList = new List<Discount__c>();
            for (String tractDiscountIdKey : discountsToUpdateMap.keySet()) {
                allDiscountList.addAll(discountsToUpdateMap.get(tractDiscountIdKey));
            }

            update allDiscountList;
        }
    }

    public static void syncProductRelations(Product2 product, List<Object> tractProductRelationObjects) {
        List<ProductRelation__c> productRelations = new List<ProductRelation__c>();
        List<ProductRelation__c> existingProductRelations = GW_ProductRelation.getListFromRelated(product.Id);

        Map<String, ProductRelation__c> prsToInsert = new Map<String, ProductRelation__c>();
        Map<String, ProductRelation__c> prsToUpdate = new Map<String, ProductRelation__c>();

        //First assume all product relations are inactive.
        for (ProductRelation__c pr : existingProductRelations) {
            pr.isActive__c = false;
            prsToUpdate.put(pr.Tract_Id__c, pr);
        }

        for (Object tractProductRelationObject : tractProductRelationObjects) {

            Map<String, Object> productRelation = (Map<String, Object>) tractProductRelationObject;
            Map<String, Object> childProductObject = (Map<String, Object>) productRelation.get('product');

            String childProductId = (String) childProductObject.get('id');

            List<Product2> childProductResults = (List<Product2>) GW_sObject.queryRecords('Product2', 'Tract_Id__c = \'' + childProductId + '\'');

            if (!childProductResults.isEmpty()) {
                Product2 childProduct = childProductResults.get(0);

                ProductRelation__c pr = new ProductRelation__c(
                        isActive__c = true, //As they are delivered by track they are active.
                        Tract_Id__c = (String) productRelation.get('id'),
                        Type__c = (String) productRelation.get('product_relation_type'),
                        Parent__c = product.Id,
                        Child__c = childProduct.Id
                );
                ProductRelation__c existingPr = prsToUpdate.get(pr.Tract_Id__c);
                if (existingPr != null && existingPr.Id != null) {
                    pr.Id = existingPr.Id;
                    prsToUpdate.put(pr.Tract_Id__c, pr);
                }
                else{
                    prsToInsert.put(pr.Tract_Id__c, pr);
                }
            }
        }
        product.Tract_NeedsRelationsSync__c = false;
        UTIL_WSC.doInsert((List<sObject>) prsToInsert.values());
        UTIL_WSC.doUpdate((List<sObject>) prsToUpdate.values());
        UTIL_WSC.doUpdate(product);
    }

    public static void syncProductDiscountRelations(Product2 product, List<Object> tractDiscountCodeObjects) {
        List<ProductDiscountRelation__c> productRelations = new List<ProductDiscountRelation__c>();
        List<ProductDiscountRelation__c> existingProductDiscountRelations = GW_ProductDiscountRelation.getListFromRelated(product.Id);

        Map<String, ProductDiscountRelation__c> pdrsToInsert = new Map<String, ProductDiscountRelation__c>();
        Map<String, ProductDiscountRelation__c> pdrsToUpdate = new Map<String, ProductDiscountRelation__c>();

        //First assume all product relations are inactive.
        for (ProductDiscountRelation__c pdr : existingProductDiscountRelations) {
            pdr.isActive__c = false;
            pdrsToUpdate.put(pdr.Tract_Id__c, pdr);
        }

        for (Object tractDiscountCodeObject : tractDiscountCodeObjects) {

            Map<String, Object> productDiscountCode = (Map<String, Object>) tractDiscountCodeObject;
            String discountCodeId = (String) productDiscountCode.get('id');
            List<Discount__c> discountCodeResults = (List<Discount__c>) GW_sObject.queryRecords('Discount__c', 'Tract_CodeId__c = \'' + discountCodeId + '\'');

            for (Discount__c discount : discountCodeResults) {
                ProductDiscountRelation__c pdr = new ProductDiscountRelation__c(
                        isActive__c = true, //As they are delivered by track they are active.
                        Tract_Id__c = product.Tract_Id__c + '_' + discount.Tract_ResourceId__c ,
                        Product__c = product.Id,
                        Discount__c = discount.Id
                );
                ProductDiscountRelation__c existingPdr = pdrsToUpdate.get(pdr.Tract_Id__c);
                if (existingPdr != null && existingPdr.Id != null) {
                    pdr.Id = existingPdr.Id;
                    pdrsToUpdate.put(pdr.Tract_Id__c, pdr);
                }
                else{
                    pdrsToInsert.put(pdr.Tract_Id__c, pdr);
                }
            }
        }
        product.Tract_NeedsDiscountRelationsSync__c = false;
        UTIL_WSC.doInsert((List<sObject>) pdrsToInsert.values());
        UTIL_WSC.doUpdate((List<sObject>) pdrsToUpdate.values());
        UTIL_WSC.doUpdate(product);
    }

    public static void syncDiscountCodes( Discount__c discount, List<Object> tractDiscountCodeObjects) {
        if (tractDiscountCodeObjects.size() > 1) UTIL.throwError('More than one DiscountCode found for the same DiscountResource');
        for (Object tractDiscountCodeObject : tractDiscountCodeObjects) {
            Map<String, Object> tractDiscountCodeMap = (Map<String, Object>) tractDiscountCodeObject;
            String discountCodeId = (String) tractDiscountCodeMap.get('id');
            String discountCodeStatus = (String) tractDiscountCodeMap.get('status');
            Boolean isActive = (discountCodeStatus != null && discountCodeStatus == UTIL_WSC_Tract.STATUS_ACTIVE);
            String validFromSring = (String) tractDiscountCodeMap.get('valid_from');
            String validToSring = (String) tractDiscountCodeMap.get('valid_to');
            String discountCodeName = (String) tractDiscountCodeMap.get('name');

            Map<String, Object> discountMap = (Map<String, Object>) tractDiscountCodeMap.get('discount');
            String discountId = (String) discountMap.get('id');

            Map<String, Object> discountChargeCategoryMap = (Map<String, Object>) tractDiscountCodeMap.get('discount_charge_category');
            String chargeCategoryName = (String) discountChargeCategoryMap.get('name');
            String chargeCategoryType = (String) discountChargeCategoryMap.get('charge_category_type');

            discount.ChargeCategory__c = chargeCategoryName;
            discount.ChargeCategoryType__c = chargeCategoryType;
            discount.IsActive__c = isActive;
            discount.ValidFrom__c = UTIL_WSC_Tract.parseTractDatetimeString(validFromSring);
            discount.ValidTo__c = UTIL_WSC_Tract.parseTractDatetimeString(validToSring);
            discount.Tract_CodeId__c = discountCodeId;
            discount.Tract_DiscountId__c = discountId;
            discount.Tract_NeedsCodeSync__c = FALSE;

            UTIL_WSC.doUpdate(discount);
        }
    }

    public class DiscountResourceSync {

        Map<String, Discount__c> discountsToUpsertMap = new Map<String, Discount__c>();

        public DiscountResourceSync(List<Object> tractDiscountResourceObjects) {
            //For each product create a master product, collect pricebooks and child products and pricebookentries.
            initExistingDiscountsAsInactive();
            for (Object tractDiscountResource : tractDiscountResourceObjects) {
                collectDiscounts(tractDiscountResource);
            }
        }

        private void initExistingDiscountsAsInactive() {
            List<Discount__c> existingDiscounts = (List<Discount__c>) GW_sObject.queryRecords('Discount__c', 'Tract_ResourceId__c <> null');

            for (Discount__c d : existingDiscounts) {
                d.isActive__c = false;
                discountsToUpsertMap.put(d.Tract_ResourceId__c, d);
            }
        }

        private void collectDiscounts(Object tractDiscountResource) {
            Map<String, Object> tractDiscountResourceMap = (Map<String, Object>) tractDiscountResource;
            String tractDiscountStatus = (String) tractDiscountResourceMap.get('status');
            String tractId = (String) tractDiscountResourceMap.get('id');
            String tractIdentifier = (String) tractDiscountResourceMap.get('identifier');
            tractDiscountStatus = (tractDiscountStatus == null) ? '' : tractDiscountStatus.toUpperCase();
            Boolean isActive = tractDiscountStatus == UTIL_WSC_Tract.STATUS_AVAILABLE;
            Discount__c existingDiscount = discountsToUpsertMap.get(tractId);
            Discount__c discount = new Discount__c(
                    Name = tractIdentifier,
                    Tract_ResourceId__c = tractId,
                    Tract_ResourceIdentifier__c = tractIdentifier,
                    isActive__c = isActive,
                    Tract_NeedsCodeSync__c = TRUE
            );
            if (existingDiscount != null){
                discount.Id = existingDiscount.Id;
                discount.Name = existingDiscount.Name;
            }
            discountsToUpsertMap.put(discount.Tract_ResourceId__c, discount);
        }

        public void commitAll() {
            upsert discountsToUpsertMap.values() Tract_ResourceId__c;
        }

    }//End
	
	//TRACT Service
    public class TRACTServiceSync {
        //map tract service external Id and Tract Service instance object
        Map<String, TRACT_Service__c> mTractServices = new Map<String, TRACT_Service__c>();
        //map tract account number with list of tract services
        Map<String, List<TRACT_Service__c>> mTractaccIDvsServices = new Map<String, List<TRACT_Service__c>>();
        //map tract account number with list of tract services
        Map<String, List<TRACT_Service__c>> mOpportunityIDvsServices = new Map<String, List<TRACT_Service__c>>();
        //map Parent Service with Child
        Map<String, String> mChildParentServices = new Map<String, String>();
        //map service and next services
        Map<String, String> mServiceVsNextServices = new Map<String, String>();
        //map service and previous service
        Map<String, String> mServiceVsPrevServices = new Map<String, String>();

        public TRACTServiceSync(List<List<String>> parsedCSV) {
            //generate map of csv column name with its value
            List<Map<String, String>> mHeaderVsValue = csv2map(parsedCSV) ;
            
            //loop throught csv to generate tract invoice sobject
            for (Map<String, String> mservice : mHeaderVsValue) {
                
                String billingAccount       = mservice.get('Billing Account ID');
                if (String.isBlank(billingAccount)) continue;

                //tract service
                String servicename          = mservice.get('Service ID');
                String currency_iso_code    = mservice.get('isocode');
                String line_item_id         = mservice.get('line item');
                String description          = mservice.get('Description');
                String status               = mservice.get('Status');
                String recurrence           = mservice.get('Recurrence');
               
                String parent_service       = mservice.get('Parent Service');
                String next_service         = mservice.get('Next Service ID');
                String opportunityId        = mservice.get('Opportunity ID');
				String terminationReason    = mservice.get('Termination Reason');

                Decimal amount              = String.isBlank(mservice.get('Amount')) ? null : Decimal.valueOf(mservice.get('Amount'));

                Integer quantity            = String.isBlank(mservice.get('Quantity')) ? 0 : Integer.valueOf(mservice.get('Quantity'));
                Integer renewal_count       = String.isBlank(mservice.get('Renewal Count')) ? 0 : Integer.valueOf(mservice.get('Renewal Count'));

                Date commitment_end_date    = String.isBlank(mservice.get('Commitment End Date')) ? null : convertDate(mservice.get('Commitment End Date'));
                Date start_date             = String.isBlank(mservice.get('Start Date')) ? null : convertDate(mservice.get('Start Date'));
                Date end_date               = String.isBlank(mservice.get('End Date')) ? null : convertDate(mservice.get('End Date'));
                Date status_date            = String.isBlank(mservice.get('Status Date')) ? null : convertDate(mservice.get('Status Date'));
                String adId 				= String.isBlank(mservice.get('Service Identifier')) ? null : mservice.get('Service Identifier').split('_')[1]; // networkid_adid Service Identifier
                String type 				= String.isBlank(mservice.get('Type')) ? null : mservice.get('Type');
                String tag 				= String.isBlank(mservice.get('Tags')) ? null : mservice.get('Tags');
                String change_service 	= String.isBlank(mservice.get('Change Service Type')) ? null : mservice.get('Change Service Type');
                String previous_service 	= String.isBlank(mservice.get('Change Service - Previous Service')) ? null : mservice.get('Change Service - Previous Service');

                //create tract invoice instance object
                TRACT_Service__c tservice   = new TRACT_Service__c(
                                        Name                        = servicename,
                                        CurrencyIsoCode             = currency_iso_code,
                                        Amount__c                   = amount,
                                        Commitment_End_Date__c      = commitment_end_date,
                                        End_Date__c                 = end_date,
                                        //Opportunity_Line_Item_ID__c = line_item_id,
                                        Quantity__c                 = quantity,
                                        Recurrence__c               = recurrence,
                                        Renewal_Count__c            = renewal_count,
                                        Start_Date__c               = start_date,
                                        Status__c                   = status,
                                        Status_Date__c              = status_date,
                                        External_Id__c              = servicename,
										TerminationReason__c        = terminationReason,
										AdId__c						= adId,
										Type__c 					= type,
										Tags__c						= tag,
										Change_Service_Type__c		= change_service
                                    );
                //Temporary fix for report not returning description
                if (!String.isEmpty(description)) tservice.Description__c = description;
                                    
                //map Billing Account with list of Services
                if ( !mTractaccIDvsServices.containsKey(billingAccount) ) mTractaccIDvsServices.put(billingAccount, new List<TRACT_Service__c>());
                mTractaccIDvsServices.get(billingAccount).add(tservice);
                
                
                //map Opportunity Id with list services
                if ( String.isNotBlank(opportunityId) ) {
                    if ( !mOpportunityIDvsServices.containsKey(opportunityId) ) mOpportunityIDvsServices.put(opportunityId, new List<TRACT_Service__c>());
                    mOpportunityIDvsServices.get(opportunityId).add(tservice);
                }
                
                //map services with next services Id
                if (String.isNotBlank(next_service)) mServiceVsNextServices.put(servicename, next_service);
                
                //map Service with thier Parent
                if (String.isNotBlank(parent_service)) mChildParentServices.put(servicename, parent_service);
                
                //map Service with thier Parent
                if (String.isNotBlank(previous_service)) mServiceVsPrevServices.put(servicename, previous_service);
            }
        }

        public void commitAll() {
            //link invoice to billing account
            for (Account acc : [select Id, Tract_AccountId__c, CurrencyISOCode from Account where Tract_AccountId__c IN: mTractaccIDvsServices.keySet()]) {
                for (TRACT_Service__c tservice : mTractaccIDvsServices.get(acc.Tract_AccountId__c)) {
                    tservice.Billing_Account__c = acc.Id;
                    tservice.CurrencyIsoCode = acc.CurrencyISOCode;
                    mTractServices.put(tservice.External_Id__c, tservice);
                }
            }
            
            
            //link service with Opportunity
            //due to csv return sometime with Salesforce OppID and sometime is tract order Id, we need to query them from DB
            for (Opportunity opp : [Select Id, Tract_Order_Number__c From Opportunity Where Id IN: mOpportunityIDvsServices.keySet() OR Tract_Order_Number__c IN: mOpportunityIDvsServices.keySet()]) {
                List<TRACT_Service__c> tservices = mOpportunityIDvsServices.containsKey(opp.Id) ? mOpportunityIDvsServices.get(opp.Id) : ( mOpportunityIDvsServices.get(opp.Tract_Order_Number__c) == null ? new List<TRACT_Service__c>() : mOpportunityIDvsServices.get(opp.Tract_Order_Number__c)) ;
                for (TRACT_Service__c ts : tservices) {
                    if (!mTractServices.containsKey(ts.External_Id__c)) continue;
                    ts.Opportunity__c = opp.Id;
                    mTractServices.put(ts.External_Id__c, ts);
                }
            }
            
            //firstly upsert all TRACT Services and link to account
            upsert mTractServices.values() External_Id__c;
            
            //link services to its parent service and next service
            for (TRACT_Service__c tractservice : mTractServices.values()) {
                String nextserviceId = mServiceVsNextServices.get(tractservice.External_Id__c);
                String parentserviceId = mChildParentServices.get(tractservice.External_Id__c);
                String prevserviceId = mServiceVsPrevServices.get(tractservice.External_Id__c);
                
                if ( String.isNotEmpty(nextserviceId)) {
                    tractservice.Next_Service__r = new TRACT_Service__c(External_Id__c = nextserviceId);
                }
                
                if (String.isNotEmpty(parentserviceId)) {
                    tractservice.Parent_Service__r = new TRACT_Service__c(External_Id__c = parentserviceId);
                }
                
                if (String.isNotEmpty(prevserviceId)) tractservice.Change_Service_Previous_Service__r = new TRACT_Service__c(External_Id__c = prevserviceId);
            }
            
            //update services with related object
            upsert mTractServices.values() External_Id__c;
        }
    } //End tract service

    public class TRACTInvoiceSync {
        public Map<String, TRACT_Invoice__c> mapTractInvoices = new Map<String, TRACT_Invoice__c>();

        public TRACTInvoiceSync(List<List<String>> parsedCSV) {
            //to map tract account number with list of tract invoices
            Map<String, List<TRACT_Invoice__c>> mTractaccIDvsInvoices = new Map<String, List<TRACT_Invoice__c>>();
            List<Map<String, String>> mHeaderVsValue = csv2map(parsedCSV) ;
            
            //loop throught csv to generate tract invoice sobject
            for (Map<String, String> mapInvoice : mHeaderVsValue) {
                
                //tract invoice
                String invoiceNumber                = mapInvoice.get('Invoice Number');
                String billingAccount               = mapInvoice.get('Billing Account ID');
                String currency_iso_code            = mapInvoice.get('Currency Code');
                String financecontactemail          = mapInvoice.get('Finance Contact Email');
                String billingschem                 = mapInvoice.get('Billing Scheme');
                String status                       = mapInvoice.get('Status');
                String externalId                   = mapInvoice.get('Invoice ID');
                
                Decimal amount                      = String.isBlank(mapInvoice.get('Amount')) ? null : Decimal.valueOf(mapInvoice.get('Amount'));
                
                Date occurred_on                    = convertDate(mapInvoice.get('Occurred On'));
                Date duedate                        = convertDate(mapInvoice.get('Due Date'));
                
                string BillingPeriod                = mapInvoice.get('Billing Period');
                Date AutoPayDate                    = convertDate(mapInvoice.get('Auto-Pay Date'));

                //create tract invoice instance object
                TRACT_Invoice__c tinv               = new TRACT_Invoice__c(
                                                                Name = invoiceNumber,
                                                                Currency_Code__c = currency_iso_code,
                                                                Amount__c = amount,
                                                                Finance_Contact_Email__c = financecontactemail,
                                                                Billing_Scheme__c = billingschem,
                                                                Occurred_On__c = occurred_on,
                                                                Status__c = status,
                                                                External_Id__c = externalId,
                                                                Due_Date__c = duedate,
                                                                Billing_Period__c = BillingPeriod,
                                                                Auto_Pay_Date__c = AutoPayDate
                                                        );
                                                        
                if (String.isBlank(billingAccount)) continue;
                
                //map Billing Account with the list of Tract Invoices                                   
                if ( !mTractaccIDvsInvoices.containsKey(billingAccount) ) mTractaccIDvsInvoices.put(billingAccount, new List<TRACT_Invoice__c>());
                mTractaccIDvsInvoices.get(billingAccount).add(tinv);
            }
            
            //link invoice to billing account
            for (Account acc : [select Id, Tract_AccountId__c from Account where Tract_AccountId__c IN: mTractaccIDvsInvoices.KeySet()]) {
                for (TRACT_Invoice__c tinvoice : mTractaccIDvsInvoices.get(acc.Tract_AccountId__c)) {
                    tinvoice.Billing_Account__c = acc.Id;
                    mapTractInvoices.put(tinvoice.External_Id__c, tinvoice);
                }
            }

        }
    }

    public class TRACTInvoiceItemSync {
        
        public Map<String, List<TRACT_Invoice_Item__c>> mInvvsInvoiceItem = new Map<String, List<TRACT_Invoice_Item__c>>();

        public TRACTInvoiceItemSync(List<List<String>> parsedCSV) {
            
            List<Map<String, String>> mHeaderVsValue = csv2map(parsedCSV) ;

            //loop throught csv to generate tract invoice sobject
            for (Map<String, String> minvoiceItem : mHeaderVsValue) {
                
                //tract invoice
                String invoice_item_type = minvoiceItem.get('Invoice Item Type');
                
                if ( String.isBlank(invoice_item_type) ) continue;
                
                String status = minvoiceItem.get('Status');
                String externalId = minvoiceItem.get('External Invoice Item ID');
                String tract_invoice_Id = minvoiceItem.get('Invoice ID');
                String description = minvoiceItem.get('Description');
                String po_number = minvoiceItem.get('P/O Number'); 
                String oliId = minvoiceItem.get('Opportunity Line Item ID'); 
                
                Date start_date = String.isBlank(minvoiceItem.get('Start Date')) ? Date.today() : convertDate(minvoiceItem.get('Start Date'));
                Date end_date = String.isBlank(minvoiceItem.get('End Date')) ? Date.today() : convertDate(minvoiceItem.get('End Date'));
                
                Integer quantity = String.isBlank(minvoiceItem.get('Quantity')) ? 0 : Integer.valueOf(minvoiceItem.get('Quantity'));
                Decimal unit_amount = getDecimalFromString(minvoiceItem.get('Unit Amount'));
                Decimal total_amount = getDecimalFromString(minvoiceItem.get('Total Amount'));
                                
                //TRACT_Invoice__c tractInvReference = new TRACT_Invoice__c(External_Id__c = tract_invoice_Id);
                             
                //create tract invoice item instance object
                TRACT_Invoice_Item__c tinvitem  = new TRACT_Invoice_Item__c(
                                                        Invoice_Item_Type__c = invoice_item_type,
                                                        Unit_Amount__c = unit_amount,
                                                        P_O_Number__c = po_number,
                                                        Quantity__c = quantity,
                                                        Status__c = status,
                                                        Description__c = description,
                                                        Start_Date__c = start_date,
                                                        End_Date__c = end_date,                                                     
                                                        External_Id__c = externalId,
                                                        //TRACT_Invoice__r = tractInvReference,
                                                        Opportunity_Line_Item_ID__c = oliId                       
                                                    );
                                                    
                if ( !mInvvsInvoiceItem.containsKey(tract_invoice_Id)) mInvvsInvoiceItem.put(tract_invoice_Id, new List<TRACT_Invoice_Item__c>());                          
                mInvvsInvoiceItem.get(tract_invoice_Id).add(tinvitem);
            } 
            
        }
        
        private decimal getDecimalFromString(string strDecimal){        
            if (String.isBlank(strDecimal)) return null;
        
            decimal returnVal;
            boolean isNegative = false;
            strDecimal = strDecimal.replaceAll(',',''); //to correct format
        
            //in case string amount is negative
            if (strDecimal.contains('-')) {
                isNegative = true;
                strDecimal = strDecimal.replace('-','');
            }   
                 
            returnVal = Decimal.valueOf(strDecimal);
            if (isNegative) returnVal = returnVal /-1;        
            return returnVal;
        }
    }
    
    public static Map<Decimal, List<TRACT_Revenue_Schedule__c>> mapTrtRevenueSchedule = new Map<Decimal, List<TRACT_Revenue_Schedule__c>>();
    public class TRACTRevenueScheduleSync {
         
        public TRACTRevenueScheduleSync() {}
        
        public TRACTRevenueScheduleSync(List<List<String>> parsedCSV) {
            List<Map<String, String>> mHeaderVsValue = csv2map(parsedCSV) ;
            
            //loop throught csv to generate TRACT_Revenue_Schedule__c sobject
            for (Map<String, String> mrs : mHeaderVsValue) {
                
                //TRACT_Revenue_Schedule__c
                String currency_iso_code            = mrs.get('Currency Code');
                String tract_service                = null;
                
                Decimal forecast_revenue            = String.isBlank(mrs.get('Forecast Revenue')) ? 0 : Decimal.valueOf(mrs.get('Forecast Revenue'));
                Decimal expected_revenue            = String.isBlank(mrs.get('Expected Revenue')) ? 0 : Decimal.valueOf(mrs.get('Expected Revenue'));
                Decimal actual_rev                  = String.isBlank(mrs.get('Actual Revenue')) ? 0 : Decimal.valueOf(mrs.get('Actual Revenue'));
                Decimal viewable_impressions_rate   = String.isBlank(mrs.get('viewable_impressions_rate')) ? 0 : Decimal.valueOf(mrs.get('viewable_impressions_rate'));
                Decimal tract_order_ID              = String.isBlank(mrs.get('Tract Order Id')) ? null : Decimal.valueOf(mrs.get('Tract Order Id'));
                
                if ( tract_order_ID == null) continue;
                
                Decimal click_thru_rate             = String.isBlank(mrs.get('Amount')) ? 0 : Decimal.valueOf(mrs.get('Amount'));
                Decimal delivery_indicator          = String.isBlank(mrs.get('Delivery Indicator')) ? 0 : Decimal.valueOf(mrs.get('Delivery Indicator'));
                Integer total_clicks                = String.isBlank(mrs.get('total_clicks')) ? 0 : Integer.valueOf(mrs.get('total_clicks'));
                Integer total_impressions           = String.isBlank(mrs.get('total_impressions')) ? 0 : Integer.valueOf(mrs.get('total_impressions'));
                Integer measurable_impressions      = String.isBlank(mrs.get('measurable_impressions')) ? 0 : Integer.valueOf(mrs.get('measurable_impressions'));
                Integer viewable_clicks             = String.isBlank(mrs.get('viewable_clicks')) ? 0 : Integer.valueOf(mrs.get('viewable_clicks'));
                Integer viewable_impressions        = String.isBlank(mrs.get('viewable_impressions')) ? 0 : Integer.valueOf(mrs.get('viewable_impressions'));
                Integer month                       = String.isBlank(mrs.get('Month')) ? null : Integer.valueOf(mrs.get('Month'));
                Integer year                        = String.isBlank(mrs.get('Year')) ? null : Integer.valueOf(mrs.get('Year'));
                
                Date period_start                   = ( month == null || year == null ) ? null : Date.newInstance(year, month, 1);
                Date period_end                     = period_start == null ? null : Date.newInstance(year, month, Date.daysInMonth(year, month));
                
                String externalId                   = tract_order_ID+ID_SEPARATOR+period_start+ID_SEPARATOR+period_end;
                
                String type                         = String.isBlank(mrs.get('Type')) ? null : mrs.get('Type');
                String tags                         = String.isBlank(mrs.get('Tags')) ? null : mrs.get('Tags');
                
                //create tract invoice instance object
                TRACT_Revenue_Schedule__c trs   = new TRACT_Revenue_Schedule__c (
                                                        Actual_Revenue__c = actual_rev,
                                                        Click_Thru_Rate__c = click_thru_rate,
                                                        Delivery_Indicator__c = delivery_indicator,
                                                        Expected_Revenue__c = expected_revenue,
                                                        Forecast_Revenue__c = forecast_revenue,
                                                        Measurable_Impressions__c = measurable_impressions,
                                                        Total_Clicks__c = total_clicks,
                                                        Period_Start__c = period_start,
                                                        Period_End__c = period_end,
                                                        Total_Impressions__c = total_impressions,
                                                        Viewable_Clicks__c = viewable_clicks,
                                                        Viewable_Impressions__c = viewable_impressions,
                                                        Viewable_Impressions_Rate__c = viewable_impressions_rate,
                                                        CurrencyIsoCode = currency_iso_code,
                                                        External_Id__c = externalId,
                                                        Type__c = type,
                                                        Tags__c = tags  
                                                    );
                
                if (!mapTrtRevenueSchedule.containsKey(tract_order_ID)) mapTrtRevenueSchedule.put(tract_order_ID, new List<TRACT_Revenue_Schedule__c>());
                mapTrtRevenueSchedule.get(tract_order_ID).add(trs);
            }
        }

        public void commitAll() {
            Map<String, TRACT_Revenue_Schedule__c> mapTractRevenueSchedule = new Map<String, TRACT_Revenue_Schedule__c>();
            Set<String> setServiceID = new Set<String>();
            
            //Map order ID and TRACT Serice ID
            for (TRACT_Service__c tservice : [Select Id, Opportunity__r.Tract_OrderId__c, Opportunity__r.CurrencyIsoCode From TRACT_Service__c Where Opportunity__r.Tract_OrderId__c IN: mapTrtRevenueSchedule.keySet()]) {
                List<TRACT_Revenue_Schedule__c> tractrevenuers = mapTrtRevenueSchedule.get(tservice.Opportunity__r.Tract_OrderId__c);
                
                for ( TRACT_Revenue_Schedule__c tractrevs : tractrevenuers) {
                    tractrevs.TRACT_Service__c = tservice.Id;
                    tractrevs.CurrencyIsoCode = tservice.Opportunity__r.CurrencyIsoCode;
                    mapTractRevenueSchedule.put(tractrevs.External_Id__c, tractrevs);
                    setServiceID.add(tservice.Id);
                }
            }
            
            upsert mapTractRevenueSchedule.values() External_Id__c;
            
            //clear data
            delete [Select Id From TRACT_Revenue_Schedule__c Where TRACT_Service__c IN: setServiceID AND External_Id__c NOT IN: mapTractRevenueSchedule.keySet()];
            
            mapTrtRevenueSchedule = new Map<Decimal, List<TRACT_Revenue_Schedule__c>>();
        }
    }

	/**
	 * To convert csv list string to map
	 * @param: parsedCSV a csv list string
	 * @return: list map --> 'account'=>'1234', 'incvoice id' => '123456'
	 */
	public static List<Map<String, String>> csv2map(List<List<String>> parsedCSV) {
		List<Map<String, String>> lstMapObjects = new List<Map<String, String>>();
		
		//if csv contains only header --> return
		if ( parsedCSV.size() == 1 ) return lstMapObjects;
		//get header as list string
		List<String> headers = parsedCSV[0];
		
		//remove header
		parsedCSV.remove(0);

		//loop throught csv rows
		for (List<String> rows : parsedCSV) {
			//create a map store column name with its value. e.g 'Id' => 'xxxxxxxxxxxxxxx'
			Map<String, String> mObject = new Map<String, String>();

			//loop throught column to get value and put in the map
			for ( Integer i = 0; i < rows.size(); i++) {
				string value = rows[i].trim();
				if ( value.startsWith(DOUBLE_QUOTE_SEPARATOR) && value.endswith(DOUBLE_QUOTE_SEPARATOR) ) {
					//firtly remove double quote from string as some column come with comma at the first & end of string
					String strRemoveDoubleQuote = value.substringBeforeLast(DOUBLE_QUOTE_SEPARATOR).substringAfter(DOUBLE_QUOTE_SEPARATOR);
					//remove 'comma' from string
					String strRemoveComma = strRemoveDoubleQuote.replaceAll(COMMA_SEPARATOR, SPACE_SEPARATOR);
					//remove 'dot' from string
					String strRemovePoint = strRemoveComma.replace(DOT_SEPARATOR, SPACE_SEPARATOR);
					//check whether current string is numneric --> if so, return xxxx.xx. else return string without double quote at starting & end
					value = strRemovePoint.isNumeric() ? strRemoveComma : strRemoveDoubleQuote;
				}
				
				//put column header name and its value to map
				mObject.put(headers[i].trim(), value);
			}

			//add map to list
			lstMapObjects.add(mObject);
		}

		return lstMapObjects;
	}

    public static List<List<String>> parseCSV(String contents,Boolean skipHeaders) {
        List<List<String>> allFields = new List<List<String>>();
    
        // replace instances where a double quote begins a field containing a comma
        // in this case you get a double quote followed by a doubled double quote
        // do this for beginning and end of a field
        contents = contents.replaceAll(',"""',',"DBLQT').replaceall('""",','DBLQT",');
        // now replace all remaining double quotes - we do this so that we can reconstruct
        // fields with commas inside assuming they begin and end with a double quote
        contents = contents.replaceAll('""','DBLQT');
        // we are not attempting to handle fields with a newline inside of them
        // so, split on newline to get the spreadsheet rows
        List<String> lines = new List<String>();
        try {
            lines = contents.split('\n');
        } catch (System.ListException e) {
            System.debug('Limits exceeded?' + e.getMessage());
        }
        Integer num = 0;
        for(String line : lines) {
            // check for blank CSV lines (only commas)
            if (line.replaceAll(',','').trim().length() == 0) break;
            
            List<String> fields = line.split(',');  
            List<String> cleanFields = new List<String>();
            String compositeField;
            Boolean makeCompositeField = false;
            for(String field : fields) {
                if (field.startsWith('"') && field.endsWith('"')) {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                } else if (field.startsWith('"')) {
                    makeCompositeField = true;
                    compositeField = field;
                } else if (field.endsWith('"')) {
                    compositeField += ',' + field;
                    cleanFields.add(compositeField.replaceAll('DBLQT','"'));
                    makeCompositeField = false;
                } else if (makeCompositeField) {
                    compositeField +=  ',' + field;
                } else {
                    cleanFields.add(field.replaceAll('DBLQT','"'));
                }
            }
            
            allFields.add(cleanFields);
        }
        if (skipHeaders) allFields.remove(0);
        return allFields;       
    }

}//End UTIL Class