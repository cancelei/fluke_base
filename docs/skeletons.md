# Skeleton Loading System

A comprehensive skeleton loading system built on DaisyUI for improved UX during content loading. This system provides visual feedback to users while data is being fetched or processed.

## Overview

The skeleton system consists of:

1. **`Ui::SkeletonComponent`** - Base skeleton component with 25+ variants
2. **`Skeletons::*` Components** - Higher-level layout components (Grid, Table, List, etc.)
3. **`SkeletonHelper`** - View helper methods for easy usage
4. **`skeleton_loader_controller.js`** - Stimulus controller for smooth transitions
5. **CSS animations** - Shimmer, pulse, and stagger effects

## Quick Start

### Basic Usage

```erb
<%# Simple text skeleton %>
<%= skeleton(:text) %>

<%# Avatar skeleton %>
<%= skeleton(:avatar, size: :lg) %>

<%# Project card skeleton %>
<%= skeleton(:project_card) %>

<%# Multiple skeletons %>
<%= skeleton(:text, count: 3) %>
```

### Grid of Cards

```erb
<%= skeleton_grid(:project_card, count: 6, columns: :projects) %>
```

### Table Skeleton

```erb
<%= skeleton_table(rows: 5, columns: 4) %>
```

### With Smooth Transitions

```erb
<%= skeleton_loader(variant: :project_card, count: 3, layout: :grid) do %>
  <%= render @projects %>
<% end %>
```

## Component Reference

### Ui::SkeletonComponent

The base skeleton component with many variants.

#### Simple Variants

| Variant | Description |
|---------|-------------|
| `:text` | Single line text (h-4 w-full) |
| `:text_sm` | Small text (h-3) |
| `:text_lg` | Large text (h-5) |
| `:title` | Page title (h-8 w-3/4) |
| `:subtitle` | Subtitle (h-6 w-1/2) |
| `:heading` | Large heading (h-10 w-2/3) |

#### Avatar Variants

| Variant | Size |
|---------|------|
| `:avatar_xs` | 24px |
| `:avatar_sm` | 32px |
| `:avatar` / `:avatar_md` | 48px |
| `:avatar_lg` | 64px |
| `:avatar_xl` | 96px |

#### Image Variants

| Variant | Height |
|---------|--------|
| `:image_sm` | 96px |
| `:image` | 128px |
| `:image_lg` | 192px |
| `:image_xl` | 256px |
| `:thumbnail` | 80x80px |

#### UI Element Variants

| Variant | Description |
|---------|-------------|
| `:badge` | Small badge (h-5 w-16) |
| `:badge_lg` | Large badge |
| `:button` | Button shape |
| `:button_sm` | Small button |
| `:button_lg` | Large button |
| `:input` | Form input |
| `:checkbox` | Checkbox |
| `:icon` | Small icon |
| `:icon_lg` | Large icon |

#### Complex Variants (Full Layouts)

| Variant | Description |
|---------|-------------|
| `:paragraph` | 3-line paragraph |
| `:card` | Generic card with title and content |
| `:card_compact` | Compact card |
| `:user_card` | User profile card with avatar, name, skills |
| `:project_card` | Project card matching app design |
| `:project_card_compact` | Compact project card |
| `:agreement_card` | Agreement card |
| `:agreement_row` | Agreement table row |
| `:table_row` | Generic table row |
| `:list_item` | List item with avatar |
| `:list_item_compact` | Compact list item |
| `:stats` | Statistics widget |
| `:stats_single` | Single stat |
| `:form` | Form with fields |
| `:form_field` | Single form field |
| `:conversation_item` | Chat conversation item |
| `:meeting_item` | Meeting list item |
| `:milestone_item` | Milestone list item |
| `:notification` | Notification item |
| `:navbar` | Navigation bar |
| `:page_header` | Page header |
| `:dashboard_widget` | Dashboard widget |

#### Options

```ruby
Ui::SkeletonComponent.new(
  variant: :text,      # Skeleton variant
  count: 1,            # Number of elements
  css_class: nil,      # Additional CSS classes
  width: nil,          # :full, :half, :third, :quarter, :three_quarters, :two_thirds
  animate: :default,   # :default, :pulse, :wave, :none
  gap: :md,            # Gap between multiple elements: :xs, :sm, :md, :lg, :xl
  stagger: false       # Apply staggered animation delays
)
```

### Skeletons::GridComponent

Grid layout for multiple skeleton cards.

```ruby
render Skeletons::GridComponent.new(
  variant: :project_card,  # Skeleton variant for each item
  count: 6,                # Number of items
  columns: :projects,      # Column preset or custom hash
  gap: :md,                # Gap between items
  stagger: true            # Stagger animations
)
```

**Column Presets:**
- `:projects` - { sm: 2, lg: 3, "2xl": 4 }
- `:users` - { sm: 2, lg: 3, xl: 4 }
- `:agreements` - { sm: 1, md: 2, lg: 3 }
- `:compact` - { sm: 2, md: 3, lg: 4, xl: 5 }
- `:single` - { sm: 1 }
- `:default` - { sm: 2, lg: 3 }

### Skeletons::TableComponent

Table skeleton for data tables.

```ruby
render Skeletons::TableComponent.new(
  rows: 5,                                    # Number of rows
  columns: 5,                                 # Number of columns
  column_widths: %w[w-24 w-32 w-20 w-16],    # Column widths
  with_header: true                           # Include header row
)
```

### Skeletons::ListComponent

List skeleton for various list layouts.

```ruby
render Skeletons::ListComponent.new(
  count: 5,              # Number of items
  variant: :default,     # :default, :compact, :large
  with_action: true,     # Show action button
  with_subtitle: true,   # Show subtitle
  divided: true          # Add dividers
)
```

