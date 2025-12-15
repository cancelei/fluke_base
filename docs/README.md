# FlukeBase Documentation Hub

**Last Updated**: 2025-12-13
**Project**: FlukeBase - Startup Collaboration Platform
**Rails Version**: 8.0.4
**Ruby Version**: 3.4.4

Welcome to the FlukeBase documentation! This hub provides comprehensive guides for developers and AI agents working with the FlukeBase codebase.

---

## 📚 Documentation Structure

This documentation follows a **category-based organization** inspired by best practices for AI-agent-optimized technical documentation. Each document includes:

- **Metadata headers** (Last Updated, Document Type, Audience)
- **Decision trees** for complex workflows
- **Anti-patterns** clearly marked with ❌
- **Real code examples** with file paths and line numbers
- **AI Agent sections** with prescriptive guidance

---

## 🚀 Quick Start

**New to FlukeBase?** Start here:

1. **[Local Setup](quick-start/local-setup.md)** - Get your development environment running
2. **[First Project](quick-start/first-project.md)** - Create your first startup project
3. **[First Agreement](quick-start/first-agreement.md)** - Set up a mentorship agreement
4. **[Testing Quick Start](quick-start/testing-quick-start.md)** - Run tests and verify everything works

---

## 📖 Comprehensive Guides

### Workflows

Complex multi-step processes and state machines:

- **[Agreement Negotiation State Machine](guides/workflows/agreement-negotiation-state-machine.md)** 🎯 - Turn-based negotiation with counter offers
- **[Project Creation Flow](guides/workflows/project-creation-flow.md)** - Setting up startup projects
- **[Time Tracking Workflow](guides/workflows/time-tracking-workflow.md)** - Real-time Turbo-enhanced time logging
- **[GitHub Commit Fetching](guides/workflows/github-commit-fetching.md)** 🎯 - Automated contribution tracking
- **[Messaging System](guides/workflows/messaging-system.md)** - User-to-user communication

### Frontend Development

Stimulus, Turbo, and modern JavaScript patterns:

- **[Stimulus Usage Guidelines](guides/frontend/stimulus-usage-guidelines.md)** 🎯 - Audit 23 controllers, prevent bloat
- **[Turbo Patterns](guides/frontend/turbo-patterns.md)** - Turbo Drive, Frames, and Streams best practices
- **[Real-Time Updates](guides/frontend/real-time-updates.md)** - ActionCable with SolidCable
- **[Toast Notification System](guides/frontend/toast-notification-system.md)** - Modern alert system
- **[Modal Patterns](guides/frontend/modal-patterns.md)** - Modal controller implementation

### Architecture

Core business logic and design patterns:

- **[Multi-Database Architecture](guides/architecture/multi-database-architecture.md)** 🎯 - Rails 8 multi-DB (primary, cache, queue, cable)
- **[Service Layer Patterns](guides/architecture/service-layer-patterns.md)** - 11 service objects documented
- **[Agreement Domain Model](guides/architecture/agreement-domain-model.md)** - Complex business logic
- **[Privacy Visibility System](guides/architecture/privacy-visibility-system.md)** 🎯 - Field-level project access control
- **[Unified User Experience](guides/architecture/unified-user-experience.md)** - No role-based restrictions

### Database

Schema, migrations, and performance:

- **[Schema Overview](guides/database/schema-overview.md)** - ER diagram with 20 models
- **[Migrations Guide](guides/database/migrations-guide.md)** - Multi-DB migration strategies
- **[Primary Database](guides/database/primary-database.md)** - Main application data
- **[Cache, Queue, Cable Databases](guides/database/cache-queue-cable-databases.md)** - Rails 8 multi-DB setup
- **[Performance Optimization](guides/database/performance-optimization.md)** - Query patterns and indexing

### Integrations

Third-party APIs and services:

- **[GitHub API Integration](guides/integrations/github-api-integration.md)** 🎯 - Commit tracking and branch management
- **[Stripe Payments](guides/integrations/stripe-payments.md)** - Pay gem integration
- **[Google Calendar](guides/integrations/google-calendar.md)** - Meeting scheduling
- **[Cloudflare Turnstile](guides/integrations/cloudflare-turnstile.md)** - Bot protection

