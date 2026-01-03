# FlukeBase Connect API Endpoints Reference

**Last Updated**: 2026-01-03
**Document Type**: API Reference
**Audience**: Developers, API Consumers, AI Agents

---

## For AI Agents

### Quick Start

```
1. Authenticate: GET /auth/validate with Bearer token
2. List projects: GET /projects
3. Sync context: GET /projects/:id/context
4. Sync environment: GET /projects/:id/environment/variables
```

### MCP Tool to API Mapping

| MCP Tool | API Endpoint | Purpose |
|----------|--------------|---------|
| `fb_login` | `GET /auth/validate` | Verify token |
| `fb_status` | `GET /auth/me` | Get user info |
| `fb_projects` | `GET /projects` | List projects |
| `fb_sync` | `GET /projects/:id/context` + `/environment/variables` | Full sync |
| `env_sync` | `GET /projects/:id/environment/variables` | Env only |
| `remember` | `POST /projects/:id/memories` | Store memory |
| `recall` | `GET /memories/search` | Search memories |

### Decision Tree: API Selection

```
Need to work with FlukeBase API?
|
+-- Authentication?
|   +-- Validate token: GET /auth/validate
|   +-- Get user info: GET /auth/me
|
+-- Projects?
|   +-- List all: GET /projects
|   +-- Find by repo: GET /projects/find?repository_url=owner/repo
|   +-- Get context: GET /projects/:id/context
|
+-- Environment?
|   +-- Get vars: GET /projects/:id/environment/variables
|   +-- Record sync: POST /projects/:id/environment/sync
|
+-- Memories?
|   +-- List: GET /projects/:id/memories
|   +-- Create: POST /projects/:id/memories
|   +-- Search cross-project: GET /memories/search
|
+-- Analytics?
    +-- Portfolio summary: GET /portfolio/summary
    +-- Compare projects: GET /portfolio/compare
    +-- View trends: GET /portfolio/trends
```

### AI-Friendly Documentation

FlukeBase provides multiple documentation formats optimized for AI consumption:

| Format | URL | Auth Required | Best For |
|--------|-----|---------------|----------|
| llms.txt | `GET /api/v1/flukebase_connect/docs/llms.txt` | Yes (Bearer token) | Navigation and structure |
| llms-full.txt | `GET /api/v1/flukebase_connect/docs/llms-full.txt` | Yes (Bearer token) | Complete reference in one file |
| OpenAPI/Swagger | `/api-docs` | No | Interactive API exploration |
| This document | - | No | Detailed endpoint reference |

**Example: Fetching llms.txt**
```bash
curl -H "Authorization: Bearer fbk_xxxxx" \
     https://flukebase.com/api/v1/flukebase_connect/docs/llms.txt
```

---

## API Overview

Base URL: `/api/v1/flukebase_connect`

All endpoints require Bearer token authentication unless otherwise noted.

---

## Endpoint Coverage Matrix

| Controller | Endpoints | Documented | OpenAPI Spec | Status |
|------------|-----------|------------|--------------|--------|
| Auth | 2 | Yes | Yes | Complete |
| Projects | 5 | Yes | Yes | Complete |
| Memories | 7 | Yes | Yes | Complete |
| Environment | 4 | Yes | Yes | Complete |
| Webhooks | 6 | Yes | Yes | Complete |
| Productivity Metrics | 5 | Yes | Yes | Complete |
| WeDo Tasks | 6 | Yes | Yes | Complete |
| Agents | 7 | Yes | Yes | Complete |
| AI Conversations | 3 | Yes | Yes | Complete |
| Portfolio Analytics | 3 | Yes | Yes | Complete |
| Delegation | 6 | Yes | Yes | Complete |
| Suggested Gotchas | 4 | No | No | Needs docs |
| Docs (llms.txt) | 2 | Yes | Yes | Complete |

**Total: 60 endpoints | Documented: 56 (93%) | In OpenAPI: 56 (93%)**

**OpenAPI Spec**: `swagger/v1/swagger.yaml` (3,157 lines)
**Swagger UI**: Available at `/api-docs` when server is running

---

## Authentication Endpoints

### GET /auth/validate
Validates the API token and returns authentication status.

**Scope Required**: None (just valid token)

**Response 200**:
```json
{
  "valid": true,
  "user_id": 123,
  "scopes": ["read:projects", "write:projects"]
}
```

### GET /auth/me
Returns current authenticated user information.

**Scope Required**: None

**Response 200**:
```json
{
  "id": 123,
  "email": "user@example.com",
  "name": "Jane Developer",
  "project_count": 5
}
```

---

## Projects Endpoints

### GET /projects
List all accessible projects.

**Scope Required**: `read:projects`

### GET /projects/:id
Get project details.

**Scope Required**: `read:projects`

