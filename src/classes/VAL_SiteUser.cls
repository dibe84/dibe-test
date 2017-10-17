/**
 * @Buss: To validate all information which input by Force.com/Community site visitor 
 * @author: Gaeasys Dev Team
 * @createddate: 10 Apr 2017
 */
public with sharing class VAL_SiteUser {
    
    /**
     * @Desc: To check whether input email address is already existed in the org/other integration system. Ex: MP User API
     * @param: email is an email input by customer (can be from Force.com sites/Community site)
     * @param: memberUnit is Member Unit name
     * @return: if email address is found in the org/other integration system --> true
     *          Else --> false
     */
    public static Boolean isEmailExist(String email, String memberUnit) {
        try {
            //Todo
        } catch (Exception ex) {
            //Todo
            return false;
        }
        
        return true;
    }
    
    /**
     * @Desc: To check whether input email address is already existed in the org/other integration system. Ex: MP User API
     * @param: promotionCode is promotion code which company provide to their customer
     * @param: memberUnit is Member Unit name
     * @return: if promotionCode is found and still active in the org/other integration system --> true 
     *          Else --> false
     */
    public static Boolean checkPromotionCode(String promotionCode, String memberUnit) {
        try {
            //Todo
        } catch (Exception ex) {
            //Todo
            return false;
        }
        
        return true;
    }
}