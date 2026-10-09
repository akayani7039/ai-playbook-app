import { defineConfig, devices } from "@playwright/test";

// Suites: tests/ui/story (dev, step 17), smoke (QA, 31), regression (UAT, 38), prod-smoke (prod, 47).
export default defineConfig({
  testDir: "./tests/ui",
  timeout: 120_000,
  expect: { timeout: 30_000 },
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: [
    ["list"],
    ["html", { outputFolder: "playwright-report", open: "never" }]
  ],
  outputDir: "test-results",
  use: {
    ...devices["Desktop Chrome"],
    viewport: { width: 1440, height: 900 },
    // Traces and video are off: they would record the frontdoor login URL and session.
    trace: "off",
    video: "off",
    screenshot: "only-on-failure"
  }
});
