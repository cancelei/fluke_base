import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="stealth-mode"
export default class extends Controller {
  static targets = ['toggle', 'customization'];
  static values = { editMode: Boolean };

  connect() {
    // Initialize form visibility immediately without delay
    this.updateFormVisibility();
  }

  toggle() {
    this.updateFormVisibility();
  }

  updateFormVisibility() {
    const checkbox = this.hasToggleTarget ? this.toggleTarget : null;
    const isStealthMode = checkbox ? checkbox.checked : false;

    const mainForm = document.getElementById('main-project-form');
    const stealthSummary = document.getElementById('stealth-mode-summary');

    // Update customization section
    if (this.hasCustomizationTarget) {
      if (isStealthMode) {
        this.customizationTarget.classList.add('group-hover:block');
        this.customizationTarget.classList.add('hidden'); // Ensure it stays hidden by default (non-hover)
      } else {
        this.customizationTarget.classList.remove('group-hover:block');
        this.customizationTarget.classList.add('hidden');
      }
    }

    // In edit mode, don't auto-hide the form on initialization if stealth mode is enabled
    // This allows users to see the form when editing stealth projects
    const isEditMode = this.hasEditModeValue && this.editModeValue;
    const shouldShowForm = !isStealthMode || (isEditMode && this.isInitialLoad);

    // Track if this is the initial page load
    if (!Object.prototype.hasOwnProperty.call(this, 'isInitialLoad')) {
      this.isInitialLoad = true;
    }

    // Update main form visibility
    if (mainForm) {
      if (shouldShowForm) {
        mainForm.classList.remove('hidden');
      } else {
        mainForm.classList.add('hidden');
      }
    }

    // Update stealth summary visibility
    if (stealthSummary) {
      if (isStealthMode && !shouldShowForm) {
        stealthSummary.classList.remove('hidden');
      } else {
        stealthSummary.classList.add('hidden');
      }
    }

    // After first update, mark as no longer initial load
    if (this.isInitialLoad) {
      this.isInitialLoad = false;
    }
  }

  showFullForm(event) {
    event.preventDefault();

    const mainForm = document.getElementById('main-project-form');
    const stealthSummary = document.getElementById('stealth-mode-summary');

    if (mainForm) {
      mainForm.classList.remove('hidden');

      if (stealthSummary) {
        stealthSummary.classList.add('hidden');
      }

      // Update button state
      const button = event.target;

      button.textContent = 'Hide Full Form';
      button.classList.add('btn-ghost');
      button.classList.remove('btn-info');

      // Change action to hide form
      button.setAttribute('data-action', 'click->stealth-mode#hideFullForm');
    }
  }

  hideFullForm(event) {
    event.preventDefault();

    const mainForm = document.getElementById('main-project-form');
    const stealthSummary = document.getElementById('stealth-mode-summary');
    const isStealthMode = this.hasToggleTarget && this.toggleTarget.checked;

    if (mainForm && isStealthMode) {
      mainForm.classList.add('hidden');

      if (stealthSummary) {
        stealthSummary.classList.remove('hidden');
      }

      // Update button state
      const button = event.target;

      button.textContent = 'Show Full Form';
      button.classList.add('btn-info');
      button.classList.remove('btn-ghost');

      // Change action back to show form
      button.setAttribute('data-action', 'click->stealth-mode#showFullForm');
    }
  }
}
