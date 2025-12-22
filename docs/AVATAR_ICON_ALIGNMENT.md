# Avatar and Icon Alignment Best Practices

This document outlines the correct patterns for implementing avatars and icons in the FlukeBase application, along with common anti-patterns to avoid.

## The Problem

Avatar containers that only specify width without height and centering classes cause:
- Initials appearing cut off or shifted
- Text showing incorrect characters (e.g., "3M" instead of "BM")
- Inconsistent visual appearance across different browsers
- Icons and text not properly centered within circular containers

## Correct Pattern for Avatar Placeholders

### Required Classes for Avatar Containers

Every avatar placeholder container MUST include:

1. **Both width AND height**: `w-12 h-12` (or any matching pair like `w-8 h-8`, `w-10 h-10`, etc.)
2. **Flexbox centering**: `flex items-center justify-center`
3. **Round shape**: `rounded-full`
4. **Background and text colors**: `bg-primary text-primary-content` or similar

### Correct Example

```erb
<div class="avatar placeholder">
  <div class="bg-primary text-primary-content rounded-full w-12 h-12 flex items-center justify-center">
    <span class="text-sm font-medium"><%= user.initials %></span>
  </div>
</div>
```

### Correct Example with Image Fallback

```erb
<div class="avatar placeholder">
  <div class="bg-neutral text-neutral-content rounded-full w-10 h-10 flex items-center justify-center">
    <% if user.avatar.attached? %>
      <%= image_tag user.avatar, class: "rounded-full w-full h-full object-cover" %>
    <% else %>
      <span class="text-sm font-medium"><%= user.initials %></span>
    <% end %>
  </div>
</div>
```

### Correct Example for SVG Icons

```erb
<div class="avatar placeholder">
  <div class="bg-base-200 text-base-content rounded-full w-16 h-16 flex items-center justify-center">
    <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <!-- SVG path -->
    </svg>
  </div>
</div>
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Missing Height Class

```erb
<!-- WRONG: Missing h-12 -->
<div class="bg-primary rounded-full w-12">
  <span><%= user.initials %></span>
</div>
```

**Why it fails**: Without explicit height, the container collapses or expands unpredictably based on content, causing text to be cut off or misaligned.

### Anti-Pattern 2: Missing Centering Classes

```erb
<!-- WRONG: Missing flex items-center justify-center -->
<div class="bg-primary rounded-full w-12 h-12">
  <span><%= user.initials %></span>
</div>
```

**Why it fails**: Text will align to the top-left corner by default, appearing offset from the center of the circle.

### Anti-Pattern 3: Using `h-full w-full` on Text Elements

```erb
<!-- WRONG: Inappropriate sizing for text -->
<div class="rounded-full w-12 h-12">
  <span class="h-full w-full"><%= user.initials %></span>
</div>
```

**Why it fails**: Text elements should not fill the container - they need fixed sizes and the container should center them.

### Anti-Pattern 4: SVG with h-full w-full Without Container Centering

```erb
<!-- WRONG: SVG sizing without proper container -->
<div class="rounded-full w-10 h-10">
  <svg class="h-full w-full p-2"><!-- content --></svg>
</div>
```

**Why it fails**: While this may sometimes work, it's fragile. Better to use explicit icon sizes with container centering.

## Image Avatar Best Practices

When displaying user-uploaded images:

```erb
<%= image_tag user.avatar, class: "rounded-full w-full h-full object-cover" %>
```

Key classes for images:
- `rounded-full`: Maintains circular shape
- `w-full h-full`: Fills the container
- `object-cover`: Maintains aspect ratio while filling container (crops if needed)

## Size Reference Chart

| Size Name | Container Classes | Icon Size | Text Size |
|-----------|-------------------|-----------|-----------|
| xs        | `w-6 h-6`         | `w-3 h-3` | `text-xs` |
| sm        | `w-8 h-8`         | `w-4 h-4` | `text-xs` |
| md        | `w-10 h-10`       | `w-5 h-5` | `text-sm` |
| default   | `w-12 h-12`       | `w-6 h-6` | `text-sm` |
| lg        | `w-16 h-16`       | `w-8 h-8` | `text-base` |
| xl        | `w-20 h-20`       | `w-10 h-10` | `text-lg` |
| xxl       | `w-24 h-24`       | `w-12 h-12` | `text-xl` |

## Using the AvatarComponent

For consistent avatar rendering, prefer using the `Ui::AvatarComponent`:

```erb
<%= render Ui::AvatarComponent.new(
  user: @user,
  size: :md,
  placeholder: :initials,
  ring: false
) %>
```

The component handles all the correct classes automatically.

## Checklist for Avatar Implementation

- [ ] Container has both width AND height classes (`w-* h-*`)
- [ ] Container has `flex items-center justify-center` for text/icon centering
- [ ] Container has `rounded-full` for circular shape
- [ ] Container has appropriate background color class
- [ ] Text has appropriate size class (`text-xs`, `text-sm`, etc.)
- [ ] Images use `w-full h-full object-cover rounded-full`
- [ ] Icons use explicit size classes (not `h-full w-full`)

## Files Fixed in This Update

The following files were updated to follow these best practices:

1. `app/views/conversations/_conversation_item.html.erb` - Added `h-12` and centering classes
2. `app/views/conversations/_conversation_content.html.erb` - Fixed multiple avatar instances
3. `app/views/conversations/_conversation_list.html.erb` - Added height and centering
4. `app/views/github_logs/_loading_state.html.erb` - Added height and centering
5. `app/views/dashboard/_recent_activity.html.erb` - Added centering classes
6. `app/views/projects/show.html.erb` - Added centering and fixed icon sizing
7. `app/views/profile/edit.html.erb` - Added height and proper image classes
