/**
 * Created by ronvelzeboer on 23/09/16.
 */

@isTest
public with sharing class TST_UTIL_FieldValidator {
    public static DF factory;

    @testSetup
    static void setup() {
        UTIL.isRunningTestSetup = true;

//        List<UserRole> userRoles = [ SELECT Id, Name, ParentRoleId, RollupDescription, DeveloperName FROM UserRole ];
//        for (UserRole r : userRoles) {
//            UTIL.log('~!@ role Name: ' + r.Name);
//        }
//        List<Profile> profiles = [ SELECT Name FROM Profile ];
//        for (Profile p : profiles) {
//            UTIL.log('~!@ profile Name: ' + p.Name);
//        }
        factory = new DF(scenarios, scenarioUsers);
        factory.createFieldValidationRules = false;
        factory.setup();

        System.runAs(factory.userMap.get('admin')) {
            UTIL_CustomJob.createTestCustomJobs();
            UTIL_CustomJob.startAllCustomJobs();
        }
        UTIL.isRunningTestSetup = false;
    }

    @isTest
    static void testGlobalScopeShouldTriggerForMultipleMemberUnits() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'Global',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 0,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        ));
        insert rules;

        Map<String, Account> memberAccounts = new Map<String, Account>();
        for (Id accountId : result.accounts.keySet()) {
            memberAccounts.put(result.accounts.get(accountId).MemberId__c, result.accounts.get(accountId)) ;
        }
        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Contact c = new Contact(
                LastName = 'Do',
                AccountId = memberAccounts.get('ECGDK').Id,
                Phone = '+1234566',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('\'First Name\''), 'Validation should give hard error on Contact First Name for ECGDK');
        }
        System.runAs(result.users.get('EBAYKRE_Rep')) {
            Contact c = new Contact(
                LastName = 'Do',
                AccountId = memberAccounts.get('EBAYK').Id,
                Phone = '+1234566',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('\'First Name\''), 'Validation should give hard error on Contact First Name for EBAYK');
        }
    }

    @isTest
    static void testMemberScopeRuleOnSameFieldTriggersCorrectRule() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'ECGDK_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'ECGDK',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 0,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = '[0-9]{1,50}'
        ));
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'EBAYK_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'EBAYK',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 0,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = '[a-zA-Z]{1,50}'
        ));
        insert rules;

        Map<String, Account> memberAccounts = new Map<String, Account>();
        for (Id accountId : result.accounts.keySet()) {
            memberAccounts.put(result.accounts.get(accountId).MemberId__c, result.accounts.get(accountId)) ;
        }
        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Contact c = new Contact(
                FirstName = 'Abcdefg',
                LastName = 'Do',
                AccountId = memberAccounts.get('ECGDK').Id,
                Phone = '+1234566',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('[0-9]{1,50}'), 'Validation should trigger ECGDK rule');
        }
        System.runAs(result.users.get('EBAYKRE_Rep')) {
            Contact c = new Contact(
                FirstName = '1234567890',
                LastName = 'Do',
                AccountId = memberAccounts.get('EBAYK').Id,
                Phone = '+1234566',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('[a-zA-Z]{1,50}'), 'Validation should trigger EBAYK rule');
        }
    }

    @isTest
    static void testMemberUnitRuleWorksOnlyForMemberUnit() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });

        FieldValidation__c rule = new FieldValidation__c(
            Active__c = true,
            Name = 'ECGDK_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'ECGDK',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 0,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        );
        insert rule;

        Map<String, Account> memberAccounts = new Map<String, Account>();
        for (Id accountId : result.accounts.keySet()) {
            memberAccounts.put(result.accounts.get(accountId).MemberId__c, result.accounts.get(accountId)) ;
        }
        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Contact c = new Contact(
                LastName = 'Do',
                AccountId = memberAccounts.get('ECGDK').Id,
                Phone = '+1234566789',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('\'First Name\''), 'Validation should give error on Contact First Name');
        }
        System.runAs(result.users.get('EBAYKRE_Rep')) {
            Contact c = new Contact(
                LastName = 'Do',
                AccountId = memberAccounts.get('EBAYK').Id,
                Phone = '+1234566789',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assertEquals('', exceptionMsg, 'Validation rule should not fire for EBAYK');
        }
    }

    @isTest
    static void testRuleWithHigherPrecedenceShouldOverrideLower() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'ECGDK_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'ECGDK',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        ));
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'Global',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 0,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        ));
        insert rules;

        Map<String, Account> memberAccounts = new Map<String, Account>();
        for (Id accountId : result.accounts.keySet()) {
            memberAccounts.put(result.accounts.get(accountId).MemberId__c, result.accounts.get(accountId)) ;
        }

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Contact c = new Contact(
                LastName = 'Do',
                AccountId = memberAccounts.get('ECGDK').Id,
                Phone = '+1234566789',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assertEquals('', exceptionMsg, 'Validation should not give a hard error on Contact First Name, only incomplete message');
        }
        System.runAs(result.users.get('EBAYKRE_Rep')) {
            Contact c = new Contact(
                LastName = 'Do',
                AccountId = memberAccounts.get('EBAYK').Id,
                Phone = '+1234566789',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('\'First Name\''), 'Validation rule on global scope should have been fired');
        }
    }

    @isTest
    static void testDelegatedValidatorThrowsValidationError() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'Global',
            delegatedValidator__c = 'TST_UTIL_FieldValidator.DelegatedValidatorStubValidationError',
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        ));
        insert rules;

        Map<String, Account> memberAccounts = new Map<String, Account>();
        for (Id accountId : result.accounts.keySet()) {
            memberAccounts.put(result.accounts.get(accountId).MemberId__c, result.accounts.get(accountId)) ;
        }

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Contact c = new Contact(
                LastName = 'Do',
                AccountId = memberAccounts.get('ECGDK').Id,
                Phone = '+1234566',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('\'First Name\''), 'Validation rule on global scope should have fired a hard error');
        }
    }

    @isTest
    static void testDelegatedValidatorThrowsIncompleteError() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'members' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        FieldValidation__c rule = new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Account_AccountName',
            Object__c = 'Account',
            Scope__c = 'Global',
            delegatedValidator__c = 'TST_UTIL_FieldValidator.DelegatedValidatorStubIncompleteError',
            ErrorMessage__c = null,
            FieldName__c = 'Name',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        );
        insert rule;

        Member__c member;
        for (Member__c m : result.members.values()) {
            member = m;
            break;
        }

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Account acc = new Account(
                Name = 'testDelegatedValidatorThrowsIncompleteError',
                RecordTypeId = DF.getAccountRecordTypeId('Advertiser'),
                Member__c = member.Id,
                BillingStreet = 'Goethestrasse 97',
                BillingPostalCode = '19053',
                BillingCity = 'Schwerin',
                BillingCountry = 'Germany'
            );
            String exceptionMsg = '';
            try {
                insert acc;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assertEquals('', exceptionMsg, 'Validation rule should not trigger hard error.');
            DF_Scenario.Result afterResult = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'accounts' });

            Account savedAcc;

            for (Account a : afterResult.accounts.values()) {
                if (a.Name.equals('testDelegatedValidatorThrowsIncompleteError')) {
                    savedAcc = a;
                    break;
                }
            }
            System.assert(null != savedAcc, 'Account should have been saved');
            System.assert(null != savedAcc.RequiredForNextStage__c && savedAcc.RequiredForNextStage__c.contains('Name'), 'Validation rule should give incompleteError on \'Name\' field.');
        }
    }

    @isTest
    static void testDelegatedValidatorThrowsMandatoryValueError() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'members' });

        FieldValidation__c rule = new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Account_Account_Status__c',
            Object__c = 'Account',
            Scope__c = 'Global',
            delegatedValidator__c = 'TST_UTIL_FieldValidator.DelegatedValidatorStubMandatoryValueError',
            ErrorMessage__c = null,
            FieldName__c = 'Account_Status__c',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = 'Active',
            Param__c = null,
            Regex__c = null
        );
        insert rule;

        Member__c member;
        for (Member__c m : result.members.values()) {
            member = m;
            break;
        }

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Account acc = new Account(
                Name = 'testDelegatedValidatorThrowsIncompleteMessage',
                RecordTypeId = DF.getAccountRecordTypeId('Advertiser'),
                Member__c = member.Id,
                Account_Status__c = 'Suspended - Bad Debt'
            );
            String exceptionMsg = '';
            try {
                insert acc;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assertEquals('', exceptionMsg, 'Validation rule should not trigger hard error.');

            DF_Scenario.Result afterResult = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'accounts' });

            Account savedAcc;

            for (Account a : afterResult.accounts.values()) {
                if (a.Name.equals('testDelegatedValidatorThrowsIncompleteMessage')) {
                    savedAcc = a;
                    break;
                }
            }
            System.assert(null != savedAcc, 'Account should have been saved');
            System.assert(null != savedAcc.RequiredForNextStage__c && savedAcc.RequiredForNextStage__c.contains('Account Status'), 'Validation rule should give incompleteError on \'Account Status\' field.');
        }
    }

    @isTest
    static void testRegexValidationError() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });

        FieldValidation__c rule = new FieldValidation__c(
            Active__c = true,
            Name = 'ECGDK_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'ECGDK',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = '[a-zA-Z\\s]{1,50}'
        );
        insert rule;
        Map<String, Account> memberAccounts = new Map<String, Account>();
        for (Id accountId : result.accounts.keySet()) {
            memberAccounts.put(result.accounts.get(accountId).MemberId__c, result.accounts.get(accountId)) ;
        }
        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Contact c = new Contact(
                FirstName = 'John Do1',
                LastName = 'Do',
                AccountId = memberAccounts.get('ECGDK').Id,
                Phone = '+1234566789',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String exceptionMsg = '';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('\'First Name\''), 'Validation should give error on Contact First Name');

            exceptionMsg = '';
            c.FirstName = 'John Do';
            try {
                insert c;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assertEquals('', exceptionMsg, 'Validation should not give error on Contact First Name');
        }

    }

    @isTest
    static void testMultipleInvalidFieldsShouldGenerateMultipleErrors() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'accounts' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'ECGDK_Contact_FirstName',
            Object__c = 'Contact',
            Scope__c = 'ECGDK',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'FirstName',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 0,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        ));
        rules.add(new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Descripton_FirstName',
            Object__c = 'Contact',
            Scope__c = 'Global',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'Description',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 0,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        ));
        insert rules;

        Map<String, Account> memberAccounts = new Map<String, Account>();
        for (Id accountId : result.accounts.keySet()) {
            memberAccounts.put(result.accounts.get(accountId).MemberId__c, result.accounts.get(accountId)) ;
        }

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Contact c = new Contact(
                LastName = 'Do',
                AccountId = memberAccounts.get('ECGDK').Id,
                Phone = '+1234566',
                Email = 'Do=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = null
            );
            Boolean firstNameErrorFound = false;
            Boolean descriptionErrorFound = false;
            try {
                insert c;
            } catch (System.DmlException e) {
                List<ApexPages.Message> vfPageMessages = ApexPages.getMessages();

                for (ApexPages.Message msg : vfPageMessages) {
                    if (msg.getSummary().contains('First Name')) {
                        firstNameErrorFound = true;
                    } else if (msg.getSummary().contains('Description')) {
                        descriptionErrorFound = true;
                    }
                }
            }
            System.assert(firstNameErrorFound, 'Validation should give error on Contact First Name');
            System.assert(descriptionErrorFound, 'Validation should give error on Contact Description');
        }
    }

    @isTest
    static void testMandatoryValueThrowsIncompleteMessage() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'members' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        FieldValidation__c rule = new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Account_Account_Status__c',
            Object__c = 'Account',
            Scope__c = 'Global',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'Account_Status__c',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = 'Active',
            Param__c = null,
            Regex__c = null
        );
        insert rule;

        Member__c member;
        for (Member__c m : result.members.values()) {
            member = m;
            break;
        }

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Account acc = new Account(
                Name = 'testMandatoryValueThrowsIncompleteMessage',
                RecordTypeId = DF.getAccountRecordTypeId('Advertiser'),
                Member__c = member.Id,
                Account_Status__c = 'Suspended - Bad Debt'
            );
            String exceptionMsg = '';
            try {
                insert acc;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assertEquals('', exceptionMsg, 'Validation rule should not trigger hard error.');

            DF_Scenario.Result afterResult = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'accounts' });

            Account savedAcc;

            for (Account a : afterResult.accounts.values()) {
                if (a.Name.equals('testMandatoryValueThrowsIncompleteMessage')) {
                    savedAcc = a;
                    break;
                }
            }
            System.assert(null != savedAcc, 'Account should have been saved');
            System.assert(null != savedAcc.RequiredForNextStage__c && savedAcc.RequiredForNextStage__c.contains('Account Status'), 'Validation rule should give incompleteError on \'Account Status\' field.');
        }
    }

    @isTest
    static void testMandatoryValueThrowsMandatoryValueError() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'members' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        FieldValidation__c rule = new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Account_Account_Status__c',
            Object__c = 'Account',
            Scope__c = 'Global',
            delegatedValidator__c = null,
            ErrorMessage__c = null,
            FieldName__c = 'Account_Status__c',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 0,
            MandatoryValue__c = 'Active',
            Param__c = null,
            Regex__c = null
        );
        insert rule;

        Member__c member;
        for (Member__c m : result.members.values()) {
            member = m;
            break;
        }

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Account acc = new Account(
                Name = 'Jane Do',
                RecordTypeId = DF.getAccountRecordTypeId('Advertiser'),
                Member__c = member.Id,
                Account_Status__c = 'Suspended - Bad Debt'
            );
            String exceptionMsg = '';
            try {
                insert acc;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('\'Account Status\''), 'Validation should give error on Account Account_Status__c');
        }
    }

    @isTest
    static void testMessageVariableReplacedByFieldValue() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'members' });

        List<FieldValidation__c> rules = new List<FieldValidation__c>();
        FieldValidation__c rule = new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Account_Account_Status__c',
            Object__c = 'Account',
            Scope__c = 'Global',
            delegatedValidator__c = null,
            ErrorMessage__c = 'Account Status should not be {{Account_Status__c}}',
            FieldName__c = 'Account_Status__c',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = 'Active',
            Param__c = null,
            Regex__c = null
        );
        insert rule;

        Member__c member;
        for (Member__c m : result.members.values()) {
            member = m;
            break;
        }

        System.runAs(result.users.get('ECGDKAD_adsalesRep')) {
            Account acc = new Account(
                Name = 'testMessageVariableReplacedByFieldValue',
                RecordTypeId = DF.getAccountRecordTypeId('Advertiser'),
                Member__c = member.Id,
                Account_Status__c = 'Suspended - Bad Debt'
            );
            String exceptionMsg = '';
            try {
                insert acc;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assertEquals('', exceptionMsg, 'Validation rule should not trigger hard error.');

            DF_Scenario.Result afterResult = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'accounts' });

            Account savedAcc;

            for (Account a : afterResult.accounts.values()) {
                if (a.Name.equals('testMessageVariableReplacedByFieldValue')) {
                    savedAcc = a;
                    break;
                }
            }
            System.assert(null != savedAcc, 'Account should have been saved');
            System.assert(null != savedAcc.RequiredForNextStage__c && savedAcc.RequiredForNextStage__c.contains('Account Status should not be Suspended - Bad Debt'), 'Validation message variable should have been replaced');
        }
    }

    @isTest
    static void testAccountVATFieldDelegatedValidator() {
        DF_Scenario.Result result = DF.queryResults(scenarios, scenarioUsers, new Set<String> { 'users', 'members' });

        FieldValidation__c rule = new FieldValidation__c(
            Active__c = true,
            Name = 'Global_Account_VATFields',
            Object__c = 'Account',
            Scope__c = 'EBAYK',
            delegatedValidator__c = 'VAL_EBAYK.AccountVATFieldsValidator',
            ErrorMessage__c = 'ApplyVAT and CompanyVAT cannot have a value at the same time',
            FieldName__c = '-',
            FieldType__c = null,
            MandatoryFromStatusNum__c = 1,
            MandatoryValue__c = null,
            Param__c = null,
            Regex__c = null
        );
        insert rule;

        Member__c member;
        for (Member__c m : result.members.values()) {
            if (m.memberId__c == 'EBAYK') {
                member = m;
                break;
            }
        }

        insert new Configuration__c(Name='VIESCountries', Value__c='AT,BE,BG,CY,CZ,DE,DK,EE,EL,ES,FI,FR,GB,HU,IE,LT,LU,LV,MT,NL,PL,PT,RO,SE,SK');

        System.runAs(result.users.get('EBAYKRE_Rep')) {
            Account acc = new Account(
                Name = 'Jane Do',
                RecordTypeId = DF.getAccountRecordTypeId('Advertiser'),
                Member__c = member.Id,
                VAT__c = 19,
                Apply_VAT__c = true,
                Company_VAT_No__c = 'DE123456789'
            );
            String exceptionMsg = '';
            try {
                insert acc;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assert(exceptionMsg.contains('ApplyVAT and CompanyVAT cannot have a value at the same time'), 'Validation should give error on Account AppyVAT and CompanyVAT');

            exceptionMsg = '';
            acc.Apply_VAT__c = false;
            try {
                insert acc;
            } catch (System.DmlException e) {
                exceptionMsg = e.getMessage();
            }
            System.assertEquals('', exceptionMsg, 'Validation should not give error on Account AppyVAT and CompanyVAT. Found error: ' + exceptionMsg);
        }
    }

    public class DelegatedValidatorStubValidationError implements UTIL_FieldValidator.IDelegatedValidator {
        public UTIL_FieldValidator.IFieldValidationResult validate(sObject so, FieldValidation__c fv) {
            return new UTIL_FieldValidator.InvalidErrorResult(so, GW_sObject.getFieldLabel(fv.Object__c, fv.FieldName__c), fv, null);
        }
    }

    public class DelegatedValidatorStubIncompleteError implements UTIL_FieldValidator.IDelegatedValidator {
        public UTIL_FieldValidator.IFieldValidationResult validate(sObject so, FieldValidation__c fv) {
            return new UTIL_FieldValidator.IncompleteErrorResult(so, GW_sObject.getFieldLabel(fv.Object__c, fv.FieldName__c), fv, null);
        }
    }

    public class DelegatedValidatorStubMandatoryValueError implements UTIL_FieldValidator.IDelegatedValidator {
        public UTIL_FieldValidator.IFieldValidationResult validate(sObject so, FieldValidation__c fv) {
            return new UTIL_FieldValidator.MandatoryValueErrorResult(so, GW_sObject.getFieldLabel(fv.Object__c, fv.FieldName__c), fv, null);
        }
    }

    public static List<DF_Scenario> scenarios;
    public static Map<String, Map<String, String>> scenarioUsers;

    static {
        scenarioUsers = new Map<String, Map<String, String>> {
            'ECGDKAD_adsalesRep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'ECGDKAD',
                DF_Scenario.CONF_USER_PROFILE   => 'ECGDK Ad Sales Rep',
                DF_Scenario.CONF_USER_USE_FOR   => 'All'
            },
            'EBAYKRE_Rep' => new Map<String, String> {
                DF_Scenario.CONF_USER_ROLE      => 'EBAYKRE_Rep',
                DF_Scenario.CONF_USER_PROFILE   => 'Real Estate',
                DF_Scenario.CONF_USER_USE_FOR   => 'All'
            }
        };

        scenarios = new List<DF_Scenario> {
            new DF_Scenario('ECGDKAD-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'ECGDK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'AD',
                DF_Scenario.CONF_USERS               => new List<String> { 'ECGDKAD_adsalesRep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser'
            }),
            new DF_Scenario('EBAYKRE-01', new Map<String, Object> {
                DF_Scenario.CONF_MEMBER              => 'EBAYK',
                DF_Scenario.CONF_MEMBER_UNIT         => 'RE',
                DF_Scenario.CONF_USERS               => new List<String> { 'EBAYKRE_Rep' },
                DF_Scenario.CONF_ACCOUNT_RECORD_TYPE => 'Advertiser'
            })
        };
    }
}