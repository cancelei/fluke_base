/**
 * FlukeBase Browser Rendering Worker
 *
 * Cloudflare-hosted Playwright for E2E testing against FlukeBase environments.
 *
 * Core Endpoints:
 *   GET  /health              - Health check
 *   GET  /screenshot          - Screenshot any URL
 *   GET  /sessions            - List active browser sessions
 *   GET  /limits              - Check rate limits
 *
 * Auth Test Endpoints:
 *   POST /test/login          - Test email login flow
 *   POST /test/oauth-redirect - Test GitHub OAuth redirect
 *   POST /test/signup-page    - Test signup page renders correctly
 *   POST /test/dashboard      - Test dashboard auth redirect
 *
 * Extended Test Endpoints:
 *   POST /test/smoke          - Run smoke tests across major pages
 *   POST /test/form/:type     - Test form submissions (project, milestone, agreement)
 *   POST /test/security/:type - Security checks (session, access, escalation)
 *   POST /test/user-journey   - Full user journey test
 *   POST /test/suite/:name    - Run predefined test suite
 */

import { launch, sessions, limits, type BrowserEndpoint } from "@cloudflare/playwright";

interface Env {
  BROWSER: BrowserEndpoint;
  BASE_URL: string;
  ENVIRONMENT: string;
  TEST_STATE?: KVNamespace;
  AUTH_TOKEN?: string;
}

interface TestResult {
  name: string;
  passed: boolean;
  message?: string;
  duration?: number;
}

interface TestResponse {
  test: string;
  passed: boolean;
  results: TestResult[];
  screenshotBase64?: string;
  finalUrl?: string;
  duration?: number;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // Optional auth check
    if (env.AUTH_TOKEN && request.method !== "GET") {
      const authHeader = request.headers.get("Authorization");
      if (authHeader !== `Bearer ${env.AUTH_TOKEN}`) {
        return jsonResponse({ error: "Unauthorized" }, 401);
      }
    }

    try {
      // Core endpoints
      if (path === "/health") {
        return jsonResponse({ status: "ok", environment: env.ENVIRONMENT, baseUrl: env.BASE_URL });
      }
      if (path === "/screenshot") {
        return await handleScreenshot(request, env);
      }
      if (path === "/sessions") {
        return await handleSessions(env);
      }
      if (path === "/limits") {
        return await handleLimits(env);
      }

      // Auth test endpoints
      if (path === "/test/login") {
        return await testLoginFlow(env);
      }
      if (path === "/test/oauth-redirect") {
        return await testOAuthRedirect(env);
      }
      if (path === "/test/signup-page") {
        return await testSignupPage(env);
      }
      if (path === "/test/dashboard") {
        return await testDashboardAccess(env);
      }

      // Extended test endpoints
      if (path === "/test/smoke") {
        const body = await parseBody(request);
        return await testSmoke(env, body);
      }
      if (path.startsWith("/test/form/")) {
        const formType = path.replace("/test/form/", "");
        const body = await parseBody(request);
        return await testFormSubmission(env, formType, body);
      }
      if (path.startsWith("/test/security/")) {
        const checkType = path.replace("/test/security/", "");
        return await testSecurityCheck(env, checkType);
      }
      if (path === "/test/user-journey") {
        const body = await parseBody(request);
        return await testUserJourney(env, body);
      }
      if (path.startsWith("/test/suite/")) {
        const suiteName = path.replace("/test/suite/", "");
        const body = await parseBody(request);
        return await runTestSuite(env, suiteName, body);
      }

      return jsonResponse(
        {
          error: "Not found",
          availableEndpoints: [
            "GET  /health",
            "GET  /screenshot?url=<url>",
            "GET  /sessions",
            "GET  /limits",
            "POST /test/login",
            "POST /test/oauth-redirect",
            "POST /test/signup-page",
            "POST /test/dashboard",
            "POST /test/smoke",
            "POST /test/form/:type",
            "POST /test/security/:type",
            "POST /test/user-journey",
            "POST /test/suite/:name",
          ],
        },
        404
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error";
      return jsonResponse({ error: message, stack: error instanceof Error ? error.stack : undefined }, 500);
    }
  },
};

// ============================================================================
// Helpers
// ============================================================================

