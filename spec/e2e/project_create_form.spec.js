import { test, expect } from './fixtures/test-base.js';

test('create project via form with required fields', async ({ page, login }) => {
  await login('e2e@example.com');

  await page.goto('/projects/new');
  const name = `E2E Form Project ${Date.now()}`;
  // Use specific ID selectors to avoid ambiguity with stealth fields
  await page.locator('#project_name').fill(name);
  await page.locator('#project_stage').selectOption('idea');
  await page.locator('#project_description').fill('Project created by Playwright form test');

  await page.getByRole('button', { name: 'Create Project' }).click();

  // Lands on show page and sees project name
  await expect(page.getByRole('heading', { name })).toBeVisible();
});
