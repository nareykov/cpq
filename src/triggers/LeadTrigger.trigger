trigger LeadTrigger on Lead (after update) {
    new LeadTriggerHandler().run();
}