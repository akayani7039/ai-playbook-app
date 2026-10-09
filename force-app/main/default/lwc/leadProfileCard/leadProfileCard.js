import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import COMPANY_FIELD from "@salesforce/schema/Lead.Company";
import COUNTRY_FIELD from "@salesforce/schema/Lead.Country";
import EMPLOYEES_FIELD from "@salesforce/schema/Lead.NumberOfEmployees";
import REVENUE_FIELD from "@salesforce/schema/Lead.AnnualRevenue";
import INDUSTRY_FIELD from "@salesforce/schema/Lead.Industry";

// optionalFields respects field-level security: hidden fields come back empty instead of failing.
const FIELDS = [
  COMPANY_FIELD,
  COUNTRY_FIELD,
  EMPLOYEES_FIELD,
  REVENUE_FIELD,
  INDUSTRY_FIELD
];

export default class LeadProfileCard extends LightningElement {
  @api recordId;
  lead;
  errorMessage;

  @wire(getRecord, { recordId: "$recordId", optionalFields: FIELDS })
  wiredLead({ data, error }) {
    if (data) {
      this.lead = data;
      this.errorMessage = undefined;
    } else if (error) {
      this.lead = undefined;
      this.errorMessage = "Unable to load lead details.";
    }
  }

  get company() {
    return getFieldValue(this.lead, COMPANY_FIELD);
  }

  get country() {
    return getFieldValue(this.lead, COUNTRY_FIELD);
  }

  get employees() {
    return getFieldValue(this.lead, EMPLOYEES_FIELD);
  }

  get annualRevenue() {
    return getFieldValue(this.lead, REVENUE_FIELD);
  }

  get industry() {
    return getFieldValue(this.lead, INDUSTRY_FIELD);
  }
}
