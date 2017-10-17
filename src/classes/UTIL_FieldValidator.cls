/**
 * Created by ronvelzeboer on 20/09/16.
 */

public class UTIL_FieldValidator {
    private static final String GLOBALSCOPE 		               = 'Global';
    private static final String MEMBERFIELD 		               = 'Member__c';
    private static final String MEMBERIDFIELD 		               = 'MemberId__c';
    private static final String MEMBERUNITFIELD 	               = 'MemberUnit__c';
    private static final String MEMBERUNITIDFIELD 	               = 'MemberUnitId__c';
    private static final String NUMSTATUSFIELD 		               = 'NumStatus__c';
    private static final String REQUIRED_FOR_NEXT_STAGE_FIELD      = 'RequiredForNextStage__c';
    private static final String LOWEST_STATUS_NUM_INCOMPLETE_FIELD = 'LowestStatusNumIncomplete__c';
    private static final String LOWEST_STATUS_NUM_SYNCERROR_FIELD  = 'LowestStatusNumSyncError__c';

    // map with the applicable rules for a specific consumer (eg. THBELAU => 'Account.BillingStreet' => specific FieldValidation__c)
    private static Map<String,Map<String, FieldValidation__c>> mapConsumer2ApplicableValidationRule = new Map<String,Map<String, FieldValidation__c>>();

    public static List<FieldValidation__c> allFieldValidations;
    //private static Map<String,FieldValidation__c> mapFieldValidations = new Map<String,FieldValidation__c>();

    private static List<FieldValidation__c> defaultValidations = new List<FieldValidation__c> {
        //new FieldValidation__c(Name='InvoiceLine restrictions', );
    };

    Static {
        allFieldValidations = FieldValidation__c.getall().values();
    }

    public static void checkObject(sObject so) {
        if (so==null) UTIL.throwError('Cannot a validate null object');
        String objectName = so.getSObjectType().getDescribe().getName();

        checkValidatorCompatibilityOf(objectName);
        String consumerId = getConsumerId(so, objectName);
        Map<String, FieldValidation__c> applicableRules = getApplicableRules(objectName, consumerId);

        Map<Integer, List<IFieldValidationResult>> errors = new Map<Integer, List<IFieldValidationResult>>();
        UTIL.log('~!@ applicableRules for ' + consumerId + ' and object ' + objectName + ':' + applicableRules);
        for (FieldValidation__c fv : applicableRules.values()) {
            if (fv == null) {
                UTIL.throwError('No validation rule');
            }
            IFieldValidationResult validateResult = doValidation(so, fv);

            if (null == validateResult) { // no error
                continue;
            }
            if (!errors.containsKey(validateResult.getApplicableStage())) {
                errors.put(validateResult.getApplicableStage(), new List<IFieldValidationResult>());
            }
            errors.get(validateResult.getApplicableStage()).add(validateResult);
        }
        UTIL.log('~!@ checkobject errors: ' + errors);
        updateSObjectValidationFields(so, errors);
    }

    private static void updateSObjectValidationFields(SObject so, Map<Integer, List<IFieldValidationResult>> errors) {
        List<String> requiredForNextStageErrors = new List<String>();
        Integer lowestStatusNum, lowestStatusNumIncomplete, lowestStatusNumSyncError;
        lowestStatusNum = lowestStatusNumIncomplete = lowestStatusNumSyncError = 99;

        if (errors.size() > 0) {
            if (errors.containsKey(0)) {
                for (IFieldValidationResult validateResult : errors.get(0)) {
                    so.addError(validateResult.getMessage());
                }
            } else {
                lowestStatusNum = findlowestStatusNum(errors.keySet());

                for (IFieldValidationResult validateResult : errors.get(lowestStatusNum)) {
                    if ('SYNC' == validateResult.getRule().get('FieldType__c')) {
                        lowestStatusNumSyncError = lowestStatusNum;
                    } else {
                        lowestStatusNumIncomplete = lowestStatusNum;
                    }
                    requiredForNextStageErrors.add(validateResult.getMessage());
                }
            }
        }
        String requiredForNextStage = sortAndFlattenStringList(requiredForNextStageErrors, '\n');
        
        if (!trigger.isDelete){
            so.put('LowestStatusNumIncomplete__c', lowestStatusNumIncomplete);
            so.put('LowestStatusNumSyncError__c', lowestStatusNumSyncError);
            so.put('RequiredForNextStage__c', requiredForNextStage.left(2048));
        }
        
    }

    private static String sortAndFlattenStringList(List<String> lst, String divider) {
        String result = '';
        if (null != lst && lst.size() > 0) {
            lst.sort();
            result = String.join(lst, divider);
        }
        return result;
    }

    private static void checkValidatorCompatibilityOf(String objectName) {
        List<String> objectFields = new List<String> {
            NUMSTATUSFIELD, REQUIRED_FOR_NEXT_STAGE_FIELD, LOWEST_STATUS_NUM_INCOMPLETE_FIELD,
            LOWEST_STATUS_NUM_SYNCERROR_FIELD
        };
        for (String fieldName : objectFields) {
            if (!GW_sObject.fieldExists(objectName, fieldName)) {
                UTIL.throwError('Cannot validate sObjects without a \'' + fieldName + '\' field');
            }
        }
    }

