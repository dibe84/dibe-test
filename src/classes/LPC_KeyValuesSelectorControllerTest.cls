/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description: 
 *	- test class of LPC_KeyValuesSelectorController
 * @references: 
 *	
 * @changeLog:
 *
 */
@isTest
public class LPC_KeyValuesSelectorControllerTest {
    
    public static Opportunity opp;
    public static OpportunityLineItem item;
    public static Targeting__c targetting;
    public static Product2 prd;
    public static list<Product2> lprd;
    public static TestDataGenerator testDATA = new TestDataGenerator();

    @testSetup static void setup() {

        UTIL.isRunningTestSetup = true;
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount();
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createOppTeamMember(testDATA.opp.id);
        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
        lprd = testDATA.lstPrd2;
        UTIL.isRunningTestSetup = false;

    }

    static void getOppLineItems(){
         opp = [select id, Name, Owner.id, Owner.Name, AccountId, CampaignStart__c, CampaignEnd__c, P_O_Number__c from Opportunity limit 1];
         prd = [select id from Product2 where Name='Test product0' limit 1];
         item = [select id, OpportunityId, from_Date__c, Until_Date__c, SalesPriceNet__c, AdOperatingSystems__c, 
                       Keywords_KeyValue_combination__c, KeyValueString__c, AdWebBrowsers__c, Ad_Id__c, AdKeywords__c, 
                       PriceBookEntry.Product2.Fixed_Site__c, Targeting__c, PricebookEntry.Product2.RecordType.Name, PriceBookEntry.Product2.Site__r.Country__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdSlotSize__c, Ad_Name__c, Device_Targeting__c, AdDayOfWeek__c, AdHourOfDay__c,
                       AdBrowsersMinorVersion__c, AdBrowsersMajorVersion__c, CurrencyIsoCode, PriceBookEntry.Product2.Target_Platform__c, Billing_Category__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_AdType__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_Prio__c, 
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_Product_Type__c, PriceBookEntry.Product2.Advertising_Medium__r.DART_MasterSize__c,
                       Quantity, Description, FC_Period__c, FC_Ad_served_every__c, FC_Quantity__c,
                       PriceBookEntry.Product2.Advertising_Medium__r.DART_CompanionSize__c, PriceBookEntry.Product2.Name
                       from OpportunityLineItem where Description='Test Desc0' and OpportunityId= :opp.Id];

    }

    static void getTargetting(){
        targetting = [select id from Targeting__c where Description__c='test' limit 1];
    }

