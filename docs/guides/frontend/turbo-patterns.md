# Turbo Patterns

**Last Updated**: 2025-12-13
**Document Type**: Guide
**Audience**: Developers, AI Agents

Complete guide to Turbo Drive, Frames, and Streams usage in FlukeBase. Follows "Turbo First, Stimulus Last" philosophy with advanced patterns including lazy loading, real-time updates, and command-based multi-frame updates.

---

## For AI Agents

### Decision Tree: Which Turbo Feature to Use?

```
What's the user interaction?
│
├─ Full page navigation?
│  └─ Use Turbo Drive (default) ✅
│     - No configuration needed
│     - Works automatically
│
├─ Expensive content that should load after page?
│  └─ Use Lazy Turbo Frame ✅
│     - render LazyTurboFrameComponent
│     - loading: "lazy" attribute
│     - Skeleton or spinner placeholder
│
├─ Real-time updates from server (timer, chat)?
│  └─ Use Turbo Streams over Broadcast ✅
│     - turbo_stream_from in view
│     - broadcast_* in model
│     - Example: time tracking updates
│
├─ Update part of page without full reload?
│  ├─ Single update after user action (click button)?
│  │  └─ Use Turbo Frame ✅
│  │     - Wrap target area in turbo_frame_tag
│  │     - Link/form inside frame auto-updates frame
│  │
│  └─ Multiple updates OR complex server response?
│     └─ Use Turbo Stream ✅
│        - Controller responds with format.turbo_stream
│        - Can update multiple targets
│        - Use Command pattern for complex updates
│
└─ Show notification after action?
   └─ Use Toast Component via Turbo Stream ✅
      - Include Flashable concern in command
      - toast_success/toast_error/toast_info
```

### Anti-Patterns

❌ DO NOT eagerly load expensive content (use lazy frames)
❌ DO NOT manually update multiple frames (use MultiFrameUpdatable concern)
❌ DO NOT forget turbo_frame_request? check for hybrid endpoints
❌ DO NOT use vanilla flash (use toast notifications)
❌ DO NOT broadcast without channel names (causes cross-project pollution)
✅ DO use LazyTurboFrameComponent for heavy sections
✅ DO use Command pattern for complex Turbo Stream responses
✅ DO check turbo_frame_request? for endpoints serving both frame and full page
✅ DO use Flashable and MultiFrameUpdatable concerns

---

## Turbo Drive (Default Navigation)

### What is Turbo Drive?

Automatic page navigation without full reloads. Replaces `<body>` content while keeping `<head>` stable.

**Configuration**: Enabled by default in Rails 8 via Turbo Rails gem.

### When to Disable

```erb
<!-- Disable on external link -->
<%= link_to "External Site", "https://example.com", data: { turbo: false } %>

<!-- Disable on form with custom JS -->
<%= form_with model: @resource, data: { turbo: false } do |f| %>
  ...
<% end %>
```

⚠️ **Note**: Disable sparingly—Turbo Drive works for 95% of navigation.

---

## Turbo Frames (Partial Updates)

### Basic Frame Pattern

```erb
<!-- Wrap target area -->
<%= turbo_frame_tag "unique_frame_id" do %>
  <div>Initial content</div>
  <%= link_to "Update", edit_path %>  <!-- Auto-updates this frame -->
<% end %>
```

### Frame Pattern 1: Lazy Loading with Component

**What is Lazy Loading?**
Load expensive content **after** initial page load to improve perceived performance.

**File**: `/app/components/lazy_turbo_frame_component.rb`

```ruby
class LazyTurboFrameComponent < ApplicationComponent
  def initialize(
    frame_id:,
    src_path:,
    title: nil,
    description: nil,
    placeholder: :spinner,  # :spinner or :skeleton
    skeleton_variant: :card,
    skeleton_count: 1,
    css_class: nil
  )
    # ...
  end

  def call
    helpers.turbo_frame_tag(@frame_id, src: @src_path, loading: "lazy", class: @css_class) do
      render_placeholder  # Spinner or skeleton
    end
  end
end
```

**Usage in Views**:

**File**: `/app/views/agreements/show.html.erb` (lines 21-25)

```erb
<!-- GitHub Integration Section (expensive API calls) -->
<%= render "shared/lazy_turbo_frame",
    frame_id: "#{dom_id(@agreement)}_github",
    src_path: github_section_agreement_path(@agreement),
    title: "GitHub Integration",
    description: "Repository access and development activity" %>
```

