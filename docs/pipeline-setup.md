# Pipeline setup

> Copied from the reviewed `github-actions-review` package. The `.github/`, `scripts/ci/` and `tests/ci/` files it describes are already in this repo.

Six workflow files for the shared-org BR-014 demo. This is a local review package. Nothing has been installed in GitHub, deployed to Salesforce or sent to Slack/Jira.

## Contents

| File                           | Trigger                              | Result                                                                 |
| ------------------------------ | ------------------------------------ | ---------------------------------------------------------------------- |
| `01-pr-validation.yml`         | PR to develop or main                | Jest, Code Analyzer, delta and Apex check-only validation              |
| `02-qa-deployment.yml`         | Push to develop; manual on develop   | Combined QA deployment and UI smoke                                    |
| `03-release-preparation.yml`   | Manual on main                       | Freeze the latest QA-tested develop SHA, release branch/tag and notes  |
| `04-uat-deployment.yml`        | Manual on main, release branch input | Deploy frozen release, regress, then business approval                 |
| `05-production-validation.yml` | Manual on main, UAT run ID           | Validate exact release delta in playbook-prod and retain validation ID |
| `06-production-deployment.yml` | Manual on main, validation run ID    | Approved quick deploy, read-only smoke, tag and release-to-main PR     |

The package includes one composite setup action, shell/Python helpers and promotion validation tests. These are dependencies of the six workflows, so copy them together.

## Install in the application repository

Copy `.github/`, `scripts/ci/`, and `tests/ci/` into a separate Salesforce DX application repository. Review conflicts with existing files first. Do not put this pipeline in the skills-only repository.

The application must have:

- `sfdx-project.json`, with deployable metadata under `force-app/`.
- `package.json` and committed `package-lock.json`.
- Local `@salesforce/sfdx-lwc-jest` and `@playwright/test` dependencies compatible with Node 24.
- Real Apex tests and Jest tests for the three stories.
- Real Playwright tests and a configuration producing `playwright-report/` and `test-results/`.
- `main` and `develop`, with the pipeline/helper files present on both before use.

The templates assume one source root: `force-app`. Adjust the package helper if the application has more package directories. Full QA/UAT deployment intentionally brings together all story dependencies. Production uses a delta against main. PR and production deltas detect and block deletions (full QA/UAT deployments do not remove obsolete metadata): develop a separate reviewed deletion plan when needed.

### Required npm script contracts

| Script               | Must do                                                                     |
| -------------------- | --------------------------------------------------------------------------- |
| `test:unit:ci`       | Run LWC Jest noninteractively; fail on test failures or no tests            |
| `test:ui:smoke`      | QA Lead eligibility happy-path smoke                                        |
| `test:ui:regression` | UAT full rule, missing-data, access and saved-result regression             |
| `test:ui:prod-smoke` | Read-only production checks; no Lead edits/check requests that save results |

Example scripts (adapt test paths to your application):

```json
{
  "scripts": {
    "test:unit:ci": "sfdx-lwc-jest -- --ci --coverage --runInBand",
    "test:ui:smoke": "playwright test tests/ui/smoke",
    "test:ui:regression": "playwright test tests/ui/regression",
    "test:ui:prod-smoke": "playwright test tests/ui/prod-smoke"
  }
}
```

The helpers never use `--if-present` or `--passWithNoTests`. Missing scripts/dependencies fail. Tests receive `SF_INSTANCE_URL` and masked `SF_UI_ACCESS_TOKEN` from the authenticated target. Implement Salesforce front-door login/session setup in your Playwright fixture, using an isolated browser context. Do not save tokens, front-door URLs, cookies or auth state in screenshots, traces or uploaded reports. Disable traces on the login step. Inspect report artifacts before enabling uploads for real data.

## GitHub environments and secrets

Create environments in Repository Settings > Environments. Environment approval rules are configured in GitHub, not in YAML. Their availability depends on plan/repository visibility. Without reviewers, the `environment:` key alone is not an approval gate.

