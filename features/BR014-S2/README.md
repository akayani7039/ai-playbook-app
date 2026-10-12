# BR014-S2: Eligibility on demand

- **Jira:** [SCRUM-7](https://asadkayani10-1791505782400.atlassian.net/browse/SCRUM-7)
- **Epic:** BR-014 Quick Eligibility Check ([SCRUM-5](https://asadkayani10-1791505782400.atlassian.net/browse/SCRUM-5))
- **Branch:** feature/BR014-S2
- **Dev org:** playbook-dev

## Story

As a sales rep, I need to check a lead's eligibility while I work on it, so I can decide quickly whether to pursue it.

Uses the eligibility rules (R1 to R5) defined in BR014-S1.

## Acceptance criteria

1. On the lead record page, a rep can run an eligibility check with one click.
2. The result shows **Eligible** or **Not eligible**.
3. A Not eligible result lists every failed rule and any missing details, in plain words.
4. The result matches the BR014-S1 decision for the same lead data.
5. If the rep changes lead details and checks again, the result uses the latest saved values.
6. The result appears within 2 seconds.
7. If the check can't run (for example, the rep can't see a needed field), the rep sees a clear message instead of a system error.
8. Reps with the Sales Rep Base permission set can run the check.

## Notes

Depends on BR014-S1. Ships with S1 and S3 in release/2026.10.

## Components changed

| Component                        | Type                  | Change                                                                                          |
| -------------------------------- | --------------------- | ----------------------------------------------------------------------------------------------- |
| `LeadEligibilityController`      | Apex class            | New: `checkEligibility(leadId)` loads the lead `WITH USER_MODE` and returns the S1 result       |
| `LeadEligibilityControllerTest`  | Apex test class       | New: 8 tests for AC 2, 3, 4, 5, 7 and 8                                                         |
| `leadEligibilityCheck`           | LWC                   | New: "Eligibility check" card with a "Check eligibility" button, outcome badge and reasons list |
| `leadEligibilityCheck.test.js`   | Jest test             | New: 5 tests for AC 1, 2, 3 and 7                                                               |
| `Sales_Rep_Base`                 | Permission set        | Changed: class access to `LeadEligibilityController`; read-only `Lead.Address`                  |
| `Lead_Record_Page`               | FlexiPage             | Changed: `leadEligibilityCheck` added to the sidebar, under `leadProfileCard`                   |
| `lead-eligibility-check.spec.ts` | Playwright story test | New: Acme Robotics (Eligible within 2 s) and Pine County Services (Not eligible, both reasons)  |
