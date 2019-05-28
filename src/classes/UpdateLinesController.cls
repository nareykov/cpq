public class UpdateLinesController {
    public class FieldWrapper {
        public Schema.FieldSetMember field { get; set; }
        public Boolean active { get; set; }

        public FieldWrapper() {
            this.active = false;
        }

        public FieldWrapper(Schema.FieldSetMember field) {
            this();
            this.field = field;
        }
    }

    public class SubscriptionWrapper {
        public QuoteLineItem subscription { get; set; }
        public Boolean active { get; set; }

        public SubscriptionWrapper() {
            this.active = false;
        }

        public SubscriptionWrapper(QuoteLineItem subscription) {
            this();
            this.subscription = subscription;
        }
    }

    public List<FieldWrapper> fieldWrappers { get; set; }
    public List<SubscriptionWrapper> subscriptionWrappers { get; set; }
    public QuoteLineItem subscription { get; set; }
    public Quote quote { get; set; }
    public Boolean selectAllFields { get; set; }
    public Boolean selectAllSubscriptions { get; set; }
    public Boolean validationError { get; set; }
    public Boolean saveError { get; set; }

    private static final String WARNING_MESSAGE = 'You have not entered a value to update.  Do you wish to update the selected subscription lines with a blank value?';

    public UpdateLinesController() {
        this.subscription = new QuoteLineItem();
        this.fieldWrappers = new List<FieldWrapper>();
        System.debug(getFields());
        for (Schema.FieldSetMember field : getFields()) {
            fieldWrappers.add(new FieldWrapper(field));
        }
        this.subscriptionWrappers = new List<SubscriptionWrapper>();
        this.quote = getquoteById(ApexPages.currentPage().getParameters().get('Id'));
        for (QuoteLineItem subscription : quote.QuoteLineItems) {
            subscriptionWrappers.add(new SubscriptionWrapper(subscription));
        }
        this.validationError = false;
        this.saveError = false;
    }

    public List<Schema.FieldSetMember> getFields() {
        return SObjectType.QuoteLineItem.FieldSets.Update_Lines.getFields();
    }

    public void checkSelectAllFields() {
        for (FieldWrapper fieldWrapper : fieldWrappers) {
            fieldWrapper.active = selectAllFields;
        }
    }

    public void checkSelectAllSubscriptions() {
        for (SubscriptionWrapper subscriptionWrapper : subscriptionWrappers) {
            subscriptionWrapper.active = selectAllSubscriptions;
        }
    }

    public PageReference validateAndSave() {
        saveError = false;
        validateFieldWrappers(fieldWrappers);
        if (!validationError) {
            return save();
        }
        return null;
    }

    public void refresh() { //method used as action to refresh page
    }

    public PageReference save() {
        validationError = false;
        if ( saveSubscriptions(subscriptionWrappers) ) {
            return new PageReference('/' + quote.Id);
        }
        return null;
    }

    public PageReference cancel() {
        validationError = false;
        return new PageReference('/' + quote.Id);
    }

    public void resetValidationError() {
        validationError = false;
    }

    private Boolean saveSubscriptions(List<SubscriptionWrapper> subscriptionWrappers) {
        List<QuoteLineItem> subscriptionsToUpdate = new List<QuoteLineItem>();
        for (SubscriptionWrapper subscriptionWrapper : subscriptionWrappers) {
            if (subscriptionWrapper.active) {
                QuoteLineItem updatedSubscription = cloneSubscriptionWithSelectedFields(subscription, fieldWrappers);
                updatedSubscription.Id = subscriptionWrapper.subscription.Id;
                subscriptionsToUpdate.add(updatedSubscription);
            }
        }
        saveError = false;
        Savepoint sp = Database.setSavepoint();
        List<Database.SaveResult> updateResults = Database.update(subscriptionsToUpdate, false);
        String errorMessage = '';
        for ( Database.SaveResult updateResult : updateResults ) {
            if ( !updateResult.isSuccess()) {
                saveError = true;
                if ( !updateResult.getErrors()[0].getMessage().containsIgnoreCase('validation_exception') ) {
                    errorMessage += updateResult.getErrors()[0].getMessage();
                }
                break;
            }
        }
        if ( String.isNotBlank(errorMessage) ) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
        }
        if ( saveError ) {
            Database.rollback(sp);
        }
        return !saveError;
    }

    private QuoteLineItem cloneSubscriptionWithSelectedFields(QuoteLineItem subscription, List<FieldWrapper> fieldWrappers) {
        QuoteLineItem newSubscription = new QuoteLineItem();
        for (FieldWrapper fieldWrapper : fieldWrappers) {
            if (fieldWrapper.active) {
                String fieldName = fieldWrapper.field.fieldPath;
                newSubscription.put(fieldName, subscription.get(fieldName));
            }
        }
        return newSubscription;
    }

    private void validateFieldWrappers(List<FieldWrapper> fieldWrappers) {
        for (FieldWrapper fieldWrapper : fieldWrappers) {
            if (!isFieldWrapperValid(fieldWrapper)) {
                validationError = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, WARNING_MESSAGE));
                break;
            }
        }
    }

    private Boolean isFieldWrapperValid(FieldWrapper fieldWrapper) {
        return !fieldWrapper.active || subscription.get(fieldWrapper.field.fieldPath) != null;
    }

    private Quote getQuoteById(Id quoteId) {
        return [SELECT Id, (SELECT Id, Discount, ListPrice,
                Description, UnitPrice, TotalPrice, Quantity
        FROM QuoteLineItems) FROM Quote WHERE Id = :quoteId];
    }
}