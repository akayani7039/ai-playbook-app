// BR014-S1: try the eligibility rules on sample leads. Read-only: nothing is queried or saved.
// Run with: sf apex run --file scripts/apex/br014-s1-try-it.apex -o <dev-org>
// Change any value below and run again.
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
