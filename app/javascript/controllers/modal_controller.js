import { Controller } from '@hotwired/stimulus';

/**
 * Modal Controller
 *
 * Stimulus controller for DaisyUI modal using native <dialog> element.
 * Provides enhanced functionality for keyboard navigation and accessibility.
 *
 * Usage:
 *   <dialog data-controller="modal" id="my-modal" class="modal">
 *     <div class="modal-box">...</div>
 *   </dialog>
 *
 * Opening modal from outside:
 *   document.getElementById('my-modal').showModal()
 *
 * Or use data-action on a button:
 *   <button data-action="click->modal#open" data-modal-target="my-modal">Open</button>
 */
export default class extends Controller {
  static values = {
    closeOnEscape: { type: Boolean, default: true },
    closeOnClickOutside: { type: Boolean, default: true }
  };

  connect() {
    // Ensure we're working with a dialog element
    if (this.element.tagName !== 'DIALOG') {
      console.warn('Modal controller should be attached to a <dialog> element');

      return;
    }

    // Bind event handlers
    this.handleKeydown = this.handleKeydown.bind(this);
    this.handleClick = this.handleClick.bind(this);

    // Add event listeners
    this.element.addEventListener('keydown', this.handleKeydown);
    this.element.addEventListener('click', this.handleClick);

    // Handle close event for cleanup
    this.element.addEventListener('close', this.handleClose.bind(this));
  }

  disconnect() {
    this.element.removeEventListener('keydown', this.handleKeydown);
    this.element.removeEventListener('click', this.handleClick);
  }

  /**
   * Open the modal
   */
  open() {
    this.element.showModal();
    // Focus the first focusable element
    this.focusFirstElement();
  }

  /**
   * Close the modal
   */
  close() {
    this.element.close();
  }

  /**
   * Toggle the modal state
   */
  toggle() {
    if (this.element.open) {
      this.close();
    } else {
      this.open();
    }
  }

  /**
   * Handle keydown events
   */
  handleKeydown(event) {
    if (event.key === 'Escape' && this.closeOnEscapeValue) {
      // Let the native dialog handle ESC key
      return;
    }

    // Trap focus within the modal
    if (event.key === 'Tab') {
      this.trapFocus(event);
    }
  }

  /**
   * Handle click events for backdrop close
   */
  handleClick(event) {
    // Check if click was on the backdrop (the dialog element itself, not its children)
    if (event.target === this.element && this.closeOnClickOutsideValue) {
      this.close();
    }
  }

  /**
   * Handle close event
   */
  handleClose() {
    // Dispatch a custom event for other components to listen to
    this.element.dispatchEvent(
      new CustomEvent('modal:closed', {
        bubbles: true,
        detail: { modalId: this.element.id }
      })
    );
  }

  /**
   * Focus the first focusable element in the modal
   */
  focusFirstElement() {
    const focusableElements = this.getFocusableElements();

    if (focusableElements.length > 0) {
      const [firstElement] = focusableElements;

      firstElement.focus();
    }
  }

  /**
   * Trap focus within the modal
   */
  trapFocus(event) {
    const focusableElements = this.getFocusableElements();

    if (focusableElements.length === 0) {
      return;
    }

    const [firstElement] = focusableElements;
    const lastElement = focusableElements.at(-1);

    if (event.shiftKey && document.activeElement === firstElement) {
      event.preventDefault();
      lastElement.focus();
    } else if (!event.shiftKey && document.activeElement === lastElement) {
      event.preventDefault();
      firstElement.focus();
    }
  }

  /**
   * Get all focusable elements within the modal
   */
  getFocusableElements() {
    const modalBox = this.element.querySelector('.modal-box');

    if (!modalBox) {
      return [];
    }

    const selector = [
      'button:not([disabled])',
      'a[href]',
      'input:not([disabled])',
      'select:not([disabled])',
      'textarea:not([disabled])',
      '[tabindex]:not([tabindex="-1"])'
    ].join(', ');

    return Array.from(modalBox.querySelectorAll(selector));
  }
}
