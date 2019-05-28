public with sharing class ContractTriggerHandler extends TriggerHandler {
    protected override void afterUpdate() {
        sendEmailToOwner(Trigger.new);
    }

    private void sendEmailToOwner(List<Contract> contracts) {
        Map<Id, Id> userIdsByEntityIds = new Map<Id, Id>();
        for (Contract contract : contracts) {
            userIdsByEntityIds.put(contract.Id, contract.OwnerId);
        }
        EmailHelper.sendEmailToUsers(userIdsByEntityIds, EmailHelper.CONTRACT_UPDATED_TEMPLATE);
    }
}