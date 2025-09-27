# Hotwire Turbo Patterns in FlukeBase

This document outlines the comprehensive Hotwire Turbo implementation patterns used throughout the FlukeBase codebase, providing real examples for future AI agents to reference.

> **🧪 Testing Guide**: For comprehensive testing patterns that complement these Turbo implementation patterns, see [`../test_spec/turbo_testing/README.md`](../test_spec/turbo_testing/README.md)

## Table of Contents

1. [Turbo Frames](#turbo-frames)
2. [Turbo Streams](#turbo-streams)
3. [Lazy Loading Patterns](#lazy-loading-patterns)
4. [Form Integration](#form-integration)
5. [Real-time Updates](#real-time-updates)
6. [Error Handling](#error-handling)
7. [Performance Optimizations](#performance-optimizations)

## Turbo Frames

### Basic Turbo Frame Structure
Turbo Frames provide page sections that can be independently updated without full page reloads.

**File**: `app/views/agreements/_agreement_results.html.erb:2`
```erb
<%= turbo_frame_tag "agreement_results" do %>
  <!-- Content that can be independently updated -->
  <div class="bg-white shadow sm:rounded-lg mb-8">
    <!-- Your content here -->
  </div>
<% end %>
```

### Nested Turbo Frames for Granular Updates
**File**: `app/views/agreements/_agreement_results.html.erb:23-25`
```erb
<%= turbo_frame_tag "agreement_results" do %>
  <!-- Outer frame -->
  <% if @my_agreements.any? %>
    <%= turbo_frame_tag "agreements_my" do %>
      <%= render "my_agreements_section", my_agreements: @my_agreements, query: @query %>
    <% end %>
  <% end %>

  <!-- Another nested frame -->
  <%= turbo_frame_tag "agreements_other" do %>
    <%= render "other_agreements_section", other_party_agreements: @other_party_agreements, query: @query %>
  <% end %>
<% end %>
```

### Show Page Turbo Frame Structure
**File**: `app/views/agreements/show.html.erb:4-13`
```erb
<%= turbo_frame_tag dom_id(@agreement) do %>
  <div class="bg-white shadow overflow-hidden sm:rounded-lg">
    <%= render "agreement_show_status" %>
    <%= render "agreement_details",
        agreement: @agreement,
        project: @project,
        current_user: current_user,
        can_view_full_details: @can_view_full_details %>
  </div>
<% end %>
```

## Turbo Streams

### Multiple Stream Updates in Controller
**File**: `app/controllers/agreements_controller.rb:37-44`
```ruby
format.turbo_stream do
  # Handle filter form submissions with Turbo Stream
  render turbo_stream: [
    turbo_stream.update("agreement_filters", partial: "filters"),
    turbo_stream.update("agreement_results", partial: "agreement_results")
  ]
end
```

### Context-Aware Turbo Stream Responses
**File**: `app/controllers/agreements_controller.rb:66-82`
```ruby
format.turbo_stream do
  if turbo_frame_request?
    render turbo_stream: turbo_stream.replace(
      dom_id(@agreement),
      partial: "agreement_show_content",
      locals: { agreement: @agreement, project: @project, can_view_full_details: @can_view_full_details }
    )
  else
    # For non-frame turbo stream requests, just replace the main content
    render turbo_stream: turbo_stream.replace(
      dom_id(@agreement),
      partial: "agreement_show_content",
      locals: { agreement: @agreement, project: @project, can_view_full_details: @can_view_full_details }
    )
  end
end
```

### Complex Turbo Stream Actions
**File**: `app/views/agreements/accept.turbo_stream.erb:1-48`
```erb
<!-- Update show page status section if present -->
<%= turbo_stream.replace "#{dom_id(@agreement)}_show_status" do %>
  <%= render "agreement_show_status" %>
<% end %>

<!-- Context-aware updates -->
<% if params[:context] == "index" %>
  <%= turbo_stream.replace dom_id(@agreement), partial: "agreement_index_row", locals: { agreement: @agreement } %>
<% else %>
  <%= turbo_stream.replace dom_id(@agreement), partial: "agreement_show_content", locals: { agreement: @agreement, project: @agreement.project, can_view_full_details: @agreement.can_view_full_project_details?(current_user) } %>
<% end %>

<!-- Update standalone status badge if present -->
<%= turbo_stream.replace "#{dom_id(@agreement)}_status" do %>
  <%= render "agreement_status", agreement: @agreement %>
<% end %>

<!-- Flash message with auto-dismiss -->
<%= turbo_stream.prepend "flash_messages" do %>
  <div class="rounded-md bg-green-50 p-4 mb-4">
    <div class="flex">
      <div class="flex-shrink-0">
        <!-- Success icon -->
      </div>
      <div class="ml-3">
        <p class="text-sm font-medium text-green-800">
          <%= flash.now[:notice] %>
        </p>
      </div>
      <div class="ml-auto pl-3">
        <button type="button" onclick="this.parentElement.parentElement.parentElement.parentElement.remove()">
          <!-- Close button -->
        </button>
      </div>
    </div>
  </div>
<% end %>
```

## Lazy Loading Patterns

### Lazy Turbo Frames with Loading States
**File**: `app/views/agreements/show.html.erb:20-25`
```erb
<!-- GitHub Integration Section -->
<%= render "shared/lazy_turbo_frame",
    frame_id: "#{dom_id(@agreement)}_github",
    src_path: github_section_agreement_path(@agreement),
    title: "GitHub Integration",
    description: "Repository access and development activity" %>
```

**File**: `app/views/shared/_lazy_turbo_frame.html.erb:1-3`
```erb
<%= turbo_frame_tag frame_id, src: src_path, loading: "lazy" do %>
  <%= render "shared/lazy_loading_placeholder", title: title, description: description %>
<% end %>
```

### Lazy Loading Controller Pattern
**File**: `app/controllers/agreements_controller.rb:383-411`
```ruby
def meetings_section
  begin
    @project = @agreement.project
    # Optimized query with proper includes to avoid N+1
    @meetings = if @agreement.active? || @agreement.completed?
      @agreement.meetings
                .includes(:agreement, :user) # Include user for meeting creator info
                .order(start_time: :asc)
    else
      []
    end

    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.replace(
          "#{dom_id(@agreement)}_meetings", 
          partial: "meetings_section", 
          locals: { agreement: @agreement, meetings: @meetings, project: @project }
        ) 
      }
      format.html { 
        render partial: "meetings_section", 
        locals: { agreement: @agreement, meetings: @meetings, project: @project } 
      }
    end
  rescue => e
    Rails.logger.error "Error loading meetings section: #{e.message}"
    respond_to do |format|
      format.turbo_stream { 
        render turbo_stream: turbo_stream.replace(
          "#{dom_id(@agreement)}_meetings", 
          partial: "lazy_loading_error", 
          locals: { title: "Meetings", description: "Scheduled meetings and collaboration sessions" }
        ) 
      }
      format.html do
        html = view_context.turbo_frame_tag("#{dom_id(@agreement)}_meetings") do
          view_context.render(partial: "lazy_loading_error", locals: { title: "Meetings", description: "Scheduled meetings and collaboration sessions" })
        end
        render html: html
      end
    end
  end
end
```

## Form Integration

### Auto-submitting Filters with Turbo
**File**: `app/views/agreements/_filters.html.erb:23-33`
```erb
<%= form_with url: agreements_path, method: :get, local: false,
    class: "mt-6 grid grid-cols-1 gap-y-6 gap-x-4 sm:grid-cols-6" do |form| %>

  <!-- Status Filter with auto-submit -->
  <div class="sm:col-span-2">
    <%= form.label :status, "Status", class: "block text-sm font-medium text-gray-700" %>
    <%= form.select :status,
        options_for_select(AgreementsQuery.status_options, params[:status]),
        {},
        { class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
          onchange: "this.form.requestSubmit();" } %>
  </div>
<% end %>
```

### Search with Debounced Auto-submit
**File**: `app/views/agreements/_filters.html.erb:47-54`
```erb
<!-- Search Filter with debounced submit -->
<div class="sm:col-span-2">
  <%= form.label :search, "Search", class: "block text-sm font-medium text-gray-700" %>
  <%= form.text_field :search,
      placeholder: "Project name or participant...",
      value: params[:search],
      class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
      oninput: "clearTimeout(this.searchTimeout); this.searchTimeout = setTimeout(() => this.form.requestSubmit(), 500);" %>
</div>
```

### Controller Response to Form Submissions
**File**: `app/controllers/agreements_controller.rb:16-45`
```ruby
def index
  @query = AgreementsQuery.new(current_user, filter_params)
  @my_agreements = @query.my_agreements
  @other_party_agreements = @query.other_party_agreements

  respond_to do |format|
    format.html do
      if turbo_frame_request?
        turbo_frame = request.headers["Turbo-Frame"]
        case turbo_frame
        when "agreement_results"
          # For filter requests, return the entire results area
          render partial: "agreement_results", layout: false
        when "agreements_my"
          # For pagination requests on my agreements table
          render partial: "my_agreements_section", layout: false, locals: { my_agreements: @my_agreements, query: @query }
        when "agreements_other"
          # For pagination requests on other party agreements table
          render partial: "other_agreements_section", layout: false, locals: { other_party_agreements: @other_party_agreements, query: @query }
        else
          render partial: "agreement_results", layout: false
        end
      else
        render :index
      end
    end
    format.turbo_stream do
      # Handle filter form submissions with Turbo Stream
      render turbo_stream: [
        turbo_stream.update("agreement_filters", partial: "filters"),
        turbo_stream.update("agreement_results", partial: "agreement_results")
      ]
    end
  end
end
```

## Real-time Updates

### Action-Based Turbo Stream Updates
**File**: `app/controllers/agreements_controller.rb:244-280`
```ruby
def accept
  if @agreement.accept!
    notify_and_message_other_party(:accept)

    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Agreement was successfully accepted."
        render :accept  # Renders accept.turbo_stream.erb
      end
      format.html do
        redirect_to @agreement, notice: "Agreement was successfully accepted."
      end
    end
  else
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = "Unable to accept agreement."
        if params[:context] == "index"
          render turbo_stream: turbo_stream.prepend(
            "flash_messages",
            partial: "shared/flash_message",
            locals: { type: "alert", message: flash.now[:alert] }
          )
        else
          render turbo_stream: turbo_stream.prepend(
            "flash_messages",
            partial: "shared/flash_message",
            locals: { type: "alert", message: flash.now[:alert] }
          )
        end
      end
      format.html do
        redirect_to @agreement, alert: "Unable to accept agreement."
      end
    end
  end
end
```

## Error Handling

### Graceful Degradation with Error States
**File**: `app/controllers/agreements_controller.rb:399-410`
```ruby
rescue => e
  Rails.logger.error "Error loading meetings section: #{e.message}"
  respond_to do |format|
    format.turbo_stream { 
      render turbo_stream: turbo_stream.replace(
        "#{dom_id(@agreement)}_meetings", 
        partial: "lazy_loading_error", 
        locals: { title: "Meetings", description: "Scheduled meetings and collaboration sessions" }
      ) 
    }
    format.html do
      html = view_context.turbo_frame_tag("#{dom_id(@agreement)}_meetings") do
        view_context.render(partial: "lazy_loading_error", locals: { title: "Meetings", description: "Scheduled meetings and collaboration sessions" })
      end
      render html: html
    end
  end
```

### Turbo Frame Request Detection
**File**: `app/controllers/agreements_controller.rb:18-19`
```ruby
if turbo_frame_request?
  turbo_frame = request.headers["Turbo-Frame"]
  # Handle different frame contexts
end
```

## Performance Optimizations

### Optimized Database Queries for Turbo Frames
**File**: `app/controllers/agreements_controller.rb:650-655`
```ruby
def set_agreement
  @agreement = Agreement.includes(
    project: :user,
    agreement_participants: :user,
    meetings: []
  ).find(params[:id])
end
```

### Pagination within Turbo Frames
**File**: `app/controllers/agreements_controller.rb:25-29`
```ruby
when "agreements_my"
  # For pagination requests on my agreements table
  render partial: "my_agreements_section", layout: false, locals: { my_agreements: @my_agreements, query: @query }
when "agreements_other"
  # For pagination requests on other party agreements table  
  render partial: "other_agreements_section", layout: false, locals: { other_party_agreements: @other_party_agreements, query: @query }
```

## Best Practices Summary

1. **Frame Hierarchy**: Use nested frames for granular updates
2. **Context Awareness**: Different behaviors for index vs show pages
3. **Lazy Loading**: Load heavy content only when needed
4. **Error Handling**: Always provide fallback UI for failed requests
5. **Performance**: Use includes() to avoid N+1 queries in frame updates
6. **Form Integration**: Auto-submit with debouncing for better UX
7. **Flash Messages**: Use prepend/append for non-intrusive notifications
8. **DOM IDs**: Use `dom_id()` helper for consistent element targeting
9. **Loading States**: Provide immediate feedback with placeholders
10. **Progressive Enhancement**: Always provide HTML fallbacks

## Common Patterns

### 1. Filter + Results Pattern
```erb
<!-- Filter controls -->
<%= turbo_frame_tag "filters" %>
  <%= form_with local: false, onchange: "this.form.requestSubmit();" %>
<% end %>

<!-- Results area -->
<%= turbo_frame_tag "results" %>
  <!-- Content updated by form submission -->
<% end %>
```

### 2. Lazy Section Loading Pattern
```erb
<%= turbo_frame_tag "section_#{id}", src: lazy_load_path, loading: "lazy" do %>
  <%= render "loading_placeholder" %>
<% end %>
```

### 3. Action with Multiple Updates Pattern
```erb
<!-- In turbo_stream.erb file -->
<%= turbo_stream.replace "main_content" do %>
  <%= render "updated_content" %>
<% end %>

<%= turbo_stream.update "sidebar" do %>
  <%= render "sidebar_stats" %>  
<% end %>

<%= turbo_stream.prepend "notifications" do %>
  <%= render "success_message" %>
<% end %>
```