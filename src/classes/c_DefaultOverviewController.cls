public class c_DefaultOverviewController {
    public List<c_Common.Subscription> activeSubscriptions { get; set; }
    public Contact currentContact { get; set; }
    private User currentUser { get; set; }
    
    public c_DefaultOverviewController () {
        currentUser = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()];
        currentContact = [SELECT Id, Name FROM Contact WHERE Id = :currentUser.ContactId];
        activeSubscriptions = c_Common.getSubscriptionsByContact(currentContact.Id);
    }
}