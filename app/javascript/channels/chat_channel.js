import consumer from './consumer';

consumer.subscriptions.create({ channel: 'ChatChannel', room: 'general' }, {
  connected() {
    console.log('Connected to chat channel');
  },

  disconnected() {
    console.log('Disconnected from chat channel');
  },

  received(data) {
    const messages = document.getElementById('messages');
    const messageElement = document.createElement('div');
    const userSpan = document.createElement('strong');
    userSpan.textContent = `${data.user}: `;
    messageElement.appendChild(userSpan);
    messageElement.appendChild(document.createTextNode(data.message));
    messages.appendChild(messageElement);
  }
});
