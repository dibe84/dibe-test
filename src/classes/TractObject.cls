public with sharing class TractObject {
	
	// Order responsed when confirm booking
    public class Order {
	    	public String id;
	    public 	String order_num;
	    	public OrderItem[] order_items;
    }
    
    // order_items in side the Order responsed when confirm booking
    public class OrderItem {
	    	public String id;
	    public 	Service service;
	    	public CustomFieldValue[] custom_field_values;
	    	public OperationRunAttribute[] operation_run_attributes;
    }
    
    // service in each order_item of the Order responsed when confirm booking
    public class Service {
    		public String id;
    		public Agreement current_agreement_service;
    }
    
    public class CustomFieldValue {
    		public String id;
    		public String value;
    		public CustomField custom_field;
    }
    
    public class CustomField {
    		public String id;
    		public String name;
    }
    
    public class Agreement {
    		public String id;
    		public String end_date;
    		public String end_action;
    }
    
    public class UsageRule {
    		public String id;
    		public String name;
    		public UsageRate usage_rate;
    		public UsageRule order_item_usage_rule;
    }
    
    public class UsageRate {
    		public String id;
    		public ChargeCategory charge_category;
    }
    
    public class ChargeCategory {
    		public String id;
    }
    
    public class OperationRunAttribute {
    		public String id;
    		public String operation_run_attribute_type;
    }
}