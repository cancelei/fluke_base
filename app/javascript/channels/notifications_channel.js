import consumer from './consumer';
import { globalEmitter } from '../utils/emitter';

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

    // Broadcast to other controllers that may want to react to notifications
    globalEmitter.emit('notification:received', data);

    // Auto-remove notification after 5 seconds
    setTimeout(() => {
      notification.remove();
    }, 5000);
  }
});
