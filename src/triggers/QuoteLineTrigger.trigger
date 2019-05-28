trigger QuoteLineTrigger on QuoteLineItem (before insert, after update) {
    new QuoteLineTriggerHandler().run();
}