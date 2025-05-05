import consumer from "./consumer"

consumer.subscriptions.create("NotificationsChannel", {
  connected() {
    console.log("Connected to notifications channel")
  },

  disconnected() {
    console.log("Disconnected from notifications channel")
  },

  received(data) {
    const notification = document.createElement('div')
    notification.className = `notification ${data.type}`
    notification.textContent = data.message
    document.getElementById('notifications').appendChild(notification)
    
    // Auto-remove notification after 5 seconds
    setTimeout(() => {
      notification.remove()
    }, 5000)
  }
}) 