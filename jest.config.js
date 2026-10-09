const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
  // Jest runs LWC unit tests only. Playwright owns tests/ui.
  roots: ["<rootDir>/force-app"]
};
