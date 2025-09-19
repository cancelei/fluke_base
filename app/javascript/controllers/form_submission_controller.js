import { Controller } from '@hotwired/stimulus';

// Prevents double form submissions by disabling submit button and showing loading state
export default class extends Controller {
  static targets = ['submit'];

  connect() {
    this.originalSubmitText = this.submitTarget?.textContent || 'Submit';
    this.submitting = false;
  }

  submit(event) {
    // Prevent double submission
    if (this.submitting) {
      event.preventDefault();
      return false;
    }

    // Check for Turnstile validation in production/staging
    if (this.element.querySelector('[data-cf-turnstile-response]')) {
      const turnstileResponse = this.element.querySelector('input[name="cf-turnstile-response"]');
      if (!turnstileResponse || !turnstileResponse.value) {
        event.preventDefault();
        console.warn('Turnstile verification required before form submission');
        return false;
      }
    }

    this.submitting = true;
    this.disableSubmitButton();
  }

  disableSubmitButton() {
    if (this.submitTarget) {
      this.submitTarget.disabled = true;
      this.submitTarget.textContent = 'Signing in...';
      this.submitTarget.classList.add('opacity-50', 'cursor-not-allowed');
    }
  }

  enableSubmitButton() {
    if (this.submitTarget) {
      this.submitTarget.disabled = false;
      this.submitTarget.textContent = this.originalSubmitText;
      this.submitTarget.classList.remove('opacity-50', 'cursor-not-allowed');
    }
    this.submitting = false;
  }

  // Reset on Turbo events
  turboLoadStart() {
    this.submitting = false;
  }

  turboLoadEnd() {
    this.enableSubmitButton();
  }

  disconnect() {
    this.enableSubmitButton();
  }
}
