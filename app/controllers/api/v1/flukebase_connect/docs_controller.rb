# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class DocsController < BaseController
        # No specific scope required - just valid token
        # These are documentation endpoints for authenticated AI agents

        # GET /api/v1/flukebase_connect/docs/llms.txt
        def llms_txt
          render plain: llms_navigation_content, content_type: "text/plain; charset=utf-8"
        end

        # GET /api/v1/flukebase_connect/docs/llms-full.txt
        def llms_full_txt
          render plain: llms_full_content, content_type: "text/plain; charset=utf-8"
        end

        private

        def llms_navigation_content
          <<~LLMS
            # FlukeBase

            > FlukeBase is a startup collaboration platform built with Rails 8. It provides project management, agreement negotiation, time tracking, and AI productivity insights. The platform integrates with AI coding assistants via the flukebase-connect MCP server.

            ## Quick Start

            - [Local Setup](https://flukebase.com/docs/quick-start/local-setup): Get your development environment running
            - [CLAUDE.md](https://github.com/cancelei/fluke_base/blob/main/CLAUDE.md): Testing commands and development workflow

            ## API Reference

            - [API Endpoints](https://flukebase.com/docs/reference/api-endpoints): Complete REST API reference (58 endpoints)
            - [OpenAPI Spec](https://flukebase.com/api-docs): Interactive Swagger UI documentation
            - [API Token Setup](https://flukebase.com/docs/guides/development/api-token-setup): Authentication with Bearer tokens

            ## Core Concepts

            - [Agreement Negotiation](https://flukebase.com/docs/guides/workflows/agreement-negotiation-state-machine): Turn-based negotiation state machine
            - [Multi-Database Architecture](https://flukebase.com/docs/guides/architecture/multi-database-architecture): Rails 8 multi-DB (primary, cache, queue, cable)
            - [Privacy Visibility System](https://flukebase.com/docs/guides/architecture/privacy-visibility-system): Field-level access control

            ## MCP Integration

            - [FlukeBase Connect API](https://flukebase.com/docs/guides/integrations/flukebase-connect-api): MCP server integration for AI assistants
            - [Environment Sync](https://flukebase.com/docs/reference/environment-variables): Environment variable management

            ## Frontend

            - [Stimulus Guidelines](https://flukebase.com/docs/guides/frontend/stimulus-usage-guidelines): Stimulus controller patterns
            - [Turbo Patterns](https://flukebase.com/docs/guides/frontend/turbo-patterns): Turbo Drive, Frames, Streams

            ## Testing

            - [Testing Strategy](https://flukebase.com/docs/guides/testing/testing-strategy): RSpec, Playwright, SimpleCov
            - [Command Reference](https://flukebase.com/docs/reference/command-reference): CLI commands

            ## Optional

            - [GitHub Integration](https://flukebase.com/docs/guides/integrations/github-api-integration): Commit tracking
            - [Stripe Payments](https://flukebase.com/docs/guides/integrations/stripe-payments): Pay gem integration
            - [Kamal Deployment](https://flukebase.com/docs/guides/development/kamal-deployment): Docker deployment
          LLMS
        end

        def llms_full_content
          <<~LLMS_FULL
            # FlukeBase

            > FlukeBase is a startup collaboration platform built with Rails 8.0.4 and Ruby 3.4.4. It provides project management, agreement negotiation, time tracking, and AI productivity insights. The platform integrates with AI coding assistants via the flukebase-connect MCP server.

            ## Technology Stack

            - Backend: Rails 8.0.4, PostgreSQL 16+, Multi-database architecture (primary, cache, queue, cable)
            - Frontend: TailwindCSS 4.0, DaisyUI, Stimulus.js, Hotwire (Turbo)
            - Asset Pipeline: Propshaft
            - Components: ViewComponent
            - Authentication: Devise
            - Authorization: CanCanCan
            - Payments: Pay gem with Stripe
            - Background Jobs: Solid Queue
            - WebSockets: Solid Cable
            - Cache: Solid Cache
            - Testing: RSpec, Playwright, SimpleCov
            - Deployment: Kamal with Docker

            ## API Reference

            Base URL: `/api/v1/flukebase_connect`

            All endpoints require Bearer token authentication: `Authorization: Bearer fbk_xxxxx`

            ### Authentication Endpoints

            ```
            GET /auth/validate
            ```
            Validates API token. Returns: `{ valid: true, user_id: 123, scopes: [...] }`

            ```
            GET /auth/me
            ```
            Returns current user info: `{ id, email, name, project_count }`

            ### Projects Endpoints

            ```
            GET /projects
            ```
            List all accessible projects. Scope: `read:projects`

            ```
            GET /projects/:id
            ```
            Get project details. Scope: `read:projects`

            ```
            POST /projects
            ```
            Create new project. Scope: `write:projects`

            ```
            GET /projects/:id/context
            ```
            Get AI-optimized project context. Scope: `read:context`

            ```
            GET /projects/find?repository_url=owner/repo
            ```
            Find project by repository URL. Scope: `read:projects`

            ### Environment Endpoints

            ```
            GET /projects/:project_id/environment/variables?environment=development
            ```
            Get environment variables. Scope: `read:environment`

            ```
            POST /projects/:project_id/environment/sync
            ```
            Record sync event. Scope: `read:environment`

            ### Memories Endpoints

            ```
            GET /projects/:project_id/memories
            ```
            List project memories. Query: `type`, `tags[]`. Scope: `read:memories`

            ```
            POST /projects/:project_id/memories
            ```
            Create memory. Scope: `write:memories`

            ```
            PATCH /projects/:project_id/memories/:id
            ```
            Update memory. Scope: `write:memories`

            ```
            DELETE /projects/:project_id/memories/:id
            ```
            Delete memory. Scope: `write:memories`

            ```
            POST /projects/:project_id/memories/bulk_sync
            ```
            Bulk sync memories. Scope: `write:memories`

            ```
            GET /memories/search
            ```
            Cross-project memory search. Scope: `read:memories`

            ### Webhooks Endpoints

            ```
            GET /projects/:project_id/webhooks
            POST /projects/:project_id/webhooks
            PUT /projects/:project_id/webhooks/:id
            DELETE /projects/:project_id/webhooks/:id
            GET /projects/:project_id/webhooks/:id/deliveries
            GET /projects/:project_id/webhooks/events
            ```
            Webhook subscriptions. Scopes: `read:webhooks`, `write:webhooks`

            ### Productivity Metrics Endpoints

            ```
            GET /projects/:project_id/productivity_metrics
            POST /projects/:project_id/productivity_metrics
            GET /projects/:project_id/productivity_metrics/summary
            POST /projects/:project_id/productivity_metrics/bulk_sync
            ```
            AI productivity tracking. Scopes: `read:metrics`, `write:metrics`

            ### WeDo Tasks Endpoints

            ```
            GET /projects/:project_id/wedo_tasks
            POST /projects/:project_id/wedo_tasks
            PUT /projects/:project_id/wedo_tasks/:id
            DELETE /projects/:project_id/wedo_tasks/:id
            POST /projects/:project_id/wedo_tasks/bulk_sync
            ```
            Task management. Scopes: `read:tasks`, `write:tasks`

            ### Agent Sessions Endpoints

            ```
            GET /projects/:project_id/agents
            POST /projects/:project_id/agents/register
            POST /projects/:project_id/agents/:id/heartbeat
            PUT /projects/:project_id/agents/:id
            DELETE /projects/:project_id/agents/:id
            GET /projects/:project_id/agents/whoami
            POST /projects/:project_id/agents/cleanup
            ```
            Agent session management. Scopes: `read:agents`, `write:agents`

            ### Portfolio Analytics Endpoints

            ```
            GET /portfolio/summary
            ```
            Aggregated metrics across all projects. Query: `period` (days). Scope: `read:metrics`

            ```
            GET /portfolio/compare
            ```
            Rank projects by productivity. Query: `period`, `sort_by`, `limit`. Scope: `read:metrics`

            ```
            GET /portfolio/trends
            ```
            Time-series productivity data. Query: `period`, `granularity`. Scope: `read:metrics`

            ### Delegation Endpoints

            ```
            GET /projects/:project_id/delegation/status
            POST /projects/:project_id/delegation/pool
            POST /projects/:project_id/delegation/claim
            POST /projects/:project_id/delegation/report_context
            POST /projects/:project_id/delegation/handoff
            GET /projects/:project_id/delegation/next_task
            ```
            Container-based task delegation. Scopes: `read:delegation`, `write:delegation`

            ## MCP Tools Quick Reference

            | Tool | Purpose | API Endpoint |
            |------|---------|--------------|
            | fb_login | Authenticate | GET /auth/validate |
            | fb_status | Check connection | GET /auth/me |
            | fb_projects | List projects | GET /projects |
            | fb_sync | Sync context + env | GET /projects/:id/context + /environment/variables |
            | env_sync | Sync environment | GET /projects/:id/environment/variables |
            | env_show | View current env | (local) |
            | env_diff | Compare local vs remote | (local + API) |
            | env_validate | Check required vars | (local) |
            | remember | Store knowledge | POST /memories (optional sync) |
            | recall | Search knowledge | (local) |
            | forget | Remove memory | (local) |

            ## Testing Commands

            ```bash
            ./bin/test                    # Run essential tests
            ./bin/test --coverage         # Run with coverage
            ./bin/test --type unit        # Unit tests only
            ./bin/test --type integration # Integration tests
            ./bin/test --type system      # E2E tests
            bundle exec rspec             # RSpec directly
            ```

            ## Development Commands

            ```bash
            rails server              # Start dev server (port 3006)
            rails console             # Rails console
            rails db:migrate          # Run migrations
            ./bin/lint                # Run all linters
            ./bin/lint --fix          # Linters with auto-fix
            ```

            ## Core Domain Models

            ### Agreement Negotiation State Machine

            States: PENDING -> ACCEPTED | REJECTED | COUNTERED

            Turn-based negotiation:
            - `accept_or_counter_turn_id` determines whose turn
            - Counter offers tracked via `agreement_participants.counter_agreement_id`
            - Payment models: Hourly, Equity, Hybrid

            ### Memory Types

            - `fact`: Project-specific information
            - `convention`: Coding standards and patterns
            - `gotcha`: Known issues and workarounds
            - `decision`: Architectural decisions with rationale

            ### Productivity Metric Types

            - `time_saved`: AI time vs estimated human time
            - `code_contribution`: Lines added/removed, commits, files
            - `task_velocity`: Tasks completed/created, completion rate
            - `token_efficiency`: Token usage and estimated cost

            ## API Token Scopes

            | Feature | Read Scope | Write Scope |
            |---------|------------|-------------|
            | Projects | read:projects | write:projects |
            | Environment | read:environment | write:environment |
            | Context | read:context | - |
            | Memories | read:memories | write:memories |
            | Webhooks | read:webhooks | write:webhooks |
            | Metrics | read:metrics | write:metrics |
            | Tasks | read:tasks | write:tasks |
            | Agents | read:agents | write:agents |
            | Delegation | read:delegation | write:delegation |

            ## Error Responses

            ```json
            // 401 Unauthorized
            { "error": "Invalid or missing API token" }

            // 403 Forbidden
            { "error": "Insufficient permissions for this resource" }

            // 404 Not Found
            { "error": "Project not found" }
            ```

            ## Rate Limiting

            - Rate: 100 requests per minute per token
            - Headers: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset

            ## Anti-Patterns

            - DO NOT update agreement.status directly (use service methods)
            - DO NOT allow actions outside user's turn
            - DO NOT call env_sync repeatedly in a loop
            - DO NOT store secrets with remember tool
            - DO use AgreementStatusService for all status changes
            - DO use fb_sync for initial context loading
            - DO use env_validate before running tests

            ## Key Files

            - `app/controllers/api/v1/flukebase_connect/` - API controllers
            - `app/models/api_token.rb` - Token model
            - `app/models/agreement.rb` - Agreement state machine
            - `app/services/` - Service objects (11 services)
            - `spec/` - RSpec tests (169 spec files)
            - `CLAUDE.md` - Development commands and testing
          LLMS_FULL
        end
      end
    end
  end
end
