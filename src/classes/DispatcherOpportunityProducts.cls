public without sharing class DispatcherOpportunityProducts {


    public DispatcherOpportunityProducts(ApexPages.StandardController controller) {
        this.controller = controller;
    }
    
    public PageReference Redir(){   
		  
		//RecordType Couponstype = [Select r.Id From RecordType r Where r.Name = 'Coupons'  And SobjectType = 'Opportunity'];	
		
        String oppId= ApexPages.currentPage().getParameters().get('id');
        if(oppId!=null){
            Opportunity o = [Select id, name, recordtypeid, RecordType.Name From Opportunity Where Id = :ApexPages.currentPage().getParameters().get('id')];
            PageReference newPage;
            
            /*if(o.RecordTypeId == Couponstype.Id){
                newPage = new PageReference('/ui/opportunity/SelectSearch?addTo=' + o.id);
            } else {*/
                newPage = Page.SelectSearch;
                newPage.getParameters().put('nooverride', '1');
                newPage.getParameters().put('id', o.id);
            //}
            return newPage.setRedirect(true);
        }
        return null;
    }
    
    private final ApexPages.StandardController controller;
    public String addProductsURL {get;set;}
    
    @isTest(SeeAllData=false)
		static void RedirTest() {
				
				//opportunity id is null
				Opportunity opportunity = new Opportunity();
				ApexPages.StandardController controller = new ApexPages.StandardController(opportunity);
				DispatcherOpportunityProducts dispathcer = new DispatcherOpportunityProducts(controller);
            	PageReference pageRef = dispathcer.Redir();
           		System.assertEquals(pageRef, null);
           		
           		User currentUser = [ select Id from User where Id = :UserInfo.getUserId() ];
           		User userAdmin;
           		Account account;
           		System.runAs ( currentUser ) {
		            Profile p=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
		            userAdmin = GW_User.createTestUser(p);
		            userAdmin.Username='testUser1@boco.com';
		            userAdmin.LastName='testLastName1';
		            userAdmin.Email='testEmail1@boco.com';
		            userAdmin.Alias='test1';
		            userAdmin.TimeZoneSidKey='Pacific/kiritimati';
		            userAdmin.LocaleSidKey='ar';
		            userAdmin.EmailEncodingKey='UTF-8';
		            userAdmin.ProfileId=p.Id;
		            userAdmin.LanguageLocaleKey='en_US';   
		            insert userAdmin;
		            
		            account = new Account(name='testAccount', ownerId = userAdmin.id, BillingPostalCode='test', BillingCity='Test',BillingStreet='Test',BillingCountryCode='GB');
                    insert account;
		        }         
			  	
    			//RecordType Couponstype = [Select r.Id From RecordType r Where r.Name = 'Coupons'  And SobjectType = 'Opportunity'];
    			 
    		/*	 //coupon record type
				opportunity = new Opportunity(
	            Name='TestOpp',
	            StageName='anyStage',
	            Probability=10,
	            CloseDate=Date.today()+10,
	            AccountId=account.Id
	            //recordTypeID = Couponstype.id
	        );
	        insert opportunity;
	
	        
	          pageRef = Page.selectsearch;
	          pageRef.getParameters().put('id', opportunity.id);
        	Test.setCurrentPage(pageRef);
        	controller = new ApexPages.StandardController(opportunity);
            dispathcer = new DispatcherOpportunityProducts(controller);
            
            pageRef = dispathcer.Redir();
           	System.assertNotEquals(pageRef, null);*/
           	
           	// not coupon record type
           	opportunity = new Opportunity(
	            Name='TestOpp',
	            StageName='anyStage',
	            Probability=10,
	            CloseDate=Date.today()+10,
	            AccountId=account.Id
	        );
	        
	        system.runAs(userAdmin){
	        	insert opportunity;
	        }

	
	        
	        pageRef = Page.selectsearch;
	        pageRef.getParameters().put('id', opportunity.id);
        	Test.setCurrentPage(pageRef);
        	controller = new ApexPages.StandardController(opportunity);
            dispathcer = new DispatcherOpportunityProducts(controller);
            
            pageRef = dispathcer.Redir();
            dispathcer.addProductsURL = 'test';
           	System.assertNotEquals(pageRef, null);
		}
}