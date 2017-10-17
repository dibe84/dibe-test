/**
 * Created by ronvelzeboer on 26/07/16.
 */

public class DF {
    public static final String INVOICE_GROUPING_1_INV_PER_BATCH = '1 Invoice per Batch';
    public static final String INVOICE_GROUPING_1_INV_PER_OPP_PER_BATCH = '1 Invoice per Opportunity per Batch';

    public Boolean createFieldValidationRules = false;

    private List<DF_Scenario> scenarios;
    private Map<String, Map<String, String>> scenarioUsers;

    private Map<String, List<String>> membersAndMemberUnitConfig;

    private Map<String, UserRole> roleMap = new Map<String, UserRole>();

    // Map<{USER_ALIAS}, User>
    public Map<String, User> userMap = new Map<String, User>();

    // Map<{SCENARIO_ID}, {USERALIAS}>
    public Map<String, String> scenarioOppUserMap = new Map<String, String>();

    // Map<{MEMBER_NAME}, Account>
    private Map<String, Account> memberAccountMap = new Map<String, Account>();

    // Map<{MEMBER_NAME}, Member__c>
    private Map<String, Member__c> memberMap = new Map<String, Member__c>();

    // Map<{MEMBERUNIT_ID}, MemberUnit__C>
    private Map<String, MemberUnit__c> memberUnitMap = new Map<String, MemberUnit__c>();

    // Map<{MEMBERUNIT_NAME}.{PRICEBOOK_NAME}, Pricebook2>
    private Map<String, Pricebook2> pricebookMap = new Map<String, Pricebook2>();

    // Map<{MEMBERUNIT_ID}.{PRICEBOOK_NAME}, List<List<SObject>>>
    private Map<String, List<List<SObject>>> pricebookEntryMap = new Map<String, List<List<SObject>>>();

    private Map<String, Account> accountMap = new Map<String, Account>();

    private Map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();

//    private Map<String, DF_Scenario.Result> scenarioResults = new Map<String, DF_Scenario.Result>();

//    // Map<{MEMBER_NAME}, List<{MEMBERUNIT_NAME}>>
//    private Map<String, List<String>> memberAndMemberUnitConfig;

    public static Id standardPricebookId {
        get {
            if (null == standardPricebookId) {
                if (Test.isRunningTest()) {
                    standardPricebookId = Test.getStandardPricebookId();
                } else {
                    Pricebook2 pb = [SELECT Id FROM Pricebook2 where isStandard = true];
                    standardPricebookId = pb.Id;
                }
            }
            return standardPricebookId;
        }
    }

    public static Map<String,RecordType> recordTypeNameMap {
        get {
            if (recordTypeNameMap == null) {
                List<RecordType> recordTypes = (List<RecordType>) GW_sObject.queryRecords('RecordType', '');
                recordTypeNameMap = new Map<String,RecordType>();
                for (RecordType rt : recordTypes) {
                    recordTypeNameMap.put(rt.sObjectType + '_' + rt.DeveloperName, rt);
                }
                UTIL.cache(recordTypeNameMap.values());
            }
            return recordTypeNameMap;
        }
    }

    public DF(List<DF_Scenario> scenarios, Map<String, Map<String, String>> scenarioUsers) {
        this.scenarios = scenarios;
        this.scenarioUsers = scenarioUsers;
    }

    public static DF_Scenario.Result queryResults(List<DF_Scenario> scenarios, Map<String, Map<String, String>> scenarioUsers) {
        return queryResults(scenarios, scenarioUsers, null);
    }

    public static DF_Scenario.Result queryResults(List<DF_Scenario> scenarios, Map<String, Map<String, String>> scenarioUsers, Set<String> objToQuery) {
        DF_Scenario.Result result = new DF_Scenario.Result();

        if (null == objToQuery || objToQuery.contains('users')) {
            Map<String, Map<String, String>> userConfig = buildUserConfig(scenarioUsers);

            List<String> userNames = new List<String>();

            for (String key : userConfig.keySet()) {
                userNames.add(userConfig.get(key).get('userName'));
            }
            List<User> users = (List<User>) GW_sObject.queryRecords('User', 'Username IN (\'' + String.join(userNames, '\', \'') + '\')');
            for (User u : users) {
                for (String key : userConfig.keySet()) {
                    if (userConfig.get(key).get('userName') == u.Username) {
                        result.users.put(key, u);
                        break;
                    }
                }
            }
        }
        if (null == objToQuery || objToQuery.contains('members')) {
            List<Member__c> members = (List<Member__c>) GW_sObject.queryRecords('Member__c', 'Id <> null');
            result.members = new Map<String, Member__c>();
            for (Member__c member : members) {
                result.members.put(member.MemberId__c, member);
            }
        }
        if (null == objToQuery || objToQuery.contains('memberunits')) {
            result.memberunits = new Map<Id, MemberUnit__c>((List<MemberUnit__c>) GW_sObject.queryRecords('MemberUnit__c', 'Id <> null'));
        }
        if (null == objToQuery || objToQuery.contains('accounts')) {
            RecordType rtMember = recordTypeNameMap.get('Account_Member');
            result.accounts = new Map<Id, Account>((List<Account>) GW_sObject.queryRecords('Account', 'RecordTypeId <> \'' + rtMember.Id + '\' ORDER BY Id')); // skip the created Member Account record
        }
        if (null == objToQuery || objToQuery.contains('oppMap')) {
            List<Opportunity> opps = GW_sObject.queryRecords('Opportunity', ' Id <> null ORDER BY Id');

            for (Opportunity opp : opps) {
                result.oppMap.put(opp.Touch__c, opp);
            }
        }
        if (null == objToQuery || objToQuery.contains('oliMap')) {
            List<OpportunityLineItem> olis = GW_sObject.queryRecords('OpportunityLineItem', ' Id <> null ORDER BY Id');

            for (OpportunityLineItem oli : olis) {
                for (String oliKey : oli.Touch__c.split(';')) {
                    result.oliMap.put(oliKey, oli);
                }
            }
        }
        if (null == objToQuery || objToQuery.contains('products')) {
            result.products = new Map<Id, Product2>((List<Product2>) GW_sObject.queryRecords('Product2', 'Id <> null ORDER BY Id'));
        }
        if (null == objToQuery || objToQuery.contains('pbes')) {
            result.pbes = new Map<Id, PricebookEntry>((List<PricebookEntry>) GW_sObject.queryRecords('PricebookEntry', ' Id <> null ORDER BY Id'));
        }
        if (null == objToQuery || objToQuery.contains('contacts')) {
            result.contacts = new Map<Id, Contact>((List<Contact>) GW_sObject.queryRecords('Contact', ' Id <> null ORDER BY Id'));
        }
        if (null == objToQuery || objToQuery.contains('revs')) {
            result.revs = new Map<Id, Rev__c>((List<Rev__c>) GW_sObject.queryRecords('Rev__c', ' Id <> null ORDER BY Id'));
        }
        if (null == objToQuery || objToQuery.contains('rss')) {
            result.rss = new Map<Id, RS__c>((List<RS__c>) GW_sObject.queryRecords('RS__c', ' Id <> null ORDER BY Id'));
        }
        if (null == objToQuery || objToQuery.contains('metrics')) {
            result.metrics = new Map<Id, Metric__c>((List<Metric__c>) GW_sObject.queryRecords('Metric__c', ' Id <> null ORDER BY Id'));
        }
        if (null == objToQuery || objToQuery.contains('invoices')) {
            result.invoices = new Map<Id, Invoice__c>((List<Invoice__c>) GW_sObject.queryRecords('Invoice__c', ' Id <> null ORDER BY Id'));
        }
        if (null == objToQuery || objToQuery.contains('invoiceLines')) {
            result.invoiceLines = new Map<Id, InvoiceLine__c>((List<InvoiceLine__c>) GW_sObject.queryRecords('InvoiceLine__c', ' Id <> null ORDER BY Id'));
        }
        if (null == objToQuery || objToQuery.contains('customAttributeDefinitions')) {
            result.customAttributeDefinitions = GW_sObject.queryRecords('CustomAttributeDefinition__c', 'Id <> null ORDER By Id');
        }

//        for (String oliKey : result.oliMap.keySet()) {
//            for (Rev__c rev : result.revs.values()) {
//                if (rev.OpportunityLineItemId__c == result.oliMap.get(oliKey).Id) {
//                    String revMapKey = oliKey + '.revs';
//                    if (!result.revMap.containsKey(revMapKey)) {
//                        result.revMap.put(revMapKey, new List<Rev__c>());
//                    }
//                    result.revMap.get(revMapKey).add(rev);
//                }
//            }
//        }
//
//        for (String revsKey : result.revMap.keySet()) {
//
//        }

        return result;
    }

