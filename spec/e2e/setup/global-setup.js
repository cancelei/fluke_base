import { chromium } from '@playwright/test';

// Logs in once via the test-only endpoint and saves auth state for reuse
export default async function globalSetup(config) {
  const { baseURL } = config.projects[0].use;
  const storagePath = 'tmp/playwright/auth.json';

  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  const loginUrl = new URL('/test_only/login?email=e2e@example.com', baseURL).toString();
  await page.goto(loginUrl);
  // Ensure home loaded post-login
  await page.waitForLoadState('domcontentloaded');

  await context.storageState({ path: storagePath });
  await browser.close();
}

