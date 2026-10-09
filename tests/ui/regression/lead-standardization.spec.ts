import { test, expect, openRecord } from "../fixtures/salesforce";

// UAT regression (step 38): base Lead behaviour still works after a release.
test.describe("lead data standardization", () => {
  let leadId: string | undefined;

  test.afterEach(async ({ api }) => {
    if (leadId) {
      await api.delete("Lead", leadId);
      leadId = undefined;
    }
  });

  test("country alias is saved as the standard name", async ({
    salesforce: page,
    api
  }) => {
    leadId = await api.create("Lead", {
      LastName: "Regression Lead",
      Company: "  Regression Robotics  ",
      Country: "usa",
      NumberOfEmployees: 120,
      AnnualRevenue: 5000000,
      Industry: "Technology",
      Email: "regression.lead@example.com"
    });

    await openRecord(page, "Lead", leadId);

    const card = page.locator("c-lead-profile-card");
    await expect(card.locator('[data-id="country"]')).toHaveText(
      "United States"
    );
    await expect(card.locator('[data-id="company"]')).toHaveText(
      "Regression Robotics"
    );
  });
});