    public static void requeryResults(DF_Scenario.Result result, Set<String> objToRequery) {
        if(objToRequery.contains('products')) result.products = new Map<Id, Product2>((List<Product2>) GW_sObject.queryRecords('Product2', 'Id <> null ORDER BY Id'));
        if(objToRequery.contains('pbes')) result.pbes = new Map<Id, PricebookEntry>((List<PricebookEntry>) GW_sObject.queryRecords('PricebookEntry', ' Id <> null ORDER BY Id'));
        if(objToRequery.contains('contacts')) result.contacts = new Map<Id, Contact>((List<Contact>) GW_sObject.queryRecords('Contact', ' Id <> null ORDER BY Id'));
        if(objToRequery.contains('revs')) result.revs = new Map<Id, Rev__c>((List<Rev__c>) GW_sObject.queryRecords('Rev__c', ' Id <> null ORDER BY Id'));
        if(objToRequery.contains('rss')) result.rss = new Map<Id, RS__c>((List<RS__c>) GW_sObject.queryRecords('RS__c', ' Id <> null ORDER BY Id'));
        if(objToRequery.contains('metrics')) result.metrics = new Map<Id, Metric__c>((List<Metric__c>) GW_sObject.queryRecords('Metric__c', ' Id <> null ORDER BY Id'));
        if(objToRequery.contains('invoices')) result.invoices = new Map<Id, Invoice__c>((List<Invoice__c>) GW_sObject.queryRecords('Invoice__c', ' Id <> null ORDER BY Id'));
        if(objToRequery.contains('invoiceLines')) result.invoiceLines = new Map<Id, InvoiceLine__c>((List<InvoiceLine__c>) GW_sObject.queryRecords('InvoiceLine__c', ' Id <> null ORDER BY Id'));
        if(objToRequery.contains('customAttributeDefinitions')) result.customAttributeDefinitions = GW_sObject.queryRecords('CustomAttributeDefinition__c', 'Id <> null ORDER By Id');

        if(objToRequery.contains('oppMap')) {
            List<Opportunity> opps = GW_sObject.queryRecords('Opportunity', ' Id <> null ORDER BY Id');
            for (Opportunity opp : opps) {
                result.oppMap.put(opp.Touch__c, opp);
            }
        }
        if(objToRequery.contains('oliMap')) {
            List<OpportunityLineItem> olis = GW_sObject.queryRecords('OpportunityLineItem', ' Id <> null ORDER BY Id');
            for (OpportunityLineItem oli : olis) {
                for (String oliKey : oli.Touch__c.split(';')) {
                    result.oliMap.put(oliKey, oli);
                }
            }
        }
    }

    public void setup() {
//        createScenarioResultBuckets();

        User runningUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs(runningUser) {
            createRoleHierarchy();
            Map<String, Map<String, String>> userConfig = buildUserConfig(scenarioUsers);
            createUsers(userConfig);
        }
        createCustomSettings();
        scenarioOppUserMap = createScenarioOpportunityUserConfig(scenarios);
        createMembersAndMemberUnits();
        createCustomLabels();
        createPricebookData();
        createAccounts();
        createContacts();
        createOpportunities();
        createOpportunityLineItems();
//        UTIL.log('~!@ sc results: ' + scenarioResults);
//        return scenarioResults;
    }

    private void createRoleHierarchy() {
//        UserRole countryLevelRole = new UserRole(Name='ECG', DeveloperName='ECG');
//        insert countryLevelRole;
//
//        List<UserRole> roles = new List<UserRole>();
//        for (String memberName : membersAndMemberUnitConfig.keySet()) {
//            UserRole role = new UserRole(Name = memberName, ParentRoleId = countryLevelRole.Id, DeveloperName = memberName);
//            roleMap.put(memberName, role);
//            roles.add(role);
//        }
//        insert roles;
//
//        roles = new List<UserRole>();
//        for (String memberName : membersAndMemberUnitConfig.keySet()) {
//            for (String memberUnit : membersAndMemberUnitConfig.get(memberName)) {
//                String roleName = memberName + memberUnit;
//                UserRole role = new UserRole(Name = roleName, ParentRoleId = roleMap.get(memberName).Id, DeveloperName = roleName);
//                roleMap.put(roleName, role);
//                roles.add(role);
//            }
//        }
//        insert roles;
    }

    private static Map<String, Map<String, String>> buildUserConfig(Map<String, Map<String, String>> scenarioUsers) {
        Map<String, Map<String, String>> config = new Map<String, Map<String, String>> { 'admin' => new Map<String, String> { 'userName' => 'admin@ecgtests.com', 'userRole' => 'ECG', 'userProfile' => 'System Administrator' } };

        for (String userAlias : scenarioUsers.keySet()) {
            if (config.containsKey(userAlias)) {
                continue;
            }
            config.put(userAlias, new Map<String, String> {
                'userName'                    => userAlias + '@ecgtests.com',
                DF_Scenario.CONF_USER_ROLE    => scenarioUsers.get(userAlias).get(DF_Scenario.CONF_USER_ROLE),
                DF_Scenario.CONF_USER_PROFILE => scenarioUsers.get(userAlias).get(DF_Scenario.CONF_USER_PROFILE)
            });
        }
        return config;
    }

