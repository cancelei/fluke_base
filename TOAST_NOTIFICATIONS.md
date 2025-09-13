# Toast Notifications System

This document describes the modern, reusable toast notification system implemented in this Rails application. The system provides user-friendly alerts that auto-dismiss in 5 seconds and don't obstruct user interactions.

## Overview

The toast notification system is built using:
- **Toastr.js** - JavaScript toast library for non-blocking notifications
- **Stimulus controllers** - For Rails 8 integration and modern JavaScript patterns
- **Turbo Streams** - For real-time notification delivery
- **Rails helpers** - For easy backend integration

## Features

✅ **Auto-dismiss**: Notifications automatically disappear after 5 seconds  
✅ **Progress bar**: Visual indicator showing remaining time  
✅ **Close button**: Users can manually dismiss notifications  
✅ **Non-obstructive**: Positioned to not interfere with user interactions  
✅ **Multiple types**: Success, error, warning, info notifications  
✅ **Turbo Stream support**: Real-time notifications via Turbo  
✅ **Backward compatible**: Works with existing Rails flash messages  
✅ **Customizable**: Configurable timeout, positioning, and styling  

## Usage

### Basic Usage in Views

```erb
<!-- Simple toast notification -->
<%= toast(:success, "Operation completed successfully!") %>

<!-- Toast with title and custom timeout -->
<%= toast(:error, "Something went wrong", title: "Error", timeout: 10000) %>

<!-- Different notification types -->
<%= toast(:info, "Information message") %>
<%= toast(:warning, "Warning message") %>
<%= toast(:success, "Success message") %>
<%= toast(:error, "Error message") %>
```

### Controller Usage

#### Flash-style notifications (shown on next request)

```ruby
class UsersController < ApplicationController
  def create
    if @user.save
      toast_success("User created successfully!")
      redirect_to users_path
    else
      toast_error("Failed to create user")
      render :new
    end
  end
end
```

#### Turbo Stream notifications (real-time)

```ruby
class AgreementsController < ApplicationController
  def accept
    if @agreement.accept!
      respond_to do |format|
        format.turbo_stream { stream_toast_success("Agreement accepted!") }
      end
    else
      respond_to do |format|
        format.turbo_stream { stream_toast_error("Failed to accept agreement") }
      end
    end
  end
end
```

### Advanced Usage

#### Custom positioning

```erb
<%= toast(:info, "Message", position: "toast-bottom-right") %>
<%= toast(:warning, "Message", position: "toast-top-center") %>
```

#### Custom timeout and options

```erb
<%= toast(:success, "Message", 
    timeout: 10000,
    close_button: false,
    progress_bar: false
) %>
```

## Available Methods

### Helper Methods (in views)

- `toast(type, message, **options)` - Generate a toast notification
- `flash_to_toasts` - Convert Rails flash messages to toasts
- `render_toast_flash` - Render toast notifications from toast_flash

### Controller Methods

#### Flash-style (next request)
- `toast_flash(type, message, **options)` - Add toast to flash
- `toast_success(message, **options)` - Add success toast to flash
- `toast_error(message, **options)` - Add error toast to flash
- `toast_info(message, **options)` - Add info toast to flash
- `toast_warning(message, **options)` - Add warning toast to flash

#### Turbo Stream (real-time)
- `render_toast_stream(type, message, **options)` - Render toast via Turbo Stream
- `stream_toast_success(message, **options)` - Stream success toast
- `stream_toast_error(message, **options)` - Stream error toast
- `stream_toast_info(message, **options)` - Stream info toast
- `stream_toast_warning(message, **options)` - Stream warning toast

## Configuration Options

### Toast Types
- `:success` / `:notice` - Green success notifications
- `:error` / `:alert` - Red error notifications
- `:warning` - Orange warning notifications
- `:info` - Blue information notifications

### Positioning Options
- `toast-top-right` (default)
- `toast-top-left`
- `toast-top-center`
- `toast-bottom-right`
- `toast-bottom-left`
- `toast-bottom-center`
- `toast-top-full-width`
- `toast-bottom-full-width`

### Timing Options
- `timeout` - Dismiss timeout in milliseconds (default: 5000)
- `close_button` - Show close button (default: true)
- `progress_bar` - Show progress bar (default: true)

