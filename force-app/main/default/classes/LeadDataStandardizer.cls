/**
 * Keeps Lead data clean before save.
 * - Trims Company and Country.
 * - Maps common country spellings to one standard name (e.g. "USA" -> "United States").
 * Country is free text in this org (no State and Country picklists), so other features
 * can rely on these standard names instead of handling every spelling themselves.
 */
public with sharing class LeadDataStandardizer {
  public static final String UNITED_STATES = 'United States';
  public static final String CANADA = 'Canada';
  public static final String UNITED_KINGDOM = 'United Kingdom';

  @TestVisible
  private static final Map<String, String> COUNTRY_ALIASES = new Map<String, String>{
    'us' => UNITED_STATES,
    'u.s.' => UNITED_STATES,
    'usa' => UNITED_STATES,
    'u.s.a.' => UNITED_STATES,
    'united states' => UNITED_STATES,
    'united states of america' => UNITED_STATES,
    'ca' => CANADA,
    'can' => CANADA,
    'canada' => CANADA,
    'uk' => UNITED_KINGDOM,
    'u.k.' => UNITED_KINGDOM,
    'gb' => UNITED_KINGDOM,
    'great britain' => UNITED_KINGDOM,
    'united kingdom' => UNITED_KINGDOM
  };

  public static void standardize(List<Lead> leads) {
    for (Lead record : leads) {
      record.Company = record.Company?.trim();
      record.Country = standardCountry(record.Country);
    }
  }

  /** Returns the standard country name, or the trimmed value if it is not a known alias. */
  public static String standardCountry(String country) {
    if (String.isBlank(country)) {
      return null;
    }
    String trimmed = country.trim();
    String standard = COUNTRY_ALIASES.get(trimmed.toLowerCase());
    return standard != null ? standard : trimmed;
  }
}
