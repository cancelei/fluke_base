import { Controller } from '@hotwired/stimulus';
import { formatDuration } from '../utils/format';
import { createLogger } from '../utils/logger';
import { logConnect, logDisconnect } from '../utils/stimulus_helpers';

const logger = window.FlukeLogger || createLogger('FlukeBase');

export default class extends Controller {
  static targets = ['timer', 'playButton', 'stopButton'];
  static values = {
    startedAt: Number,
    usedHours: Number,
    now: Number
  };

  connect() {
    this.interval = null;
    this.tick = 0;
    logConnect(logger, 'TimerController', this, {
      hasStartedAt: !!this.startedAtValue,
      usedHours: this.usedHoursValue
    });
    if (this.startedAtValue) {
      this.startTimer();
    }
  }

  disconnect() {
    logDisconnect(logger, 'TimerController');
    if (this.interval) {
      clearInterval(this.interval);
    }
  }

  startTimer() {
    window.FlukeLogger?.userInteraction(
      'started timer',
      this.playButtonTarget,
      {
        startedAt: this.startedAtValue,
        usedHours: this.usedHoursValue
      }
    );
    this.playButtonTarget.classList.add('hidden');
    this.stopButtonTarget.classList.remove('hidden');
    this.interval = setInterval(() => this.updateTimer(), 1000);
  }

  stopTimer() {
    window.FlukeLogger?.userInteraction(
      'stopped timer',
      this.stopButtonTarget,
      {
        duration: this.tick,
        usedHours: this.usedHoursValue
      }
    );
    this.playButtonTarget.classList.remove('hidden');
    this.stopButtonTarget.classList.add('hidden');
    clearInterval(this.interval);
  }

  updateTimer() {
    // Use server time as base, increment by tick
    const now = this.nowValue + this.tick;

    this.tick += 1;
    const elapsedSeconds = now - this.startedAtValue;
    const totalUsedSeconds =
      Math.floor(this.usedHoursValue * 3600) + elapsedSeconds;

    this.timerTarget.textContent = formatDuration(totalUsedSeconds);
  }
}
