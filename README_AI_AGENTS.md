# AI Agent Codebase Analysis Guide: FlukeBase

> Canonical run/debug instructions for AI agents have been consolidated here: `docs/AI_OPERATIONS.md`.
> Use that as the single source for how to run, test, and debug.

## Project Overview

**FlukeBase** is a Rails 8.0.2 application designed as a collaborative platform connecting entrepreneurs, mentors, and co-founders. The system facilitates project management, time tracking, agreement workflows, and GitHub integration for software development collaborations.

### Core Technology Stack
- **Framework**: Ruby on Rails 8.0.2.1
- **Ruby Version**: 3.2.1
- **Node Version**: 23.0.0 (development)
- **Database**: PostgreSQL with multi-database architecture (primary, cache, queue, cable)
- **Frontend**: Turbo-Rails, Stimulus, TailwindCSS, Propshaft asset pipeline
- **Authentication**: Devise
- **Authorization**: CanCanCan
- **Payment Processing**: Pay gem with Stripe integration
- **External APIs**: GitHub (Octokit), Google Calendar
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Real-time**: Solid Cable (ActionCable)
- **Testing**: RSpec with SimpleCov coverage reporting
- **Deployment**: Kamal with Docker support

## Architecture Patterns

### Multi-Database Configuration
The application uses Rails 8.0's multi-database support with four distinct databases:
- **Primary**: Main application data (users, projects, agreements)
- **Cache**: Solid Cache storage (`db/cache_migrate`)
- **Queue**: Solid Queue background jobs (`db/queue_migrate`) 
- **Cable**: Solid Cable WebSocket connections (`db/cable_migrate`)

**AI Agent Note**: When analyzing database-related code, check `config/database.yml:73-91` for CI-conditional database setup. The system disables additional databases in CI environments via `ENV["CI"]` checks.

### Service-Oriented Architecture
The application heavily uses service objects for business logic encapsulation:

**Key Services** (located in `app/services/`):
- `AgreementStatusService`: Manages agreement lifecycle and status transitions
- `AgreementCalculationsService`: Handles time tracking, cost calculations, payment details
- `ProjectGithubService`: GitHub API integration, commit tracking, repository management
- `ProjectVisibilityService`: Field-level privacy controls for project data
- `UserOnboardingService`: Role-based user onboarding workflows
- `NotificationService`: System-wide notification management

**AI Agent Analysis Pattern**: When encountering business logic in models, look for delegated service methods (e.g., `Agreement:92-94` delegates to `calculations_service`).

## Core Domain Models

### User Model (`app/models/user.rb`)
**Central Entity**: Manages authentication, roles, and relationships

**Key Associations**:
- `belongs_to :selected_project` - Current project context
- `belongs_to :current_role` - Active role (entrepreneur/mentor/co-founder)
- `has_many :user_roles, :roles` - Multi-role system
- `has_many :agreement_participants` - Agreement participation tracking
- `has_many :initiated_agreements, :received_agreements` - Directional agreement access

**AI Agent Note**: The `User:79-84` `selected_project` method is overridden to return nil - actual project selection is session-managed by `ApplicationController`.

### Project Model (`app/models/project.rb`)
**Core Business Entity**: Represents entrepreneurial projects seeking collaboration

**Key Features**:
- **Stages**: `IDEA`, `PROTOTYPE`, `LAUNCHED`, `SCALING` (lines 26-29)
- **Collaboration Types**: `SEEKING_MENTOR`, `SEEKING_COFOUNDER`, `SEEKING_BOTH` (lines 32-34)
- **Privacy System**: Field-level visibility controls via `ProjectVisibilityService`
- **GitHub Integration**: Commit tracking, contribution analysis, branch management

**Critical Methods for AI Analysis**:
- `github_contributions(branch:, agreement_only:, agreement_user_ids:, user_name:)` (lines 64-172): Complex query logic for GitHub statistics
- `field_public?(field_name)`, `visible_to_user?(field_name, user)` (lines 217-227): Privacy delegation pattern

### Agreement Model (`app/models/agreement.rb`)
**Complex Business Logic**: Manages mentorship and co-founder agreements

**Status Workflow**: `PENDING` → `ACCEPTED`/`REJECTED`/`COUNTERED` → `COMPLETED`/`CANCELLED`

