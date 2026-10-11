# BR014-S1: Consistent eligibility decision

- **Jira:** [SCRUM-6](https://asadkayani10-1791505782400.atlassian.net/browse/SCRUM-6)
- **Epic:** BR-014 Quick Eligibility Check ([SCRUM-5](https://asadkayani10-1791505782400.atlassian.net/browse/SCRUM-5))
- **Branch:** feature/BR014-S1
- **Dev org:** playbook-dev
- **Release:** 2026.10

## Story

As a sales rep, I need every lead judged by the same agreed rules, so each rep gets the same answer and knows why.

## Eligibility rules

A lead is eligible only if it meets all five rules.

| Rule | Requirement                    |
| ---- | ------------------------------ |
| R1   | Based in the US, Canada or UK  |
| R2   | 50 or more employees           |
| R3   | Annual revenue of 1M or more   |
| R4   | Not Government or Education    |
| R5   | Has an email address           |

## Acceptance criteria

> Copied from Jira SCRUM-6 (added 2026-10-10). Not yet confirmed by the business owner.

1. A lead that meets all five rules (R1 to R5) is judged **Eligible**.
2. A lead that fails any rule is judged **Not eligible**.
3. The result lists every rule the lead failed, not just the first one.
4. A lead with a missing value for any rule (country, employees, revenue, industry or email) is judged Not eligible, and the result says which details are missing.
5. Boundary values pass: exactly 50 employees meets R2, and exactly 1M revenue meets R3.
6. Common spellings of a country are treated the same (for example, "USA", "US" and "United States" all meet R1).
7. The same lead data always gives the same result, no matter which rep runs the check.
8. The rules give the same results when many leads are checked at once (for example, 200 leads in one data load).

## Notes

- Sibling stories: BR014-S2 (eligibility on demand) and BR014-S3 (recorded outcome) use this decision. All three ship together.

## Components changed

| Component | Type | Change |
| --------- | ---- | ------ |
| LeadEligibilityResult | Apex class | New |
| LeadEligibilityService | Apex class | New |
| LeadEligibilityServiceTest | Apex test class | New (9 tests, 100% coverage) |
| scripts/apex/br014-s1-try-it.apex | Anonymous Apex | New, read-only try-it script |
