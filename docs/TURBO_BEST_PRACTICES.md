# Turbo Best Practices for FlukeBase

This document outlines best practices and anti-patterns for working with Hotwire Turbo in the FlukeBase Rails application.

## Table of Contents

1. [Turbo Frames vs Turbo Streams](#turbo-frames-vs-turbo-streams)
2. [Lazy-Loaded Frames](#lazy-loaded-frames)
3. [Frame ID Naming Conventions](#frame-id-naming-conventions)
4. [Controller Response Patterns](#controller-response-patterns)
5. [Common Anti-Patterns](#common-anti-patterns)
6. [Debugging Turbo Issues](#debugging-turbo-issues)

---

## Turbo Frames vs Turbo Streams

### Turbo Frames (`<turbo-frame>`)

Use Turbo Frames when:
- Navigating within a specific section of the page
- Lazy-loading content on scroll or visibility
- Scoping link/form behavior to a container

```erb
<%# Parent view - defines the frame %>
<%= turbo_frame_tag "user_profile" do %>
  <%= render "profile", user: @user %>
<% end %>

<%# The partial must also wrap content in the same frame ID %>
<%= turbo_frame_tag "user_profile" do %>
  <!-- content -->
<% end %>
```

### Turbo Streams (`<turbo-stream>`)

Use Turbo Streams when:
- Updating multiple parts of the page at once
- Broadcasting real-time updates via WebSockets
- Responding to form submissions with specific actions (append, prepend, replace, remove, update)

```ruby
# Controller
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.replace("notifications", partial: "notifications"),
      turbo_stream.prepend("messages", partial: "message", locals: { message: @message })
    ]
  end
end
```

---

## Lazy-Loaded Frames

Lazy-loaded frames fetch content when they become visible in the viewport.

### Correct Pattern

**In the parent view:**
```erb
<%= turbo_frame_tag "section_id", src: section_path, loading: "lazy" do %>
  <%= render "loading_placeholder" %>
<% end %>
```

**In the partial being loaded:**
```erb
<%= turbo_frame_tag "section_id" do %>
  <!-- actual content -->
<% end %>
```

**In the controller:**
```ruby
def section_action
  # Render the partial directly - it includes its own turbo_frame_tag wrapper
  render partial: "section_partial", locals: { ... }, layout: false
end
```

### Why This Works

1. Lazy-loaded frames make an **HTML request** (Accept: text/html)
2. They expect a response containing `<turbo-frame id="section_id">`
3. The partial includes the matching frame wrapper
4. Turbo swaps the content automatically

### Anti-Pattern: Using Turbo Stream for Lazy Frames

```ruby
# DON'T do this for lazy-loaded frames
def section_action
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace("section_id", partial: "section")
    end
  end
end
```

This fails because:
- Turbo Stream responses use `<turbo-stream action="replace">` tags
- Lazy-loaded frames expect `<turbo-frame>` tags
- The browser shows: "The response did not contain the expected <turbo-frame id=...>"

---

## Frame ID Naming Conventions

Use consistent, predictable frame IDs based on Rails' `dom_id` helper:

```erb
<%# For model-specific frames %>
<%= turbo_frame_tag dom_id(@agreement) %>           <%# agreement_123 %>
<%= turbo_frame_tag "#{dom_id(@agreement)}_github" %> <%# agreement_123_github %>

<%# For section/area frames %>
<%= turbo_frame_tag "agreement_results" %>
<%= turbo_frame_tag "user_settings" %>
```

### Naming Patterns

| Pattern | Example | Use Case |
|---------|---------|----------|
| `dom_id(model)` | `agreement_123` | Main model content |
| `dom_id(model)_section` | `agreement_123_github` | Lazy-loaded sections |
| `dom_id(parent)_child_form` | `agreement_123_meeting_form` | Nested resource forms |
| `noun_results` | `agreement_results` | Search/filter results |

---

## Controller Response Patterns

### Pattern 1: Lazy-Loaded Sections

```ruby
def github_section
  @data = load_data
  render partial: "github_section", locals: { data: @data }, layout: false
end
```

### Pattern 2: Form Submissions with Turbo Stream

```ruby
def create
  @item = Item.new(item_params)

  respond_to do |format|
    if @item.save
      format.html { redirect_to @item, notice: "Created!" }
      format.turbo_stream # renders create.turbo_stream.erb
    else
      format.html { render :new, status: :unprocessable_content }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "item_form",
          partial: "form",
          locals: { item: @item }
        )
      end
    end
  end
end
```

### Pattern 3: Frame Requests with Conditional Responses

```ruby
def index
  respond_to do |format|
    format.html do
      if turbo_frame_request?
        turbo_frame = request.headers["Turbo-Frame"]
        case turbo_frame
        when "results"
          render partial: "results", layout: false
        else
          render partial: "default_partial", layout: false
        end
      else
        render :index
      end
    end
  end
end
```

---

## Common Anti-Patterns

### 1. Missing Frame Wrapper in Partial

```erb
<%# BAD - No frame wrapper %>
<div class="content">
  <%= @data %>
</div>

<%# GOOD - Include frame wrapper %>
<%= turbo_frame_tag "section_id" do %>
  <div class="content">
    <%= @data %>
  </div>
<% end %>
```

### 2. Mismatched Frame IDs

```ruby
# Controller uses one ID
render turbo_stream: turbo_stream.replace("meeting_form", ...)

# But the form partial uses a different ID
<%= turbo_frame_tag "#{dom_id(@agreement)}_meeting_form" do %>
```

**Solution:** Use consistent ID patterns and test both create and update paths.

### 3. Using Turbo Stream for Frame Requests

```ruby
# BAD - Lazy frame requests expect HTML, not turbo_stream
def lazy_section
  respond_to do |format|
    format.turbo_stream { ... }  # This won't work for lazy frames
    format.html { ... }
  end
end

# GOOD - Just render HTML for lazy-loaded frames
def lazy_section
  render partial: "section", locals: { ... }, layout: false
end
```

### 4. Empty Frame Tags

```erb
<%# BAD - Empty frame with no placeholder %>
<%= turbo_frame_tag "content" %>

<%# GOOD - Include placeholder content %>
<%= turbo_frame_tag "content", src: content_path, loading: "lazy" do %>
  <%= render "loading_skeleton" %>
<% end %>
```

---

## Debugging Turbo Issues

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Response did not contain expected turbo-frame" | Response missing frame wrapper | Add `turbo_frame_tag` to partial |
| Frame content not updating | Mismatched frame IDs | Check IDs match exactly |
| Form submits as full page | Missing Turbo attributes | Check form_with defaults |
| Infinite loop / flash | Frame nesting issues | Use `data-turbo-frame="_top"` |

### Debugging Tools

1. **Browser DevTools Network Tab**
   - Check Accept header (should be `text/html` for frames)
   - Verify Turbo-Frame header is set
   - Inspect response content

2. **Rails Logs**
   - Look for format being used (html vs turbo_stream)
   - Check which action/partial is rendering

3. **Turbo Debug Mode**
   ```javascript
   // In browser console
   Turbo.setProgressBarDelay(0)
   Turbo.session.drive = false // Disable Turbo Drive temporarily
   ```

---

## References

- [Turbo Handbook - Frames](https://turbo.hotwired.dev/handbook/frames)
- [Turbo Reference - Frames](https://turbo.hotwired.dev/reference/frames)
- [Hotwire Discussion Forum](https://discuss.hotwired.dev/)
- [Boring Rails - Lazy Loading](https://boringrails.com/tips/turboframe-lazy-load-skeleton)
