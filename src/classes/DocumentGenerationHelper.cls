public with sharing class DocumentGenerationHelper {

    public static List<QuoteLineItem> getQuoteLines(String quoteId) {
        return [SELECT Id, Product2Id, Quantity, ServiceDate, Discount, ListPrice, TotalPrice FROM QuoteLineItem WHERE QuoteId = :quoteId];
    }

    public static Quote getQuoteDetails(String quoteId) {
        try {
            return [
                    SELECT Id, Name, Email, GrandTotal, ContactId, ExpirationDate, LineItemCount
                    FROM Quote
                    WHERE id = :quoteId
            ];
        } catch (Exception exc) {
            String errorMsg = 'There was an error getting Quote. Exception Cause = ' +
                    exc.getCause() + ', Exception Message = ' + exc.getMessage();
            System.debug('=====> ' + errorMsg);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
        }

        return null;
    }
}