    private Map<String, String> createScenarioOpportunityUserConfig(List<DF_Scenario> scenarios) {
        Map<String, String> result = new Map<String, String>();

        for (DF_Scenario sc : scenarios) {
            for (String userAlias : sc.users) {
                Map<String, String> userSettings = scenarioUsers.get(userAlias);

                if ((userSettings.get(DF_Scenario.CONF_USER_USE_FOR) != 'Opportunity' && userSettings.get(DF_Scenario.CONF_USER_USE_FOR) != 'All')
                    || result.containsKey(userAlias)
                ) {
                    continue;
                }
                result.put(sc.scenarioId, userAlias);
            }
        }
        return result;
    }

    private void createUsers(Map<String, Map<String, String>> config) {
        for (String userAlias : config.keySet()) {
            if (userMap.containsKey(userAlias)) {
                continue;
            }
            User u = GW_User.createTestUser(
                config.get(userAlias).get('userName'),
                config.get(userAlias).get(DF_Scenario.CONF_USER_ROLE),
                //Changing on member unit sharing to private caused profile error, we need to enforce profile as admin
                //config.get(userAlias).get(DF_Scenario.CONF_USER_PROFILE)
                'System Administrator'
            );
            u.LanguageLocaleKey = 'en_US';
            userMap.put(userAlias, u);
        }
        try {
            Database.insert(userMap.values(),false); // Workaround
        } catch (Exception ex) {
            UTIL.Log('XX Expect the unexpected: ' + ex);
        }
    }

    private void createCustomSettings() {
        // UTIL_RecordRestriction.createMissingRestrictionRules();
//        insert dataSet.constructWebserviceSettings();
        createFieldValidationRules();
    }

    private void createFieldValidationRules() {
        if (false == createFieldValidationRules || fieldValidationRulesAlreadyCreated()) {
            return;
        }
        List<Map<String, String>> defaultRules = new List<Map<String, String>> {
            new Map<String, String> {
                'Name' => 'Global_Lead_Company', 'Object' => 'Lead', 'Scope' => 'Global', 'delegatedValidator' => null, 'ErrorMessage' => null,
                'FieldName' => 'Company', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => null
            },
            new Map<String, String> {
                'Name' => 'Global_Lead_LastName', 'Object' => 'Lead', 'Scope' => 'Global', 'delegatedValidator' => null, 'ErrorMessage' => null,
                'FieldName' => 'LastName', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => null
            },
            new Map<String, String> {
                'Name' => 'Global_Lead_Status', 'Object' => 'Lead', 'Scope' => 'Global', 'delegatedValidator' => null, 'ErrorMessage' => null,
                'FieldName' => 'Status', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => 'Qualified', 'Param' => null, 'Regex' => null
            },
            new Map<String, String> {
                'Name' => 'EBAYK_Account_LocalPlatformId', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => null, 'ErrorMessage' => null,
                'FieldName' => 'UniquePlatformId__c', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => null
            },
            new Map<String, String> {
                'Name' => 'EBAYK_Account_AccountName', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => null, 'ErrorMessage' => null,
                'FieldName' => 'Name', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => '.{1,50}'
            },
            new Map<String, String> {
                'Name' => 'Global_Account_FQ_SyncStatus', 'Object' => 'Account', 'Scope' => 'Global', 'delegatedValidator' => null, 'ErrorMessage' => 'Account sync in progress...',
                'FieldName' => 'FQ_SyncStatus__c', 'FieldType' => 'SYNC', 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => 'OK', 'Param' => null, 'Regex' => null
            },
            new Map<String, String> {
                'Name' => 'EBAYK_Account_BillingStreet', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => null, 'ErrorMessage' => null,
                'FieldName' => 'BillingStreet', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => '.{1,50}'
            },
            new Map<String, String> {
                'Name' => 'EBAYK_Account_BillingPostalCode', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => null, 'ErrorMessage' => 'Billing Postal Code should consist of 5 digits',
                'FieldName' => 'BillingPostalCode', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => '[0-9]{5}'
            },
            new Map<String, String> {
                'Name' => 'EBAYK_Account_BillingCountry', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => null, 'ErrorMessage' => 'Billing Country not set',
                'FieldName' => 'BillingCountryCode', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => null
            },
            new Map<String, String> {
                'Name' => 'EBAYK_Account_BillingCity', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => null, 'ErrorMessage' => null,
                'FieldName' => 'BillingCity', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => '.{1,50}'
            },
//            new Map<String, String> {
//                'Name' => 'EBAYK_Account_CustomAttr_FTPUsername', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => 'VAL_Global.AccountCustomAttributeValidator', 'ErrorMessage' => null,
//                'FieldName' => 'CustomAttribute.ftpUsername', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => 'EBAYKRE', 'Regex' => null
//            },
//            new Map<String, String> {
//                'Name' => 'EBAYK_Account_CustomAttr_FTPPassword', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => 'VAL_Global.AccountCustomAttributeValidator', 'ErrorMessage' => null,
//                'FieldName' => 'CustomAttribute.ftpPassword', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => 'EBAYKRE', 'Regex' => null
//            },
            new Map<String, String> {
                'Name' => 'EBAYK_Account_ApplyVAT_CompanyVAT', 'Object' => 'Account', 'Scope' => 'EBAYK', 'delegatedValidator' => 'VAL_EBAYK.AccountVATFieldsValidator', 'ErrorMessage' => '\'Company VAT No.\' and \'Apply VAT\' cannot be set at the same time',
                'FieldName' => '-', 'FieldType' => null, 'MandatoryFromStatusNum' => '1', 'MandatoryValue' => null, 'Param' => null, 'Regex' => null
            },
            new Map<String, String> {
                'Name' => 'ECGDK_Contact_FirstName', 'Object' => 'Contact', 'Scope' => 'ECGDK', 'delegatedValidator' => null, 'ErrorMessage' => null,
                'FieldName' => 'FirstName', 'FieldType' => null, 'MandatoryFromStatusNum' => '0', 'MandatoryValue' => null, 'Param' => null, 'Regex' => null
            }
        };
        List<FieldValidation__c> rulesToInsert = new List<FieldValidation__c>();
        for (Map<String, String> ruleSettings : defaultRules) {
            FieldValidation__c rule = new FieldValidation__c(
                Active__c = true,
                Name = ruleSettings.get('Name'),
                Object__c = ruleSettings.get('Object'),
                Scope__c = ruleSettings.get('Scope'),
                delegatedValidator__c = ruleSettings.get('delegatedValidator'),
                ErrorMessage__c = ruleSettings.get('ErrorMessage'),
                FieldName__c = ruleSettings.get('FieldName'),
                FieldType__c = ruleSettings.get('FieldType'),
                MandatoryFromStatusNum__c = Integer.valueOf(ruleSettings.get('MandatoryFromStatusNum')),
                MandatoryValue__c = ruleSettings.get('MandatoryValue'),
                Param__c = ruleSettings.get('Param'),
                Regex__c = ruleSettings.get('Regex')
            );
            rulesToInsert.add(rule);
        }
        if (rulesToInsert.size() > 0) {
            UTIL.log('~!@ before insert rules: ' + rulesToInsert);
            insert rulesToInsert;
        }
    }

