import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = [
    'recordBtn',
    'micIcon',
    'recordingIndicator',
    'audioInput',
    'form',
    'recordingReview',
    'playBtn',
    'playIcon',
    'pauseIcon',
    'audioPlayer',
    'waveform',
    'duration',
    'clearRecordingBtn',
    'sendBtn',
    'textInput'
  ];

  connect() {
    this.mediaRecorder = null;
    this.audioChunks = [];
    this.recordingStartTime = null;
    this.recordingDuration = 0;
    this.isPlaying = false;
    this.audioBlob = null;
    this.waveformBars = [];

    this.setupEventListeners();
  }

  setupEventListeners() {
    if (this.hasRecordBtnTarget) {
      this.recordBtnTarget.addEventListener(
        'click',
        this.handleRecording.bind(this)
      );
    }
    if (this.hasPlayBtnTarget) {
      this.playBtnTarget.addEventListener(
        'click',
        this.togglePlayback.bind(this)
      );
    }
    if (this.hasClearRecordingBtnTarget) {
      this.clearRecordingBtnTarget.addEventListener(
        'click',
        this.clearRecording.bind(this)
      );
    }
    if (this.hasFormTarget) {
      this.formTarget.addEventListener(
        'submit',
        this.handleFormSubmit.bind(this)
      );
      // Listen for successful Turbo form submission
      this.formTarget.addEventListener(
        'turbo:submit-end',
        this.handleTurboSubmitEnd.bind(this)
      );
    }
    if (this.hasAudioPlayerTarget) {
      this.audioPlayerTarget.addEventListener(
        'ended',
        this.onAudioEnded.bind(this)
      );
      this.audioPlayerTarget.addEventListener(
        'timeupdate',
        this.updateProgress.bind(this)
      );
    }
  }

  async handleRecording(event) {
    event.preventDefault();

    if (!this.mediaRecorder || this.mediaRecorder.state === 'inactive') {
      await this.startRecording();
    } else if (this.mediaRecorder.state === 'recording') {
      this.stopRecording();
    }
  }

  async startRecording() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.showError('Recording not supported in this browser.');

      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });

      this.mediaRecorder = new MediaRecorder(stream);
      this.audioChunks = [];
      this.recordingStartTime = Date.now();

      this.mediaRecorder.ondataavailable = e => {
        if (e.data.size > 0) {
          this.audioChunks.push(e.data);
        }
      };

      this.mediaRecorder.onstop = () => {
        this.onRecordingComplete();
        // Stop all tracks to release microphone
        stream.getTracks().forEach(track => track.stop());
      };

      this.mediaRecorder.start();
      this.updateRecordingUI(true);
    } catch (err) {
      window.FlukeLogger?.error('MessageRecorder', err, {
        action: 'startRecording',
        hasMediaDevices: !!navigator.mediaDevices,
        hasGetUserMedia: !!navigator.mediaDevices?.getUserMedia
      });
      this.showError('Microphone access denied or not available.');
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
      this.recordingDuration = Date.now() - this.recordingStartTime;
      this.mediaRecorder.stop();
      this.updateRecordingUI(false);
    }
  }

  onRecordingComplete() {
    this.audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });

    // Create file for form submission
    const file = new File([this.audioBlob], 'voice-message.webm', {
      type: 'audio/webm'
    });
    const dt = new DataTransfer();

    dt.items.add(file);
    this.audioInputTarget.files = dt.files;

    // Setup audio player for review
    const audioUrl = URL.createObjectURL(this.audioBlob);

    this.audioPlayerTarget.src = audioUrl;

    // Show recording review UI
    this.showRecordingReview();

    // Generate waveform visualization
    this.generateWaveform();
  }

  showRecordingReview() {
    this.recordingReviewTarget.classList.remove('hidden');
    this.recordingReviewTarget.scrollIntoView({
      behavior: 'smooth',
      block: 'nearest'
    });

    // Update duration display
    this.updateDurationDisplay(this.recordingDuration / 1000);

    // Update send button to indicate voice message will be sent
    this.sendBtnTarget.textContent = 'Send with Voice Message';
    this.sendBtnTarget.classList.add('btn-secondary');
    this.sendBtnTarget.classList.remove('btn-primary');
  }

  generateWaveform() {
    // Create a simple animated waveform visualization
    const waveformContainer = this.waveformTarget;

    waveformContainer.innerHTML = '';

    // Generate random heights for waveform bars (in a real app, you'd analyze the audio)
    const barCount = 40;

    this.waveformBars = [];

    for (let i = 0; i < barCount; i++) {
      const bar = document.createElement('div');
      const height = Math.random() * 20 + 4; // Random height between 4-24px

      bar.className =
        'bg-secondary/30 rounded-full transition-all duration-200';
      bar.style.width = '2px';
      bar.style.height = `${height}px`;
      this.waveformBars.push(bar);
      waveformContainer.appendChild(bar);
    }
  }

  togglePlayback() {
    if (this.isPlaying) {
      this.pausePlayback();
    } else {
      this.startPlayback();
    }
  }

  startPlayback() {
    this.audioPlayerTarget.play();
    this.isPlaying = true;
    this.playIconTarget.classList.add('hidden');
    this.pauseIconTarget.classList.remove('hidden');

    // Animate waveform during playback
    this.animateWaveform();
  }

  pausePlayback() {
    this.audioPlayerTarget.pause();
    this.isPlaying = false;
    this.playIconTarget.classList.remove('hidden');
    this.pauseIconTarget.classList.add('hidden');
  }

  onAudioEnded() {
    this.isPlaying = false;
    this.playIconTarget.classList.remove('hidden');
    this.pauseIconTarget.classList.add('hidden');
    this.audioPlayerTarget.currentTime = 0;
    this.updateDurationDisplay(this.recordingDuration / 1000);
  }

  updateProgress() {
    if (this.audioPlayerTarget.duration) {
      const remaining =
        this.audioPlayerTarget.duration - this.audioPlayerTarget.currentTime;

      this.updateDurationDisplay(remaining);
    }
  }

  animateWaveform() {
    if (!this.isPlaying) {
      return;
    }

    // Animate waveform bars during playback
    this.waveformBars.forEach((bar, index) => {
      const delay = index * 50; // Stagger animation

      setTimeout(() => {
        if (this.isPlaying) {
          bar.classList.add('bg-secondary');
          bar.classList.remove('bg-secondary/30');
          setTimeout(() => {
            if (bar) {
              bar.classList.remove('bg-secondary');
              bar.classList.add('bg-secondary/30');
            }
          }, 200);
        }
      }, delay);
    });

    // Continue animation if still playing
    if (this.isPlaying) {
      setTimeout(
        () => this.animateWaveform(),
        this.waveformBars.length * 50 + 500
      );
    }
  }

  clearRecording() {
    // Clear the recording
    this.audioBlob = null;
    this.audioChunks = [];
    this.recordingDuration = 0;

    // Clear file input
    this.audioInputTarget.value = '';

    // Hide recording review
    this.recordingReviewTarget.classList.add('hidden');

    // Reset send button
    this.sendBtnTarget.textContent = 'Send';
    this.sendBtnTarget.classList.remove('btn-secondary');
    this.sendBtnTarget.classList.add('btn-primary');

    // Reset playback state
    this.isPlaying = false;
    this.playIconTarget.classList.remove('hidden');
    this.pauseIconTarget.classList.add('hidden');

    // Clear audio player
    if (this.audioPlayerTarget.src) {
      URL.revokeObjectURL(this.audioPlayerTarget.src);
      this.audioPlayerTarget.src = '';
    }
  }

  updateRecordingUI(isRecording) {
    const micSvg = this.micIconTarget.querySelector('svg');

    if (isRecording) {
      micSvg.setAttribute('fill', 'currentColor');
      micSvg.classList.add('text-error');
      this.recordingIndicatorTarget.classList.remove('hidden');
      this.recordBtnTarget.classList.add('bg-error/20', 'hover:bg-error/30');
      this.recordBtnTarget.classList.remove('bg-base-300', 'hover:bg-base-200');
      this.recordBtnTarget.title = 'Stop recording';
    } else {
      micSvg.setAttribute('fill', 'currentColor');
      micSvg.classList.remove('text-error');
      this.recordingIndicatorTarget.classList.add('hidden');
      this.recordBtnTarget.classList.remove('bg-error/20', 'hover:bg-error/30');
      this.recordBtnTarget.classList.add('bg-base-300', 'hover:bg-base-200');
      this.recordBtnTarget.title = 'Record voice message';
    }
  }

  updateDurationDisplay(seconds) {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = Math.floor(seconds % 60);

    this.durationTarget.textContent = `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
  }

  showError(message) {
    this.displayFlashMessage(message, 'error');
  }

  displayFlashMessage(message, type = 'info') {
    const flashContainer = document.getElementById('flash_messages');

    if (!flashContainer) {
      return;
    }

    const alertClasses = {
      error: 'alert-error',
      success: 'alert-success',
      info: 'alert-info',
      warning: 'alert-warning'
    };

    const alertClass = alertClasses[type] || alertClasses.info;
    const wrapper = document.createElement('div');

    wrapper.className = `alert ${alertClass} mb-4 shadow-lg`;
    wrapper.setAttribute('role', 'alert');

    const messageSpan = document.createElement('span');

    messageSpan.textContent = message;
    wrapper.appendChild(messageSpan);

    flashContainer.innerHTML = '';
    flashContainer.appendChild(wrapper);

    setTimeout(() => {
      if (flashContainer.contains(wrapper)) {
        wrapper.remove();
      }
    }, 5000);
  }

  handleFormSubmit() {
    // Clean up on form submit
    if (this.isPlaying) {
      this.pausePlayback();
    }

    // Hide recording indicator
    this.recordingIndicatorTarget.classList.add('hidden');

    // Stop any ongoing recording
    if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
      this.mediaRecorder.stop();
      this.updateRecordingUI(false);
    }
  }

  handleTurboSubmitEnd(event) {
    // Check if the form submission was successful
    const { success } = event.detail;

    if (success) {
      // Clear the recording review after successful submission
      this.clearRecording();

      // Clear the text input as well
      if (this.hasTextInputTarget) {
        this.textInputTarget.value = '';
      }

      // Reset form to initial state
      this.resetForm();
    }
  }

  resetForm() {
    // Reset all form state to initial values
    this.audioBlob = null;
    this.audioChunks = [];
    this.recordingDuration = 0;
    this.isPlaying = false;

    // Hide recording review if visible
    if (this.hasRecordingReviewTarget) {
      this.recordingReviewTarget.classList.add('hidden');
    }

    // Reset send button
    if (this.hasSendBtnTarget) {
      this.sendBtnTarget.textContent = 'Send';
      this.sendBtnTarget.classList.remove('btn-secondary');
      this.sendBtnTarget.classList.add('btn-primary');
    }
  }

  disconnect() {
    // Clean up when controller is disconnected
    if (this.audioPlayerTarget && this.audioPlayerTarget.src) {
      URL.revokeObjectURL(this.audioPlayerTarget.src);
    }

    if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
      this.mediaRecorder.stop();
    }
  }
}