### Skeletons::PageComponent

Full page skeleton for entire page loading states.

```ruby
render Skeletons::PageComponent.new(
  layout: :dashboard,  # :dashboard, :list, :grid, :detail, :form
  items: 5             # Number of items in lists/grids
)
```

## Helper Methods

### skeleton(variant, **options)

Render a single skeleton element.

```erb
<%= skeleton(:text) %>
<%= skeleton(:avatar, width: :half) %>
<%= skeleton(:project_card, animate: :pulse) %>
```

### skeleton_grid(variant, count:, columns:, gap:)

Render a grid of skeleton cards.

```erb
<%= skeleton_grid(:project_card, count: 6, columns: :projects) %>
<%= skeleton_grid(:user_card, count: 4, columns: { sm: 2, lg: 4 }) %>
```

### skeleton_table(rows:, columns:, with_header:)

Render a table skeleton.

```erb
<%= skeleton_table(rows: 10, columns: 5) %>
```

### skeleton_loader(variant:, count:, layout:, &block)

Wrap content with skeleton loading state and smooth transitions.

```erb
<%= skeleton_loader(variant: :project_card, count: 3, layout: :grid) do %>
  <%= render @projects %>
<% end %>
```

### skeleton_page(layout:, items:)

Render a full page skeleton.

```erb
<%= skeleton_page(layout: :dashboard) %>
```

### skeleton_stats(count:, horizontal:)

Render statistics skeleton.

```erb
<%= skeleton_stats(count: 3, horizontal: true) %>
```

### skeleton_form(fields:, with_actions:)

Render form skeleton.

```erb
<%= skeleton_form(fields: 4, with_actions: true) %>
```

### skeleton_widget(title:, items:)

Render dashboard widget skeleton.

```erb
<%= skeleton_widget(title: "Recent Projects", items: 3) %>
```

## Stimulus Controller

The `skeleton_loader_controller` handles smooth transitions between skeleton and content states.

### HTML Attributes

```html
<div data-controller="skeleton-loader"
     data-skeleton-loader-delay-value="300"
     data-skeleton-loader-transition-value="300"
     data-skeleton-loader-auto-show-value="true">
  <div data-skeleton-loader-target="skeleton">
    <!-- Skeleton content -->
  </div>
  <div data-skeleton-loader-target="content" class="hidden">
    <!-- Actual content -->
  </div>
</div>
```

### Values

| Value | Type | Default | Description |
|-------|------|---------|-------------|
| `delay` | Number | 0 | Minimum display time in ms |
| `transition` | Number | 300 | Transition duration in ms |
| `autoShow` | Boolean | true | Auto-show content when loaded |

### Actions

| Action | Description |
|--------|-------------|
| `show` | Show content, hide skeleton |
| `hide` | Hide content, show skeleton |
| `toggle` | Toggle between states |
| `refresh` | Hide then show (for data refresh) |

### Events

| Event | Description |
|-------|-------------|
| `skeleton-loader:loaded` | Fired when content is shown |
| `skeleton-loader:loading` | Fired when skeleton is shown |

## CSS Classes

### Container Classes

- `.skeleton-loader` - Container for skeleton/content
- `.skeleton-loading` - Applied while loading
- `.skeleton-loaded` - Applied when content is shown

### Animation Classes

- `.skeleton` - DaisyUI skeleton base class (built-in animation)
- `.animate-shimmer` - Shimmer wave animation
- `.skeleton-pulse` - Pulse animation
- `.skeleton-stagger` - Parent class for staggered children

## Turbo Integration

### Lazy-loaded Turbo Frames

Use `LazyTurboFrameComponent` for lazy-loaded content with skeleton placeholders:

```erb
<%= render LazyTurboFrameComponent.new(
  frame_id: "projects_list",
  src_path: projects_path,
  skeleton_variant: :project_card,
  skeleton_count: 6,
  skeleton_layout: :grid
) %>
```

### With Spinner Placeholder

```erb
<%= render LazyTurboFrameComponent.new(
  frame_id: "github_section",
  src_path: github_section_path,
  title: "GitHub Integration",
  description: "Loading repository data..."
) %>
```

## Best Practices

1. **Match skeleton to content** - Use skeleton variants that closely match the actual content layout
2. **Use appropriate counts** - Match skeleton count to expected content items
3. **Keep transitions smooth** - Use the Stimulus controller for fade transitions
4. **Consider mobile** - Ensure skeletons work well on all screen sizes
5. **Accessibility** - Skeletons include `role="status"` and `aria-label` for screen readers

## Examples

### Dashboard Page Loading

```erb
<%# Initial page load with skeletons %>
<% if @loading %>
  <%= skeleton_page(layout: :dashboard) %>
<% else %>
  <%= render "dashboard/content" %>
<% end %>
```

### Project Cards Grid

```erb
<%= turbo_frame_tag "projects" do %>
  <% if @projects.loaded? %>
    <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
      <%= render @projects %>
    </div>
  <% else %>
    <%= skeleton_grid(:project_card, count: 6, columns: :projects) %>
  <% end %>
<% end %>
```

### Form with Loading State

```erb
<%= form_with model: @project, data: { controller: "skeleton-loader" } do |f| %>
  <div data-skeleton-loader-target="skeleton" class="hidden">
    <%= skeleton_form(fields: 4) %>
  </div>
  <div data-skeleton-loader-target="content">
    <%= f.text_field :name %>
    <%= f.text_area :description %>
    <%= f.submit "Save" %>
  </div>
<% end %>
```
