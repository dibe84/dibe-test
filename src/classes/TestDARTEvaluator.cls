/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestDARTEvaluator {
    
    static testMethod void testEval2()
    {
        Test.startTest();
        String formula1 = '(car=bmw) AND (pos <> bottom)';
    
        List<DARTEvaluator.CustomCriteriaSet> lc1 = DARTEvaluator.convertToCritSet(formula1)[0];
        System.assertEquals(2,lc1.size(), '2 criteriaSet expected');
        
        Test.stopTest();
    }
    
   static testMethod void testEval()
    {
        Test.startTest();
        
            String formula1 =  '(um=6 OR um=7 OR um=8) AND (fbi=11730 OR fbo=11730 OR fse=11730)';
            String formula2 = '((um=6) OR (um=7) OR (um=8)) AND (fbi=11730)';
            String formula0 = '((um=6) OR (um=7) OR (um=8))';
            String formula3 = 'um=6 AND (um=7 OR um=8)';
            String formula4 = '(um=7 OR um=8) AND um=6';
            String formula5 = 'um=7 OR um=8';
            // ((um=6) OR (um=7) OR (um=8))
            //((um=6) OR (um=7) OR (um=8)) AND ((fbi=11730))
            String formula6 = '(kw=apple)';
            
        List<DARTEvaluator.CustomCriteriaSet> lc1 = DARTEvaluator.convertToCritSet(formula1)[0];
        System.assertEquals(2,lc1.size(), '2 criteriaSet expected');
        
        System.assert(lc1.get(0).getCriterion().get(0).getParameter() !=null, 'Key expected');
        System.assert(lc1.get(0).getCriterion().get(0).getValue() !=null, 'Value expected');
        System.assertEquals(lc1.get(0).getCriterion().get(0).getOperator() ,'=', 'EQual expected');
        
        List<DARTEvaluator.CustomCriteriaSet> lc4 = DARTEvaluator.convertToCritSet(formula6)[0];
        System.assertEquals(1,lc4.size(), ' 1 crit set kw=apple expected');
        
        String f12 = '(((loc=Aberdeen*) OR (loc=Bath*) OR (loc=Belfast*) OR (loc=Birmingham*) OR (loc=Edinburgh*) OR (loc=Glasgow*) OR (loc=London*))) AND (kw=banana OR kw=apple)';
        List<DARTEvaluator.CustomCriteriaSet> lc5 = DARTEvaluator.convertToCritSet(f12)[0];
        System.assertEquals(2,lc5.size(), ' 2 AND = 2 crit set');
         
        String f13 ='fruit=apple,banana,black burry';
        List<DARTEvaluator.CustomCriteriaSet> lc6 = DARTEvaluator.convertToCritSet(f13)[0];
        System.assertEquals(1,lc6.size(), '1 crit set as comma = OR ');
        
        String f14 ='(fruit=apple,banana,black burry) AND loc=London';
        List<DARTEvaluator.CustomCriteriaSet> lc7 = DARTEvaluator.convertToCritSet(f14)[0];
        System.assertEquals(2,lc7.size(), '2 crit set as comma = OR x 1AND: fruit=apple AND loc=London, fruit=banana AND loc=London, fruit=black burry AND loc=London');
        
        String formula15 = 'Audience Segment=10,25$ to 100,25$ OR Audience Segment=20,25$ to 200,25$ OR car=bmw,toyota';
        List<DARTEvaluator.CustomCriteriaSet> lc8 = DARTEvaluator.convertToCritSet(formula15)[0];
        System.assertEquals(1,lc8.size(), '1 crit set for: [Audience Segment=10,25$ to 100,25$],[Audience Segment=20,25$ to 200,25$],[car=bmw],[car=toyota] ');
        Test.stopTest();
        
    }
    
    
}