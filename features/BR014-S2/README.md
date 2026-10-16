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

Depends on S1 (Consistent eligibility decision), which is now in develop. Ships with S1 and S3 in release/2026.10. S3 (Recorded eligibility outcome) builds on this story.

## Components changed

| Component                         | Type            | Change                                                                                        |
| --------------------------------- | --------------- | --------------------------------------------------------------------------------------------- |
| `LeadEligibilityController`       | Apex class      | New: runs the S1 check on the latest saved lead and returns a clear message when it can't run |
| `LeadEligibilityControllerTest`   | Apex test class | New: 8 tests covering AC 2–5, 7 and 8                                                         |
| `leadEligibilityCheck`            | LWC             | New: "Eligibility check" card with one button, the result and the reasons                     |
| `leadEligibilityCheck.test.js`    | Jest test       | New: 5 tests covering AC 1–3 and 7                                                            |
| `Sales_Rep_Base`                  | Permission set  | Changed: access to `LeadEligibilityController`; read-only Lead Address (for Country)          |
| `Lead_Record_Page`                | Lightning page  | Changed: eligibility card in the sidebar, under Lead Profile                                  |
| `tests/ui/story/BR014-S2.spec.ts` | Playwright test | New: 2 story tests covering AC 1–4 and 6                                                      |
