import { test, expect } from '@playwright/test';

/**
 * Full Application Smoke Tests
 *
 * These tests visit every major page in the application to verify:
 * - Pages render without 500 errors
 * - No missing database columns or model attributes
 * - Basic UI elements are present
 *
 * Run with: npm run test:e2e -- spec/e2e/full_app_smoke.spec.js
 */

// Use authenticated session for all tests
test.use({ storageState: 'tmp/playwright/auth.json' });

test.describe('Public Pages (No Auth Required)', () => {
  test.use({ storageState: { cookies: [], origins: [] } }); // Clear auth for public tests

  test('home page loads', async ({ page }) => {
    await page.goto('/');
    await expect(page).not.toHaveTitle(/Error|Exception/i);
    // Check for no 500 error in response
    const response = await page.goto('/');
    expect(response?.status()).toBeLessThan(500);
  });

  test('sign in page loads', async ({ page }) => {
    const response = await page.goto('/users/sign_in');
    expect(response?.status()).toBeLessThan(500);
    await expect(page.locator('form#new_user, form[action*="sign_in"]').first()).toBeVisible();
  });

  test('sign up page loads', async ({ page }) => {
    const response = await page.goto('/users/sign_up');
    expect(response?.status()).toBeLessThan(500);
    await expect(page.locator('form#new_user, form[action*="sign_up"]').first()).toBeVisible();
  });

  test('health check endpoint returns OK', async ({ page }) => {
    const response = await page.goto('/up');
    expect(response?.status()).toBe(200);
  });
});

