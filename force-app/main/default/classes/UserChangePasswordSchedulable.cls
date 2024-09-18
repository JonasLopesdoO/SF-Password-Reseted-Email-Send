public class UserChangePasswordSchedulable implements Schedulable {   
    List<User> usersToUpdate = new List<User>();
    
    public void execute(SchedulableContext context) {
        getChangedPasswordUsers();
        sendEmailToTheUsers();
        Integer minutes = Integer.valueOf([SELECT Value__c FROM BT_CheckPasswordChange__c]?.Value__c) ?? 5;
        rescheduleJob(minutes);
    }
    
    private void getChangedPasswordUsers() {
        List<User> usersToCheck = [SELECT Id, LastPasswordChangeDate, LastPasswordChangeDate__c 
                                   FROM User WHERE Profile.Name = 'Portal Community Plus Login' AND IsActive = true];
        
        List<User> userFirstTimeCheck = new List<User>();

        for (User u : usersToCheck) {
            if (u.LastPasswordChangeDate > u.LastPasswordChangeDate__c) {
                u.LastPasswordChangeDate__c = u.LastPasswordChangeDate;
                usersToUpdate.add(u);
            } else if (u.LastPasswordChangeDate__c == null) {
                u.LastPasswordChangeDate__c = u.LastPasswordChangeDate;
                userFirstTimeCheck.add(u);
            }
        }
        
        if (usersToUpdate.size() > 0) update usersToUpdate;
        if (userFirstTimeCheck.size() > 0) update userFirstTimeCheck;
    }
    
    private void sendEmailToTheUsers() {
        EmailTemplate template = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Portal_Changed_password'];

        List<Messaging.SingleEmailMessage> emails = EmailService.CreateEmails(false, usersToUpdate, null, null, template.Id, null);
        if (emails.size() > 0) EmailService.SendEmails(emails);
    }
    
    private void rescheduleJob(Integer minutes) {
        // If job currently scheduled remove it
        List<CronTrigger> schJobs = [SELECT Id FROM CronTrigger where CronJobDetail.Name LIKE '%Portal User Password Changed Process%'];
        String myJobID;
        
        if (schJobs.size() > 0) {
            myJobID = schJobs[0].Id;
            System.abortjob(myJobID); 
        }
        
        DateTime calculateDateTime = DateTime.now();  
        DateTime newDateTime = calculateDateTime.addMinutes(minutes); // Reschedule job in passed minutes from time job finishes
        Integer min = newDateTime.minute();
        String sch = '0 ' + String.valueOf(min) + ' * * * ? ';
        System.schedule('Portal User Password Changed Process', sch, new UserChangePasswordSchedulable());  
    }
}