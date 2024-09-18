public without sharing class EmailService {
    public static final String AttachmentSize25MB = '25MB';
    public static final String AttachmentSize3MB = '3MB';
    private static final Map<String, Long> EMAIL_STRING_TO_LONG = new Map<String, Long> {
		AttachmentSize3MB => 3145728,
		AttachmentSize25MB => 26214400
	};
    @TestVisible
    public static Map<String, Id> GetAllOweaIdsMapCache;

    public static Map<String, Id> GetAllOweaIdsMap() {
        if (GetAllOweaIdsMapCache == null) {
            GetAllOweaIdsMapCache = new Map<String, Id>();

            List<OrgWideEmailAddress> oweas = [SELECT Id, Address FROM OrgWideEmailAddress];
            
            for (OrgWideEmailAddress owea : oweas) {
                GetAllOweaIdsMapCache.put(owea.Address, owea.Id);
            }
        }

        return GetAllOweaIdsMapCache;
    }

    public static Id GetAllOweaIdsByEmail(String email) {
        return EmailService.GetAllOweaIdsMap().get(email);
    }

    public static String GetOweaNameByEmail(String email) {
        return [SELECT DisplayName FROM OrgWideEmailAddress WHERE Address = :email]?.DisplayName;
    }

    public static List<Messaging.SingleEmailMessage> CreateEmails(Boolean sendSingleEmail, List<User> usersToSendEmail, Id whatId, Id oweaId, Id emailTemplateId, List<Messaging.EmailFileAttachment> emailFileAttachments) {        
        if (sendSingleEmail) {
            return createSingleEmail(usersToSendEmail[0].Id, whatId, oweaId, emailTemplateId, null, null, emailFileAttachments);
        } else {
            return createMultipleEmails(usersToSendEmail, whatId, oweaId, emailTemplateId, null, null, emailFileAttachments);
        }
    }

    private static List<Messaging.SingleEmailMessage> createSingleEmail(Id targetObjectId, Id whatId, Id oweaId, Id emailTemplateId, List<String> toAddresses, List<String> ccAddresses, List<Messaging.EmailFileAttachment> emailFileAttachments) {
        EmailBuilder emailBuilder = new EmailBuilder(AttachmentSize25MB, targetObjectId, whatId, oweaId, emailTemplateId,
                                                     false, toAddresses, ccAddresses, emailFileAttachments);
        createEmail(emailBuilder);
        
        return new List<Messaging.SingleEmailMessage>{emailBuilder.email};
    }

    private static List<Messaging.SingleEmailMessage> createMultipleEmails(List<User> usersToSendEmail, Id whatId, Id oweaId, Id emailTemplateId, List<String> toAddresses, List<String> ccAddresses, List<Messaging.EmailFileAttachment> emailFileAttachments) {
        List<String> allEmailRecipientsIds = getAllEmailRecipientIds(usersToSendEmail);
        List<Messaging.SingleEmailMessage> emails = decorateAllEmails(allEmailRecipientsIds, whatId, oweaId, emailTemplateId, null, null, emailFileAttachments);
     
        return emails;
    }

    private static List<String> getAllEmailRecipientIds(List<User> usersToSendEmail) {
        List<String> allEmailRecipientsIds = new List<Id>();

        for (User u : usersToSendEmail) {
            allEmailRecipientsIds.add(u.Id);
        }

        return allEmailRecipientsIds;
    }
    
    private static List<Messaging.SingleEmailMessage> decorateAllEmails(List<String> allEmailRecipientsIds, Id whatId, Id oweaId, Id emailTemplateId, List<String> toAddresses, 
                                                                        List<String> ccAddresses, List<Messaging.EmailFileAttachment> emailFileAttachments) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (String recipient : allEmailRecipientsIds) {
            EmailBuilder emailBuilder = new EmailBuilder(AttachmentSize25MB, recipient, whatId, oweaId, emailTemplateId, false, null, null, emailFileAttachments);
            createEmail(emailBuilder);
            emails.add(emailBuilder.email);
        }
        
        return emails;
    }
    
    private static Messaging.SingleEmailMessage createEmail(EmailBuilder emailBuilder) {		
        decorateEmail(emailBuilder, emailBuilder.attachments != null);

        return emailBuilder.email;
    }

    private static void decorateEmail(EmailBuilder emailBuilder, Boolean hasAttachments) {
        emailBuilder.email = new Messaging.SingleEmailMessage();

        if (hasAttachments && String.isNotBlank(emailBuilder.sizeMB)) {
            IsValidEmailAttachmentSize(emailBuilder.attachments, emailBuilder.sizeMb);
            emailBuilder.email.setFileAttachments(emailBuilder.attachments);
        }
        
        decorateEmail(emailBuilder);
    }

    private static void decorateEmail(EmailBuilder emailBuilder) {
        emailBuilder.email.setTargetObjectId(emailBuilder.targetObjectId);
        emailBuilder.email.setWhatId(emailBuilder.whatId);
        emailBuilder.email.setTemplateId(emailBuilder.emailTemplateId);
        emailBuilder.email.setSaveAsActivity(emailBuilder.saveAsActivity);
        if (emailBuilder.toAddresses != null && emailBuilder.toAddresses.size() > 0) emailBuilder.email.setToAddresses(emailBuilder.toAddresses);
        if (emailBuilder.ccAddresses != null && emailBuilder.ccAddresses.size() > 0) emailBuilder.email.setCcAddresses(emailBuilder.ccAddresses);
        if (String.isNotBlank(emailBuilder.oweaId)) emailBuilder.email.setOrgWideEmailAddressId(emailBuilder.oweaId);

    }

    public static void SendEmails(List<Messaging.SingleEmailMessage> emails) {
        try {
            Messaging.sendEmail(emails);
        } catch (Exception e) {
            System.debug(e);
        }
    }

    public static Boolean IsValidEmailAttachmentSize(List<Messaging.EmailFileAttachment> attachments, String sizeMb) {
        Long emailSize = 0;
        Long maxEmailAttachmentSize = EMAIL_STRING_TO_LONG.get(sizeMb); 

        for (Messaging.EmailFileAttachment att : attachments) {
            emailSize += att.getBody().size();
        }

        Boolean isSizeValid = emailSize < maxEmailAttachmentSize;

        return isSizeValid;
    }
    
    public static Boolean IsValidEmailListSize(List<Messaging.SingleEmailMessage> emails) {
        return emails.isEmpty() == false;
    }

    public static Boolean IsValidEmailTemplate(String emailTemplateId) {
        return String.isNotBlank(emailTemplateId);
    }

    public class EmailBuilder {
        public Messaging.SingleEmailMessage email {get; private set;}
        public String sizeMb {get; private set;}
        public Id targetObjectId {get; private set;}
        public Id whatId {get; private set;}
        public Id emailTemplateId {get; private set;}
        public Id oweaId {get; private set;}
        public Boolean saveAsActivity {get; private set;}
        public List<String> toAddresses {get; private set;}
        public List<String> ccAddresses {get; private set;}
        public List<Messaging.EmailFileAttachment> attachments {get; private set;}
        
        public EmailBuilder(String sizeMb, Id targetObjectId, Id whatId, Id oweaId, Id emailTemplateId, Boolean saveAsActivity, 
                            List<String> toAddresses, List<String> ccAddresses, List<Messaging.EmailFileAttachment> attachments) {
            this.sizeMb = sizeMb;
            this.targetObjectId = targetObjectId;
            this.whatId = whatId;
            this.emailTemplateId = emailTemplateId;
            this.oweaId = oweaId;
            this.saveAsActivity = saveAsActivity ?? true;
            this.toAddresses = toAddresses;
            this.ccAddresses = ccAddresses;
            this.attachments = attachments;
        }

        public EmailBuilder(String sizeMb, Id targetObjectId, Id whatId, Id oweaId, Id emailTemplateId, Boolean saveAsActivity, 
                            List<String> toAddresses, List<String> ccAddresses) {
            this.sizeMb = sizeMb;
            this.targetObjectId = targetObjectId;
            this.whatId = whatId;
            this.emailTemplateId = emailTemplateId;
            this.oweaId = oweaId;
            this.saveAsActivity = saveAsActivity ?? true;
            this.toAddresses = toAddresses;
            this.ccAddresses = ccAddresses;
        }
        
        public EmailBuilder(String sizeMb, Id targetObjectId, Id whatId, Id oweaId, Id emailTemplateId, Boolean saveAsActivity) {
            this.sizeMb = sizeMb;
            this.targetObjectId = targetObjectId;
            this.whatId = whatId;
            this.oweaId = oweaId;
            this.emailTemplateId = emailTemplateId;
            this.saveAsActivity = saveAsActivity ?? true;
        }
    }
}