module ToastHelper
  # Generate a toast notification
  #
  # @param type [Symbol, String] The type of notification (:success, :error, :info, :warning, :notice, :alert)
  # @param message [String] The message to display
  # @param options [Hash] Additional options
  # @option options [String] :title Optional title for the toast
  # @option options [Integer] :timeout Timeout in milliseconds (default: 5000)
  # @option options [Boolean] :close_button Show close button (default: true)
  # @option options [Boolean] :progress_bar Show progress bar (default: true)
  # @option options [String] :position Toast position class (default: "toast-top-right")
  #
  # @return [String] HTML for the toast notification
  #
  # @example Basic usage
  #   <%= toast(:success, "Operation completed successfully!") %>
  #
  # @example With title and custom timeout
  #   <%= toast(:error, "Something went wrong", title: "Error", timeout: 10000) %>
  #
  def toast(type, message, **options)
    # Validate toast type
    valid_types = %w[success error info warning notice alert]
    normalized_type = normalize_toast_type(type)

    # Validate message
    raise ArgumentError, "Message cannot be blank" if message.blank?

    render "shared/toast_notification",
           type: normalized_type,
           message: message,
           **options
  end

  # Convert Rails flash messages to toast notifications
  # Place this in your layout after flash message processing
  #
  # @return [String] HTML for all flash message toasts
  #
  # @example In layout
  #   <%= flash_to_toasts %>
  #
  def flash_to_toasts
    return "" if flash.empty?

    flash.map do |flash_type, message|
      next if message.blank?

      toast_type = normalize_flash_type(flash_type)
      toast(toast_type, message)
    end.compact.join.html_safe
  end

  # Add a toast notification to be shown on the next request
  # This works like Rails flash messages but specifically for toasts
  #
  # @param type [Symbol, String] The type of notification
  # @param message [String] The message to display
  # @param options [Hash] Additional toast options
  #
  # @example In controller
  #   toast_flash(:success, "User created successfully!")
  #   redirect_to users_path
  #
  def toast_flash(type, message, **options)
    flash[:toast] ||= []
    flash[:toast] << { type: type, message: message, **options }
  end

  # Render toast notifications from toast_flash
  # This is automatically included in flash_to_toasts
  #
  # @return [String] HTML for toast flash notifications
  #
  def render_toast_flash
    return "" unless flash[:toast]

    toast_notifications = flash[:toast].map do |toast_data|
      type = toast_data[:type]
      message = toast_data[:message]
      options = toast_data.except(:type, :message)

      toast(type, message, **options)
    end

    flash.delete(:toast)
    toast_notifications.join.html_safe
  end

  # Create a toast with action buttons
  #
  # @param type [Symbol, String] The type of notification
  # @param message [String] The message to display
  # @param actions [Array] Array of action hashes with :label, :url, and :method
  # @param options [Hash] Additional toast options
  #
  # @example With action buttons
  #   <%= toast_with_actions(:success, "User created!",
  #     actions: [
  #       { label: "View", url: user_path(@user) },
  #       { label: "Edit", url: edit_user_path(@user) }
  #     ]
  #   ) %>
  #
  def toast_with_actions(type, message, actions: [], **options)
    options[:actions] = actions
    toast(type, message, **options)
  end

  # Create a persistent toast that doesn't auto-dismiss
  #
  # @param type [Symbol, String] The type of notification
  # @param message [String] The message to display
  # @param options [Hash] Additional toast options
  #
  def persistent_toast(type, message, **options)
    options[:timeout] = 0 # Never auto-dismiss
    options[:close_button] = true # Always show close button
    toast(type, message, **options)
  end

  # Create a toast with custom styling
  #
  # @param type [Symbol, String] The type of notification
  # @param message [String] The message to display
  # @param custom_class [String] Custom CSS class
  # @param options [Hash] Additional toast options
  #
  def custom_toast(type, message, custom_class: nil, **options)
    options[:custom_class] = custom_class
    toast(type, message, **options)
  end

  private

  # Normalize toast types to ensure consistency
  #
  # @param type [String, Symbol] Toast type
  # @return [Symbol] Normalized toast type
  #
  def normalize_toast_type(type)
    case type.to_s.downcase
    when "notice", "success"
      :success
    when "alert", "error"
      :error
    when "warning"
      :warning
    when "info"
      :info
    else
      :info
    end
  end

  # Normalize Rails flash types to toast types
  #
  # @param flash_type [String, Symbol] Rails flash type
  # @return [Symbol] Normalized toast type
  #
  def normalize_flash_type(flash_type)
    normalize_toast_type(flash_type)
  end
end
