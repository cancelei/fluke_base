# FlukeBase Connect API

**Last Updated**: 2025-12-29
**Document Type**: Integration Guide
**Audience**: Developers, AI Agents, API Consumers

---

## Overview

The FlukeBase Connect API enables AI coding assistants and CLI tools to sync environment variables and project context from FlukeBase. This powers the [flukebase-connect](https://pypi.org/project/flukebase-connect/) Python package.

## API Base URL

- **Production**: `https://flukebase.com/api/v1/flukebase_connect`
- **Development**: `http://localhost:3006/api/v1/flukebase_connect`

## Authentication

> **MCP**: Use `fb_login` for initial authentication, `fb_status` to verify connection

All API requests require a Bearer token in the `Authorization` header:

```bash
Authorization: Bearer fbk_xxxxxxxxxxxxx
```

### Token Format

- Prefix: `fbk_`
- Format: `fbk_` + 43 URL-safe base64 characters
- Example: `fbk_a1b2c3d4e5f6g7h8i9j0...`

### Getting an API Token

1. Log into FlukeBase
2. Navigate to **Settings → API Tokens**
3. Click **Create New Token**
4. Copy the token immediately (shown only once)

---

## Endpoints

### Authentication

#### Validate Token

```http
GET /api/v1/flukebase_connect/auth/validate
```

Validates the API token and returns basic status.

**Response:**
```json
{
  "valid": true,
  "user_id": 123
}
```

#### Get Current User

```http
GET /api/v1/flukebase_connect/auth/me
```

Returns current authenticated user information.

**Response:**
```json
{
  "id": 123,
  "email": "developer@example.com",
  "name": "Jane Developer",
  "project_count": 5
}
```

---

### Projects

#### List Projects

> **MCP**: Use `fb_projects` to list all accessible projects

```http
GET /api/v1/flukebase_connect/projects
```

Lists all projects accessible to the authenticated user.

**Response:**
```json
{
  "projects": [
    {
      "id": 1,
      "name": "My Startup",
      "repository_url": "cancelei/my-startup",
      "stage": "prototype",
      "created_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

#### Get Project

```http
GET /api/v1/flukebase_connect/projects/:id
```

Returns detailed project information.

**Response:**
```json
{
  "id": 1,
  "name": "My Startup",
  "repository_url": "cancelei/my-startup",
  "stage": "prototype",
  "description": "A revolutionary startup idea",
  "created_at": "2025-01-15T10:30:00Z"
}
```

#### Find Project by Repository

```http
GET /api/v1/flukebase_connect/projects/find?repository_url=owner/repo
```

Finds a project by its git repository URL. Used for auto-detection.

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `repository_url` | string | Repository in `owner/repo` format |

**Response:**
```json
{
  "id": 1,
  "name": "My Startup",
  "repository_url": "cancelei/my-startup",
  "stage": "prototype"
}
```

#### Get Project Context

> **MCP**: Use `fb_sync` to fetch context + environment in one call

```http
GET /api/v1/flukebase_connect/projects/:id/context
```

Returns AI-optimized project context for coding assistants.

**Response:**
```json
{
  "project": {
    "name": "My Startup",
    "description": "A revolutionary startup idea",
    "stage": "prototype"
  },
  "team": [
    {
      "name": "Jane Developer",
      "role": "founder"
    }
  ],
  "milestones": [
    {
      "title": "MVP Launch",
      "status": "in_progress"
    }
  ],
  "conventions": [
    "Use PostgreSQL for all databases",
    "Follow Rails conventions"
  ]
}
```

---

### Environment

#### Get Environment Variables

> **MCP**: Use `env_sync` to fetch, `env_show` to display, `env_validate` to check

```http
GET /api/v1/flukebase_connect/projects/:id/environment/variables
```

Returns environment variables for the project.

**Query Parameters:**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environment` | string | `development` | Environment name |

**Response:**
```json
{
  "variables": [
    {
      "key": "DATABASE_URL",
      "value": "postgres://localhost:5432/myapp_dev",
      "is_secret": true,
      "description": "Database connection string"
    },
    {
      "key": "RAILS_ENV",
      "value": "development",
      "is_secret": false,
      "description": "Rails environment"
    }
  ],
  "environment": "development",
  "synced_at": "2025-12-29T10:30:00Z"
}
```

#### Record Sync

```http
POST /api/v1/flukebase_connect/projects/:id/environment/sync
```

Records that the client synced the environment.

**Request Body:**
```json
{
  "environment": "development"
}
```

**Response:**
```json
{
  "synced": true,
  "synced_at": "2025-12-29T10:30:00Z"
}
```

---

## Error Responses

### 401 Unauthorized

```json
{
  "error": "Invalid or missing API token"
}
```

### 403 Forbidden

```json
{
  "error": "Insufficient permissions for this resource"
}
```

### 404 Not Found

```json
{
  "error": "Project not found"
}
```

---

## Rate Limiting

- **Rate**: 100 requests per minute per token
- **Headers**: Rate limit info included in response headers:
  - `X-RateLimit-Limit`: Maximum requests per window
  - `X-RateLimit-Remaining`: Requests remaining
  - `X-RateLimit-Reset`: Unix timestamp when limit resets

---

## Client Libraries

### Python (flukebase-connect)

The official Python client for FlukeBase Connect:

```bash
pip install flukebase-connect
```

Usage:
```bash
export FLUKEBASE_API_TOKEN=fbk_xxxxx
fbc sync    # Sync environment from FlukeBase
fbc status  # Check connection status
fbc serve   # Start MCP server for AI assistants
```

### MCP Server Integration

FlukeBase Connect works as an MCP (Model Context Protocol) server with Claude Code:

```bash
# Add to Claude Code
claude mcp add flukebase-connect -s user -- fbc serve
```

---

## API Token Management

### Token Scopes

| Scope | Description |
|-------|-------------|
| `read:projects` | List and view projects |
| `read:environment` | Read environment variables |
| `write:environment` | Modify environment variables |
| `read:context` | Access AI context information |

### Security

- Tokens are stored as SHA-256 digests (never in plaintext)
- Tokens can be revoked at any time
- Each token shows last used time and IP address
- Create separate tokens for different use cases

---

## For AI Agents

### MCP Tools Quick Reference

| When you need to... | Use this MCP tool | API Endpoint Called |
|---------------------|-------------------|---------------------|
| Authenticate | `fb_login` | `GET /auth/validate` |
| Check connection | `fb_status` | `GET /auth/me` |
| List projects | `fb_projects` | `GET /projects` |
| Sync everything | `fb_sync` | `GET /projects/:id/context` + `/environment/variables` |
| Get env vars only | `env_sync` | `GET /projects/:id/environment/variables` |
| View current env | `env_show` | (local only - shows .env) |
| Compare env files | `env_diff` | `GET /projects/:id/environment/variables` |
| Check required vars | `env_validate` | (local validation) |
| Store knowledge | `remember` | (local storage) |
| Search knowledge | `recall` | (local search) |
| Remove memory | `forget` | (local deletion) |
| Get convention reason | `why` | (local lookup) |

### Decision Tree: Syncing Project Context

```
Starting development session?
│
├── Check status first
│   `fb_status`
│   │
│   ├── Not authenticated?
│   │   `fb_login` (will prompt for token)
│   │
│   └── Authenticated → continue
│
└── Sync project context
    `fb_sync`
    │
    └── This fetches:
        - Project metadata
        - Team members
        - Milestones
        - Conventions
        - Environment variables (.env)
```

### Decision Tree: Environment Management

```
Environment issue detected?
│
├── Missing environment variables?
│   │
│   ├── `env_validate` → shows what's missing
│   └── `env_sync` → fetches from FlukeBase
│
├── Env vars seem wrong?
│   │
│   ├── `env_show` → view current (secrets masked)
│   ├── `env_diff` → compare local vs FlukeBase
│   └── `env_sync` → pull latest from FlukeBase
│
└── Need to see actual values?
    │
    └── `env_show --reveal` → shows unmasked values
```

### Decision Tree: Memory Management

```
Need to remember or recall information?
│
├── Want to store something for later?
│   │
│   ├── Project-specific fact?
│   │   `remember` with scope: "project-name"
│   │
│   ├── Global convention?
│   │   `remember` with scope: "global"
│   │
│   └── Types: fact, convention, gotcha, decision
│
├── Want to find stored info?
│   │
│   ├── `recall` with search query
│   └── Filter by type if needed
│
└── Want to understand a convention?
    │
    └── `why` with convention key
```

### Anti-Patterns

- ❌ **DO NOT** call `env_sync` repeatedly in a loop - sync once per session
- ❌ **DO NOT** store secrets with `remember` - use `env_sync` instead
- ❌ **DO NOT** skip `fb_status` at session start - always verify connection
- ✅ **DO** use `fb_sync` for initial context loading
- ✅ **DO** use `env_validate` before running tests
- ✅ **DO** use `remember` to store project conventions discovered during work

### Files to Check

- `app/controllers/api/v1/flukebase_connect/` - API controllers
- `app/models/api_token.rb` - Token model
- `app/models/environment_variable.rb` - Environment variable model
- `app/services/flukebase_connect/project_context_service.rb` - Context generation

### Common Tasks

1. **Testing API locally:**
   ```bash
   curl -H "Authorization: Bearer fbk_xxx" \
        http://localhost:3006/api/v1/flukebase_connect/projects
   ```

2. **Creating a token for testing:**
   - See [API Token Setup](../development/api-token-setup.md)

3. **Debugging sync issues:**
   - Check `rails logs` for API errors
   - Verify environment variables exist for the project
   - Confirm the repository URL matches

---

## MCP Plugin Ecosystem

### Production Plugins

| Plugin | Slug | Description | Required Scopes |
|--------|------|-------------|-----------------|
| FlukeBase Core | `flukebase-core` | Authentication, projects, sync | `read:projects` |
| Environment Manager | `environment` | Sync and manage environment variables | `read:environment` |
| Memory Store | `memory` | Persistent memory for AI agents | (none) |

### Conceptual Plugins (Roadmap)

| Plugin | Slug | Description | Status |
|--------|------|-------------|--------|
| GitHub Integration | `github` | Direct GitHub access: PRs, issues, commits | Planned |
| OpenAI Provider | `openai` | OpenAI API integration for GPT models | Planned |
| Anthropic Provider | `anthropic` | Anthropic Claude API integration | Planned |

### MCP Presets

Pre-configured plugin bundles for different user types:

| Preset | Target | Enabled Plugins | Context Level |
|--------|--------|-----------------|---------------|
| Founder Quick Start | founders | flukebase-core, environment | Minimal (500 tokens) |
| Developer Full | developers | flukebase-core, environment, memory | Full (5000 tokens) |
| Contractor Limited | contractors | flukebase-core, environment | Scoped (2000 tokens) |

---

## Related Documentation

- [GitHub API Integration](./github-api-integration.md)
- [Environment Variables Reference](../../reference/environment-variables.md)
- [flukebase-connect README](https://github.com/flukebase/flukebase-connect)
- [API Token Setup](../development/api-token-setup.md)
