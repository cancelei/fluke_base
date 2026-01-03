import { chromium } from '@playwright/test';
import { execSync } from 'child_process';

/**
 * Playwright Global Setup - Fluke_base Project
 * Runs before all tests to prepare the test environment
 *
 * Features:
 * - Seeds test data via FactoryBot (always runs for consistency)
 * - Saves authenticated session state for faster tests
 *
 * Environment Variables:
 * - RAILS_ENV: Rails environment (must be 'test')
 * - SKIP_SEED: Set to '1' to skip seeding (not recommended)
 */
export default async function globalSetup(config) {
  console.log('\n🧪 Setting up E2E test environment for Fluke_base...\n');

  const baseURL = config.projects?.[0]?.use?.baseURL || config.use?.baseURL || 'http://127.0.0.1:5010';
  const storagePath = 'tmp/playwright/auth.json';

  try {
    // Seed test data via FactoryBot (unless explicitly skipped)
    if (process.env.SKIP_SEED !== '1') {
      console.log('📦 Seeding test data with FactoryBot...');
      execSync('bundle exec rake e2e:seed_test_data', {
        cwd: process.cwd(),
        stdio: 'inherit',
        env: {
          ...process.env,
          RAILS_ENV: 'test'
        }
      });
    } else {
      console.log('⏭️  Skipping seed (SKIP_SEED=1)');
    }

    // Always save authenticated session state
    console.log('🔐 Setting up authenticated session...');
    const browser = await chromium.launch();
    const context = await browser.newContext();
    const page = await context.newPage();

    const loginUrl = new URL('/test_only/login?email=e2e@example.com', baseURL).toString();
    await page.goto(loginUrl);
    await page.waitForLoadState('domcontentloaded');

    await context.storageState({ path: storagePath });
    await browser.close();

    console.log(`✅ Auth state saved to ${storagePath}`);
    console.log('\n✅ E2E test environment ready!\n');
  } catch (error) {
    console.error('\n❌ Failed to setup E2E test environment:', error.message);
    console.error('\nMake sure the Rails server is accessible and the database is set up.');
    throw error;
  }
}

