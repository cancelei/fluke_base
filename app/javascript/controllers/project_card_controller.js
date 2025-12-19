import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="project-card"
export default class extends Controller {
  static targets = ['card', 'loadingIndicator'];
  static classes = ['loading'];
  static values = {
    url: String
  };

  connect() {
    this.setupHoverEffects();
    this.setupKeyboardNavigation();
  }

  // Navigate to project page when card is clicked
  // Ignores clicks on links or buttons
  navigate(event) {
    // Skip if clicking on a link, button, or their children
    if (
      event.target.tagName === 'A' ||
      event.target.tagName === 'BUTTON' ||
      event.target.closest('a') ||
      event.target.closest('button')
    ) {
      return;
    }

    if (this.hasUrlValue && window.Turbo) {
      window.Turbo.visit(this.urlValue);
    }
  }

  // Enhanced hover effects with subtle animations
  setupHoverEffects() {
    const card = this.element.querySelector('.cursor-pointer');

    if (!card) {
      return;
    }

    card.addEventListener('mouseenter', () => {
      this.addHoverState();
    });

    card.addEventListener('mouseleave', () => {
      this.removeHoverState();
    });
  }

  // Keyboard navigation support
  setupKeyboardNavigation() {
    if (!this.hasUrlValue) {
      return;
    }

    // Make the entire card focusable
    const card = this.element.querySelector('.cursor-pointer');

    if (card) {
      card.setAttribute('tabindex', '0');
      card.setAttribute('role', 'link');
      card.setAttribute('aria-label', 'View project');

      card.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          Turbo.visit(this.urlValue);
        }
      });
    }
  }

  // Enhanced loading state with visual feedback
  showLoadingState(element) {
    if (!element) {
      return;
    }

    // Add loading class
    element.classList.add('opacity-75', 'pointer-events-none');

    // Create loading spinner
    const spinner = document.createElement('div');

    spinner.innerHTML = `
      <div class="inline-flex items-center">
        <svg class="animate-spin h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Loading...
      </div>
    `;

    // Replace button content temporarily
    const originalContent = element.innerHTML;

    element.innerHTML = spinner.innerHTML;

    // Restore after 2 seconds (fallback)
    setTimeout(() => {
      element.innerHTML = originalContent;
      element.classList.remove('opacity-75', 'pointer-events-none');
    }, 2000);
  }

  // Enhanced hover state management
  addHoverState() {
    const card = this.element.querySelector('.cursor-pointer');

    if (!card) {
      return;
    }

    // Add subtle glow effect using CSS class instead of hardcoded color
    card.classList.add('ring-1', 'ring-primary/30');
  }

  removeHoverState() {
    const card = this.element.querySelector('.cursor-pointer');

    if (!card) {
      return;
    }

    // Remove glow effect
    card.classList.remove('ring-1', 'ring-primary/30');
  }

  // Copy project link to clipboard
  async copyLink(event) {
    event.preventDefault();
    event.stopPropagation();

    const projectId = this.element.dataset.projectId;
    const baseUrl = window.location.origin;
    const projectUrl = `${baseUrl}/projects/${projectId}`;

    try {
      await navigator.clipboard.writeText(projectUrl);
      this.showToast('Project link copied to clipboard!', 'success');
    } catch {
      // Fallback for older browsers
      this.fallbackCopyToClipboard(projectUrl);
    }
  }

  // Fallback clipboard method
  fallbackCopyToClipboard(text) {
    const textArea = document.createElement('textarea');

    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    textArea.style.top = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
      document.execCommand('copy');
      this.showToast('Project link copied to clipboard!', 'success');
    } catch {
      this.showToast('Failed to copy link', 'error');
    }

    document.body.removeChild(textArea);
  }

  // Show toast notification using DaisyUI toast component
  // Creates a consistent toast that matches the server-rendered ToastComponent
  showToast(message, type = 'info') {
    const alertClasses = {
      success: 'alert-success',
      error: 'alert-error',
      warning: 'alert-warning',
      info: 'alert-info'
    };

    const iconPaths = {
      success: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z',
      error:
        'M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z',
      warning:
        'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z',
      info: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
    };

    const alertClass = alertClasses[type] || alertClasses.info;
    const iconPath = iconPaths[type] || iconPaths.info;

    // Create toast container matching DaisyUI/ToastComponent structure
    const toast = document.createElement('div');

    toast.className = 'toast toast-top toast-end z-50';
    toast.setAttribute('data-controller', 'toast');
    toast.setAttribute('data-toast-timeout-value', '5000');
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'polite');

    toast.innerHTML = `
      <div class="alert ${alertClass} shadow-lg">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 shrink-0 stroke-current" fill="none" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="${iconPath}" />
        </svg>
        <span>${this.escapeHtml(message)}</span>
        <button class="btn btn-sm btn-ghost" data-action="toast#dismiss">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    `;

    document.body.appendChild(toast);
  }

  // Escape HTML to prevent XSS
  escapeHtml(text) {
    const div = document.createElement('div');

    div.textContent = text;

    return div.innerHTML;
  }

  // Quick preview functionality (expandable)
  togglePreview(event) {
    event.preventDefault();
    event.stopPropagation();

    const previewElement = this.element.querySelector(
      '[data-project-card-target="preview"]'
    );

    if (!previewElement) {
      return;
    }

    const isExpanded = previewElement.style.display !== 'none';

    if (isExpanded) {
      this.collapsePreview(previewElement);
    } else {
      this.expandPreview(previewElement);
    }
  }

  expandPreview(element) {
    element.style.display = 'block';
    element.style.maxHeight = '0px';
    element.style.overflow = 'hidden';
    element.style.transition = 'max-height 0.3s ease-out';

    setTimeout(() => {
      element.style.maxHeight = '200px';
    }, 10);
  }

  collapsePreview(element) {
    element.style.maxHeight = '0px';

    setTimeout(() => {
      element.style.display = 'none';
    }, 300);
  }

  disconnect() {
    // Cleanup any event listeners or timers if needed
  }
}
