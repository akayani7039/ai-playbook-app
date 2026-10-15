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

- Ships with S1 and S2 in release/2026.10.
- Builds on BR014-S1 and BR014-S2 (both in `develop`): S3 saves the result of the S2 check.

## Components changed

| Component                         | Type                  | Change                                                                           |
| --------------------------------- | --------------------- | -------------------------------------------------------------------------------- |
| `Lead.Eligibility_Result__c`      | Custom field          | New: restricted picklist (Eligible, Not eligible), history tracked               |
| `Lead.Eligibility_Reasons__c`     | Custom field          | New: restricted multi-select picklist of the 9 S1 reasons, history tracked       |
| `Lead.Eligibility_Checked_By__c`  | Custom field          | New: lookup to User, history tracked                                             |
| `Lead.Eligibility_Checked_On__c`  | Custom field          | New: date/time, history tracked                                                  |
| `Lead`                            | Object settings       | Changed: field history turned on                                                 |
| `LeadEligibilityRecorder`         | Apex class            | New: saves the outcome on each lead in one save (approved system-mode exception) |
| `LeadEligibilityRecorderTest`     | Apex test class       | New: 12 tests, AC 1–6, 200 leads                                                 |
| `LeadEligibilityController`       | Apex class            | Changed: every check saves its outcome; a failed save gets a clear message       |
| `LeadEligibilityControllerTest`   | Apex test class       | Changed: 2 new tests (outcome saved, failed save message)                        |
| `leadEligibilityCheck`            | LWC                   | Changed: refreshes the lead page after a check; 2 new Jest tests                 |
| `Sales_Rep_Base`                  | Permission set        | Changed: read-only access to the 4 fields                                        |
| `Admin`                           | Profile               | New in repo: read-only access to the 4 fields                                    |
| `Lead-Lead Layout`                | Page layout           | Changed: "Eligibility" section (read only) and the Lead History related list     |
| `tests/ui/story/BR014-S3.spec.ts` | Playwright story test | New: 2 tests, AC 1–3, 5, 6                                                       |
