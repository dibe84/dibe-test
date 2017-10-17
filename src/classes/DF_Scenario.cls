/**
 * Created by ronvelzeboer on 26/07/16.
 */

public class DF_Scenario {
    public static final String CONF_MEMBER = 'member';
    public static final String CONF_MEMBER_UNIT = 'memberUnit';
    public static final String CONF_INVOICE_GROUPING = 'invoiceGrouping';
    public static final String CONF_USERS = 'users';
    public static final String CONF_USER_ROLE = 'userRole';
    public static final String CONF_USER_PROFILE = 'userProfile';
    public static final String CONF_ACCOUNT_RECORD_TYPE = 'accountRecordType';
    public static final String CONF_ACCOUNT_HAS_INDIRECT_PARTNER = 'accountHasIndirectPartner';
    public static final String CONF_INDIRECT_DISCOUNT = 'indirectDiscount';
    public static final String CONF_CONTRACT_DISCOUNT = 'contractDiscount';
    public static final String CONF_PRICEBOOK = 'pricebook';
    public static final String CONF_PRODUCTS = 'products';
    public static final String CONF_PRODUCT_QUANTITY = 'quantity';
    public static final String CONF_PRODUCT_AD_ID = 'adId';
    public static final String CONF_PRODUCT_DATA = 'data';
    public static final String CONF_OPPORTUNITY = 'opportunity';
    public static final String CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION = 'activeExtSubscription';
    public static final String CONF_OPPORTUNITY_COUNT = 'count';
    public static final String CONF_OPPORTUNITY_START_DATE = 'startDate';
    public static final String CONF_USER_USE_FOR = 'useFor';

    public String scenarioId { get; private set; }
    private Map<String, Object> config { get; set; }

    public String member {
        get {
            checkConfigContains(DF_Scenario.CONF_MEMBER);
            return (String) config.get(DF_Scenario.CONF_MEMBER);
        }
    }

    public String memberUnit {
        get {
            checkConfigContains(DF_Scenario.CONF_MEMBER_UNIT);
            return (String) config.get(DF_Scenario.CONF_MEMBER_UNIT);
        }
    }

    public String memberUnitId {
        get {
            return member + memberUnit;
        }
    }

    public String invoiceGrouping {
        get {
            if (config.containsKey(DF_Scenario.CONF_INVOICE_GROUPING)) {
                return (String) config.get(DF_Scenario.CONF_INVOICE_GROUPING);
            }
            return null;
        }
    }

    public List<String> users {
        get {
            checkConfigContains(DF_Scenario.CONF_USERS);
            return (List<String>) config.get(DF_Scenario.CONF_USERS);
        }
    }

    public String accountRecordType {
        get {
            if (config.containsKey(DF_Scenario.CONF_ACCOUNT_RECORD_TYPE)) {
                return (String) config.get(DF_Scenario.CONF_ACCOUNT_RECORD_TYPE);
            }
            return null;
        }
    }

    public Boolean accountHasIndirectParner {
        get {
            return config.containsKey(DF_Scenario.CONF_ACCOUNT_HAS_INDIRECT_PARTNER)
                ? (Boolean) config.get(DF_Scenario.CONF_ACCOUNT_HAS_INDIRECT_PARTNER)
                : false;
        }
    }

    public Decimal indirectDiscount {
        get {
            return config.containsKey(DF_Scenario.CONF_INDIRECT_DISCOUNT)
                ? (Decimal) config.get(DF_Scenario.CONF_INDIRECT_DISCOUNT)
                : 0;
        }
    }

    public Decimal contractDiscount {
        get {
            return config.containsKey(DF_Scenario.CONF_CONTRACT_DISCOUNT)
                ? (Decimal) config.get(DF_Scenario.CONF_CONTRACT_DISCOUNT)
                : 0;
        }
    }

    public String pricebook {
        get {
            if (config.containsKey(DF_Scenario.CONF_PRICEBOOK)) {
                return (String) config.get(DF_Scenario.CONF_PRICEBOOK);
            }
            return null;
        }
    }

    public Map<String, String> opportunity {
        get {
            if (config.containsKey(DF_Scenario.CONF_OPPORTUNITY)) {
                return (Map<String, String>) config.get(DF_Scenario.CONF_OPPORTUNITY);
            }
            return null;
        }
    }

    public List<Map<String, Object>> products {
        get {
            if (config.containsKey(DF_Scenario.CONF_OPPORTUNITY)) {
                return (List<Map<String, Object>>) config.get(DF_Scenario.CONF_PRODUCTS);
            }
            return null;
        } 
    }

    public DF_Scenario(String name, Map<String, Object> config) {
        this.scenarioId = name;
        this.config = config;
    }

    public void checkConfigContains(String key) {
        if (!config.containsKey(key)) {
            throw new UTIL.CustomException('Scenario Error: [' + scenarioId + '] - "' + key + '" settings missing.');
        }
    }

    public class Result {
        public Map<Id, SObject> sObjectMap = new Map<Id, SObject>();
        public Map<String, User> users = new Map<String, User>();
        public Map<Id, Account> accounts = new Map<Id, Account>();
        public Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
        public Map<String, OpportunityLineItem> oliMap = new Map<String, OpportunityLineItem>();
        public Map<String, Member__c> members = new Map<String,Member__c>();
        public Map<Id, MemberUnit__c> memberUnits = new Map<Id, MemberUnit__c>();
        public Map<Id, Contact> contacts = new Map<Id, Contact>();
        public Map<Id, Product2> products = new Map<Id, Product2>();
        public Map<Id, PricebookEntry> pbes = new Map<Id, PricebookEntry>();
        public Map<Id, Rev__c> revs = new Map<Id, Rev__c>();
        public Map<String, List<Rev__c>> revMap = new Map<String, List<Rev__c>>();
        public Map<Id, RS__c> rss = new Map<Id, RS__c>();
        public Map<Id, Metric__c> metrics = new Map<Id, Metric__c>();
        public Map<Id, Invoice__c> invoices = new Map<Id, Invoice__c>();
        public Map<Id, InvoiceLine__c> invoicelines = new Map<Id, InvoiceLine__c>();
        public List<CustomAttributeDefinition__c> customAttributeDefinitions = new List<CustomAttributeDefinition__c>();
        public List<WS_Log__c> wsLogs = new List<WS_Log__c>();
        public List<WS_ScheduledCallout__c> wsScheduledCallouts = new List<WS_ScheduledCallout__c>();
    }
}