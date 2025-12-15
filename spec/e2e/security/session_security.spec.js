import { test, expect } from '../fixtures/test-base.js';

/**
 * Session Security Tests
 *
 * These tests verify proper session handling and security measures.
 */
test.describe('Session Security', () => {
  test.describe('Session Validity', () => {
    test('Unauthenticated user is redirected to login', async ({ page }) => {
      // Don't login, just try to access protected route
      await page.goto('/dashboard');

      // Should redirect to login
      expect(page.url()).toContain('/sign_in');
    });

    test('Unauthenticated user cannot access projects', async ({ page }) => {
      await page.goto('/projects');

      // Should redirect to login
      expect(page.url()).toContain('/sign_in');
    });

    test('Unauthenticated user cannot access people directory', async ({ page }) => {
      await page.goto('/people/explore');

      // Should redirect to login
      expect(page.url()).toContain('/sign_in');
    });
  });

  test.describe('Logout Behavior', () => {
    test('Session is invalidated on logout', async ({ page, login }) => {
      // Login
      await login('session_test@example.com');

      // Verify logged in
      await page.goto('/dashboard');
      expect(page.url()).not.toContain('/sign_in');

      // Logout
      const logoutButton = page.locator('[data-testid="logout-button"]');
      if (await logoutButton.count() > 0) {
        await logoutButton.click();
      } else {
        // Try to find logout in dropdown
        const userMenu = page.locator('[data-testid="user-menu"]');
        if (await userMenu.count() > 0) {
          await userMenu.click();
          await page.click('text=Sign out');
        }
      }

      // Wait for navigation
      await page.waitForLoadState('networkidle');

      // Try to access protected route
      await page.goto('/dashboard');

      // Should be redirected to login
      expect(page.url()).toContain('/sign_in');
    });
  });

  test.describe('Session Isolation', () => {
    test('Different browser contexts have isolated sessions', async ({ browser }) => {
      // Create two separate browser contexts
      const contextA = await browser.newContext();
      const contextB = await browser.newContext();

      const pageA = await contextA.newPage();
      const pageB = await contextB.newPage();

      // Login user A in context A
      await pageA.goto('/test_only/login?email=user_a@example.com');

      // Login user B in context B
      await pageB.goto('/test_only/login?email=user_b@example.com');

      // Both should be logged in
      await pageA.goto('/dashboard');
      await pageB.goto('/dashboard');

      expect(pageA.url()).not.toContain('/sign_in');
      expect(pageB.url()).not.toContain('/sign_in');

      // Verify they see their own data (user names in navigation)
      const userMenuA = await pageA.locator('[data-testid="user-name"]').textContent();
      const userMenuB = await pageB.locator('[data-testid="user-name"]').textContent();

      // They should show different user info
      expect(userMenuA).not.toBe(userMenuB);

      await contextA.close();
      await contextB.close();
    });
  });

  test.describe('CSRF Protection', () => {
    test('Forms include CSRF token', async ({ page, login }) => {
      await login();

      // Go to a page with a form
      await page.goto('/projects/new');

      // Check for CSRF token in form
      const csrfInput = page.locator('input[name="authenticity_token"]');
      const csrfCount = await csrfInput.count();

      expect(csrfCount).toBeGreaterThan(0);

      // Verify token has a value
      if (csrfCount > 0) {
        const token = await csrfInput.first().getAttribute('value');
        expect(token).toBeTruthy();
        expect(token.length).toBeGreaterThan(10);
      }
    });
  });

  test.describe('Cookie Security', () => {
    test('Session cookie has secure attributes in production-like setting', async ({ page, login }) => {
      await login();

      // Get cookies
      const cookies = await page.context().cookies();
      const sessionCookie = cookies.find(c => c.name.includes('_session'));

      if (sessionCookie) {
        // HttpOnly should be set to prevent XSS access
        expect(sessionCookie.httpOnly).toBeTruthy();

        // In production, SameSite should be set
        // (might be Lax or Strict depending on config)
        // Just verify it's not None
        expect(sessionCookie.sameSite).not.toBe('None');
      }
    });
  });
});
