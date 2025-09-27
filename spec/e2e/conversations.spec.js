import { test, expect } from './fixtures/test-base.js';

test('conversations page shows a seeded conversation and message', async ({ page, login }) => {
  await login('e2e@example.com');
  const body = `Hello E2E ${Date.now()}`;
  await page.goto(`/test_only/create_conversation?other_email=${encodeURIComponent('mentor@example.com')}&body=${encodeURIComponent(body)}`);

  await page.goto('/conversations');
  await expect(page.getByRole('heading', { name: /messages/i })).toBeVisible({ timeout: 5000 });
  const content = page.locator('#conversation_content');
  await expect(content.getByText(body)).toBeVisible();
});
