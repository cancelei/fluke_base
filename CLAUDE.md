# Claude Code Configuration

## Testing Commands

> **MCP**: Use `fb_sync` to ensure project context is loaded before testing

- `rails server` - Start development server (port 3006)
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
- `http://localhost:3006/test/turbo` - Turbo fixes summary
- `http://localhost:3006/test/agreements` - Agreements Turbo features test
- `http://localhost:3006/up` - Rails health check

These endpoints work without authentication and confirm all Turbo implementations are working.

## Database Setup Commands

> **MCP**: Use `env_sync` to fetch environment variables, `env_validate` to check completeness

- `rails db:create` - Create database
- `rails db:migrate` - Run migrations
- `rails db:seed` - Seed initial data
- `rails db:reset` - Reset database completely

## Linting Commands
- `./bin/lint` - Run all linters in parallel (RuboCop, Brakeman, ERB Lint, ESLint)
- `./bin/lint --fix` - Run linters with auto-fix where possible
- `npm run js-lint` - Run ESLint for JavaScript files
- `npm run js-lint-fix` - Run ESLint with auto-fix
- `npm run css-lint` - Run Stylelint for CSS files
- `npm run css-lint-fix` - Run Stylelint with auto-fix
- `npm run format-check` - Check code formatting with Prettier
- `npm run format-fix` - Fix code formatting with Prettier
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
- Rails 8.1 multi-database support: primary, cache, queue, cable databases
- CI environment automatically disables additional databases via ENV["CI"] check

## Turbo Testing Notes
- All Turbo implementations have been reviewed and fixed
- Frame structure corrected in agreements/show.html.erb
- Flash messaging properly configured for Turbo Streams
- Controller responses include proper frame awareness
- JavaScript moved to Stimulus controllers
- See `docs/TURBO_BEST_PRACTICES.md` for detailed patterns and anti-patterns

### Turbo Frame Anti-Patterns to Avoid

1. **Never use Turbo Stream for lazy-loaded frames**: Lazy frames expect `<turbo-frame>` responses, not `<turbo-stream>` responses
2. **Always include frame wrapper in partials**: Partials rendered for lazy frames must wrap content in matching `turbo_frame_tag`
3. **Use consistent frame ID patterns**: Follow `dom_id(model)_section` convention (e.g., `agreement_123_github`)
4. **Match frame IDs across create/update paths**: Ensure form error handling uses the same frame ID as success paths

## Devise Authentication (No Turbo)

**Important**: All Devise views use `data: { turbo: false }` to disable Turbo Drive.

### Rationale
- Authentication flows (sign up, sign in, password reset) use traditional full-page requests
- Simplifies error handling and redirects for authentication
- Avoids complexity with Turbo Stream responses for auth failures
- Cloudflare Turnstile widget works reliably with standard form submissions

### Affected Views
All forms in `app/views/devise/` have `data: { turbo: false }`:
- `registrations/new.html.erb` - Sign up
- `registrations/edit.html.erb` - Edit account
- `sessions/_form.html.erb` - Sign in
- `passwords/new.html.erb` - Forgot password
- `passwords/edit.html.erb` - Reset password
- `confirmations/new.html.erb` - Resend confirmation
- `unlocks/new.html.erb` - Unlock account

### Custom Devise Controllers
Located in `app/controllers/users/`:
- `registrations_controller.rb` - Handles sign up with Turnstile validation
- `sessions_controller.rb` - Handles sign in with Turnstile validation
- `passwords_controller.rb` - Handles password reset

All controllers include `skip_before_action :authenticate_user!` for public actions.

## Unified Notification System

The application uses a DRY notification system with two types of feedback:
- **Toasts**: Floating notifications that auto-dismiss (for Turbo Stream responses)
- **Flash Messages**: Inline alerts within page content (for non-Turbo pages)

### ViewComponents
Both types use centralized ViewComponents with shared configuration:
- `Ui::ToastComponent` - Floating toast notifications with auto-dismiss
- `Ui::FlashMessageComponent` - Inline alert banners
- `Ui::SharedConstants` - Shared type mappings, colors, and position classes

### Partials (DRY Usage)
```erb
<%# Toast notification (typically via Turbo Stream) %>
<%= render "shared/toast_notification", type: :success, message: "Saved!" %>

<%# Inline flash message %>
<%= render "shared/flash_message", type: :notice, message: "Welcome!" %>

<%# Turbo Stream toast (for turbo_stream.append) %>
<%= render "shared/toast_turbo_stream", type: :error, message: "Failed" %>
```

### Controller Helpers
```ruby
# In ApplicationController - stream toast notifications
stream_toast_success("Operation completed!")
stream_toast_error("Something went wrong")
stream_toast_info("FYI...")
stream_toast_warning("Be careful!")
```

### Z-Index Layering
Toasts use `z-[10000]` to appear above all UI elements:
- Drawer/Sidebar: `z-[9999]`
- Toast notifications: `z-[10000]`
- Configured in `Ui::SharedConstants::TOAST_POSITIONS` and `application.css`

### Toast Options
- `type`: `:success`, `:error`, `:warning`, `:info`, `:notice`, `:alert`
- `message`: Notification text (required)
- `title`: Optional title
- `timeout`: Auto-dismiss time in ms (default: 5000)
- `close_button`: Show close button (default: true)
- `position`: Toast position (default: "toast-top-right")

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

