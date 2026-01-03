import { Controller } from '@hotwired/stimulus';

/**
 * Stimulus controller for log filtering controls.
 * Manages type toggles, level selection, sandbox filter, and search.
 *
 * Features:
 * - Loading state feedback during filter application
 * - Visual feedback during debounce period
 * - Error state handling
 */
export default class extends Controller {
  static targets = [
    'typeToggles',
    'levelSelect',
    'sandboxSelect',
    'searchInput',
    'filterContainer'
  ];

  static values = {
    selectedTypes: {
      type: Array,
      default: ['mcp', 'container', 'application']
    },
    selectedLevels: {
      type: Array,
      default: ['info', 'warn', 'error', 'fatal']
    },
    debounceMs: { type: Number, default: 300 },
    isFiltering: { type: Boolean, default: false }
  };

  static classes = ['filtering', 'filterActive'];

  connect() {
    this.debounceTimer = null;
    this.isFiltering = false;
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
  }

  toggleType(event) {
    const type = event.currentTarget.dataset.type;
    const button = event.currentTarget;

    if (this.selectedTypesValue.includes(type)) {
      // Don't allow deselecting all types
      if (this.selectedTypesValue.length > 1) {
        this.selectedTypesValue = this.selectedTypesValue.filter(
          t => t !== type
        );
        button.classList.remove('btn-primary', 'btn-secondary', 'btn-accent');
        button.classList.add('btn-ghost');
      }
    } else {
      this.selectedTypesValue = [...this.selectedTypesValue, type];
      button.classList.remove('btn-ghost');

      // Add appropriate color class
      const colorMap = {
        mcp: 'btn-primary',
        container: 'btn-secondary',
        application: 'btn-accent'
      };

      button.classList.add(colorMap[type] || 'btn-primary');
    }

    this.emitFilterChange();
  }

  updateLevels(event) {
    const value = event.target.value;

    const levelPresets = {
      all: ['trace', 'debug', 'info', 'warn', 'error', 'fatal'],
      info: ['info', 'warn', 'error', 'fatal'],
      warn: ['warn', 'error', 'fatal'],
      error: ['error', 'fatal'],
      custom: this.selectedLevelsValue // Keep current for custom
    };

    if (value !== 'custom') {
      this.selectedLevelsValue = levelPresets[value] || levelPresets.all;
      this.emitFilterChange();
    }
  }

  updateSandbox(_event) {
    this.emitFilterChange();
  }

  debounceSearch() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }

    // Show typing indicator on search input
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.classList.add('animate-pulse', 'border-primary');
    }

    this.debounceTimer = setTimeout(() => {
      this.clearSearchFeedback();
      this.emitFilterChange();
    }, this.debounceMsValue);
  }

  applyFilter() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    this.clearSearchFeedback();
    this.emitFilterChange();
  }

  /**
   * Clear search input visual feedback
   */
  clearSearchFeedback() {
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.classList.remove(
        'animate-pulse',
        'border-primary'
      );
    }
  }

  clearFilters() {
    // Reset types
    this.selectedTypesValue = ['mcp', 'container', 'application'];
    this.updateTypeButtonStyles();

    // Reset levels
    this.selectedLevelsValue = ['info', 'warn', 'error', 'fatal'];
    if (this.hasLevelSelectTarget) {
      this.levelSelectTarget.value = 'info';
    }

    // Reset sandbox
    if (this.hasSandboxSelectTarget) {
      this.sandboxSelectTarget.value = '';
    }

    // Reset search
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = '';
    }

    this.emitFilterChange();
  }

  updateTypeButtonStyles() {
    if (!this.hasTypeTogglesTarget) {
      return;
    }

    const buttons =
      this.typeTogglesTarget.querySelectorAll('button[data-type]');

    buttons.forEach(button => {
      const type = button.dataset.type;
      const isActive = this.selectedTypesValue.includes(type);

      button.classList.remove(
        'btn-primary',
        'btn-secondary',
        'btn-accent',
        'btn-ghost'
      );

      if (isActive) {
        const colorMap = {
          mcp: 'btn-primary',
          container: 'btn-secondary',
          application: 'btn-accent'
        };

        button.classList.add(colorMap[type] || 'btn-primary');
      } else {
        button.classList.add('btn-ghost');
      }
    });
  }

  emitFilterChange() {
    const filter = this.buildFilter();

    // Show filtering state
    this.showFilteringState();

    // Dispatch custom event for unified-logs controller to handle
    this.dispatch('change', {
      detail: filter,
      bubbles: true
    });

    // Also try to find and update the unified-logs controller directly
    const logsController = this.findLogsController();

    if (logsController) {
      logsController.applyFilter(filter);
    }

    // Hide filtering state after a brief delay
    setTimeout(() => {
      this.hideFilteringState();
    }, 150);
  }

  /**
   * Show visual feedback that filtering is in progress
   */
  showFilteringState() {
    this.isFilteringValue = true;

    if (this.hasFilterContainerTarget) {
      this.filterContainerTarget.classList.add(this.filteringClass);
    }

    // Add subtle indicator to the element
    this.element.setAttribute('aria-busy', 'true');
  }

  /**
   * Hide filtering state feedback
   */
  hideFilteringState() {
    this.isFilteringValue = false;

    if (this.hasFilterContainerTarget) {
      this.filterContainerTarget.classList.remove(this.filteringClass);
    }

    this.element.removeAttribute('aria-busy');
  }

  buildFilter() {
    return {
      types: this.selectedTypesValue,
      levels: this.selectedLevelsValue,
      // eslint-disable-next-line camelcase -- API requires snake_case
      sandbox_id: this.hasSandboxSelectTarget
        ? this.sandboxSelectTarget.value
        : null,
      search: this.hasSearchInputTarget ? this.searchInputTarget.value : null
    };
  }

  findLogsController() {
    // Look for unified-logs controller in parent elements or siblings
    const logsElement = document.querySelector(
      '[data-controller~="unified-logs"]'
    );

    if (logsElement) {
      return this.application.getControllerForElementAndIdentifier(
        logsElement,
        'unified-logs'
      );
    }

    return null;
  }

  // Default class names if not specified
  get filteringClass() {
    return this.hasFilteringClass ? this.filteringClasses[0] : 'opacity-60';
  }

  get filterActiveClass() {
    return this.hasFilterActiveClass
      ? this.filterActiveClasses[0]
      : 'filter-active';
  }
}