    private Boolean fieldValidationRulesAlreadyCreated() {
        List<FieldValidation__c> currentValidations = FieldValidation__c.getall().values();
        return null != currentValidations && currentValidations.size() > 0;
    }

    private void createCustomLabels() {
        List<Custom_ECG_Labels__c> customLabels = new List<Custom_ECG_Labels__c>();
        for (String memberUnitId : memberUnitMap.keySet()) {
            customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_' + memberUnitId, Value__c='TEST IO SUBJECT'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_' + memberUnitId + '_EN', Value__c='TEST IO SUBJECT'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_' + memberUnitId + '_FR', Value__c='TEST IO SUBJECT'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_' + memberUnitId + '_DE', Value__c='TEST IO SUBJECT'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOSubject_' + memberUnitId + '_NL', Value__c='TEST IO SUBJECT'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOName_' + memberUnitId, Value__c='TEST IO NAME'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOName_' + memberUnitId + '_EN', Value__c='TEST IO NAME'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOName_' + memberUnitId + '_FR', Value__c='TEST IO NAME'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOName_' + memberUnitId + '_DE', Value__c='TEST IO NAME'));
            customLabels.add(new Custom_ECG_Labels__c(Name='IOName_' + memberUnitId + '_NL', Value__c='TEST IO NAME'));
            customLabels.add(new Custom_ECG_Labels__c(Name='MandateSubject_' + memberUnitId , Value__c='TEST Mandate Subject'));
            customLabels.add(new Custom_ECG_Labels__c(Name='MandateSubject_' + memberUnitId + '_EN', Value__c='TEST Mandate Subject'));
            customLabels.add(new Custom_ECG_Labels__c(Name='MandateSubject_' + memberUnitId + '_FR', Value__c='TEST Mandate Subject'));
            customLabels.add(new Custom_ECG_Labels__c(Name='MandateSubject_' + memberUnitId + '_DE', Value__c='TEST Mandate Subject'));
            customLabels.add(new Custom_ECG_Labels__c(Name='MandateSubject_' + memberUnitId + '_NL', Value__c='TEST Mandate Subject'));
        }
        insert customLabels;
    }

    private void createMembersAndMemberUnits() {
        membersAndMemberUnitConfig = buildMembersAndMemberUnitsConfig();
        memberAccountMap = createMemberAccounts(new List<String>(membersAndMemberUnitConfig.keySet()));
        memberMap        = createMembers(memberAccountMap);
        memberUnitMap    = createMemberUnits(membersAndMemberUnitConfig, memberMap);
        updateMemberDefaultMemberUnit(memberMap, memberUnitMap);
    }

    private void createPricebookData() {
        pricebookMap = createPricebooks(buildPricebookConfig());
        createPricebookEntriesAndProducts();
    }

    // TODO: refactor method to make it more readable
    private void createAccounts() {
        Map<String, List<Account>> userAccounts = new Map<String, List<Account>>();
        Map<String, String> accountToAgencyMap = new Map<String, String>();

        for (DF_Scenario sc : scenarios) {
            if (null == sc.accountRecordType) { // scenario does not require account
                continue;
            }
            if (!userAccounts.containsKey(scenarioOppUserMap.get(sc.scenarioId))) {
                userAccounts.put(scenarioOppUserMap.get(sc.scenarioId), new List<Account>());
            }

            String name = sc.scenarioId + '.Account.' + sc.accountRecordType;
            Account acc = new Account(
                Name = name,
                RecordTypeId = getAccountRecordTypeId(sc.accountRecordType),
                Member__c = memberMap.get(sc.member).Id,
                InvoiceGrouping__c = sc.invoiceGrouping,
                BillingStreet = 'Goethestrasse 97',
                BillingPostalCode = '19053',
                BillingCity = 'Schwerin',
                BillingState = 'Berlin',
                BillingCountry = 'Germany',
                AccountDiscount__c = sc.contractDiscount
            );
            if (null != sc.opportunity && sc.opportunity.containsKey(DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION)) {
                acc.ExternalSubscriptionStatus__c = Boolean.valueOf(sc.opportunity.get(DF_Scenario.CONF_OPPORTUNITY_ACTIVE_EXT_SUBSCRIPTION)) ? 'Active' : '';
            }
            userAccounts.get(scenarioOppUserMap.get(sc.scenarioId)).add(acc);
            accountMap.put(name, acc);

            if (sc.accountHasIndirectParner) {
                String agencyName = sc.scenarioId + '.Account.Agency';

                Account agencyAcc = new Account(
                    Name = agencyName,
                    RecordTypeId = getAccountRecordTypeId('Agency'),
                    Member__c = memberMap.get(sc.member).Id,
                    InvoiceGrouping__c = sc.invoiceGrouping,
                    BillingStreet = 'Wibautstraat 224',
                    BillingPostalCode = '1097DN',
                    BillingCity = 'Amsterdam',
                    BillingCountry = 'Netherlands',
                    AccountDiscount__c = sc.indirectDiscount
                );
                accountToAgencyMap.put(name, agencyName);

                accountMap.put(agencyName, agencyAcc);
                userAccounts.get(scenarioOppUserMap.get(sc.scenarioId)).add(agencyAcc);
            }
        }

        for (String userAlias : userAccounts.keySet()) {
            // added suspend to avoid triggered checkAccountMember which uses static userRoleMap that has old data
            System.runAs(userMap.get(userAlias)) {
                GW_User.userMapRequery = true;
                insert userAccounts.get(userAlias);

                List<Account> linkedAccounts = new List<Account>();

                findAndLinkAccountsToAgencies(userAccounts.get(userAlias), accountToAgencyMap);

                GW_User.userMapRequery = false;
            }
            UTIL.cache(userAccounts.get(userAlias));
        }
    }

    private void findAndLinkAccountsToAgencies(List<Account> userAccountList, Map<String, String> accountToAgencyMap) {
        List<Account> updateList = new List<Account>();

        for (Account acc : userAccountList) {
            if (accountToAgencyMap.containsKey(acc.Name)) {
                acc.DefaultIndirect__c = accountMap.get(accountToAgencyMap.get(acc.Name)).Id;
                updateList.add(acc);
            }
        }
        if (updateList.size() > 0) {
            update updateList;
        }
    }

    private void createContacts() {
        Map<String, List<Contact>> userContactMap = createFinanceContacts();
//        List<Contact> contacts = financeContactMap.values();

        for (String userAlias : userContactMap.keySet()) {
            System.runAs(userMap.get(userAlias)) {
                insert userContactMap.get(userAlias);
            }
        }
        attachContactAsAccountFinanceContact(userContactMap);
    }

