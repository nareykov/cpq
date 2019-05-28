public class PricingDocumentController {

    public Quote quote { get; set; }
    public List<QuoteLineItem> lineItems { get; set; }

    public PricingDocumentController() {
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('id');
        quote = DocumentGenerationHelper.getQuoteDetails(quoteId);
        lineItems = DocumentGenerationHelper.getQuoteLines(quoteId);
    }
}