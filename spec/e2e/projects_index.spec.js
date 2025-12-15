import { test, expect } from './fixtures/test-base.js';

test('projects index shows newly created project', async ({ page, login }) => {
  await login();
  const name = `E2E Project ${Date.now()}`;

  // Seed via test-only endpoint (works in test env only)
  await page.goto(`/test_only/create_project?name=${encodeURIComponent(name)}`);

  // Visit projects index
  await page.goto('/projects');
  await expect(page.getByRole('heading', { name: 'My Projects' })).toBeVisible();
  // Use exact: true to match only the project title link, not the "View" button
  await expect(page.getByRole('link', { name, exact: true })).toBeVisible();
});

