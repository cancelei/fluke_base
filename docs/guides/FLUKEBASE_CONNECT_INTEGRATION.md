# Fluke Base + Flukebase Connect Integration Guide

> **Last Updated**: 2025-12-29
> **Status**: Active

This guide documents how fluke_base (Rails backend/frontend) and flukebase_connect (Python MCP server) work together as an integrated system.

## Overview

```
fluke_base (Rails)              flukebase_connect (Python)
──────────────────              ──────────────────────────
Web UI                          MCP Server
API                             CLI (fbc)
PostgreSQL                      SQLite (local cache)
Background Jobs                 Plugins
Webhooks                        AI Tool Integration
```

## Core Concepts

### Source of Truth
- **fluke_base**: Authoritative source for all project data
- **flukebase_connect**: Local cache and bridge to AI tools

### Data Flow
```
fluke_base DB → API → flukebase_connect → AI Tools
                         ↓
                    Local SQLite
                    (cache/offline)
```

## API Endpoints

### FlukebaseConnect Namespace

All endpoints under `/api/v1/flukebase_connect/`:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/context` | GET | Full project context |
| `/env` | GET | Environment variables |
| `/memories` | GET/POST | Memory sync |
| `/webhooks` | POST | Webhook subscription |

### Authentication

```ruby
# fluke_base: API Token model
class ApiToken < ApplicationRecord
  belongs_to :user
  belongs_to :project

  # token_type: 'flukebase_connect'
  # scope: 'read', 'write', 'admin'
end

# Request header
Authorization: Bearer fbk_xxx
```

### Context Response Schema

```json
{
  "project": {
    "id": 123,
    "name": "string",
    "description": "string",
    "stage": "prototype|mvp|beta|production",
    "repository_url": "string",
    "created_at": "iso8601",
    "updated_at": "iso8601"
  },
  "environment_variables": [
    {
      "key": "string",
      "value": "string",
      "is_secret": true,
      "environment": "development|staging|production"
    }
  ],
  "milestones": [
    {
      "id": 1,
      "title": "string",
      "status": "pending|in_progress|completed",
      "due_date": "iso8601"
    }
  ],
  "team_members": [
    {
      "id": 1,
      "name": "string",
      "email": "string",
      "role": "owner|admin|developer|viewer"
    }
  ],
  "mcp_configuration": {
    "preset": "string",
    "enabled_plugins": ["string"],
    "context_level": "minimal|standard|full",
    "plugin_settings": {}
  }
}
```

## Models

### fluke_base Models

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  has_many :environment_variables
  has_many :milestones
  has_many :project_memories
  has_one :mcp_configuration, class_name: 'ProjectMcpConfiguration'
  has_many :api_tokens
  has_many :webhook_subscriptions
end

# app/models/project_memory.rb
class ProjectMemory < ApplicationRecord
  belongs_to :project
  belongs_to :user

  enum memory_type: {
    fact: 0,
    convention: 1,
    gotcha: 2,
    decision: 3
  }

  # Columns:
  # - content (text)
  # - key (string, for conventions)
  # - rationale (text)
  # - tags (jsonb)
  # - external_id (string, UUID from flukebase_connect)
  # - synced_at (datetime)
end

# app/models/project_mcp_configuration.rb
class ProjectMcpConfiguration < ApplicationRecord
  belongs_to :project
  belongs_to :preset, class_name: 'McpPreset', optional: true

  # Columns:
  # - enabled_plugins (jsonb, array)
  # - context_level (string)
  # - plugin_settings (jsonb)
end
```

### flukebase_connect Models

```python
# flukebase_connect/memory/store.py
@dataclass
class Fact:
    id: str
    content: str
    memory_type: str  # fact, convention, gotcha, decision
    scope: str
    tags: list[str]
    created_at: datetime
    external_id: Optional[str]  # ID from fluke_base
    synced_at: Optional[datetime]
```

## Services

### fluke_base Services

```ruby
# app/services/flukebase_connect/project_context_service.rb
class FlukebaseConnect::ProjectContextService
  def initialize(project)
    @project = project
  end

  def generate
    {
      project: project_info,
      environment_variables: env_vars,
      milestones: milestone_info,
      team_members: team_info,
      mcp_configuration: mcp_config
    }
  end
end

# app/services/flukebase_connect/memory_sync_service.rb
class FlukebaseConnect::MemorySyncService
  def sync_from_client(memories_json)
    memories_json.each do |mem|
      memory = @project.project_memories.find_or_initialize_by(
        external_id: mem["id"]
      )
      memory.update!(
        content: mem["content"],
        memory_type: mem["type"],
        tags: mem["tags"],
        synced_at: Time.current
      )
    end
  end
end
```

### flukebase_connect Services

```python
# flukebase_connect/flukebase/client.py
class FlukebaseClient:
    def __init__(self, api_token: str):
        self.api_token = api_token
        self.base_url = "https://api.flukebase.com/api/v1"

    async def get_context(self) -> dict:
        """Fetch project context from fluke_base."""
        ...

    async def sync_memories(self, memories: list[Fact]) -> bool:
        """Sync local memories to fluke_base."""
        ...
```

## Sync Protocol

### Initial Sync (fb_sync)

```
1. User runs: fbc sync (or fb_sync MCP tool)
2. flukebase_connect fetches context from API
3. Environment variables written to .env
4. Project memories cached locally
5. MCP configuration applied to AI tools
```

### Real-time Sync (Webhooks)

