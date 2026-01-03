/**
 * Cloudflare Browser Rendering Test Fixture
 *
 * Hybrid fixture that supports both local Playwright and Cloudflare Worker modes.
 * When USE_CF_BROWSER=1, tests delegate browser operations to the worker.
 */

import { test as base, expect } from '@playwright/test';
import {
  CloudflareBrowserClient,
  shouldUseCloudflare,
  formatTestResults,
  createAssertions
} from '../helpers/cloudflare-browser.js';

// Determine mode from environment
const useCloudflare = shouldUseCloudflare();

/**
 * Extended test fixture with Cloudflare support
 */
export const test = base.extend({
  /**
   * Cloudflare client - available in CF mode
   */
  cfClient: async ({}, use) => {
    if (useCloudflare) {
      const client = new CloudflareBrowserClient({
        workerUrl: process.env.CF_BROWSER_WORKER_URL,
        authToken: process.env.CF_BROWSER_AUTH_TOKEN,
        timeout: 45000
      });
      await use(client);
    } else {
      await use(null);
    }
  },

  /**
   * Login helper - works in both modes
   */
  login: async ({ page, cfClient }, use) => {
    if (useCloudflare && cfClient) {
      // In CF mode, login is handled by worker tests
      await use(async (email = 'e2e@example.com') => {
        // Worker handles auth internally via test-only endpoints
        console.log(`[CF Mode] Login for ${email} handled by worker`);
      });
    } else {
      // Local mode - use test-only endpoint
      await page.goto('/test_only/login?email=e2e@example.com');
      await page.waitForLoadState('domcontentloaded');
      await use(async (email = 'e2e@example.com') => {
        await page.goto(`/test_only/login?email=${encodeURIComponent(email)}`);
        await page.waitForLoadState('domcontentloaded');
      });
    }
  },

  /**
   * Screenshot helper - uses worker in CF mode
   */
  takeScreenshot: async ({ page, cfClient }, use) => {
    await use(async (url, options = {}) => {
      if (useCloudflare && cfClient) {
        const result = await cfClient.screenshot(url, options);
        return result.data;
      } else {
        if (url) await page.goto(url);
        return await page.screenshot(options);
      }
    });
  },

  /**
   * Run predefined test on worker
   */
  runWorkerTest: async ({ cfClient }, use) => {
    await use(async (testName, options = {}) => {
      if (!cfClient) {
        throw new Error('runWorkerTest requires USE_CF_BROWSER=1');
      }

      const testMethods = {
        'login': () => cfClient.testLogin(),
        'oauth-redirect': () => cfClient.testOAuthRedirect(),
        'signup-page': () => cfClient.testSignupPage(),
        'dashboard': () => cfClient.testDashboard(),
        'smoke': () => cfClient.testSmoke(options),
        'user-journey': () => cfClient.testUserJourney(options.email)
      };

      const method = testMethods[testName];
      if (!method) {
        throw new Error(`Unknown worker test: ${testName}`);
      }

      return method();
    });
  },

  /**
   * Assertion helpers for worker responses
   */
  cfAssertions: async ({}, use) => {
    await use(createAssertions(expect));
  },

  /**
   * Mode indicator
   */
  isCloudflareMode: async ({}, use) => {
    await use(useCloudflare);
  }
});

/**
 * Decorator to skip test in Cloudflare mode
 * Use when test requires local-only features (e.g., direct DB access)
 */
export function skipInCloudflareMode(testFn) {
  return async (args) => {
    if (useCloudflare) {
      test.skip(true, 'Test not supported in Cloudflare mode');
      return;
    }
    return testFn(args);
  };
}

/**
 * Decorator to only run test in Cloudflare mode
 * Use for worker-specific integration tests
 */
export function cloudflareOnly(testFn) {
  return async (args) => {
    if (!useCloudflare) {
      test.skip(true, 'Test only runs in Cloudflare mode');
      return;
    }
    return testFn(args);
  };
}

/**
 * Helper to create hybrid tests that work in both modes
 *
 * @example
 * test('login page renders', hybridTest({
 *   local: async ({ page }) => {
 *     await page.goto('/users/sign_in');
 *     await expect(page.locator('h2')).toBeVisible();
 *   },
 *   cloudflare: async ({ cfClient, cfAssertions }) => {
 *     const result = await cfClient.testLogin();
 *     cfAssertions.expectAllPassed(result);
 *   }
 * }));
 */
export function hybridTest({ local, cloudflare }) {
  return async (args) => {
    if (useCloudflare && cloudflare) {
      return cloudflare(args);
    } else if (!useCloudflare && local) {
      return local(args);
    } else {
      throw new Error('No handler for current mode');
    }
  };
}

export { expect };