**How it works**:
1. Initial page load shows **spinner placeholder**
2. Browser loads frame content from `src_path` **after** page renders
3. Turbo replaces spinner with actual content
4. **No blocking render** for expensive operations

---

#### Lazy Frame with Skeleton Placeholder

```erb
<%= render LazyTurboFrameComponent.new(
  frame_id: "project_cards",
  src_path: projects_path,
  placeholder: :skeleton,
  skeleton_variant: :project_card,
  skeleton_count: 6,
  skeleton_layout: :grid
) %>
```

**Benefits**:
- Shows content-shaped placeholders
- Better perceived performance than spinners
- User sees page structure immediately

---

### Frame Pattern 2: Hybrid Endpoints (Frame + Full Page)

**Problem**: Some endpoints must serve **both** Turbo Frame requests and full-page navigation.

**Solution**: Use `turbo_frame_request?` check

**File**: `/app/controllers/meetings_controller.rb` (lines 14-24)

```ruby
def show
  respond_to do |format|
    format.html do
      if turbo_frame_request?
        # Request came from inside a Turbo Frame
        render partial: "meeting_details", locals: { meeting: @meeting }
      else
        # Direct URL access or full page navigation
        # Renders full layout with navbar, etc.
      end
    end
  end
end
```

**When to use**:
- Modals that open via frame but need direct URL access
- Inline forms that can also be accessed as standalone pages
- Details sections that load lazily but can be deep-linked

---

### Frame Pattern 3: Inline Editing (Meetings)

**File**: `/app/views/agreements/_meetings_section.html.erb`

```erb
<%= turbo_frame_tag "#{dom_id(@agreement)}_meetings" do %>
  <div class="card">
    <h3>Meetings</h3>

    <!-- Meetings list -->
    <%= turbo_frame_tag "#{dom_id(@agreement)}_meetings_list" do %>
      <%= render "meetings_list", meetings: @meetings %>
    <% end %>

    <!-- Form area -->
    <%= turbo_frame_tag "#{dom_id(@agreement)}_meeting_form" do %>
      <%= link_to "Schedule Meeting", new_agreement_meeting_path(@agreement),
          data: { turbo_frame: "#{dom_id(@agreement)}_meeting_form" } %>
    <% end %>
  </div>
<% end %>
```

**Nested Frame Structure**:
```
meetings (outer frame)
├── meetings_list (inner frame - updates after create/delete)
└── meeting_form (inner frame - toggles between link and form)
```

**How it works**:
1. Click "Schedule Meeting" → Loads form into `meeting_form` frame
2. Submit form → Updates both `meetings_list` (new meeting) and `meeting_form` (reset button)
3. **No parent frame reload** - only targeted updates

---

## Turbo Streams (Multiple Updates)

### Stream Actions

```ruby
turbo_stream.append("target_id", ...)    # Add to end
turbo_stream.prepend("target_id", ...)   # Add to beginning
turbo_stream.replace("target_id", ...)   # Replace entire element
turbo_stream.update("target_id", ...)    # Replace innerHTML only
turbo_stream.remove("target_id")         # Delete element
```

### Stream Pattern 1: Multi-Frame Updates (Meetings)

**File**: `/app/views/meetings/create.turbo_stream.erb`

```erb
<!-- Update meetings list -->
<%= turbo_stream.replace "#{dom_id(@agreement)}_meetings_list" do %>
  <%= render "meetings_list", meetings: @meetings, agreement: @agreement %>
<% end %>

<!-- Reset form -->
<%= turbo_stream.replace "#{dom_id(@agreement)}_meeting_form" do %>
  <div class="text-center py-4">
    <%= link_to "Schedule Another Meeting", new_agreement_meeting_path(@agreement),
        class: "btn btn-primary",
        data: { turbo_frame: "#{dom_id(@agreement)}_meeting_form" } %>
  </div>
<% end %>

<!-- Show success toast -->
<%= turbo_stream.prepend "flash-messages" do %>
  <div class="alert alert-success" data-controller="auto-dismiss">
    <span>Meeting was successfully scheduled.</span>
  </div>
<% end %>
```

**Result**: Three frames update with one response

---

### Stream Pattern 2: Command Pattern with Concerns

**Problem**: Controllers become bloated with repeated Turbo Stream logic.

**Solution**: Extract to Command objects with reusable concerns.

#### Flashable Concern (Toast Notifications)

**File**: `/app/commands/concerns/flashable.rb`

