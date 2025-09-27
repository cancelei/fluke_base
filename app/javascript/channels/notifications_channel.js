import consumer from './consumer';

consumer.subscriptions.create('NotificationsChannel', {
  connected() {
    window.FlukeLogger?.websocketEvent('NotificationsChannel', 'connected');
  },

  disconnected() {
    window.FlukeLogger?.websocketEvent('NotificationsChannel', 'disconnected');
  },

  received(data) {
    const notification = document.createElement('div');
    notification.className = `notification ${data.type}`;
    notification.textContent = data.message;
    document.getElementById('notifications').appendChild(notification);

    // Auto-remove notification after 5 seconds
    setTimeout(() => {
      notification.remove();
    }, 5000);
  }
});
