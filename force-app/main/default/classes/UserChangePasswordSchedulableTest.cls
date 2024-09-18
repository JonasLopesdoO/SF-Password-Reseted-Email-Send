@IsTest
private class UserChangePasswordSchedulableTest {
    @IsTest
    static void testSchedulingTheJob() {
        SetupData setup = new SetupData();
        setup.createNewPortalUser();
        
        System.runAs(setup.testUser) {
            Test.startTest();
            
            String CRON_EXP = '0 0 0 3 9 ? 2042';
            String jobId = System.schedule('Portal User Password Changed Process Test', CRON_EXP, new UserChangePasswordSchedulable());
            
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                              FROM CronTrigger WHERE id = :jobId];
            
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            
            System.assertEquals('2042-09-03 00:00:00', String.valueOf(ct.NextFireTime));
            Test.stopTest();
        }
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