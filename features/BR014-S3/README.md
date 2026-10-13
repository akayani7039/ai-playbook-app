# BR014-S3: Recorded eligibility outcome

- **Jira:** [SCRUM-8](https://asadkayani10-1791505782400.atlassian.net/browse/SCRUM-8)
- **Epic:** BR-014 Quick Eligibility Check ([SCRUM-5](https://asadkayani10-1791505782400.atlassian.net/browse/SCRUM-5))
- **Branch:** feature/BR014-S3
- **Dev org:** playbook-dev

## Story

As a sales manager, I need each result, its reasons and who checked it kept on the lead, so I can report on it and audit it.

## Acceptance criteria

1. Each eligibility check saves four things on the lead: the result, the reasons (failed rules and missing details), who ran the check, and when.
2. A new check replaces the saved outcome with the latest one.
3. Earlier outcomes stay available for audit through the lead's field history.
4. Managers can build reports on leads by result, reason, checked by and checked date.
5. Reps can see the saved outcome on the lead page but can't edit it by hand. Only a check can set it.
6. Changing lead details doesn't change the saved outcome until someone runs a new check.

## Notes

Depends on BR014-S1 and S2. Ships with S1 and S2 in release/2026.10.

## Components changed

| Component                                                                                                   | Type                  | Change                                                                                                                      |
| ----------------------------------------------------------------------------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `Eligibility_Result__c`, `Eligibility_Reasons__c`, `Eligibility_Checked_By__c`, `Eligibility_Checked_On__c` | Lead fields           | New: restricted picklist, restricted multi-select picklist (9 reason texts), lookup to User, date/time. All history tracked |
| `Lead`                                                                                                      | Object                | Changed: field history turned on                                                                                            |
| `LeadEligibilityRecorder`                                                                                   | Apex class            | New: saves the 4 fields in one DML, system mode, `with sharing` (approved FLS exception)                                    |
| `LeadEligibilityRecorderTest`                                                                               | Apex test class       | New: 12 tests for AC 1–6, the reason values and bulk                                                                        |
| `LeadEligibilityController`                                                                                 | Apex class            | Changed: saves the outcome after `evaluate`; clear message if the save fails                                                |
| `LeadEligibilityControllerTest`                                                                             | Apex test class       | Changed: 2 new tests (outcome saved; failed save)                                                                           |
| `leadEligibilityCheck` + Jest test                                                                          | LWC                   | Changed: refreshes the page's record data after a check; 2 new Jest tests                                                   |
| `Sales_Rep_Base`                                                                                            | Permission set        | Changed: read only on the 4 fields                                                                                          |
| `Admin`                                                                                                     | Profile               | Changed: read only on the 4 fields (plan row 12, added during the build)                                                    |
| `Lead-Lead Layout`                                                                                          | Layout                | Changed: "Eligibility" section (4 fields, read only) and Lead History related list                                          |
| `lead-eligibility-outcome.spec.ts`                                                                          | Playwright story test | New: saved outcome on the page; edit keeps it; new check replaces it; Lead History has both                                 |
