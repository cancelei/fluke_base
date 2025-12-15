import { Controller } from '@hotwired/stimulus';

// Auto-dismisses elements after a delay
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 }
  };

  connect() {
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, this.delayValue);
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  dismiss() {
    this.element.classList.add(
      'opacity-0',
      'transition-opacity',
      'duration-300'
    );
    setTimeout(() => {
      this.element.remove();
    }, 300);
  }
}
