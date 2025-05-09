class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def notify(data)
    ActionCable.server.broadcast(
      "notifications_#{data['user_id']}",
      message: data["message"],
      type: data["type"]
    )
  end
end
