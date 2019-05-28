public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        sendEmailToOwner(Trigger.new);
    }

    private void sendEmailToOwner(List<Opportunity> opportunities) {
        Map<Id, Id> userIdsByEntityIds = new Map<Id, Id>();
        for (Opportunity opportunity : opportunities) {
            userIdsByEntityIds.put(opportunity.Id, opportunity.OwnerId);
        }
        EmailHelper.sendEmailToUsers(userIdsByEntityIds, EmailHelper.OPPORTUNITY_UPDATED_TEMPLATE);
    }
}