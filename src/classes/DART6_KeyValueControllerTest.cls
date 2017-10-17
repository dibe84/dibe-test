@isTest
public with sharing class DART6_KeyValueControllerTest {
    //@vitou 09-04-2015
    static testMethod void testKV()
    {
 
   /* ================================== Test KeyValue Free-Form & Audience Segment=================================    */
             
        TestDataGenerator testDATA = new TestDataGenerator(); 
        testDATA.createCredential();
        testDATA.createTargetingHierarchy();
        testDATA.createAccount(); 
        testDATA.createAdvertiser();
        testDATA.createOpp(testDATA.lstAcc.get(0));
        testDATA.createNewOppItemsDart(testDATA.opp.id,2,DARTUtil.DART6,testDATA.targetting[0].Id);
        List<OpportunityLineItem> items =testDATA.getOppItem(testDATA.opp.id, new Set<String>{testDATA.lstLineItems.get(0).id});
        testDATA.createTargetingKVHierarchy();
        
        Test.startTest();
            
            String token = 'DQAAAIYAAADrtubcdIuc0bz-CksXJh6v';
            String kv = '((car=hummer)) OR ((car=bmw) OR (car=tico) OR (car=vigo) OR (color=red) OR (color=white) OR (Audience Segment=Aud1) OR (Audience Segment=Aud2))';
            String nw = '18823133';
            String siteAuto = items.get(0).PricebookEntry.Product2.Site__r.id;
            
            DART6_KeyValueController ctrl = new DART6_KeyValueController(siteAuto,kv,token,nw);
            
            if(ctrl.isNeedToCreate()) 
            {
              ctrl.searchCreateDFPFreeFormValues();
              ctrl.updateDart6ValueIds();
              System.assertEquals(testDATA.keyvalues[1].Dart6_ValueId__c,22222,'dfp value id must be assigned to sf record');
              
              List<DART6_FORECASTSERVICE.CustomCriteriaSet> listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>)ctrl.getListDart();
              
               System.assertEquals(listCrit.size(),1,'1 CustomCriteriaSet for targeting');
               System.assertEquals(listCrit[0].children.size(),1,'1 CustomCriteriaSet expected: {(car=hummer)  OR  (car=bmw) OR (car=tico) OR (car=vigo) OR (color=red) OR (color=white) OR (Audience Segment=Aud1) OR (Audience Segment=Aud2)}');
            }
            
            
            // In case (Key value: Free-form) and no KeyValue in sf & need to created
            if(ctrl.isCreateNewKv())
            {
                ctrl.createObjectKeyVal();
                System.assertEquals(testDATA.keyvalues[4].Dart6_ValueId__c,66666,'dfp value id must be assigned to sf record');
            }
            
            String kv2 = '((car=hummer)) OR ((carx=bmw))';
            
            try
            {
                DART6_KeyValueController ctrl2 = new DART6_KeyValueController(siteAuto,kv2,token,nw);
                
            }catch(ExceptionGroup.DARTKeyValueException dex)
            {
                System.assert(dex.getMessage().contains('Key(s) not found'),'Key(s) not found in the TargetingKeyValueAssociations:{carx}');
                System.assert(dex.getMessage().contains('carx'));
            }
        
        Test.stopTest();    
    }
}