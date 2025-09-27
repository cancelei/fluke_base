# Stimulus Controller Patterns in FlukeBase

This document outlines the comprehensive Stimulus controller implementation patterns used throughout the FlukeBase codebase, providing real examples for future AI agents to reference.

> **⚡ Testing Guide**: For comprehensive testing patterns that complement these Stimulus implementation patterns, see [`../test_spec/stimulus_testing/README.md`](../test_spec/stimulus_testing/README.md)

## Table of Contents

1. [Basic Controller Structure](#basic-controller-structure)
2. [Target Management](#target-management)
3. [Event Handling](#event-handling)
4. [Lifecycle Management](#lifecycle-management)
5. [Inter-Controller Communication](#inter-controller-communication)
6. [Form Integration](#form-integration)
7. [Media & Advanced Features](#media--advanced-features)
8. [Performance Patterns](#performance-patterns)

## Basic Controller Structure

### Application Controller Setup
**File**: `app/javascript/controllers/application.js:1-9`

```javascript
import { Application } from '@hotwired/stimulus';

const application = Application.start();

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

export { application };
```

### Standard Controller Template
```javascript
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['element'];
  static values = { property: String };
  
  connect() {
    // Initialize when element connects to DOM
  }
  
  disconnect() {
    // Cleanup when element disconnects from DOM
  }
  
  // Action methods
  methodName(event) {
    // Handle user interactions
  }
}
```

## Target Management

### Simple Target Usage
**File**: `app/javascript/controllers/timer_controller.js:3-4`

```javascript
export default class extends Controller {
  static targets = ['timer', 'playButton', 'stopButton'];

  connect() {
    this.interval = null;
    this.tick = 0;
    if (this.startedAtValue) {
      this.startTimer();
    }
  }

  startTimer() {
    this.playButtonTarget.classList.add('hidden');
    this.stopButtonTarget.classList.remove('hidden');
    this.interval = setInterval(() => this.updateTimer(), 1000);
  }
}
```

### Complex Target Management
**File**: `app/javascript/controllers/message_recorder_controller.js:4-8`

```javascript
export default class extends Controller {
  static targets = [
    'recordBtn', 'micIcon', 'recordingIndicator', 'audioInput', 'form',
    'recordingReview', 'playBtn', 'playIcon', 'pauseIcon', 'audioPlayer',
    'waveform', 'duration', 'clearRecordingBtn', 'sendBtn', 'textInput'
  ];

  // Safe target checking with hasXxxTarget
  setupEventListeners() {
    if (this.hasRecordBtnTarget) {
      this.recordBtnTarget.addEventListener('click', this.handleRecording.bind(this));
    }
    if (this.hasPlayBtnTarget) {
      this.playBtnTarget.addEventListener('click', this.togglePlayback.bind(this));
    }
    // ... more conditional setup
  }
}
```

### Multiple Target Selection
**File**: `app/javascript/controllers/agreement_form_controller.js:10-28`

```javascript
togglePaymentFields() {
  const paymentType = this.paymentTypeTargets.find(radio => radio.checked)?.value;
  const hourlyFields = this.hourlyFieldTargets;
  const equityFields = this.equityFieldTargets;
  
  if (paymentType === 'Hourly') {
    hourlyFields.forEach(field => { field.style.display = 'block'; });
    equityFields.forEach(field => { field.style.display = 'none'; });
  } else if (paymentType === 'Equity') {
    hourlyFields.forEach(field => { field.style.display = 'none'; });
    equityFields.forEach(field => { field.style.display = 'block'; });
  }
  // ... more conditions
}
```

## Event Handling

### Proper Event Management with Cleanup
**File**: `app/javascript/controllers/dropdown_controller.js:6-10`

```javascript
connect() {
  this.boundHide = this.hide.bind(this);
  this.boundCloseOthers = this.closeOthers.bind(this);
  document.addEventListener('dropdown:opened', this.boundCloseOthers);
}

toggle(event) {
  event.preventDefault();
  event.stopPropagation();

  if (this.menuTarget.classList.contains('hidden')) {
    this.show();
  } else {
    this.hideMenu();
  }
}

disconnect() {
  document.removeEventListener('click', this.boundHide);
  document.removeEventListener('dropdown:opened', this.boundCloseOthers);
}
```

### Form Event Integration
**File**: `app/javascript/controllers/message_recorder_controller.js:32-36`

```javascript
if (this.hasFormTarget) {
  this.formTarget.addEventListener('submit', this.handleFormSubmit.bind(this));
  // Listen for successful Turbo form submission
  this.formTarget.addEventListener('turbo:submit-end', this.handleTurboSubmitEnd.bind(this));
}
```

### Async Event Handling
**File**: `app/javascript/controllers/message_recorder_controller.js:43-51`

```javascript
async handleRecording(event) {
  event.preventDefault();

  if (!this.mediaRecorder || this.mediaRecorder.state === 'inactive') {
    await this.startRecording();
  } else if (this.mediaRecorder.state === 'recording') {
    this.stopRecording();
  }
}
```

## Lifecycle Management

### Connect Initialization
**File**: `app/javascript/controllers/message_recorder_controller.js:10-20`

```javascript
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
```

### Disconnect Cleanup
**File**: `app/javascript/controllers/message_recorder_controller.js:323-332`

```javascript
disconnect() {
  // Clean up when controller is disconnected
  if (this.audioPlayerTarget && this.audioPlayerTarget.src) {
    URL.revokeObjectURL(this.audioPlayerTarget.src);
  }

  if (this.mediaRecorder && this.mediaRecorder.state === 'recording') {
    this.mediaRecorder.stop();
  }
}
```

### Dynamic State Management
**File**: `app/javascript/controllers/message_recorder_controller.js:303-321`

```javascript
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
    this.sendBtnTarget.classList.remove('bg-purple-600', 'hover:bg-purple-500');
    this.sendBtnTarget.classList.add('bg-indigo-600', 'hover:bg-indigo-500');
  }
}
```

## Inter-Controller Communication

### Custom Event Dispatch
**File**: `app/javascript/controllers/dropdown_controller.js:30-34`

```javascript
show() {
  // Close all other dropdowns first
  this.closeAllDropdowns();

  this.menuTarget.classList.remove('hidden');
  document.addEventListener('click', this.boundHide);

  // Dispatch event for coordination with other dropdowns
  document.dispatchEvent(new CustomEvent('dropdown:opened', {
    detail: { controller: this }
  }));
}
```

### Custom Event Listening
**File**: `app/javascript/controllers/dropdown_controller.js:47-51`

```javascript
closeOthers(event) {
  if (event.detail.controller !== this) {
    this.hideMenu();
  }
}
```

### Controller Coordination
**File**: `app/javascript/controllers/dropdown_controller.js:53-64`

```javascript
closeAllDropdowns() {
  // Close all other dropdown controllers
  const allDropdowns = document.querySelectorAll('[data-controller*="dropdown"]');
  allDropdowns.forEach(dropdown => {
    if (dropdown !== this.element) {
      const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown');
      if (controller && !controller.menuTarget.classList.contains('hidden')) {
        controller.hideMenu();
      }
    }
  });
}
```

## Form Integration

### Conditional Form Fields
**File**: `app/javascript/controllers/agreement_form_controller.js:3-29`

```javascript
export default class extends Controller {
  static targets = ['paymentType', 'hourlyField', 'equityField'];

  connect() {
    this.togglePaymentFields();
  }

  togglePaymentFields() {
    const paymentType = this.paymentTypeTargets.find(radio => radio.checked)?.value;
    const hourlyFields = this.hourlyFieldTargets;
    const equityFields = this.equityFieldTargets;
    
    if (paymentType === 'Hourly') {
      hourlyFields.forEach(field => { field.style.display = 'block'; });
      equityFields.forEach(field => { field.style.display = 'none'; });
    } else if (paymentType === 'Equity') {
      hourlyFields.forEach(field => { field.style.display = 'none'; });
      equityFields.forEach(field => { field.style.display = 'block'; });
    } else if (paymentType === 'Hybrid') {
      hourlyFields.forEach(field => { field.style.display = 'block'; });
      equityFields.forEach(field => { field.style.display = 'block'; });
    } else {
      // Default: hide all payment fields until user selects a payment type
      hourlyFields.forEach(field => { field.style.display = 'none'; });
      equityFields.forEach(field => { field.style.display = 'none'; });
    }
  }
}
```

### Turbo Integration
**File**: `app/javascript/controllers/message_recorder_controller.js:285-301`

```javascript
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
```

## Media & Advanced Features

### Media Recording Controller
**File**: `app/javascript/controllers/message_recorder_controller.js:53-82`

```javascript
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
      if (e.data.size > 0) this.audioChunks.push(e.data);
    };

    this.mediaRecorder.onstop = () => {
      this.onRecordingComplete();
      // Stop all tracks to release microphone
      stream.getTracks().forEach(track => track.stop());
    };

    this.mediaRecorder.start();
    this.updateRecordingUI(true);

  } catch (err) {
    console.error('Recording error:', err);
    this.showError('Microphone access denied or not available.');
  }
}
```

### File Handling
**File**: `app/javascript/controllers/message_recorder_controller.js:92-110`

```javascript
onRecordingComplete() {
  this.audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });

  // Create file for form submission
  const file = new File([this.audioBlob], 'voice-message.webm', { type: 'audio/webm' });
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
```

### Dynamic UI Generation
**File**: `app/javascript/controllers/message_recorder_controller.js:125-143`

```javascript
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
    bar.className = 'bg-indigo-300 rounded-full transition-all duration-200';
    bar.style.width = '2px';
    bar.style.height = `${height}px`;
    this.waveformBars.push(bar);
    waveformContainer.appendChild(bar);
  }
}
```

## Performance Patterns

### Timer with Server Sync
**File**: `app/javascript/controllers/timer_controller.js:5-9, 31-43`

```javascript
export default class extends Controller {
  static values = {
    startedAt: Number,
    usedHours: Number,
    now: Number
  };

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
```

### Animation with Conditional Logic
**File**: `app/javascript/controllers/message_recorder_controller.js:185-209`

```javascript
animateWaveform() {
  if (!this.isPlaying) return;

  // Animate waveform bars during playback
  this.waveformBars.forEach((bar, index) => {
    const delay = index * 50; // Stagger animation
    setTimeout(() => {
      if (this.isPlaying) {
        bar.classList.add('bg-indigo-600');
        bar.classList.remove('bg-indigo-300');
        setTimeout(() => {
          if (bar) {
            bar.classList.remove('bg-indigo-600');
            bar.classList.add('bg-indigo-300');
          }
        }, 200);
      }
    }, delay);
  });

  // Continue animation if still playing
  if (this.isPlaying) {
    setTimeout(() => this.animateWaveform(), this.waveformBars.length * 50 + 500);
  }
}
```

## HTML Integration Examples

### Basic Controller Usage
```html
<div data-controller="dropdown">
  <button data-action="click->dropdown#toggle" data-dropdown-target="button">
    Menu
  </button>
  <div data-dropdown-target="menu" class="hidden">
    <!-- Menu content -->
  </div>
</div>
```

### Multiple Controllers
```html
<form data-controller="message-recorder form-submission">
  <input data-message-recorder-target="textInput">
  <input type="file" data-message-recorder-target="audioInput" hidden>
  <button data-action="click->message-recorder#handleRecording" 
          data-message-recorder-target="recordBtn">
    Record
  </button>
</form>
```

### Values and Targets
```html
<div data-controller="timer" 
     data-timer-started-at-value="<%= @time_log.started_at.to_i %>"
     data-timer-used-hours-value="<%= @time_log.used_hours || 0 %>"
     data-timer-now-value="<%= Time.current.to_i %>">
  <span data-timer-target="timer">00:00:00</span>
  <button data-action="click->timer#startTimer" data-timer-target="playButton">Start</button>
  <button data-action="click->timer#stopTimer" data-timer-target="stopButton" class="hidden">Stop</button>
</div>
```

## Best Practices Summary

1. **Target Safety**: Always use `hasXxxTarget` checks before accessing targets
2. **Event Binding**: Bind event listeners properly and clean them up in disconnect()
3. **State Management**: Initialize all state in connect(), clean up in disconnect()
4. **Error Handling**: Gracefully handle browser API unavailability
5. **Memory Management**: Clean up URLs, intervals, and media streams
6. **Progressive Enhancement**: Check for API support before using advanced features
7. **Performance**: Use requestAnimationFrame for animations, debounce where appropriate
8. **Turbo Integration**: Listen for Turbo events for proper form integration
9. **Inter-Controller Communication**: Use custom events for controller coordination
10. **Accessibility**: Provide proper ARIA labels and keyboard support

## Common Patterns

### 1. Toggle Pattern
```javascript
toggle() {
  if (this.element.classList.contains('active')) {
    this.hide();
  } else {
    this.show();
  }
}
```

### 2. State Sync Pattern
```javascript
connect() {
  this.syncState();
}

syncState() {
  // Update UI based on current data values
}
```

### 3. Form Enhancement Pattern
```javascript
connect() {
  this.originalSubmit = this.formTarget.onsubmit;
  this.formTarget.addEventListener('submit', this.enhanceSubmit.bind(this));
}

enhanceSubmit(event) {
  // Add enhancements before original submit
  if (this.originalSubmit) {
    this.originalSubmit.call(this.formTarget, event);
  }
}
```