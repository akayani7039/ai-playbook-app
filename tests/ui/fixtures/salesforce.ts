import { test as base, expect, type Page } from "@playwright/test";
import { execFileSync } from "node:child_process";

/**
 * Salesforce session for UI tests.
 * CI: scripts/ci/tests.sh sets SF_INSTANCE_URL and a masked SF_UI_ACCESS_TOKEN.
 * Local: set TARGET_ORG to an org alias, e.g. TARGET_ORG=playbook-dev npm run test:ui:smoke
 * Never log, screenshot or save the token. Traces are off in playwright.config.ts for this reason.
 */
type OrgSession = { instanceUrl: string; accessToken: string };

function resolveSession(): OrgSession {
  const { SF_INSTANCE_URL, SF_UI_ACCESS_TOKEN, TARGET_ORG } = process.env;
  if (SF_INSTANCE_URL && SF_UI_ACCESS_TOKEN) {
    return { instanceUrl: SF_INSTANCE_URL, accessToken: SF_UI_ACCESS_TOKEN };
  }
  if (!TARGET_ORG) {
    throw new Error(
      "Set SF_INSTANCE_URL and SF_UI_ACCESS_TOKEN, or TARGET_ORG for local runs."
    );
  }
  const sf = (args: string[]) =>
    JSON.parse(
      execFileSync("sf", [...args, "--target-org", TARGET_ORG, "--json"], {
        encoding: "utf8"
      })
    ).result;
  return {
    instanceUrl: sf(["org", "display"]).instanceUrl,
    accessToken: sf(["org", "auth", "show-access-token"]).accessToken
  };
}

let cachedSession: OrgSession | undefined;
const session = () => (cachedSession ??= resolveSession());

/** Small REST helper for test data setup and lookups. */
export class SalesforceApi {
  constructor(private readonly org: OrgSession) {}

  private async request(path: string, init: RequestInit = {}) {
    const response = await fetch(
      `${this.org.instanceUrl}/services/data/v67.0${path}`,
      {
        ...init,
        headers: {
          Authorization: `Bearer ${this.org.accessToken}`,
          "Content-Type": "application/json",
          ...init.headers
        }
      }
    );
    if (!response.ok) {
      throw new Error(
        `Salesforce API ${init.method ?? "GET"} ${path} failed: ${response.status}`
      );
    }
    return response.status === 204 ? undefined : response.json();
  }

  query<T = Record<string, unknown>>(soql: string): Promise<{ records: T[] }> {
    return this.request(`/query?q=${encodeURIComponent(soql)}`);
  }

  async create(
    sobject: string,
    fields: Record<string, unknown>
  ): Promise<string> {
    const result = await this.request(`/sobjects/${sobject}`, {
      method: "POST",
      body: JSON.stringify(fields)
    });
    return result.id;
  }

  async delete(sobject: string, id: string): Promise<void> {
    await this.request(`/sobjects/${sobject}/${id}`, { method: "DELETE" });
  }
}

/** Logs in through frontdoor and waits for Lightning to load. */
async function login(page: Page, org: OrgSession) {
  await page.goto(
    `${org.instanceUrl}/secur/frontdoor.jsp?sid=${encodeURIComponent(org.accessToken)}`
  );
  await page.waitForURL(/lightning\.force\.com|\/lightning\//, {
    timeout: 60_000
  });
}

export async function openRecord(
  page: Page,
  sobject: string,
  recordId: string
) {
  await page.goto(`/lightning/r/${sobject}/${recordId}/view`);
}

export const test = base.extend<{ salesforce: Page; api: SalesforceApi }>({
  baseURL: async ({}, use) => {
    await use(
      session().instanceUrl.replace(
        ".my.salesforce.com",
        ".lightning.force.com"
      )
    );
  },
  salesforce: async ({ page }, use) => {
    await login(page, session());
    await use(page);
  },
  api: async ({}, use) => {
    await use(new SalesforceApi(session()));
  }
});

export { expect };
