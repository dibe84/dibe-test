public class TSTDF_DataContainer {
	public Map<String,User> testUsers = new Map<String,User>();
    public Map<String,Member__c> members = new Map<String,Member__c>();
    public List<MemberUnit__c> memberUnits = new List<MemberUnit__c>();

    public List<Lead> leads = new List<Lead>();
    public List<Account> accounts = new List<Account>();
    public List<Contact> contacts = new List<Contact>();
    public List<Product2> products = new List<Product2>();
    public List<PricebookEntry> pbes = new List<PricebookEntry>();
    public List<Opportunity> opps = new List<Opportunity>();
    public List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
    public List<Rev__c> revs = new List<Rev__c>();
    public List<RS__c> rss = new List<RS__c>();
    public List<Metric__c> metrics = new List<Metric__c>();
    public List<Invoice__c> invoices = new List<Invoice__c>();
    public List<InvoiceLine__c> invoicelines = new List<InvoiceLine__c>();
	public List<CustomAttributeDefinition__c> customAttributeDefinitions = new List<CustomAttributeDefinition__c>();
    public List<WS_Log__c> wsLogs = new List<WS_Log__c>();
    public List<WS_ScheduledCallout__c> wsScheduledCallouts = new List<WS_ScheduledCallout__c>();
    public List<Pricebook2> pricebooks = new List<Pricebook2>();
}