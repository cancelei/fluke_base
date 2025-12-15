# FlukeBase — AI Operations Guide (Concise)

- Stack: Rails 8, PostgreSQL, Hotwire, Tailwind, RSpec, ESLint, Prettier, Stylelint, Playwright
- Envs: `RAILS_ENV=test`, `NODE_ENV=test`. Coverage via `COVERAGE=true`.
- Port: Development runs on `http://localhost:3006`, Test runs on `http://127.0.0.1:5010`

## Run
- Unified: `bundle exec rake test`
- Coverage: `COVERAGE=true bundle exec rake test`
- Ruby only: `bundle exec rspec [spec/path_spec.rb]`
- Lint JS: `npm run js-lint` | Fix: `npm run js-lint-fix`
- Lint CSS: `npm run css-lint` | Fix: `npm run css-lint-fix`
- Format Check: `npm run format-check` | Fix: `npm run format-fix`
- E2E: `npm run test:e2e` | Headed: `npm run test:e2e:headed` | UI: `npm run test:e2e:ui` | Debug: `npm run test:e2e:debug`

## What `rake test` does
1) ESLint (JavaScript)
2) RSpec (Rails, transactional, coverage if `COVERAGE=true`)
3) Playwright: starts Rails server in test env at `http://127.0.0.1:5010`

## Setup
- Ruby deps: `bundle install`
- Node deps: `npm install` (runs `playwright install --with-deps`)
- DB: `RAILS_ENV=test bin/rails db:prepare`

## Debug
- RSpec verbose: `bundle exec rspec spec/path_spec.rb --format documentation`
- Playwright report: `playwright-report/`; run headed: `npm run test:e2e:headed`
- Traces: auto on retry; open report with `npx playwright show-report`
- ESLint: fix automatically `npm run lint:js:fix`

## Conventions
- Tests live under `spec/` (RSpec) and `spec/e2e/` (Playwright)
- Prefer service objects for business logic tests
- Use factory_bot and shoulda-matchers for model tests

## Notes
- `./bin/test` forwards to `bundle exec rake test` and is deprecated
- Keep browser/E2E tests deterministic; seed DB explicitly in fixtures/factories
- CI entrypoint: `npm run ci` (lint + unified test with coverage)
- ESLint uses Ackama configuration for code quality
- Prettier enforces consistent formatting across JS/JSX files
- Stylelint configured for SCSS with Tailwind support

## Maintaining Documentation

When adding new features or updating existing ones:
1. Update CLAUDE.md with new commands or testing endpoints
2. Update this AI_OPERATIONS.md if test/lint/build commands change
3. Document new environment variables in `.env` file
4. Add comments to complex service objects and business logic

