import { Controller } from '@hotwired/stimulus';
import { globalEmitter } from '../utils/emitter';
import { createLogger } from '../utils/logger';
import { logConnect, logDisconnect } from '../utils/stimulus_helpers';
import { fadeOutAndRemove } from '../utils/transitions';

const logger = window.FlukeLogger || createLogger('FlukeBase');

// Auto-dismisses elements after a delay
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 }
  };

  connect() {
    logConnect(logger, 'AutoDismissController', this, {
      delay: this.delayValue
    });

    this.timeout = setTimeout(() => {
      this.dismiss();
    }, this.delayValue);
  }

  disconnect() {
    logDisconnect(logger, 'AutoDismissController');

    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }

  dismiss() {
    fadeOutAndRemove(this.element);
    const toastId = this.element.id || this.element.dataset.toastId;

    globalEmitter.emit('toast:dismissed', toastId);
  }
}
