public with sharing class ContactTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        sendEmailToOwner(Trigger.new);
    }

    private void sendEmailToOwner(List<Contact> contacts) {
        Map<Id, Id> userIdsByEntityIds = new Map<Id, Id>();
        for (Contact contact : contacts) {
            userIdsByEntityIds.put(contact.Id, contact.OwnerId);
        }
        EmailHelper.sendEmailToUsers(userIdsByEntityIds, EmailHelper.CONTACT_UPDATED_TEMPLATE);
    }
}