```ruby
module Flashable
  extend ActiveSupport::Concern

  # Display toast notification
  # @param type [Symbol] Toast type (:success, :error, :info, :warning)
  # @param message [String] The message to display
  def flash_toast(type, message, **options)
    component = Ui::ToastComponent.new(
      type: type,
      message: message,
      timeout: options[:timeout] || 5000
    )

    turbo_streams << turbo_stream.append(
      "body",
      component.render_in(controller.view_context)
    )
  end

  # Convenience methods
  def toast_success(message, **options)
    flash_toast(:success, message, **options)
  end

  def toast_error(message, **options)
    flash_toast(:error, message, **options)
  end
end
```

**Usage in Command**:

```ruby
class TimeLog::StartTrackingCommand < ApplicationCommand
  include Flashable
  include MultiFrameUpdatable

  def call
    time_log = TimeLog.create!(
      project: project,
      user: user,
      milestone: milestone,
      started_at: Time.current,
      status: "in_progress"
    )

    if time_log.persisted?
      toast_success("Time tracking started for #{milestone.name}")
      update_time_logs_frames(project: project, ...)
    else
      toast_error("Failed to start tracking")
    end

    time_log
  end
end
```

---

#### MultiFrameUpdatable Concern

**File**: `/app/commands/concerns/multi_frame_updatable.rb`

```ruby
module MultiFrameUpdatable
  extend ActiveSupport::Concern

  # Standard time logs page update pattern
  # Updates 4 frames used in time log operations
  def update_time_logs_frames(project:, milestones_pending:, current_log: nil, owner:)
    turbo_streams << turbo_stream.update(
      "pending_confirmation_section",
      partial: "time_logs/pending_confirmation_section",
      locals: { milestones_pending_confirmation: milestones_pending, ... }
    )

    turbo_streams << turbo_stream.update(
      "remaining_time_progress",
      partial: "remaining_time_progress",
      locals: { project: project, current_log: current_log, ... }
    )

    turbo_streams << turbo_stream.update(
      "milestone_bar_container",
      partial: "shared/milestone_bar"
    )

    turbo_streams << turbo_stream.update(
      "navbar_milestones_list",
      partial: "shared/navbar_milestones_list"
    )
  end

  # Replace a specific milestone row
  def update_milestone_row(milestone:, project:, active_log: nil)
    turbo_streams << turbo_stream.replace(
      "milestone_#{milestone.id}",
      partial: "time_logs/milestone_row",
      locals: { milestone: milestone, ... }
    )
  end
end
```

**Usage**:

```ruby
class TimeLog::StopTrackingCommand < ApplicationCommand
  include Flashable
  include MultiFrameUpdatable

  def call
    time_log.complete!(Time.current)

    toast_success("Time tracking stopped: #{time_log.hours_spent}h logged")

    # Update 4 frames + 1 milestone row in single response
    update_time_logs_frames(
      project: time_log.project,
      milestones_pending: ...,
      current_log: nil,
      owner: owner?
    )
    update_milestone_row(
      milestone: time_log.milestone,
      project: time_log.project
    )

    time_log
  end
end
```

**Result**: Clean command with **5 frame updates** in 2 method calls

---

## Real-Time Updates (Turbo Streams over Broadcast)

### What is Broadcasting?

Server pushes updates to clients via WebSocket **without** user action.

**Use Cases**:
- Live time tracking (timer updates every second)
- Chat messages from other users
- Notifications from background jobs
- Collaborative editing

---

### Broadcast Pattern 1: Time Log Updates

**File**: `/app/models/time_log.rb` (lines 28-29)

```ruby
class TimeLog < ApplicationRecord
  # ...

  after_update_commit :broadcast_time_log

  private

  def broadcast_time_log
    # Broadcast to project-specific channel
    broadcast_replace_to(
      "project_#{project_id}_time_logs",
      target: "time_log_#{id}",
      partial: "time_logs/time_log_row",
      locals: { time_log: self }
    )
  end
end
```

**How it works**:
1. User A starts time tracking
2. TimeLog record updates (elapsed time increments)
3. Broadcast sends update to all subscribed clients
4. User B (viewing same project) sees timer update **instantly**

---

### Subscribe to Broadcast (View)

**File**: `/app/views/projects/show.html.erb`

```erb
<!-- Subscribe to project-specific channel -->
<%= turbo_stream_from "project_#{@project.id}_time_logs" %>

<!-- Time logs list -->
<div id="time_logs_list">
  <% @time_logs.each do |time_log| %>
    <%= turbo_frame_tag "time_log_#{time_log.id}" do %>
      <%= render "time_logs/time_log_row", time_log: time_log %>
    <% end %>
  <% end %>
</div>
```

