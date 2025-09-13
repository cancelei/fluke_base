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
    render "shared/toast_notification",
           type: type,
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

  private

  # Normalize Rails flash types to toast types
  #
  # @param flash_type [String, Symbol] Rails flash type
  # @return [Symbol] Normalized toast type
  #
  def normalize_flash_type(flash_type)
    case flash_type.to_s
    when "notice"
      :success
    when "alert"
      :error
    when "success"
      :success
    when "error"
      :error
    when "warning"
      :warning
    when "info"
      :info
    else
      :info
    end
  end
end
