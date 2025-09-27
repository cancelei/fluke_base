# Repository Guidelines

## Project Structure & Module Organization
- Rails app in `app/` (controllers, models, views).
- Client code in `app/javascript/` (Stimulus controllers, utils).
- Business logic in `app/services/`, `app/presenters/`, `app/policies/`, `app/queries/`.
- Tests in `spec/` (RSpec: `models/`, `controllers/`, `requests/`, `system/`; Playwright: `e2e/`).
- Configuration in `config/`; database in `db/`; shared libs in `lib/`; assets in `app/assets/`; docs in `docs/` and `technical_spec/`.

## Build, Test, and Development Commands
- Install deps: `bundle install && npm ci`.
- Run server: `rails server` (console: `rails console`; workers: `./bin/jobs`).
- Unified tests: `bundle exec rake test` (ESLint → RSpec → Playwright).
- Coverage: `COVERAGE=true bundle exec rake test`.
- RSpec only: `bundle exec rspec [spec/path_spec.rb]`.
- Playwright: `npm run test:e2e` (headed: `npm run test:e2e:headed`).
- Lint: `./bin/lint` (auto-fix: `./bin/lint --fix`); JS-only: `npm run lint:js` (fix: `npm run lint:js:fix`).

## Coding Style & Naming Conventions
- Ruby: `rubocop-rails-omakase`; snake_case methods; CamelCase classes; service objects; concerns for shared logic; Pundit policies.
- JavaScript: ES modules, single quotes, semicolons, 2-space indent; camelCase functions/vars; PascalCase classes; place Stimulus controllers in `app/javascript/controllers/`.
- Hotwire/Turbo: server-rendered HTML; no client-side routing; prefer Turbo Frames/Streams for scoped updates.

## Testing Guidelines
- Use RSpec for unit/integration/system; mirror paths (e.g., `spec/models/user_spec.rb`).
- Keep coverage for new/changed code; run `COVERAGE=true bundle exec rake test` locally.
- Place E2E tests in `spec/e2e/`; keep fast tests in RSpec, flows in Playwright.

## Commit & Pull Request Guidelines
- Commits: short, imperative. Prefer `feat:`, `fix:`, `chore:`, `refactor:`. Existing history also uses `feat/update ...`; be consistent and clear.
- PRs: include summary, linked issues, screenshots for UI, and test plan. All linters/tests must pass (`bundle exec rake test`).

## Security & Configuration Tips
- Use `.env` and Rails credentials; never commit secrets.
- Update CSP/Turnstile configs in `config/` with care; verify via E2E before merge.
- Run `bin/rails db:prepare` after pulling schema changes.
