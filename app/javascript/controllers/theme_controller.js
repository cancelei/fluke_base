import { Controller } from '@hotwired/stimulus';
import { qs, qsa } from '../utils/dom';
import { createLogger } from '../utils/logger';
import { jsonFetch } from '../utils/network';
import { logConnect, logDisconnect } from '../utils/stimulus_helpers';

const logger = window.FlukeLogger || createLogger('FlukeBase');

/**
 * Theme Controller
 *
 * Handles DaisyUI theme switching with:
 * - Immediate visual feedback (no page reload)
 * - localStorage persistence for fast initial load
 * - Server persistence for logged-in users
 */
export default class extends Controller {
  static values = {
    current: { type: String, default: 'nord' },
    endpoint: { type: String, default: '/users/preferences/theme' }
  };

  connect() {
    logConnect(logger, 'ThemeController', this, {
      current: this.currentValue
    });

    // Initialize current theme from HTML attribute
    this.currentValue =
      document.documentElement.getAttribute('data-theme') || 'nord';
    this.updateUI();
  }

  disconnect() {
    logDisconnect(logger, 'ThemeController');
  }

  /**
   * Get the theme modal element (rendered globally in layout)
   */
  get modal() {
    return qs(document, '#theme-modal');
  }

  /**
   * Open the theme modal
   */
  openModal() {
    const modal = this.modal;

    if (modal) {
      modal.showModal();
      // Update UI when modal opens (in case theme changed elsewhere)
      this.updateUI();
    }
  }

  /**
   * Close the theme modal
   */
  closeModal() {
    const modal = this.modal;

    if (modal) {
      modal.close();
    }
  }

  /**
   * Switch theme - called from theme card click
   */
  switch(event) {
    event.preventDefault();
    const theme = event.currentTarget.dataset.themeValue;

    if (!theme || theme === this.currentValue) {
      return;
    }

    this.applyTheme(theme);
    this.persistTheme(theme);
  }

  /**
   * Apply theme immediately to DOM
   */
  applyTheme(theme) {
    // Update HTML attribute - DaisyUI picks this up immediately
    document.documentElement.setAttribute('data-theme', theme);

    // Update localStorage for fast initial load on next visit
    localStorage.setItem('theme', theme);

    // Update internal state
    this.currentValue = theme;
    this.updateUI();
  }

  /**
   * Persist theme to server
   */
  async persistTheme(theme) {
    try {
      await jsonFetch(this.endpointValue, {
        method: 'PATCH',
        body: JSON.stringify({ theme })
      });
    } catch (error) {
      logger?.warning('ThemeController', 'Failed to persist theme preference', {
        error: error.message,
        theme
      });
      // Theme is already applied via localStorage, so graceful degradation
    }
  }

  /**
   * Update UI to reflect current theme
   */
  updateUI() {
    // Find all theme cards in the modal (which is outside controller scope)
    const themeCards = qsa(document, '[data-theme-card]');

    themeCards.forEach(card => {
      const cardTheme = card.dataset.themeValue;
      const isSelected = cardTheme === this.currentValue;

      // Update ring highlight and border
      if (isSelected) {
        card.classList.add(
          'ring-2',
          'ring-primary',
          'ring-offset-2',
          'ring-offset-base-100',
          'border-primary'
        );
        card.classList.remove('border-base-300');
      } else {
        card.classList.remove(
          'ring-2',
          'ring-primary',
          'ring-offset-2',
          'ring-offset-base-100',
          'border-primary'
        );
        card.classList.add('border-base-300');
      }

      // Update checkmark visibility
      const checkmark = qs(card, '[data-checkmark]');

      if (checkmark) {
        checkmark.classList.toggle('hidden', !isSelected);
      }
    });
  }
}
