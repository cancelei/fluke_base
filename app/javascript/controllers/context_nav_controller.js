import { Controller } from '@hotwired/stimulus';

/**
 * Context Navigation Controller
 *
 * Manages the project context navigation bar interactions:
 * - Dropdown exclusivity (only one dropdown open at a time)
 * - Click outside to close dropdowns
 * - Injects context page info into project selection forms
 */
export default class extends Controller {
  static targets = ['projectDropdown', 'milestoneDropdown'];

  connect() {
    this.handleClick = this.handleClick.bind(this);
    this.handleEscape = this.handleEscape.bind(this);

    document.addEventListener('click', this.handleClick);
    document.addEventListener('keydown', this.handleEscape);
  }

  disconnect() {
    document.removeEventListener('click', this.handleClick);
    document.removeEventListener('keydown', this.handleEscape);
  }

  /**
   * Handle clicks for dropdown exclusivity
   */
  handleClick(event) {
    const clickedSummary = event.target.closest('details.dropdown > summary');

    if (clickedSummary) {
      // Clicked on a dropdown summary - close all OTHER dropdowns after native toggle
      const clickedDropdown = clickedSummary.parentElement;

      setTimeout(() => {
        this.element
          .querySelectorAll('details.dropdown[open]')
          .forEach(dropdown => {
            if (dropdown !== clickedDropdown) {
              dropdown.removeAttribute('open');
            }
          });
      }, 0);
    } else if (!event.target.closest('details.dropdown')) {
      // Clicked outside all dropdowns - close all
      this.closeAllDropdowns();
    }
  }

  /**
   * Close all dropdowns on Escape key
   */
  handleEscape(event) {
    if (event.key === 'Escape') {
      this.closeAllDropdowns();
    }
  }

  /**
   * Close all dropdown menus
   */
  closeAllDropdowns() {
    this.element
      .querySelectorAll('details.dropdown[open]')
      .forEach(dropdown => {
        dropdown.removeAttribute('open');
      });
  }

  /**
   * Called when a project selection form is submitted
   * Ensures the context_page field is properly set
   */
  selectProject(event) {
    const form = event.target.closest('form');

    if (!form) {
      return;
    }

    // Close dropdown after selection
    const dropdown = form.closest('details.dropdown');

    if (dropdown) {
      setTimeout(() => {
        dropdown.removeAttribute('open');
      }, 100);
    }
  }

  /**
   * Handle milestone tracking button clicks
   * Close the milestone dropdown after action
   */
  trackMilestone(event) {
    const dropdown = event.target.closest('details.dropdown');

    if (dropdown) {
      setTimeout(() => {
        dropdown.removeAttribute('open');
      }, 100);
    }
  }
}
