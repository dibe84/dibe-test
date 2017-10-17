public class AsyncBookingPushTract implements Queueable {
    
    public Opportunity[] listBookingPush = new List<Opportunity>();
    public String contextInvocation;
    
    public AsyncBookingPushTract(Opportunity[] opps, String contexInvocation) {
        listBookingPush = opps;
        contextInvocation = contexInvocation;
    }
    
    public void execute (QueueableContext context){
        GW_Opportunity.callBookingPush(listBookingPush, 0, contextInvocation, null, null);
    }
}