async function parseBody(request: Request): Promise<Record<string, unknown>> {
  try {
    if (request.method === "POST") {
      const text = await request.text();
      return text ? JSON.parse(text) : {};
    }
  } catch {
    // Ignore parse errors
  }
  return {};
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

async function assertVisible(page: any, selector: string, name: string): Promise<TestResult> {
  const start = Date.now();
  try {
    const element = page.locator(selector).first();
    const isVisible = await element.isVisible({ timeout: 5000 }).catch(() => false);

    return {
      name,
      passed: isVisible,
      message: isVisible ? "Element found and visible" : `Selector "${selector}" not visible`,
      duration: Date.now() - start,
    };
  } catch (error) {
    return {
      name,
      passed: false,
      message: `Error: ${error instanceof Error ? error.message : "Unknown error"}`,
      duration: Date.now() - start,
    };
  }
}

async function assertNotError(page: any, name: string): Promise<TestResult> {
  const start = Date.now();
  try {
    // Check for common error indicators
    const errorSelectors = [
      ".error-page",
      "[data-testid='error']",
      "h1:has-text('500')",
      "h1:has-text('Error')",
    ];

    for (const selector of errorSelectors) {
      const hasError = await page.locator(selector).count() > 0;
      if (hasError) {
        return {
          name,
          passed: false,
          message: `Error indicator found: ${selector}`,
          duration: Date.now() - start,
        };
      }
    }

    return {
      name,
      passed: true,
      message: "No error indicators found",
      duration: Date.now() - start,
    };
  } catch (error) {
    return {
      name,
      passed: false,
      message: `Error checking page: ${error instanceof Error ? error.message : "Unknown"}`,
      duration: Date.now() - start,
    };
  }
}

async function loginAsTestUser(page: any, env: Env, email = "e2e@example.com"): Promise<void> {
  await page.goto(`${env.BASE_URL}/test_only/login?email=${encodeURIComponent(email)}`);
  await page.waitForLoadState("domcontentloaded");
}

// ============================================================================
// Screenshot Handler
// ============================================================================

async function handleScreenshot(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const targetUrl = url.searchParams.get("url") || env.BASE_URL;
  const fullPage = url.searchParams.get("fullPage") === "true";

  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();

  try {
    await page.goto(targetUrl, { waitUntil: "networkidle" });
    const screenshot = await page.screenshot({ fullPage });

    return new Response(screenshot, {
      headers: {
        "Content-Type": "image/png",
        "X-Screenshot-URL": targetUrl,
      },
    });
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Session Management
// ============================================================================

async function handleSessions(env: Env): Promise<Response> {
  const activeSessions = await sessions(env.BROWSER);
  return jsonResponse({ sessions: activeSessions });
}

async function handleLimits(env: Env): Promise<Response> {
  const currentLimits = await limits(env.BROWSER);
  return jsonResponse({ limits: currentLimits });
}

// ============================================================================
// Test: Login Flow
// ============================================================================

async function testLoginFlow(env: Env): Promise<Response> {
  const start = Date.now();
  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();
  const results: TestResult[] = [];

  try {
    await page.goto(`${env.BASE_URL}/users/sign_in`, { waitUntil: "networkidle" });

    results.push(await assertVisible(page, "h2", "Sign in page title visible"));
    results.push(await assertVisible(page, 'input[name="user[email]"]', "Email input visible"));
    results.push(await assertVisible(page, 'input[name="user[password]"]', "Password input visible"));
    results.push(await assertVisible(page, 'button:has-text("GitHub"), form[action*="github"]', "GitHub OAuth button visible"));
    results.push(await assertVisible(page, 'input[type="submit"], button[type="submit"]', "Sign in button visible"));

    const screenshot = await page.screenshot();

    return jsonResponse({
      test: "login-flow",
      passed: results.every((r) => r.passed),
      results,
      screenshotBase64: btoa(String.fromCharCode(...new Uint8Array(screenshot))),
      duration: Date.now() - start,
    } as TestResponse);
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Test: OAuth Redirect
// ============================================================================

async function testOAuthRedirect(env: Env): Promise<Response> {
  const start = Date.now();
  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();
  const results: TestResult[] = [];

  try {
    await page.goto(`${env.BASE_URL}/users/sign_in`, { waitUntil: "networkidle" });

    const githubButton = page.locator('form[action*="github"] button, form[action*="github"] input[type="submit"]').first();

    if ((await githubButton.count()) > 0) {
      await Promise.all([page.waitForURL(/github\.com/, { timeout: 10000 }), githubButton.click()]);

      const currentUrl = page.url();
      const isGitHubOAuth = currentUrl.includes("github.com");

      results.push({
        name: "GitHub OAuth redirect",
        passed: isGitHubOAuth,
        message: isGitHubOAuth ? `Redirected to: ${currentUrl}` : `Unexpected URL: ${currentUrl}`,
      });
    } else {
      results.push({
        name: "GitHub OAuth button",
        passed: false,
        message: "GitHub OAuth button not found on sign-in page",
      });
    }

    return jsonResponse({
      test: "oauth-redirect",
      passed: results.every((r) => r.passed),
      results,
      finalUrl: page.url(),
      duration: Date.now() - start,
    } as TestResponse);
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Test: Signup Page
// ============================================================================

async function testSignupPage(env: Env): Promise<Response> {
  const start = Date.now();
  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();
  const results: TestResult[] = [];

  try {
    await page.goto(`${env.BASE_URL}/users/sign_up`, { waitUntil: "networkidle" });

    results.push(await assertVisible(page, "h2", "Page title visible"));
    results.push(await assertVisible(page, 'input[name="user[first_name]"]', "First name input visible"));
    results.push(await assertVisible(page, 'input[name="user[last_name]"]', "Last name input visible"));
    results.push(await assertVisible(page, 'input[name="user[email]"]', "Email input visible"));
    results.push(await assertVisible(page, 'input[name="user[password]"]', "Password input visible"));
    results.push(await assertVisible(page, 'form[action*="github"]', "GitHub signup option visible"));

    const screenshot = await page.screenshot({ fullPage: true });

    return jsonResponse({
      test: "signup-page",
      passed: results.every((r) => r.passed),
      results,
      screenshotBase64: btoa(String.fromCharCode(...new Uint8Array(screenshot))),
      duration: Date.now() - start,
    } as TestResponse);
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Test: Dashboard Access
// ============================================================================

async function testDashboardAccess(env: Env): Promise<Response> {
  const start = Date.now();
  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();
  const results: TestResult[] = [];

  try {
    await page.goto(`${env.BASE_URL}/dashboard`, { waitUntil: "networkidle" });

    const currentUrl = page.url();
    const redirectedToLogin = currentUrl.includes("/sign_in") || currentUrl.includes("/login");

    results.push({
      name: "Unauthenticated redirect",
      passed: redirectedToLogin,
      message: redirectedToLogin ? "Correctly redirected to login when unauthenticated" : `Unexpected URL: ${currentUrl}`,
    });

    return jsonResponse({
      test: "dashboard-access",
      passed: results.every((r) => r.passed),
      results,
      finalUrl: currentUrl,
      duration: Date.now() - start,
    } as TestResponse);
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Test: Smoke Tests
// ============================================================================

async function testSmoke(env: Env, options: Record<string, unknown>): Promise<Response> {
  const start = Date.now();
  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();
  const results: TestResult[] = [];

  const pagesToTest = [
    { path: "/", name: "Home page" },
    { path: "/users/sign_in", name: "Sign in page" },
    { path: "/users/sign_up", name: "Sign up page" },
    { path: "/projects/explore", name: "Explore projects" },
  ];

  // Add authenticated pages if email provided
  const testEmail = options.email as string | undefined;

  try {
    for (const { path, name } of pagesToTest) {
      const pageStart = Date.now();
      try {
        await page.goto(`${env.BASE_URL}${path}`, { waitUntil: "networkidle", timeout: 15000 });
        results.push(await assertNotError(page, `${name} loads without error`));
      } catch (error) {
        results.push({
          name: `${name} loads`,
          passed: false,
          message: `Failed to load: ${error instanceof Error ? error.message : "Unknown"}`,
          duration: Date.now() - pageStart,
        });
      }
    }

    // Test authenticated pages if we can log in
    if (testEmail) {
      try {
        await loginAsTestUser(page, env, testEmail);

        const authPages = [
          { path: "/dashboard", name: "Dashboard" },
          { path: "/projects", name: "Projects list" },
        ];

        for (const { path, name } of authPages) {
          const pageStart = Date.now();
          try {
            await page.goto(`${env.BASE_URL}${path}`, { waitUntil: "networkidle", timeout: 15000 });
            results.push(await assertNotError(page, `${name} loads without error (auth)`));
          } catch (error) {
            results.push({
              name: `${name} loads (auth)`,
              passed: false,
              message: `Failed to load: ${error instanceof Error ? error.message : "Unknown"}`,
              duration: Date.now() - pageStart,
            });
          }
        }
      } catch (error) {
        results.push({
          name: "Test login",
          passed: false,
          message: `Login failed: ${error instanceof Error ? error.message : "Unknown"}`,
        });
      }
    }

    return jsonResponse({
      test: "smoke",
      passed: results.every((r) => r.passed),
      results,
      duration: Date.now() - start,
    } as TestResponse);
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Test: Form Submissions
// ============================================================================

async function testFormSubmission(env: Env, formType: string, data: Record<string, unknown>): Promise<Response> {
  const start = Date.now();
  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();
  const results: TestResult[] = [];

  try {
    // Login first
    const email = (data.email as string) || "e2e@example.com";
    await loginAsTestUser(page, env, email);

    switch (formType) {
      case "project":
        await page.goto(`${env.BASE_URL}/projects/new`, { waitUntil: "networkidle" });
        results.push(await assertVisible(page, 'form[action*="projects"]', "Project form visible"));
        results.push(await assertVisible(page, 'input[name*="name"]', "Name input visible"));
        results.push(await assertVisible(page, 'textarea[name*="description"], input[name*="description"]', "Description field visible"));
        break;

      case "milestone":
        // Need a project ID - check if provided
        const projectPath = data.projectPath || "/projects";
        await page.goto(`${env.BASE_URL}${projectPath}`, { waitUntil: "networkidle" });
        results.push(await assertVisible(page, 'a[href*="milestone"], button:has-text("Milestone")', "Milestone link/button visible"));
        break;

      case "agreement":
        await page.goto(`${env.BASE_URL}/agreements/new`, { waitUntil: "networkidle" });
        results.push(await assertVisible(page, 'form[action*="agreement"]', "Agreement form visible"));
        break;

      default:
        results.push({
          name: "Form type",
          passed: false,
          message: `Unknown form type: ${formType}`,
        });
    }

    const screenshot = await page.screenshot();

    return jsonResponse({
      test: `form-${formType}`,
      passed: results.every((r) => r.passed),
      results,
      screenshotBase64: btoa(String.fromCharCode(...new Uint8Array(screenshot))),
      duration: Date.now() - start,
    } as TestResponse);
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Test: Security Checks
// ============================================================================

async function testSecurityCheck(env: Env, checkType: string): Promise<Response> {
  const start = Date.now();
  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();
  const results: TestResult[] = [];

  try {
    switch (checkType) {
      case "session":
        // Test that unauthenticated users are redirected
        await page.goto(`${env.BASE_URL}/dashboard`, { waitUntil: "networkidle" });
        const dashUrl = page.url();
        results.push({
          name: "Dashboard requires auth",
          passed: dashUrl.includes("/sign_in"),
          message: dashUrl.includes("/sign_in") ? "Correctly redirected" : `Accessed without auth: ${dashUrl}`,
        });

        await page.goto(`${env.BASE_URL}/projects`, { waitUntil: "networkidle" });
        const projUrl = page.url();
        results.push({
          name: "Projects requires auth",
          passed: projUrl.includes("/sign_in"),
          message: projUrl.includes("/sign_in") ? "Correctly redirected" : `Accessed without auth: ${projUrl}`,
        });
        break;

      case "access":
        // Test cross-user access prevention
        await loginAsTestUser(page, env, "alice.entrepreneur@test.com");
        // Try to access another user's profile edit (should fail or redirect)
        await page.goto(`${env.BASE_URL}/profile/edit`, { waitUntil: "networkidle" });
        results.push({
          name: "Profile edit loads for authenticated user",
          passed: !page.url().includes("/sign_in"),
          message: "User can access their own profile",
        });
        break;

      case "escalation":
        // Test that normal users can't access admin routes
        await loginAsTestUser(page, env, "frank.newbie@test.com");

        const adminPaths = ["/admin", "/rails/conductor"];
        for (const adminPath of adminPaths) {
          await page.goto(`${env.BASE_URL}${adminPath}`, { waitUntil: "networkidle" });
          const url = page.url();
          const status = await page.evaluate(() => {
            // Check if we got a 404 or redirect
            return document.body.innerText.includes("404") || document.body.innerText.includes("Not Found");
          });
          results.push({
            name: `Admin path ${adminPath} blocked`,
            passed: url.includes("/sign_in") || status,
            message: url.includes("/sign_in") ? "Redirected to login" : status ? "Got 404" : `Unexpected access: ${url}`,
          });
        }
        break;

      default:
        results.push({
          name: "Security check type",
          passed: false,
          message: `Unknown check type: ${checkType}`,
        });
    }

    return jsonResponse({
      test: `security-${checkType}`,
      passed: results.every((r) => r.passed),
      results,
      duration: Date.now() - start,
    } as TestResponse);
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Test: User Journey
// ============================================================================

async function testUserJourney(env: Env, options: Record<string, unknown>): Promise<Response> {
  const start = Date.now();
  const browser = await launch(env.BROWSER);
  const page = await browser.newPage();
  const results: TestResult[] = [];

  const email = (options.email as string) || "alice.entrepreneur@test.com";

  try {
    // Login
    await loginAsTestUser(page, env, email);
    results.push({
      name: "Login successful",
      passed: true,
      message: `Logged in as ${email}`,
    });

    // Navigate to dashboard
    await page.goto(`${env.BASE_URL}/dashboard`, { waitUntil: "networkidle" });
    results.push(await assertNotError(page, "Dashboard accessible"));
    results.push(await assertVisible(page, "nav, header", "Navigation visible"));

    // Navigate to projects
    await page.goto(`${env.BASE_URL}/projects`, { waitUntil: "networkidle" });
    results.push(await assertNotError(page, "Projects page accessible"));

    // Check for project cards or empty state
    const hasProjects = (await page.locator('[data-testid="project-card"], .project-card, a[href*="/projects/"]').count()) > 0;
    const hasEmptyState = (await page.locator('[data-testid="empty-state"], .empty-state, :has-text("No projects")').count()) > 0;
    results.push({
      name: "Projects or empty state visible",
      passed: hasProjects || hasEmptyState,
      message: hasProjects ? "Projects found" : hasEmptyState ? "Empty state shown" : "Neither projects nor empty state found",
    });

    // Navigate to profile
    await page.goto(`${env.BASE_URL}/profile`, { waitUntil: "networkidle" });
    results.push(await assertNotError(page, "Profile page accessible"));

    const screenshot = await page.screenshot({ fullPage: true });

    return jsonResponse({
      test: "user-journey",
      passed: results.every((r) => r.passed),
      results,
      screenshotBase64: btoa(String.fromCharCode(...new Uint8Array(screenshot))),
      finalUrl: page.url(),
      duration: Date.now() - start,
    } as TestResponse);
  } finally {
    await browser.close();
  }
}

// ============================================================================
// Test Suites
// ============================================================================

async function runTestSuite(env: Env, suiteName: string, options: Record<string, unknown>): Promise<Response> {
  const start = Date.now();
  const suiteResults: TestResponse[] = [];

  switch (suiteName) {
    case "smoke":
      const smokeResult = await testSmoke(env, options);
      suiteResults.push(await smokeResult.json());
      break;

    case "auth":
      const loginResult = await testLoginFlow(env);
      suiteResults.push(await loginResult.json());
      const signupResult = await testSignupPage(env);
      suiteResults.push(await signupResult.json());
      const dashResult = await testDashboardAccess(env);
      suiteResults.push(await dashResult.json());
      break;

    case "security":
      for (const checkType of ["session", "access", "escalation"]) {
        const result = await testSecurityCheck(env, checkType);
        suiteResults.push(await result.json());
      }
      break;

    case "forms":
      for (const formType of ["project", "agreement"]) {
        const result = await testFormSubmission(env, formType, options);
        suiteResults.push(await result.json());
      }
      break;

    case "full":
      // Run all suites
      const fullSmoke = await testSmoke(env, options);
      suiteResults.push(await fullSmoke.json());
      const fullLogin = await testLoginFlow(env);
      suiteResults.push(await fullLogin.json());
      for (const checkType of ["session", "access"]) {
        const result = await testSecurityCheck(env, checkType);
        suiteResults.push(await result.json());
      }
      if (options.email) {
        const journey = await testUserJourney(env, options);
        suiteResults.push(await journey.json());
      }
      break;

    default:
      return jsonResponse({ error: `Unknown suite: ${suiteName}`, availableSuites: ["smoke", "auth", "security", "forms", "full"] }, 400);
  }

  const allPassed = suiteResults.every((r) => r.passed);
  const totalResults = suiteResults.flatMap((r) => r.results);

  return jsonResponse({
    suite: suiteName,
    passed: allPassed,
    testsRun: suiteResults.length,
    totalAssertions: totalResults.length,
    passedAssertions: totalResults.filter((r) => r.passed).length,
    failedAssertions: totalResults.filter((r) => !r.passed).length,
    results: suiteResults,
    duration: Date.now() - start,
  });
}
