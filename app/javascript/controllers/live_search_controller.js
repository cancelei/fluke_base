import { Controller } from '@hotwired/stimulus';
import { createLogger } from '../utils/logger';
import {
  debounced,
  logConnect,
  logDisconnect
} from '../utils/stimulus_helpers';

const logger = window.FlukeLogger || createLogger('FlukeBase');

/**
 * Live Search Controller
 *
 * Provides debounced auto-submit functionality for search forms.
 * Text inputs are debounced, while selects and dates submit immediately.
 */
export default class extends Controller {
  static targets = ['input', 'form', 'submitButton'];
  static values = {
    debounce: { type: Number, default: 400 },
    minLength: { type: Number, default: 0 }
  };

  connect() {
    logConnect(logger, 'LiveSearchController', this);

    this.debouncedSubmit = debounced(() => this.submit(), this.debounceValue);

    // Hide submit button if it exists and auto-submit is enabled
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.classList.add('hidden');
    }
  }

  disconnect() {
    logDisconnect(logger, 'LiveSearchController');
  }

  /**
   * Debounced search - waits for user to stop typing
   * Use with: data-action="input->live-search#search"
   */
  search(event) {
    const value = event.target.value;

    // Check minimum length requirement
    if (value.length > 0 && value.length < this.minLengthValue) {
      return;
    }

    this.debouncedSubmit();
  }

  /**
   * Immediate submission - for selects, dates, etc.
   * Use with: data-action="change->live-search#submitNow"
   */
  submitNow() {
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
