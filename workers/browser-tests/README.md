# FlukeBase Browser Rendering Worker

Cloudflare-hosted Playwright for E2E testing against FlukeBase environments.

## Overview

This worker uses [Cloudflare Browser Rendering](https://developers.cloudflare.com/browser-rendering/) to run Playwright tests in Cloudflare's global edge network. No local browser installation required.

**Benefits:**
- Instant browser access (low cold-start)
- Global edge deployment
- No browser binaries to manage
- Free tier available

## Quick Start

```bash
cd workers/browser-tests

# Install dependencies
npm install

# Run locally (requires Cloudflare account)
npm run dev

# Deploy to Cloudflare
npm run deploy
```

## API Endpoints

### Core Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check with environment info |
| `/screenshot` | GET | Screenshot any URL |
| `/sessions` | GET | List active browser sessions |
| `/limits` | GET | Check rate limits |

### Auth Test Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/test/login` | POST | Test email login flow elements |
| `/test/oauth-redirect` | POST | Test GitHub OAuth redirect |
| `/test/signup-page` | POST | Test signup page renders correctly |
| `/test/dashboard` | POST | Test dashboard auth redirect |

### Extended Test Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/test/smoke` | POST | Run smoke tests across major pages |
| `/test/form/:type` | POST | Test form submissions (project, milestone, agreement) |
| `/test/security/:type` | POST | Security checks (session, access, escalation) |
| `/test/user-journey` | POST | Full user journey test |
| `/test/suite/:name` | POST | Run predefined test suite |

### Test Suites

Available suites via `/test/suite/:name`:

| Suite | Description |
|-------|-------------|
| `smoke` | Basic page load tests |
| `auth` | Authentication flow tests |
| `security` | Security check tests |
| `forms` | Form validation tests |
| `full` | All tests combined |

## Usage Examples

```bash
# Health check
curl http://localhost:8787/health

# Screenshot dev.flukebase.me
curl http://localhost:8787/screenshot -o screenshot.png

# Screenshot any URL with full page
curl "http://localhost:8787/screenshot?url=https://example.com&fullPage=true" -o screenshot.png

# Test login page elements
curl -X POST http://localhost:8787/test/login | jq

# Test GitHub OAuth redirect
curl -X POST http://localhost:8787/test/oauth-redirect | jq

# Run smoke tests with authenticated pages
curl -X POST http://localhost:8787/test/smoke \
  -H "Content-Type: application/json" \
  -d '{"email": "alice.entrepreneur@test.com"}' | jq

# Run full test suite
curl -X POST http://localhost:8787/test/suite/full \
  -H "Content-Type: application/json" \
  -d '{"email": "e2e@example.com"}' | jq

# Security check
curl -X POST http://localhost:8787/test/security/session | jq

# User journey test
curl -X POST http://localhost:8787/test/user-journey \
  -H "Content-Type: application/json" \
  -d '{"email": "alice.entrepreneur@test.com"}' | jq
```

## Test Response Format

All test endpoints return JSON:

```json
{
  "test": "login-flow",
  "passed": true,
  "results": [
    {
      "name": "Sign in page title visible",
      "passed": true,
      "message": "Element found and visible",
      "duration": 234
    }
  ],
  "screenshotBase64": "iVBORw0KGgo...",
  "duration": 1523
}
```

Suite responses include aggregated stats:

```json
{
  "suite": "full",
  "passed": true,
  "testsRun": 5,
  "totalAssertions": 23,
  "passedAssertions": 23,
  "failedAssertions": 0,
  "results": [...],
  "duration": 8234
}
```

## Integration with FlukeBase Tests

### From Main Project

```bash
# Run E2E tests via Cloudflare Worker
npm run test:e2e:cf

# Run E2E tests against dev.flukebase.me
npm run test:e2e:cf:dev

# Start worker locally
npm run cf-worker:dev
```

### Environment Variables

Set these in your environment or CI:

| Variable | Description | Default |
|----------|-------------|---------|
| `USE_CF_BROWSER` | Enable Cloudflare mode | `false` |
| `CF_BROWSER_WORKER_URL` | Worker URL | `http://localhost:8787` |
| `CF_BROWSER_AUTH_TOKEN` | Optional auth token | - |
| `PLAYWRIGHT_BASE_URL` | Target FlukeBase URL | `https://dev.flukebase.me` |

### Using Hybrid Test Fixture

```javascript
import { test, hybridTest } from '../fixtures/cloudflare-test.js';

// Works in both local and Cloudflare modes
test('login page renders', hybridTest({
  local: async ({ page }) => {
    await page.goto('/users/sign_in');
    await expect(page.locator('h2')).toBeVisible();
  },
  cloudflare: async ({ cfClient, cfAssertions }) => {
    const result = await cfClient.testLogin();
    cfAssertions.expectAllPassed(result);
  }
}));
```

## Configuration

### wrangler.toml

Key settings:
- `compatibility_date = "2025-09-17"` - Required for @cloudflare/playwright
- `compatibility_flags = ["nodejs_compat"]` - Required for node.fs API
- `[browser] binding = "BROWSER"` - Browser Rendering binding

### Environment Variables (Worker)

| Variable | Description | Default |
|----------|-------------|---------
| `BASE_URL` | Target FlukeBase URL | `https://dev.flukebase.me` |
| `ENVIRONMENT` | Environment name | `development` |
| `AUTH_TOKEN` | Optional auth token for POST endpoints | - |

## Deployment

### Local Development

```bash
npm run dev
```

### Staging

```bash
npm run deploy:staging
```

### Production

```bash
npm run deploy:production
```

### GitHub Actions Integration

To enable Cloudflare mode in CI, set these repository variables:

1. `USE_CF_BROWSER` = `true`
2. `CF_BROWSER_WORKER_URL` = `https://your-worker.your-subdomain.workers.dev`

And this repository secret:
- `CF_BROWSER_AUTH_TOKEN` = your auth token (if configured)

## Pricing

Cloudflare Browser Rendering pricing (as of 2025):
- **Free tier**: Included with Workers Free plan
- **Paid**: See [Cloudflare pricing](https://developers.cloudflare.com/browser-rendering/platform/pricing/)

## Troubleshooting

### "Browser binding not available"
Ensure you're running with `wrangler dev` (not just `node`), as the browser binding requires Cloudflare's infrastructure.

### Rate Limited
Check limits with `/limits` endpoint. Consider session reuse for high-volume tests.

### Timeout Errors
Increase timeouts for slow pages. The worker uses 15s timeout for page loads by default.

### Authentication Issues
Ensure `test_only/login` endpoint is available in your target environment (test/development only).

## Related

- [Cloudflare Browser Rendering Docs](https://developers.cloudflare.com/browser-rendering/)
- [Playwright API](https://playwright.dev/docs/api/class-playwright)
- [FlukeBase E2E Tests](../../spec/e2e/)
- [Hybrid Test Fixture](../../spec/e2e/fixtures/cloudflare-test.js)