### POST /projects
Create a new project.

**Scope Required**: `write:projects`

### GET /projects/:id/context
Get AI-optimized project context.

**Scope Required**: `read:context`

### GET /projects/find
Find project by repository URL.

**Scope Required**: `read:projects`

**Query Params**: `repository_url`

---

## Batch Operations

### GET /batch/context
Get context for multiple projects.

**Scope Required**: `read:context`

**Query Params**: `project_ids[]` or `all=true`

### GET /batch/environment
Get environment variables for multiple projects.

**Scope Required**: `read:environment`

**Query Params**: `project_ids[]` or `all=true`, `environment`

### GET /batch/memories
Get memories for multiple projects.

**Scope Required**: `read:memories`

**Query Params**: `project_ids[]` or `all=true`

---

## Environment Endpoints

### GET /projects/:project_id/environment
Get environment configuration.

**Scope Required**: `read:environment`

### GET /projects/:project_id/environment/variables
Get environment variables.

**Scope Required**: `read:environment`

**Query Params**: `environment` (development|staging|production)

### POST /projects/:project_id/environment/sync
Record sync event.

**Scope Required**: `read:environment`

---

## Memories Endpoints

### GET /projects/:project_id/memories
List project memories.

**Scope Required**: `read:memories`

**Query Params**: `type`, `tags[]`

### GET /projects/:project_id/memories/:id
Get memory details.

**Scope Required**: `read:memories`

### POST /projects/:project_id/memories
Create a memory.

**Scope Required**: `write:memories`

### PATCH /projects/:project_id/memories/:id
Update a memory.

**Scope Required**: `write:memories`

### DELETE /projects/:project_id/memories/:id
Delete a memory.

**Scope Required**: `write:memories`

### POST /projects/:project_id/memories/bulk_sync
Bulk sync memories.

**Scope Required**: `write:memories`

### GET /projects/:project_id/memories/conventions
List conventions only.

**Scope Required**: `read:memories`

### GET /memories/search
Cross-project memory search.

**Scope Required**: `read:memories`

---

## Webhooks Endpoints

### GET /projects/:project_id/webhooks
List webhook subscriptions.

**Scope Required**: `read:webhooks`

### GET /projects/:project_id/webhooks/:id
Get webhook details.

**Scope Required**: `read:webhooks`

### POST /projects/:project_id/webhooks
Create webhook subscription.

**Scope Required**: `write:webhooks`

### PUT /projects/:project_id/webhooks/:id
Update webhook.

**Scope Required**: `write:webhooks`

### DELETE /projects/:project_id/webhooks/:id
Delete webhook.

**Scope Required**: `write:webhooks`

### GET /projects/:project_id/webhooks/:id/deliveries
Get delivery history.

**Scope Required**: `read:webhooks`

### GET /projects/:project_id/webhooks/events
List available event types.

**Scope Required**: `read:webhooks`

---

## Productivity Metrics Endpoints

### GET /projects/:project_id/productivity_metrics
List productivity metrics.

**Scope Required**: `read:metrics`

**Query Params**: `type`, `period_type`, `since`, `page`, `per_page`

### GET /projects/:project_id/productivity_metrics/:id
Get metric details.

**Scope Required**: `read:metrics`

### POST /projects/:project_id/productivity_metrics
Create metric.

**Scope Required**: `write:metrics`

### GET /projects/:project_id/productivity_metrics/summary
Get aggregated summary.

**Scope Required**: `read:metrics`

### POST /projects/:project_id/productivity_metrics/bulk_sync
Bulk sync metrics.

**Scope Required**: `write:metrics`

---

## WeDo Tasks Endpoints

### GET /projects/:project_id/wedo_tasks
List WeDo tasks.

**Scope Required**: `read:tasks`

**Query Params**: `status`, `scope`, `assignee_id`, `root_only`, `since_version`

### GET /projects/:project_id/wedo_tasks/:id
Get task details.

**Scope Required**: `read:tasks`

### POST /projects/:project_id/wedo_tasks
Create task.

**Scope Required**: `write:tasks`

### PUT /projects/:project_id/wedo_tasks/:id
Update task.

**Scope Required**: `write:tasks`

### DELETE /projects/:project_id/wedo_tasks/:id
Delete task.

**Scope Required**: `write:tasks`

### POST /projects/:project_id/wedo_tasks/bulk_sync
Bulk sync tasks.

**Scope Required**: `write:tasks`

---

## Agent Sessions Endpoints

### GET /projects/:project_id/agents
List agent sessions.

**Scope Required**: `read:agents`

### GET /projects/:project_id/agents/:id
Get agent session.

**Scope Required**: `read:agents`

### POST /projects/:project_id/agents/register
Register agent session.

**Scope Required**: `write:agents`

