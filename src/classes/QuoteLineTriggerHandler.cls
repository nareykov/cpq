public with sharing class QuoteLineTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        sendEmailToOwner(Trigger.new);
    }

    private void sendEmailToOwner(List<QuoteLineItem> quoteLineItems) {
        Map<Id, Id> userIdsByEntityIds = new Map<Id, Id>();
        for (QuoteLineItem quoteLineItem : quoteLineItems) {
            userIdsByEntityIds.put(quoteLineItem.Id, quoteLineItem.CreatedById);
        }
        EmailHelper.sendEmailToUsers(userIdsByEntityIds, EmailHelper.QUOTELINEITEM_UPDATED_TEMPLATE);
    }
}