import consumer from "./consumer"

consumer.subscriptions.create("NotificationsChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    const notificationsContainer = document.getElementById('notifications_container')
    const notificationIndicator = document.querySelector('.notification-indicator')
    
    if (notificationsContainer) {
      // Prepend the new notification
      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = data.html
      notificationsContainer.insertBefore(tempDiv.firstChild, notificationsContainer.firstChild)
    }

    if (notificationIndicator) {
      // Update the unread count
      notificationIndicator.textContent = data.unread_count
      notificationIndicator.classList.remove('hidden')
    }
  }
}) 