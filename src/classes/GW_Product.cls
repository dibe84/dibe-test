public with sharing class GW_Product {

    private static final Schema.sObjectType GW_BASEOBJECT = Product2.sObjectType;
    private static final String GW_BASEOBJECTNAME = 'Product2';

    private final static String BILLINGCAT_CPM = 'CPM';
    private final static String BILLINGCAT_CPD = 'CPD';
    private final static String BILLINGCAT_CPC = 'CPC';
    private final static String BILLINGCAT_SERVICEFEE = 'ServiceFee';

    private final static Decimal UPCF_CPM = 0.001;
    private final static Decimal UPCF_DEFAULT = 1;

    private final static Decimal QDEFAULT_CPM = 1000;
    private final static Decimal QDEFAULT_DEFAULT = 1;

//////////////////////////////////////////////////////////////////////////////////////////////////////
// public query methods
//////////////////////////////////////////////////////////////////////////////////////////////////////
    public static Product2           getRecord(Id id)           { return (Product2) GW_sObject.queryRecord(GW_BASEOBJECTNAME, id); }
    public static Map<id,Product2>   getMap(Set<id> ids)        { return new Map<id,Product2>( getList(ids) ); }
    public static List<Product2>     getList(Set<id> ids)       { return (List<Product2>) GW_sObject.queryRecords(GW_BASEOBJECTNAME, ids); }


//////////////////////////////////////////////////////////////////////////////////////////////////////
//  Test Factory
//////////////////////////////////////////////////////////////////////////////////////////////////////

    public static final String DEFAULT_ACCNAME = 'ACME Inc.';

    public static Product2 createSObject(String productName) { return new Product2(Name=productName); }

    public static Product2 insertSObject(String productName) {
        Product2 prod= createSObject(productname);
        prod.Product_Type__c = productname;
        prod.Product_SubType__c = productname;
        prod.Billing_Category__c = 'CPM_Delivery;CPM_DailyFixed;CPD_Delivery;CPD_DailyFixed;CPC_Delivery;ServiceFee_OneTime;ServiceFee_MonthlyFixed;Subscription_MonthlyProRata,Subscription_MultiMonth';
        insert prod;
        return prod;
    }

// related objects for which we are not creating separate GW class
//
    public static Pricebook2 insertPricebook() {
        Pricebook2 pb = new Pricebook2();
        pb.Name = 'Standard Price Book';
        insert pb;
        return pb;
    }

    public static PricebookEntry insertPricebookEntry(Product2 product, Pricebook2 priceBook, Decimal unitPrice) {
        PricebookEntry pbe = new PricebookEntry();
        pbe.Product2Id = product.Id;
        pbe.Pricebook2Id = pricebook.Id;
        pbe.UnitPrice = unitPrice;
        pbe.IsActive = true;
        pbe.CurrencyIsoCode = UTIL.corporateCurrency.IsoCode;
        insert pbe;
        return pbe;
    }

    public static Decimal getListPrice(ID pbeId, String billingCat) {
        PricebookEntry pbe = (PricebookEntry) UTIL.getCached(pbeId);
        Product2 prod = (Product2) UTIL.getCached(pbe.Product2Id);
        if (billingCat == null) return 0;
        Map<String, Decimal> mapBC2LP = new Map<String, Decimal>();
        if (billingCat.toUpperCase() == BILLINGCAT_CPM) return prod.CPM_Price__c == null ? 0 : prod.CPM_Price__c;
        if (billingCat.toUpperCase() == BILLINGCAT_CPD) return prod.CPD_Price__c == null ? 0 : prod.CPD_Price__c;
        if (billingCat.toUpperCase() == BILLINGCAT_CPC) return prod.CPC_Price__c == null ? 0 : prod.CPC_Price__c;
        if (billingCat.toUpperCase() == BILLINGCAT_SERVICEFEE) return prod.ServiceFee_Price__c == null ? 0 : prod.ServiceFee_Price__c;
        return 0;
    }

    public static Decimal getUPCF(String billingCat){
    	if (billingCat == null) return UPCF_DEFAULT;
        return (billingCat.toUpperCase() == BILLINGCAT_CPM) ? UPCF_CPM : UPCF_DEFAULT;
    }

    public static Decimal getDefaultQuantity(String billingCat) {
        if (billingCat == null) return QDEFAULT_DEFAULT;
        return (billingCat.toUpperCase() == BILLINGCAT_CPM) ? QDEFAULT_CPM : QDEFAULT_DEFAULT;
    }

}