### POST /projects/:project_id/agents/:id/heartbeat
Update heartbeat.

**Scope Required**: `write:agents`

### PUT /projects/:project_id/agents/:id
Update agent metadata.

**Scope Required**: `write:agents`

### DELETE /projects/:project_id/agents/:id
Disconnect agent.

**Scope Required**: `write:agents`

### GET /projects/:project_id/agents/whoami
Get current agent by X-Agent-ID header.

**Scope Required**: `read:agents`

### POST /projects/:project_id/agents/cleanup
Clean up stale sessions.

**Scope Required**: `write:agents`

---

## AI Conversations Endpoints

### GET /projects/:project_id/ai_conversations
List AI conversation logs.

**Scope Required**: `read:metrics`

### GET /projects/:project_id/ai_conversations/:id
Get conversation details.

**Scope Required**: `read:metrics`

### POST /projects/:project_id/ai_conversations/bulk_sync
Bulk sync conversation logs.

**Scope Required**: `write:metrics`

---

## Portfolio Analytics Endpoints

### GET /portfolio/summary
Aggregate metrics across all projects.

**Scope Required**: `read:metrics`

**Query Params**: `period` (days)

### GET /portfolio/compare
Rank projects by productivity.

**Scope Required**: `read:metrics`

**Query Params**: `period`, `sort_by`, `limit`

### GET /portfolio/trends
Time-series productivity data.

**Scope Required**: `read:metrics`

**Query Params**: `period`, `granularity` (daily|weekly)

---

## Delegation Endpoints (Container-based execution)

### GET /projects/:project_id/delegation/status
Get delegation status.

**Scope Required**: `read:delegation`

### POST /projects/:project_id/delegation/pool
Create/update container pool.

**Scope Required**: `write:delegation`

### POST /projects/:project_id/delegation/claim
Claim task for execution.

**Scope Required**: `write:delegation`

### POST /projects/:project_id/delegation/report_context
Report context usage.

**Scope Required**: `write:delegation`

### POST /projects/:project_id/delegation/handoff
Handoff to new session.

**Scope Required**: `write:delegation`

### POST /projects/:project_id/delegation/register_session
Register container session.

**Scope Required**: `write:delegation`

### GET /projects/:project_id/delegation/next_task
Get next delegable task.

**Scope Required**: `read:delegation`

---

## Suggested Gotchas Endpoints

### GET /projects/:project_id/suggested_gotchas
List auto-detected gotchas.

**Scope Required**: `read:memories`

### GET /projects/:project_id/suggested_gotchas/:id
Get suggested gotcha details.

**Scope Required**: `read:memories`

### POST /projects/:project_id/suggested_gotchas/:id/approve
Approve and convert to memory.

**Scope Required**: `write:memories`

### POST /projects/:project_id/suggested_gotchas/:id/dismiss
Dismiss suggestion.

**Scope Required**: `write:memories`

---

## API Visibility Classification

### Public APIs (Documented for external consumers)

These APIs are stable and intended for third-party integrations:

| Category | Endpoints | Purpose |
|----------|-----------|---------|
| Authentication | `/auth/*` | Token validation, user info |
| Projects | `/projects/*` | Project management |
| Environment | `/environment/*` | Environment variable sync |
| Memories | `/memories/*` | Knowledge storage |
| Batch | `/batch/*` | Multi-project operations |

### Internal APIs (For flukebase_connect only)

These APIs may change without notice:

| Category | Endpoints | Purpose |
|----------|-----------|---------|
| WeDo Tasks | `/wedo_tasks/*` | Team board sync |
| Agents | `/agents/*` | Agent session management |
| Delegation | `/delegation/*` | Container execution |
| AI Conversations | `/ai_conversations/*` | Log sync |
| Portfolio Analytics | `/portfolio/*` | Cross-project metrics |

### Experimental APIs

Subject to breaking changes:

- Webhooks (event subscriptions)
- Suggested Gotchas (auto-detection)

---

## Required Scopes by Feature

| Feature | Read Scope | Write Scope |
|---------|------------|-------------|
| Projects | `read:projects` | `write:projects` |
| Environment | `read:environment` | `write:environment` |
| Context | `read:context` | - |
| Memories | `read:memories` | `write:memories` |
| Webhooks | `read:webhooks` | `write:webhooks` |
| Metrics | `read:metrics` | `write:metrics` |
| Tasks | `read:tasks` | `write:tasks` |
| Agents | `read:agents` | `write:agents` |
| Delegation | `read:delegation` | `write:delegation` |

---

## Related Documentation

- [API Token Setup](../guides/development/api-token-setup.md)
- [OpenAPI Documentation](../guides/development/openapi-documentation.md)
- [FlukeBase Connect Integration](../guides/integrations/flukebase-connect-api.md)
