/**
 * Created by ronvelzeboer on 17/10/16.
 */

@isTest
public with sharing class TST_UTIL_WSC_Subscription {

    @isTest
    static void testEmptyWSCSubscriptionCustomSettingsShouldReturnUnsubscribed() {
        System.assert(false == UTIL_WSC_Subscription.isSubscribedToWS('EBAYKRE', 'WSC_API_SFECG_v1', 'AccountPush'), 'Unregistered subscription should not pass');
        System.assert(false == UTIL_WSC_Subscription.isSubscribedToWS('EBAYKRE', 'WSC_API_SFECG_v1', 'BookingPush'), 'Unregistered subscription should not pass');
    }

    @isTest
    static void testOnlySubscribedWsShouldReturnSubscribed() {
        List<WSC_Subscription__c> subscriptions = new List<WSC_Subscription__c> {
            new WSC_Subscription__c(
                Name = 'EBAYKRE.WSC_API_SFECG_v1.AccountPush',
                ConsumerId__c = 'EBAYKRE',
                Class__c = 'WSC_API_SFECG_v1',
                Method__c = 'AccountPush',
                IsActive__c = true
            ),
            new WSC_Subscription__c(
                Name = 'EBAYKRE.WSC_API_SFECG_v1.BookingPush',
                ConsumerId__c = 'EBAYKRE',
                Class__c = 'WSC_API_SFECG_v1',
                Method__c = 'BookingPush',
                IsActive__c = true
            )
        };
        insert subscriptions;

        System.assert(UTIL_WSC_Subscription.isSubscribedToWS('EBAYKRE', 'WSC_API_SFECG_v1', 'BookingPush'), 'Registered subscription should pass');
        System.assert(UTIL_WSC_Subscription.isSubscribedToWS('EBAYKRE', 'WSC_API_SFECG_v1', 'AccountPush'), 'Registered subscription should pass');
        System.assert(false == UTIL_WSC_Subscription.isSubscribedToWS('EBAYKRE', 'WSC_API_SFECG_v2', 'AccountPush'), 'Unregistered subscription should not pass');
    }

    @isTest
    static void testInactiveSubscriptionShouldReturnUnsubscribed() {
        WSC_Subscription__c subscription = new WSC_Subscription__c(
            Name = 'EBAYKRE.WSC_API_SFECG_v1.BookingPush',
            ConsumerId__c = 'EBAYKRE',
            Class__c = 'WSC_API_SFECG_v1',
            Method__c = 'BookingPush',
            IsActive__c = false
        );
        insert subscription;

        System.assert(false == UTIL_WSC_Subscription.isSubscribedToWS('EBAYKRE', 'WSC_API_SFECG_v1', 'BookingPush'), 'Unregistered subscription should not pass');
    }
}