### Testing

Test strategies and examples:

- **[Testing Strategy](guides/testing/testing-strategy.md)** - Overall testing approach
- **[Unit Testing Guide](guides/testing/unit-testing-guide.md)** - Models and services (RSpec)
- **[Integration Testing Guide](guides/testing/integration-testing-guide.md)** - Controllers and requests
- **[Playwright E2E Guide](guides/testing/playwright-e2e-guide.md)** - End-to-end testing
- **[Test Coverage Analysis](guides/testing/test-coverage-analysis.md)** - SimpleCov usage

### Development

Daily workflow and tools:

- **[Development Workflow](guides/development/development-workflow.md)** - Day-to-day development process
- **[Linting Tools](guides/development/linting-tools.md)** - RuboCop, Brakeman, ESLint, ERB Lint
- **[GitHub Actions CI](guides/development/github-actions-ci.md)** - CI/CD pipeline
- **[Kamal Deployment](guides/development/kamal-deployment.md)** - Production deployment with Docker

### Admin

System administration:

- **[Admin Features](guides/admin/admin-features.md)** - Administrative capabilities
- **[System Monitoring](guides/admin/system-monitoring.md)** - Health checks and metrics

---

## 🔍 Quick Reference

Fast lookup for common tasks:

- **[API Endpoints](reference/api-endpoints.md)** - Controller routes catalog (60+ routes)
- **[Model Relationships](reference/model-relationships.md)** - Association diagram (20 models)
- **[Service Catalog](reference/service-catalog.md)** - Service object index (11 services)
- **[Command Reference](reference/command-reference.md)** - CLI commands and testing
- **[Environment Variables](reference/environment-variables.md)** - Complete .env reference

---

## 🤖 For AI Agents

This documentation is optimized for AI agents working with the FlukeBase codebase. Each guide includes:

### Decision Trees

ASCII flowcharts for complex decisions:
```
Can user accept agreement?
│
├─ Is agreement PENDING? → Check whose_turn? == user
├─ Does user have permission? → Check participant role
└─ Valid? → Execute accept! method ✅
```

### Anti-Patterns

Clearly marked incorrect approaches:
- ❌ DO NOT update agreement.status directly (use service methods)
- ❌ DO NOT allow actions outside user's turn
- ✅ DO use AgreementStatusService for all status changes

### Quick Reference Sections

Every guide ends with a "For AI Agents" section containing:
- **Files to Check**: Relevant code file paths
- **Common Tasks**: Step-by-step instructions

---

## 📊 Project Metrics

- **Models**: 20 core models
- **Controllers**: 17+ controllers (~3,500 LOC)
- **Services**: 11 service objects (~2,000 LOC)
- **ViewComponents**: 8 reusable components
- **Background Jobs**: Multiple job classes
- **Stimulus Controllers**: 23 (target: <30)
- **Test Coverage**: 169 RSpec spec files
- **Routes**: 60+ named routes

---

## 🎯 High-Priority Documentation

Start with these critical documents:

1. **[Agreement Negotiation State Machine](guides/workflows/agreement-negotiation-state-machine.md)** - Turn-based system (most complex workflow)
2. **[Multi-Database Architecture](guides/architecture/multi-database-architecture.md)** - Rails 8 multi-DB setup
3. **[GitHub Commit Fetching](guides/workflows/github-commit-fetching.md)** - Integration pipeline
4. **[Stimulus Usage Guidelines](guides/frontend/stimulus-usage-guidelines.md)** - Prevent controller proliferation
5. **[Privacy Visibility System](guides/architecture/privacy-visibility-system.md)** - Field-level access control

---

## 📁 Technical Specifications

Detailed pattern documentation:

- **[Ruby Patterns](../technical_spec/ruby_patterns/README.md)** - Ruby coding patterns
- **[Hotwire Turbo](../technical_spec/hotwire_turbo/README.md)** - Turbo implementation patterns
- **[Stimulus](../technical_spec/stimulus/README.md)** - Stimulus controller patterns
- **[Test Spec](../technical_spec/test_spec/README.md)** - Testing patterns

