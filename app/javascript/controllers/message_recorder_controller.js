import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "recordBtn", "micIcon", "recordingIndicator", "audioInput", "form",
    "recordingReview", "playBtn", "playIcon", "pauseIcon", "audioPlayer",
    "waveform", "duration", "clearRecordingBtn", "sendBtn", "textInput"
  ]

  connect() {
    this.mediaRecorder = null
    this.audioChunks = []
    this.recordingStartTime = null
    this.recordingDuration = 0
    this.isPlaying = false
    this.audioBlob = null
    this.waveformBars = []
    
    this.setupEventListeners()
  }

  setupEventListeners() {
    if (this.hasRecordBtnTarget) {
      this.recordBtnTarget.addEventListener('click', this.handleRecording.bind(this))
    }
    if (this.hasPlayBtnTarget) {
      this.playBtnTarget.addEventListener('click', this.togglePlayback.bind(this))
    }
    if (this.hasClearRecordingBtnTarget) {
      this.clearRecordingBtnTarget.addEventListener('click', this.clearRecording.bind(this))
    }
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', this.handleFormSubmit.bind(this))
      // Listen for successful Turbo form submission
      this.formTarget.addEventListener('turbo:submit-end', this.handleTurboSubmitEnd.bind(this))
    }
    if (this.hasAudioPlayerTarget) {
      this.audioPlayerTarget.addEventListener('ended', this.onAudioEnded.bind(this))
      this.audioPlayerTarget.addEventListener('timeupdate', this.updateProgress.bind(this))
    }
  }

  async handleRecording(event) {
    event.preventDefault()
    
    if (!this.mediaRecorder || this.mediaRecorder.state === "inactive") {
      await this.startRecording()
    } else if (this.mediaRecorder.state === "recording") {
      this.stopRecording()
    }
  }

  async startRecording() {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      this.showError("Recording not supported in this browser.")
      return
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      this.mediaRecorder = new MediaRecorder(stream)
      this.audioChunks = []
      this.recordingStartTime = Date.now()
      
      this.mediaRecorder.ondataavailable = e => {
        if (e.data.size > 0) this.audioChunks.push(e.data)
      }
      
      this.mediaRecorder.onstop = () => {
        this.onRecordingComplete()
        // Stop all tracks to release microphone
        stream.getTracks().forEach(track => track.stop())
      }
      
      this.mediaRecorder.start()
      this.updateRecordingUI(true)
      
    } catch (err) {
      console.error('Recording error:', err)
      this.showError("Microphone access denied or not available.")
    }
  }

  stopRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state === "recording") {
      this.recordingDuration = Date.now() - this.recordingStartTime
      this.mediaRecorder.stop()
      this.updateRecordingUI(false)
    }
  }

  onRecordingComplete() {
    this.audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' })
    
    // Create file for form submission
    const file = new File([this.audioBlob], "voice-message.webm", { type: 'audio/webm' })
    const dt = new DataTransfer()
    dt.items.add(file)
    this.audioInputTarget.files = dt.files
    
    // Setup audio player for review
    const audioUrl = URL.createObjectURL(this.audioBlob)
    this.audioPlayerTarget.src = audioUrl
    
    // Show recording review UI
    this.showRecordingReview()
    
    // Generate waveform visualization
    this.generateWaveform()
  }

  showRecordingReview() {
    this.recordingReviewTarget.classList.remove('hidden')
    this.recordingReviewTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    
    // Update duration display
    this.updateDurationDisplay(this.recordingDuration / 1000)
    
    // Update send button to indicate voice message will be sent
    this.sendBtnTarget.textContent = "Send with Voice Message"
    this.sendBtnTarget.classList.add('bg-purple-600', 'hover:bg-purple-500')
    this.sendBtnTarget.classList.remove('bg-indigo-600', 'hover:bg-indigo-500')
  }

  generateWaveform() {
    // Create a simple animated waveform visualization
    const waveformContainer = this.waveformTarget
    waveformContainer.innerHTML = ''
    
    // Generate random heights for waveform bars (in a real app, you'd analyze the audio)
    const barCount = 40
    this.waveformBars = []
    
    for (let i = 0; i < barCount; i++) {
      const bar = document.createElement('div')
      const height = Math.random() * 20 + 4 // Random height between 4-24px
      bar.className = 'bg-indigo-300 rounded-full transition-all duration-200'
      bar.style.width = '2px'
      bar.style.height = `${height}px`
      this.waveformBars.push(bar)
      waveformContainer.appendChild(bar)
    }
  }

  togglePlayback() {
    if (this.isPlaying) {
      this.pausePlayback()
    } else {
      this.startPlayback()
    }
  }

  startPlayback() {
    this.audioPlayerTarget.play()
    this.isPlaying = true
    this.playIconTarget.classList.add('hidden')
    this.pauseIconTarget.classList.remove('hidden')
    
    // Animate waveform during playback
    this.animateWaveform()
  }

  pausePlayback() {
    this.audioPlayerTarget.pause()
    this.isPlaying = false
    this.playIconTarget.classList.remove('hidden')
    this.pauseIconTarget.classList.add('hidden')
  }

  onAudioEnded() {
    this.isPlaying = false
    this.playIconTarget.classList.remove('hidden')
    this.pauseIconTarget.classList.add('hidden')
    this.audioPlayerTarget.currentTime = 0
    this.updateDurationDisplay(this.recordingDuration / 1000)
  }

  updateProgress() {
    if (this.audioPlayerTarget.duration) {
      const remaining = this.audioPlayerTarget.duration - this.audioPlayerTarget.currentTime
      this.updateDurationDisplay(remaining)
    }
  }

  animateWaveform() {
    if (!this.isPlaying) return
    
    // Animate waveform bars during playback
    this.waveformBars.forEach((bar, index) => {
      const delay = index * 50 // Stagger animation
      setTimeout(() => {
        if (this.isPlaying) {
          bar.classList.add('bg-indigo-600')
          bar.classList.remove('bg-indigo-300')
          setTimeout(() => {
            if (bar) {
              bar.classList.remove('bg-indigo-600')
              bar.classList.add('bg-indigo-300')
            }
          }, 200)
        }
      }, delay)
    })
    
    // Continue animation if still playing
    if (this.isPlaying) {
      setTimeout(() => this.animateWaveform(), this.waveformBars.length * 50 + 500)
    }
  }

  clearRecording() {
    // Clear the recording
    this.audioBlob = null
    this.audioChunks = []
    this.recordingDuration = 0
    
    // Clear file input
    this.audioInputTarget.value = ''
    
    // Hide recording review
    this.recordingReviewTarget.classList.add('hidden')
    
    // Reset send button
    this.sendBtnTarget.textContent = "Send"
    this.sendBtnTarget.classList.remove('bg-purple-600', 'hover:bg-purple-500')
    this.sendBtnTarget.classList.add('bg-indigo-600', 'hover:bg-indigo-500')
    
    // Reset playback state
    this.isPlaying = false
    this.playIconTarget.classList.remove('hidden')
    this.pauseIconTarget.classList.add('hidden')
    
    // Clear audio player
    if (this.audioPlayerTarget.src) {
      URL.revokeObjectURL(this.audioPlayerTarget.src)
      this.audioPlayerTarget.src = ''
    }
  }

  updateRecordingUI(isRecording) {
    const micSvg = this.micIconTarget.querySelector("svg")
    
    if (isRecording) {
      micSvg.setAttribute("fill", "red")
      this.recordingIndicatorTarget.classList.remove('hidden')
      this.recordBtnTarget.classList.add('bg-red-100', 'hover:bg-red-200')
      this.recordBtnTarget.classList.remove('bg-gray-200', 'hover:bg-indigo-100')
      this.recordBtnTarget.title = "Stop recording"
    } else {
      micSvg.setAttribute("fill", "#000000")
      this.recordingIndicatorTarget.classList.add('hidden')
      this.recordBtnTarget.classList.remove('bg-red-100', 'hover:bg-red-200')
      this.recordBtnTarget.classList.add('bg-gray-200', 'hover:bg-indigo-100')
      this.recordBtnTarget.title = "Record voice message"
    }
  }

  updateDurationDisplay(seconds) {
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = Math.floor(seconds % 60)
    this.durationTarget.textContent = `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
  }

  showError(message) {
    // You could integrate with your flash message system here
    alert(message)
  }

  handleFormSubmit(event) {
    // Clean up on form submit
    if (this.isPlaying) {
      this.pausePlayback()
    }
    
    // Hide recording indicator
    this.recordingIndicatorTarget.classList.add('hidden')
    
    // Stop any ongoing recording
    if (this.mediaRecorder && this.mediaRecorder.state === "recording") {
      this.mediaRecorder.stop()
      this.updateRecordingUI(false)
    }
  }

  handleTurboSubmitEnd(event) {
    // Check if the form submission was successful
    const { success } = event.detail
    
    if (success) {
      // Clear the recording review after successful submission
      this.clearRecording()
      
      // Clear the text input as well
      if (this.hasTextInputTarget) {
        this.textInputTarget.value = ''
      }
      
      // Reset form to initial state
      this.resetForm()
    }
  }

  resetForm() {
    // Reset all form state to initial values
    this.audioBlob = null
    this.audioChunks = []
    this.recordingDuration = 0
    this.isPlaying = false
    
    // Hide recording review if visible
    if (this.hasRecordingReviewTarget) {
      this.recordingReviewTarget.classList.add('hidden')
    }
    
    // Reset send button
    if (this.hasSendBtnTarget) {
      this.sendBtnTarget.textContent = "Send"
      this.sendBtnTarget.classList.remove('bg-purple-600', 'hover:bg-purple-500')
      this.sendBtnTarget.classList.add('bg-indigo-600', 'hover:bg-indigo-500')
    }
  }

  disconnect() {
    // Clean up when controller is disconnected
    if (this.audioPlayerTarget && this.audioPlayerTarget.src) {
      URL.revokeObjectURL(this.audioPlayerTarget.src)
    }
    
    if (this.mediaRecorder && this.mediaRecorder.state === "recording") {
      this.mediaRecorder.stop()
    }
  }
}