    private void attachContactAsAccountFinanceContact(Map<String, List<Contact>> userFinanceContacts) {
        Map<String, List<Account>> userAccountMap = new Map<String, List<Account>>();

        for (String userAlias : userFinanceContacts.keySet()) { 
            for (Contact fc : userFinanceContacts.get(userAlias)) {
                String accountMapKey = fc.LastName.substring(0, (fc.LastName.length() - 3));
                
                if (accountMap.containsKey(accountMapKey)) {
                    Account acc = accountMap.get(accountMapKey);
                    acc.Finance_contact__c = fc.Id;

                    if (!userAccountMap.containsKey(userAlias)) {
                        userAccountMap.put(userAlias, new List<Account>());
                    }
                    userAccountMap.get(userAlias).add(acc);
                }
            }
        }
        for (String userAlias : userAccountMap.keySet()) {
            System.runAs(userMap.get(userAlias)) {
                update userAccountMap.get(userAlias);
            }
        }
    }

    private Map<String, List<Contact>> createFinanceContacts() {
        Map<String, List<Contact>> userContactMap = new Map<String, List<Contact>>();

        for (String accKey : accountMap.keySet()) {
            String name = accKey + '.FC';
            Contact contact = new Contact(
                FirstName = 'John-Jane',
                LastName= name,
                AccountId =  accountMap.get(accKey).Id,
                Phone = '+12345668',
                Email = name + '=ebay.com@example.com',
                MailingCountry = 'Germany',
                MailingStreet = 'Dealer straat 1',
                MailingCity = 'Schwerin',
                MailingPostalCode = '19053',
                Description = 'Auto Generated Test Data'
            );
            String scenarioId = accKey.substringBefore('.');

            if (!userContactMap.containsKey(scenarioOppUserMap.get(scenarioId))) {
               userContactMap.put(scenarioOppUserMap.get(scenarioId), new List<Contact>());
            }
            userContactMap.get(scenarioOppUserMap.get(scenarioId)).add(contact);
        }
        return userContactMap;
    }

    private Map<String, List<String>> buildMembersAndMemberUnitsConfig() {
        Map<String, List<String>> config = new Map<String, List<String>>();

        for (DF_Scenario sc : scenarios) {
            if (!config.containsKey(sc.member)) {
                config.put(sc.member, new List<String>());
            }
            config.get(sc.member).add(sc.memberUnit);
        }
        return config;
    }

    private Map<String, Set<String>> buildPricebookConfig() {
        Map<String, Set<String>> config = new Map<String, Set<String>>();

        for (DF_Scenario sc : scenarios) {
            if (null == sc.pricebook) { // the scenario does not require a pricebook
                continue;
            }
            if (!config.containsKey(sc.memberUnitId)) {
                config.put(sc.memberUnitId, new Set<String>());
            }
            config.get(sc.memberUnitId).add(sc.pricebook);
        }
        return config;
    }

    private Map<String, Account> createMemberAccounts(List<String> memberNames) {
        Map<String, Account> maMap = new Map<String, Account>();

        if (memberNames.size() == 0) {
            return maMap;
        }
        for (String memberName : memberNames) {
            Account ma = new Account(
                Name = memberName + ' (Member)',
                RecordTypeId = recordTypeNameMap.get('Account_Member').Id
            );
            maMap.put(memberName, ma);
        }
        insert maMap.values();
        UTIL.log('~!@ memberAccounts: ' + maMap.values());

        return maMap;
    }

    private Map<String, Member__c> createMembers(Map<String, Account> memberAccountMap) {
        Map<String, Member__c> mMap = new Map<String, Member__c>();
        Map<String, Map<String, String>> defaultSettings  = new Map<String, Map<String, String>> {
            'ECGDK' => new Map<String, String> {
                'ActivePaymentMethods' => 'Invoice', 'CurrencyIsoCode' => 'DKK', 'DefaultAgencyDiscount' => '7', 'DefaultVAT' => '25', 'DefaultVATApplication' => 'true',
                'FQ_BillingCycle' => null, 'FQ_CmrType' => null, 'FQ_CustomerType__c' => null
            },
            'ECITAAU' => new Map<String, String> {
                'ActivePaymentMethods' => 'Invoice;Direct Debit', 'CurrencyIsoCode' => 'EUR', 'DefaultAgencyDiscount' => '0', 'DefaultVAT' => '22', 'DefaultVATApplication' => 'true',
                'FQ_BillingCycle' => 'Default Kijiji IT cycle', 'FQ_CmrType' => 'Email KIJIJI IT Autos CMR', 'FQ_CustomerType__c' => 'KijijiIT autos'
            },
            'THBELAU_Rep' => new Map<String, String> {
                'ActivePaymentMethods' => 'Invoice;Direct Debit', 'CurrencyIsoCode' => 'EUR', 'DefaultAgencyDiscount' => '0', 'DefaultVAT' => '21', 'DefaultVATApplication' => 'true',
                'FQ_BillingCycle' => 'Default BE Cycle - CARS', 'FQ_CmrType' => 'Email BEC-{{Language_Preference__c}} CMR', 'FQ_CustomerType' => 'BE 2dehands'
            },
            'GTAUSAD' => new Map<String, String> {
                'ActivePaymentMethods' => 'Invoice', 'CurrencyIsoCode' => 'AUD', 'DefaultAgencyDiscount' => '10', 'DefaultVAT' => '10', 'DefaultVATApplication' => 'true',
                'FQ_BillingCycle' => 'Default AU Cycle', 'FQ_CmrType' => 'Banners', 'FQ_CustomerType' => 'Banners'
            },
            'EBAYK' => new Map<String, String> {
                'ActivePaymentMethods' => 'Invoice;Direct Debit', 'CurrencyIsoCode' => 'EUR', 'DefaultAgencyDiscount' => '0', 'DefaultVAT' => '19', 'DefaultVATApplication' => 'false',
                'FQ_BillingCycle' => 'KA-RealEstate', 'FQ_CmrType' => 'Email KA-RealEstate-SendInvoice', 'FQ_CustomerType' => 'KA-RealEstate COMMERCIAL'
            }
        };

        if (memberAccountMap.size() == 0) {
            return mMap;
        }
        for (String key : memberAccountMap.keySet()) {
            mMap.put(key, createMember(key, memberAccountMap.get(key), defaultSettings));
        }
        insert mMap.values();
        UTIL.log('~!@ members: ' + mMap.values());

        return mMap;
    }