## AI Productivity Insights System

FlukeBase provides AI productivity insights to help users understand the value of AI-assisted development. The system tracks metrics from flukebase-connect MCP sessions and displays them on the dashboard.

### Metric Types

| Type | Description | Key Data Points |
|------|-------------|-----------------|
| `time_saved` | Estimated time saved by AI | ai_time_ms, estimated_human_time_ms, efficiency_ratio |
| `code_contribution` | Code changes from AI sessions | lines_added, lines_removed, commits, files_changed |
| `task_velocity` | WeDo task completion rates | tasks_completed, tasks_created, completion_rate |
| `token_efficiency` | Token usage and costs | total_tokens, input/output_tokens, estimated_cost_usd |

### Key Models

- **`AiProductivityMetric`** - Stores metrics synced from flukebase-connect
  - Scopes: `time_saved`, `code_contributions`, `task_velocity`, `token_efficiency`
  - Period types: `session`, `daily`, `weekly`, `monthly`
  - Aggregation methods: `aggregate_for_project(project_id, since:)`

- **`UserOnboardingProgress`** - Tracks progressive disclosure of insights
  - Stages: `new_user` → `first_connection` → `first_ai_session` → `first_task_completed` → `insights_explored` → `onboarding_complete`
  - Methods: `mark_insight_seen!`, `mark_milestone_completed!`, `advance_stage!`, `progress_percentage`

- **`AiProductivityStat`** - Materialized view for fast aggregated queries
  - Refresh: `AiProductivityStat.refresh_all` or via scheduled job

### API Endpoints (flukebase-connect sync)

All endpoints require API token with `read:metrics` or `write:metrics` scope.

```
GET    /api/v1/flukebase_connect/projects/:id/productivity_metrics
GET    /api/v1/flukebase_connect/projects/:id/productivity_metrics/:id
POST   /api/v1/flukebase_connect/projects/:id/productivity_metrics
GET    /api/v1/flukebase_connect/projects/:id/productivity_metrics/summary
POST   /api/v1/flukebase_connect/projects/:id/productivity_metrics/bulk_sync
```

### Dashboard Integration

```ruby
# In DashboardController
@ai_insights = AiInsightsService.new(current_user, @project).dashboard_insights
```

```erb
<%# In dashboard view %>
<%= render "dashboard/ai_insights_section", insights: @ai_insights %>
```

### ViewComponents

- **`AiInsights::InsightCardComponent`** - Dismissible insight card with icon, value, trend
- Stimulus controller: `insight_card_controller.js` - handles dismiss, navigate, mark_seen

### Service Layer

```ruby
# AiInsightsService provides all dashboard insight calculations
service = AiInsightsService.new(user, project)

service.dashboard_insights     # All insights for dashboard display
service.time_saved_summary     # Detailed time saved breakdown
service.code_contribution_summary
service.task_velocity_summary
service.token_efficiency_summary
```

### API Token Scopes

The following scopes are available for AI productivity metrics:
- `read:metrics` - Read productivity metrics and summaries
- `write:metrics` - Create/update productivity metrics (for sync)

## MCP Tools Integration (flukebase-connect)

This project supports flukebase-connect MCP tools for AI agent assistance. See [API Token Setup](docs/guides/development/api-token-setup.md) for authentication.

### Quick Reference

| When you need to... | Use this MCP tool |
|---------------------|-------------------|
| Authenticate with FlukeBase | `fb_login` |
| Check connection status | `fb_status` |
| List your projects | `fb_projects` |
| Sync project context + .env | `fb_sync` |
| Sync only environment vars | `env_sync` |
| View current env vars | `env_show` |
| Compare local vs FlukeBase env | `env_diff` |
| Validate required env vars | `env_validate` |
| Store knowledge for later | `remember` |
| Search stored knowledge | `recall` |
| Remove stored memory | `forget` |
| Get convention rationale | `why` |
| View AI productivity summary | `ai_productivity_summary` (planned) |
| Sync metrics to FlukeBase | `ai_sync_metrics` (planned) |

### Decision Tree

```
Starting session?
├── `fb_status` → check connection
├── Not connected? → `fb_login`
└── Connected? → `fb_sync` for context

Environment issues?
├── Missing vars? → `env_validate`
├── Out of sync? → `env_diff` then `env_sync`
└── View current? → `env_show`

Remember something?
├── Store → `remember` (type: fact/convention/gotcha/decision)
├── Search → `recall`
└── Understand why → `why`
```

### MCP Plugin Status

**Production Ready:**
- FlukeBase Core - Authentication, projects, sync
- Environment Manager - Environment variable management
- Memory Store - Persistent knowledge storage
- AI Productivity Metrics API - Rails backend ready for sync

**In Development:**
- AI Productivity Plugin - MCP tools for productivity tracking (ONBOARD-003-007)
  - `ai_productivity_summary` - Get session productivity metrics
  - `ai_time_saved` - Detailed time saved breakdown
  - `ai_code_attribution` - Code contributions from AI sessions
  - `ai_sync_metrics` - Sync metrics to FlukeBase

**Conceptual (Future):**
- GitHub Integration - Direct PR/issue access
- OpenAI Provider - GPT model integration
- Anthropic Provider - Claude API integration