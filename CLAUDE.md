# Claude Code Configuration

## Testing Commands
- `rails server` - Start development server (port 3000)
- `rails console` - Start Rails console
- `./bin/test` - Run essential tests (models + helpers)
- `./bin/test --coverage` - Run tests with coverage reporting
- `./bin/test --type unit` - Run only unit tests (models, services, helpers)
- `./bin/test --type integration` - Run integration tests (controllers, requests)
- `./bin/test --type system` - Run system/end-to-end tests
- `./bin/test --verbose` - Run tests with detailed output
- `bundle exec rspec` - Run RSpec tests directly
- `npm run test` - Run tests via npm (calls ./bin/test)
- `npm run test:coverage` - Run tests with coverage via npm
- `npm run ci` - Run full CI pipeline locally (lint + test with coverage)

## Testing Endpoints (No Authentication Required)

Test the Turbo implementations using these endpoints:
- `http://localhost:3000/test/turbo` - Turbo fixes summary
- `http://localhost:3000/test/agreements` - Agreements Turbo features test
- `http://localhost:3000/up` - Rails health check

These endpoints work without authentication and confirm all Turbo implementations are working.

## Database Setup Commands
- `rails db:create` - Create database
- `rails db:migrate` - Run migrations
- `rails db:seed` - Seed initial data
- `rails db:reset` - Reset database completely

## Linting Commands
- `./bin/lint` - Run all linters in parallel (RuboCop, Brakeman, ERB Lint, ESLint)
- `./bin/lint --fix` - Run linters with auto-fix where possible
- `npm run lint:js` - Run ESLint for JavaScript files
- `npm run lint:js:fix` - Run ESLint with auto-fix
- `bundle exec rubocop` - Ruby code style checker
- `bundle exec brakeman` - Security vulnerability scanner
- `bundle exec erb_lint` - ERB template linter

## Coverage and CI/CD
- `npm run ci` - Run full CI pipeline locally (lint + test with coverage)
- Coverage reports generated in `coverage/` directory
- HTML coverage report: `coverage/index.html`
- LCOV format for CI: `coverage/lcov.info`
- GitHub Actions workflow:
  - `.github/workflows/ci.yml` - Streamlined CI with parallel linting and essential tests only

## Additional Development Tools
- `./bin/dev` - Start development server with live reloading
- `./bin/setup` - Initial project setup script
- `./bin/workers` - Manual background job worker management
- `kamal setup` - Initial deployment setup
- `kamal deploy` - Deploy application to production
- `kamal app logs` - View production application logs

## Multi-Database Commands
- `RAILS_ENV=test rails db:create` - Create test databases
- `RAILS_ENV=test rails db:migrate` - Run test migrations
- Rails 8.0 multi-database support: primary, cache, queue, cable databases
- CI environment automatically disables additional databases via ENV["CI"] check

## Turbo Testing Notes
- All Turbo implementations have been reviewed and fixed
- Frame structure corrected in agreements/show.html.erb
- Flash messaging properly configured for Turbo Streams
- Controller responses include proper frame awareness
- JavaScript moved to Stimulus controllers