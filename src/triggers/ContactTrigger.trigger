trigger ContactTrigger on Contact (before insert, after update) {
    new ContactTriggerHandler().run();
}