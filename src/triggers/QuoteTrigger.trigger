trigger QuoteTrigger on Quote (before insert, after update) {
    new QuoteTriggerHandler().run();
}