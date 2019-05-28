trigger ContractTrigger on Contract (before insert, after update) {
    new ContractTriggerHandler().run();
}