/**
 * Cloudflare Browser Rendering Client
 *
 * Client library for calling the FlukeBase browser-tests worker API.
 * Used when USE_CF_BROWSER=1 to delegate browser automation to Cloudflare.
 */

const DEFAULT_WORKER_URL = process.env.CF_BROWSER_WORKER_URL || 'http://localhost:8787';
const WORKER_AUTH_TOKEN = process.env.CF_BROWSER_AUTH_TOKEN || '';

/**
 * CloudflareBrowserClient - API client for browser-tests worker
 */
class CloudflareBrowserClient {
  constructor(options = {}) {
    this.baseUrl = options.workerUrl || DEFAULT_WORKER_URL;
    this.authToken = options.authToken || WORKER_AUTH_TOKEN;
    this.timeout = options.timeout || 30000;
  }

  /**
   * Make authenticated request to worker
   */
  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}${endpoint}`;
    const headers = {
      'Content-Type': 'application/json',
      ...(this.authToken && { 'Authorization': `Bearer ${this.authToken}` }),
      ...options.headers
    };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeout);

    try {
      const response = await fetch(url, {
        method: options.method || 'GET',
        headers,
        body: options.body ? JSON.stringify(options.body) : undefined,
        signal: controller.signal
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: response.statusText }));
        throw new Error(`Worker request failed: ${error.error || response.statusText}`);
      }

      // Handle binary responses (screenshots)
      const contentType = response.headers.get('content-type');
      if (contentType?.includes('image/')) {
        return {
          type: 'image',
          data: await response.arrayBuffer(),
          contentType
        };
      }

      return await response.json();
    } catch (error) {
      clearTimeout(timeoutId);
      if (error.name === 'AbortError') {
        throw new Error(`Worker request timed out after ${this.timeout}ms`);
      }
      throw error;
    }
  }

  // ============================================================================
  // Health & Status
  // ============================================================================

  async health() {
    return this.request('/health');
  }

  async sessions() {
    return this.request('/sessions');
  }

  async limits() {
    return this.request('/limits');
  }

  // ============================================================================
  // Screenshot
  // ============================================================================

  async screenshot(url, options = {}) {
    const params = new URLSearchParams();
    if (url) params.set('url', url);
    if (options.fullPage) params.set('fullPage', 'true');

    return this.request(`/screenshot?${params.toString()}`);
  }

  // ============================================================================
  // Test Endpoints
  // ============================================================================

  async testLogin() {
    return this.request('/test/login', { method: 'POST' });
  }

  async testOAuthRedirect() {
    return this.request('/test/oauth-redirect', { method: 'POST' });
  }

  async testSignupPage() {
    return this.request('/test/signup-page', { method: 'POST' });
  }

  async testDashboard() {
    return this.request('/test/dashboard', { method: 'POST' });
  }

  // Extended test endpoints (to be added to worker)
  async testSmoke(options = {}) {
    return this.request('/test/smoke', {
      method: 'POST',
      body: options
    });
  }

  async testFormSubmission(formType, data = {}) {
    return this.request(`/test/form/${formType}`, {
      method: 'POST',
      body: data
    });
  }

  async testSecurityCheck(checkType) {
    return this.request(`/test/security/${checkType}`, { method: 'POST' });
  }

  async testUserJourney(userEmail) {
    return this.request('/test/user-journey', {
      method: 'POST',
      body: { email: userEmail }
    });
  }

  // ============================================================================
  // Custom Test Execution
  // ============================================================================

  /**
   * Execute arbitrary test script on worker
   * @param {string} script - Playwright script to execute
   * @param {object} context - Variables to pass to script
   */
  async executeTest(script, context = {}) {
    return this.request('/test/execute', {
      method: 'POST',
      body: { script, context }
    });
  }

  /**
   * Run a predefined test suite
   * @param {string} suiteName - Name of test suite (smoke, security, forms, journey)
   * @param {object} options - Suite-specific options
   */
  async runSuite(suiteName, options = {}) {
    return this.request(`/test/suite/${suiteName}`, {
      method: 'POST',
      body: options
    });
  }
}

/**
 * Test result helper - formats worker response for Playwright assertions
 */
function formatTestResults(workerResponse) {
  const { test, passed, results, screenshotBase64, finalUrl } = workerResponse;

  return {
    testName: test,
    passed,
    results: results.map(r => ({
      name: r.name,
      passed: r.passed,
      message: r.message || ''
    })),
    screenshot: screenshotBase64 ? Buffer.from(screenshotBase64, 'base64') : null,
    finalUrl
  };
}

/**
 * Create assertion helpers for Playwright test integration
 */
function createAssertions(expect) {
  return {
    /**
     * Assert all test results passed
     */
    expectAllPassed(workerResponse) {
      const formatted = formatTestResults(workerResponse);
      const failures = formatted.results.filter(r => !r.passed);

      if (failures.length > 0) {
        const failureMessages = failures.map(f => `  - ${f.name}: ${f.message}`).join('\n');
        throw new Error(`Test "${formatted.testName}" had ${failures.length} failures:\n${failureMessages}`);
      }

      return formatted;
    },

    /**
     * Assert specific test result passed
     */
    expectTestPassed(workerResponse, testName) {
      const formatted = formatTestResults(workerResponse);
      const result = formatted.results.find(r => r.name === testName);

      if (!result) {
        throw new Error(`Test "${testName}" not found in results`);
      }

      if (!result.passed) {
        throw new Error(`Test "${testName}" failed: ${result.message}`);
      }

      return result;
    }
  };
}

/**
 * Check if Cloudflare Browser should be used
 */
function shouldUseCloudflare() {
  return process.env.USE_CF_BROWSER === '1' || process.env.USE_CF_BROWSER === 'true';
}

/**
 * Get configured client instance
 */
function getClient(options = {}) {
  return new CloudflareBrowserClient({
    workerUrl: process.env.CF_BROWSER_WORKER_URL,
    authToken: process.env.CF_BROWSER_AUTH_TOKEN,
    ...options
  });
}

module.exports = {
  CloudflareBrowserClient,
  formatTestResults,
  createAssertions,
  shouldUseCloudflare,
  getClient,
  DEFAULT_WORKER_URL
};
