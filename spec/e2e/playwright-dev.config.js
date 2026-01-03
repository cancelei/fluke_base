import { defineConfig } from '@playwright/test';

/**
 * Playwright configuration for development environment testing
 *
 * This config is used to test against the development server with real seed data.
 * Unlike the main config which uses test environment, this uses development.
 *
 * For secure connection testing (OAuth, Turnstile, etc.), use:
 *   PLAYWRIGHT_BASE_URL=https://dev.flukebase.me npx playwright test --config spec/e2e/playwright-dev.config.js
 *
 * Standard URL pattern: dev-{projectName} → dev.flukebase.me
 */

export default defineConfig({
  testDir: 'spec/e2e',
  timeout: 30_000,
  retries: 0, // No retries in dev testing
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'playwright-report-dev' }]],
  use: {
    // Default to secure dev URL, fallback to localhost for quick local testing
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'https://dev.flukebase.me',
    headless: true,
    trace: 'on-first-retry',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
    // Accept self-signed certs for tunnel/local HTTPS
    ignoreHTTPSErrors: true
  },
  // No global setup or web server - assumes dev server is already running
  projects: [
    {
      name: 'chromium',
      use: {
        viewport: { width: 1280, height: 720 }
      }
    }
  ]
});
