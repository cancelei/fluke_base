import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="turnstile"
export default class extends Controller {
  static targets = ['widget', 'submitButton'];
  static values = {
    siteKey: String,
    mode: String
  };

  connect() {
    console.log('Turnstile controller connected');
    this.loadTurnstileScript();
  }

  loadTurnstileScript() {
    if (window.turnstile) {
      this.initializeWidget();
      return;
    }

    const script = document.createElement('script');
    script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js';
    script.async = true;
    script.defer = true;
    script.onload = () => this.initializeWidget();
    document.head.appendChild(script);
  }

  initializeWidget() {
    if (this.modeValue === 'development') {
      this.handleDevelopmentMode();
      return;
    }

    if (!this.siteKeyValue) {
      console.warn('Turnstile site key not provided');
      return;
    }

    try {
      this.widgetId = window.turnstile.render(this.widgetTarget, {
        sitekey: this.siteKeyValue,
        callback: (token) => this.onSuccess(token),
        'expired-callback': () => this.onExpired(),
        'error-callback': (error) => this.onError(error),
        size: 'invisible'
      });
    } catch (error) {
      console.error('Turnstile initialization error:', error);
    }
  }

  handleDevelopmentMode() {
    console.log('Development mode: Turnstile verification disabled');
    this.enableSubmitButton();
    this.addDevelopmentToken();
  }

  onSuccess(token) {
    console.log('Turnstile verification successful');
    this.addTokenToForm(token);
    this.enableSubmitButton();
  }

  onExpired() {
    console.log('Turnstile token expired');
    this.disableSubmitButton();
  }

  onError(error) {
    console.error('Turnstile error:', error);
    this.disableSubmitButton();
  }

  addTokenToForm(token) {
    const form = this.element.closest('form');
    if (!form) return;

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
  }

  addDevelopmentToken() {
    const form = this.element.closest('form');
    if (!form) return;

    const tokenField = document.createElement('input');
    tokenField.type = 'hidden';
    tokenField.name = 'turnstile_token';
    tokenField.value = 'development_mode_token';
    form.appendChild(tokenField);
  }

  enableSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false;
      this.submitButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed');
    }
  }

  disableSubmitButton() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true;
      this.submitButtonTarget.classList.add('opacity-50', 'cursor-not-allowed');
    }
  }

  reset() {
    if (this.widgetId && window.turnstile) {
      window.turnstile.reset(this.widgetId);
    }
  }

  remove() {
    if (this.widgetId && window.turnstile) {
      window.turnstile.remove(this.widgetId);
    }
  }
}
