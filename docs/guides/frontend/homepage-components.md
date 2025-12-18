# Homepage Components

This guide documents the homepage component architecture implemented using ViewComponent and DaisyUI.

## Overview

The homepage has been refactored from a 1,748-line monolithic view into a component-based architecture using ViewComponent. All components use DaisyUI semantic classes for theme adaptability.

## Component Architecture

```
app/components/homepage/
├── hero_component.rb
├── hero_component.html.erb
├── stats_component.rb
├── stats_component.html.erb
├── features_component.rb
├── features_component.html.erb
├── how_it_works_component.rb
├── how_it_works_component.html.erb
├── tech_stack_component.rb
├── tech_stack_component.html.erb
├── cta_component.rb
└── cta_component.html.erb
```

## Components

### Homepage::HeroComponent

The main hero section with tagline, value proposition, and CTA buttons.

**Props:**
- `active_agreements_count` (Integer): Number of active agreements to display
- `signed_in` (Boolean): Whether the user is authenticated

**Usage:**
```erb
<%= render Homepage::HeroComponent.new(
  active_agreements_count: @stats[:active_agreements],
  signed_in: user_signed_in?
) %>
```

**Theme Adaptation:**
- Uses `bg-gradient-to-br from-primary to-secondary` for background
- Text uses `text-primary-content` for proper contrast
- Buttons use `btn-accent` and `btn-ghost` variants

### Homepage::StatsComponent

Displays real-time platform statistics from the database.

**Props:**
- `stats` (Hash): Statistics hash with keys `:total_users`, `:total_projects`, `:total_agreements`, `:active_agreements`

**Usage:**
```erb
<%= render Homepage::StatsComponent.new(stats: @stats) %>
```

**Features:**
- Shows empty state with CTA when no data exists
- Uses `Ui::IconComponent` for stat icons
- Integrates with `stats_counter_controller.js` for animations

### Homepage::FeaturesComponent

Highlights core platform features with capability lists.

**Props:** None (features are defined in the component)

**Usage:**
```erb
<%= render Homepage::FeaturesComponent.new %>
```

**Features Highlighted:**
1. Project & Milestone Management
2. Collaboration Agreements

### Homepage::HowItWorksComponent

Four-step process visualization.

**Props:** None (steps are defined in the component)

**Usage:**
```erb
<%= render Homepage::HowItWorksComponent.new %>
```

**Steps:**
1. Create Your Profile
2. Start or Join Projects
3. Set Up Agreements
4. Track Progress

### Homepage::TechStackComponent

Displays technology badges for the platform.

**Props:** None (technologies are defined in the component)

**Usage:**
```erb
<%= render Homepage::TechStackComponent.new %>
```

**Technologies Shown:**
- Ruby on Rails 8
- Hotwire/Turbo
- Stimulus
- PostgreSQL
- Tailwind CSS
- DaisyUI

### Homepage::CtaComponent

Final call-to-action section.

**Props:**
- `signed_in` (Boolean): Whether the user is authenticated

**Usage:**
```erb
<%= render Homepage::CtaComponent.new(signed_in: user_signed_in?) %>
```

## Theme Adaptability

All components use DaisyUI semantic color classes instead of hard-coded colors:

| Instead of | Use |
|------------|-----|
| `bg-indigo-600` | `bg-primary` |
| `bg-purple-500` | `bg-secondary` |
| `text-gray-900` | `text-base-content` |
| `bg-white` | `bg-base-100` |
| `bg-gray-50` | `bg-base-200` |
| `border-gray-200` | `border-base-300` |

### Gradient Strategy

For gradient backgrounds, use theme-adaptive gradients:
```erb
<div class="bg-gradient-to-br from-primary via-primary/90 to-secondary">
```

## Controller

The `HomeController` provides real statistics:

```ruby
class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    @stats = {
      total_users: User.count,
      total_projects: Project.count,
      total_agreements: Agreement.count,
      active_agreements: Agreement.active.count
    }
  end
end
```

## FAQ Section

The FAQ is implemented as a partial (`app/views/home/_faq_section.html.erb`) using DaisyUI collapse components with radio buttons for accordion behavior.

## Testing Themes

To verify theme adaptability, test the homepage with different DaisyUI themes:

1. Light themes: `light`, `nord`, `cupcake`, `emerald`, `corporate`
2. Dark themes: `dark`, `night`, `dracula`, `forest`, `business`

Use the theme switcher in the navbar or add `?theme=dark` to the URL for testing.

## Migration Notes

### Removed Content

The refactor removed:
- Fabricated testimonials
- Fake trust signals (Y Combinator, Techstars logos)
- Misleading claims (AI-powered matching, legal templates)
- Role-based terminology (entrepreneurs, mentors, co-founders)
- Inline CSS animations (~100 lines)
- Inline JavaScript (~45 lines)

### Removed Files

- `app/views/home/_stats.html.erb`
- `app/views/home/_entrepreneur_count.html.erb`
- `app/views/home/_mentor_count.html.erb`
- `app/views/home/_cofounder_count.html.erb`
- `app/views/shared/_count_display.html.erb`

### Removed Routes

- `GET /home/stats` - No longer needed with component-based architecture
