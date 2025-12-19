import { Controller } from '@hotwired/stimulus';

/**
 * Star Rating Controller
 *
 * Provides interactive star rating display with:
 * - Hover preview effects with smooth animations
 * - Tooltip showing rating value
 * - Animated fill on load
 * - TurboBoost command integration for server submission
 * - Optimistic UI updates with revert on failure
 */
export default class extends Controller {
  static targets = [
    'star',
    'tooltip',
    'value',
    'count',
    'userRating',
    'loading',
    'error'
  ];

  static values = {
    rating: { type: Number, default: 0 },
    userRating: { type: Number, default: 0 },
    maxRating: { type: Number, default: 5 },
    readonly: { type: Boolean, default: true },
    animated: { type: Boolean, default: true },
    userId: { type: Number, default: 0 },
    submitting: { type: Boolean, default: false },
    failureCount: { type: Number, default: 0 },
    maxFailures: { type: Number, default: 3 }
  };

  connect() {
    this.hoveredRating = null;
    this.previousRating = this.userRatingValue;

    if (this.animatedValue) {
      this.animateStarsOnLoad();
    } else {
      this.updateStarDisplay(this.ratingValue);
    }

    // Listen for TurboBoost command responses
    this.element.addEventListener(
      'turbo-boost:command:finish',
      this.handleCommandFinish.bind(this)
    );
  }

  disconnect() {
    this.element.removeEventListener(
      'turbo-boost:command:finish',
      this.handleCommandFinish.bind(this)
    );
  }

  animateStarsOnLoad() {
    // Start with empty stars
    this.starTargets.forEach(star => {
      star.style.opacity = '0';
      star.style.transform = 'scale(0.5)';
    });

    // Animate each star appearing
    this.starTargets.forEach((star, index) => {
      setTimeout(() => {
        star.style.transition = 'all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)';
        star.style.opacity = '1';
        star.style.transform = 'scale(1)';

        // After appearing, fill the star if needed
        setTimeout(() => {
          this.updateSingleStar(star, index + 1, this.ratingValue);
        }, 100);
      }, index * 100);
    });
  }

  updateStarDisplay(rating) {
    this.starTargets.forEach((star, index) => {
      this.updateSingleStar(star, index + 1, rating);
    });

    // Update value display if exists
    if (this.hasValueTarget) {
      this.valueTarget.textContent = rating > 0 ? rating.toFixed(1) : '-';
    }
  }

  updateSingleStar(star, starPosition, rating) {
    const fillPercentage = this.calculateFillPercentage(starPosition, rating);
    const filledStar = star.querySelector('[data-star-filled]');
    const emptyStar = star.querySelector('[data-star-empty]');

    if (filledStar && emptyStar) {
      // Use clip-path for partial fill
      filledStar.style.clipPath = `inset(0 ${100 - fillPercentage}% 0 0)`;
      filledStar.style.opacity = fillPercentage > 0 ? '1' : '0';
    }

    // Add filled class for full stars
    star.classList.toggle('star-filled', fillPercentage === 100);
    star.classList.toggle(
      'star-partial',
      fillPercentage > 0 && fillPercentage < 100
    );
    star.classList.toggle('star-empty', fillPercentage === 0);
  }

  calculateFillPercentage(starPosition, rating) {
    if (rating >= starPosition) {
      return 100;
    } else if (rating > starPosition - 1) {
      return (rating - (starPosition - 1)) * 100;
    }

    return 0;
  }

  // Hover events
  mouseEnter(_event) {
    if (this.readonlyValue) {
      // Show tooltip with rating info
      if (this.hasTooltipTarget) {
        this.tooltipTarget.classList.remove('opacity-0', 'invisible');
        this.tooltipTarget.classList.add('opacity-100', 'visible');
      }

      // Add subtle pulse to stars
      this.starTargets.forEach(star => {
        star.style.transform = 'scale(1.05)';
      });
    }
  }

  mouseLeave(_event) {
    if (this.hasTooltipTarget) {
      this.tooltipTarget.classList.remove('opacity-100', 'visible');
      this.tooltipTarget.classList.add('opacity-0', 'invisible');
    }

    // Reset hover state
    this.hoveredRating = null;
    this.updateStarDisplay(this.ratingValue);

    // Reset scale
    this.starTargets.forEach(star => {
      star.style.transform = 'scale(1)';
    });
  }

