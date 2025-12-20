module ToastHelper
  # Generate a toast notification using DaisyUI
  # Delegates to Ui::ToastComponent
  #
  # @param type [Symbol, String] The type of notification (:success, :error, :info, :warning, :notice, :alert)
  # @param message [String] The message to display
  # @param options [Hash] Additional options
  # @option options [String] :title Optional title for the toast
  # @option options [Integer] :timeout Timeout in milliseconds (default: 5000)
  # @option options [Boolean] :close_button Show close button (default: true)
  # @option options [String] :position Toast position (default: "toast-top-right")
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
    # Validate message
    raise ArgumentError, "Message cannot be blank" if message.blank?

    # Delegate to ToastComponent (DaisyUI-based)
    render(Ui::ToastComponent.new(
      type:,
      message:,
      title: options[:title],
      timeout: options[:timeout] || 5000,
      close_button: options.fetch(:close_button, true),
      position: options[:position] || "toast-top-right"
    ))
  end

  # Convert Rails flash messages to toast notifications
  # Place this in your layout after flash message processing
  # Uses Ui::ToastComponent for rendering
  #
  # @return [String] HTML for all flash message toasts
  #
  # @example In layout
  #   <%= flash_to_toasts %>
  #
  def flash_to_toasts
    return "".html_safe if flash.empty?

    toasts = flash.map do |flash_type, message|
      next if message.blank?

      render(Ui::ToastComponent.new(
        type: flash_type,
        message:
      ))
    end.compact

    safe_join(toasts)
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
  def toast_flash(type, message, **)
    flash[:toast] ||= []
    flash[:toast] <<({ type:, message:, ** })
  end

  # Render toast notifications from toast_flash
  # This is automatically included in flash_to_toasts
  #
  # @return [String] HTML for toast flash notifications
  #
  def render_toast_flash
    return "".html_safe unless flash[:toast]

    toast_notifications = flash[:toast].map do |toast_data|
      type = toast_data[:type]
      message = toast_data[:message]
      options = toast_data.except(:type, :message)

      toast(type, message, **options)
    end

    flash.delete(:toast)
    safe_join(toast_notifications)
  end
end