| Environment           | Target        | Secret `SFDX_AUTH_URL` | Variable `SF_ORG_ID` | Reviewer                                           |
| --------------------- | ------------- | ---------------------- | -------------------- | -------------------------------------------------- |
| pr-validation         | playbook-qa   | QA auth                | 00DAs00000yqFRpMAM   | Maintainer for credential-bearing PR jobs          |
| qa                    | playbook-qa   | QA auth                | 00DAs00000yqFRpMAM   | Optional                                           |
| release-freeze        | No org        | None                   | None                 | Release owner; verifies QA acceptance and blockers |
| uat                   | playbook-uat  | UAT auth               | 00DG100000EezETMAZ   | Release owner before deployment                    |
| uat-signoff           | No new login  | None                   | 00DG100000EezETMAZ   | Business owner, after regression evidence          |
| production-validation | playbook-prod | Main org auth          | 00DgK00000UgtoPUAR   | Release owner; UAT evidence is also checked        |
| production            | playbook-prod | Main org auth          | 00DgK00000UgtoPUAR   | Change approver before quick deploy                |
| release-finalization  | No org        | None                   | None                 | Optional release owner                             |

Shared dev is `playbook-dev` / `00DAw00000HPGhKMAX`. It is used locally, not by these workflows. Scratch orgs expire November 2, 2026. Replace auth and IDs if you recreate them. Aliases are recreated on each runner; local aliases alone cannot authenticate CI.

### Salesforce authentication

In your own authenticated terminal, retrieve the SFDX auth URL for each target:

```sh
sf org auth show-sfdx-auth-url --target-org playbook-qa
sf org auth show-sfdx-auth-url --target-org playbook-uat
sf org auth show-sfdx-auth-url --target-org playbook-prod
```

These commands reveal sensitive authentication material after confirmation. Store only the URL value in the matching environment secret `SFDX_AUTH_URL`. Do not paste it into a public file, commit, issue or workflow log. The package contains no credentials. A fresh runner logs in with `sf org login sfdx-url`, then queries Organization.Id and fails if it differs from `SF_ORG_ID`.

Set repository variables `SF_CLI_VERSION` and `SGD_VERSION` to the exact versions tested during rehearsal. Defaults are `latest` for initial setup, so pin before the demo. Reviewed action references use version tags; pin to verified commit SHAs if your repository policy requires them.

### GitHub permissions

Protect main/develop with reviews and the **PR validation / validate** required check. Enable Actions to create PRs. Freeze `release/*` and `freeze-*` tags using rulesets with only the release workflow identity able to create them; prevent edits after freeze. Restrict manual environment deployments to main as appropriate. Install these workflow files on the default main branch before dispatching.

Optional finalization environment secret `RELEASE_TOKEN`: a repository-scoped GitHub App installation token or fine-grained PAT with Contents and Pull requests write access. Tokens must be approved by organization policy. A PAT is simplest for this demo; a short-lived App token requires adapting the workflow to generate it. A PAT/App token lets the final PR trigger validation automatically. Without this optional secret, the workflow uses `GITHUB_TOKEN`: current GitHub documentation says opened/synchronize/reopened PR workflows require a user to select **Approve workflows to run**. Other token-generated event types generally do not trigger workflows. Approve those checks before reviewing the final merge.

All other GitHub operations use the workflow-scoped `GITHUB_TOKEN`. Grant only the permissions shown. PR validation never uses `pull_request_target`; fork PRs cannot access Salesforce credentials and fail with an explicit message. Review trusted internal PR code before allowing its credential-bearing environment job. Do not auto-approve unknown contributor code.

## Promotion and release sequence

1. Open each story PR to develop. Required PR validation checks the GitHub test-merge commit against the current QA org without deploying.
2. Merge approved stories into develop. QA deploys the combined full package and runs smoke. Initial QA must be seeded with any baseline metadata not in force-app; incremental PR validation needs existing dependencies. Each story PR may need fields/service dependencies included or already merged.
3. Dispatch Release preparation from main. Supply `release_month` (e.g. `2026.10`), latest successful QA `qa_run_id`, `jira_keys` (`SCRUM-10 SCRUM-11 SCRUM-12`) and a link to QA acceptance/blocker review. Approval freezes the exact tested develop SHA as `release/2026.10` and `freeze-2026.10`. It refuses to overwrite an existing release/tag.
4. Dispatch UAT deployment from main with `release_branch`. UAT deployment approval runs full Apex/Jest/UI regression. The separate uat-signoff job then pauses for the business owner. They review regression artifacts before approving. Only after both jobs succeed is the workflow run suitable for promotion.
5. Dispatch Production validation from main with the release branch and successful UAT run ID. It verifies workflow identity, run success, release SHA and main baseline. It generates the main-to-release delta and validates with `RunLocalTests` against playbook-prod. Keep the validation artifact/run ID and review runbook.
6. Dispatch Production deployment from main with release branch and validation run ID. Production environment reviewers approve before any step runs. The workflow verifies the successful validation workflow, identical release SHA, unchanged main baseline, matching org ID and a conservative nine-day age limit. It passes the saved validation ID to quick deploy, then runs read-only smoke.
7. After smoke success, finalization tags the deployed SHA as `prod-2026.10` and opens the release-to-main PR. A reviewer merges that PR under branch protection. The workflow deliberately does not bypass required reviews or merge protections. This manual merge is the final completion step; until then the deployment is successful but main is not yet updated.

