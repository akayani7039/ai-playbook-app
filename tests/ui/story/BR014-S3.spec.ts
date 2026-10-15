import {
  test,
  expect,
  openRecord,
  type SalesforceApi
} from "../fixtures/salesforce";
import type { Page } from "@playwright/test";

// BR014-S3 story test (step 17): each check saves its outcome on the lead.
// Uses the sample leads in scripts/data/Lead.json, plus one temporary lead it deletes.

type SavedOutcome = {
  Eligibility_Result__c: string | null;
  Eligibility_Reasons__c: string | null;
  Eligibility_Checked_By__c: string | null;
  Eligibility_Checked_On__c: string | null;
};

async function savedOutcome(api: SalesforceApi, leadId: string) {
  const { records } = await api.query<SavedOutcome>(
    "SELECT Eligibility_Result__c, Eligibility_Reasons__c, Eligibility_Checked_By__c, " +
      `Eligibility_Checked_On__c FROM Lead WHERE Id = '${leadId}'`
  );
  return records[0];
}

/** The value shown for a field in the page's detail panel. */
function fieldValue(page: Page, label: string) {
  return page.locator(`records-record-layout-item[field-label="${label}"]`);
}

async function runCheck(page: Page, expected: string) {
  const card = page.locator("c-lead-eligibility-check");
  await card.getByRole("button", { name: "Check eligibility" }).click();
  await expect(card.locator('[data-id="outcome"]')).toHaveText(expected);
}

test("AC 1, 5: a check saves the outcome and the page shows it", async ({
  salesforce: page,
  api
}) => {
  const { records } = await api.query<{ Id: string }>(
    "SELECT Id FROM Lead WHERE Company = 'Pine County Services' LIMIT 1"
  );
  expect(records.length, "Load scripts/data first.").toBe(1);
  await openRecord(page, "Lead", records[0].Id);

  await runCheck(page, "Not eligible");

  const saved = await savedOutcome(api, records[0].Id);
  expect(saved.Eligibility_Result__c).toBe("Not eligible");
  expect(saved.Eligibility_Reasons__c).toBe(
    "Industry is Government or Education;Email is missing"
  );
  expect(saved.Eligibility_Checked_By__c).not.toBeNull();
  expect(saved.Eligibility_Checked_On__c).not.toBeNull();

  await expect(fieldValue(page, "Eligibility Result")).toContainText(
    "Not eligible"
  );
  await expect(fieldValue(page, "Eligibility Reasons")).toContainText(
    "Email is missing"
  );
  await expect(fieldValue(page, "Eligibility Checked By")).not.toBeEmpty();
  await expect(fieldValue(page, "Eligibility Checked On")).not.toBeEmpty();
});

test("AC 2, 3, 6: editing the lead keeps the saved outcome until the next check", async ({
  salesforce: page,
  api
}) => {
  const leadId = await api.create("Lead", {
    LastName: "BR014-S3 story test",
    Company: "S3 Outcome Test Co",
    Country: "United States",
    NumberOfEmployees: 120,
    AnnualRevenue: 5000000,
    Industry: "Technology",
    Email: "s3.outcome.test@example.com"
  });
  try {
    await openRecord(page, "Lead", leadId);
    await runCheck(page, "Eligible");
    expect((await savedOutcome(api, leadId)).Eligibility_Result__c).toBe(
      "Eligible"
    );

    // Change the lead by hand: the saved outcome must not change.
    await page.getByRole("button", { name: "Edit", exact: true }).click();
    const employees = page.getByLabel("No. of Employees");
    await employees.fill("10");
    await page.getByRole("button", { name: "Save", exact: true }).click();
    await expect(employees).toBeHidden();
    await page.reload();
    await expect(fieldValue(page, "Eligibility Result")).toContainText(
      "Eligible"
    );
    expect((await savedOutcome(api, leadId)).Eligibility_Result__c).toBe(
      "Eligible"
    );

    // A new check replaces it.
    await runCheck(page, "Not eligible");
    const saved = await savedOutcome(api, leadId);
    expect(saved.Eligibility_Result__c).toBe("Not eligible");
    expect(saved.Eligibility_Reasons__c).toBe("Fewer than 50 employees");

    // Field history keeps both outcomes for audit.
    const history = await api.query<{ OldValue: string; NewValue: string }>(
      "SELECT OldValue, NewValue FROM LeadHistory WHERE LeadId = " +
        `'${leadId}' AND Field = 'Eligibility_Result__c' ORDER BY CreatedDate`
    );
    expect(history.records.map((row) => row.NewValue)).toEqual([
      "Eligible",
      "Not eligible"
    ]);
  } finally {
    await api.delete("Lead", leadId);
  }
});