---

## 📁 Archive

Outdated documentation preserved for reference:

- **[Old Setup Docs](archive/old-setup-docs/)** - STAGING_SETUP.md, FINALIZATION_COMPLETE.md
- **[Old Test Docs](archive/old-test-docs/)** - TEST_IMPLEMENTATION_SUMMARY.md

---

## 🔑 Key Concepts

### Agreement Negotiation

FlukeBase uses a sophisticated turn-based negotiation system:
- **State Machine**: PENDING → ACCEPTED/REJECTED/COUNTERED
- **Counter Offers**: Tracked via agreement_participants.counter_agreement_id
- **Turn Tracking**: accept_or_counter_turn_id determines whose turn it is
- **Payment Models**: Hourly, Equity, or Hybrid compensation

[Learn more →](guides/workflows/agreement-negotiation-state-machine.md)

### Multi-Database Architecture

Rails 8 multi-database configuration:
- **Primary**: Main application data (users, projects, agreements)
- **Cache**: Solid Cache storage
- **Queue**: Solid Queue background jobs
- **Cable**: Solid Cable WebSocket connections

[Learn more →](guides/architecture/multi-database-architecture.md)

### Privacy & Visibility

Field-level access control for project data:
- **Public Fields**: Always visible
- **Private Fields**: Only visible to project owner
- **Agreement-Dependent Fields**: Visible to agreement participants

[Learn more →](guides/architecture/privacy-visibility-system.md)

### Unified User Experience

All authenticated users have equal access:
- **No Role Restrictions**: All users can create projects, agreements, track time
- **Universal Features**: Equal access to all platform capabilities
- **Simplified Architecture**: No role-related complexity

[Learn more →](guides/architecture/unified-user-experience.md)

---

## 🛠️ Technology Stack

- **Backend**: Rails 8.0.4, PostgreSQL 16+, Multi-database architecture
- **Frontend**: TailwindCSS 4.0, DaisyUI, Stimulus.js, Hotwire (Turbo)
- **Asset Pipeline**: Propshaft
- **Components**: ViewComponent
- **Authentication**: Devise
- **Authorization**: CanCanCan
- **Payments**: Pay gem with Stripe
- **GitHub**: Octokit gem
- **Calendar**: Google Calendar API
- **Security**: Cloudflare Turnstile
- **AI**: ruby_llm
- **Background Jobs**: Solid Queue
- **WebSockets**: Solid Cable
- **Cache**: Solid Cache
- **Testing**: RSpec, Playwright, SimpleCov
- **Deployment**: Kamal with Docker, Thruster

---

## 📞 Getting Help

1. **Search this documentation** - Use Ctrl+F or your IDE's file search
2. **Check decision trees** - Most guides have "For AI Agents" sections
3. **Review anti-patterns** - Learn what NOT to do
4. **Examine code examples** - All examples include file paths
5. **Check technical specs** - Detailed patterns in `technical_spec/` directory

---

## 🔄 Documentation Maintenance

This documentation follows these principles:

- **Last Updated dates** on every document
- **Real code examples** with line numbers
- **Visual markers** (✅ ❌ ⚠️) for quick scanning
- **Progressive disclosure**: Quick starts → References → Comprehensive guides
- **AI-first design**: Decision trees and prescriptive guidance

**Contributing**: When updating docs, please:
1. Update the "Last Updated" date
2. Verify code examples with actual file line numbers
3. Add decision trees for complex workflows
4. Mark anti-patterns with ❌

---

## 📚 Related Resources

- **Main README**: [../README.md](../README.md) - Project overview and setup
- **AI Agents Guide**: [../README_AI_AGENTS.md](../README_AI_AGENTS.md) - Codebase analysis for AI
- **Claude Code Config**: [../CLAUDE.md](../CLAUDE.md) - Testing commands
- **Agents Guide**: [../AGENTS.md](../AGENTS.md) - Repository guidelines

---

*This documentation hub was created following patterns from industry-leading Rails projects with AI-agent optimization.*
