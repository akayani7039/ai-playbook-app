import { test, expect, openRecord } from "../fixtures/salesforce";

// Production smoke (step 47). READ-ONLY: never create, edit or delete records here.
test("leads list view loads", async ({ salesforce: page }) => {
  await page.goto("/lightning/o/Lead/list");
  await expect(
    page.getByRole("heading", { name: /Leads/ }).first()
  ).toBeVisible();
});

test("lead record page shows the Lead Profile card", async ({
  salesforce: page,
  api
}) => {
  const { records } = await api.query<{ Id: string }>(
    "SELECT Id FROM Lead ORDER BY CreatedDate DESC LIMIT 1"
  );
  test.skip(records.length === 0, "No Lead in this org to open.");

  await openRecord(page, "Lead", records[0].Id);
  await expect(page.getByText("Lead Profile", { exact: true })).toBeVisible();
});
