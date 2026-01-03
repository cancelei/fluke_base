# Fluke Base - Northstar Goals

> **Created**: 2025-12-29
> **Last Updated**: 2025-12-29
> **Status**: Active

This document outlines the long-term strategic goals for fluke_base and its integration with flukebase_connect.

## Vision

fluke_base is the central platform for project management, collaboration, and AI-powered development workflows. It serves as the source of truth for project context that flows to all AI coding assistants through flukebase_connect.

## Northstar Goals

### 1. Platform-Driven AI Integration
**Goal**: fluke_base controls which AI tools and configurations are available per project

**Current State**:
- MCP infrastructure exists (McpPlugin, McpPreset, ProjectMcpConfiguration)
- API exposes project context to flukebase_connect

**Target State**:
```ruby
# Project admin configures MCP in fluke_base UI
project.mcp_configuration.update(
  preset: "development",
  enabled_plugins: ["flukebase-connect", "github", "sentry"],
  context_level: "full",
  plugin_settings: {
    "flukebase-connect" => { auto_sync: true, memory_sync: true },
    "github" => { repos: ["org/repo"], auto_pr: true }
  }
)

# This automatically:
# 1. Updates API response for flukebase_connect
# 2. Triggers webhook to connected clients
# 3. Reconfigures AI tools on developer machines
```

**Milestones**:
- [x] MCP infrastructure (models, migrations)
- [x] Project context API
- [ ] MCP configuration UI in projects
- [ ] Webhook system for real-time updates
- [ ] Team-level MCP presets
- [ ] Usage analytics dashboard

### 2. Bi-directional Memory Sync
**Goal**: Project memories flow between fluke_base and flukebase_connect

**Implementation Plan**:
```ruby
# fluke_base models
class ProjectMemory < ApplicationRecord
  belongs_to :project
  belongs_to :user

  # memory_type: fact, convention, gotcha, decision
  # external_id: UUID from flukebase_connect
  # synced_at: Last sync timestamp
end

# API endpoints
# POST /api/v1/flukebase_connect/memories - Create from flukebase_connect
# GET  /api/v1/flukebase_connect/memories - Fetch for sync
# PUT  /api/v1/flukebase_connect/memories/:id - Update
```

**Milestones**:
- [ ] ProjectMemory model and migration
- [ ] Memory API endpoints
- [ ] Memory sync service
- [ ] Conflict resolution logic
- [ ] Memory UI in project dashboard

### 3. Real-time Webhook System
**Goal**: Push updates to flukebase_connect when project data changes

**Events to Support**:
- `env.updated` - Environment variable changed
- `env.deleted` - Environment variable deleted
- `milestone.updated` - Milestone status changed
- `memory.synced` - Memory synced from fluke_base
- `mcp.config_changed` - MCP configuration updated

**Implementation**:
```ruby
class WebhookSubscription < ApplicationRecord
  belongs_to :project
  belongs_to :api_token

  # events: Array of event types to subscribe to
  # callback_url: Where to send webhooks
  # secret: HMAC signing key
end

class WebhookDispatcherService
  def dispatch(event_type, payload)
    subscriptions = WebhookSubscription.for_event(event_type)
    subscriptions.each do |sub|
      WebhookDeliveryJob.perform_later(sub.id, event_type, payload)
    end
  end
end
```

**Milestones**:
- [ ] Webhook models and migrations
- [ ] Webhook dispatcher service
- [ ] Delivery job with retry logic
- [ ] Webhook management UI
- [ ] HMAC signature verification

### 4. AI Provider Ecosystem Management
**Goal**: fluke_base tracks and manages AI provider configurations

