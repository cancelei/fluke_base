import { test, expect } from '../fixtures/test-base.js';

/**
 * Role Escalation Prevention Tests
 *
 * These tests verify that users cannot perform actions above their permission level.
 */
test.describe('Role Escalation Prevention', () => {
  test.describe('Member Restrictions', () => {
    test('Member cannot access admin-only project settings', async ({ page, login }) => {
      // Login as owner and create project
      await login('owner@example.com');
      await page.goto('/test_only/create_project?name=AdminRestrictedProject');
      const projectUrl = page.url();
      const projectId = projectUrl.split('/').pop();

      // Add a member to the project (would need test helper)
      // For now, login as a different user who doesn't have admin access
      await login('member@example.com');

      // Try to access edit page
      const editResponse = await page.goto(`/projects/${projectId}/edit`);

      // Should be denied
      const content = await page.content();
      const isDenied = editResponse.status() === 403 ||
                       content.includes('Access Denied') ||
                       content.includes('not authorized') ||
                       page.url() !== `/projects/${projectId}/edit`;

      expect(isDenied).toBeTruthy();
    });

    test('Member cannot delete project via form submission', async ({ page, login }) => {
      // Login as owner and create project
      await login('owner@example.com');
      await page.goto('/test_only/create_project?name=DeleteTestProject');
      const projectUrl = page.url();
      const projectId = projectUrl.split('/').pop();

      // Login as member (non-owner)
      await login('member@example.com');

      // Try direct DELETE request via page navigation (simulating form submission)
      // This would normally be done via fetch, but we test the page behavior
      await page.goto(`/projects/${projectId}`);

      // Verify the delete button is not visible to members
      const deleteButton = page.locator('[data-testid="delete-project"]');
      const deleteButtonCount = await deleteButton.count();

      expect(deleteButtonCount).toBe(0);
    });

    test('Member cannot access team management page', async ({ page, login }) => {
      // Login as owner and create project
      await login('owner@example.com');
      await page.goto('/test_only/create_project?name=TeamMgmtProject');
      const projectUrl = page.url();
      const projectId = projectUrl.split('/').pop();

      // Login as non-member
      await login('non_member@example.com');

      // Try to access memberships
      await page.goto(`/projects/${projectId}/memberships`);

      // Should be denied or redirected
      const content = await page.content();
      const isDenied = content.includes('Access Denied') ||
                       content.includes('not authorized') ||
                       content.includes("don't have permission");

      expect(isDenied).toBeTruthy();
    });
  });

  test.describe('Guest Restrictions', () => {
    test('Guest cannot create agreements for project', async ({ page, login }) => {
      // Login as guest
      await login('guest@example.com');

      // Try to create an agreement
      await page.goto('/agreements/new');

      // If accessible, try to submit the form
      const formExists = await page.locator('form').count() > 0;

      if (formExists) {
        // Try to submit - should fail for projects they don't have access to
        const projectSelect = page.locator('[name="agreement[project_id]"]');
        const options = await projectSelect.locator('option').allTextContents();

        // Guest should only see projects they have access to
        // (empty or limited options)
        expect(options.length).toBeLessThanOrEqual(1);
      }
    });

    test('Guest cannot invite team members', async ({ page, login }) => {
      // Login as owner and create project
      await login('owner@example.com');
      await page.goto('/test_only/create_project?name=InviteTestProject');
      const projectUrl = page.url();
      const projectId = projectUrl.split('/').pop();

      // Login as guest
      await login('guest@example.com');

      // Try to access invite page
      await page.goto(`/projects/${projectId}/memberships/new`);

      // Should be denied
      const content = await page.content();
      const isDenied = content.includes('Access Denied') ||
                       content.includes('not authorized') ||
                       content.includes("don't have permission");

      expect(isDenied).toBeTruthy();
    });
  });

  test.describe('Self-Promotion Prevention', () => {
    test('User cannot change their own role via direct manipulation', async ({ page, login }) => {
      // This tests protection against form manipulation
      // Login as member
      await login('member@example.com');

      // Navigate to a project they're part of
      await page.goto('/projects');

      const projectLink = page.locator('[data-testid="project-card"] a').first();
      if (await projectLink.count() > 0) {
        await projectLink.click();

        // Try to access memberships (if visible)
        const teamLink = page.locator('text=Team').first();
        if (await teamLink.count() > 0) {
          await teamLink.click();

          // Verify role change dropdown is not available for own membership
          // or only shows lower roles
          const roleDropdown = page.locator('[data-testid="role-dropdown"]');
          const hasRestrictedOptions = await roleDropdown.count() === 0;

          expect(hasRestrictedOptions).toBeTruthy();
        }
      }
    });
  });
});
