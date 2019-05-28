public with sharing class QuoteTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        sendEmailToOwner(Trigger.new);
    }

    private void sendEmailToOwner(List<Quote> quotes) {
        Map<Id, Id> userIdsByEntityIds = new Map<Id, Id>();
        for (Quote quote : quotes) {
            userIdsByEntityIds.put(quote.Id, quote.OwnerId);
        }
        EmailHelper.sendEmailToUsers(userIdsByEntityIds, EmailHelper.QUOTE_UPDATED_TEMPLATE);
    }
}