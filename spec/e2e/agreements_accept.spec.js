import { test, expect } from './fixtures/test-base.js';

test('other party can accept a pending agreement', async ({ page, login }) => {
  // Initiator creates an agreement
  await login('e2e@example.com');
  const projectName = `E2E Agreement Project ${Date.now()}`;
  await page.goto(`/test_only/create_agreement?project_name=${encodeURIComponent(projectName)}&other_email=${encodeURIComponent('mentor@example.com')}`);

  // Switch to other party (mentor) to accept
  await login('mentor@example.com');
  await page.goto('/agreements');

  // Find the row with our project name
  const row = page.getByRole('row', { name: new RegExp(projectName) });
  await expect(row).toBeVisible();

  // Click Accept within that row
  await expect(row.getByText('Pending')).toBeVisible();
  page.once('dialog', async (dialog) => {
    await dialog.accept();
  });
  await row.getByRole('button', { name: 'Accept' }).click();

  // Status badge updates to Accepted
  await expect(row.getByText('Accepted')).toBeVisible({ timeout: 5000 });
});
