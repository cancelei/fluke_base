# FlukeBase

FlukeBase is a Rails 8.0.2 collaborative platform connecting entrepreneurs, mentors, and co-founders through structured agreements, project management, and integrated time tracking.

## 🚀 Quick Start

### Requirements
- Ruby 3.2.1+
- PostgreSQL 16+
- Node.js 20+
- Git

### Development Setup

```bash
# Clone and setup
git clone <repository-url>
cd fluke_base
bundle install
npm install

# Database setup
rails db:create
rails db:migrate
rails db:seed

# Start development server
rails server
```

Visit `http://localhost:3000` to access the application.

### Test Endpoints (Development)
- `http://localhost:3000/test/turbo` - Turbo implementation verification
- `http://localhost:3000/test/agreements` - Agreement workflows testing
- `http://localhost:3000/up` - Rails health check

## 🧪 Testing & Quality

### Running Tests
```bash
# Essential tests (models + helpers)
./bin/test

# Test types
./bin/test --type unit          # Models, services, helpers
./bin/test --type integration   # Controllers, requests  
./bin/test --type system        # End-to-end browser tests

# With coverage reporting
./bin/test --coverage

# Full CI pipeline locally
npm run ci
```

### Code Quality
```bash
# Linting and security
bundle exec rubocop             # Ruby code style
bundle exec brakeman            # Security analysis
bundle exec erb_lint            # ERB template linting
npm run lint:js                 # JavaScript linting

# Auto-fix issues
npm run lint:fix
```

## 🏗️ Architecture

### Technology Stack
- **Backend**: Rails 8.0.2 with multi-database architecture
- **Frontend**: Turbo-Rails, Stimulus, TailwindCSS
- **Database**: PostgreSQL (primary, cache, queue, cable)
- **Authentication**: Devise
- **Authorization**: CanCanCan
- **Payments**: Pay gem with Stripe
- **Background Jobs**: Solid Queue
- **Real-time**: Solid Cable (ActionCable)
- **Deployment**: Kamal with Docker

### Multi-Database Setup
The application uses Rails 8.0's multi-database support:
- **Primary**: Main application data (users, projects, agreements)
- **Cache**: Solid Cache storage
- **Queue**: Background job processing
- **Cable**: WebSocket connections

### Key Services
- `AgreementStatusService` - Agreement lifecycle management
- `ProjectGithubService` - GitHub integration and commit tracking
- `ProjectVisibilityService` - Field-level privacy controls
- `UserOnboardingService` - Role-based user workflows

## 💼 Core Features

### User Management
- Multi-role system (entrepreneur, mentor, co-founder)
- Role-based onboarding workflows
- Project context switching
- GitHub integration for developers

### Project Collaboration
- **Project Stages**: Idea → Prototype → Launched → Scaling
- **Privacy Controls**: Field-level visibility settings
- **GitHub Integration**: Commit tracking and contribution analysis
- **Milestone Management**: Progress tracking with confirmations

### Agreement Workflows
- **Types**: Mentorship and Co-founder agreements
- **Payment Models**: Hourly, Equity, or Hybrid compensation
- **Turn-based Negotiations**: Counter-offer system
- **Status Tracking**: Pending → Accepted/Rejected → Completed

### Time Tracking (Turbo-Enhanced)
- **Real-time Interface**: No page reloads, instant UI updates
- **Multi-component Sync**: Navbar, main page, and progress bars synchronized
- **Manual & Automatic**: Flexible time logging options
- **Milestone Integration**: Progress tracking tied to project milestones

### Communication
- **Direct Messaging**: User-to-user conversations
- **Notifications**: System-wide notification management
- **Toast System**: Modern, non-obstructive alerts with auto-dismiss

## 🔧 Development

### Environment Variables
```bash
# Database
FLUKE_BASE_DATABASE_USERNAME=postgres
FLUKE_BASE_DATABASE_PASSWORD=your_password

# External APIs
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
STRIPE_PUBLISHABLE_KEY=your_stripe_key
STRIPE_SECRET_KEY=your_stripe_secret

# Background Jobs
SOLID_QUEUE_IN_PUMA=true
JOB_CONCURRENCY=3
```

### Database Commands
```bash
rails db:create                # Create databases
rails db:migrate               # Run migrations
rails db:migrate:status        # Check migration status
rails db:seed                  # Load sample data
rails db:reset                 # Reset and reseed
```

### GitHub Actions CI/CD
Streamlined pipeline with parallel linting and essential testing:
- **Parallel Linting**: RuboCop, Brakeman, ERB Lint, ESLint
- **Essential Tests**: Models and helpers with coverage reporting
- **PostgreSQL Service**: Automated database setup
- **Coverage Reports**: SimpleCov with HTML and LCOV outputs

## 🎯 Key Implementation Details

### Turbo-Rails Integration
The application extensively uses Turbo Streams for seamless interactions:
- **Time Tracking**: Multi-component updates without page reloads
- **Agreement Workflows**: Real-time form submissions and status updates
- **Navigation**: Context-preserving interactions across all components

### Service-Oriented Architecture
Business logic is encapsulated in dedicated service objects, keeping models focused on data relationships while services handle complex operations.

### Privacy & Visibility System
Projects implement field-level privacy controls, allowing users to selectively share information based on agreement status and user relationships.

### Multi-Database Performance
Optimized for scalability with separate databases for caching, background jobs, and real-time features while maintaining data consistency.

## 📖 Documentation

### For Developers
- `CLAUDE.md` - Claude Code configuration and testing commands
- `README_AI_AGENTS.md` - Comprehensive codebase analysis guide for AI agents

### Implementation Guides
- Turbo Stream implementation provides seamless user experience
- Toast notification system for modern, non-obstructive feedback
- GitHub integration for developer project tracking
- Multi-database deployment configuration

## 🚀 Deployment

### Production Setup
```bash
# Using Kamal
kamal setup                     # Initial deployment setup
kamal deploy                    # Deploy application
kamal app logs                  # View application logs
```

### Key Configuration
- **Background Jobs**: Solid Queue runs within Puma processes
- **Database**: Uses primary database for all operations in production
- **Caching**: Solid Cache for Rails.cache operations
- **Real-time**: Solid Cable for WebSocket connections

### Health Monitoring
- Health check endpoint: `/up`
- Background job monitoring via admin panel
- Database connection pooling for multi-database setup

## 🤝 Contributing

### Development Workflow
1. Create feature branch from `main`
2. Implement changes with tests
3. Ensure all linting passes: `npm run lint:fix`
4. Run test suite: `./bin/test --coverage`
5. Create pull request

### Code Standards
- Follow Rails conventions and established patterns
- Use service objects for complex business logic
- Implement Turbo Streams for dynamic interactions
- Maintain test coverage for new features
- Document significant architectural decisions

### Testing Requirements
- Unit tests for models and services
- Integration tests for controller workflows
- System tests for critical user journeys
- Coverage reporting via SimpleCov

---

**Version**: Rails 8.0.2 | **Ruby**: 3.2.1 | **Node**: 20+ | **Database**: PostgreSQL 16