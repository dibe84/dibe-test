global class c_JIT implements Auth.SamlJitHandler {
    private class JitException extends Exception{}

    private void handleJit(boolean create, User u, Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion) {
        Contact c;
        if (federationIdentifier.left(5) == 'EBAYK') {
            Account a = [SELECT Id, Portal_User__c FROM Account WHERE UniquePlatformId__c = :federationIdentifier];
            c = (Contact) GW_sObject.queryRecord('Contact', a.Portal_User__c);
        } else {
            c = (Contact) GW_sObject.queryRecord('Contact', federationIdentifier);
        }
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Customer Community Login User'];
        
        Integer randomNumber = Math.round(Math.random()*1000000);
        
        u.Username = ('' + Math.round(Math.random()*1000000)) + c.Email;
        u.LanguageLocaleKey = 'en_US';
        u.LastName = c.LastName;
        u.LocaleSidKey = 'en_US';
        u.ProfileId = p.Id;
        u.TimeZoneSidKey = 'Europe/Amsterdam';
        u.UserPermissionsMarketingUser = false;
        u.UserPermissionsOfflineUser = false;
        u.Alias = String.valueOf(randomNumber);
        u.DefaultGroupNotificationFrequency = 'N';
        u.DigestFrequency = 'N';
        u.Email = c.Email;
        u.EmailEncodingKey = 'UTF-8';        
        u.FederationIdentifier = federationIdentifier;
        
        if (create) {
            u.ContactId = c.Id;
            insert u;
        } else {
            update u;
        }
        
        Account acc = [SELECT Id, MemberId__c FROM Account WHERE Id = :c.AccountId];
        
        List<String> permissionSetsToAdd = new List<String>();
        permissionSetsToAdd.add('Portal_User');
        permissionSetsToAdd.add('Portal_User_'+acc.MemberId__c);
        
        
        List<PermissionSet> permissionSets = [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetsToAdd];
        List<PermissionSetAssignment> existingAssignments = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :u.Id];
        Set<Id> existingAssignmentIds = new Set<Id>();
        for (PermissionSetAssignment psa : existingAssignments) {
            existingAssignmentIds.add(psa.PermissionSetId);
        }
        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        for (PermissionSet ps : permissionSets) {
            if (!existingAssignmentIds.contains(ps.Id)) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.assigneeId = u.Id;
                psa.PermissionSetId = ps.Id;
                permissionSetAssignments.add(psa);
            }
        }
        insert permissionSetAssignments;
        
        
        //UTIL.throwError('User: ' + u);
        
        //return u;
    }

    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion) {
        //UTIL.throwError('CreateUser / samlSsoProviderId: ' + samlSsoProviderId + ' communityId: ' + communityId + ' portalId: ' + portalId + ' federationIdentifier: ' + federationIdentifier + ' attributes: ' + attributes + ' assertion: ' +assertion);
        User u = new User();
        handleJit(true, u, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion);
        return u;
    }

    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId, String federationIdentifier, Map<String, String> attributes, String assertion) {
        //UTIL.throwError('UpdateUser / samlSsoProviderId: ' + samlSsoProviderId + ' communityId: ' + communityId + ' portalId: ' + portalId + ' federationIdentifier: ' + federationIdentifier + ' attributes: ' + attributes + ' assertion: ' +assertion);
        handleJit(false, [SELECT Id, FirstName, ContactId FROM User WHERE Id=:userId], samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion);
    }
}