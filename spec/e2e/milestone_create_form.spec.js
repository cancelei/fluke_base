import { test, expect } from './fixtures/test-base.js';

test('add milestone to a project via form with required fields', async ({ page, login }) => {
  await login('e2e@example.com');
  const projectName = `E2E Milestone Project ${Date.now()}`;

  // Seed a project to attach milestone to
  await page.goto(`/test_only/create_project?name=${encodeURIComponent(projectName)}`);

  // Go to projects and open the project
  await page.goto('/projects');
  // Use exact: true to match only the project title link, not the "View" button
  await page.getByRole('link', { name: projectName, exact: true }).click();

  // Click Add Milestone
  await page.getByRole('link', { name: /add milestone/i }).first().click();

  // Fill minimal required fields
  await page.getByLabel('Title').fill('Kickoff');
  // Due date defaults; Status defaults; Description optional
  await page.getByRole('button', { name: 'Create Milestone' }).click();

  // Back on project page: new milestone listed
  await expect(page.locator('p', { hasText: 'Kickoff' })).toBeVisible();
});