    @isTest static void testKeyValueSelector() {

        getOppLineItems();
        getTargetting();
        
        User currentUser = new User( Id = UserInfo.getUserId() );
        
        Account acc;
        User userAdmin = [ select id from User where Username='testUser1@boco.com' limit 1]; 
        
                 
        System.runAs ( currentUser ) {
            acc = new Account(name='Test Account Test class',ownerId= userAdmin.id);
            insert acc;
        }

        MemberUnit__c mu = [SELECT Id FROM MemberUnit__c WHERE Name = 'Test member unit' AND LineOfBusiness__c = 'AD'];

        Opportunity  opp1 = new Opportunity(name='Test', closeDate= system.today(), stageName='test', AccountId= acc.id, MemberUnit__c=mu.Id );
        system.runAs(userAdmin){                    
            insert opp1;
        }
                
        testDATA.createSite(new Set<String>{'US'});
        Product2 prod = new Product2( Name='Test Ad Spec', Site__c = testDATA.sites[0].Id, Available_Key_Values__c='TestKey1;TestKey2;TestKey3');
        insert prod;
         
        DART_KeyValue_2__c key1=  new DART_KeyValue_2__c( Name='TestKey1', Key__c='TSK1',  Key_Value_Name__c='TestKey1', Key_Value__c='TestKey1');
        insert key1;
        
        DART_KeyValue_2__c key2=  new DART_KeyValue_2__c( Name='TestKey2', Key__c='TSK2',  Key_Value_Name__c='TestKey2', Key_Value__c='TestKey2', Dart6_ValueId__c=2.5, Node_ID__c= key1.id);
        insert key2;
        
        DART_KeyValue_2__c key3=  new DART_KeyValue_2__c( Name='TestKey3', Key__c='TSK3',  Key_Value_Name__c='TestKey3', Key_Value__c='TestKey3', Node_ID__c= key2.id);
        insert key3;
        
        
        Targeting__c t = new Targeting__c(TempBinder__c = true); 
        insert t;
        
        //create new targeting template
        Id RecId = Schema.SObjectType.Targeting__c.getRecordTypeInfosByName().get('Template').getRecordTypeId();
        Targeting__c targ = new Targeting__c();
        targ.Description__c = 'Tageting Template';
        targ.RecordTypeId = RecId;
        insert targ;
                 
        List<TargetingKeyValueAssociation__c> lstKeyAss = new List<TargetingKeyValueAssociation__c>();              
        lstKeyAss.add( new TargetingKeyValueAssociation__c(Targeting__c = t.id , DART_KeyValue__c   = key1.id , Operator__c= 'OR', targetkeyvalue__c =  (t.id +''+ key1.id )));
        lstKeyAss.add( new TargetingKeyValueAssociation__c(Targeting__c = t.id , DART_KeyValue__c   = key2.id , Operator__c= 'OR', targetkeyvalue__c = (t.id + ''+key2.id)));
        lstKeyAss.add( new TargetingKeyValueAssociation__c(Targeting__c = t.id , DART_KeyValue__c   = key3.id , Operator__c= 'OR', targetkeyvalue__c = (t.id + ''+key3.id)));
        insert lstKeyAss;
         
        Available_Site__c avai = new Available_Site__c(Product__c = prod.Id);
        Available_Site__c avai2 = new Available_Site__c(Product__c = prod.Id);
        insert new List<Available_Site__c>{avai, avai2};
        
        testDATA.getPricebook2();
        PricebookEntry pbe1 = new PricebookEntry(UseStandardPrice = false, Product2Id = prod.Id, Pricebook2Id = testDATA.standardPbId, UnitPrice = 1.00, IsActive=true, CurrencyIsoCode = TestDataGenerator.TESTINGCURRENCY);
        insert pbe1;
                
        OpportunityLineItem oppItem = new OpportunityLineItem(
                                           opportunityId = opp1.id,
                                           from_Date__c =  system.today(), 
                                           until_Date__c = system.today().addDays(7),
                                           Quantity = 1,
                                           TotalPrice = 0.01,
                                           PricebookEntryId = pbe1.id,
                                           Billing_category__c = 'CPM', 
                                           Description = 'item test',
                                           Targeting__c = t.id
                                           );
         
        insert oppItem;
                
                  
        Test.startTest();
           
            RemoteResponse response1 = LPC_KeyValuesSelectorController.initKeyN(item.id);
            
            RemoteResponse response = LPC_KeyValuesSelectorController.initKeyN(oppItem.id);
            System.assertEquals(response.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(response.content != null);
            
            RemoteResponse resVal = LPC_KeyValuesSelectorController.initValueN(key1.id, '');
            
            //List key value set
            List<LPC_KeyValuesSelectorController.KeyWrp> keyList = new List<LPC_KeyValuesSelectorController.KeyWrp>();
            LPC_KeyValuesSelectorController.KeyWrp keyOne = new LPC_KeyValuesSelectorController.KeyWrp(key1.Id, key1.Key_Value__c, key1.Key_Value_Name__c);
            keyList.add(keyOne);
            
            List<LPC_KeyValuesSelectorController.ValueWrp> valueList = new List<LPC_KeyValuesSelectorController.ValueWrp>();
            LPC_KeyValuesSelectorController.ValueWrp valueOne = new LPC_KeyValuesSelectorController.ValueWrp(key2.Id, String.valueOf(key2.Dart6_ValueId__c), key2.Key_Value_Name__c);
            valueList.add(valueOne);
            
            LPC_KeyValuesSelectorController.KeyValueWrp kvWrp = new LPC_KeyValuesSelectorController.KeyValueWrp();
            kvWrp.index = 0;
            kvWrp.keyone = keyOne;
            kvWrp.opperator = 'is';
            kvWrp.valueN = valueList;
            
            List<LPC_KeyValuesSelectorController.KeyValueWrp> kvWrpList = new List<LPC_KeyValuesSelectorController.KeyValueWrp>();
            kvWrpList.add(kvWrp);
            
            LPC_KeyValuesSelectorController.KeyValueSetWrp kvSetWrp = new LPC_KeyValuesSelectorController.KeyValueSetWrp();
            kvSetWrp.index = 0;
            kvSetWrp.valueListSel = new List<LPC_KeyValuesSelectorController.ValueWrp>();
            kvSetWrp.keyOneSel = new LPC_KeyValuesSelectorController.KeyWrp(null, '', '');
            kvSetWrp.keyValueN = kvWrpList;
            
            List<LPC_KeyValuesSelectorController.KeyValueSetWrp> keyValueSetWrpList = new List<LPC_KeyValuesSelectorController.KeyValueSetWrp>();
            keyValueSetWrpList.add(kvSetWrp);
            
            
            String keyValueSetList = JSON.serialize(keyValueSetWrpList);
            RemoteResponse saveKeyValue = LPC_KeyValuesSelectorController.saveKeyValue(oppItem.id, keyValueSetList);
            System.assertEquals(saveKeyValue.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(saveKeyValue.content != null);
            
            
            //Targeting Template
            RemoteResponse saveKeyValueTemp = LPC_KeyValuesSelectorController.saveKeyValueTemplate(targ.id, keyValueSetList);
            RemoteResponse loadKeyValueTemp = LPC_KeyValuesSelectorController.loadKeyValueTemplate(targ.id);
            System.assertEquals(loadKeyValueTemp.statusCode, RemoteResponse.STATUSCODE_OK);
            System.assert(loadKeyValueTemp.content != null);
            
            RemoteResponse rrm = new RemoteResponse('test');
        Test.stopTest();
    }
    
}