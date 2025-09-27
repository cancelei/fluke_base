import { test as base, expect } from '@playwright/test';

// Extend Playwright test with a convenient login helper using the test-only endpoint
export const test = base.extend({
  login: async ({ page }, use) => {
    await page.goto('/test_only/login?email=e2e@example.com');
    await page.waitForLoadState('domcontentloaded');
    await use(async (email = 'e2e@example.com') => {
      await page.goto(`/test_only/login?email=${encodeURIComponent(email)}`);
      await page.waitForLoadState('domcontentloaded');
    });
  }
});

export { expect };

