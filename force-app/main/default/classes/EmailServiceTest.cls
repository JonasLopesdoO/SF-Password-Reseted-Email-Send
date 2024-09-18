@IsTest
private class EmailServiceTest {
    @IsTest
    static void testSendMultipleEmails() {
        SetupData setup = new SetupData();
        setup.createNewPortalUser();
        
        System.runAs(setup.testUser) {
            List<User> usersToCheck = [SELECT Id FROM User WHERE Profile.Name = 'Portal Community Plus Login' AND IsActive = true];
            EmailTemplate template = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Portal_Changed_password'];
            List<Messaging.SingleEmailMessage> emails = EmailService.CreateEmails(false, usersToCheck, null, null, template.Id, null);
            
            Test.startTest();
            EmailService.SendEmails(emails);
            Integer invocations = Limits.getEmailInvocations();
            Test.stopTest();

            System.assertEquals(1, invocations, 'An email has not been sent');
        }
    }

    @IsTest
    static void testSendSingleEmail() {
        SetupData setup = new SetupData();
        setup.createNewPortalUser();
        
        System.runAs(setup.testUser) {
            List<User> usersToCheck = [SELECT Id FROM User WHERE Profile.Name = 'Portal Community Plus Login' AND IsActive = true];
            EmailTemplate template = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Portal_Changed_password'];
            List<Messaging.SingleEmailMessage> emails = EmailService.CreateEmails(true, usersToCheck, null, null, template.Id, null);
            
            Test.startTest();
            EmailService.SendEmails(emails);
            Integer invocations = Limits.getEmailInvocations();
            Test.stopTest();

            System.assertEquals(1, invocations, 'An email has not been sent');
        }
    }

    @IsTest
	static void testGetAllOweaIdsMapCoverage() {
		Test.startTest();
		Map<String, Id> mapResult = EmailService.GetAllOweaIdsMap();
		Id idResult = EmailService.GetAllOweaIdsByEmail('someemail@someDomainTest12344321.com');
        Test.stopTest();
        
        Assert.isNull(idResult);
		Assert.isNotNull(mapResult);
	}

    @IsTest
	static void testValidations() {
        SetupData setup = new SetupData();
        setup.createNewPortalUser();

        System.runAs(setup.testUser) {
            List<User> usersToCheck = [SELECT Id FROM User WHERE Profile.Name = 'Portal Community Plus Login' AND IsActive = true];
            EmailTemplate template = [SELECT Id, Subject, Body FROM EmailTemplate LIMIT 1];
            List<Messaging.SingleEmailMessage> emails = EmailService.CreateEmails(false, usersToCheck, null, null, template.Id, null);
            System.debug('>>> emails' + emails.size());
            List<Messaging.EmailFileAttachment> attachment = new List<Messaging.EmailFileAttachment>{
                createAttachment(Blob.valueOf('some content'), 'someContent')
            };

            Test.startTest();
            Boolean isValidEmailAttachment = EmailService.IsValidEmailAttachmentSize(attachment, EmailService.AttachmentSize25MB);
            Boolean isValidEmailListSize = EmailService.IsValidEmailListSize(emails);
            Boolean isInValidEmailListSize = EmailService.IsValidEmailListSize(new List<Messaging.SingleEmailMessage>());
            Boolean isValidEmailTemplate = EmailService.IsValidEmailTemplate(template.Id);
            Test.stopTest();

            Assert.isTrue(isValidEmailAttachment);
            Assert.isTrue(isValidEmailListSize);
            Assert.isFalse(isInValidEmailListSize);
            Assert.isTrue(isValidEmailTemplate);
        }
	}

    @IsTest
	static void testConstructors() {
		Test.startTest();
		EmailService.EmailBuilder builderWithNoAttachments = new EmailService.EmailBuilder(null, null, null, null, null, null, null, null);
		EmailService.EmailBuilder builderWithNoCCNeitherAttachments = new EmailService.EmailBuilder(null, null, null, null, null, null);
        Test.stopTest();
	}

    private static Messaging.EmailFileAttachment createAttachment(Blob content, String name) {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(name);
        attachment.setBody(content);
        return attachment;
    }
    
    
    private class SetupData {
        private User testUser;
        private Contact testContact;
        private final String COMMUNITY_PROFILE = 'Portal Community Plus Login';
        private final String LANGUAGE_LOCALE_KEY = 'en_US';
        private final String LOCALE = 'en_US';
        private final String UNITED_STATES = 'United States';       
        private final String GMT = 'GMT';        
        private final String UTF = 'UTF-8';
        
        public void createNewPortalUser() {
            List<User> users = new List<User>();
            List<Account> newAccounts = createNewAccount(1, true);
            this.testUser = createNewPortalUser(COMMUNITY_PROFILE, newAccounts, true)[0];
        }
        
        public List<Account> createNewAccount(Integer quantity, Boolean insertRecord) {
            List<Account> accounts = new List<Account>();
            RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'IndustriesBusiness' AND SobjectType = 'Account'];
            for(Integer i = 0; i < quantity; i++) {
                Account newAccount = new Account(Name='Account Test Name' + i, RecordTypeId=rt.Id);
                accounts.add(newAccount);            
            }
            if(insertRecord) {
                insert accounts;
            }
            return accounts;
        }
        
        public List<User> createNewPortalUser(String profileName, Account[] accounts, Boolean insertRecord) {
            List<User> users = new List<User>();
            Integer quantity = accounts.size();
            List<Contact> newContacts = createNewContact(quantity, accounts, true);
            Id profileId = [SELECT Id FROM Profile WHERE Name = :profileName].Id;
            String uniqueName = generateUniqueName();
            
            for(Integer i = 0; i < quantity; i++){
                User newUser = new User();
                newUser.ProfileID = profileId;
                newUser.EmailEncodingKey = 'ISO-8859-1';
                newUser.LanguageLocaleKey = 'en_US';
                newUser.TimeZoneSidKey = 'America/New_York';
                newUser.LocaleSidKey = 'en_US';
                newUser.FirstName = 'PortalUserFirst' + i;
                newUser.LastName = 'PortalUserLast' + i;
                newUser.Username = 'test@appirio.com';   
                newUser.CommunityNickname = 'testUser' + i;
                newUser.Alias = 'test' + i;
                newUser.Email = uniqueName + '@testorg.com' + i;
                newUser.UserName = uniqueName + '@test.com' + i;
                newUser.IsActive = true;
                newUser.ContactId = newContacts.get(i).Id;
                newUser.PortalRole = 'Worker';
                users.add(newUser);
            }
            
            if(insertRecord) {
                insert users;
            }
            return users;
        }
        
        public List<Contact> createNewContact(Integer quantity, List<Account> accounts, Boolean insertRecord) {
            List<Contact> contacts = new List<Contact>();
            for(Integer i = 0; i < quantity; i++) {
                String uniqueName = generateUniqueName();
                Contact newContact =  new Contact(
                    LastName = 'Test Contact Last Name' + i,
                    AccountId = accounts.get(i).Id,
                    Email = uniqueName + '@testcontact.com',
                    Phone = '0123456789'
                );
                contacts.add(newContact);
            }
            if(insertRecord) {
                insert contacts;
            }
            return contacts;
        }
        
        public String generateUniqueName() {
            String orgId = UserInfo.getOrganizationId();
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            Integer randomInt = Integer.valueOf(Math.rint(math.random()*1000000));
            return randomInt + orgId + dateString;
        }
    }
}