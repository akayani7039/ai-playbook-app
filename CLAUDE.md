# AI Playbook App — agent rules

Salesforce DX project for BR-014 Quick Eligibility Check. Pipeline skills (story-setup, architecture-brief, pr-package, sf-code-review, ui-test-playwright, release-train, prod-change) live in the separate `ai-playbook-skills` repo.

## Branches and stories

- Branch from `develop`: `feature/BR014-S<n>`. One story per branch, worktree and dev org.
- Commit messages start with the story key: `BR014-S1: <what changed>`.
- Never commit to `main` or `develop` directly. Never push without being asked.
- Each story's feature folder is `features/BR014-S<n>/` (copy `features/_template/`).
- No code before the story's `architecture.md` is approved by the architect (step 11).

## Apex

- Lead logic: add a method call in `LeadTriggerHandler`, put the logic in a service class. No logic in triggers.
- Queries go in a selector and use `WITH USER_MODE`. DML uses `AccessLevel.USER_MODE` or `Security.stripInaccessible`.
- Classes declare `with sharing` (or `inherited sharing` for selectors and utilities).
- Bulk-safe: no SOQL or DML in loops. Tests insert 200 records.
- Use `LeadDataStandardizer` country names. Don't re-implement country matching.
- Tests: use `TestDataFactory`, `Assert` class, meaningful asserts. Aim for 90% coverage on new classes.

## LWC

- Follow `leadProfileCard`: `getRecord` with `optionalFields`, schema imports, Jest test in `__tests__`.

## Metadata

- New Lead fields: add field permissions to `Sales_Rep_Base` and place the field on `Lead-Lead Layout`.
- Never commit deletions. CI blocks destructive changes.

## Checks before a PR

```sh
npm run lint && npm run test:unit
sf project deploy start --dry-run --source-dir force-app -o <dev-org> --test-level RunLocalTests -w 30
sf code-analyzer run --workspace force-app   # zero Sev 1
```

## Data and safety

- Demo orgs and sample data only. No real customer data in prompts, tests or screenshots.
- Never print, log or commit access tokens or SFDX auth URLs.
- `prod-smoke` tests must be read-only.
