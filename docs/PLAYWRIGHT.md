# Playwright E2E Testing

This project uses Playwright for end-to-end tests located under `spec/e2e/`. The config `playwright.config.js` starts a Rails server in `RAILS_ENV=test` at `http://127.0.0.1:5010` and sets a `globalSetup` that logs in once using a test-only endpoint to create a reusable auth state.

## Quick Start

- Install deps: `bundle install && npm ci`
- Run lint + RSpec + Playwright: `RUN_E2E=1 bundle exec rake test`
- Playwright only (headed): `npm run test:e2e:headed`
- Fail-fast: `npx playwright test --max-failures=1`

## Test-Only Login Endpoint

For fast and reliable authenticated tests, a test-only endpoint is mounted in test environment:

- Route: `GET/POST /test_only/login?email=e2e@example.com[&password=Password!123]`
- Controller: `app/controllers/test_only/sessions_controller.rb`
- Behavior: Finds or creates the user and signs them in via Devise. Redirects to `/` for HTML, returns `{ ok: true, user_id }` for JSON.

This avoids fragile UI-based login and speeds up tests considerably.

## Auth State Reuse

`spec/e2e/setup/global-setup.js` performs a one-time login and saves storage state to `tmp/playwright/auth.json`. You can opt-in per test file:

```js
// spec/e2e/authenticated_example.spec.js
import { test, expect } from '@playwright/test';
test.use({ storageState: 'tmp/playwright/auth.json' });
test('authenticated flow', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('link', { name: /dashboard/i })).toBeVisible();
});
```

## Base Fixture and Page Objects

- `spec/e2e/fixtures/test-base.js` — extends `test` with a `login` helper that hits the test-only login endpoint from the current page context.
- `spec/e2e/pages/*.page.js` — simple Page Object Models (POM) to keep tests readable and resilient.

## Conventions

- Place flows end-to-end in `spec/e2e/`.
- Prefer test-only endpoints for setup over UI when feasible.
- Keep tests independent; do not rely on execution order.
- Use `--max-failures=1` during triage (fail fast), then run full suite.

## Troubleshooting

- If browsers aren’t installed, run `PLAYWRIGHT_INSTALL=1 npm install` locally.
- Server port clash: adjust `PLAYWRIGHT_BASE_URL` or the `webServer.port` in `playwright.config.js`.
- DB issues: ensure Postgres is running and `RAILS_ENV=test bin/rails db:prepare` succeeds.