    private Member__c createMember(String memberId, Account memberAccount, Map<String, Map<String, String>> defaultSettings) {
        Member__c m = new Member__c(
            Name = memberId,
            MemberId__c = memberId,
            Account__c = memberAccount.Id,
            CurrencyIsoCode          = (defaultSettings.containskey(memberId) ? defaultSettings.get(memberId).get('CurrencyIsoCode') : null),
            ActivePaymentMethods__c  = (defaultSettings.containskey(memberId) ? defaultSettings.get(memberId).get('ActivePaymentMethods') : 'Invoice'),
            FQ_BillingCycle__c       = (defaultSettings.containskey(memberId) ? defaultSettings.get(memberId).get('FQ_BillingCycle') : null),
            FQ_CmrType__c            = (defaultSettings.containskey(memberId) ? defaultSettings.get(memberId).get('FQ_CmrType') : null),
            FQ_CustomerType__c       = (defaultSettings.containskey(memberId) ? defaultSettings.get(memberId).get('FQ_CustomerType') : null),
            DefaultAgencyDiscount__c = (defaultSettings.containskey(memberId) ? Integer.valueOf(defaultSettings.get(memberId).get('DefaultAgencyDiscount')) : 0),
            DefaultVAT__c            = (defaultSettings.containskey(memberId) ? Integer.valueOf(defaultSettings.get(memberId).get('DefaultVAT')) : 0),
            DefaultVATApplication__c = (defaultSettings.containskey(memberId) ? Boolean.valueOf(defaultSettings.get(memberId).get('DefaultVATApplication')) : false)
        );
        return m;
    }

    private Map<String, MemberUnit__c> createMemberUnits(Map<String, List<String>> config, Map<String, Member__c> memberMap) {
        // Map<{MEMBERUNITID}, Map<String, String>>
        
        Set<String> NON_TRACT_MEMBER_UNITS = new Set<String>{'ECGDKAD'};
        //PLEASE KEEP THESE SETTINGS IN SYNC WITH PRODUCTION!
        Map<String, Map<String, String>> defaultSettings  = new Map<String, Map<String, String>> {
            'ECGDKAD' => new Map<String, String> { 'RevenueItemRunningStatusCalculation' => 'None', 'LineOfBusiness' => 'AD',  'Currency' => 'DKK', 'UseIndirectPartnerAsBillingAccount' => 'true' },
            'ECITAAU' => new Map<String, String> { 'RevenueItemRunningStatusCalculation' => 'UniqueLocalBookingId', 'LineOfBusiness' => 'AU',  'Currency' => 'EUR', 'UseIndirectPartnerAsBillingAccount' => 'false' },
            'THBELAU_Rep' => new Map<String, String> { 'RevenueItemRunningStatusCalculation' => 'AccountExternalSubscriptionStatus', 'LineOfBusiness' => 'AU',  'Currency' => 'EUR', 'UseIndirectPartnerAsBillingAccount' => 'false' },
            'THBE2AD' => new Map<String, String> { 'RevenueItemRunningStatusCalculation' => 'None', 'LineOfBusiness' => 'AD',  'Currency' => 'EUR', 'UseIndirectPartnerAsBillingAccount' => 'false' },
            'GTAUSAD' => new Map<String, String> { 'RevenueItemRunningStatusCalculation' => 'None', 'LineOfBusiness' => 'AD',  'Currency' => 'AUD', 'UseIndirectPartnerAsBillingAccount' => 'true' },
            'EBAYKRE_Rep' => new Map<String, String> { 'RevenueItemRunningStatusCalculation' => 'UniqueLocalBookingId', 'LineOfBusiness' => 'RE',  'Currency' => 'EUR', 'UseIndirectPartnerAsBillingAccount' => 'false' }
        };
        Map<String, MemberUnit__c> muMap = new Map<String, MemberUnit__c>();
        Map<Id, MemberUnit__c> muDefaultMap = new Map<Id, MemberUnit__c>();

        if (memberMap.size() == 0) {
            return muMap;
        }
        for (String key : config.keySet()) {
            if (!memberMap.containsKey(key)) {
                // TODO: Throw Exception?
                continue;
            }
            
            for (String memberUnitName: config.get(key)) {
                String memberUnitId = key + memberUnitName;
                if (memberUnitId == 'THBELAU') memberUnitId = 'THBELAU_Rep'; 
                MemberUnit__c mu = new MemberUnit__c(
                    Name      = memberUnitName,
                    Member__c = memberMap.get(key).Id,
                    RevenueItemRunningStatusCalculation__c = (defaultSettings.containskey(memberUnitId) ? defaultSettings.get(memberUnitId).get('RevenueItemRunningStatusCalculation') : 'None'),
                    LineOfBusiness__c                      = (defaultSettings.containskey(memberUnitId) ? defaultSettings.get(memberUnitId).get('LineOfBusiness') : 'AD'),
                    CurrencyIsoCode                        = (defaultSettings.containskey(memberUnitId) ? defaultSettings.get(memberUnitId).get('Currency') : 'USD'),
                    UseIndirectPartnerAsBillingAccount__c  = (defaultSettings.containskey(memberUnitId) ? Boolean.valueOf(defaultSettings.get(memberUnitId).get('UseIndirectPartnerAsBillingAccount')) : false)
                );
                if (NON_TRACT_MEMBER_UNITS.contains(memberUnitName)) mu.EnableTract__c = false;
                muMap.put(memberUnitId, mu);
                muDefaultMap.put(memberMap.get(key).Id, mu);
            }
        }
        
        if (muMap.size() > 0) {
            insert muMap.values();
        }
        List<Member__c> setDefaultMU = new List<Member__c>();
        for (Id memberId : muDefaultMap.keySet()) {
            setDefaultMU.add(new Member__c(Id = memberId, DefaultMemberUnit__c = muDefaultMap.get(memberId).Id));
        }
        if (setDefaultMU.size() > 0) {
            update setDefaultMU;
        }
        
        return muMap;
    }

    private void updateMemberDefaultMemberUnit(Map<String, Member__c> memberMap, Map<String, MemberUnit__c> memberUnitMap) {
        Map<String, String> defaultMemberUnit = new Map<String, String> {
            'ECGDK' => 'ECGDKAD',
            'ECITAAU' => 'ECITAAU',
            'ECG'   => null,
            'THBEL' => 'THBELAU',
            'GTAUSAD' => 'GTAUSAD',
            'EBAYK' => 'EBAYKRE_Rep'
        };

        List<Member__c> membersToUpdate = new List<Member__c>();
        for (String memberId : memberMap.keySet()) {
            if (defaultMemberUnit.containsKey(memberId) && null != defaultMemberUnit.get(memberId) && memberUnitMap.containsKey(defaultMemberUnit.get(memberId))) {
                Member__c member = memberMap.get(memberId);
                member.DefaultMemberUnit__c = memberUnitMap.get(defaultMemberUnit.get(memberId)).Id;
                membersToUpdate.add(member);
            }
        }
        if (membersToUpdate.size() > 0) {
            update membersToUpdate;
        }
    }

