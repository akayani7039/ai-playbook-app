import { test, expect, openRecord } from "../fixtures/salesforce";

// QA smoke (step 31): the Lead record page loads with the Lead Profile card.
test("lead record page shows the Lead Profile card", async ({
  salesforce: page,
  api
}) => {
  const { records } = await api.query<{ Id: string }>(
    "SELECT Id FROM Lead ORDER BY CreatedDate DESC LIMIT 1"
  );
  expect(
    records.length,
    "No Lead in this org. Load scripts/data first."
  ).toBeGreaterThan(0);

  await openRecord(page, "Lead", records[0].Id);

  await expect(page.getByText("Lead Profile", { exact: true })).toBeVisible();
  await expect(
    page.locator('c-lead-profile-card [data-id="company"]')
  ).not.toBeEmpty();
});
