import { Controller } from '@hotwired/stimulus';
import toastr from 'toastr';

export default class extends Controller {
  static values = {
    message: String,
    type: String,
    title: String,
    timeout: { type: Number, default: 5000 },
    closeButton: { type: Boolean, default: true },
    progressBar: { type: Boolean, default: true },
    positionClass: { type: String, default: 'toast-top-right' },
    preventDuplicates: { type: Boolean, default: true },
    maxToasts: { type: Number, default: 5 },
    queue: { type: Boolean, default: true },
    announceToScreenReader: { type: Boolean, default: true }
  };

  connect() {
    this.configureToastr();
    this.showToast();
  }

  configureToastr() {
    toastr.options = {
      closeButton: this.closeButtonValue,
      debug: false,
      newestOnTop: true,
      progressBar: this.progressBarValue,
      positionClass: this.positionClassValue,
      preventDuplicates: this.preventDuplicatesValue,
      onclick: null,
      showDuration: '300',
      hideDuration: '1000',
      timeOut: this.timeoutValue,
      extendedTimeOut: '1000',
      showEasing: 'swing',
      hideEasing: 'linear',
      showMethod: 'fadeIn',
      hideMethod: 'fadeOut'
    };
  }

  showToast() {
    if (!this.messageValue) return;

    // Check toast queue limits
    if (this.queueValue && this.getActiveToastCount() >= this.maxToastsValue) {
      this.removeOldestToast();
    }

    const type = this.normalizeType(this.typeValue);
    const title = this.titleValue || '';
    const toastId = this.element.dataset.toastId;

    // Announce to screen readers if enabled
    if (this.announceToScreenReaderValue) {
      this.announceToScreenReader(this.messageValue, type);
    }

    // Show the toast
    let toastElement;
    switch (type) {
    case 'success':
      toastElement = toastr.success(this.messageValue, title);
      break;
    case 'info':
      toastElement = toastr.info(this.messageValue, title);
      break;
    case 'warning':
      toastElement = toastr.warning(this.messageValue, title);
      break;
    case 'error':
      toastElement = toastr.error(this.messageValue, title);
      break;
    default:
      toastElement = toastr.info(this.messageValue, title);
    }

    // Enhance the toast element with accessibility features
    if (toastElement && toastElement.length) {
      this.enhanceToastAccessibility(toastElement[0], type, toastId);
    }

    // Remove the trigger element after showing the toast
    this.element.remove();
  }

  normalizeType(type) {
    const typeMap = {
      'notice': 'success',
      'alert': 'error',
      'success': 'success',
      'error': 'error',
      'warning': 'warning',
      'info': 'info'
    };

    return typeMap[type] || 'info';
  }

  // Accessibility enhancements
  enhanceToastAccessibility(toastElement, type, toastId) {
    // Add ARIA attributes
    toastElement.setAttribute('role', 'alert');
    toastElement.setAttribute('aria-live', 'polite');
    toastElement.setAttribute('aria-atomic', 'true');
    toastElement.setAttribute('data-toast-id', toastId);

    // Add keyboard navigation
    toastElement.setAttribute('tabindex', '0');

    // Add close button accessibility
    const closeButton = toastElement.querySelector('.toast-close-button');
    if (closeButton) {
      closeButton.setAttribute('aria-label', 'Close notification');
      closeButton.setAttribute('title', 'Close notification');
    }

    // Add keyboard event listeners
    toastElement.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        this.closeToast(toastElement);
      }
    });
  }

  // Screen reader announcements
  announceToScreenReader(message, type) {
    const announcement = document.createElement('div');
    announcement.setAttribute('aria-live', 'assertive');
    announcement.setAttribute('aria-atomic', 'true');
    announcement.className = 'sr-only';
    announcement.textContent = `${type}: ${message}`;

    document.body.appendChild(announcement);

    // Remove after announcement
    setTimeout(() => {
      document.body.removeChild(announcement);
    }, 1000);
  }

  // Performance and queue management
  getActiveToastCount() {
    return document.querySelectorAll('#toast-container > div').length;
  }

  removeOldestToast() {
    const container = document.getElementById('toast-container');
    if (container && container.firstChild) {
      container.removeChild(container.firstChild);
    }
  }

  closeToast(toastElement) {
    if (toastElement && toastElement.parentNode) {
      toastElement.parentNode.removeChild(toastElement);
    }
  }
}