```
1. Change in fluke_base (e.g., env var updated)
2. WebhookDispatcher creates delivery
3. Webhook sent to flukebase_connect callback
4. flukebase_connect validates HMAC signature
5. Local cache updated
6. AI tools notified if needed
```

### Memory Sync

```
Direction: Bi-directional

flukebase_connect → fluke_base:
  - New facts created locally
  - Updates to existing memories
  - Conflict: local wins (user intent)

fluke_base → flukebase_connect:
  - Team-shared memories
  - Admin-created conventions
  - Conflict: server wins (source of truth)
```

## MCP Tool Integration

### fb_sync Tool

```python
# In flukebase_connect MCP server
@tool
async def fb_sync(environment: str = "development", configure_mcp: bool = True):
    """Sync project from FlukeBase."""

    # 1. Fetch context
    context = await client.get_context()

    # 2. Write .env
    await write_env_file(context["environment_variables"])

    # 3. Cache memories
    await store.upsert_from_remote(context.get("memories", []))

    # 4. Configure MCP clients
    if configure_mcp:
        detector = MCPClientDetector()
        detector.configure_all()

    return "Sync complete"
```

### remember Tool

```python
@tool
async def remember(content: str, type: str = "fact", tags: list[str] = None):
    """Store knowledge for future sessions."""

    memory = await store.remember(content=content, type=type, tags=tags)

    # Sync to fluke_base if connected
    if client.is_connected:
        await client.sync_memory(memory)

    return f"Remembered: {memory.id}"
```

## Configuration Files

### fluke_base

```yaml
# config/flukebase_connect.yml
default: &default
  api_version: "v1"
  webhook_secret: <%= ENV['FLUKEBASE_WEBHOOK_SECRET'] %>
  allowed_scopes:
    - read
    - write
    - admin

development:
  <<: *default

production:
  <<: *default
  rate_limit: 100  # requests per minute
```

### flukebase_connect

```toml
# ~/.flukebase_connect/config.toml
[api]
base_url = "https://api.flukebase.com"
timeout = 30

[sync]
auto_sync = true
sync_interval = 300  # seconds

[mcp]
auto_configure = true
supported_clients = ["claude-code", "windsurf", "gemini-cli", "cursor"]
```

## Error Handling

### API Errors

```python
# flukebase_connect error handling
class FlukebaseAPIError(Exception):
    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        self.message = message

# Usage
try:
    context = await client.get_context()
except FlukebaseAPIError as e:
    if e.status_code == 401:
        return "Invalid API token. Run: fbc login"
    elif e.status_code == 404:
        return "Project not found"
    else:
        return f"API error: {e.message}"
```

### Webhook Validation

```ruby
# fluke_base webhook signature
class WebhookSignature
  def self.generate(payload, secret)
    OpenSSL::HMAC.hexdigest('SHA256', secret, payload)
  end

  def self.verify(payload, signature, secret)
    expected = generate(payload, secret)
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end
end
```

## Testing

### fluke_base Tests

```ruby
# spec/requests/api/v1/flukebase_connect/context_spec.rb
RSpec.describe "FlukebaseConnect Context API" do
  let(:project) { create(:project) }
  let(:api_token) { create(:api_token, project: project) }

  it "returns project context" do
    get "/api/v1/flukebase_connect/context",
        headers: { "Authorization" => "Bearer #{api_token.token}" }

    expect(response).to have_http_status(:ok)
    expect(json_response["project"]["id"]).to eq(project.id)
  end
end
```

### flukebase_connect Tests

```python
# tests/integration/test_fluke_base_sync.py
@pytest.mark.asyncio
async def test_sync_context():
    client = FlukebaseClient(api_token="test_token")

    with aioresponses() as m:
        m.get(f"{client.base_url}/flukebase_connect/context",
              payload={"project": {"id": 1, "name": "Test"}})

        context = await client.get_context()
        assert context["project"]["name"] == "Test"
```

## Deployment

### fluke_base (Production)

```ruby
# Ensure API endpoints are available
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :flukebase_connect do
        resource :context, only: [:show]
        resources :memories
        resources :webhooks
      end
    end
  end
end
```

### flukebase_connect (PyPI)

```bash
# Install from PyPI
pip install flukebase-connect

# Or from source
pip install git+https://github.com/flukebase/flukebase_connect.git
```

## Security Considerations

1. **API Tokens**: Never commit tokens to version control
2. **Secrets**: Environment variables marked `is_secret` are masked in logs
3. **Webhooks**: Always verify HMAC signatures
4. **HTTPS**: All API communication must use HTTPS
5. **Scopes**: Use minimal required scopes for tokens

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| 401 Unauthorized | Check API token validity |
| 404 Not Found | Verify project exists and token has access |
| Sync failed | Check network connectivity |
| MCP not configured | Run `fbc mcp setup` |
| Webhook not received | Verify callback URL is accessible |

### Debug Mode

```bash
# flukebase_connect debug
FBC_DEBUG=1 fbc sync

# Check API response
curl -H "Authorization: Bearer $FLUKEBASE_TOKEN" \
  https://api.flukebase.com/api/v1/flukebase_connect/context | jq .
```

## References

- [fluke_base NORTHSTAR](../NORTHSTAR.md)
- [flukebase_connect NORTHSTAR](/home/cancelei/Projects/flukebase_connect/docs/NORTHSTAR.md)
- [AI Providers Documentation](/home/cancelei/Projects/flukebase_connect/docs/ai_providers/README.md)