**Key Features**:
- **Types**: `MENTORSHIP`, `CO_FOUNDER` (lines 3-4)
- **Payment Types**: `HOURLY`, `EQUITY`, `HYBRID` (lines 15-17)
- **Turn-Based System**: Counter-offer negotiations with user turn tracking
- **Service Delegation**: Status management and calculations delegated to dedicated services

**AI Agent Analysis Pattern**: The model heavily delegates to `AgreementStatusService` and `AgreementCalculationsService` - examine these services for actual business logic implementation.

## Controller Architecture

### Base Controller (`app/controllers/application_controller.rb`)
**Modified**: Contains project context management and authentication

**Key Methods for AI Agents**:
- Project selection and context switching logic
- Devise authentication integration
- Role-based authorization setup

### Primary Controllers
- **ProjectsController**: CRUD operations, GitHub integration, milestone management
- **AgreementsController**: Complex negotiation workflows, Turbo-enhanced forms
- **DashboardController**: User-specific aggregated views
- **TimeLogsController**: Time tracking with real-time updates

**AI Agent Note**: Controllers use Turbo-Rails extensively. Look for `turbo_frame` and `turbo_stream` usage when analyzing frontend interactions.

## Database Schema Analysis

### Key Tables for AI Agents
1. **users**: Core user data with role and project associations
2. **projects**: Main business entities with privacy field configurations
3. **agreements**: Complex workflow table with participant relationships
4. **agreement_participants**: Join table managing user roles in agreements
5. **time_logs**: Time tracking with project and agreement associations
6. **github_logs**: Git commit tracking and contribution analysis
7. **milestones**: Project milestone management with confirmation workflows

### Multi-Database Migrations
**Critical for AI Agents**: The system uses separate migration paths:
- `db/migrate/` - Primary database schema
- `db/cache_migrate/` - Solid Cache tables
- `db/queue_migrate/` - Solid Queue job tables  
- `db/cable_migrate/` - Solid Cable WebSocket tables

## Testing Infrastructure

### Test Framework Setup
**Location**: `spec/` directory with RSpec configuration
**Coverage**: SimpleCov with HTML and LCOV output formats
**CI Integration**: GitHub Actions with parallelized linting

### Unified Test Runner (`rake test`)
**AI Agent Usage**: Execute via `bundle exec rake test`.
- Runs in order: ESLint → RSpec → Playwright (Rails server auto-starts in test env on port 5010).
- Coverage: set `COVERAGE=true` (e.g., `COVERAGE=true bundle exec rake test`).

**RSpec Coverage** (`spec/support/coverage.rb`):
- Controlled by `COVERAGE=true`.
- HTML: `coverage/index.html`, LCOV: `coverage/lcov.info`.

## GitHub Actions CI/CD

### Workflow Configuration (`.github/workflows/ci.yml`)
**Streamlined Pipeline**: Essential linting and testing only

**Parallel Linting Matrix**:
- RuboCop (Ruby code style)
- Brakeman (Security analysis) 
- ERB Lint (Template linting)
- ESLint (JavaScript linting)

**Database Setup**: PostgreSQL 16 service with conditional multi-database configuration

**AI Agent Note**: The CI is optimized for essential checks only. Previous complex workflows were simplified to prevent over-testing.

## Development Environment

### Required Environment Variables
- `FLUKE_BASE_DATABASE_USERNAME`: PostgreSQL username (defaults to 'postgres')
- `FLUKE_BASE_DATABASE_PASSWORD`: PostgreSQL password
- GitHub API integration requires GitHub tokens for repository access

### Development Commands
```bash
rails server                    # Start development server (default port 3000)
./bin/dev                       # Start with live reloading
rails console                   # Interactive Rails console  
bundle exec rake test          # Unified tests (ESLint, RSpec, Playwright)
COVERAGE=true bundle exec rake test  # With coverage
./bin/lint                      # Run all linters in parallel
npm run ci                      # Full CI pipeline locally
kamal deploy                    # Deploy to production
```

### Playwright (E2E)
- Config: `playwright.config.js` (JS-only). Web server: `bin/rails server -e test -p 5010`.
- Run: `npm run test:e2e` | Headed: `npm run test:e2e:headed`.
- Base URL: `http://127.0.0.1:5010`.

### Debugging Tips
- RSpec: `bundle exec rspec spec/path/to/file_spec.rb --format documentation`.
- ESLint: `npm run lint:js:fix` for auto-fix.
- Playwright: use `--headed --debug` flags; inspect reports under `playwright-report/` and traces on retry.

