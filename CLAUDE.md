# Claude Code Configuration

## Testing Commands
- `rails server` - Start development server
- `rails console` - Start Rails console
- `./bin/test` - Run essential tests (models + helpers)
- `./bin/test --coverage` - Run tests with coverage reporting
- `./bin/test --type unit` - Run only unit tests (models, services, helpers)
- `./bin/test --type integration` - Run integration tests (controllers, requests)
- `./bin/test --type system` - Run system/end-to-end tests
- `bundle exec rspec` - Run RSpec tests directly
- `npm run test` - Run tests via npm
- `npm run test:coverage` - Run tests with coverage via npm

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

## Coverage and CI/CD
- `npm run ci` - Run full CI pipeline locally (lint + test with coverage)
- Coverage reports generated in `coverage/` directory
- HTML coverage report: `coverage/index.html`
- LCOV format for CI: `coverage/lcov.info`
- GitHub Actions workflow:
  - `.github/workflows/ci.yml` - Streamlined CI with essential linting and tests only

## Turbo Testing Notes
- All Turbo implementations have been reviewed and fixed
- Frame structure corrected in agreements/show.html.erb
- Flash messaging properly configured for Turbo Streams
- Controller responses include proper frame awareness
- JavaScript moved to Stimulus controllers