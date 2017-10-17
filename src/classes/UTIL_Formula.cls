public class UTIL_Formula {
	/* ContextData classes and types */
	public enum ContextDataType { ROOT, VAL, OBJ, ARR }
	public interface IContextData {
		Object get(); // get the current contextdata's value, needs to be casted
		Object get(String path); // get a value down the road somewhere
		IContextData walk(String path); // walk a certain path
		IContextData add(String key, Object value);
		List<IContextData> asList();
		ContextDataType getType(); // get the type
	}
	public virtual class ContextData implements IContextData {
		private Object value;
		private ContextDataType type;
		public ContextData() {
			this.type = ContextDataType.ROOT;
			this.value = new Map<String,IContextData>();
		}
		public virtual Object get() {
			return this.value;
		}
		public Object get(String path) {
			// If we get a path we can assume that the entire path except the last element will always be of type contextdata
			path = path.trim();

			Object result = null;
			try {
				IContextData data = this.walk(path);
				result = data.get();
			} catch (Exception e) {}
			return result;
		}
		public IContextData walk(String path) {
			// If we get a path we can assume that the entire path except the last element will always be of type contextdata
			IContextData result = null;
			try {
				List<String> pathParts = path.split('\\.');
				Map<String,IContextData> valueCopy = (Map<String,IContextData>) this.value;
				if (pathParts.size() == 1) {
					// This is the last element, it will be of type VAL, but we need to retrieve it and call getValue() on it
					return valueCopy.get(pathParts.get(0).trim().toLowerCase());
				} else {
					String firstKey = pathParts.remove(0).toLowerCase().trim();

					return valueCopy.get(firstKey).walk(String.join(pathParts, '.'));
				}
			} catch (Exception e) {}
			return result;
		}
		public ContextDataType getType() {
			return this.type;
		}
		public List<IContextData> asList() {
			return (List<IContextData>) this.value;
		}
		public IContextData add(String key, Object val) {
			IContextData element = null;
			if (this.type == ContextDataType.OBJ || this.type == ContextDataType.ROOT) {
				Map<String,IContextData> valueCopy = (Map<String,IContextData>) this.value;
				if (val instanceof IContextData) {
					element = (IContextData) val;
				} else {
					element = itemToContextData(val);
				}
				if (key != null) {
					valueCopy.put(key.toLowerCase(), element);
				} else {
					Map<String,IContextData> copyEl = (Map<String,IContextdata>) element.get();
					for (String s : copyEl.keySet()) {
						valueCopy.put(s, copyEl.get(s));
					}
				}
				this.value = valueCopy;
			} else if (this.type == ContextDataType.ARR) {
				List<IContextData> valueCopy = (List<IContextData>) this.value;
				if (val instanceof IContextData) {
					element = (IContextData) val;
				} else {
					element = itemToContextData(val);
				}
				valueCopy.add((IContextData) element);
				this.value = valueCopy;
			} else if (this.type == ContextDataType.VAL) {}
			return element;
		}
	}
	public class ContextDataValue extends ContextData {
		public ContextDataValue(Object o) {
			this.value = o;
			this.type = ContextDataType.VAL;
		}
	}
	public class ContextDataArray extends ContextData {
		public ContextDataArray(List<Object> objs) {
			this.value = objs;
			this.type = ContextDataType.ARR;
		}
	}
	public class ContextDataObject extends ContextData {
		public ContextDataObject(Object o) {
			this.value = o;
			this.type = ContextDataType.OBJ;
		}
	}

	/* ContextData static methods */
	public static ContextDataObject sObjectToContextData(sObject sObj) {
		String objectType = sObj.getsObjectType().getDescribe().getName().toLowerCase(); // @TODO: Cache
		// Loop through all possible sObject fields and set them in this.value
		Map<String,IContextData> values = new Map<String,IContextData>();
		Set<String> relationshipNames = getRelationshipNames(objectType);
		Map<String,Object> exploded = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(sObj));
		for (String s : exploded.keySet()) {
			// S is a key in our map...
			try {
				if (relationshipNames.contains(s.toLowerCase())) {
					values.put(s.toLowerCase(), itemToContextData(exploded.get(s)));
				} else {
					values.put(s.toLowercase(), (IContextData) new ContextDataValue(exploded.get(s)));
				}
			} catch (Exception e) {

			}
		}

		return new ContextDataObject(values);
	}
	public static IContextData itemToContextData(Object obj) {
		IContextData result = null;
		String objType = getType(obj);
		if (objType == '') {
			return result;
		} else if (objType == 'Iterable') {
			// This yields a List<ContextData>
			List<Object> objList = (List<Object>) obj;
			List<IContextData> ctxList = new List<IContextData>();
			if (objList.size() > 0) {
				String itemType = getType(objList.get(0));
				for (Object o : objList) {
					ctxList.add(itemToContextData(o));
				}
				return new ContextDataArray(ctxList);
			} else {
				return result;
			}
		} else if (objType == 'SObject') {
			return sObjectToContextData((SObject) obj);
		} else if (objType == 'Map') {
			Map<String,IContextData> mapItem = new Map<String,IContextData>();
			Map<String,Object> casted = (Map<String,Object>) obj;
			for (String s : casted.keySet()) {
				 mapItem.put(s.toLowerCase(), itemToContextData(casted.get(s)));
			}
			return new ContextDataObject(mapItem);
		} else {
			return new ContextDataValue(obj);
		}
		return result;
	}
	public static String getType(Object o) {
		if (o == null)								return '';
		if (o instanceof Iterable<SObject>)			return 'Iterable';
		if (o instanceof SObject)					return 'SObject';
		if (o instanceof Boolean)					return 'Boolean';
		if (o instanceof Id)						return 'Id';
		if (o instanceof String)					return 'String';
		if (o instanceof Blob)						return 'Blob';
		if (o instanceof Date)						return 'Date';
		if (o instanceof Datetime)					return 'Datetime';
		if (o instanceof Time)						return 'Time';
		if (o instanceof Integer)					return 'Integer';
		if (o instanceof Long)						return 'Long';
		if (o instanceof Decimal)					return 'Decimal';  // we can't distinguish between decimal and double
		if (o instanceof Double)					return 'Double';   // we can't distinguish between decimal and double
		if (o instanceof Iterable<Object>)			return 'Iterable';
		if (o instanceof Map<Object,Object>)		return 'Map';
		if (o instanceof Map<String,Object>)		return 'Map';
		return 'Object';
	}

	/* Formula and Expression classes */
	public class Formula {
		public String formula;
		public IExpression expression;
		public List<String> referencedFields = new List<String>();
		public Formula(String formula) {
			this.formula = formula;
			this.expression = buildExpression(this.formula);
			List<ValueExpression> valueExpressions = this.expression.getChildValues();
			for (ValueExpression ve : valueExpressions) {
				if (ve.valueType == 'CONTEXT') {
					this.referencedFields.add(ve.text.trim());
				}
			}
		}
		public FormulaInstance getInstance(IContextData ctx) {
			return new FormulaInstance(this, ctx);
		}
	}

	public class FormulaInstance {
		private Formula formula;
		private IContextData ctx;

		public FormulaInstance(Formula f, IContextData ctx) {
			this.formula = f;
			this.ctx = ctx;
			for (ValueExpression expr : this.formula.expression.getChildValues()) {
				expr.injectContext(ctx);
			}
		}

		public Object getResult() {
			return this.formula.expression.run();
		}
	}

	/* Expression classes and logic */
	public static Set<String> functions = new Set<String>{'IF', 'AND', 'OR', 'REGEX', 'EACH', 'NOT', 'ISBLANK'};
	public static Set<String> comparators = new Set<String>{'==', '!=', '>', '<', '>=', '<=', '&'};
	public enum ExpressionType { COMPARISON, FUNCTION, VALUE }
	public static IExpression buildExpression(String text) {
		// Determine the type, create an instance
		ExpressionType type = determineExpressionType(text);
		if (type == ExpressionType.FUNCTION) { return (IExpression) new FunctionExpression(text); }
		if (type == ExpressionType.COMPARISON) { return (IExpression) new ComparisonExpression(text); }
		if (type == ExpressionType.VALUE) { return (IExpression) new ValueExpression(text); }
		return null;
	}
	public static ExpressionType determineExpressionType(String text) {
		for (String func : functions) {
			if (text.startsWith(func)) {
				return ExpressionType.FUNCTION;
			}
		}
		for (String comp : comparators) {
			if (text.contains(comp)) {
				return ExpressionType.COMPARISON;
			}
		}
		return ExpressionType.VALUE;

		return null;
	}

	public interface IExpression {
		ExpressionType getType();
		List<IExpression> getChildren();
		List<ValueExpression> getChildValues();
		IContextData getContext();
		String getText();
		Object getResult();
		Object run();
	}
	public virtual class ExpressionBase {
		public String text;
		public ExpressionType type;
		public List<IExpression> arguments = new List<IExpression>();
		public void init() {}
		public ExpressionType getType() {
			return this.type;
		}
		public virtual IContextData getContext() {
			return null;
		}
		public String getText() {
			return this.text;
		}
		public Object getResult() {
			Object result = this.run();
			return result;
		}
		public virtual Object run() {
			return null;
		}
		public List<IExpression> getChildren() {
			List<IExpression> result = new List<IExpression>();
			result.addAll(this.arguments);
			for (IExpression expr : this.arguments) {
				result.addAll(expr.getChildren());
			}
			return result;
		}
		public List<ValueExpression> getChildValues() {
			List<ValueExpression> result = new List<ValueExpression>();
			for (IExpression expr : this.getChildren()) {
				if (expr.getType() == ExpressionType.VALUE) {
					result.add((ValueExpression) expr);
				}
			}
			return result;
		}
	}
	public class ValueExpression extends ExpressionBase implements IExpression {
		public String valueType = null;
		public Object value = null;
		public IContextData ctx = null;
		public ValueExpression(String text) {
			this.type = ExpressionType.VALUE;
			this.text = text;
			this.valueType = this.getValueType();
			this.value = this.getValue();
			this.init();
		}
		public void injectContext(IContextData ctx) {
			this.ctx = ctx;
		}
		public override IContextData getContext() {
			return this.ctx;
		}
		private String getValueType() {
			if (this.text.indexOf('"') > -1 || this.text.trim().isNumeric()) {
				return 'STRING';
			} else if (this.text.trim() == 'true' || this.text.trim() == 'false') {
				return 'BOOLEAN';
			} else {
				return 'CONTEXT';
			}
		}
		private Object getValue() {
			if (this.valueType == 'STRING') {
				return this.text.trim().replaceAll('"','');
			} else if (this.valueType == 'BOOLEAN') {
				return this.text.trim() == 'true';
			} else {
				return this.text;
			}
		}
		public override Object run() {
			if (this.valueType == 'CONTEXT') {
				return this.ctx.get(this.text);
			} else {
				return this.value;
			}
		}
	}
	public class ComparisonExpression extends ExpressionBase implements IExpression {
		public String compareType = null;
		public ComparisonExpression(String text) {
			this.type = ExpressionType.COMPARISON;
			this.text = text;
			this.compareType = this.getCompareType();
			this.arguments = this.getArguments();
			this.init();
		}
		public override Object run() {
			if (this.compareType == '==') {
				return this.arguments.get(0).getResult() == this.arguments.get(1).getResult();
			} else if (this.compareType == '!=') {
				return this.arguments.get(0).getResult() != this.arguments.get(1).getResult();
			} else if (this.compareType == '>=') {
				return Integer.valueOf(this.arguments.get(0).getResult()) >= Integer.valueOf(this.arguments.get(1).getResult());
			} else if (this.compareType == '<=') {
				return Integer.valueOf(this.arguments.get(0).getResult()) <= Integer.valueOf(this.arguments.get(1).getResult());
			} else if (this.compareType == '<') {
				return Integer.valueOf(this.arguments.get(0).getResult()) < Integer.valueOf(this.arguments.get(1).getResult());
			} else if (this.compareType == '>') {
				return Integer.valueOf(this.arguments.get(0).getResult()) > Integer.valueOf(this.arguments.get(1).getResult());
			} else if (this.compareType == '&') {
				return String.valueOf(this.arguments.get(0).getResult()) + String.valueOf(this.arguments.get(1).getResult());
			}
			return null;
		}
		private String getCompareType() {
			for (String comp : comparators) {
				if (this.text.contains(comp)) {
					return comp;
				}
			}
			return null;
		}
		private List<IExpression> getArguments() {
			List<IExpression> result = new List<IExpression>();
			for (String comp : comparators) {
				if (this.text.contains(comp)) {
					List<String> splits = this.text.split(comp);
					for (String s : splits) {
						result.add(buildExpression(s));
					}
				}
			}
			return result;
		}
	}
	public class FunctionExpression extends ExpressionBase implements IExpression {
		public String function = null;
		public FunctionExpression(String text) {
			this.type = ExpressionType.FUNCTION;
			this.text = text;
			this.init();
			this.function = this.determineFunction();
			this.arguments = this.determineArguments();
		}
		private String determineFunction() {
			Integer bracketStart = this.text.indexOf('(');
			Integer bracketEnd = this.text.lastIndexOf(')');
			String functionName = this.text.substring(0, bracketStart);
			if (!functions.contains(functionName)) {
				throw new FormulaException('Unknown function: ' + functionName);
			}
			return functionName;
		}
		private List<IExpression> determineArguments() {
			Integer bracketStart = this.text.indexOf('(');
			Integer bracketEnd = this.text.lastIndexOf(')');
			String body = this.text.substring(bracketStart+1, bracketEnd);

			List<List<Integer>> bracketGroups = new List<List<Integer>>();
			Integer bracketState = null;
			Integer initialBracket = null;
			Integer closingBracket = null;
			Boolean quoteState = false;

			for (Integer i = 0; i < body.length(); i++) {
				String c = body.substring(i,i+1);
				if (c == '"') {
					quoteState = !quoteState;
				}
				if (c == '(') {
					if (quoteState) {
						continue;
					}
					if (bracketState == null) {
						bracketState = 0;
						initialBracket = i;
					}
					bracketState++;
				} else if (c == ')') {
					if (quoteState) {
						continue;
					}
					bracketState--;
				}
				if (bracketState == 0) {
					closingBracket = i;
					// We found one complete outer loop, yay
					bracketGroups.add(new List<Integer>{initialBracket, closingBracket});
					bracketState = null;
					initialBracket = null;
					closingBracket = null;
				}
			}

			List<String> identifiedFunctions = new List<String>();

			Integer lastPosition = 0;
			for (List<Integer> bg : bracketGroups) {
				// Get the enclosing function name as well for each bracket group
				String searchPart = body.substring(lastPosition, bg.get(0));
				Integer lastSpace = searchPart.lastIndexOf(' ');
				Integer lastComma = searchPart.lastIndexOf(',');
				Integer lastBracket = searchPart.lastIndexOf('(');
				Integer max = Math.max(lastSpace, Math.max(lastComma, lastBracket));
				identifiedFunctions.add(body.substring(lastPosition +1 + max, bg.get(1)+1));
				lastPosition = bg.get(1)+1;
			}

			// Identified functions needs to be sorted from complex to non-complex....
			identifiedFunctions = sortByLength(identifiedFunctions);

			// Now we replace all identifiedFunctions by some string, then at the top level we split by "," to determine the number of arguments we have and identify non-function arguments
			Integer i = 0;
			for (String fn : identifiedFunctions) {
				body = body.replace(fn, 'FN____'+i);
				i++;
			}
			List<String> parts = body.split(',');
			List<IExpression> result = new List<IExpression>();
			for(String s : parts) {
				s = s.trim();
				if (s.contains('FN____')) {
					List<String> splits = s.split('____');
					s = identifiedFunctions.get(Integer.valueOf(splits.get(1)));
				}
				result.add(buildExpression(s));
			}
			return result;
		}

		public override Object run() {
			if (this.function == 'IF') {
				return FUNCTION_IF(this.arguments);
			} else if (this.function == 'OR') {
				return FUNCTION_OR(this.arguments);
			} else if (this.function == 'AND') {
				return FUNCTION_AND(this.arguments);
			} else if (this.function == 'REGEX') {
				return FUNCTION_REGEX(this.arguments);
			} else if (this.function == 'EACH') {
				return FUNCTION_EACH(this.arguments);
			} else if (this.function == 'NOT') {
				return FUNCTION_NOT(this.arguments);
			} else if (this.function == 'ISBLANK') {
				return FUNCTION_ISBLANK(this.arguments);
			}
			return null;
		}
	}

	/* Formula Functions */
	public static Object FUNCTION_IF(List<IExpression> arguments) {
		IExpression statement = arguments.get(0);
		Object result = statement.getResult();
		if (result == true) {
			return arguments.get(1).getResult();
		} else if (result == false) {
			return arguments.get(2).getResult();
		}
		return null;
	}
	public static Object FUNCTION_AND(List<IExpression> arguments) {
		Boolean result = true;
		for (IExpression arg : arguments) {
			if (result && arg.getResult() == true) {
				result = true;
			} else {
				result = false;
			}
		}
		return result;
	}
	public static Object FUNCTION_OR(List<IExpression> arguments) {
		Boolean result = false;
		for (IExpression arg : arguments) {
			if (arg.getResult() == true) {
				result = true;
				break;
			}
		}
		return result;
	}
	public static Object FUNCTION_REGEX(List<IExpression> arguments) {
		Boolean regexMatch = Pattern.matches(String.valueOf(arguments.get(0).getResult()), String.valueOf(arguments.get(1).getResult()));
		return regexMatch;
	}
	public static Object FUNCTION_EACH(List<IExpression> arguments) {
		List<IContextData> dataObjects = (List<IContextData>) arguments.get(0).getResult();
		String childRelationshipName = arguments.get(0).getText();
		String formulaText = arguments.get(1).getText().replaceAll(childRelationshipName + '.', '');
		Formula f = formulaCache.get(formulaText);
		if (f == null) {
			f =  new Formula(formulaText);
			formulaCache.put(formulaText, f);
		}

		Boolean result = true;
		for (IContextData cd : dataObjects) {
			Object sObjResult = f.getInstance(cd).getResult();

			if (sObjResult == false) {
				result = false;
			}
		}
		return result;
	}
	public static Object FUNCTION_ISBLANK(List<IExpression> arguments) {
		return arguments.get(0).getResult() == null || arguments.get(0).getResult() == '';
	}
	public static Object FUNCTION_NOT(List<IExpression> arguments) {
		return arguments.get(0).getResult() != true;
	}

	/* Utility */
	private static Map<String, Schema.SObjectType> globalDescribe {
		get {
			if (globalDescribe == null) {
				Map<String, Schema.SObjectType> tmpDescribe = Schema.getGlobalDescribe();
				Map<String, Schema.SObjectType> lowerCaseDescribe = new Map<String, Schema.SObjectType>();
				for (String s : tmpDescribe.keySet()) {
					lowerCaseDescribe.put(s.toLowerCase(), tmpDescribe.get(s));
				}
				globalDescribe = lowerCaseDescribe;
			}
			return globalDescribe;
		}
		private set;
	}
	public class SortString implements Comparable {
		public String data;
		public SortString(String data) {
			this.data = data;
		}

		public Integer compareTo(Object compareTo) {
			SortString cmpObj = (SortString) compareTo;
			Integer numberofBrackets = this.data.countMatches('(');
			Integer numberOfBracketsCmp = cmpObj.data.countMatches('(');
			if (numberofBrackets > numberOfBracketsCmp) {
				return -1;
			} else if (numberofBrackets < numberOfBracketsCmp) {
				return 1;
			} else {
				return 0 ;
			}
		}
	}
	public static List<String> sortByLength(List<String> input) {
		List<String> output = new List<String>();
		if (input != null) {
			List<SortString> sortList = new List<SortString>();
			for (String s : input) {
				sortList.add(new SortString(s));
			}
			sortList.sort();
			for (SortString s : sortList) {
				output.add(s.data);
			}
		}
		return output;
	}
	public static Formula getFormula(String s) {
		if (formulaCache.get(s) == null) {
			formulaCache.put(s, new Formula(s));
		}
		return formulaCache.get(s);
	}
	private static Map<String,Formula> formulaCache = new Map<String,Formula>();
	public class FormulaException extends Exception {}

	private static Map<String, Schema.SObjectField> getFieldMap(String objectType) {
		Map<String, Schema.SObjectField> result = objectToFieldMapCache.get(objectType);
		if (result == null) {
			result = globalDescribe.get(objectType).getDescribe().fields.getMap();
			objectToFieldMapCache.put(objectType, result);
		}
		return result;
	}
	private static Schema.DescribeFieldResult getObjectFieldDescribe(Schema.SObjectField sObjectField) {
		Schema.DescribeFieldResult result = objectFieldDescribeCache.get(sObjectField);
		if (result == null) {
			result = sObjectField.getDescribe();
			objectFieldDescribeCache.put(sObjectField, result);
		}
		return result;
	}
	private static List<Schema.sObjectType> getRelatedTypes(Schema.DescribeFieldResult describeResult) {
		List<Schema.sObjectType> result = relatedTypeCache.get(describeResult);
		if (result == null) {
			result = describeResult.getReferenceTo();
			relatedTypeCache.put(describeResult, result);
		}
		return result;
	}
	private static String getRelationshipName(Schema.DescribeFieldResult describeResult) {
		String result = relationshipNameCache.get(describeResult);
		if (result == null) {
			result = describeResult.getRelationshipName();
			relationshipNameCache.put(describeResult, result);
		}
		return result;
	}

	private static Set<String> getRelationshipNames(String objectType) {
		Set<String> result = objectRelationshipNameCache.get(objectType);
		if (result == null) {
			result = new Set<String>();
			Map<String, Schema.SObjectField> fieldMap = getFieldMap(objectType);
			for (Schema.SObjectField f : fieldMap.values()) {
				Schema.DescribeFieldResult fd = getObjectFieldDescribe(f);
				List<Schema.sObjectType> relatedTypes = getRelatedTypes(fd);
				if (relatedTypes != null && relatedTypes.size() > 0) {
					String relationshipName = getRelationshipName(fd);
					result.add(relationshipName.toLowerCase());
				}
			}
			objectRelationshipNameCache.put(objectType, result);
		}
		return result;
	}

	public static Map<String,Map<String, Schema.SObjectField>> objectToFieldMapCache = new Map<String,Map<String, Schema.SObjectField>>();
	public static Map<Schema.SObjectField, Schema.DescribeFieldResult> objectFieldDescribeCache = new Map<Schema.SObjectField, Schema.DescribeFieldResult>();
	public static Map<Schema.DescribeFieldResult, List<Schema.sObjectType>> relatedTypeCache = new Map<Schema.DescribeFieldResult, List<Schema.sObjectType>>();
	public static Map<Schema.DescribeFieldResult, String> relationshipNameCache = new Map<Schema.DescribeFieldResult, String>();
	public static Map<String,Set<String>> objectRelationshipNameCache = new Map<String,Set<String>>();
}