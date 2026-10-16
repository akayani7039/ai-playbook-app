import { LightningElement, api } from "lwc";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import checkEligibility from "@salesforce/apex/LeadEligibilityController.checkEligibility";

const GENERIC_ERROR = "The eligibility check couldn't run. Try again.";

export default class LeadEligibilityCheck extends LightningElement {
  @api recordId;
  result;
  errorMessage;
  isChecking = false;

  // Calls Apex on every click (no cache), so each check uses the latest saved values.
  async handleCheck() {
    this.isChecking = true;
    this.errorMessage = undefined;
    try {
      this.result = await checkEligibility({ leadId: this.recordId });
      // BR014-S3: the check saved its outcome on the lead, so refresh the page's record data.
      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
    } catch (error) {
      this.result = undefined;
      // AuraHandledException messages are written for the rep; anything else gets a generic line.
      this.errorMessage = error?.body?.message || GENERIC_ERROR;
    } finally {
      this.isChecking = false;
    }
  }

  get isEligible() {
    return this.result?.isEligible === true;
  }

  get badgeClass() {
    return this.isEligible
      ? "slds-badge slds-theme_success"
      : "slds-badge slds-theme_error";
  }

  get hasReasons() {
    return this.result?.reasons?.length > 0;
  }
}
