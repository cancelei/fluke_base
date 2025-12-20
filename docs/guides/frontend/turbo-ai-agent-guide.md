# AI Agent Guide: Turbo-First Development

**Last Updated**: 2025-12-20
**Document Type**: Guide
**Audience**: AI Agents, Developers

This guide provides AI agents with clear, prescriptive guidance for implementing features in FlukeBase using a Turbo-first approach with minimal Stimulus controller usage.

---

## Quick Decision Tree

**START HERE** before implementing any feature:

```
Need to build a feature?
│
├─ Does it require server data or updates?
│  YES → Use Turbo (Frames/Streams) ✅ STOP
│  NO → Continue
│
├─ Is it form submission or validation?
│  YES → Use Turbo + server validation ✅ STOP
│  NO → Continue
│
├─ Is it navigation or routing?
│  YES → Use Turbo Drive/Frames ✅ STOP
│  NO → Continue
│
├─ Can CSS handle it?
│  YES → Use CSS (:hover, :focus-within, transitions) ✅ STOP
│  NO → Continue
│
├─ Can HTML5 handle it?
│  YES → Use HTML5 attributes (required, pattern, <dialog>) ✅ STOP
│  NO → Continue
│
├─ Is it wrapping a third-party library?
│  YES → Stimulus wrapper is appropriate ⚠️ Keep minimal
│  NO → Continue
│
├─ Is it enhancing Turbo (debounce, loading states)?
│  YES → Minimal Stimulus OK ⚠️ < 50 lines
│  NO → Continue
│
└─ Is it managing client-side UI state ONLY?
   YES → Minimal Stimulus OK ⚠️ < 50 lines
   NO → Reconsider entire approach ❌
```

---

## Rule #1: Turbo First, Stimulus Last

### The Philosophy

**Turbo handles 90% of web application interactivity without JavaScript.**

- ✅ **Use Turbo for**: Forms, navigation, updates, real-time features, modals
- ⚠️ **Use Stimulus for**: Debouncing, animations, third-party library wrappers
- ❌ **Never use raw JavaScript for**: Fetch calls, form handling, DOM updates from server data

### Why This Matters

1. **Less JavaScript = Fewer Bugs**: Server-side code is easier to test and maintain
2. **Better Performance**: Browser-native HTML rendering is faster
3. **Progressive Enhancement**: Features work without JavaScript when possible
4. **SEO Friendly**: Server-rendered HTML is crawlable

---

## Implementation Patterns for FlukeBase

### Pattern 1: Agreement Forms

#### ✅ DO: Use Turbo Frames for agreement creation

```erb
<%# Agreement form with dynamic payment fields %>
<%= turbo_frame_tag "agreement_form" do %>
  <%= form_with model: @agreement do |f| %>
    <%= f.text_field :title %>
    <%= f.select :payment_type, Agreement::PAYMENT_TYPES,
                 data: { action: "change->agreement-form#updatePaymentFields" } %>

    <%= turbo_frame_tag "payment_fields" do %>
      <%# Rendered based on payment type %>
    <% end %>

    <%= f.submit "Create Agreement" %>
  <% end %>
<% end %>
```

#### ✅ DO: Use Turbo Streams for validation errors

```ruby
# Controller
def create
  @agreement = Agreement.new(agreement_params)
  @agreement.initiator = current_user

  if @agreement.save
    redirect_to @agreement, notice: "Agreement created!"
  else
    render :new, status: :unprocessable_content
  end
end
```

### Pattern 2: Time Tracking

#### ✅ DO: Use Turbo Streams for real-time timer updates

```erb
<%# Subscribe to time log updates %>
<%= turbo_stream_from @milestone, "time_logs" %>

<div id="time_log_list">
  <%= render @time_logs %>
</div>
```

```ruby
# Broadcast from model
class TimeLog < ApplicationRecord
  after_create_commit -> {
    broadcast_prepend_to(
      milestone,
      "time_logs",
      target: "time_log_list",
      partial: "time_logs/time_log",
      locals: { time_log: self }
    )
  }
end
```

### Pattern 3: Milestone Management

#### ✅ DO: Use Turbo Frames for milestone updates

```erb
<%= turbo_frame_tag dom_id(@milestone) do %>
  <div class="milestone-card">
    <h3><%= @milestone.title %></h3>
    <p>Progress: <%= @milestone.completion_percentage %>%</p>
    <%= link_to "Edit", edit_milestone_path(@milestone) %>
  </div>
<% end %>
```

### Pattern 4: Messaging System

#### ✅ DO: Use Turbo Streams with Action Cable

```erb
<%# Subscribe to conversation updates %>
<%= turbo_stream_from @conversation %>

<div id="messages">
  <%= render @messages %>
</div>

<%= form_with model: [@conversation, Message.new],
              data: { controller: "message-input" } do |f| %>
  <%= f.text_area :content %>
  <%= f.submit "Send" %>
<% end %>
```

```ruby
# Model broadcasts automatically
class Message < ApplicationRecord
  after_create_commit -> {
    broadcast_append_to(
      conversation,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  }
end
```

---

## Valid Stimulus Use Cases for FlukeBase

### Category 1: Client-Side UI State

- ✅ Modal show/hide for agreements
- ✅ Tab navigation for project settings
- ✅ Theme toggle (light/dark mode)

### Category 2: Third-Party Library Wrappers

- ✅ Chart.js for analytics dashboards
- ✅ Sortable.js for milestone ordering

### Category 3: Enhancing Turbo

- ✅ Time log timer display (`time_log_controller.js`)
- ✅ Loading states for form submissions
- ✅ Debouncing search inputs

### Category 4: Domain-Specific

