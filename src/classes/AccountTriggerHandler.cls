public with sharing class AccountTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        sendEmailToOwner(Trigger.new);
    }

    private void sendEmailToOwner(List<Account> accounts) {
        Map<Id, Id> userIdsByEntityIds = new Map<Id, Id>();
        for (Account account : accounts) {
            userIdsByEntityIds.put(account.Id, account.OwnerId);
        }
        EmailHelper.sendEmailToUsers(userIdsByEntityIds, EmailHelper.ACCOUNT_UPDATED_TEMPLATE);
    }
}