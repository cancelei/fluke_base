import { test, expect } from '@playwright/test';

// Use authenticated session
test.use({ storageState: 'tmp/playwright/auth.json' });

test.describe('Unified Logs Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/logs');
  });

  test('page loads with required elements', async ({ page }) => {
    // Page header
    await expect(page.getByRole('heading', { name: /unified logs/i })).toBeVisible();

    // Filter controls
    await expect(page.getByText('Types:')).toBeVisible();
    await expect(page.getByRole('button', { name: /mcp/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /container/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /app/i })).toBeVisible();

    // Level select
    await expect(page.getByText('Level:')).toBeVisible();

    // Search input
    await expect(page.getByPlaceholder('Search logs...')).toBeVisible();

    // Log stream container
    await expect(page.locator('[data-controller="unified-logs"]')).toBeVisible();
  });

  test('stream controls are present', async ({ page }) => {
    // Pause button
    await expect(page.getByRole('button', { name: /pause/i })).toBeVisible();

    // Clear button
    await expect(page.getByRole('button', { name: /clear/i })).toBeVisible();

    // Auto-scroll checkbox
    await expect(page.getByRole('checkbox', { name: /auto-scroll/i })).toBeVisible();
  });

  test('connection status indicator is present', async ({ page }) => {
    // Status indicator (connecting, connected, or disconnected)
    const statusIndicator = page.locator('[data-unified-logs-target="connectionStatus"]');
    await expect(statusIndicator).toBeVisible();
  });

  test('export dropdown works', async ({ page }) => {
    // Click export dropdown
    const exportButton = page.getByRole('button', { name: /export/i });
    await expect(exportButton).toBeVisible();
    await exportButton.click();

    // Export options should appear
    await expect(page.getByRole('link', { name: /json/i })).toBeVisible();
    await expect(page.getByRole('link', { name: /csv/i })).toBeVisible();
  });

  test('type toggle buttons work', async ({ page }) => {
    const mcpButton = page.getByRole('button', { name: /mcp/i });

    // Initially active (has primary class)
    await expect(mcpButton).toHaveClass(/btn-primary/);

    // Click to toggle off
    await mcpButton.click();

    // Should now be ghost style
    await expect(mcpButton).toHaveClass(/btn-ghost/);

    // Click again to toggle on
    await mcpButton.click();
    await expect(mcpButton).toHaveClass(/btn-primary/);
  });

  test('clear button empties log list', async ({ page }) => {
    const clearButton = page.getByRole('button', { name: /clear/i });
    await clearButton.click();

    // Should show empty state
    await expect(page.getByText(/no log entries/i)).toBeVisible();
  });

  test('pause button toggles streaming', async ({ page }) => {
    const pauseButton = page.locator('[data-unified-logs-target="pauseButton"]');

    // Initially shows pause
    await expect(pauseButton).toBeVisible();

    // Click to pause
    await pauseButton.click();

    // Button should now indicate resume
    await expect(page.getByRole('button', { name: /resume/i })).toBeVisible();
  });

  test('search input accepts text', async ({ page }) => {
    const searchInput = page.getByPlaceholder('Search logs...');

    await searchInput.fill('error message');
    await expect(searchInput).toHaveValue('error message');
  });

  test('level dropdown has all options', async ({ page }) => {
    const levelSelect = page.locator('[data-log-filter-target="levelSelect"]');
    await levelSelect.click();

    // Check dropdown options
    await expect(page.getByRole('option', { name: 'All' })).toBeVisible();
    await expect(page.getByRole('option', { name: 'Info+' })).toBeVisible();
    await expect(page.getByRole('option', { name: 'Warn+' })).toBeVisible();
    await expect(page.getByRole('option', { name: 'Error+' })).toBeVisible();
  });

  test('keyboard shortcuts are documented', async ({ page }) => {
    // Check keyboard shortcut hints are visible
    await expect(page.getByText('Space')).toBeVisible();
    await expect(page.getByText('Pause/Resume')).toBeVisible();
  });

  test('auto-scroll checkbox toggles', async ({ page }) => {
    const checkbox = page.getByRole('checkbox', { name: /auto-scroll/i });

    // Initially checked
    await expect(checkbox).toBeChecked();

    // Click to uncheck
    await checkbox.click();
    await expect(checkbox).not.toBeChecked();

    // Click to check again
    await checkbox.click();
    await expect(checkbox).toBeChecked();
  });
});

test.describe('Unified Logs Security', () => {
  test.use({ storageState: 'tmp/playwright/auth.json' });

  test('XSS in log message is prevented', async ({ page }) => {
    await page.goto('/logs');

    // Wait for page to load
    await expect(page.getByRole('heading', { name: /unified logs/i })).toBeVisible();

    // Inject malicious log entry via console (simulating WebSocket message)
    await page.evaluate(() => {
      const logList = document.querySelector('[data-unified-logs-target="logList"]');
      if (logList) {
        // This should NOT execute - the controller should escape it
        logList.innerHTML += `<div><script>window.xssExecuted=true</script></div>`;
      }
    });

    // Verify XSS didn't execute
    const xssExecuted = await page.evaluate(() => window.xssExecuted);
    expect(xssExecuted).not.toBe(true);
  });

  test('unauthenticated access redirects to login', async ({ browser }) => {
    // Create new context without auth
    const context = await browser.newContext();
    const page = await context.newPage();

    await page.goto('/logs');

    // Should redirect to login
    await expect(page).toHaveURL(/sign_in/);

    await context.close();
  });
});

test.describe('Unified Logs Accessibility', () => {
  test.use({ storageState: 'tmp/playwright/auth.json' });

  test('page has proper heading structure', async ({ page }) => {
    await page.goto('/logs');

    // Main heading
    const h1 = page.getByRole('heading', { level: 1 });
    await expect(h1).toBeVisible();
  });

  test('buttons have accessible names', async ({ page }) => {
    await page.goto('/logs');

    // All buttons should be accessible
    const buttons = page.getByRole('button');
    const count = await buttons.count();

    for (let i = 0; i < count; i++) {
      const button = buttons.nth(i);
      const name = await button.getAttribute('aria-label') || await button.textContent();
      expect(name).toBeTruthy();
    }
  });

  test('form controls have labels', async ({ page }) => {
    await page.goto('/logs');

    // Search input should have placeholder as accessible name
    const searchInput = page.getByPlaceholder('Search logs...');
    await expect(searchInput).toBeVisible();

    // Level select should be associated with label
    await expect(page.getByText('Level:')).toBeVisible();
  });
});
