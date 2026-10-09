import { createElement } from "@lwc/engine-dom";
import LeadProfileCard from "c/leadProfileCard";
import { getRecord } from "lightning/uiRecordApi";

const mockRecord = require("./data/getRecord.json");

describe("c-lead-profile-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent() {
    const element = createElement("c-lead-profile-card", {
      is: LeadProfileCard
    });
    element.recordId = mockRecord.id;
    document.body.appendChild(element);
    return element;
  }

  const text = (element, id) =>
    element.shadowRoot.querySelector(`[data-id="${id}"]`)?.textContent;

  it("shows the lead details", async () => {
    const element = createComponent();

    getRecord.emit(mockRecord);
    await Promise.resolve();

    expect(text(element, "company")).toBe("Acme Robotics");
    expect(text(element, "country")).toBe("United States");
    expect(text(element, "industry")).toBe("Technology");
    const revenue = element.shadowRoot.querySelector(
      '[data-id="revenue"] lightning-formatted-number'
    );
    expect(revenue.value).toBe(5000000);
    expect(element.shadowRoot.querySelector('[data-id="error"]')).toBeNull();
  });

  it("shows an error when the lead cannot be loaded", async () => {
    const element = createComponent();

    getRecord.error();
    await Promise.resolve();

    expect(text(element, "error")).toBe("Unable to load lead details.");
    expect(element.shadowRoot.querySelector('[data-id="company"]')).toBeNull();
  });
});
