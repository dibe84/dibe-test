public class Q_CheckPermissionGroups implements System.Queueable, UTIL_CustomJob.ICustomJob, Database.AllowsCallouts {

	public Q_CheckPermissionGroups() {
		UTIL_CustomJob.CustomJobDef jobDef = UTIL_CustomJob.getJobDef('Q_CheckPermissionGroups');
		this.numRecords = 1;
		this.readyForRun = true;
	}

	public void execute(QueueableContext qc) {
		try {
			UTIL_CustomJob.updateJobExecuteStartTime(qc.getJobId(), Datetime.now());
			Map<Id, User> allUsers = new Map<Id,User>(F_PermissionGroup.getUsers());
			F_PermissionGroup.CalculationResult calcResult = F_PermissionGroup.calculate(allUsers.keySet(), null);
			System.debug(LoggingLevel.ERROR, 'Calcresult: ' + calcResult);
			if (calcResult.changesPending) {
				// Send e-mail
				List<String> bodyElements = new List<String>();
				bodyElements.add('The system has detected that the following changes are pending in regards to Permission Groups:');

				for (User u : allUsers.values()) {
					if (calcResult.permissionSetsToAdd.get(u.Id) != null || calcResult.permissionSetsToRemove.get(u.Id) != null) {
						List<String> userElements = new List<String>();
						userElements.add('<b>' + (u.Firstname != null ? u.Firstname + ' ' : '') + u.Lastname + ' (' + u.Username + ')' + '</b>');
						if (calcResult.permissionSetsToAdd.get(u.Id) != null) {
							for (PermissionSet ps: calcResult.permissionSetsToAdd.get(u.Id)) {
								userElements.add('<b>Add</b>: ' + ps.Name);
							}
						}
						if (calcResult.permissionSetsToRemove.get(u.Id) != null) {
							for (PermissionSet ps: calcResult.permissionSetsToRemove.get(u.Id)) {
								userElements.add('<b>Remove</b>: ' + ps.Name);
							}
						}
						bodyElements.add(String.join(userElements,'<br />\n'));
					}
				}

				UTIL_Email.sendSystemAlert('Permission Groups out of sync', String.join(bodyElements, '<br />\n<br />\n'), String.join(bodyElements, '<br />\n<br />\n'));
			}
		} catch(Exception ex) {
			UTIL.throwError('Q_CheckPermissionGroups: ',ex);
		} finally {
			UTIL_CustomJob.markJobFinished('Q_CheckPermissionGroups', qc.getJobId());
		}
	}

	private Boolean readyForRun = true;
	private Integer numRecords = 1;
	public Boolean readyForRun() { return this.readyForRun; }
	public integer getNumRecords() { return this.numRecords; }
}