**Channel Naming**:
- ✅ GOOD: `"project_#{project.id}_time_logs"` (scoped to project)
- ❌ BAD: `"time_logs"` (global channel, leaks data across projects)

⚠️ **Security**: Always scope channels to prevent data leakage

---

### Broadcast Pattern 2: Chat Messages

**File**: `/app/views/conversations/show.html.erb`

```erb
<!-- Subscribe to conversation-specific channel -->
<%= turbo_stream_from "conversation_#{@conversation.id}_messages" %>

<div id="messages_list">
  <% @messages.each do |message| %>
    <%= render "messages/message", message: message %>
  <% end %>
</div>
```

**File**: `/app/models/message.rb`

```ruby
class Message < ApplicationRecord
  after_create_commit -> {
    broadcast_append_to(
      "conversation_#{conversation_id}_messages",
      target: "messages_list",
      partial: "messages/message",
      locals: { message: self }
    )
  }
end
```

**How it works**:
1. User A sends message
2. Message created in database
3. Broadcast appends to `messages_list` for all viewers
4. User B sees new message appear **without refresh**

---

## Advanced Patterns

### Pattern 1: Toast Notification System

**File**: `/app/views/shared/_toast_turbo_stream.turbo_stream.erb`

```erb
<%
  type = local_assigns[:type] || :info
  message = local_assigns[:message]
  timeout = local_assigns[:timeout] || 5000
%>
<% if message.present? %>
  <%= render "shared/toast_notification",
             type: type,
             message: message,
             timeout: timeout %>
<% end %>
```

**Usage in Controller**:

```ruby
respond_to do |format|
  format.turbo_stream {
    render turbo_stream: turbo_stream.append("body",
      partial: "shared/toast_turbo_stream",
      locals: { type: :success, message: "Meeting created!" }
    )
  }
end
```

**Better: Use Flashable Concern**:

```ruby
class CreateMeetingCommand < ApplicationCommand
  include Flashable

  def call
    meeting = Meeting.create!(...)
    toast_success("Meeting created!", title: "Success", timeout: 3000)
    meeting
  end
end
```

---

### Pattern 2: Agreement State Transitions

**File**: `/app/views/agreements/accept.turbo_stream.erb`

```erb
<!-- Replace agreement card with updated status -->
<%= turbo_stream.replace dom_id(@agreement) do %>
  <%= render "agreement_show_content", agreement: @agreement %>
<% end %>

<!-- Update project agreements list (if on projects page) -->
<% if @project %>
  <%= turbo_stream.update "project_#{@project.id}_agreements_count" do %>
    <%= @project.agreements.accepted.count %> active
  <% end %>
<% end %>

<!-- Show success toast -->
<%= turbo_stream.append "body" do %>
  <%= render Ui::ToastComponent.new(
    type: :success,
    message: "Agreement accepted! Time tracking is now enabled."
  ) %>
<% end %>
```

---

### Pattern 3: Conditional Frame Rendering

**File**: `/app/controllers/agreements_controller.rb`

```ruby
def show
  @agreement = Agreement.find(params[:id])
  @project = @agreement.project

  respond_to do |format|
    format.html {
      # Check if request is from Turbo Frame
      if turbo_frame_request?
        # Render minimal content (no layout)
        render partial: "agreement_show_content",
               locals: { agreement: @agreement }
      else
        # Full page render (with layout, navbar, etc.)
        # Renders show.html.erb normally
      end
    }
  end
end
```

**When to use**:
- Endpoints accessed both via frame and direct URL
- Modal content that can be deep-linked
- Sections that load lazily but need SEO

---

## Testing Turbo Interactions

### System Test Example (Lazy Frames)

```ruby
require "test_helper"

class AgreementsShowTest < ApplicationSystemTestCase
  test "lazy loads GitHub section" do
    agreement = agreements(:active)
    visit agreement_path(agreement)

    # Initially shows spinner
    assert_selector "[id='#{dom_id(agreement)}_github']"
    assert_text "GitHub Integration"

    # Wait for lazy frame to load
    assert_selector "[id='#{dom_id(agreement)}_github'] .github-commits", wait: 5

    # Verify content loaded
    assert_text "Recent Commits"
  end
end
```

---

### Request Test Example (Multi-Frame Updates)

