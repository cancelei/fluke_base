# WEDO Tasks: Device Authorization & Access Control

## fluke_base (Rails Backend)

### FB-AUTH-01: DeviceAuthorization Model
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** auth, model, backend

Create `DeviceAuthorization` model for tracking CLI devices:

```ruby
# Fields
- user_id: references (indexed)
- device_id: string (UUID, unique, indexed)
- device_name: string (hostname)
- os_type: string (macos, linux, windows)
- os_version: string
- last_active_at: datetime
- ip_address: inet
- revoked_at: datetime (nullable)
- created_at, updated_at: timestamps
```

**Acceptance Criteria:**
- [ ] Generate migration with proper indexes
- [ ] Add `belongs_to :user` association
- [ ] Add scopes: `active`, `revoked`
- [ ] Add `revoke!` method
- [ ] Add validation for device_id uniqueness

---

### FB-AUTH-02: Device Management API Endpoints
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** auth, api, backend

Create RESTful API for device management:

```
POST   /api/v1/devices          - Register new device
GET    /api/v1/devices          - List user's devices
GET    /api/v1/devices/:id      - Show device details
DELETE /api/v1/devices/:id      - Revoke device
POST   /api/v1/devices/:id/ping - Update last_active_at
```

**Acceptance Criteria:**
- [ ] Create `Api::V1::DevicesController`
- [ ] Authenticate via API token
- [ ] Scope to current user's devices only
- [ ] Return proper JSON responses
- [ ] Add rate limiting for ping endpoint
- [ ] Add Swagger/OpenAPI documentation

---

### FB-AUTH-03: Project Collaborator Access Control
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** auth, access-control, backend

Extend collaborator model with CLI access toggle:

```ruby
# Add to project_collaborators or create new join model
- can_use_cli: boolean, default: true
- cli_access_revoked_at: datetime
- cli_access_revoked_by_id: references
```

**Acceptance Criteria:**
- [ ] Add migration for CLI access fields
- [ ] Add `toggle_cli_access!` method
- [ ] Add policy for CLI access checking
- [ ] Integrate with API token validation
- [ ] Add audit trail for access changes

---

### FB-AUTH-04: Cascading Device Revocation
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** auth, access-control, backend

When project owner removes collaborator or disables CLI access:
- Automatically revoke all their devices for that project
- Send notification to affected user
- Log action in audit trail
- Optionally revoke API tokens

**Acceptance Criteria:**
- [ ] Create `CollaboratorAccessService`
- [ ] Hook into collaborator removal callbacks
- [ ] Batch revoke related devices
- [ ] Send email notification
- [ ] Record in audit log
- [ ] Add admin override capability

---

### FB-AUTH-05: API Token Scoping
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** auth, security, backend

Enhance API tokens with device binding:
- Token can be scoped to specific device_id
- Validate device_id on each request
- Reject requests from revoked devices
- Support device-agnostic tokens for CI/CD

**Acceptance Criteria:**
- [ ] Add `device_id` column to api_tokens
- [ ] Add validation in authentication flow
- [ ] Add `--device-bound` flag for token creation
- [ ] Document scoping behavior

---

## fluke_base (Frontend)

### FB-UI-01: Device Management Page
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** frontend, ui, device-management

Create user settings page for managing authorized devices:
- List all devices with visual cards
- Show: device name, OS icon, last active, IP location
- "Revoke" button with confirmation modal
- "Revoke All Other Devices" bulk action
- Matches CLI `fb_devices` output

**Acceptance Criteria:**
- [ ] Create `/settings/devices` route
- [ ] Create `Devices::IndexComponent`
- [ ] Add OS icons (macOS, Linux, Windows)
- [ ] Implement revoke with Turbo
- [ ] Add "This device" badge for current
- [ ] Mobile-responsive design

---

### FB-UI-02: Collaborator CLI Access Panel
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** frontend, ui, access-control

Project settings panel for managing collaborator CLI access:
- List collaborators with toggle switches
- Show CLI access status per collaborator
- Bulk enable/disable options
- Activity log preview
- Non-technical friendly labels

**Acceptance Criteria:**
- [ ] Add to project settings page
- [ ] Create `Collaborators::CliAccessComponent`
- [ ] Toggle switches with Stimulus
- [ ] Confirmation for bulk actions
- [ ] Clear permission explanations
- [ ] Real-time updates via Turbo

---

### FB-UI-03: Device Removal Help Section
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** frontend, docs, ux

In-app help explaining device management:
- Step-by-step: Remove device from web UI
- Step-by-step: Remove device from CLI (`fb_devices revoke`)
- FAQ: "What happens when I revoke?"
- FAQ: "Why was my device auto-revoked?"
- Screenshots and clear language for non-technical users

**Acceptance Criteria:**
- [ ] Create help article in docs system
- [ ] Add contextual help links in UI
- [ ] Include CLI command examples
- [ ] Add tooltip explanations
- [ ] Test with non-technical users

---

### FB-UI-04: Activity Dashboard (CLI Capabilities Mirror)
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** frontend, ui, dashboard

Dashboard showing what users can access via CLI:
- Projects list (mirrors `fb_projects`)
- Environment variables (mirrors `env_show`)
- Memories summary (mirrors `recall`)
- Active tasks (mirrors `wedo_list_tasks`)
- Connection status (mirrors `fb_status`)

**Acceptance Criteria:**
- [ ] Create dashboard widgets
- [ ] Real-time sync status indicator
- [ ] "Try in CLI" command hints
- [ ] Collapsible sections
- [ ] Export/copy functionality

---

### FB-UI-05: Security Notifications
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** frontend, notifications, security

Notify users of security-relevant events:
- New device authorized
- Device revoked (by self or admin)
- CLI access disabled by project owner
- Suspicious login attempt

**Acceptance Criteria:**
- [ ] Email notifications for security events
- [ ] In-app notification center
- [ ] Push notifications (optional)
- [ ] "Don't recognize this? Secure your account" link

---

## Integration Tasks

### FB-INT-01: CLI-Web Parity Audit
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** integration, testing

Ensure web UI shows same data as CLI:
- Compare `fb_status` output with dashboard
- Compare `fb_devices` with devices page
- Compare `fb_projects` with projects list
- Document any intentional differences

**Acceptance Criteria:**
- [ ] Create comparison checklist
- [ ] Test each CLI command vs web equivalent
- [ ] Fix any data mismatches
- [ ] Document behavior differences

---

### FB-INT-02: E2E Device Flow Tests
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** testing, e2e

Playwright tests for device management:
- [ ] Register device via API
- [ ] View devices in web UI
- [ ] Revoke device from web
- [ ] Verify CLI shows revoked status
- [ ] Test collaborator access toggle

---

## Documentation Tasks

### FB-DOC-01: Admin Guide for Access Control
**Status:** pending
**Dependency:** AGENT_CAPABLE
**Tags:** docs, admin

Documentation for project owners:
- How to manage collaborator CLI access
- When to revoke devices
- Audit trail interpretation
- Best practices for team security
