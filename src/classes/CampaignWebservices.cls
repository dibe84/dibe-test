/**
 * @Created: KF - 10-0-2015
 * @Description: 
 *  1. This class contains webservices used for managing campaigns
 */
 
 
global class CampaignWebservices {
    
    webService static String queueAllUnsent(Id campaignId) {
        String result = null;
        try {
            List<CampaignMember> membersToQueue = (List<CampaignMember>) GW_sObject.queryRecords('CampaignMember', 'Status = \'Unsent\' AND Campaign.Id = \'' + campaignId + '\'');
            if (membersToQueue.size() > 0) {
                for (CampaignMember member : membersToQueue) {
                    member.Status = 'Queued';
                }
                update membersToQueue;
                result = '' + membersToQueue.size();
            } else {
                result = '0';
            }
        } catch (Exception e) {
            result = e.getMessage();
        }
        return result;
    }
    
}