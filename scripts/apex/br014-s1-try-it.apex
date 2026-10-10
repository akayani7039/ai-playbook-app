// BR014-S1: try the eligibility rules. Read-only: nothing is saved.
// Run in Developer Console > Debug > Open Execute Anonymous Window, tick "Open Log",
// then filter the log with "Debug Only".

// Part 1: sample leads built in memory. Change any value and run again.
List<Lead> samples = new List<Lead>{
  new Lead(Company = 'Acme Robotics', Country = 'USA', NumberOfEmployees = 120,
    AnnualRevenue = 5000000, Industry = 'Technology', Email = 'buyer@acme.example'),
  new Lead(Company = 'Exactly On The Line', Country = 'Canada', NumberOfEmployees = 50,
    AnnualRevenue = 1000000, Industry = 'Retail', Email = 'ops@line.example'),
  new Lead(Company = 'Berlin Bikes', Country = 'Germany', NumberOfEmployees = 30,
    AnnualRevenue = 800000, Industry = 'Retail', Email = null),
  new Lead(Company = 'Pine County Services', Country = 'US', NumberOfEmployees = 400,
    AnnualRevenue = 9000000, Industry = 'Government', Email = null),
  new Lead(Company = 'Half Filled Ltd', Country = 'UK', NumberOfEmployees = null,
    AnnualRevenue = 2000000, Industry = null, Email = 'hi@half.example')
};
List<LeadEligibilityResult> results = LeadEligibilityService.evaluate(samples);
for (Integer i = 0; i < samples.size(); i++) {
  System.debug(samples[i].Company + ' -> ' + results[i].outcome
    + (results[i].reasons.isEmpty() ? '' : '. Why: ' + String.join(results[i].reasons, '; ')));
}

// Part 2: the real leads in this org.
List<Lead> orgLeads = [
  SELECT Id, Company, Country, NumberOfEmployees, AnnualRevenue, Industry, Email
  FROM Lead WITH USER_MODE ORDER BY Company LIMIT 50
];
for (LeadEligibilityResult r : LeadEligibilityService.evaluate(orgLeads)) {
  Lead l = new Map<Id, Lead>(orgLeads).get(r.leadId);
  System.debug('[org] ' + l.Company + ' -> ' + r.outcome
    + (r.reasons.isEmpty() ? '' : '. Why: ' + String.join(r.reasons, '; ')));
}
