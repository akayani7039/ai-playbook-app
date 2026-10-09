# Architecture: <STORY-KEY> <Story title>

**Status:** Draft | Approved | Returned
**Architect:** <name> — **Decision date:** <date>

## 1. Context

- Epic and sibling stories considered:
- What this story must deliver:

## 2. Current state and impact

| Component                        | Exists today | Impact |
| -------------------------------- | ------------ | ------ |
| LeadTrigger / LeadTriggerHandler | Yes          |        |
| LeadDataStandardizer             | Yes          |        |
| Lead_Default_Rating flow         | Yes          |        |
| Lead_Record_Page                 | Yes          |        |

Dependencies on sibling stories:

## 3. Options

|                       | Option A | Option B |
| --------------------- | -------- | -------- |
| Summary               |          |          |
| Pros                  |          |          |
| Cons                  |          |          |
| Fits sibling stories? |          |          |

## 4. Security and NFRs

- [ ] Sharing model and class sharing keywords
- [ ] CRUD/FLS: `WITH USER_MODE` / `AccessLevel.USER_MODE`
- [ ] Bulk: 200-record trigger batch, no SOQL/DML in loops
- [ ] Governor limits
- [ ] Data classification (no sensitive data in logs or prompts)

## 5. Recommendation

Chosen option and trade-offs:

## 6. Design and build plan

| #   | Component | Type | New/Changed | Test |
| --- | --------- | ---- | ----------- | ---- |

**Deploy order:**

**Tests:** Apex: — Jest: — Playwright:

## 7. Open questions for the business
