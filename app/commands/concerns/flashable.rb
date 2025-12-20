# frozen_string_literal: true

# Provides flash message helpers for TurboBoost commands
# DRYs up the repeated turbo_stream.update("flash_messages", ...) pattern
# found throughout controllers
module Flashable
  extend ActiveSupport::Concern

  FLASH_CONTAINER_ID = "flash_messages"

  # Display a success/notice flash message
  # @param message [String] The message to display
  def flash_notice(message)
    turbo_streams << turbo_stream.update(
      FLASH_CONTAINER_ID,
      partial: "shared/flash_messages",
      locals: { notice: message, alert: nil }
    )
  end

  # Display an error/alert flash message
  # @param message [String] The message to display
  def flash_error(message)
    turbo_streams << turbo_stream.update(
      FLASH_CONTAINER_ID,
      partial: "shared/flash_messages",
      locals: { notice: nil, alert: message }
    )
  end

  # Display a toast notification using the ToastComponent
  # @param type [Symbol] Toast type (:success, :error, :info, :warning)
  # @param message [String] The message to display
  # @param options [Hash] Additional options (title:, timeout:, etc.)
  def flash_toast(type, message, **options)
    component = Ui::ToastComponent.new(
      type:,
      message:,
      title: options[:title],
      timeout: options[:timeout] || 5000,
      close_button: options.fetch(:close_button, true),
      progress_bar: options.fetch(:progress_bar, true),
      position: options[:position] || "toast-top-right"
    )

    turbo_streams << turbo_stream.append(
      "body",
      component.render_in(controller.view_context)
    )
  end

  # Convenience methods for specific toast types
  def toast_success(message, **)
    flash_toast(:success, message, **)
  end

  def toast_error(message, **)
    flash_toast(:error, message, **)
  end

  def toast_info(message, **)
    flash_toast(:info, message, **)
  end

  def toast_warning(message, **)
    flash_toast(:warning, message, **)
  end
end
