import { Controller } from '@hotwired/stimulus';
import { createLogger } from '../utils/logger';
import { jsonFetch } from '../utils/network';
import { logConnect, logDisconnect } from '../utils/stimulus_helpers';

const logger = window.FlukeLogger || createLogger('FlukeBase');

/**
 * Insight Card Controller
 * Handles AI productivity insight card interactions including
 * dismissal, navigation, and marking insights as seen.
 *
 * Features:
 * - Loading states during API operations
 * - Error handling with visual feedback
 * - Smooth animations for state transitions
 * - Retry mechanism for failed operations
 */
export default class extends Controller {
  static targets = ['content', 'loading', 'error'];
  static values = {
    type: String,
    introKey: String,
    detailPath: String,
    retryCount: { type: Number, default: 0 },
    maxRetries: { type: Number, default: 2 }
  };

  static classes = ['loading', 'error', 'success'];

  connect() {
    logConnect(logger, 'InsightCardController', this, {
      type: this.typeValue,
      introKey: this.introKeyValue
    });

    this.isLoading = false;
    this.setupAccessibility();
  }

  disconnect() {
    logDisconnect(logger, 'InsightCardController');
  }

  /**
   * Navigate to the detail view
   * @param {Event} event
   */
  navigate(event) {
    // Don't navigate if clicking dismiss button
    if (event.target.closest('[data-action*="dismiss"]')) {
      return;
    }

    if (this.hasDetailPathValue && this.detailPathValue) {
      // Mark as seen before navigating
      this.markAsSeen();
      window.Turbo.visit(this.detailPathValue);
    }
  }

  /**
   * Dismiss the insight card
   * @param {Event} event
   */
  dismiss(event) {
    event.preventDefault();
    event.stopPropagation();

    // Mark insight as seen via API
    this.markAsSeen();

    // Animate out
    this.element.classList.add(
      'opacity-0',
      'scale-95',
      'transition-all',
      'duration-300'
    );

    // Remove element after animation
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }

  /**
   * Mark insight as seen via API with loading state and error handling
   */
  async markAsSeen() {
    if (!this.hasIntroKeyValue) {
      return;
    }

    this.showLoadingState();

    try {
      await jsonFetch('/dashboard/insights/mark_seen', {
        method: 'POST',
        // eslint-disable-next-line camelcase -- API requires snake_case
        body: JSON.stringify({ insight_key: this.introKeyValue })
      });

      this.showSuccessState();
    } catch (error) {
      logger?.warning(
        'InsightCardController',
        'Failed to mark insight as seen',
        {
          error: error.message,
          insightKey: this.introKeyValue
        }
      );
      this.handleError(error);
    } finally {
      this.hideLoadingState();
    }
  }

  /**
   * Show loading indicator on the card
   */
  showLoadingState() {
    this.isLoading = true;
    this.element.classList.add(this.loadingClass);
    this.element.setAttribute('aria-busy', 'true');

    // Disable interactions during loading
    this.element.style.pointerEvents = 'none';
    this.element.style.opacity = '0.7';

    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden');
    }
  }

  /**
   * Hide loading indicator
   */
  hideLoadingState() {
    this.isLoading = false;
    this.element.classList.remove(this.loadingClass);
    this.element.removeAttribute('aria-busy');

    // Re-enable interactions
    this.element.style.pointerEvents = '';
    this.element.style.opacity = '';

    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden');
    }
  }

  /**
   * Show success state briefly
   */
  showSuccessState() {
    this.element.classList.add(this.successClass);

    setTimeout(() => {
      this.element.classList.remove(this.successClass);
    }, 1000);
  }

  /**
   * Handle API errors with retry option
   * @param {Error} _error - Error object (logged by caller)
   */
  handleError(_error) {
    this.element.classList.add(this.errorClass);

    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove('hidden');
      this.errorTarget.textContent = 'Failed to save. Click to retry.';
    }

    // Allow retry on next interaction
    if (this.retryCountValue < this.maxRetriesValue) {
      this.retryCountValue += 1;
    }

    // Auto-clear error state after 3 seconds
    setTimeout(() => {
      this.clearErrorState();
    }, 3000);
  }

  /**
   * Clear error state
   */
  clearErrorState() {
    this.element.classList.remove(this.errorClass);

    if (this.hasErrorTarget) {
      this.errorTarget.classList.add('hidden');
    }
  }

  /**
   * Retry failed operation
   */
  async retry(event) {
    event.preventDefault();
    event.stopPropagation();

    this.clearErrorState();
    await this.markAsSeen();
  }

  /**
   * Setup ARIA attributes for accessibility
   */
  setupAccessibility() {
    this.element.setAttribute('role', 'article');
    this.element.setAttribute(
      'aria-label',
      `AI insight: ${this.typeValue || 'productivity'}`
    );

    if (this.hasDetailPathValue) {
      this.element.setAttribute('tabindex', '0');
      this.element.addEventListener('keydown', this.handleKeydown.bind(this));
    }
  }

  /**
   * Handle keyboard navigation
   * @param {KeyboardEvent} event
   */
  handleKeydown(event) {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      this.navigate(event);
    } else if (event.key === 'Escape') {
      this.dismiss(event);
    }
  }
}
