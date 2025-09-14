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

## User System Architecture

### Philosophy
FlukeBase operates with a **unified user experience** without role-based restrictions or categorizations. All authenticated users have equal access to all platform features.

### Key Principles
- **Universal Access**: All authenticated users have access to all core features
- **Simplified Experience**: No role-based onboarding, restrictions, or complex user flows
- **Feature Equality**: All users can create projects, initiate agreements, track time, and access all functionality
- **Clean Architecture**: Simplified codebase without role-related complexity

### User Features Available to All
- **Project Management**: Create, manage, and collaborate on projects
- **Agreement System**: Initiate mentorship or co-founder agreements with any user
- **Time Tracking**: Track time on project milestones
- **Messaging**: Direct communication with other users
- **Profile Management**: Complete user profiles with skills, experience, and social links

### Removed Components (Completely Eliminated)
- `Role` model: Role definitions and categorization system removed
- `UserRole` join table: User-role associations removed
- `Roleable` concern: Role management helpers removed
- `RoleManager` service: Role assignment logic removed
- `RolesController`: Role management interface removed
- `OnboardingController`: Role-specific onboarding flows removed
- `UserOnboardingService`: Complex onboarding logic removed
- Onboarding routes: `/onboarding/*` and `/roles/*` paths removed
- Role-specific views: All role categorization templates removed
- Role initializers and rake tasks removed
- Role-related test files and factories removed

### Unified Experience
- **Navbar**: All users see project selector and milestones dropdown
- **Project Access**: Users can access any project they own or have agreements with
- **Time Tracking**: All users can track time on project milestones
- **Dashboard**: Direct access to dashboard with unified experience for all users
- **User Discovery**: All users can explore and connect with other users
- **Agreement Creation**: Any user can initiate agreements with any other user