- ✅ AI milestone generation with streaming (`milestone_ai_controller.js`)
- ✅ Audio recording for voice messages (`audio_recorder_controller.js`)

---

## Anti-Patterns: What NOT to Do

### ❌ Anti-Pattern 1: Fetch + Render in Stimulus

```javascript
// ❌ DON'T DO THIS
async loadProjects() {
  const response = await fetch('/api/projects');
  const data = await response.json();
  this.element.innerHTML = this.renderProjects(data);
}
```

**Use instead**:
```erb
<%= turbo_frame_tag "projects", src: projects_path, loading: "lazy" do %>
  <div class="loading">Loading projects...</div>
<% end %>
```

### ❌ Anti-Pattern 2: Form Submission via Stimulus

```javascript
// ❌ DON'T DO THIS
async submit(event) {
  event.preventDefault();
  const response = await fetch(this.formTarget.action, {
    method: 'POST',
    body: new FormData(this.formTarget)
  });
}
```

**Use instead**: `form_with` + Turbo handles everything.

### ❌ Anti-Pattern 3: Polling for Updates

```javascript
// ❌ DON'T DO THIS
setInterval(() => {
  fetch('/api/notifications').then(response => {});
}, 5000);
```

**Use instead**:
```erb
<%= turbo_stream_from current_user, "notifications" %>
```

---

## Decision Matrix

| Need | Turbo Solution | Stimulus Solution | Use Stimulus? |
|------|---------------|-------------------|---------------|
| Agreement form | `form_with model:` | N/A | ❌ NO |
| Update project list | Turbo Streams | N/A | ❌ NO |
| Load milestones | `turbo_frame_tag src:` | N/A | ❌ NO |
| Real-time messages | `turbo_stream_from` | N/A | ❌ NO |
| Modal show/hide | Turbo Frame + minimal | `showModal()` | ✅ YES (< 50 lines) |
| Time log timer | Turbo Streams | Timer display | ✅ YES (~100 lines) |
| Toast notifications | Turbo Streams | Auto-dismiss | ✅ YES (< 30 lines) |
| AI streaming | Server events | Display handler | ✅ YES (library) |
| Drag & drop sort | N/A + persist via Turbo | Sortable.js | ✅ YES (library) |

---

## Turbo Frame Anti-Patterns (FlukeBase Specific)

Based on fixes applied to this codebase:

### 1. Never use Turbo Stream for lazy-loaded frames

Lazy frames expect `<turbo-frame>` responses, not `<turbo-stream>` responses.

```erb
<%# Wrong %>
<%= turbo_frame_tag "github_section", src: github_path, loading: "lazy" %>
<%# Controller responds with turbo_stream ❌ %>

<%# Correct %>
<%= turbo_frame_tag "github_section", src: github_path, loading: "lazy" %>
<%# Controller responds with render partial wrapped in turbo_frame_tag ✅ %>
```

### 2. Always include frame wrapper in partials

```erb
<%# Partial for lazy frame response %>
<%= turbo_frame_tag "github_section" do %>
  <%# Content here %>
<% end %>
```

### 3. Match frame IDs across create/update paths

```erb
<%# Form uses same frame ID for both success and error %>
<%= turbo_frame_tag dom_id(@agreement, :form) do %>
  <%= form_with model: @agreement do |f| %>
    ...
  <% end %>
<% end %>
```

---

## Testing with Turbo

### System Tests Cover Full Flow

```ruby
test "user can create agreement" do
  visit new_agreement_path
  fill_in "Title", with: "Co-founder Agreement"
  select "Hourly", from: "Payment type"
  fill_in "Rate", with: "50"
  click_button "Create Agreement"

  # Turbo handles submission and redirect
  assert_text "Agreement created!"
  assert_selector "h1", text: "Co-founder Agreement"
end

test "user can track time on milestone" do
  visit milestone_path(@milestone)
  click_button "Start Timer"

  # Turbo Streams update timer display
  assert_selector "[data-controller='time-log']"

  click_button "Stop"
  assert_text "Time logged successfully"
end
```

**No separate JavaScript tests needed!**

---

## Unified Notification System

FlukeBase uses a DRY notification system with Turbo:

### Toasts (for Turbo Stream responses)

```ruby
# In controller
stream_toast_success("Agreement created!")
stream_toast_error("Failed to save")
```

### Flash Messages (for non-Turbo pages)

```erb
<%= render "shared/flash_message", type: :notice, message: "Welcome!" %>
```

### From Turbo Streams

```erb
<%= render "shared/toast_turbo_stream", type: :success, message: "Saved!" %>
```

---

## Summary: The Turbo-First Mindset

1. **Default to Turbo** (90% of features)
   - Forms → `form_with` + Turbo
   - Updates → Turbo Streams
   - Navigation → Turbo Frames/Drive
   - Real-time → `turbo_stream_from`

2. **Consider Stimulus** (9% of features)
   - Only for client-side UI state
   - Only for third-party library wrappers
   - Only to enhance Turbo (not replace)
   - Keep minimal (< 50 lines ideal)

3. **Never use raw JavaScript** (< 1% of features)

### FlukeBase-Specific Notes

- **At 21 controllers** - be cautious adding more
- Time log timer is domain-critical, Stimulus justified
- AI streaming requires Stimulus for progressive display
- Always verify Turbo Frame IDs match across views

---

## Related Documentation

- [Stimulus Usage Guidelines](./stimulus-usage-guidelines.md)
- [Turbo Patterns](./turbo-patterns.md)
- [Ruby Coding Patterns](../../technical_spec/ruby_patterns/README.md)
- [Testing Guide](../testing/testing-guide.md)
- [CLAUDE.md](../../../CLAUDE.md) - Turbo testing notes