**Vision**:
```ruby
# Global AI provider registry
class AiProviderRegistry
  PROVIDERS = {
    "anthropic" => {
      tools: ["claude-code", "claude-desktop"],
      docs_url: "https://docs.flukebase.com/ai/anthropic",
      last_audit: Date.parse("2025-12-29")
    },
    "openai" => {
      tools: ["codex-cli", "chatgpt-desktop", "copilot"],
      docs_url: "https://docs.flukebase.com/ai/openai",
      last_audit: Date.parse("2025-12-29")
    },
    # ... more providers
  }
end

# Scheduled audit job
class AiProviderAuditJob < ApplicationJob
  def perform
    # Check documentation currency
    # Verify API compatibility
    # Update last_audit timestamps
    # Notify admins of issues
  end
end
```

**Milestones**:
- [ ] AI provider registry model
- [ ] Automated audit scheduling
- [ ] Documentation sync with flukebase_connect
- [ ] Provider status dashboard

### 5. Developer Experience Dashboard
**Goal**: Visibility into AI tool usage and integration health

**Features**:
- Active flukebase_connect installations per project
- MCP server usage statistics
- Memory sync status
- Environment variable access logs
- Integration health checks

## Integration with flukebase_connect

### Architecture
```
┌─────────────────────────────────────────────────────────────────┐
│                         fluke_base (Rails)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Projects   │  │   Memories   │  │  MCP Config  │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                 │                 │                   │
│         └────────────────┼────────────────┘                    │
│                          │                                      │
│              ┌───────────▼───────────┐                         │
│              │   FlukebaseConnect    │                         │
│              │   ProjectContext API  │                         │
│              └───────────┬───────────┘                         │
│                          │                                      │
│              ┌───────────▼───────────┐                         │
│              │   Webhook Dispatcher  │                         │
│              └───────────┬───────────┘                         │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                           │ HTTPS/API
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                    flukebase_connect (Python)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  MCP Server  │  │ Memory Store │  │ MCP Detector │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         │                 │                 │                   │
│         └────────────────┼────────────────┘                    │
│                          │                                      │
│              ┌───────────▼───────────┐                         │
│              │      AI Tools         │                         │
│              │  Claude, Gemini, etc  │                         │
│              └───────────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

### API Contract

**Project Context Endpoint**:
```
GET /api/v1/flukebase_connect/context
Authorization: Bearer fbk_xxx

Response:
{
  "project": {
    "id": 123,
    "name": "Project Name",
    "description": "...",
    "stage": "mvp"
  },
  "environment_variables": [...],
  "milestones": [...],
  "team_members": [...],
  "mcp_configuration": {
    "preset": "development",
    "enabled_plugins": ["flukebase-connect", "github"],
    "plugin_settings": {...}
  }
}
```

### Sync Protocol

1. **On Connect**: flukebase_connect fetches full context
2. **On Change**: Webhook pushes delta updates
3. **On Reconnect**: Sync missed changes since last_seen
4. **Offline Mode**: Local cache serves until reconnected

## Roadmap

### Q1 2026
- [ ] ProjectMemory model and API
- [ ] Webhook infrastructure
- [ ] MCP configuration UI
- [ ] Real-time sync

### Q2 2026
- [ ] AI provider registry
- [ ] Automated audits
- [ ] Usage analytics
- [ ] Team MCP presets

### Q3 2026
- [ ] Multi-tenant MCP server deployment
- [ ] Custom plugin marketplace
- [ ] Advanced analytics

### Q4 2026
- [ ] AI-driven project insights
- [ ] Automated code review integration
- [ ] Enterprise features

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Projects with MCP config | 0 | 1000+ |
| Active flukebase_connect users | N/A | 5000+ |
| Memory sync latency | N/A | <1s |
| Webhook delivery rate | N/A | 99.9% |
| AI provider coverage | 22 | 30+ |

## Related Documents

- [flukebase_connect NORTHSTAR.md](/home/cancelei/Projects/flukebase_connect/docs/NORTHSTAR.md)
- [AI Providers Documentation](/home/cancelei/Projects/flukebase_connect/docs/ai_providers/README.md)
- [Integration Guide](./guides/FLUKEBASE_CONNECT_INTEGRATION.md)
