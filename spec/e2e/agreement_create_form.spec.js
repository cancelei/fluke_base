import { test, expect } from './fixtures/test-base.js';

test('user can view project and navigate to agreements', async ({ page, login }) => {
  // This test verifies project viewing and navigation to agreements
  // FlukeBase unified experience: any user can access all features
  await login('e2e@example.com');
  const projectName = `E2E Agreement Form ${Date.now()}`;

  // Create project via test-only endpoint for reliable setup
  await page.goto(`/test_only/create_project?name=${encodeURIComponent(projectName)}`);

  // Navigate to projects page
  await page.goto('/projects');

  // Verify project exists
  await expect(page.getByRole('heading', { name: 'My Projects', level: 1 })).toBeVisible();
  await expect(page.getByRole('link', { name: projectName, exact: true })).toBeVisible();

  // Click on the project to navigate to project show page
  await page.getByRole('link', { name: projectName, exact: true }).click();
  await page.waitForLoadState('networkidle');

  // Verify we're on the project page
  await expect(page.getByRole('heading', { name: projectName })).toBeVisible();

  // Verify project page has expected sections
  const hasProjectContent = await page.locator('main').isVisible();
  expect(hasProjectContent).toBeTruthy();

  // Navigate to agreements via navbar to verify agreements access
  await page.getByRole('link', { name: 'Agreements' }).click();
  await page.waitForLoadState('networkidle');

  // Verify we're on agreements page
  await expect(page.getByRole('heading', { name: 'Agreements', level: 1 })).toBeVisible();
});

test('user can create agreement using test endpoint and view it', async ({ page, login }) => {
  // This test uses the reliable test-only endpoint to create agreement
  // then verifies the UI displays it correctly
  await login('e2e@example.com');
  const projectName = `E2E Agreement View ${Date.now()}`;

  // Create agreement via test-only endpoint (most reliable)
  await page.goto(`/test_only/create_agreement?project_name=${encodeURIComponent(projectName)}&other_email=collaborator@example.com`);

  // Navigate to agreements list
  await page.goto('/agreements');

  // Verify we're on agreements page - use level 1 heading to be specific
  await expect(page.getByRole('heading', { name: 'Agreements', level: 1 })).toBeVisible();

  // Find the agreement row
  const agreementRow = page.getByRole('row', { name: new RegExp(projectName) });
  await expect(agreementRow).toBeVisible();

  // Verify status badge shows Pending
  await expect(agreementRow.getByText('Pending')).toBeVisible();

  // Click the View link - this navigates to the associated project page
  const viewLink = agreementRow.getByRole('link', { name: /view/i }).first();
  await expect(viewLink).toBeVisible();
  await viewLink.click();
  await page.waitForLoadState('networkidle');

  // Verify we're on a detail page (project or agreement)
  // The "View" link in agreements list navigates to the project page
  const currentUrl = page.url();
  const isOnDetailPage = currentUrl.includes('/projects/') || currentUrl.includes('/agreements/');
  expect(isOnDetailPage).toBeTruthy();

  // Verify the project name is visible on the page
  await expect(page.getByRole('heading', { name: projectName })).toBeVisible({ timeout: 5000 });
});

test('user can cancel their own pending agreement', async ({ page, login }) => {
  // Test the ability to cancel a pending agreement
  // FlukeBase unified experience: any user can cancel their own agreements
  await login('e2e@example.com');
  const projectName = `E2E Cancel Agreement ${Date.now()}`;

  // Create agreement via test-only endpoint
  await page.goto(`/test_only/create_agreement?project_name=${encodeURIComponent(projectName)}&other_email=cancel-test@example.com`);

  // Navigate to agreements list
  await page.goto('/agreements');

  // Verify we're on agreements page
  await expect(page.getByRole('heading', { name: 'Agreements', level: 1 })).toBeVisible();

  // Find the agreement row
  const row = page.getByRole('row', { name: new RegExp(projectName) });
  await expect(row).toBeVisible();

  // Verify status shows Pending (prerequisite for cancellation)
  await expect(row.getByText('Pending')).toBeVisible();

  // Try to find cancel button in the row
  const cancelInRow = row.getByRole('button', { name: /cancel/i });
  const viewLink = row.getByRole('link', { name: /view/i }).first();

  if (await cancelInRow.isVisible().catch(() => false)) {
    // Cancel directly from list - handle confirmation dialog
    page.once('dialog', async (dialog) => await dialog.accept());
    await cancelInRow.click();
    await page.waitForLoadState('networkidle');
  } else if (await viewLink.isVisible().catch(() => false)) {
    // Navigate to show page and cancel there
    await viewLink.click();
    await page.waitForLoadState('networkidle');

    // Look for cancel button on show page
    const cancelButton = page.getByRole('button', { name: /cancel/i }).first();
    if (await cancelButton.isVisible().catch(() => false)) {
      page.once('dialog', async (dialog) => await dialog.accept());
      await cancelButton.click();
      await page.waitForLoadState('networkidle');
    }
  }

  // Verify cancellation outcome - either see "Cancelled" status or success message
  const cancelled = await page.getByText(/cancelled/i).first().isVisible({ timeout: 5000 }).catch(() => false);
  const success = await page.getByText(/success|agreement.*cancel/i).first().isVisible({ timeout: 5000 }).catch(() => false);

  expect(cancelled || success).toBeTruthy();
});