**File**: `/spec/requests/agreements_turbo_stream_spec.rb`

```ruby
require "rails_helper"

RSpec.describe "Agreements Turbo Streams", type: :request do
  let(:agreement) { create(:agreement, status: "Pending") }
  let(:user) { agreement.user }

  before { sign_in user }

  describe "PATCH /agreements/:id/accept" do
    it "returns turbo stream response with multiple updates" do
      patch accept_agreement_path(agreement), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq Mime[:turbo_stream]

      # Verify multiple turbo_stream actions
      expect(response.body).to include("turbo-stream action=\"replace\"")
      expect(response.body).to include(dom_id(agreement))
      expect(response.body).to include("Agreement accepted")
    end
  end
end
```

---

### Playwright Test Example (Real-time Updates)

```javascript
// test/playwright/time_tracking.spec.js
import { test, expect } from '@playwright/test';

test('real-time time tracking updates', async ({ page, context }) => {
  // User A starts time tracking
  await page.goto('/projects/1');
  await page.click('[data-testid="start-tracking-milestone-1"]');

  // Verify timer started
  await expect(page.locator('[data-testid="timer-milestone-1"]')).toContainText('0:00');

  // Open second tab as User B
  const page2 = await context.newPage();
  await page2.goto('/projects/1');

  // Verify User B sees timer (via broadcast)
  await expect(page2.locator('[data-testid="timer-milestone-1"]')).toBeVisible();

  // Wait for timer to increment
  await page.waitForTimeout(2000);

  // Both users see updated time
  await expect(page.locator('[data-testid="timer-milestone-1"]')).toContainText('0:02');
  await expect(page2.locator('[data-testid="timer-milestone-1"]')).toContainText('0:02');
});
```

---

## Common Patterns Summary

### When to Use Each Feature

| Scenario | Feature | Example |
|----------|---------|---------|
| Full page navigation | Turbo Drive | Dashboard → Projects |
| Expensive content (API calls, charts) | Lazy Turbo Frame | GitHub integration section |
| Single section update (user click) | Turbo Frame | Edit meeting inline |
| Multiple updates (one action) | Turbo Stream | Create meeting (update list + form + toast) |
| Complex multi-frame updates | Command + Concerns | Time tracking (5+ frames) |
| Real-time updates (timers, chat) | Turbo Streams + Broadcast | Live time tracking |
| User notifications | Toast Component | Success/error messages |

---

### Frame ID Naming Conventions

```ruby
# ✅ GOOD: Scoped, unique IDs
"#{dom_id(@agreement)}_github"           # agreement_123_github
"#{dom_id(@project)}_meetings_list"     # project_456_meetings_list
"time_log_#{time_log.id}"                # time_log_789

# ❌ BAD: Generic IDs (conflicts across items)
"github_section"      # Multiple agreements on page
"meetings_list"       # Ambiguous
"form"                # Too generic
```

---

### Broadcast Channel Naming

```ruby
# ✅ GOOD: Scoped to resource
"project_#{project.id}_time_logs"
"conversation_#{conversation.id}_messages"
"user_#{user.id}_notifications"

# ❌ BAD: Global channels
"time_logs"           # Leaks across projects
"messages"            # Leaks across conversations
"notifications"       # Leaks across users
```

---

## Best Practices

### ✅ DO

1. **Use LazyTurboFrameComponent for expensive content** - Defer API calls, charts, large lists
2. **Scope broadcast channels** - Always include resource ID in channel name
3. **Use Command pattern for complex updates** - Include Flashable and MultiFrameUpdatable concerns
4. **Check turbo_frame_request?** - For hybrid endpoints (frame + full page)
5. **Use toast notifications** - Better UX than page-level flash messages
6. **Nest frames strategically** - Update child frames without reloading parent
7. **Test real-time features** - Use Playwright multi-tab tests for broadcasts

### ❌ DON'T

1. **Don't eagerly load expensive content** - Use lazy frames instead
2. **Don't use global broadcast channels** - Always scope to resource ID
3. **Don't manually build multi-frame responses** - Use MultiFrameUpdatable concern
4. **Don't forget turbo_frame_request? check** - Causes layout issues
5. **Don't use vanilla flash** - Use toast components for Turbo apps
6. **Don't nest frames > 3 levels deep** - Becomes hard to maintain
7. **Don't broadcast sensitive data** - Verify channel permissions

---

## Troubleshooting

### Issue: Lazy frame not loading

**Symptoms**: Spinner shows forever
**Cause**: `src_path` returns 404 or error

