import { Controller } from '@hotwired/stimulus';
import { qs, qsa } from '../utils/dom';
import { createLogger } from '../utils/logger';
import { logConnect, logDisconnect } from '../utils/stimulus_helpers';

const logger = window.FlukeLogger || createLogger('FlukeBase');

/**
 * Navbar Controller
 *
 * Handles mobile drawer navigation and dropdown exclusivity.
 * Uses click delegation for reliable dropdown management.
 */
export default class extends Controller {
  connect() {
    logConnect(logger, 'NavbarController', this);

    // Bind methods for proper event listener removal
    this.handleClick = this.handleClick.bind(this);
    this.handleEscape = this.handleEscape.bind(this);
    this.handleResize = this.handleResize.bind(this);
    this.syncSwapWithDrawer = this.syncSwapWithDrawer.bind(this);

    // Click anywhere to handle dropdown exclusivity
    document.addEventListener('click', this.handleClick);
    document.addEventListener('keydown', this.handleEscape);
    window.addEventListener('resize', this.handleResize);

    // Sync swap component with drawer checkbox
    this.setupSwapLink();
  }

  disconnect() {
    logDisconnect(logger, 'NavbarController');

    document.removeEventListener('click', this.handleClick);
    document.removeEventListener('keydown', this.handleEscape);
    window.removeEventListener('resize', this.handleResize);
  }

  handleClick(event) {
    const clickedSummary = event.target.closest('details.dropdown > summary');

    if (clickedSummary) {
      // Clicked on a dropdown summary - close all OTHER dropdowns after native toggle
      const clickedDropdown = clickedSummary.parentElement;

      // Use setTimeout to run after the native details toggle
      setTimeout(() => {
        qsa(this.element, 'details.dropdown[open]').forEach(dropdown => {
          if (dropdown !== clickedDropdown) {
            dropdown.removeAttribute('open');
          }
        });
      }, 0);
    } else if (!event.target.closest('details.dropdown')) {
      // Clicked outside all dropdowns - close all
      qsa(this.element, 'details.dropdown[open]').forEach(dropdown => {
        dropdown.removeAttribute('open');
      });
    }
  }

  handleEscape(event) {
    if (event.key !== 'Escape') {
      return;
    }

    qsa(this.element, 'details.dropdown[open]').forEach(d => {
      d.removeAttribute('open');
    });

    const drawer = qs(document, '#mobile-drawer');

    if (drawer) {
      drawer.checked = false;
      this.syncSwapWithDrawer();
    }
  }

  handleResize() {
    if (window.innerWidth >= 1024) {
      const drawer = qs(document, '#mobile-drawer');

      if (drawer) {
        drawer.checked = false;
        this.syncSwapWithDrawer();
      }
    }
  }

  setupSwapLink() {
    const drawer = qs(document, '#mobile-drawer');
    const swap = qs(document, '#mobile-drawer-swap');

    if (!drawer || !swap) {
      return;
    }

    // Sync swap when drawer changes
    drawer.addEventListener('change', this.syncSwapWithDrawer);

    // Sync drawer when swap changes (for accessibility)
    swap.addEventListener('change', e => {
      drawer.checked = e.target.checked;
    });
  }

  syncSwapWithDrawer() {
    const drawer = qs(document, '#mobile-drawer');
    const swap = qs(document, '#mobile-drawer-swap');

    if (drawer && swap) {
      swap.checked = drawer.checked;
    }
  }
}