    private Map<String, Pricebook2> createPricebooks(Map<String, Set<String>> config) {
        Map<String, Pricebook2> muPricebookMap = new Map<String, Pricebook2>();
        if (config.size() == 0) {
            return muPricebookMap;
        }
        for (String key : config.keySet()) {
            for (String pricebookName : config.get(key)) {
                if (key == 'THBELAU') key = 'THBELAU_Rep';
                if (!memberUnitMap.containsKey(key)) {
                    // TODO: throw Exception?
                    continue;
                }
                Pricebook2 pb = new Pricebook2(
                    Name = pricebookName,
                    IsActive = true,
                    MemberUnit__c = memberUnitMap.get(key).Id,
                    CurrencyIsoCode = memberUnitMap.get(key).CurrencyIsoCode
                );
                muPricebookMap.put(key + '.' + pricebookName, pb);
            }
        }
        if (muPricebookMap.size() > 0) {
            insert muPricebookMap.values();
        }
        return muPricebookMap;
    }

    private void createPricebookEntriesAndProducts() {
        createProducts();
        createPricebookEntries();

        retrieveAndPopulateProduct2Cache();
    }

    private void createProducts() {
        List<Product2> productList = new List<Product2>();

        for (DF_Scenario sc : scenarios) {
            if (null == sc.products) { // scenario does not require products
                continue;
            }
            for (Map<String, Object> prodConfig : sc.products) {
                productList.add((Product2) ((List<SObject>) prodConfig.get(DF_Scenario.CONF_PRODUCT_DATA)).get(0));
            }
        }
        if (productList.size() > 0) {
            insert productList;
        }
    }

    private void retrieveAndPopulateProduct2Cache() {
        List<Product2> products = GW_sObject.queryRecords('Product2', 'Id <> null ORDER BY Id');
        UTIL.cache(products);
    }

    private void createPricebookEntries() {
        List<PricebookEntry> pbEntryList = new List<PricebookEntry>();

        for (DF_Scenario sc : scenarios) {
            if (null == sc.products) { // scenario does not require pricebook entries
                continue;
            }
            for (Map<String, Object> prodConfig : sc.products) {
                PricebookEntry pbEntry = (PricebookEntry) ((List<SObject>) prodConfig.get(DF_Scenario.CONF_PRODUCT_DATA)).get(1);
                pbEntry.Product2Id = ((List<SObject>) prodConfig.get(DF_Scenario.CONF_PRODUCT_DATA)).get(0).Id;
                String fixedMemberUnitId = sc.memberUnitId == 'THBELAU' ? 'THBELAU_Rep' : sc.memberUnitId;
                String pbKey = fixedMemberUnitId + '.' + sc.pricebook;
                pbEntry.Pricebook2Id = pricebookMap.get(pbKey).Id;
                pbEntry.CurrencyIsoCode = memberUnitMap.get(fixedMemberUnitId).CurrencyIsoCode;

                // avoiding error "No standard price defined for this product"
                PricebookEntry stdPbEntry = pbEntry.clone(false, true);
                stdPbEntry.Pricebook2Id = standardPricebookId;

                pbEntryList.add(stdPbEntry);
                pbEntryList.add(pbEntry);
            }
        }
        if (pbEntryList.size() > 0) {
            insert pbEntryList;
            retrieveAndPopulatePricebookEntryCache();
        }
    }

    private void retrieveAndPopulatePricebookEntryCache() {
        List<PricebookEntry> pricebookEntries = GW_sObject.queryRecords('PricebookEntry', ' Id <> null ORDER BY Id');
        UTIL.cache(pricebookEntries);
    }

    public static Id getAccountRecordTypeId(String name) {
        String key = 'Account_' + name;

        if (!recordTypeNameMap.containsKey(key)) {
            throw new UTIL.CustomException('Could not find key "' + key + '" in recordTypeNameMap');
        }
        return recordTypeNameMap.get(key).Id;
    }
//
//    public List<RecordRestrictions__c> constructRecordRestrictions() {
//        List<RecordRestrictions__c> recordRestrictions = new List<RecordRestrictions__c> {
//            new RecordRestrictions__c(Name= 'Lock RS when Invoice Sent', LineOfBusiness__c= null,LockedFields__c= 'Invoice__c,From_Date__c,Until_Date__c,Revenue__c,QuantityBilled__c,QuantityDelivered__c',LockRecord__c= true,
//                Message__c= 'Invoice has been sent to billing for depending RS.',ObjectName__c= 'RS__c',Profiles__c= null,Active__c= true,StatusNumbers__c= '7,8,9'),
//            new RecordRestrictions__c(Name= 'Lock Invoices Sent', LineOfBusiness__c= null, LockedFields__c= 'Amount__c,NumLineItems__c,MinInvLineStatus__c', LockRecord__c= true,
//                Message__c= 'Invoice has been sent to billing.',ObjectName__c= 'Invoice__c',Profiles__c= null,Active__c= true,StatusNumbers__c= '7,8,9,10,11'),
//            new RecordRestrictions__c(Name= 'InvoiceLine restrictions',LineOfBusiness__c= null,LockedFields__c= 'NumStatus__c,UniqueKey__c,FQ_SyncTimestamp__c,FQ_SyncStatus__c,Invoice__c,Amount__c',LockRecord__c= true,
//                Message__c= 'InvoiceLine has been sent to Billing',ObjectName__c= 'InvoiceLine__c',Profiles__c= null,Active__c= true,StatusNumbers__c= '7,8,9'),
//            new RecordRestrictions__c(Name= 'Opportunity set Lost restrictions',LineOfBusiness__c= null,LockedFields__c= 'Lost__c',LockRecord__c= false,
//                Message__c= 'Signed Opportunities can\'t be lost.',ObjectName__c= 'Opportunity',Profiles__c= null,Active__c= true,StatusNumbers__c= '2,3,4,5'),
//            new RecordRestrictions__c(Name= 'Opportunity Deletion Restriction',LineOfBusiness__c= null,LockedFields__c= null,LockRecord__c= true,
//                Message__c= 'Opportunity cannot be deleted',ObjectName__c= 'Opportunity',Profiles__c= null,Active__c= true,StatusNumbers__c= '1,2,3,4,5')
//        };
//        return recordRestrictions;
//    }


