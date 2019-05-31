public with sharing class LeadTriggerHandler extends TriggerHandler{
    protected override void afterUpdate() {
        sendEmailToOwner(Trigger.new);
    }

    private void sendEmailToOwner(List<Lead> leads) {
        Map<Id, Id> userIdsByEntityIds = new Map<Id, Id>();
        for (Lead lead : leads) {
            userIdsByEntityIds.put(lead.Id, lead.OwnerId);
        }
        EmailHelper.sendEmailToUsers(userIdsByEntityIds, EmailHelper.OPPORTUNITY_UPDATED_TEMPLATE);
    }
}