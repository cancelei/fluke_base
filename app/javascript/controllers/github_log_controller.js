import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['changesContainer', 'toggleButton'];

  connect() {
    // Initialize the height to 0 and set overflow hidden
    const container = this.changesContainerTarget;
    container.style.maxHeight = '0';
    container.style.overflow = 'hidden';
    container.style.transition = 'max-height 0.3s ease-in-out';
  }

  toggleChanges(event) {
    event.preventDefault();

    const container = this.changesContainerTarget;
    const button = this.toggleButtonTarget;
    const isExpanding = container.style.maxHeight === '0px';

    // Toggle max-height for smooth animation
    if (isExpanding) {
      container.style.maxHeight = `${container.scrollHeight}px`;
      button.querySelector('svg').classList.add('rotate-180');
      button.innerHTML = button.innerHTML.replace('Show', 'Hide');

      // Reset height after animation completes
      setTimeout(() => {
        container.style.maxHeight = 'none';
      }, 300);
    } else {
      // Set explicit height before collapsing for smooth animation
      container.style.maxHeight = `${container.scrollHeight}px`;

      // Force reflow
      container.offsetHeight;

      // Collapse
      container.style.maxHeight = '0';
      button.querySelector('svg').classList.remove('rotate-180');
      button.innerHTML = button.innerHTML.replace('Hide', 'Show');
    }
  }
}