    private void createOpportunities() {
        Map<String, List<Opportunity>> userOpportunityMap = new Map<String, List<Opportunity>>();
        
        
        for (DF_Scenario sc : scenarios) {
            if (null == sc.opportunity) { // scenario does not require opportunities
                continue;
            }
            String fixedMemberUnitId = sc.memberUnitId == 'THBELAU' ? 'THBELAU_Rep' : sc.memberUnitId;
            if (!sc.opportunity.containsKey(DF_Scenario.CONF_OPPORTUNITY_COUNT) || Integer.valueOf(sc.opportunity.get(DF_Scenario.CONF_OPPORTUNITY_COUNT)) <= 0) {
                UTIL.Log('Scenario "' + sc.scenarioId + '" does not contain or has a negative opportunity count. Using default "2" instead.');
                sc.opportunity.put(DF_Scenario.CONF_OPPORTUNITY_COUNT, '2');
            }
            String accountMapKey = sc.scenarioId + '.Account.' + sc.accountRecordType;

            for (Integer i = 1, n = Integer.valueOf(sc.opportunity.get(DF_Scenario.CONF_OPPORTUNITY_COUNT)); i <= n; i++) {
                Opportunity opp = new Opportunity();
                opp.Name = sc.scenarioId + ' Test Opp';
                opp.CloseDate = Date.today() + 90;
                opp.StageName = 'Draft';
                
                opp.CurrencyIsoCode = memberUnitMap.get(fixedMemberUnitId).CurrencyIsoCode;
                opp.AccountId = accountMap.get(accountMapKey).Id;
                opp.Pricebook2Id = pricebookMap.get(fixedMemberUnitId + '.' + sc.pricebook).Id;
                opp.ApprovalStatus__c = 'Previously Approved';
                opp.ContractStatus__c = 'Signed';
                opp.MemberUnit__c = memberUnitMap.get(fixedMemberUnitId).Id;

                String oppKey = sc.scenarioId + '.Opportunity[' + i + ']';
                opp.Touch__c = oppKey; //field set to distinguish opps based on scenario

//                opp.Primary_Contact__c=primaryContact.Id;
                opportunityMap.put(oppKey, opp);
                if (!userOpportunityMap.containsKey(scenarioOppUserMap.get(sc.scenarioId))) {
                    userOpportunityMap.put(scenarioOppUserMap.get(sc.scenarioId), new List<Opportunity>());
                }
                userOpportunityMap.get(scenarioOppUserMap.get(sc.scenarioId)).add(opp);
            }
        }
        for (String userAlias : userOpportunityMap.keySet()) {
            System.runAs(userMap.get(userAlias)) {
                insert userOpportunityMap.get(userAlias);
            }
        }
        retrieveAndPopulateOpportunityCache();
    }

    private void retrieveAndPopulateOpportunityCache() {
        if (opportunityMap.isEmpty()) { // no opportunities created, skip query
            return;
        }
        List<Opportunity> opps = GW_sObject.queryRecords('Opportunity', ' Id <> null ORDER BY Id');
        UTIL.cache(opps);
    }

    private void createOpportunityLineItems() {
        Map<String, List<OpportunityLineItem>> userOliMap = new Map<String, List<OpportunityLineItem>>();

        for (DF_Scenario sc : scenarios) {
            if (null == sc.products) { // scenario does not require opportunity lines
                continue;
            }
            Integer i = 1;

            while (opportunityMap.containsKey(sc.scenarioId + '.Opportunity[' + i + ']')) {
                String oppKey = sc.scenarioId + '.Opportunity[' + i + ']';
                Opportunity opp = opportunityMap.get(oppKey);
                Integer j = 1;
                for (Map<String, Object> prodConfig : sc.products) {
                    // TODO check if config keys DF_Scenario.CONF_PRODUCT_DATA and DF_Scenario.CONF_PRODUCT_QUANTITY exist

                    Product2 p = (Product2) ((List<SObject>) prodConfig.get(DF_Scenario.CONF_PRODUCT_DATA)).get(0);
                    PricebookEntry pbe = (PricebookEntry) ((List<SObject>) prodConfig.get(DF_Scenario.CONF_PRODUCT_DATA)).get(1);

                    String indexBasedOliKey = oppKey + '.oli[' + j + ']';
                    String productBasedOliKey = oppKey + '.oli[' + p.Name + ']';

                    OpportunityLineItem oli = DF.createOliSObject(opp, pbe, (Decimal) prodConfig.get(DF_Scenario.CONF_PRODUCT_QUANTITY), sc);
                    oli.Touch__c = indexBasedOliKey + ';' + productBasedOliKey; //field set to distinguish olis based on scenario
                    oli.Ad_Id__c = prodConfig.containsKey(DF_Scenario.CONF_PRODUCT_AD_ID) ? (String) prodConfig.get(DF_Scenario.CONF_PRODUCT_AD_ID) + i: null;

                    if (!userOliMap.containsKey(scenarioOppUserMap.get(sc.scenarioId))) {
                        userOliMap.put(scenarioOppUserMap.get(sc.scenarioId), new List<OpportunityLineItem>());
                    }
                    userOliMap.get(scenarioOppUserMap.get(sc.scenarioId)).add(oli);
                    j++;
                }
                i++;
            }
        }
        for (String userAlias : userOliMap.keySet()) {
            System.runAs(userMap.get(userAlias)) {
                insert userOliMap.get(userAlias);
            }
        }
    }

    public static OpportunityLineItem createOliSObject(Opportunity opp, PricebookEntry pbe, Decimal quantity, DF_Scenario scenario) {
        Date fromDate = Date.valueOf(scenario.opportunity.get(DF_Scenario.CONF_OPPORTUNITY_START_DATE));

        Product2 prod = (Product2) UTIL.getCached(pbe.Product2Id);
        Account relatedAcc = (Account) UTIL.getCached(opp.AccountId);
        pbe.Product2 = prod;
        Advertising_Medium__c am = (null != prod.Advertising_Medium__c) ? (Advertising_Medium__c) GW_sObject.queryRecord('Advertising_Medium__c', prod.Advertising_Medium__c) : null;

        String firstBillingCatCalc = prod.Billing_Category__c.split(';')[0];
        String bCat = firstBillingCatCalc.split('_')[0];
        String bCalc = firstBillingCatCalc.split('_')[1];

        Date untilDate = prod.ContractPeriodInMonths__c > 0 ? fromDate.addMonths(Integer.valueOf(prod.ContractPeriodInMonths__c)) : fromDate.addMonths(1);

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbe.Id,
            PricebookEntry = pbe,
            Quantity = quantity,
            Billing_Category__c = bCat,
            BillingCalc__c = bCalc,
            FC_Quantity__c = am!=null?am.FC_Quantity__c:0,
            FC_Period__c = am!=null?am.FC_Period__c:'',
            FC_Ad_served_every__c = am!=null?am.FC_Ad_served_every__c:null,
            AdKeywords__c = prod.AdServer_Keywords_Key_Values__c,
            KeyValueString__c = String.isBlank(prod.AdServer_Keywords_Key_Values__c)?'':prod.AdServer_Keywords_Key_Values__c,
            Check_Inventory__c = true,
            from_date__c = fromDate,
            until_Date__c = untilDate,
            ContractDiscount__c = (opp.ContractDiscount__c == null ? 0 : opp.ContractDiscount__c)
        );

        PriceCalculator.applyPriceModel(oli);

        // TBFIXED JC - MOVE TO PRICE CALCULATOR
        // It's related to LCC pricing calculator, figure out how and why and move to price calculator
        Decimal partnerShare = opp.IndirectDiscount__c == null ? 0 : opp.IndirectDiscount__c;
        Decimal ebayShare = 100 - partnerShare;

        if(oli.CustomListPrice__c != NULL && oli.CustomListPrice__c != 0) {
            oli.SalesPriceNet__c = oli.CustomListPrice__c * (ebayShare / 100);
            oli.UnitPrice = oli.CustomListPrice__c;
        } else {
            oli.SalesPriceNet__c = oli.ListPrice__c * (ebayShare / 100);
            oli.UnitPrice = oli.ListPrice__c;
        }
        return oli;
    }
}