**Solution**:
```ruby
# Verify endpoint exists
Rails.application.routes.url_helpers.github_section_agreement_path(@agreement)
# => "/agreements/123/github_section"

# Check controller action renders frame
def github_section
  render partial: "github_section", locals: { ... }
end
```

---

### Issue: Broadcast not received

**Symptoms**: Real-time updates don't appear
**Cause 1**: Channel name mismatch
**Cause 2**: Missing cable configuration

**Solution 1 - Verify channel names**:
```ruby
# View
<%= turbo_stream_from "project_#{@project.id}_time_logs" %>

# Model (must match exactly)
broadcast_replace_to "project_#{project_id}_time_logs", ...
```

**Solution 2 - Check cable config**:
```yaml
# config/cable.yml
development:
  adapter: solid_cable  # Rails 8 default

production:
  adapter: solid_cable
  # Or use Redis for multi-server deployments
```

---

### Issue: Multiple frames update on single click

**Symptoms**: Click "Edit" and 3+ sections reload
**Cause**: Frame nesting without proper targeting

**Solution**:
```erb
<!-- ❌ BAD: Parent frame catches navigation -->
<%= turbo_frame_tag "parent" do %>
  <%= turbo_frame_tag "child" do %>
    <%= link_to "Edit", edit_path %>  <!-- Updates parent, not child -->
  <% end %>
<% end %>

<!-- ✅ GOOD: Explicit target -->
<%= turbo_frame_tag "parent" do %>
  <%= turbo_frame_tag "child" do %>
    <%= link_to "Edit", edit_path, data: { turbo_frame: "child" } %>
  <% end %>
<% end %>
```

---

### Issue: Toast notifications stack forever

**Symptoms**: Old toasts never disappear
**Cause**: Missing auto-dismiss controller

**Solution**:
```erb
<div class="alert" data-controller="auto-dismiss" data-auto-dismiss-delay-value="5000">
  <%= message %>
</div>
```

```javascript
// app/javascript/controllers/auto_dismiss_controller.js
export default class extends Controller {
  static values = { delay: { type: Number, default: 5000 } }

  connect() {
    setTimeout(() => {
      this.element.remove()
    }, this.delayValue)
  }
}
```

---

## For AI Agents: Quick Reference

### Files to Check
- **LazyTurboFrame**: `/app/components/lazy_turbo_frame_component.rb`
- **Flashable Concern**: `/app/commands/concerns/flashable.rb`
- **MultiFrameUpdatable**: `/app/commands/concerns/multi_frame_updatable.rb`
- **Toast Partial**: `/app/views/shared/_toast_turbo_stream.turbo_stream.erb`
- **Broadcasts**: `/app/models/time_log.rb` (line 28)

### Common Tasks

**Add lazy-loaded section**:
```erb
<%= render LazyTurboFrameComponent.new(
  frame_id: "section_id",
  src_path: section_path,
  title: "Loading...",
  placeholder: :skeleton,
  skeleton_variant: :card
) %>
```

**Use Command with toast**:
```ruby
class MyCommand < ApplicationCommand
  include Flashable

  def call
    result = perform_action
    toast_success("Action completed!")
    result
  end
end
```

**Update multiple frames**:
```ruby
class MyCommand < ApplicationCommand
  include MultiFrameUpdatable

  def call
    update_time_logs_frames(project: project, ...)
    update_milestone_row(milestone: milestone, ...)
  end
end
```

**Add real-time broadcast**:
```ruby
# Model
after_update_commit -> {
  broadcast_replace_to "resource_#{resource_id}_items",
                       target: "item_#{id}",
                       partial: "items/item"
}

# View
<%= turbo_stream_from "resource_#{@resource.id}_items" %>
```

**Hybrid endpoint (frame + full page)**:
```ruby
def show
  respond_to do |format|
    format.html do
      if turbo_frame_request?
        render partial: "content"
      else
        # Full page with layout
      end
    end
  end
end
```

---

## Related Documentation

- [Stimulus Usage Guidelines](stimulus-usage-guidelines.md) - When to use Stimulus vs Turbo
- [Agreement State Machine](../workflows/agreement-negotiation-state-machine.md) - Turbo Streams for state transitions
- [Multi-Database Architecture](../architecture/multi-database-architecture.md) - ActionCable with SolidCable
- [Testing Guide](../testing/testing-strategy.md) - Testing Turbo interactions
- [Hotwire Documentation](https://hotwired.dev/) - Official Turbo docs
