# BR014-S1: Consistent eligibility decision

- **Jira:** [SCRUM-6](https://asadkayani10-1791505782400.atlassian.net/browse/SCRUM-6)
- **Epic:** BR-014 Quick Eligibility Check ([SCRUM-5](https://asadkayani10-1791505782400.atlassian.net/browse/SCRUM-5))
- **Branch:** feature/BR014-S1
- **Dev org:** playbook-dev

## Story

As a sales rep, I need every lead judged by the same agreed rules, so each rep gets the same answer and knows why.

### Eligibility rules

A lead is eligible only if it meets all five rules.

- R1: Based in the US, Canada or UK
- R2: 50 or more employees
- R3: Annual revenue of 1M or more
- R4: Not Government or Education
- R5: Has an email address

## Acceptance criteria

1. A lead that meets all five rules (R1 to R5) is judged **Eligible**.
2. A lead that fails any rule is judged **Not eligible**.
3. The result lists every rule the lead failed, not just the first one.
4. A lead with a missing value for any rule (country, employees, revenue, industry or email) is judged Not eligible, and the result says which details are missing.
5. Boundary values pass: exactly 50 employees meets R2, and exactly 1M revenue meets R3.
6. Common spellings of a country are treated the same (for example, "USA", "US" and "United States" all meet R1).
7. The same lead data always gives the same result, no matter which rep runs the check.
8. The rules give the same results when many leads are checked at once (for example, 200 leads in one data load).

## Notes

Ships with S2 and S3 in release/2026.10. S2 (Eligibility on demand) builds on this story, and S3 (Recorded eligibility outcome) builds on S2.

## Components changed

| Component                           | Type            | Change                                                                                     |
| ----------------------------------- | --------------- | ------------------------------------------------------------------------------------------ |
| `LeadEligibilityResult`             | Apex class      | New: the eligibility answer for one lead (outcome, failed rules, missing details, reasons) |
| `LeadEligibilityService`            | Apex class      | New: judges leads against R1–R5 on demand; no SOQL or DML                                  |
| `LeadEligibilityServiceTest`        | Apex test class | New: 11 tests covering AC 1–8, input guard and caller contract                             |
| `scripts/apex/br014-s1-try-it.apex` | Anonymous Apex  | New: demo aid, not deployed                                                                |
