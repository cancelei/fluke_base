import { defineConfig } from '@playwright/test';

/**
 * Cloudflare Browser Rendering Configuration
 *
 * Set USE_CF_BROWSER=1 to use Cloudflare Workers for browser automation.
 * This delegates Playwright execution to the browser-tests worker.
 *
 * Environment Variables:
 *   USE_CF_BROWSER=1           - Enable Cloudflare Browser mode
 *   CF_BROWSER_WORKER_URL      - Worker URL (default: http://localhost:8787)
 *   CF_BROWSER_AUTH_TOKEN      - Optional auth token for worker
 */
const useCloudflare = process.env.USE_CF_BROWSER === '1' || process.env.USE_CF_BROWSER === 'true';
const cfWorkerUrl = process.env.CF_BROWSER_WORKER_URL || 'http://localhost:8787';

// When using Cloudflare, we target the dev environment by default
const baseURL = useCloudflare
  ? (process.env.PLAYWRIGHT_BASE_URL || 'https://dev.flukebase.me')
  : (process.env.PLAYWRIGHT_BASE_URL || 'http://127.0.0.1:5010');

export default defineConfig({
  testDir: 'spec/e2e',
  timeout: useCloudflare ? 60_000 : 30_000, // Longer timeout for remote browser
  retries: process.env.CI ? 2 : 0,
  reporter: [['list'], ['html', { open: 'never' }]],

  // Global metadata for test fixtures
  metadata: {
    useCloudflare,
    cfWorkerUrl,
    baseURL
  },

  use: {
    baseURL,
    headless: true,
    trace: 'on-first-retry',
    video: useCloudflare ? 'off' : 'retain-on-failure', // Videos not available in CF mode
    screenshot: 'only-on-failure',
    // Accept self-signed certs when testing against dev tunnel
    ignoreHTTPSErrors: useCloudflare || baseURL.includes('dev.flukebase')
  },

  // Log in once and reuse auth state for faster authenticated tests
  globalSetup: useCloudflare ? undefined : 'spec/e2e/setup/global-setup.js',

  // Only start local server when not using Cloudflare
  webServer: useCloudflare
    ? undefined
    : {
        command: 'bin/rails server -e test -p 5010',
        url: 'http://127.0.0.1:5010',
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
        env: {
          RAILS_ENV: 'test',
          E2E_COVERAGE: process.env.E2E_COVERAGE ? '1' : undefined
        }
      },

  // Projects configuration
  projects: [
    {
      name: useCloudflare ? 'cloudflare' : 'chromium',
      use: {
        viewport: { width: 1280, height: 720 }
      }
    }
  ]
});
