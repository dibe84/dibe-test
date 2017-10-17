/**
 *@createdDate: 29-11-2016
 *@createdBy: Sochanra
 *@desc: Test logic on HNDL_Contact.cls
 */
@isTest
private class TST_Contact {
    
    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;
        TST_DataFactory.createTestSet();
        UTIL.isRunningTestSetup = false;
    }
    
    @isTest static void testPrimaryContactLogic(){
        Test.startTest();
            UTIL.isRunningTestSetup = true;
            // retrieve test data
            TST_DataFactory fac = TST_DataFactory.getInstance();
        
            //contact with User Portal role
            Contact con1 = TST_DataFactory.createPrimaryContact('Test_Contact1', true, GW_Contact.ROLE_PORTAL_USER, fac.acc);
            //contact with finance contact role
            Contact con2 = TST_DataFactory.createPrimaryContact('Test_Contact2', true, GW_Contact.ROLE_FINANCE_CONTACT, fac.acc);
            //contact with no role
            Contact con3 = TST_DataFactory.createPrimaryContact('Test_Contact1', true, '', fac.acc);
            //After con2 is inserted then con1 will be updated field Primary__c to false (only one contact can be primary)
            //System.assertEquals(1, [Select count() From Contact where AccountID =: fac.acc.Id And Primary__c = TRUE], 'Only one Contact should be primary.'); 
            //Field Finance_Contact__c/Portal_User__c of account will be populate with contact base on Role of contact
            Account acc = [Select Id, Finance_Contact__c, Portal_User__c From Account Where Id =: fac.acc.Id];
            System.assertEquals(con1.Id, acc.Portal_User__c);
            System.assertEquals(con2.Id, acc.Finance_Contact__c);
            
            //Case update contact
            con1.LastName='ChangeCont2';
            con1.Primary__c = true;
            update con1;
            //If con1 of account is updated then Primary of con2 will be updated to false
            //System.assertEquals(1, [Select count() From Contact where AccountID =: fac.acc.Id And Primary__c = TRUE], 'con1 is primary contact now.');
            //As con1 is primary > the other cannot be primary
            //System.assertEquals(2, [Select count() From Contact Where Id IN: new Set<String>{con2.Id, con3.Id} And Primary__c = false], 'Only one Contact should be primary.'); 
            //Delete related Contacts from Account => Finance_Contact__c/Portal_User__c of account will be blank
            //Delete[Select Id From Contact Where AccountId=:fac.acc.Id And Id IN: new Set<String>{con1.Id, con2.Id}];
            //acc = [Select Id, Finance_Contact__c, Portal_User__c From Account Where Id =: fac.acc.Id];
            //System.assertEquals(null, acc.Portal_User__c);
            //System.assertEquals(null, acc.Finance_Contact__c);
        Test.stopTest();
    }
    
    @isTest static void testOppPrimaryContact(){
        //retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        Test.startTest();
            //If one of contact of opp's account that have isActive=true & Primary__c=true so, The Primary_Contact__c of opp will be populated with that contact
            List<Contact> lstConts = (List<Contact>)GW_sObject.queryRecords('Contact', 'AccountId IN: idSet1 And isActive__c = TRUE And Primary__c = TRUE', new Map<String, Set<id>>{'idSet1' => new Set<Id>{fac.opp.AccountId}});
            System.assertEquals(fac.opp.Primary_Contact__c, lstConts.get(0).Id);
        Test.stopTest();
    }
    
    @isTest static void testInitialMemberUnitId(){
          Account acc = GW_Account.insertSObject();
          Contact con = GW_Contact.insertSObject('LastName', acc);
          Test.startTest();
              Case ca = new Case(status='New',MemberUnitId__c='test',MemberId__c='1234s',ContactId = con.id);
              if(String.isNotEmpty(GW_Case.recordTypeIdECGDKCS)) {
                ca.recordTypeId = GW_Case.recordTypeIdECGDKCS;
              }
              insert ca;
        Test.stopTest();
    }
    
    @isTest static void testSameFinancePortalContactOnAccount(){
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        Test.startTest();
            //contact with User Portal role and finance contact role
            Contact financeorportal = TST_DataFactory.createPrimaryContact('Test_Contact1', true, GW_Contact.ROLE_PORTAL_USER+';'+GW_Contact.ROLE_FINANCE_CONTACT, fac.acc);
            system.assert(([select count() from Account Where Portal_User__c =: financeorportal.Id or Finance_Contact__c =: financeorportal.Id] == 1), 'Finance & portal should link to same contact as financeorportal is a finance and also portal role.');
        Test.stopTest();
    }
    
    @isTest static void testValidateContactRolesOnAcc() {
        // retrieve test data
        TST_DataFactory fac = TST_DataFactory.getInstance();
        Test.startTest();
            //contact with prtal & finance contact role
            Contact financeorportal = TST_DataFactory.createPrimaryContact('Test_Contact1', true, GW_Contact.ROLE_PORTAL_USER+';'+GW_Contact.ROLE_FINANCE_CONTACT, fac.acc);
            //contact with User Portal role, it will be error as Account is belong to both roles
            try {
                //contact with User Portal role
                Contact con1 = TST_DataFactory.createPrimaryContact('Test_Contact1', true, GW_Contact.ROLE_PORTAL_USER, fac.acc);
            } catch (Exception ex) {
                system.assert((ex+'').contains('Please update existing contact to a new role'), 'Error will occurred as Account already has Financial contact or portal user.');
            }
        Test.stopTest();
    }
    
    @isTest static void testCheckPhoneNumbers() {
        Test.startTest();
            TST_DataFactory fac = TST_DataFactory.getInstance();
            //contact with no role
            Contact con = TST_DataFactory.createPrimaryContact('Test_Contact1', true, '', fac.acc);
            //phone number is updated as user input with correct format +xxxxxxxxx
            con.Phone = '+000000899';
            update con;
            system.assert([select Phone from Contact where Id =: con.Id].get(0).Phone == '+000000899', 'Phone field is updated.');
        Test.stopTest();            
    }
    
    @isTest static void testCheckPhoneNumbersError() {
        Test.startTest();
            TST_DataFactory fac = TST_DataFactory.getInstance();
            //contact with no role
            Contact con = TST_DataFactory.createPrimaryContact('Test_Contact1', true, '', fac.acc);
        
            //if user input with worng phone number format, error is occurred.
            try {
                con.Phone = '000000899';
                update con;
            } catch (Exception exp) {
                system.assert( (exp+'').contains('Phone number should start with \'+\' sign'), 'Phone field is not updated.');
            }
        Test.stopTest();
    }
    
    @isTest static void testValidateInactiveReason() {
        Contact con = GW_Contact.createSObject('CON_INACTIVE', new Account());
        con.isActive__c = false;
        Test.startTest();
            try {
                insert con;
            } catch (Exception exp) {
                system.assert( (exp+'').contains('You must enter a value.'), 'user cannot inactive a contact without the reason.');
            }
            
            con.Inactivation_Reason__c = 'Left Business';
            insert con;
            con = [select Id, isActive__c, Inactivation_Reason__c From Contact where Id =: con.Id];
            system.assert(!con.isActive__c, 'Now contact is inactivated as it has a reason.');
        Test.stopTest();
    }
}