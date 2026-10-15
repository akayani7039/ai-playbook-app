import {
  test,
  expect,
  openRecord,
  type SalesforceApi
} from "../fixtures/salesforce";

// BR014-S2 story test (step 17): a rep checks a lead's eligibility from the record page.
// Uses the sample leads in scripts/data/Lead.json (Acme Robotics, Pine County Services).

async function leadIdFor(api: SalesforceApi, company: string) {
  const { records } = await api.query<{ Id: string }>(
    `SELECT Id FROM Lead WHERE Company = '${company}' LIMIT 1`
  );
  expect(
    records.length,
    `Sample lead "${company}" not found. Load scripts/data first.`
  ).toBe(1);
  return records[0].Id;
}

test("AC 1, 2, 6: one click shows Eligible within 2 seconds", async ({
  salesforce: page,
  api
}) => {
  await openRecord(page, "Lead", await leadIdFor(api, "Acme Robotics"));
  const card = page.locator("c-lead-eligibility-check");
  const button = card.getByRole("button", { name: "Check eligibility" });
  await expect(button).toBeEnabled();

  const started = Date.now();
  await button.click();
  await expect(card.locator('[data-id="outcome"]')).toHaveText("Eligible");
  const elapsed = Date.now() - started;

  expect(elapsed, `Result took ${elapsed} ms`).toBeLessThan(2_000);
  await expect(card.locator('[data-id="reasons"]')).toHaveCount(0);
});

test("AC 3, 4: Not eligible lists every failed rule and missing detail", async ({
  salesforce: page,
  api
}) => {
  await openRecord(page, "Lead", await leadIdFor(api, "Pine County Services"));
  const card = page.locator("c-lead-eligibility-check");

  await card.getByRole("button", { name: "Check eligibility" }).click();

  await expect(card.locator('[data-id="outcome"]')).toHaveText("Not eligible");
  await expect(card.locator('[data-id="reasons"] li')).toHaveText([
    "Industry is Government or Education",
    "Email is missing"
  ]);
});
