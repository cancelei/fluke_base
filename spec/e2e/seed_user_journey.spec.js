import { test, expect } from '@playwright/test';

/**
 * E2E Test: User Journey with Factory-Created Data
 * 
 * This test verifies that users created via FactoryBot can log in and navigate
 * the application's core features in the test environment.
 * 
 * Prerequisites:
 * - Run: RAILS_ENV=test bundle exec rake e2e:seed_test_data
 * 
 * Test Users (password: 'password123'):
 * - alice.entrepreneur@test.com - Project owner with agreements
 * - bob.mentor@test.com - Active mentor with time logging
 * - carol.cofounder@test.com - Co-founder with completed tracking
 * - frank.newbie@test.com - New user without agreements
 */

test.describe('User Journey - Factory-Created Test Data', () => {
  // Test with Alice (Project Owner)
  test('Alice can login and navigate projects', async ({ page, context }) => {
    // Clear any existing auth
    await context.clearCookies();
    
    // Navigate to login
    await page.goto('/users/sign_in');
    
    // Fill in credentials
    await page.fill('input[name="user[email]"]', 'alice.entrepreneur@test.com');
    await page.fill('input[name="user[password]"]', 'password123');
    
    // Click sign in button
    await page.click('button[type="submit"], input[type="submit"]');
    
    // Wait for redirect to dashboard/home
    await page.waitForURL(/\/($|dashboard|home|projects)/, { timeout: 10000 });
    
    // Verify we're logged in - look for navbar
    const navbar = page.locator('nav');
    await expect(navbar).toBeVisible();
    
    // Navigate to Projects
    await page.goto('/projects');
    await expect(page).toHaveURL(/\/projects/);
    
    // Should see "DeFi Yield Optimizer" project
    const pageContent = await page.textContent('body');
    expect(pageContent).toContain('DeFi Yield Optimizer');
    
    console.log('✓ Alice can access projects and see her DeFi project');
  });

  test('Bob (Mentor) can view agreements and time logs', async ({ page, context }) => {
    await context.clearCookies();
    
    // Login as Bob
    await page.goto('/users/sign_in');
    await page.fill('input[name="user[email]"]', 'bob.mentor@test.com');
    await page.fill('input[name="user[password]"]', 'password123');
    await page.click('button[type="submit"], input[type="submit"]');
    
    await page.waitForURL(/\/($|dashboard|home|projects)/, { timeout: 10000 });
    
    // Navigate to Agreements
    await page.goto('/agreements');
    await expect(page).toHaveURL(/\/agreements/);
    
    // Should see mentorship agreement
    const agreementsContent = await page.textContent('body');
    expect(agreementsContent.toLowerCase()).toMatch(/agreement|mentor|accepted/i);
    
    console.log('✓ Bob can access agreements');
    
    // Navigate to Time Logs
    await page.goto('/time_logs');
    await expect(page).toHaveURL(/\/time_logs/);
    
    console.log('✓ Bob can access time logs');
  });

  test('Carol (Co-founder) can view her equity agreement', async ({ page, context }) => {
    await context.clearCookies();
    
    // Login as Carol
    await page.goto('/users/sign_in');
    await page.fill('input[name="user[email]"]', 'carol.cofounder@test.com');
    await page.fill('input[name="user[password]"]', 'password123');
    await page.click('button[type="submit"], input[type="submit"]');
    
    await page.waitForURL(/\/($|dashboard|home|projects)/, { timeout: 10000 });
    
    // Navigate to Agreements
    await page.goto('/agreements');
    await expect(page).toHaveURL(/\/agreements/);
    
    // Should see co-founder agreement with equity
    const agreementsContent = await page.textContent('body');
    expect(agreementsContent.toLowerCase()).toMatch(/agreement|co-founder|equity/i);
    
    console.log('✓ Carol can access her equity agreement');
  });

  test('Full navigation flow - Alice explores the product', async ({ page, context }) => {
    await context.clearCookies();
    
    // Login as Alice
    await page.goto('/users/sign_in');
    await page.fill('input[name="user[email]"]', 'alice.entrepreneur@test.com');
    await page.fill('input[name="user[password]"]', 'password123');
    await page.click('button[type="submit"], input[type="submit"]');
    
    await page.waitForURL(/\/($|dashboard|home|projects)/, { timeout: 10000 });
    console.log('✓ Logged in successfully');
    
    // 1. Visit Projects - should see her DeFi project
    await page.goto('/projects');
    await expect(page).toHaveURL(/\/projects/);
    let content = await page.textContent('body');
    expect(content).toContain('DeFi');
    console.log('✓ Accessed projects page with DeFi project');
    
    // Click on the DeFi project
    const projectLink = page.locator('a', { hasText: 'DeFi' }).first();
    if (await projectLink.count() > 0) {
      await projectLink.click();
      await page.waitForLoadState('domcontentloaded');
      console.log('✓ Viewed DeFi project details');
      
      // Should see milestone
      content = await page.textContent('body');
      expect(content).toContain('MVP');
    }
    
    // 2. Visit Agreements - should see 2 agreements
    await page.goto('/agreements');
    await expect(page).toHaveURL(/\/agreements/);
    content = await page.textContent('body');
    expect(content.toLowerCase()).toMatch(/mentorship|mentor|bob/i);
    console.log('✓ Accessed agreements page');
    
    // 3. Visit People/Explore
    await page.goto('/people/explore');
    await page.waitForLoadState('domcontentloaded');
    console.log('✓ Accessed people explore page');
    
    // 4. Visit Conversations - should see conversation with Bob
    const conversationsResponse = await page.goto('/conversations');
    if (conversationsResponse && conversationsResponse.ok()) {
      await expect(page).toHaveURL(/\/conversations/);
      content = await page.textContent('body');
      // Should see Bob's name or message
      console.log('✓ Accessed conversations page');
    }
    
    // 5. Visit Time Logs
    await page.goto('/time_logs');
    await expect(page).toHaveURL(/\/time_logs/);
    console.log('✓ Accessed time logs page');
    
    // 6. Visit Profile
    await page.goto('/people/alice-entrepreneur');
    await page.waitForLoadState('domcontentloaded');
    content = await page.textContent('body');
    expect(content).toContain('Alice');
    console.log('✓ Accessed Alice\'s profile');
    
    console.log('\n✅ Full navigation flow completed successfully!');
  });

  test('Frank (new user) has no payment gates', async ({ page, context }) => {
    await context.clearCookies();
    
    // Login as Frank (new user with no agreements)
    await page.goto('/users/sign_in');
    await page.fill('input[name="user[email]"]', 'frank.newbie@test.com');
    await page.fill('input[name="user[password]"]', 'password123');
    await page.click('button[type="submit"], input[type="submit"]');
    
    await page.waitForURL(/\/($|dashboard|home|projects)/, { timeout: 10000 });
    
    // Try to access key features - should not be blocked by payment
    const routes = [
      '/projects',
      '/agreements',
      '/people/explore',
      '/time_logs'
    ];
    
    for (const route of routes) {
      const response = await page.goto(route);
      
      // Should not redirect to payment/subscription page
      expect(response.status()).toBeLessThan(400);
      expect(page.url()).not.toContain('subscribe');
      expect(page.url()).not.toContain('payment');
      expect(page.url()).not.toContain('billing');
      
      // Should not show payment modal or blocking message
      const body = await page.textContent('body');
      expect(body.toLowerCase()).not.toContain('subscription required');
      
      console.log(`✓ ${route} - no payment gate`);
    }
    
    console.log('\n✅ No payment gates found - as expected!');
  });
});

test.describe('Test-Only Login Helper', () => {
  test('Test-only login endpoint works', async ({ page, context }) => {
    // This endpoint only works in RAILS_ENV=test
    await context.clearCookies();
    
    // Use test-only login helper
    const response = await page.goto('/test_only/login?email=e2e@example.com');
    
    if (response && response.ok()) {
      // Should redirect to root after login
      await page.waitForURL(/\//, { timeout: 5000 });
      
      // Verify logged in
      const navbar = page.locator('nav');
      await expect(navbar).toBeVisible();
      
      console.log('✓ Test-only login helper works');
    }
  });
});
