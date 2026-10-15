import { createElement } from "@lwc/engine-dom";
import LeadEligibilityCheck from "c/leadEligibilityCheck";
import checkEligibility from "@salesforce/apex/LeadEligibilityController.checkEligibility";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";

jest.mock(
  "@salesforce/apex/LeadEligibilityController.checkEligibility",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const LEAD_ID = "00Q000000000001AAA";

const ELIGIBLE = {
  leadId: LEAD_ID,
  isEligible: true,
  outcome: "Eligible",
  failedRules: [],
  missingDetails: [],
  reasons: []
};

const NOT_ELIGIBLE = {
  leadId: LEAD_ID,
  isEligible: false,
  outcome: "Not eligible",
  failedRules: ["R4"],
  missingDetails: ["Email"],
  reasons: ["Industry is Government or Education", "Email is missing"]
};

// Waits for the mocked Apex call and the re-render to finish.
// eslint-disable-next-line @lwc/lwc/no-async-operation
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-lead-eligibility-check", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent() {
    const element = createElement("c-lead-eligibility-check", {
      is: LeadEligibilityCheck
    });
    element.recordId = LEAD_ID;
    document.body.appendChild(element);
    return element;
  }

  const find = (element, id) =>
    element.shadowRoot.querySelector(`[data-id="${id}"]`);

  async function clickCheck(element) {
    find(element, "check-button").click();
    await flushPromises();
  }

  it("shows Eligible and no reasons", async () => {
    checkEligibility.mockResolvedValue(ELIGIBLE);
    const element = createComponent();

    await clickCheck(element);

    expect(checkEligibility).toHaveBeenCalledWith({ leadId: LEAD_ID });
    expect(find(element, "outcome").textContent).toBe("Eligible");
    expect(find(element, "reasons")).toBeNull();
    expect(find(element, "error")).toBeNull();
  });

  it("refreshes the page's record data after a check", async () => {
    checkEligibility.mockResolvedValue(ELIGIBLE);
    const element = createComponent();

    await clickCheck(element);

    expect(notifyRecordUpdateAvailable).toHaveBeenCalledWith([
      { recordId: LEAD_ID }
    ]);
  });

  it("does not refresh the record data when the check fails", async () => {
    checkEligibility.mockRejectedValue({ body: { message: "Not saved" } });
    const element = createComponent();

    await clickCheck(element);

    expect(notifyRecordUpdateAvailable).not.toHaveBeenCalled();
  });

  it("shows Not eligible with one list item per reason", async () => {
    checkEligibility.mockResolvedValue(NOT_ELIGIBLE);
    const element = createComponent();

    await clickCheck(element);

    expect(find(element, "outcome").textContent).toBe("Not eligible");
    const items = [...find(element, "reasons").querySelectorAll("li")].map(
      (item) => item.textContent
    );
    expect(items).toEqual([
      "Industry is Government or Education",
      "Email is missing"
    ]);
  });

  it("shows the server message on error, not a raw error", async () => {
    const message =
      "You don't have access to all the lead details the check needs. Ask your admin for the Sales Rep Base permission set.";
    checkEligibility.mockRejectedValue({ body: { message } });
    const element = createComponent();

    await clickCheck(element);

    expect(find(element, "error").textContent).toBe(message);
    expect(find(element, "outcome")).toBeNull();
  });

  it("shows a plain message when the error has no server message", async () => {
    checkEligibility.mockRejectedValue(new Error("network"));
    const element = createComponent();

    await clickCheck(element);

    expect(find(element, "error").textContent).toBe(
      "The eligibility check couldn't run. Try again."
    );
  });

  it("disables the button while the check runs", async () => {
    let finish;
    checkEligibility.mockReturnValue(
      new Promise((resolve) => {
        finish = resolve;
      })
    );
    const element = createComponent();
    const button = find(element, "check-button");

    button.click();
    await Promise.resolve();
    expect(button.disabled).toBe(true);

    finish(ELIGIBLE);
    await flushPromises();
    expect(button.disabled).toBe(false);
  });
});