  starMouseEnter(event) {
    if (this.readonlyValue || this.submittingValue) {
      return;
    }

    const starIndex = parseInt(event.currentTarget.dataset.starIndex);

    this.hoveredRating = starIndex;

    // Preview the hover rating
    this.starTargets.forEach((star, index) => {
      if (index < starIndex) {
        star.style.transform = 'scale(1.15)';
        this.updateSingleStar(star, index + 1, starIndex);
      } else {
        star.style.transform = 'scale(1)';
        this.updateSingleStar(star, index + 1, 0);
      }
    });

    // Show tooltip
    if (this.hasTooltipTarget) {
      this.tooltipTarget.classList.remove('opacity-0', 'invisible');
      this.tooltipTarget.classList.add('opacity-100', 'visible');
    }
  }

  starMouseLeave(_event) {
    if (this.readonlyValue || this.submittingValue) {
      return;
    }

    this.hoveredRating = null;
    this.updateStarDisplay(this.ratingValue);

    this.starTargets.forEach(star => {
      star.style.transform = 'scale(1)';
    });
  }

  // Click to set rating - TurboBoost will handle the command
  selectRating(event) {
    if (this.readonlyValue || this.submittingValue) {
      return;
    }

    // Check circuit breaker
    if (this.failureCountValue >= this.maxFailuresValue) {
      this.showError('Rating temporarily disabled. Please try again later.');

      return;
    }

    const starIndex = parseInt(event.currentTarget.dataset.starIndex);

    // Store previous rating for potential revert
    this.previousRating = this.userRatingValue;

    // Optimistic UI update
    this.userRatingValue = starIndex;
    this.submittingValue = true;

    // Show loading state
    this.showLoading();

    // Animate the selection
    this.animateSelection(starIndex);

    // Update the data attribute for TurboBoost command
    event.currentTarget.dataset.previousValue = this.previousRating;

    // TurboBoost will pick up the command from data-turbo-command attribute
    // The command response will be handled by handleCommandFinish
  }

  handleCommandFinish(event) {
    const { state } = event.detail;

    this.submittingValue = false;
    this.hideLoading();

    if (state?.success) {
      // Success - update display with new values
      if (state.average !== undefined) {
        this.ratingValue = state.average;
        this.updateStarDisplay(state.average);
      }

      if (state.rating !== undefined) {
        this.userRatingValue = state.rating;
        this.updateUserRatingBadge(state.rating);
      }

      // Reset failure count on success
      this.failureCountValue = 0;
      this.hideError();

      // Dispatch success event
      this.dispatch('success', {
        detail: { rating: state.rating, average: state.average }
      });
    } else if (state?.should_revert) {
      // Failure - revert to previous state
      this.revertRating(state.revert_to);
      this.failureCountValue += 1;

      if (state.disabled) {
        this.readonlyValue = true;
        this.showError(state.disabled_message);
      } else {
        this.showError(state.error || 'Failed to submit rating');
      }

      // Dispatch failure event
      this.dispatch('failure', {
        detail: {
          error: state.error,
          failureCount: this.failureCountValue
        }
      });
    }
  }

  revertRating(previousValue) {
    const revertTo = previousValue || this.previousRating || 0;

    this.userRatingValue = revertTo;

    // Animate the revert
    this.starTargets.forEach(star => {
      star.style.transition = 'all 0.3s ease';
      star.classList.add('star-revert');

      setTimeout(() => {
        star.classList.remove('star-revert');
      }, 300);
    });

    // Update display
    this.updateStarDisplay(this.ratingValue);
    this.updateUserRatingBadge(revertTo);
  }

  updateUserRatingBadge(rating) {
    if (this.hasUserRatingTarget) {
      if (rating > 0) {
        this.userRatingTarget.textContent = `Your rating: ${rating}`;
        this.userRatingTarget.classList.remove('hidden');
      } else {
        this.userRatingTarget.classList.add('hidden');
      }
    }
  }

  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden');
    }

    // Add loading state to stars
    this.element.classList.add('opacity-75', 'pointer-events-none');
  }

  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden');
    }

    this.element.classList.remove('opacity-75', 'pointer-events-none');
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message;
      this.errorTarget.classList.remove('hidden');

      // Auto-hide error after 5 seconds
      setTimeout(() => {
        this.hideError();
      }, 5000);
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add('hidden');
    }
  }

  animateSelection(rating) {
    this.starTargets.forEach((star, index) => {
      if (index < rating) {
        star.style.transition = 'transform 0.2s ease';
        star.style.transform = 'scale(1.3)';

        setTimeout(() => {
          star.style.transform = 'scale(1)';
        }, 200);
      }
    });
  }
}