The release branch is never rebuilt between UAT and production. If it moves after freeze, promotion fails. If main changes, re-run UAT and validation to obtain evidence for the new baseline. Use a new release month/identifier if a frozen release needs correction; this template supports YYYY.MM only, so adapt naming to support same-month revisions before using them.

### What each approval proves

Environment approval is a human control, not just a Boolean workflow input. Configure distinct reviewers and prevent self-review where needed. The workflow uses run IDs and attestation artifacts to bind tests/sign-off/validation to the release SHA. These artifacts are workflow evidence, not a cryptographic signing system. Restrict workflow/config edits and action privileges to trusted maintainers.

Main is assumed to reflect the last deployed baseline. Initialize it with the known application baseline before first release. External/manual changes to QA/UAT/production are not reconciled automatically. Do not run competing manual deployments during the release. Shared concurrency groups serialize QA jobs and production validation/deployment within their respective workflows; PR dry runs do not lock out a QA deployment. Schedule credential-bearing validations away from QA deploys if they contend.

## Notifications and Jira

Optional repository/environment secret `SLACK_WEBHOOK_URL` sends run-status notifications to its preselected demo channel. Leave it unset to skip. No Slack MCP is required by the runner. Notifications include only workflow name, job status, repository and run link. UAT notification is after business sign-off; production notification is after finalization. If an earlier UAT/production job fails and a later job never starts, review GitHub directly; no failure notification is promised for that skipped later job.

Jira keys and blocker-review links are recorded in release notes. The workflows do not independently query Jira or advance statuses. Use the Jira MCP/custom skills to check blockers, record business decisions and close stories after the main merge. This avoids assuming site-specific workflow transition IDs or storing Jira API credentials. If you want Jira writes inside CI later, add a separately reviewed Jira integration.

## Evidence and failure behavior

General test/deployment artifacts are kept for 30 days; the production-validation attestation for 10 days. Quick deploy rejects evidence older than nine days, leaving time before Salesforce's ten-day validity limit. Failed/in-progress validation is not treated as success. A reused quick-deploy ID may be rejected by Salesforce; revalidate rather than replay it blindly. Parallel same-workflow queued runs may be coalesced by GitHub concurrency; inspect the latest successful run.

A failed test/deploy stops promotion. A production smoke failure happens after metadata has already deployed; this template stops finalization and retains evidence. It does not automatically roll back or restore data. Prepare and rehearse a component-specific rollback/runbook before demo production deployment.

Code Analyzer results are explicitly gated: the action must succeed and report zero Sev 1 findings. Salesforce `RunLocalTests` applies platform deployment coverage requirements; this does not enforce the earlier proposed 90% story-specific target. Add a reviewed coverage gate if 90% remains a requirement.

Apex test results appear in deployment JSON and GitHub logs. Jest should emit coverage; Playwright should emit reports. Customize reporter paths if different. This folder has no business test implementation and cannot validate your application yet.

## Local verification

```sh
actionlint .github/workflows/*.yml
shellcheck scripts/ci/*.sh
python3 -m unittest discover -s tests/ci -v
```

Also parse the composite action YAML with a YAML parser. Four test cases cover matching evidence, changed SHA/baseline/org, stale validation and unsuccessful/wrong workflow identities. These checks do not substitute for a real GitHub/Salesforce rehearsal.

## Official references

- [Salesforce deploy commands](https://github.com/salesforcecli/plugin-deploy-retrieve)
- [sfdx-git-delta](https://github.com/scolladon/sfdx-git-delta)
- [Salesforce Code Analyzer action](https://github.com/forcedotcom/run-code-analyzer)
- [GitHub environment approvals](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)
- [Events and GITHUB_TOKEN](https://docs.github.com/en/actions/how-tos/writing-workflows/choosing-when-your-workflow-runs/triggering-a-workflow)

Prepared 3 October 2026. This folder is ready for review, not activated or tested against your orgs.