    private static IFieldValidationResult doValidation(SObject so, FieldValidation__c fv) {
        if (null != fv.delegatedValidator__c) {
            return doDelegatedValidation(so, fv, fv.delegatedValidator__c);
        }
        return doStandardValidation(so, fv);
    }

    private static IFieldValidationResult doDelegatedValidation(sObject so, FieldValidation__c fv, string delegatedValidator) {
        UTIL_FieldValidator.IDelegatedValidator validator;
        try {
            validator = (UTIL_FieldValidator.IDelegatedValidator) Type.forName(delegatedValidator).newInstance();
        } catch (System.TypeException e) {
            throw new UTIL.CustomException('Delegated validator \'' + delegatedValidator + '\' does not implement interface \'UTIL_FieldValidator.IDelegatedValidator\'. Original Exception: ' + e.getMessage());
        }
        return validator.validate(so, fv);
    }

    private static IFieldValidationResult doStandardValidation(SObject so, FieldValidation__c fv) {
        if (so.get(fv.FieldName__c) != null) { // field has value, check validation
            return checkFieldValidation(so, fv);
        }
        // field has no value set
        String fieldLabel = GW_sObject.getFieldLabel(fv.Object__c, fv.FieldName__c);
        return new UTIL_FieldValidator.IncompleteErrorResult(so, fieldLabel, fv, null);
    }

    // check validation, return error String if any, returns null if ok
    private static IFieldValidationResult checkFieldValidation(sObject so, FieldValidation__c fv) {
        Object fieldValue = so.get(fv.FieldName__c);
        String fieldLabel = GW_sObject.getFieldLabel(fv.Object__c, fv.FieldName__c);

        if (fieldValue==null) UTIL.throwError('Cannot validate null value');

        if (fv.Regex__c != null) {
            if (!Pattern.matches(String.valueOf(fv.Regex__c), String.valueOf(fieldValue))) {
                return new UTIL_FieldValidator.InvalidErrorResult(so, fieldLabel, fv, null);
            }
        }
        if (null != fv.MandatoryValue__c && fv.MandatoryValue__c != String.valueof(fieldValue)) {
            return new UTIL_FieldValidator.MandatoryValueErrorResult(so, fieldLabel, fv, null);
        }
        return null;
    }

    private static Map<String, FieldValidation__c> createApplicableRuleMap(String objectName, String consumerId ) {
        List <FieldValidation__c> sObjectValidations = new List<FieldValidation__c>();
        // Filter rules for this sObject
        for (FieldValidation__c fv : allFieldValidations) {
            if (!fv.Active__c) { continue; }
            if (fv.Object__c == objectName) sObjectValidations.add(fv);
        }
        String memberId, memberUnitId;
        // find member/memberUnit based on consumerId
        if (null != consumerId && consumerId.length() == 7) {
            memberId = consumerId.left(5);
            memberUnitId = consumerId;
        } else if (null != consumerId && consumerId.length() == 5) {
            memberId = consumerId;
        }
        List<String> ruleScopePrecedenceLowToHigh = new List<String> { GLOBALSCOPE, memberId, memberUnitId };
        return doCreateApplicableRuleMap(sObjectValidations, ruleScopePrecedenceLowToHigh);
    }

    private static Map<String, FieldValidation__c> doCreateApplicableRuleMap(List<FieldValidation__c> sObjectValidations, List<String> ruleScopePrecedenceLowToHigh) {
        Map<String, FieldValidation__c> applicableValidationRules = new Map<String, FieldValidation__c>();

        for (String scopeKey : ruleScopePrecedenceLowToHigh) {
            if (null == scopeKey) {
                continue;
            }
            applicableValidationRules.putAll(collectFieldValidationRulesForScope(scopeKey, sObjectValidations));
        }
        return applicableValidationRules;
    }

    private static Map<String, FieldValidation__c> collectFieldValidationRulesForScope(String scopeKey, List <FieldValidation__c> sObjectValidations) {
        Map<String, FieldValidation__c> collectedRules = new Map<String, FieldValidation__c>();

        for (FieldValidation__c fv : sObjectValidations) {
            if (fv.Scope__c == scopeKey) {
                collectedRules.put(getFieldValidationKey(fv), fv);
            }
        }
        return collectedRules;
    }

    private static Map<String, FieldValidation__c> getApplicableRules(String objectName, String consumerId ) {
        String key = objectName+'.'+consumerId;
        if (!mapConsumer2ApplicableValidationRule.containsKey(key)) {
            mapConsumer2ApplicableValidationRule.put(key, createApplicableRuleMap(objectName, consumerId ));
        }
        return mapConsumer2ApplicableValidationRule.get(key);
    }

