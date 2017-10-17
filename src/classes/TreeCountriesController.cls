global class TreeCountriesController {
	public String lineItemId{get;set;}
    public String targetId{get;set;}
    public String sessionId { get; set;}
    public String checkedNodes { get; set;}
    public String fromId {get; set;}
    public Boolean isConf {get;set;}
    public String hideId{get;set;}
    // Controller
    public TreeCountriesController (ApexPages.StandardController controller){
        isConf = false;
      	String id=((OpportunityLineItem)controller.getrecord()).id;
      	sessionId = UserInfo.getSessionId();
      	hideId = ApexPages.currentPage().getParameters().get('hidId');
      	fromId = ApexPages.currentPage().getParameters().get('fromId');
      	//to know that open targeting tree by Product Configurator VF
      	String strTmp = ApexPages.currentPage().getParameters().get('isConf');
          
        if(strTmp != '' && strTmp != null){
        	isConf = Boolean.valueOf(strTmp);
        }
          
      	if(isConf){
            targetId = ApexPages.currentPage().getParameters().get('targetId');
      	}else{    
        	if(id != null && id != ''){ 
            	OpportunityLineItem oppItem=[Select o.Targeting__c,o.Id From OpportunityLineItem o where o.Id=:id];
            
            	lineItemId=oppItem.Id;
            	if(oppItem.Targeting__c!=null){
                	targetId=oppItem.Targeting__c;
            	}
          	}
      	}
     	checkedNodes='';
     	if(targetId != ''){
     		List<TargetingCountryAssociation__c> lstCountries= new List<TargetingCountryAssociation__c>([Select  t.Country__c From TargetingCountryAssociation__c t where t.Targeting__c=:targetId and t.Country__r.Active__c = true]);// Sreymol 25/04/2014: change to query only the active countries
            if(lstCountries.size()>0){
            	for(TargetingCountryAssociation__c tct:lstCountries){
              		checkedNodes=checkedNodes+tct.Country__c+',';
              	}
            }
     	}
    }
    
    webService static String apexSaveHandler(String sChecked,String lineItemId , String targetId,String strValue, String isConf){
      	//Connect Targeting__c to the line item by putting the id in the lookup field "Targeting__c" in line items.
        System.debug('===================================================tar:' + targetId);
        if(targetId == ''){
            Targeting__c t = new Targeting__c(Description__c = 'Tar_LineItemId ' + lineItemId );
            insert t;
            targetId = t.Id;
        }
    	//System.debug('++++++++++++++++++'+sChecked);
        Set<String> sChk = new Set<String>(sChecked.split(','));
       // String keyValueString='';    
        Map<String,Country__c> mChkCountry = new Map<String,Country__c>();
        List<Country__c> lstChkCountry=[Select c.Id From Country__c c Where c.Id In :sChk and Active__c = true]; // Sreymol 25/04/2014: change to query only the active countries
        
        if(lstChkCountry.size()>0){          
          for(Country__c c : lstChkCountry){  
              mChkCountry.put(c.Id, c);  
          }
        }
        //All objects that are checked in the tree have to be related to the targeting record.
        List<TargetingCountryAssociation__c> lstTgCountry = new List<TargetingCountryAssociation__c>();
            
        //for deletion of tree nodes changed to unchecked status from opp lineitem
        Set<String> assoNotToDelete = new Set<String>();

        //for lower than top level nodes
        for(String chk : sChk){
            if(chk == '' || mChkCountry.get(chk) == null) continue;      
                TargetingCountryAssociation__c tca = new TargetingCountryAssociation__c(Targeting__c = targetId ,Country__c  =chk , TargetCountry__c  = targetId + chk);
                lstTgCountry.add(tca);
                assoNotToDelete.add(tca.TargetCountry__c);        
        }
    
        
        if(!lstTgCountry.isEmpty()){
           
            upsert lstTgCountry TargetCountry__c;
            
        }
        
        if(lineItemId != ''){
            List<OpportunityLineItem> li = [Select o.Targeting__c From OpportunityLineItem o Where Id = :lineItemId];
            if(li.size()>0){
            li[0].Targeting__c = targetId;
            li[0].Countries_Description__c=strValue; 
            update li;
            }
        }
        delete [Select Id From TargetingCountryAssociation__c Where Targeting__c= :targetId And TargetCountry__c Not In :assoNotToDelete ];
          
        if(isConf.equalsIgnoreCase('true')){
            return  targetId+'#'+strValue;
         }
         return '';
    }
    
    static testmethod void testProduct_QuickCreate(){
    	Product2 p = new product2(name = 'blabla Licenses bla');
        insert p;
        
        Pricebook2 stdPb = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
        PricebookEntry pbe = new PricebookEntry(
            pricebook2id    = stdPb.id, 
            product2id      = p.id, 
            unitprice       = 1.0, 
            isActive        = true,
            CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY
        );
        insert pbe;
      
        User currentUser = [ select Id from User where Id = :UserInfo.getUserId() limit 1];
        User userAdmin;
        System.runAs ( currentUser ) {
            Profile pro=[Select Id From Profile Where Name='System Administrator'  or Name='Systemadministrator' Limit 1];
            userAdmin = GW_User.createTestUser(pro);
            userAdmin.Username='testUser1@boco.com';
            userAdmin.LastName='testLastName1';
            userAdmin.Email='testEmail1@boco.com';
            userAdmin.Alias='test1';
            userAdmin.TimeZoneSidKey='Pacific/kiritimati';
            userAdmin.LocaleSidKey='ar';
            userAdmin.EmailEncodingKey='UTF-8';
            userAdmin.ProfileId=pro.Id;
            userAdmin.LanguageLocaleKey='en_US';   
            insert userAdmin;
        }            
        
        Account acc;
        
        system.runAs(currentUser){

            createMembers();

	      	    acc = new Account(
	            Name   = 'TestAcc',
	            BillingStreet = 'Fake Street',
	            BillingCity = 'Fake City',
	            BillingPostalCode = 'Fake',
	            BillingCountryCode = 'GB',
	            ownerId= userAdmin.Id         
	        );
	        insert acc;

        }
        
	    Contact c = new Contact(
	      LastName = 'TestCont'
	    );
    	insert c;
        
        MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test Adsales' AND LineOfBusiness__c = 'AD'];
        Opportunity o = new Opportunity(
            AccountId       = acc.Id,
            name      ='test', 
            pricebook2id    = stdPb.id, 
            stageName       = 'Closed Won', 
            CloseDate       = Date.Today(),
            Primary_Contact__c = c.Id,
            Probability = 0.90,
            P_O_Number__c = '123',
            CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY,
            MemberUnit__c = mu.Id
        );
        
        system.runAs(userAdmin){
               insert o;  
        }
          
        Country__c c1 = new Country__c(Name = 'Test', Active__c = true);
        insert c1;
        Country__c c2 = new Country__c(Name = 'Test1', Active__c = true);
        insert c2;
    
        Targeting__c t = new Targeting__c(Description__c = 'TargetingTreeProduct' );
        insert t;
        TargetingCountryAssociation__c tac = new TargetingCountryAssociation__c(Targeting__c = t.Id, Country__c  = c1.Id,TargetCountry__c = t.Id+''+c1.Id);
        insert tac;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            opportunityid           = o.id, 
            pricebookentryid        = pbe.id,
            unitprice               = 1.5, 
            quantity                = 2.0,
            Targeting__c            = t.Id,
            SalesPriceNet__c		= 1.5
        );
        insert oli;
        
        Test.startTest();
            String str = '/apex/TreeCountriesPage?fromId=&targetId='+t.Id;
            PageReference pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            TreeCountriesController contr = new TreeCountriesController(new Apexpages.Standardcontroller(oli));
            TreeCountriesController.apexSaveHandler((c1.id+','+c2.id),'',(t.id+''),'','true');
            TreeCountriesController.apexSaveHandler((c1.id+','+c2.id),oli.Id,'',(t.id+''),'true');
            TreeCountriesController.apexSaveHandler((c1.id+','+c2.id),oli.Id,'','','false');
            str = '/apex/TreeCountriesPage?fromId=&targetId='+t.Id + '&isConf=true';
            pageRef = new PageReference(str);
            Test.setCurrentPage(pageRef);
            contr = new TreeCountriesController(new Apexpages.Standardcontroller(oli));
         Test.stopTest();   
        }

        /**
         * insert member and member unit for testing
         */
        private static void createMembers() {

            Id RecId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member').getRecordTypeId();
            Account memberAccount = new Account(RecordTypeId=RecId, name='MemberAccount', BillingCountry='Netherlands', ShippingCountry='Italy');
            insert memberAccount;
            Member__c member = GW_Member.insertSObject('Test Member', 'TTCLG',memberAccount);
            List<MemberUnit__c> memberUnits = new List<MemberUnit__c>();
            memberUnits.add(GW_MemberUnit.insertObject(member.Id, 'Test Adsales', 'AD'));
            memberUnits.add(GW_MemberUnit.insertObject(member.Id, 'Test Automotive', 'AU'));
            member.DefaultMemberUnit__c = memberUnits[1].Id;
            update member;
        }
    
}