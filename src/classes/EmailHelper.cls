public without sharing class EmailHelper {

    public class EmailTemplateException extends Exception {}

    public static final String ACCOUNT_UPDATED_TEMPLATE = 'Account_Updated';
    public static final String CASE_UPDATED_TEMPLATE = 'Case_Updated';
    public static final String CONTACT_UPDATED_TEMPLATE = 'Contact_Updated';
    public static final String CONTRACT_UPDATED_TEMPLATE = 'Contract_Updated';
    public static final String OPPORTUNITY_UPDATED_TEMPLATE = 'Opportunity_Updated';
    public static final String QUOTE_UPDATED_TEMPLATE = 'Quote_Updated';
    public static final String QUOTELINEITEM_UPDATED_TEMPLATE = 'QuoteLineItem_Updated';

    public static final String BRUNTWOOD_ORG_WIDE_EMAIL = 'no-reply@bruntwood.co.uk';
    public static final String EMAIL_ADDRESS_BOUNCED_ERROR = 'EMAIL_ADDRESS_BOUNCED';

    public static final String EMAIL_SENDING_UNKNOWN_ERROR_MSG = 'Error sending emails. Please contact an administrator';
    public static final String NOT_VALID_EMAILS_ERROR_MSG = 'Error sending emails. Make sure all contacts have valid emails.';
    public static final String EMAIL_TEMPLATE_NOT_FOUND_ERROR_MSG = 'Email template not found. DeveloperName: ';
    public static final String FF_EMAILS_DISABLED_ERROR_MSG = 'Finance emails sending is disabled - please contact your administrator';
    public static Boolean isFFEmailsDisabled;

    private static Map<String, Id> orgWideEmailsMap { get; set; }
    private static Map<String, Id> emailTemplatesMap { get; set; }
    static {
        emailTemplatesMap = new Map<String, Id>();
        orgWideEmailsMap = new Map<String, Id>();
    }

    @Future
    public static void sendEmailToUsers(Map<Id, Id> userIdByEntityId, String templateName) {
        generateAndSendEmailsToUsers(userIdByEntityId, templateName);
    }

    public static void generateAndSendEmailsToUsers(Map<Id, Id> userIdByEntityId, String templateName){
        Set<Id> usersIds = new Set<Id>(userIdByEntityId.values());
        Map<Id, Contact> contactsByUsersIds = makeTempContactsFromUsers(usersIds);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId = getEmailTemplateId(templateName);
        for (Id entityId : userIdByEntityId.keySet()) {
            Id contactId = contactsByUsersIds.get(userIdByEntityId.get(entityId)).Id;
            Messaging.SingleEmailMessage mail = generateEmailMessage(templateId, contactId, entityId);
            mails.add(mail);
        }
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mails);
        delete contactsByUsersIds.values();
    }

    public static void sendCanceledEmailToAttendees(Map<Id, Id> relationIdByEventId, String templateName) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId = getEmailTemplateId(templateName);
        Map<Id, Contact> contactsByUsersIds = makeTempContactsFromUsers(relationIdByEventId.keySet());
        Map<Id, Contact> contactInAttendees = new Map<Id, Contact>([SELECT Id, LastName, FirstName, Email FROM Contact WHERE Id IN :relationIdByEventId.keySet()]);
        contactInAttendees.putAll(contactsByUsersIds);
        for (Id item : relationIdByEventId.keySet()) {
            Id contactId = contactInAttendees.get(item).Id;
            String eventId = relationIdByEventId.get(item);
            Messaging.SingleEmailMessage mail = generateEmailMessage(templateId, contactId, eventId);
            mail.setToAddresses(new String[]{
                    item
            });
            mails.add(mail);
        }
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mails);
        delete contactsByUsersIds.values();
    }

    public static void sendEmailsToApprovers(Map<Id, List<ProcessInstanceWorkitem>> workItemsMappedByQuoteId, String templateName) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId = getEmailTemplateId(templateName);
        Set<Id> approversIds = new Set<Id>();
        for (Id quoteId : workItemsMappedByQuoteId.keySet()) {
            for (ProcessInstanceWorkitem workItem : workItemsMappedByQuoteId.get(quoteId)) {
                approversIds.add(workItem.OriginalActorId);
            }
        }
        Map<Id, Contact> contactsByApproverIds = makeTempContactsFromUsers(approversIds);
        for (Id quoteId : workItemsMappedByQuoteId.keySet()) {
            for (ProcessInstanceWorkitem workItem : workItemsMappedByQuoteId.get(quoteId)) {
                Contact cont = contactsByApproverIds.get(workItem.OriginalActorId);
                if (cont != null) {
                    Messaging.SingleEmailMessage mail = generateEmailMessage(templateId, cont.Id, quoteId);
                    mails.add(mail);
                }
            }
        }
        Messaging.sendEmail(mails);
        delete contactsByApproverIds.values();
    }

    private static Map<Id, Id> getOpportunityOwnerIdsByQuoteIds(Set<Id> quoteIds) {
        List<Quote> quotes = [SELECT Id, Opportunity.OwnerId FROM Quote WHERE Id IN :quoteIds];
        Map<Id, Id> opportunityOwnerIdsByQuoteIds = new Map<Id, Id>();
        for (Quote quote : quotes) {
            opportunityOwnerIdsByQuoteIds.put(quote.Id, quote.Opportunity.OwnerId);
        }
        return opportunityOwnerIdsByQuoteIds;
    }

    public static Messaging.SingleEmailMessage generateEmailMessage(Id templateId, Id targetId, Id whatId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(getOrgWideEmailId(BRUNTWOOD_ORG_WIDE_EMAIL));
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(targetId);
        mail.setSaveAsActivity(false);
        mail.setWhatId(whatId);
        return mail;
    }

    /**
     * DON'T FORGET TO DELETE GENERATED CONTACTS
     */
    private static Map<Id, Contact> makeTempContactsFromUsers(Set<Id> usersIds) {
        Database.DMLOptions dml = new Database.DMLOptions();
        //Ignore duplication rules for saving
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        List<User> users = [SELECT Id, Email, FirstName, LastName FROM User WHERE Id IN :usersIds];
        Map<Id, Contact> contactsByUsersIds = new Map<Id, Contact>();
        for (User tempUser : users) {
            Contact tempContact = new Contact(
                    Email = tempUser.Email,
                    FirstName = tempUser.FirstName,
                    LastName = tempUser.LastName,
                    Phone = '7788'); //Phone is defined to prevent duplication error
            contactsByUsersIds.put(tempUser.Id, tempContact);
        }
        Database.insert(contactsByUsersIds.values(), dml);
        return contactsByUsersIds;
    }

    public static Id getEmailTemplateId(String templateDeveloperName) {
        if (emailTemplatesMap.isEmpty()) {
            List<EmailTemplate> emailTemplates = [SELECT Id, Body, Subject, DeveloperName FROM EmailTemplate];
            for (EmailTemplate emailTemplate : emailTemplates) {
                emailTemplatesMap.put(emailTemplate.DeveloperName, emailTemplate.Id);
            }
        }

        if (emailTemplatesMap.get(templateDeveloperName) == null) {
            throw new EmailTemplateException(EMAIL_TEMPLATE_NOT_FOUND_ERROR_MSG + templateDeveloperName);
        } else {
            return emailTemplatesMap.get(templateDeveloperName);
        }
    }

    public static Id getOrgWideEmailId(String emailAddress) {
        if (orgWideEmailsMap.isEmpty()) {
            List<OrgWideEmailAddress> orgWideEmails = [SELECT Address FROM OrgWideEmailAddress];
            for (OrgWideEmailAddress orgWideEmail : orgWideEmails) {
                orgWideEmailsMap.put(orgWideEmail.Address, orgWideEmail.Id);
            }
        }
        return orgWideEmailsMap.get(emailAddress);
    }

    public static void assertFFEmailsEnabled() {
        if (isFFEmailsDisabled) {
            throw new AuraHandledException(EmailHelper.FF_EMAILS_DISABLED_ERROR_MSG);
        }
    }

    public static void handleEmailException(EmailException e) {
        AuraHandledException auraHandledException;
        if (e.getMessage().contains(EmailHelper.EMAIL_ADDRESS_BOUNCED_ERROR)) {
            auraHandledException = new AuraHandledException(EmailHelper.NOT_VALID_EMAILS_ERROR_MSG); // to handling in Lightning
            auraHandledException.setMessage(EmailHelper.NOT_VALID_EMAILS_ERROR_MSG);                 // to handling in other cases
        } else {
            auraHandledException = new AuraHandledException(EmailHelper.EMAIL_SENDING_UNKNOWN_ERROR_MSG);
            auraHandledException.setMessage(EmailHelper.EMAIL_SENDING_UNKNOWN_ERROR_MSG);
        }
        throw auraHandledException;
    }

    public static List<Messaging.SingleEmailMessage> getMailsWithAttachments(List<Messaging.SingleEmailMessage> mails,
            List<String> files, List<String> fileNames, List<String> documentIds) {

        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        String base64String;
        for (Integer i = 0; i < fileNames.size(); i++) {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            base64String = EncodingUtil.urlDecode(files[i], 'UTF-8');
            efa.setBody(EncodingUtil.base64Decode(base64String));
            efa.setFileName(fileNames[i]);
            fileAttachments.add(efa);
        }

        for (Messaging.SingleEmailMessage mail : mails) {
            if (!fileAttachments.isEmpty()) {
                List<Messaging.EmailFileAttachment> attachments = mail.getFileAttachments() != null ? mail.getFileAttachments() : new List<Messaging.EmailFileAttachment>();
                attachments.addAll(fileAttachments);
                mail.setFileAttachments(attachments);
            }
            if (!documentIds.isEmpty()) {
                List<String> attachments = mail.getEntityAttachments() != null ? mail.getEntityAttachments() : new List<String>();
                attachments.addAll(documentIds);
                mail.setEntityAttachments(attachments);
            }
        }

        return mails;
    }
}