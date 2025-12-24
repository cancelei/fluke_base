import { Controller } from '@hotwired/stimulus';

/**
 * Live Search Controller
 *
 * Provides debounced auto-submit functionality for search forms.
 * Text inputs are debounced, while selects and dates submit immediately.
 *
 * Usage:
 *   <form data-controller="live-search" data-live-search-debounce-value="500">
 *     <input type="text" data-live-search-target="input" data-action="input->live-search#search">
 *     <select data-action="change->live-search#submitNow">
 *   </form>
 */
export default class extends Controller {
  static targets = ['input', 'form', 'submitButton'];
  static values = {
    debounce: { type: Number, default: 400 },
    minLength: { type: Number, default: 0 }
  };

  connect() {
    this.timeout = null;

    // Hide submit button if it exists and auto-submit is enabled
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.classList.add('hidden');
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  /**
   * Debounced search - waits for user to stop typing
   * Use with: data-action="input->live-search#search"
   */
  search(event) {
    const value = event.target.value;

    // Clear any pending submission
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    // Check minimum length requirement
    if (value.length > 0 && value.length < this.minLengthValue) {
      return;
    }

    // Debounce the submission
    this.timeout = setTimeout(() => {
      this.submit();
    }, this.debounceValue);
  }

  /**
   * Immediate submission - for selects, dates, etc.
   * Use with: data-action="change->live-search#submitNow"
   */
  submitNow() {
    // Clear any pending debounced submission
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
    this.submit();
  }

  /**
   * Submit the form
   */
  submit() {
    const form =
      this.element.tagName === 'FORM'
        ? this.element
        : this.element.querySelector('form');

    if (form) {
      // Add loading state to inputs
      this.inputTargets.forEach(input => {
        input.classList.add('animate-pulse');
      });

      // Use requestSubmit for proper form submission with Turbo
      form.requestSubmit();

      // Remove loading state after a short delay
      setTimeout(() => {
        this.inputTargets.forEach(input => {
          input.classList.remove('animate-pulse');
        });
      }, 300);
    }
  }

  /**
   * Clear the search and submit
   * Use with: data-action="click->live-search#clear"
   */
  clear(event) {
    event.preventDefault();

    this.inputTargets.forEach(input => {
      if (input.type === 'text' || input.type === 'search') {
        input.value = '';
      } else if (input.tagName === 'SELECT') {
        input.selectedIndex = 0;
      }
    });

    this.submit();
  }
}
