global class WSI_Lead {
    webService static void reOwnerLead(Id leadId){
    	try {
	    	for(Lead l : [select id, OwnerId from Lead where id =:leadId and OwnerId != :UserInfo.getUserId()]){
	    		for(User u : [select Profile.UserLicense.Name from User where id = :l.OwnerId and Profile.UserLicense.Name = 'Guest User License']) {
		    		l.OwnerId = UserInfo.getUserId();
		    		update l;
	    		}
	    	}
    	} catch(Exception e){}
    }
}