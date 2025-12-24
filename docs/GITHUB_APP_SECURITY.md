# GitHub App Security Implementation

> **Last Updated:** 2024-12-24
> **Status:** Production Ready

## Table of Contents

1. [Overview](#overview)
2. [Security Features](#security-features)
3. [Architecture](#architecture)
4. [Configuration](#configuration)
5. [Development Setup](#development-setup)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This document covers the security implementation for GitHub App integration, following [GitHub's official best practices](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/best-practices-for-creating-a-github-app).

### Security Features Implemented

| Feature | Status | Description |
|---------|--------|-------------|
| Token Encryption at Rest | ✅ | Active Record Encryption for all GitHub tokens |
| PKCE (RFC 7636) | ✅ | Proof Key for Code Exchange for OAuth |
| Webhook Signature Validation | ✅ | HMAC-SHA256 with timing-safe comparison |
| Refresh Token Expiry Tracking | ✅ | 6-month expiry with re-auth prompts |
| Installation Access Tokens | ✅ | App-attributed tokens for background jobs |
| Private Email Handling | ✅ | Fallback to verified emails when noreply used |
| Separate Token Storage | ✅ | Different encryption keys for refresh tokens |

---

## Security Features

### 1. Token Encryption at Rest

All GitHub tokens are encrypted using Active Record Encryption before storage.

**Configuration:** `app/models/user.rb`

```ruby
# GitHub Token Encryption (Per GitHub's security best practices)
encrypts :github_user_access_token
encrypts :github_refresh_token, deterministic: false  # Non-deterministic for extra security
encrypts :github_token  # Legacy PAT
```

**Encryption Keys:** Stored in Rails credentials (`config/credentials.yml.enc`)

```yaml
active_record_encryption:
  primary_key: <32-character key>
  deterministic_key: <32-character key>
  key_derivation_salt: <32-character salt>
```

**Verification:**
```ruby
# Test that encryption is working
user = User.find(1)
user.update!(github_user_access_token: "test_token")

# Raw database value is encrypted
raw = ActiveRecord::Base.connection.execute(
  "SELECT github_user_access_token FROM users WHERE id = #{user.id}"
).first["github_user_access_token"]
# => {"p":"uHnJ3Ja8g5cq/R9C..."} (encrypted JSON)

# Model returns decrypted value
user.reload.github_user_access_token
# => "test_token"
```

### 2. PKCE (Proof Key for Code Exchange)

PKCE prevents authorization code interception attacks per [RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636).

**Configuration:** `config/initializers/devise.rb`

```ruby
config.omniauth :github,
  github_client_id,
  github_client_secret,
  scope: "user:email",
  pkce: true  # Enable PKCE
```

**How it works:**
1. Client generates a random `code_verifier`
2. Client creates `code_challenge = SHA256(code_verifier)`
3. Authorization request includes `code_challenge`
4. Token request includes `code_verifier`
5. GitHub verifies `SHA256(code_verifier) == code_challenge`

### 3. Webhook Signature Validation

All incoming webhooks are validated using HMAC-SHA256 signatures.

**Controller:** `app/controllers/webhooks/github_controller.rb`

```ruby
def verify_webhook_signature
  secret = Github::AppConfig.webhook_secret

  # Require secret in production
  if secret.blank?
    if Rails.env.production?
      Rails.logger.error "[Webhooks::Github] SECURITY: Webhook secret not configured!"
      head :internal_server_error
      return false
    else
      Rails.logger.warn "[Webhooks::Github] Skipping signature verification"
      return true
    end
  end

  signature = request.headers["X-Hub-Signature-256"]
  return head(:unauthorized) unless signature.present?

  payload = request.body.read
  expected = "sha256=" + OpenSSL::HMAC.hexdigest(
    OpenSSL::Digest.new("sha256"),
    secret,
    payload
  )

  # Timing-safe comparison prevents timing attacks
  unless Rack::Utils.secure_compare(signature, expected)
    Rails.logger.warn "[Webhooks::Github] Invalid webhook signature"
    head :unauthorized
    return false
  end

  true
end
```

### 4. Refresh Token Expiry Tracking

GitHub refresh tokens expire after 6 months. The system tracks expiry and prompts re-authentication.

**Migration:** `db/migrate/20251224213259_add_github_refresh_token_expires_at_to_users.rb`

```ruby
add_column :users, :github_refresh_token_expires_at, :datetime
```

**User Model Methods:**

```ruby
# Check if GitHub connection needs re-authentication
def github_needs_reauth?
  return false unless github_uid.present?
  return true if github_refresh_token.blank? && github_connected_at.present?

  if github_refresh_token_expires_at.present?
    github_refresh_token_expires_at < 7.days.from_now
  else
    false
  end
end

# Check if GitHub connection is fully functional
def github_connection_valid?
  github_app_connected? && !github_needs_reauth?
end
```

**Token Refresh Service:** `app/services/github/token_refresh_service.rb`

```ruby
EXPIRED_TOKEN_ERRORS = [
  "bad_refresh_token",
  "The refresh token has expired",
  "refresh_token is expired"
].freeze

def call
  return failure_result(:no_refresh_token, "...") unless @user.github_refresh_token

  if refresh_token_expired?
    invalidate_github_connection!
    return failure_result(:refresh_token_expired, "GitHub connection has expired...")
  end

  response = exchange_refresh_token

  if expired_token_error?(response)
    invalidate_github_connection!
    return failure_result(:refresh_token_expired, "...")
  end

  update_user_tokens(response)
  Success(@user.github_user_access_token)
end
```

### 5. Installation Access Tokens

Background jobs use Installation Access Tokens (app-attributed) instead of User Access Tokens per GitHub's recommendations.

**Service:** `app/services/github/installation_token_service.rb`

```ruby
# Cache tokens for 50 minutes (they expire at 60 minutes)
CACHE_TTL = 50.minutes
CACHE_KEY_PREFIX = "github:installation_token"

def self.client_for_installation(installation_id)
  result = call(installation_id: installation_id)
  return nil if result.failure?
  Octokit::Client.new(access_token: result.value![:token])
end

def self.client_for_repo(user:, repo_full_name:)
  installation = user.installation_for_repo(repo_full_name)
  return nil unless installation
  client_for_installation(installation.installation_id)
end
```

**Polling Job:** `app/jobs/github_polling_job.rb`

```ruby
# Token Priority:
# 1. Installation Access Token (app-attributed, best for automation)
# 2. User Access Token (refreshed if needed)
# 3. Legacy PAT

def get_access_token_for_project(project)
  user = project.user
  repo_full_name = Github::Base.new.send(:extract_repo_path, project.repository_url)

  # Try installation token first (preferred for background tasks)
  installation_token = get_installation_token(user, repo_full_name)
  return { token: installation_token, type: :installation } if installation_token

  # Fall back to user token
  user_token = user.effective_github_token
  if user_token.present?
    return { token: user_token, type: user.github_app_connected? ? :user_oauth : :legacy_pat }
  end

  nil
end
```

### 6. Private Email Handling

When users have private emails, GitHub returns `noreply@github.com` addresses. The system fetches verified emails as fallback.

**Controller:** `app/controllers/users/omniauth_callbacks_controller.rb`

```ruby
def extract_verified_email(auth)
  primary_email = auth.info&.email

  # If primary email is valid (not noreply), use it
  if primary_email.present? && !github_noreply_email?(primary_email)
    return primary_email
  end

  # Otherwise, look for verified emails in extra data
  all_emails = auth.extra&.all_emails || auth.extra&.raw_info&.emails || []

  verified_email = all_emails
    .select { |e| e[:verified] || e["verified"] }
    .reject { |e| github_noreply_email?(e[:email] || e["email"]) }
    .sort_by { |e| (e[:primary] || e["primary"]) ? 0 : 1 }
    .first

  email = verified_email&.dig(:email) || verified_email&.dig("email")
  email.presence || primary_email
end

def github_noreply_email?(email)
  email.to_s.match?(/\A\d+\+.*@users\.noreply\.github\.com\z/i) ||
    email.to_s.end_with?("@users.noreply.github.com")
end
```

---

## Architecture

### Token Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        OAuth Flow                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  User clicks "Sign in with GitHub"                              │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────┐    PKCE code_challenge                     │
│  │ Rails App       │─────────────────────────►┌───────────────┐ │
│  │ (OmniAuth)      │                          │ GitHub OAuth  │ │
│  └─────────────────┘◄─────────────────────────└───────────────┘ │
│         │              Authorization Code                        │
│         │                                                        │
│         ▼           code + code_verifier                        │
│  ┌─────────────────┐─────────────────────────►┌───────────────┐ │
│  │ Token Exchange  │                          │ GitHub API    │ │
│  └─────────────────┘◄─────────────────────────└───────────────┘ │
│         │              access_token + refresh_token              │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────┐                                            │
│  │ Encrypt & Store │  ActiveRecord::Encryption                  │
│  │ in Database     │                                            │
│  └─────────────────┘                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Webhook Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                      Webhook Flow                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  GitHub Event (push, installation, etc.)                        │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────┐                                            │
│  │ GitHub          │  POST /webhooks/github                     │
│  │ Webhook Sender  │  X-Hub-Signature-256: sha256=abc123...     │
│  └─────────────────┘                                            │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────┐                                            │
│  │ Signature       │  HMAC-SHA256(payload, webhook_secret)      │
│  │ Validation      │  Rack::Utils.secure_compare()              │
│  └─────────────────┘                                            │
│         │                                                        │
│         ▼ (if valid)                                            │
│  ┌─────────────────┐                                            │
│  │ Event Handler   │  Process installation, push, etc.         │
│  └─────────────────┘                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Background Job Token Selection

```
┌─────────────────────────────────────────────────────────────────┐
│              Background Job Token Priority                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  GithubPollingJob starts                                        │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────┐                                            │
│  │ 1. Try          │  Installation Token (app-attributed)      │
│  │    Installation │  - Higher rate limits                     │
│  │    Token        │  - Actions attributed to app              │
│  └─────────────────┘  - Cached for 50 minutes                   │
│         │                                                        │
│         ▼ (if not available)                                    │
│  ┌─────────────────┐                                            │
│  │ 2. Try User     │  User OAuth Token                         │
│  │    OAuth Token  │  - Auto-refreshed if expired              │
│  └─────────────────┘  - Actions attributed to user              │
│         │                                                        │
│         ▼ (if not available)                                    │
│  ┌─────────────────┐                                            │
│  │ 3. Try Legacy   │  Personal Access Token                    │
│  │    PAT          │  - Fallback for older integrations        │
│  └─────────────────┘                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Configuration

### Environment Variables

```bash
# Required for GitHub App
GITHUB_APP_ID=123456
GITHUB_APP_CLIENT_ID=Iv1.xxxxxxxxxxxxx
GITHUB_APP_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GITHUB_APP_WEBHOOK_SECRET=your_webhook_secret

# Private Key (choose one option)
# Option 1: File path
GITHUB_APP_PRIVATE_KEY_PATH=/path/to/private-key.pem

# Option 2: Inline (escape newlines)
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nMIIE...\n-----END RSA PRIVATE KEY-----"
```

### Rails Credentials

For production, store sensitive values in encrypted credentials:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

```yaml
github_app:
  app_id: "123456"
  client_id: "Iv1.xxxxxxxxxxxxx"
  client_secret: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  webhook_secret: "your_webhook_secret"
  private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpQIBAAKCAQEA...
    -----END RSA PRIVATE KEY-----

active_record_encryption:
  primary_key: "32-character-primary-key-here"
  deterministic_key: "32-character-deterministic-key"
  key_derivation_salt: "32-character-salt-here"
```

### GitHub App Settings

When creating the GitHub App at https://github.com/settings/apps:

| Setting | Value |
|---------|-------|
| Homepage URL | `https://yourdomain.com` |
| Callback URL | `https://yourdomain.com/users/auth/github/callback` |
| Webhook URL | `https://yourdomain.com/webhooks/github` |
| Webhook secret | Match `GITHUB_APP_WEBHOOK_SECRET` |

**Required Permissions (Repository):**
- Contents: Read-only
- Metadata: Read-only
- Commit statuses: Read-only

**Required Permissions (Account):**
- Email addresses: Read-only

---

## Development Setup

### Prerequisites

1. Create a development GitHub App at https://github.com/settings/apps
2. Download the private key (.pem file)
3. Note the App ID, Client ID, and Client Secret

### Configuration

1. **Update `.env`:**

```bash
GITHUB_APP_ID=your_dev_app_id
GITHUB_APP_CLIENT_ID=Iv1.your_client_id
GITHUB_APP_CLIENT_SECRET=your_client_secret
GITHUB_APP_WEBHOOK_SECRET=your_webhook_secret
GITHUB_APP_PRIVATE_KEY_PATH=/absolute/path/to/private-key.pem
```

2. **Shell Environment Conflict:**

If you have old GitHub credentials exported in your shell, unset them:

```bash
unset GITHUB_APP_ID GITHUB_APP_CLIENT_ID GITHUB_APP_CLIENT_SECRET GITHUB_APP_PRIVATE_KEY_PATH
```

Or run Rails with explicit environment clearing:

```bash
env -u GITHUB_APP_ID -u GITHUB_APP_CLIENT_ID -u GITHUB_APP_CLIENT_SECRET -u GITHUB_APP_PRIVATE_KEY_PATH bin/rails server -p 3006
```

### Cloudflare Tunnel (for Webhook Testing)

Webhooks require a public URL. Use Cloudflare Tunnel for local development.

1. **Install cloudflared:**

```bash
# Linux
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o ~/.local/bin/cloudflared
chmod +x ~/.local/bin/cloudflared

# macOS
brew install cloudflare/cloudflare/cloudflared
```

2. **Quick tunnel (no account required):**

```bash
cloudflared tunnel --url http://localhost:3006
# Gives you: https://random-words.trycloudflare.com
```

3. **Named tunnel (persistent URL, requires Cloudflare account):**

```bash
# One-time setup
cloudflared tunnel login
cloudflared tunnel create fluke-dev
cloudflared tunnel route dns fluke-dev dev.yourdomain.com

# Create config
cat > ~/.cloudflared/config.yml << EOF
tunnel: fluke-dev
credentials-file: ~/.cloudflared/<tunnel-id>.json

ingress:
  - hostname: dev.yourdomain.com
    service: http://localhost:3006
  - service: http_status:404
EOF

# Run tunnel
cloudflared tunnel run fluke-dev
```

4. **Allow tunnel host in Rails:**

```ruby
# config/environments/development.rb
config.hosts << /.*\.trycloudflare\.com/
config.hosts << "dev.yourdomain.com"
```

5. **Update GitHub App settings:**
   - Callback URL: `https://dev.yourdomain.com/users/auth/github/callback`
   - Webhook URL: `https://dev.yourdomain.com/webhooks/github`

---

## Testing

### Verify Configuration

```bash
bin/rails runner '
puts "=== GitHub App Configuration ==="
puts "App ID: #{Github::AppConfig.app_id}"
puts "Client ID: #{Github::AppConfig.client_id}"
puts "Client Secret: #{Github::AppConfig.client_secret.present? ? "[SET]" : "[NOT SET]"}"
puts "Webhook Secret: #{Github::AppConfig.webhook_secret.present? ? "[SET]" : "[NOT SET]"}"
puts "Private Key: #{Github::AppConfig.private_key.present? ? "[SET]" : "[NOT SET]"}"
puts ""
puts "configured?: #{Github::AppConfig.configured?}"
puts "fully_configured?: #{Github::AppConfig.fully_configured?}"
'
```

### Test JWT Generation

```bash
bin/rails runner '
result = Github::AppJwtGenerator.call
if result.success?
  jwt = result.value!
  require "jwt"
  payload, _ = JWT.decode(jwt, nil, false)
  puts "JWT Generated Successfully"
  puts "  App ID: #{payload["iss"]}"
  puts "  Expires: #{Time.at(payload["exp"])}"
else
  puts "FAILED: #{result.failure}"
end
'
```

### Test Webhook Signature Validation

```bash
PAYLOAD='{"zen":"test"}'
SECRET="your_webhook_secret"
SIGNATURE="sha256=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | cut -d' ' -f2)"

# Should return 200
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: ping" \
  -H "X-Hub-Signature-256: $SIGNATURE" \
  -d "$PAYLOAD" \
  https://dev.yourdomain.com/webhooks/github \
  -w "\nHTTP Status: %{http_code}\n"

# Without signature - should return 401
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: ping" \
  -d "$PAYLOAD" \
  https://dev.yourdomain.com/webhooks/github \
  -w "\nHTTP Status: %{http_code}\n"
```

### Test Token Encryption

```bash
bin/rails runner '
test_token = "ghu_test_#{SecureRandom.hex(10)}"

ActiveRecord::Base.transaction do
  user = User.create!(
    first_name: "Test", last_name: "User",
    email: "test-#{SecureRandom.hex(4)}@example.com",
    password: "password123",
    github_user_access_token: test_token
  )

  raw = ActiveRecord::Base.connection.execute(
    "SELECT github_user_access_token FROM users WHERE id = #{user.id}"
  ).first["github_user_access_token"]

  user.reload

  puts "Original: #{test_token}"
  puts "Encrypted in DB: #{raw[0..50]}..."
  puts "Decrypted: #{user.github_user_access_token}"
  puts ""
  puts "Encryption Working: #{raw != test_token && user.github_user_access_token == test_token ? "YES" : "NO"}"

  raise ActiveRecord::Rollback
end
'
```

### Test OAuth Flow

1. Start Rails server and tunnel
2. Visit: `https://dev.yourdomain.com/users/sign_in`
3. Click "Continue with GitHub"
4. Authorize the app
5. Verify redirect back and successful login

---

## Troubleshooting

### OAuth Returns "Not found. Authentication passthru."

**Cause:** OmniAuth only accepts POST requests for security.

**Solution:** Use the sign-in page form, not a direct GET request:
```
https://yourdomain.com/users/sign_in → Click "Continue with GitHub"
```

### Rate Limit Exceeded During OAuth

**Cause:** Your GitHub account has hit API rate limits.

**Solution:** Wait ~60 minutes for reset, or use a different GitHub account.

### Webhook Returns 401 Unauthorized

**Cause:** Invalid or missing signature.

**Checklist:**
1. Verify `GITHUB_APP_WEBHOOK_SECRET` matches GitHub App settings
2. Ensure signature header is `X-Hub-Signature-256` (not `X-Hub-Signature`)
3. Check Rails logs for signature validation errors

### Webhook Returns 500 in Production

**Cause:** Webhook secret not configured.

**Solution:** Set `GITHUB_APP_WEBHOOK_SECRET` environment variable.

### Token Refresh Fails

**Cause:** Refresh token expired (6-month lifetime).

**Solution:** User needs to re-authenticate via OAuth:
```ruby
user.github_needs_reauth?  # => true
user.disconnect_github_app!
# Redirect user to /users/auth/github
```

### Installation Token Generation Fails

**Cause:** Private key not configured or invalid.

**Checklist:**
1. Verify `GITHUB_APP_PRIVATE_KEY_PATH` points to valid .pem file
2. Check file permissions: `chmod 600 /path/to/private-key.pem`
3. Verify the key was downloaded from the correct GitHub App

---

## Files Reference

### Core Services

| File | Purpose |
|------|---------|
| `app/services/github/app_config.rb` | Centralized configuration |
| `app/services/github/app_jwt_generator.rb` | JWT generation for API auth |
| `app/services/github/installation_token_service.rb` | Installation token management |
| `app/services/github/token_refresh_service.rb` | OAuth token refresh |

### Controllers

| File | Purpose |
|------|---------|
| `app/controllers/users/omniauth_callbacks_controller.rb` | OAuth callback handling |
| `app/controllers/webhooks/github_controller.rb` | Webhook processing |

### Jobs

| File | Purpose |
|------|---------|
| `app/jobs/github_polling_job.rb` | Background commit polling |
| `app/jobs/github_commit_refresh_job.rb` | Commit fetching per branch |

### Configuration

| File | Purpose |
|------|---------|
| `config/initializers/devise.rb` | OAuth provider setup |
| `config/initializers/omniauth.rb` | OmniAuth security settings |

### Migrations

| File | Purpose |
|------|---------|
| `db/migrate/20251224212823_encrypt_github_token_columns.rb` | Token column type change |
| `db/migrate/20251224213259_add_github_refresh_token_expires_at_to_users.rb` | Refresh token expiry |

---

## Security Checklist

Before deploying to production:

- [ ] `GITHUB_APP_WEBHOOK_SECRET` is set (required in production)
- [ ] Active Record Encryption keys are in credentials
- [ ] Private key file has restricted permissions (600)
- [ ] Callback URLs use HTTPS
- [ ] Webhook URL uses HTTPS
- [ ] Token columns are `text` type (for encrypted storage)
- [ ] Rate limiting is configured for OAuth endpoints

---

## References

- [GitHub App Best Practices](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/best-practices-for-creating-a-github-app)
- [GitHub OAuth Web Application Flow](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps)
- [Refreshing User Access Tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens)
- [Webhook Security](https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries)
- [PKCE RFC 7636](https://datatracker.ietf.org/doc/html/rfc7636)
- [Active Record Encryption](https://guides.rubyonrails.org/active_record_encryption.html)

---

**Last Updated:** 2024-12-24
**Version:** 1.0
**Status:** Production Ready
