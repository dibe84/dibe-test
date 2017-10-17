public with sharing class PGC_SandboxInitialisation {
	public List<StaticResource> availableStaticResources { get; set; }
	public String exportName { get; set; }
	public Id selectedSrId { get; set; }

	public PGC_SandboxInitialisation() {
		exportName = F_SandboxInitialisation.DefaultDataContainer;
		load();
	}

	public PageReference create() {
		try {
			F_SandboxInitialisation.exportCurrentStatus(exportName);
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Export saved successfully'));
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error while exporting: ' + e.getMessage() + ' Trace: ' + e.getStackTraceString()));
		}
		load();
		return null;
	}

	public PageReference import() {
		if(!String.isBlank(selectedSrId)){
			PGC_SandboxInitialisation.launchInitialisation(selectedSrId);
			load();
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM,'The loading has begun and will be completed soon.'));
		}else{
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error while import: unselected existing backup resource'));
		}
		return null;
	}

	@future
	public static void launchInitialisation(Id selectedSrId) {
		SavePoint sp = Database.setSavepoint();
		try {
			StaticResource sr = [SELECT Id, Name FROM StaticResource WHERE Id = :selectedSrId];
			F_SandboxInitialisation.initDataAndRunJob(sr.Name);
		} catch (Exception e) {
			UTIL.Log('Exception while loading data @ launch initialisation. Ex: ' + e.getStackTraceString());
			Database.rollback(sp);
		}
	}

	private void load() {
		this.availableStaticResources = F_SandboxInitialisation.getAvailableStaticResources();
	}
}