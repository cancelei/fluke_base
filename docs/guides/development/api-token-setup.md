# API Token Setup for Development

**Last Updated**: 2025-12-29
**Document Type**: Development Guide
**Audience**: Developers, AI Agents

---

## Overview

FlukeBase Connect uses API tokens for authentication. Tokens start with `fbk_` and provide scoped access to the FlukeBase API.

> **MCP**: Use `fb_login` to authenticate with your token, `fb_status` to verify connection

---

## Generating a Token

### Method 1: Web UI (Recommended for Production)

1. Start the development server: `rails server`
2. Navigate to `http://localhost:3006/settings/api_tokens`
3. Click **Create New Token**
4. Enter a name (e.g., "Development Token")
5. Select scopes (or use defaults)
6. Click **Create**
7. **Copy the token immediately** - it's only shown once!

### Method 2: Rails Console (Development/Testing)

```ruby
# Start Rails console
rails console

# Find your user
user = User.find_by(email: "your@email.com")

# Generate token with default scopes
result = ApiToken.generate_for(user, name: "Dev Token")
puts result.raw_token  # Copy this! Only shown once

# Or with specific scopes
result = ApiToken.generate_for(
  user,
  name: "Full Access Token",
  scopes: %w[read:projects read:environment write:environment read:context]
)
puts result.raw_token

# With expiration (optional)
result = ApiToken.generate_for(
  user,
  name: "Temporary Token",
  expires_in: 7.days
)
puts result.raw_token
```

---

## Available Scopes

| Scope | Description | Default |
|-------|-------------|---------|
| `read:projects` | List and view projects | Yes |
| `read:environment` | Read environment variables | Yes |
| `write:environment` | Modify environment variables | No |
| `read:milestones` | View project milestones | Yes |
| `read:agreements` | View agreements | No |
| `read:context` | Access AI context information | Yes |
| `read:plugins` | View MCP plugin configurations | No |

**Default scopes** (automatically applied if none specified):
- `read:projects`
- `read:environment`
- `read:milestones`
- `read:context`

---

## Using Your Token

### With flukebase-connect CLI

```bash
# Set environment variable
export FLUKEBASE_API_TOKEN=fbk_xxxxxxxxxxxxx

# Or use the login command
fbc login
# Paste token when prompted
```

### With MCP Tools (Claude Code)

```
# Check status first
fb_status

# If not authenticated, login
fb_login
# Provide your token when prompted

# Sync project context
fb_sync
```

### With cURL (Direct API)

```bash
curl -H "Authorization: Bearer fbk_xxxxxxxxxxxxx" \
     http://localhost:3006/api/v1/flukebase_connect/projects
```

---

## Token Management

### View Active Tokens

```ruby
# In Rails console
User.find_by(email: "your@email.com").api_tokens.active
```

### Revoke a Token

```ruby
# In Rails console
token = ApiToken.find(token_id)
token.revoke!

# Or via UI at /settings/api_tokens
```

### Check Token Status

```ruby
token = ApiToken.find_by_raw_token("fbk_xxxxx")
token.active?    # => true/false
token.expired?   # => true/false
token.revoked?   # => true/false
```

---

## Security Notes

- Tokens are stored as SHA-256 digests (never plaintext)
- The raw token is only shown once at creation
- Tokens can be revoked at any time
- Each token tracks `last_used_at` and `last_used_ip`
- Create separate tokens for different use cases

---

## For AI Agents

### Files to Check

- `app/models/api_token.rb` - Token model with scopes
- `app/controllers/user_settings/api_tokens_controller.rb` - Token management UI
- `app/controllers/api/v1/flukebase_connect/base_controller.rb` - API authentication

### MCP Tools Reference

| Task | MCP Tool |
|------|----------|
| Authenticate | `fb_login` |
| Check connection | `fb_status` |
| View projects | `fb_projects` |
| Sync everything | `fb_sync` |

### Quick Start for AI Agents

```
1. fb_status          # Check if connected
2. fb_login           # If not, provide token
3. fb_sync            # Fetch project context
4. env_validate       # Verify environment setup
```
