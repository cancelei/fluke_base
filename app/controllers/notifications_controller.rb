class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:show, :mark_as_read]

  def index
    @pagy, @notifications = pagy(current_user.notifications.order(created_at: :desc), items: 20)
  end

  def show
    # Mark as read when viewing
    @notification.mark_as_read! unless @notification.read?

    # Redirect to the notification URL
    redirect_to @notification.url
  end

  def mark_as_read
    @notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path, notice: "Notification marked as read.") }
      format.json { head :no_content }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("notification_#{@notification.id}") }
    end
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_back(fallback_location: notifications_path, notice: "All notifications marked as read.") }
      format.json { head :no_content }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("notifications_container", partial: "notifications/notifications", locals: { notifications: current_user.notifications.recent }) }
    end
  end

  private

  def set_notification = @notification = current_user.notifications.find(params[:id])
end
