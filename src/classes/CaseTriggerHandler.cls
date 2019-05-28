public with sharing class CaseTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        sendEmailToOwner(Trigger.new);
    }

    private void sendEmailToOwner(List<Case> cases) {
        Map<Id, Id> userIdsByEntityIds = new Map<Id, Id>();
        for (Case theCase : cases) {
            userIdsByEntityIds.put(theCase.Id, theCase.OwnerId);
        }
        EmailHelper.sendEmailToUsers(userIdsByEntityIds, EmailHelper.CASE_UPDATED_TEMPLATE);
    }
}