### Test Endpoints (Development Only)
- `http://localhost:3000/test/turbo` - Turbo implementation verification
- `http://localhost:3000/test/agreements` - Agreement workflow testing  
- `http://localhost:3000/up` - Rails health check

## Key AI Agent Analysis Patterns

### 1. Service Delegation Pattern
**Models delegate business logic to services**: When analyzing model methods, check for `@service ||= SomeService.new(self)` patterns and follow delegation chains.

### 2. Multi-Database Awareness  
**Database operations may target specific databases**: Check for `connects_to` configurations and migration paths when analyzing data access patterns.

### 3. Privacy/Visibility System
**Field-level access controls**: The `Project` model uses `ProjectVisibilityService` for granular field visibility. Analyze `public_fields` attributes and visibility service methods.

### 4. GitHub Integration Complexity
**Heavy GitHub API usage**: The `ProjectGithubService` and related models handle complex Git data synchronization. Analyze commit tracking, branch management, and contribution calculations.

### 5. Agreement Workflow State Machine
**Complex status transitions**: The `Agreement` model uses `AgreementStatusService` for state management. Analyze turn-based negotiation logic and counter-offer workflows.

### 6. Turbo-Rails Frontend Pattern
**Server-rendered JavaScript**: Controllers return Turbo Streams and Frames. When analyzing frontend interactions, look for `respond_to :turbo_stream` and frame-specific rendering.

## Critical Files for AI Agent Analysis

### Configuration Files
- `config/database.yml`: Multi-database setup with CI conditionals
- `config/routes.rb`: RESTful routes with nested resources
- `Gemfile`: Dependency management and gem versions

### Business Logic Concentration
- `app/models/agreement.rb`: Core agreement workflow logic
- `app/models/project.rb`: GitHub integration and privacy controls  
- `app/services/agreement_status_service.rb`: Agreement state machine
- `app/services/project_github_service.rb`: Git repository integration

### Testing Infrastructure  
- `spec/support/coverage.rb`: SimpleCov configuration
- `bin/test`: Custom test runner with type-specific execution
- `.github/workflows/ci.yml`: Streamlined CI pipeline

## AI Agent Troubleshooting Guide

### Common Analysis Points
1. **Service Method Delegation**: If a model method seems empty, check for service delegation
2. **Multi-Database Operations**: Verify which database context is being used for operations
3. **Privacy System**: Check field visibility before assuming data access patterns
4. **GitHub Integration**: Understand that GitHub data is cached locally and synchronized
5. **Agreement Workflows**: Follow state machine logic through service objects
6. **Testing Context**: Distinguish between unit, integration, and system test contexts

### Performance Considerations
- **N+1 Query Prevention**: Models use `includes` in scopes for eager loading
- **Service Object Memoization**: Services cache expensive operations in instance variables
- **Database Connection Pooling**: Multi-database setup requires careful connection management

## Current Development Status

### Recently Completed
- **GitHub Actions CI/CD**: Streamlined pipeline with parallel linting and essential testing
- **Turbo Stream Implementation**: Complete time tracking system with real-time UI updates
- **Toast Notification System**: Modern, non-obstructive alerts with auto-dismiss
- **Multi-Database Setup**: Rails 8.0 architecture with conditional CI configuration
- **Test Infrastructure**: Custom test runner with type-specific execution and coverage reporting

### Development Tools Available
- **Custom Scripts**: `./bin/test`, `./bin/lint`, `./bin/dev` for streamlined development
- **Parallel Processing**: Linting runs in parallel threads for faster feedback
- **Coverage Reporting**: SimpleCov with HTML and LCOV formats
- **Development Endpoints**: `/test/turbo`, `/test/agreements` for feature verification

### AI Agent Integration Notes
- **Service Pattern Recognition**: Look for `@service ||= ServiceClass.new(self)` patterns
- **Turbo Stream Analysis**: Check for `respond_to :turbo_stream` and multiple simultaneous updates
- **Privacy System Logic**: Analyze `ProjectVisibilityService` for field-level access controls
- **GitHub Data Flow**: Understand cached local synchronization vs. live API calls
- **Multi-Database Context**: Verify which database (primary/cache/queue/cable) operations target

**AI Agent Final Note**: This codebase follows Rails conventions with heavy service-oriented architecture. Always check service objects for actual business logic implementation before assuming model-based logic patterns. The system emphasizes real-time interactions via Turbo Streams and maintains data consistency across multiple database contexts.
