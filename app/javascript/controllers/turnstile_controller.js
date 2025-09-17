import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['widget'];
  static values = {
    sitekey: String,
    size: { type: String, default: 'invisible' }
  };

  connect() {
    // Ensure Turnstile API is loaded before initializing
    if (window.turnstile) {
      this.initializeTurnstile();
    } else {
      // Wait for Turnstile script to load
      this.waitForTurnstile();
    }
  }

  waitForTurnstile() {
    const checkTurnstile = () => {
      if (window.turnstile) {
        this.initializeTurnstile();
      } else {
        setTimeout(checkTurnstile, 100);
      }
    };
    checkTurnstile();
  }

  initializeTurnstile() {
    if (this.hasWidgetTarget && this.sitekeyValue) {
      // Render the Turnstile widget
      window.turnstile.render(this.widgetTarget, {
        sitekey: this.sitekeyValue,
        size: this.sizeValue,
        callback: this.onSuccess.bind(this),
        'expired-callback': this.onExpired.bind(this),
        'error-callback': this.onError.bind(this)
      });
    }
  }

  onSuccess(token) {
    const form = this.element.closest('form');
    if (form) {
      // Remove existing token field
      const existingField = form.querySelector('input[name="cf-turnstile-response"]');
      if (existingField) {
        existingField.remove();
      }

      // Add new token field
      const tokenField = document.createElement('input');
      tokenField.type = 'hidden';
      tokenField.name = 'cf-turnstile-response';
      tokenField.value = token;
      form.appendChild(tokenField);

      // Dispatch custom event for additional handling if needed
      this.dispatch('success', { detail: { token } });
    }
  }

  onExpired() {
    console.log('Turnstile token expired');
    // Remove token field on expiration
    const form = this.element.closest('form');
    if (form) {
      const existingField = form.querySelector('input[name="cf-turnstile-response"]');
      if (existingField) {
        existingField.remove();
      }
    }
    this.dispatch('expired');
  }

  onError(error) {
    console.error('Turnstile error:', error);
    this.dispatch('error', { detail: { error } });
  }

  // Method to reset the widget if needed
  reset() {
    if (window.turnstile && this.widgetId) {
      window.turnstile.reset(this.widgetId);
    }
  }
}
