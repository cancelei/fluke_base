import { test, expect } from '@playwright/test';

// Use global storageState produced by global-setup for this spec
test.use({ storageState: 'tmp/playwright/auth.json' });

test('authenticated user sees dashboard links', async ({ page }) => {
  await page.goto('/');
  // Expect navbar or a sign-out link to be present for authenticated users
  const navbar = page.locator('nav');
  await expect(navbar).toBeVisible();
  await expect(navbar.getByRole('link', { name: 'Dashboard' })).toBeVisible({ timeout: 5000 });
});
