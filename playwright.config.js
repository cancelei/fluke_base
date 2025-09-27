import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: 'spec/e2e',
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  reporter: [ ['list'], ['html', { open: 'never' }] ],
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://127.0.0.1:5010',
    headless: true,
    trace: 'on-first-retry',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure'
  },
  // Log in once and reuse auth state for faster authenticated tests
  globalSetup: 'spec/e2e/setup/global-setup.js',
  webServer: {
    command: 'bin/rails server -e test -p 5010',
    url: 'http://127.0.0.1:5010',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: {
      RAILS_ENV: 'test',
      E2E_COVERAGE: process.env.E2E_COVERAGE ? '1' : undefined
    }
  }
});
