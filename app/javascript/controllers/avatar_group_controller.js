import { Controller } from '@hotwired/stimulus';

/**
 * Avatar Group Controller
 *
 * Handles hover interactions for avatar popovers and overflow dropdown.
 * Implements intelligent positioning to keep popovers within viewport.
 */
export default class extends Controller {
  static targets = [
    'avatarWrapper',
    'popover',
    'overflowDropdown',
    'overflowPopover'
  ];

  static values = {
    popoverDelay: { type: Number, default: 200 }
  };

  connect() {
    this.showTimeouts = new Map();
    this.hideTimeouts = new Map();
    this.boundHandleDocumentClick = this.handleDocumentClick.bind(this);
    document.addEventListener('click', this.boundHandleDocumentClick);
  }

  disconnect() {
    // Clear all timeouts
    this.showTimeouts.forEach(timeout => clearTimeout(timeout));
    this.hideTimeouts.forEach(timeout => clearTimeout(timeout));
    document.removeEventListener('click', this.boundHandleDocumentClick);
  }

  /**
   * Show popover with delay
   */
  showPopover(event) {
    const wrapper = event.currentTarget.closest(
      '[data-avatar-group-target="avatarWrapper"]'
    );

    if (!wrapper) {
      return;
    }

    const userId = wrapper.dataset.userId;
    const popover = this.findPopoverForUser(userId);

    if (!popover) {
      return;
    }

    // Clear any pending hide timeout
    if (this.hideTimeouts.has(userId)) {
      clearTimeout(this.hideTimeouts.get(userId));
      this.hideTimeouts.delete(userId);
    }

    // Set show timeout
    const timeout = setTimeout(() => {
      this.positionPopover(popover, wrapper);
      popover.classList.remove('hidden');
      popover.classList.add('opacity-100', 'pointer-events-auto');
      popover.classList.remove('opacity-0', 'pointer-events-none');
      popover.setAttribute('aria-hidden', 'false');
    }, this.popoverDelayValue);

    this.showTimeouts.set(userId, timeout);
  }

  /**
   * Schedule hide popover with small delay for smooth transition
   */
  scheduleHidePopover(event) {
    const wrapper = event.currentTarget.closest(
      '[data-avatar-group-target="avatarWrapper"]'
    );

    if (!wrapper) {
      return;
    }

    const userId = wrapper.dataset.userId;

    // Clear any pending show timeout
    if (this.showTimeouts.has(userId)) {
      clearTimeout(this.showTimeouts.get(userId));
      this.showTimeouts.delete(userId);
    }

    // Set hide timeout with small delay
    const timeout = setTimeout(() => {
      this.hidePopoverForUser(userId);
    }, 100);

    this.hideTimeouts.set(userId, timeout);
  }

  /**
   * Immediately hide popover (for blur events)
   */
  hidePopover(event) {
    const wrapper = event.currentTarget.closest(
      '[data-avatar-group-target="avatarWrapper"]'
    );

    if (!wrapper) {
      return;
    }

    const userId = wrapper.dataset.userId;

    // Clear timeouts
    if (this.showTimeouts.has(userId)) {
      clearTimeout(this.showTimeouts.get(userId));
      this.showTimeouts.delete(userId);
    }

    // Delay hide slightly to allow click on popover content
    setTimeout(() => {
      this.hidePopoverForUser(userId);
    }, 150);
  }

  /**
   * Show overflow item popover (handled by CSS group-hover, but we can enhance positioning)
   */
  showOverflowPopover(event) {
    const overflowPopover = event.currentTarget.querySelector(
      '[data-avatar-group-target="overflowPopover"]'
    );

    if (!overflowPopover) {
      return;
    }

    this.positionOverflowPopover(overflowPopover, event.currentTarget);
  }

  /**
   * Hide overflow item popover
   */
  hideOverflowPopover(_event) {
    // Handled by CSS group-hover
  }

  /**
   * Position popover relative to avatar, keeping within viewport
   */
  positionPopover(popover, wrapper) {
    const wrapperRect = wrapper.getBoundingClientRect();
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    // Reset position styles
    popover.style.top = '';
    popover.style.bottom = '';
    popover.style.left = '';
    popover.style.right = '';
    popover.style.transform = '';
    popover.style.marginLeft = '';
    popover.style.marginRight = '';
    popover.style.marginTop = '';

    // Temporarily show to measure
    popover.classList.remove('hidden');
    const popoverRect = popover.getBoundingClientRect();

    // Determine horizontal position
    const spaceRight = viewportWidth - wrapperRect.right;
    const spaceLeft = wrapperRect.left;

    if (spaceRight >= popoverRect.width + 16) {
      // Position to the right
      popover.style.left = '100%';
      popover.style.marginLeft = '8px';
    } else if (spaceLeft >= popoverRect.width + 16) {
      // Position to the left
      popover.style.right = '100%';
      popover.style.marginRight = '8px';
    } else {
      // Center below
      popover.style.left = '50%';
      popover.style.transform = 'translateX(-50%)';
      popover.style.top = '100%';
      popover.style.marginTop = '8px';

      return;
    }

    // Determine vertical position
    const spaceBelow = viewportHeight - wrapperRect.bottom;
    const spaceAbove = wrapperRect.top;

    if (spaceBelow >= popoverRect.height / 2 || spaceBelow > spaceAbove) {
      popover.style.top = '0';
    } else {
      popover.style.bottom = '0';
    }
  }

  /**
   * Position overflow popover, adjusting if near viewport edge
   */
  positionOverflowPopover(popover, trigger) {
    const triggerRect = trigger.getBoundingClientRect();
    const viewportWidth = window.innerWidth;

    // Check if there's space to the right
    if (triggerRect.right + 240 > viewportWidth) {
      // Position to the left instead
      popover.style.left = 'auto';
      popover.style.right = '100%';
      popover.style.marginLeft = '0';
      popover.style.marginRight = '8px';
    } else {
      popover.style.left = '100%';
      popover.style.right = 'auto';
      popover.style.marginLeft = '8px';
      popover.style.marginRight = '0';
    }
  }

  /**
   * Handle document clicks to close popovers when clicking outside
   */
  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.hideAllPopovers();
    }
  }

  /**
   * Find popover element for a specific user
   */
  findPopoverForUser(userId) {
    return this.popoverTargets.find(p => p.dataset.userId === userId);
  }

  /**
   * Hide popover for a specific user
   */
  hidePopoverForUser(userId) {
    const popover = this.findPopoverForUser(userId);

    if (popover) {
      popover.classList.add('hidden', 'opacity-0', 'pointer-events-none');
      popover.classList.remove('opacity-100', 'pointer-events-auto');
      popover.setAttribute('aria-hidden', 'true');
    }
  }

  /**
   * Hide all visible popovers
   */
  hideAllPopovers() {
    this.popoverTargets.forEach(popover => {
      popover.classList.add('hidden', 'opacity-0', 'pointer-events-none');
      popover.classList.remove('opacity-100', 'pointer-events-auto');
      popover.setAttribute('aria-hidden', 'true');
    });
  }
}
