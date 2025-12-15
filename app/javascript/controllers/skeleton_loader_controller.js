import { Controller } from '@hotwired/stimulus';

/**
 * Skeleton Loader Controller
 *
 * Manages smooth transitions between skeleton loading states and actual content.
 * Supports both immediate content display and delayed transitions for async loading.
 *
 * Usage:
 *   <div data-controller="skeleton-loader"
 *        data-skeleton-loader-delay-value="300"
 *        data-skeleton-loader-loaded-class="skeleton-loaded">
 *     <div data-skeleton-loader-target="skeleton">
 *       <!-- Skeleton content -->
 *     </div>
 *     <div data-skeleton-loader-target="content" class="hidden">
 *       <!-- Actual content -->
 *     </div>
 *   </div>
 *
 * Actions:
 *   data-action="skeleton-loader#show"  - Show content, hide skeleton
 *   data-action="skeleton-loader#hide"  - Hide content, show skeleton
 *   data-action="skeleton-loader#toggle" - Toggle between states
 */
export default class extends Controller {
  static targets = ['skeleton', 'content'];
  static values = {
    delay: { type: Number, default: 0 },
    transition: { type: Number, default: 300 },
    autoShow: { type: Boolean, default: true },
    loaded: { type: Boolean, default: false }
  };

  static classes = ['loaded', 'loading', 'hidden'];

  connect() {
    // Auto-show content if it exists and autoShow is enabled
    if (
      this.autoShowValue &&
      this.hasContentTarget &&
      this.contentHasContent()
    ) {
      this.scheduleShow();
    }

    // Listen for Turbo events to handle lazy-loaded frames
    this.element.addEventListener(
      'turbo:frame-load',
      this.handleFrameLoad.bind(this)
    );
    this.element.addEventListener(
      'turbo:before-fetch-request',
      this.handleBeforeFetch.bind(this)
    );
  }

  disconnect() {
    this.element.removeEventListener(
      'turbo:frame-load',
      this.handleFrameLoad.bind(this)
    );
    this.element.removeEventListener(
      'turbo:before-fetch-request',
      this.handleBeforeFetch.bind(this)
    );
    this.clearTimers();
  }

  /**
   * Show the content and hide the skeleton with smooth transition
   */
  show() {
    this.clearTimers();

    // Apply transition styles
    if (this.hasSkeletonTarget) {
      this.skeletonTarget.style.transition = `opacity ${this.transitionValue}ms ease-out`;
      this.skeletonTarget.style.opacity = '0';
    }

    // After transition, swap visibility
    this.showTimer = setTimeout(() => {
      if (this.hasSkeletonTarget) {
        this.skeletonTarget.classList.add(this.hiddenClass);
        this.skeletonTarget.style.display = 'none';
      }

      if (this.hasContentTarget) {
        this.contentTarget.classList.remove('hidden', this.hiddenClass);
        this.contentTarget.style.opacity = '0';
        this.contentTarget.style.transition = `opacity ${this.transitionValue}ms ease-in`;

        // Trigger reflow for transition
        this.contentTarget.getBoundingClientRect();

        this.contentTarget.style.opacity = '1';
      }

      this.loadedValue = true;
      this.element.classList.add(this.loadedClass);
      this.element.classList.remove(this.loadingClass);

      // Dispatch custom event
      this.dispatch('loaded', { detail: { element: this.element } });
    }, this.transitionValue);
  }

  /**
   * Hide the content and show the skeleton (useful for refresh)
   */
  hide() {
    this.clearTimers();

    if (this.hasContentTarget) {
      this.contentTarget.style.transition = `opacity ${this.transitionValue}ms ease-out`;
      this.contentTarget.style.opacity = '0';
    }

    this.hideTimer = setTimeout(() => {
      if (this.hasContentTarget) {
        this.contentTarget.classList.add('hidden', this.hiddenClass);
      }

      if (this.hasSkeletonTarget) {
        this.skeletonTarget.classList.remove(this.hiddenClass);
        this.skeletonTarget.style.display = '';
        this.skeletonTarget.style.opacity = '0';
        this.skeletonTarget.style.transition = `opacity ${this.transitionValue}ms ease-in`;

        this.skeletonTarget.getBoundingClientRect();

        this.skeletonTarget.style.opacity = '1';
      }

      this.loadedValue = false;
      this.element.classList.remove(this.loadedClass);
      this.element.classList.add(this.loadingClass);

      this.dispatch('loading', { detail: { element: this.element } });
    }, this.transitionValue);
  }

  /**
   * Toggle between skeleton and content states
   */
  toggle() {
    if (this.loadedValue) {
      this.hide();
    } else {
      this.show();
    }
  }

  /**
   * Refresh: hide content, then show after a delay (useful for data refresh)
   */
  refresh() {
    this.hide();
    this.refreshTimer = setTimeout(() => {
      this.show();
    }, this.transitionValue + 100);
  }

  // Handle Turbo frame load completion
  handleFrameLoad(_event) {
    this.scheduleShow();
  }

  // Handle Turbo fetch start
  handleBeforeFetch(_event) {
    if (!this.loadedValue) {
      return;
    }
    this.hide();
  }

  // Schedule showing content with optional delay
  scheduleShow() {
    this.clearTimers();

    if (this.delayValue > 0) {
      this.delayTimer = setTimeout(() => {
        this.show();
      }, this.delayValue);
    } else {
      // Use requestAnimationFrame for smoother initial render
      requestAnimationFrame(() => {
        this.show();
      });
    }
  }

  // Check if content target has actual content
  contentHasContent() {
    if (!this.hasContentTarget) {
      return false;
    }

    return this.contentTarget.innerHTML.trim().length > 0;
  }

  // Clear all pending timers
  clearTimers() {
    if (this.showTimer) {
      clearTimeout(this.showTimer);
    }
    if (this.hideTimer) {
      clearTimeout(this.hideTimer);
    }
    if (this.delayTimer) {
      clearTimeout(this.delayTimer);
    }
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer);
    }
  }

  // Default class names if not specified
  get hiddenClass() {
    return this.hasHiddenClass ? this.hiddenClasses[0] : 'hidden';
  }

  get loadedClass() {
    return this.hasLoadedClass ? this.loadedClasses[0] : 'skeleton-loaded';
  }

  get loadingClass() {
    return this.hasLoadingClass ? this.loadingClasses[0] : 'skeleton-loading';
  }
}