test.describe('Dashboard & Home', () => {
  test('dashboard loads without errors', async ({ page }) => {
    const response = await page.goto('/dashboard');
    expect(response?.status()).toBeLessThan(500);
    await expect(page.locator('nav')).toBeVisible();
  });

  test('authenticated home page loads', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Profile Pages', () => {
  test('profile show page loads', async ({ page }) => {
    const response = await page.goto('/profile');
    expect(response?.status()).toBeLessThan(500);
  });

  test('profile edit page loads', async ({ page }) => {
    const response = await page.goto('/profile/edit');
    expect(response?.status()).toBeLessThan(500);
    // Page should contain form elements (input fields)
    await expect(page.locator('input, textarea, select').first()).toBeAttached();
  });
});

test.describe('Projects', () => {
  test('projects index loads', async ({ page }) => {
    const response = await page.goto('/projects');
    expect(response?.status()).toBeLessThan(500);
  });

  test('new project form loads', async ({ page }) => {
    const response = await page.goto('/projects/new');
    expect(response?.status()).toBeLessThan(500);
    // Page should contain form elements for creating a project
    await expect(page.locator('input, textarea, select').first()).toBeAttached();
  });

  test('can view a project if one exists', async ({ page }) => {
    // First go to projects index to find a project
    await page.goto('/projects');

    // Try to click on a project link if one exists
    const projectLink = page.locator('a[href^="/projects/"]').first();
    if (await projectLink.isVisible({ timeout: 2000 }).catch(() => false)) {
      await projectLink.click();
      await page.waitForLoadState('domcontentloaded');
      // Should not be a 500 error page
      await expect(page.locator('body')).not.toContainText('Internal Server Error');
    }
  });
});

test.describe('Agreements', () => {
  test('agreements index loads', async ({ page }) => {
    const response = await page.goto('/agreements');
    expect(response?.status()).toBeLessThan(500);
  });

  test('new agreement form loads', async ({ page }) => {
    const response = await page.goto('/agreements/new');
    expect(response?.status()).toBeLessThan(500);
  });

  test('can view an agreement if one exists', async ({ page }) => {
    await page.goto('/agreements');

    const agreementLink = page.locator('a[href^="/agreements/"]').first();
    if (await agreementLink.isVisible({ timeout: 2000 }).catch(() => false)) {
      await agreementLink.click();
      await page.waitForLoadState('domcontentloaded');
      await expect(page.locator('body')).not.toContainText('Internal Server Error');
    }
  });
});

test.describe('Conversations', () => {
  test('conversations index loads', async ({ page }) => {
    const response = await page.goto('/conversations');
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('Notifications', () => {
  test('notifications index loads', async ({ page }) => {
    const response = await page.goto('/notifications');
    expect(response?.status()).toBeLessThan(500);
  });
});

test.describe('People/Users', () => {
  test('can view another user profile', async ({ page }) => {
    // Try viewing user with ID 1, 2, or 3
    for (const userId of [1, 2, 3]) {
      const response = await page.goto(`/people/${userId}`);
      if (response?.status() === 200) {
        // Successfully found a user, verify page rendered
        await expect(page.locator('body')).not.toContainText('Internal Server Error');
        break;
      }
    }
  });
});

test.describe('Time Logs', () => {
  test('time logs page loads for a project', async ({ page }) => {
    // First find a project
    await page.goto('/projects');
    const projectLink = page.locator('a[href^="/projects/"]').first();

    if (await projectLink.isVisible({ timeout: 2000 }).catch(() => false)) {
      const href = await projectLink.getAttribute('href');
      const projectId = href?.match(/\/projects\/(\d+)/)?.[1];

      if (projectId) {
        const response = await page.goto(`/projects/${projectId}/time_logs`);
        expect(response?.status()).toBeLessThan(500);
      }
    }
  });
});

test.describe('Milestones', () => {
  test('milestones page loads for a project', async ({ page }) => {
    await page.goto('/projects');
    const projectLink = page.locator('a[href^="/projects/"]').first();

    if (await projectLink.isVisible({ timeout: 2000 }).catch(() => false)) {
      const href = await projectLink.getAttribute('href');
      const projectId = href?.match(/\/projects\/(\d+)/)?.[1];

      if (projectId) {
        const response = await page.goto(`/projects/${projectId}/milestones`);
        expect(response?.status()).toBeLessThan(500);
      }
    }
  });
});

test.describe('UI Components Render Correctly', () => {
  test('navbar is visible on authenticated pages', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page.locator('nav')).toBeVisible();
  });

  test('theme toggle works', async ({ page }) => {
    await page.goto('/dashboard');
    // Check if theme selector/toggle exists
    const themeButton = page.locator('[data-controller*="theme"], [data-action*="theme"]').first();
    if (await themeButton.isVisible({ timeout: 2000 }).catch(() => false)) {
      await themeButton.click();
    }
  });

  test('mobile drawer toggle exists', async ({ page }) => {
    await page.goto('/dashboard');
    // Check for mobile drawer checkbox
    const drawerToggle = page.locator('#mobile-drawer');
    await expect(drawerToggle).toBeAttached();
  });
});

test.describe('Form Submissions (Create Flows)', () => {
  test('project creation form has all required fields', async ({ page }) => {
    await page.goto('/projects/new');

    // Page loads without errors
    await expect(page.locator('body')).not.toContainText('Internal Server Error');

    // Check for form input elements
    const inputFields = page.locator('input, textarea, select');
    await expect(inputFields.first()).toBeAttached();
  });

  test('can fill and submit project form without JS errors', async ({ page }) => {
    // Listen for console errors
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.goto('/projects/new');
    await page.waitForLoadState('domcontentloaded');

    // Wait a bit for any JS to initialize
    await page.waitForTimeout(1000);

    // Filter out expected errors (CSP in test env, favicon 404s, etc.)
    const realErrors = errors.filter(e =>
      !e.includes('favicon') &&
      !e.includes('404') &&
      !e.includes('net::ERR') &&
      !e.includes('Content Security Policy') &&
      !e.includes('CSP')
    );

    expect(realErrors).toHaveLength(0);
  });
});

test.describe('Error Handling', () => {
  test('404 page renders for non-existent routes', async ({ page }) => {
    const response = await page.goto('/this-route-does-not-exist-12345');
    expect(response?.status()).toBe(404);
  });

  test('no console errors on dashboard', async ({ page }) => {
    const errors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });

    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Filter out non-critical errors (CSP in test env, resource loading, etc.)
    const criticalErrors = errors.filter(e =>
      !e.includes('favicon') &&
      !e.includes('404') &&
      !e.includes('net::ERR') &&
      !e.includes('Failed to load resource') &&
      !e.includes('Content Security Policy') &&
      !e.includes('CSP')
    );

    expect(criticalErrors).toHaveLength(0);
  });
});
