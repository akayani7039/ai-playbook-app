# AI Playbook App

Salesforce application for the AI Development Playbook demo. The business requirement is **BR-014: Quick Eligibility Check**.

`main` holds the base project. BR-014 is built on top of it through `develop` and feature branches.

## What is in the base

| Area                                   | What it gives the stories                                                                                                                               |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Lead trigger + `TriggerHandler`        | One trigger per object. New Lead logic goes in a handler method that calls a service.                                                                   |
| `LeadDataStandardizer`                 | Existing feature. Trims Company and Country and maps country spellings (`USA`, `UK`, `CA`...) to one standard name. Country is free text in these orgs. |
| `LeadSelector`                         | All Lead queries, always `WITH USER_MODE`.                                                                                                              |
| `TestDataFactory`                      | Shared Lead and User test data.                                                                                                                         |
| `leadProfileCard` LWC + Jest test      | Pattern for Lead record page components and their unit tests.                                                                                           |
| `Lead_Default_Rating` flow + Apex test | Example record-triggered flow, so Apex vs. Flow is a real choice.                                                                                       |
| `Lead_Record_Page` + Lead layout       | The page and layout the stories add to.                                                                                                                 |
| `Sales_Rep_Base` permission set        | Base Lead access. Stories add their fields and classes.                                                                                                 |
| `scripts/data/`                        | 12 sample Leads covering every eligibility rule, including the edge cases.                                                                              |
| `tests/ui/`                            | Playwright login fixture plus smoke, regression and prod-smoke suites.                                                                                  |
| `.github/` + `scripts/ci/`             | The 6-workflow pipeline: PR validation, QA, release freeze, UAT, prod validation, prod deploy.                                                          |
| `code-analyzer.yml`                    | Security policy. CRUD/FLS, SOQL injection and sharing findings are Sev 1 and block the merge.                                                           |
| `features/_template/`                  | Feature folder template: story README and `architecture.md`.                                                                                            |

**Not in the base:** eligibility fields, eligibility rules, the eligibility component. Those are BR014-S1, S2 and S3.

## Branches

```
main ─────────────── production baseline (tag: v0-baseline, then prod-YYYY.MM)
 └─ develop ──────── integration, deploys to QA on every push
     ├─ feature/BR014-S1
     ├─ feature/BR014-S2
     └─ feature/BR014-S3
release/YYYY.MM ──── frozen from develop by workflow 03, deployed to UAT and prod
```

- Feature branches come from `develop` and merge back by PR.
- Only workflow 06 updates `main`, through a release-to-main PR.
- Protect `main` and `develop`: PR review plus the **PR validation / validate** check.

## Orgs

| Alias           | Use                                                     |
| --------------- | ------------------------------------------------------- |
| `playbook-dev`  | Developer org (one per story worktree in the full demo) |
| `playbook-qa`   | QA and PR validation                                    |
| `playbook-uat`  | UAT and regression                                      |
| `playbook-prod` | Demo production                                         |

## Getting started

```sh
npm install
npx playwright install chromium

# Deploy the base to an org and load sample data
sf project deploy start --source-dir force-app --target-org playbook-dev
sf org assign permset --name Sales_Rep_Base --target-org playbook-dev
npm run data:load -- --target-org playbook-dev
```

## Tests

| Command                                                      | What runs                                                  |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| `npm run test:unit`                                          | LWC Jest tests                                             |
| `sf apex run test --test-level RunLocalTests -o <org> -w 20` | Apex tests                                                 |
| `TARGET_ORG=playbook-dev npm run test:ui:story`              | Story UI tests (step 17). Empty until a story adds one.    |
| `TARGET_ORG=playbook-qa npm run test:ui:smoke`               | QA smoke (step 31)                                         |
| `TARGET_ORG=playbook-uat npm run test:ui:regression`         | UAT regression (step 38). Creates and deletes a test Lead. |
| `TARGET_ORG=playbook-prod npm run test:ui:prod-smoke`        | Production smoke (step 47). Read-only.                     |
| `sf code-analyzer run --workspace force-app`                 | Code Analyzer. Needs Java 11+ and Python 3.10+.            |
| `npm run test:ci`                                            | Tests for the CI evidence helper                           |

## Pipeline setup

See `docs/pipeline-setup.md` for GitHub environments, secrets and approvals.

## Open business decision

The deck does not say which answer wins when a lead **fails a rule and is also missing data**. The sample lead `Pine County Services` covers this case. Decide it in the BR014-S1 architecture brief.
