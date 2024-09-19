
# Send email after password set

Hi everyone, recently I had a tricky requirement to solve in Salesforce Experience Cloud. I was preparing this material some time ago and wanted to share here for who can benefit from it.  

## Requirement:
Send an email everytime the user finishes reseting the password in an experience cloud portal site
Problem: Salesforce doesn't trigger an event by password set up, only when the reset password form is filled.

The `LastPasswordChangeDate` field doesn't fire apex triggers, record triggered flows  or platform events with detailed payload in case they exist.

## Restrictions: 
Salesforce only sends email when the user asks to reset password in the reset password page.

The field `LastPasswordChangeDate` can not be used to trigger a flow, platform event or apex trigger as well as some other standard fields like `LastLoginDate` so we can not rely on this standard field to fire some process to send the email.

## Solution: 
The solution involves Scheduled Jobs, Custom Field, Email Template and Custom Settings
- Create a new custom field to mimic the standard `LastPasswordChangeDate` in the User object so we can rely on it to compare the last changed password date. For instance I used the same name [LastPasswordChangeDate__c](https://github.com/JonasLopesdoO/SF-Password-Reseted-Email-Send/blob/main/force-app/main/default/objects/User/fields/LastPasswordChangeDate__c.field-meta.xml)
- Create a new email template to inform the user that his password was correctly set up. [Portal_Changed_password](https://github.com/JonasLopesdoO/SF-Password-Reseted-Email-Send/blob/main/force-app/main/default/email/unfiled%24public/Portal_Changed_password.email)
- Create an apex scheduler class that will runs from every **n** minutes to check if the password was changed from the latest n minutes to now. [UserChangePasswordSchedulable](https://github.com/JonasLopesdoO/SF-Password-Reseted-Email-Send/blob/main/force-app/main/default/classes/UserChangePasswordSchedulable.cls)
- Create a Custom Setting to store this **n** minutes so it can be changed manually later by a salesforce admin. [BT_CheckPasswordChange__c](https://github.com/JonasLopesdoO/SF-Password-Reseted-Email-Send/tree/main/force-app/main/default/objects/BT_CheckPasswordChange__c)

## Explanation
If the new field is null in the first execution, set it to be the same value as the current `LastPasswordChangeDate`
If the standard `LastPasswordChangeDate` field is bigger than the new custom field, it means the password was changed, so we can send the email

After that we set the new field to have the same value of the standard field, so it will fire only once as needed.

Abort the job and reschedule itself to run in the next n minutes, so you will always have only one instance of the pending job to run and not hit the 100 queued jobs limit. 

Doing this way we avoid filling the jobs pending queue which has a small limit compared if we are setting all the jobs needed to run throughout the day. 


---
> ℹ️ **_TIP:_**  As this is a really fast and small consuming process, you can put it to run every minute or every two minutes. I did that and had no blockers. Since the only record that will be locked is the user record that changed the password in the latest minute. For more complex and demanding processes I recommend separating the job in less frequent executions or separate into two different jobs.
---

### Considerations:
Problem with the approach:
If the user goes fast and set his password as soon as the email arrives and complete the password setup before the time set, he will probably not receive the confirmation password email, because the new field will be first set from null to the `LastPasswordChangeDate`, then to the new changed password date. This is an edge case and to decrease the chance from this to happen we can set the job to run every minute.
Additional checks and approachs could be done to avoid this problem, but it was not done in this example due to the restriction of the requirement itself.
