# frozen_string_literal: true

# Service for creating and broadcasting user notifications
class NotificationService < ApplicationService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  # @param attributes [Hash] notification attributes (title, message, url)
  # @return [Dry::Monads::Result] Success(notification) or Failure(error)
  def notify(attributes = {})
    notification = user.notifications.build(
      title: attributes[:title],
      message: attributes[:message],
      url: attributes[:url]
    )

    if notification.save
      broadcast_notification(notification)
      Success(notification)
    else
      failure_result(:save_failed, notification.errors.full_messages.to_sentence, errors: notification.errors)
    end
  end

  private

  def broadcast_notification(notification)
    ActionCable.server.broadcast(
      "notifications_#{user.id}",
      {
        html: render_notification(notification),
        unread_count: user.notifications.unread.count
      }
    )
  end

  def render_notification(notification)
    ApplicationController.renderer.render(
      partial: "notifications/notification",
      locals: { notification: notification }
    )
  end
end
