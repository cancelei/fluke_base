class NotificationService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def notify(attributes = {})
    notification = user.notifications.build(
      title: attributes[:title],
      message: attributes[:message],
      url: attributes[:url]
    )

    return false unless notification.save

    broadcast_notification(notification)
    notification
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
