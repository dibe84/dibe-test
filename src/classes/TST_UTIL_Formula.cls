@isTest
public class TST_UTIL_Formula {
	@testSetup
	public static void createDataSet() {
		// Insert data
        Account a = new Account(Name='Test Account');
        insert a;

		Contact c = new Contact(LastName='Test Contact', AccountId = a.Id, Phone='+31630059008', Email='test@test.com');
		insert c;

		a.Finance_Contact__c = c.Id;
		update a;
	}

	private static void runAll() {
		System.SavePoint sp = null;
		if (!Test.isRunningTest()) {
			sp = Database.setSavePoint();
		}

		testSObject();
		testSObjectWithRelationship();
		testSObjectList();
		testSObjectAdd();
		testObject();
		testObjectList();
		testSimpleFormula();
		testContextFormula();
		testContextFormulaEach();

		if (!Test.isRunningTest()) {
			Database.rollback(sp);
		}
	}

	public static testMethod void testSObject() {
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		ctx.add('Account', (Account) [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1]);
		System.assertEquals('Test Account', (String) ctx.get('Account.Name'));
	}

	public static testMethod void testSObjectWithRelationship() {
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		ctx.add('Account', (Account) [SELECT Id, Name, Finance_Contact__r.Name FROM Account WHERE Name = 'Test Account' LIMIT 1]);
		System.assertEquals('Test Contact', (String) ctx.get('Account.Finance_Contact__r.Name'));
	}

	public static testMethod void testSObjectAdd() {
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		ctx.add('Account', (Account) [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1]);
		ctx.walk('Account').add('Test', 'STRINGVALUE');
		System.assertEquals('STRINGVALUE', (String) ctx.get('Account.Test'));
	}

	public static testMethod void testSObjectList() {
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		ctx.add('Accounts', [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1]);
		System.assertEquals('Test Account', ctx.walk('Accounts').asList().get(0).get('Name'));
	}

	public static testMethod void testObject() {
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		Map<String,Object> obj = new Map<String,Object>();
		obj.put('key', 'value');
		obj.put('rel', new Map<String,Object>{'key2' => 'value2'});
		ctx.add('Object', obj);
		System.assertEquals('value2', ctx.get('Object.rel.key2'));
	}

	public static testMethod void testObjectList() {
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		Map<String,Object> obj = new Map<String,Object>();
		obj.put('key', 'value');
		obj.put('rel', new Map<String,Object>{'key2' => (Account) [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1]});
		List<Object> objectList = new List<Object>();
		objectList.add(obj);
		ctx.add('List', objectList);
		System.assertEquals('Test Account', ctx.walk('List').asList().get(0).get('rel.key2.Name'));
	}

	public static testMethod void testSimpleFormula() {
		UTIL_Formula.Formula f = new UTIL_Formula.Formula('IF(1==1,true,false)');
		System.assertEquals(f.getInstance(null).getResult(), true);
	}

	public static testMethod void testContextFormula() {
		UTIL_Formula.Formula f = new UTIL_Formula.Formula('IF(Account.Name=="Test Account",true,false)');
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		ctx.add('Account', (Account) [SELECT Id, Name, Finance_Contact__r.Name FROM Account WHERE Name = 'Test Account' LIMIT 1]);
		System.assertEquals(f.getInstance(ctx).getResult(), true);

		UTIL_Formula.Formula f2 = new UTIL_Formula.Formula('IF(Account.Name=="Test Account",false,false)');
		System.assertEquals(f2.getInstance(ctx).getResult(), false);
	}

	public static testMethod void testContextFormulaEach() {
		UTIL_Formula.Formula f = new UTIL_Formula.Formula('EACH(Accounts,IF(Name=="Test Account",true,false))');
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		ctx.add('Accounts', [SELECT Id, Name, Finance_Contact__r.Name FROM Account WHERE Name = 'Test Account' LIMIT 15]);
		System.assertEquals(true, f.getInstance(ctx).getResult());
		ctx.walk('Accounts').add(null, [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1]);
	}

	public static testMethod void testFormulas() {
		UTIL_Formula.Formula f = new UTIL_Formula.Formula('OR(NOT(ISBLANK(Account.Name)), AND(1==1,2==1), NOT(1==1), NOT(1==2), ISBLANK(Account.Name), REGEX("([0-9])+", "1234") )');
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		ctx.add('Account', (Account) [SELECT Id, Name, Finance_Contact__r.Name FROM Account WHERE Name = 'Test Account' LIMIT 1]);
		System.assertEquals(true, f.getInstance(ctx).getResult());
	}

	public static testMethod void testRegex() {
		UTIL_Formula.Formula f = new UTIL_Formula.Formula('REGEX("([0-9])+", "1234")');
		UTIL_Formula.IContextData ctx = (UTIL_Formula.IContextData) new UTIL_Formula.ContextData();
		System.assertEquals(true, f.getInstance(ctx).getResult());
	}
}