## Backward Compatibility

The system automatically converts existing Rails flash messages to toast notifications:

```ruby
# This still works and will show as a toast
flash[:notice] = "Success message"
flash[:alert] = "Error message"
```

Legacy flash message elements with `data-notice` and `data-alert` attributes are also automatically converted.

## File Structure

```
app/
├── javascript/
│   ├── controllers/
│   │   └── toast_controller.js        # Stimulus controller for toasts
│   └── flash_messages.js              # Legacy flash message integration
├── views/
│   └── shared/
│       ├── _toast_notification.html.erb         # Reusable toast partial
│       └── _toast_turbo_stream.turbo_stream.erb  # Turbo Stream template
├── helpers/
│   └── toast_helper.rb                # Toast helper methods
├── controllers/
│   └── application_controller.rb      # Controller toast methods
└── assets/
    └── stylesheets/
        └── application.tailwind.css   # Toast CSS styles
```

## Implementation Details

### Stimulus Controller
The `toast_controller.js` handles:
- Toastr configuration
- Message display
- Type normalization
- Auto-cleanup of DOM elements

### CSS Styling
Toast styles include:
- Proper z-index for overlay positioning
- Fade in/out animations
- Progress bar styling
- Different colors for notification types
- Responsive positioning

### Rails Integration
- Helper methods in `ToastHelper`
- Controller methods in `ApplicationController`
- Automatic flash message conversion
- Turbo Stream support

## Best Practices

1. **Use appropriate types**: Match the notification type to the message content
2. **Keep messages short**: Toasts are meant for brief notifications
3. **Use Turbo Streams for real-time feedback**: For AJAX operations and dynamic updates
4. **Use flash for page redirects**: For operations that redirect to new pages
5. **Consider timeout for important messages**: Use longer timeouts for critical errors
6. **Test positioning**: Ensure toasts don't obstruct important UI elements

## Examples

### Complete Controller Example

```ruby
class ProjectsController < ApplicationController
  def create
    @project = current_user.projects.build(project_params)
    
    respond_to do |format|
      if @project.save
        # Flash-style for redirect
        toast_success("Project '#{@project.name}' created successfully!")
        format.html { redirect_to @project }
        
        # Turbo Stream for dynamic updates
        format.turbo_stream { 
          stream_toast_success("Project created!")
          # Additional Turbo Stream actions...
        }
      else
        # Error handling
        toast_error("Failed to create project")
        format.html { render :new }
        format.turbo_stream { stream_toast_error("Please fix the errors below") }
      end
    end
  end
end
```

### View Integration Example

```erb
<!-- In any view -->
<%= toast(:info, "Welcome to the dashboard!") %>

<!-- In forms for validation feedback -->
<% if @user.errors.any? %>
  <%= toast(:error, "Please fix #{pluralize(@user.errors.count, 'error')} below") %>
<% end %>

<!-- Custom positioning for specific contexts -->
<%= toast(:warning, "Changes not saved", position: "toast-bottom-center") %>
```

## Troubleshooting

### Toasts not appearing
1. Check that `toastr` is properly imported in `config/importmap.rb`
2. Verify the `toast_controller.js` is loaded
3. Ensure CSS styles are included

### Styling issues
1. Check for CSS conflicts with existing styles
2. Verify z-index values for proper layering
3. Test responsive behavior on different screen sizes

### JavaScript errors
1. Check browser console for import/module errors
2. Verify Stimulus controller registration
3. Ensure jQuery is available if required by toastr

## Migration from Old System

The new toast system is designed to be backward compatible. Existing flash messages will automatically be converted to toasts. To fully migrate:

1. Replace manual flash message rendering with `flash_to_toasts`
2. Update controller flash assignments to use toast helper methods
3. Replace any custom JavaScript toast implementations
4. Update Turbo Stream responses to use the new toast methods

## Dependencies

- Rails 8.0+
- Stimulus
- Turbo Streams  
- Toastr.js (automatically managed via importmap)
- Tailwind CSS (for base styling)

---

**Last updated**: September 2025  
**Author**: PA Team  
**Version**: 1.0