    private static String getFieldValidationKey(FieldValidation__c fv) {
        return getFieldValidationKey(fv.Object__c, fv.FieldName__c);
    }
    private static String getFieldValidationKey(String objectName, String fieldName) {
        return objectName + '.' + fieldName;
    }

    // This method will return either memberId or memberUnitId depending on the sobject's sharing scope.
    // Eg. Account => memberId, Opportunity and below => MemberUnitId
    private static String getConsumerId(sObject so, String objectName) {
        String consumerId;
        if (GW_sObject.fieldExists(objectName, MEMBERIDFIELD) && so.get(MEMBERIDFIELD) != null) consumerId = (String) so.get(MEMBERIDFIELD);
        if (GW_sObject.fieldExists(objectName, MEMBERUNITIDFIELD) && so.get(MEMBERUNITIDFIELD) != null) consumerId = (String) so.get(MEMBERUNITIDFIELD);

        // fallback in case record is not yet committed, but (uncalculated) formula field is present
        // for memberId/memberUnitId and MemberUnit__c and/or Member__c field exists
        if (null == consumerId && GW_sObject.fieldExists(objectName, MEMBERUNITFIELD) && null != so.get(MEMBERUNITFIELD)) {
            MemberUnit__c mu = GW_MemberUnit.memberUnitCache.get((Id) so.get(MEMBERUNITFIELD));

            if (null != mu) {
                consumerId = mu.MemberUnitId__c;
            }
        }
        if (null == consumerId && GW_sObject.fieldExists(objectName, MEMBERFIELD) && null != so.get(MEMBERFIELD)) {
            Member__c m = GW_Member.memberCache.get((Id) so.get(MEMBERFIELD));

            if (null != m) {
                consumerId = m.MemberId__c;
            }
        }
        return consumerId;
    }

    public virtual interface IFieldValidationResult {
        String getMessage();
        FieldValidation__c getRule();
        Integer getApplicableStage();
    }

    public abstract class AbstractFieldValidationResult implements UTIL_FieldValidator.IFieldValidationResult {
        private SObject so;
        private String fieldLabel;
        private FieldValidation__c rule;
        private String customMessage;
        private String actualMessage;

        public AbstractFieldValidationResult(SObject so, String fieldLabel, FieldValidation__c rule, String customMessage) {
            this.so            = so;
            this.fieldLabel    = fieldLabel;
            this.rule          = rule;
            this.customMessage = customMessage;
        }

        public FieldValidation__c getRule() { return rule; }
        public virtual Integer getApplicableStage() { return Integer.valueOf(rule.MandatoryFromStatusNum__c); }

        public virtual String getMessage() {
            if (null == actualMessage) {
                if (null != rule.ErrorMessage__c) {
                    actualMessage = rule.ErrorMessage__c;
                } else if (null != customMessage) {
                    actualMessage = customMessage;
                } else {
                    actualMessage = buildMessage();
                }
                actualMessage = UTIL_StringParser.parseAndReplace(actualMessage, so);
            }
            return actualMessage;
        }
        abstract protected String buildMessage();
    }

    public virtual class InvalidErrorResult extends UTIL_FieldValidator.AbstractFieldValidationResult {
        public InvalidErrorResult(SObject so, String fieldLabel, FieldValidation__c rule, String customMessage) {
            super(so, fieldLabel, rule, customMessage);
        }
        public override Integer getApplicableStage() { return 0; }

        protected override String buildMessage() {
            return null != rule.Regex__c
                ? '\'' + fieldLabel + '\' not matching the required pattern: ' + rule.Regex__c
                : '\'' + fieldLabel + '\' should have a value';
        }
    }

    public virtual class IncompleteErrorResult extends UTIL_FieldValidator.AbstractFieldValidationResult {
        public IncompleteErrorResult(SObject so, String fieldLabel, FieldValidation__c rule, String customMessage) {
            super(so, fieldLabel, rule, customMessage);
        }

        protected override String buildMessage() {
            return getApplicableStage() == 0
                ? '\'' + fieldLabel + '\' should have a value'
                : '\'' + fieldLabel + '\' set to a value';
        }
    }

    public virtual class MandatoryValueErrorResult extends UTIL_FieldValidator.AbstractFieldValidationResult {
        public MandatoryValueErrorResult(SObject so, String fieldLabel, FieldValidation__c rule, String customMessage) {
            super(so, fieldLabel, rule, customMessage);
        }

        protected override String buildMessage() {
            return getApplicableStage() == 0
                ? '\'' + fieldLabel + '\' should have value \'' + rule.MandatoryValue__c + '\''
                : '\'' + fieldLabel + '\' to value \'' + rule.MandatoryValue__c + '\'';
        }
    }

    public virtual interface IDelegatedValidator {
        IFieldValidationResult validate(sObject so, FieldValidation__c fv);
    }

    private static Integer findlowestStatusNum(Set<Integer> l) {
        List<Integer> sl = new List<Integer>(l);
        sl.sort();
        return sl.get(0);
    }
}