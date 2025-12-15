import { Controller } from '@hotwired/stimulus';

/**
 * DaisyUI Toast Controller
 * Handles toast notifications using DaisyUI's native toast component.
 * No external dependencies required - pure CSS-based styling.
 */
export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 5000 }
  };

  connect() {
    this.setupAccessibility();
    this.scheduleRemoval();
    this.addKeyboardSupport();
  }

  disconnect() {
    if (this.removalTimeout) {
      clearTimeout(this.removalTimeout);
    }
  }

  /**
   * Dismiss the toast with fade-out animation
   */
  dismiss() {
    // Add fade-out animation
    this.element.classList.add(
      'opacity-0',
      'transition-opacity',
      'duration-300'
    );

    // Remove element after animation completes
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }

  /**
   * Schedule automatic removal after timeout
   */
  scheduleRemoval() {
    if (this.timeoutValue > 0) {
      this.removalTimeout = setTimeout(() => {
        this.dismiss();
      }, this.timeoutValue);
    }
  }

  /**
   * Setup ARIA attributes for accessibility
   */
  setupAccessibility() {
    // The component already sets role="alert" in the Ruby template
    // Add live region attributes for screen readers
    this.element.setAttribute('aria-live', 'polite');
    this.element.setAttribute('aria-atomic', 'true');

    // Announce to screen readers
    this.announceToScreenReader();
  }

  /**
   * Add keyboard support for dismissing toast
   */
  addKeyboardSupport() {
    this.element.setAttribute('tabindex', '0');
    this.element.addEventListener('keydown', this.handleKeydown.bind(this));
  }

  /**
   * Handle keyboard events
   */
  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.dismiss();
    }
  }

  /**
   * Announce toast message to screen readers
   */
  announceToScreenReader() {
    const message = this.element.querySelector('span')?.textContent;

    if (!message) {
      return;
    }

    const announcement = document.createElement('div');

    announcement.setAttribute('aria-live', 'assertive');
    announcement.setAttribute('aria-atomic', 'true');
    announcement.className = 'sr-only';
    announcement.textContent = message;

    document.body.appendChild(announcement);

    // Remove after announcement is complete
    setTimeout(() => {
      announcement.remove();
    }, 1000);
  }
}
