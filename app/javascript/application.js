// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import '@hotwired/turbo-rails';
import '@turbo-boost/streams';
import '@turbo-boost/commands';
import 'controllers';
import 'utils/logger';

// Enable TurboBoost Commands debug logging in development
if (
  window.location.hostname === 'localhost' ||
  window.location.hostname === '127.0.0.1'
) {
  TurboBoost.Commands.logger.level = 'debug';
}
