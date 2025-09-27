import { Controller } from '@hotwired/stimulus';

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
    window.FlukeLogger?.controllerLifecycle('TimerController', 'connected', {
      hasStartedAt: !!this.startedAtValue,
      usedHours: this.usedHoursValue
    });
    if (this.startedAtValue) {
      this.startTimer();
    }
  }

  startTimer() {
    window.FlukeLogger?.userInteraction('started timer', this.playButtonTarget, {
      startedAt: this.startedAtValue,
      usedHours: this.usedHoursValue
    });
    this.playButtonTarget.classList.add('hidden');
    this.stopButtonTarget.classList.remove('hidden');
    this.interval = setInterval(() => this.updateTimer(), 1000);
  }

  stopTimer() {
    window.FlukeLogger?.userInteraction('stopped timer', this.stopButtonTarget, {
      duration: this.tick,
      usedHours: this.usedHoursValue
    });
    this.playButtonTarget.classList.remove('hidden');
    this.stopButtonTarget.classList.add('hidden');
    clearInterval(this.interval);
  }

  updateTimer() {
    // Use server time as base, increment by tick
    const now = this.nowValue + this.tick;
    this.tick += 1;
    const elapsedSeconds = now - this.startedAtValue;
    const totalUsedSeconds = Math.floor(this.usedHoursValue * 3600) + elapsedSeconds;

    const hours = Math.floor(totalUsedSeconds / 3600);
    const minutes = Math.floor((totalUsedSeconds % 3600) / 60);
    const seconds = totalUsedSeconds % 60;

    this.timerTarget.textContent = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
  }
}
