import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playBtn", "playIcon", "pauseIcon", "progress", "duration", "currentTime", "waveform"]
  static values = { src: String }

  connect() {
    this.isPlaying = false
    this.duration = 0
    this.currentTime = 0
    this.waveformBars = []
    
    // Add a small delay to ensure DOM is fully rendered
    setTimeout(() => {
      this.setupAudio()
      this.generateWaveform()
    }, 100)
  }

  setupAudio() {
    if (this.hasAudioTarget) {
      // Add event listeners
      this.audioTarget.addEventListener('loadedmetadata', this.onLoadedMetadata.bind(this))
      this.audioTarget.addEventListener('timeupdate', this.onTimeUpdate.bind(this))
      this.audioTarget.addEventListener('ended', this.onAudioEnded.bind(this))
      this.audioTarget.addEventListener('error', this.onAudioError.bind(this))
      this.audioTarget.addEventListener('canplay', this.onCanPlay.bind(this))
      this.audioTarget.addEventListener('loadstart', this.onLoadStart.bind(this))
      
      // Set the source if provided via data attribute
      if (this.srcValue) {
        console.log('Setting audio source:', this.srcValue)
        this.audioTarget.src = this.srcValue
        this.audioTarget.load() // Force load the audio
      }
    } else {
      console.error('Audio target not found for audio player controller')
    }
  }

  onLoadStart() {
    console.log('Audio loading started')
  }

  onCanPlay() {
    console.log('Audio can play')
  }

  onLoadedMetadata() {
    this.duration = this.audioTarget.duration
    console.log('Audio metadata loaded, duration:', this.duration)
    this.updateDurationDisplay()
  }

  onTimeUpdate() {
    this.currentTime = this.audioTarget.currentTime
    this.updateProgress()
    this.updateCurrentTimeDisplay()
  }

  onAudioEnded() {
    this.isPlaying = false
    this.updatePlayButton()
    this.audioTarget.currentTime = 0
    this.currentTime = 0
    this.updateProgress()
    this.updateCurrentTimeDisplay()
  }

  onAudioError(event) {
    console.error('Audio playback error:', event)
    console.error('Audio error details:', {
      error: this.audioTarget.error,
      networkState: this.audioTarget.networkState,
      readyState: this.audioTarget.readyState,
      src: this.audioTarget.src
    })
    this.showError('Unable to play audio')
  }

  togglePlayback() {
    if (this.isPlaying) {
      this.pause()
    } else {
      this.play()
    }
  }

  play() {
    const playPromise = this.audioTarget.play()
    
    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          this.isPlaying = true
          this.updatePlayButton()
          this.animateWaveform()
        })
        .catch(error => {
          console.error('Playback failed:', error)
          this.showError('Playback failed')
        })
    }
  }

  pause() {
    this.audioTarget.pause()
    this.isPlaying = false
    this.updatePlayButton()
  }

  updatePlayButton() {
    if (this.hasPlayIconTarget && this.hasPauseIconTarget) {
      if (this.isPlaying) {
        this.playIconTarget.classList.add('hidden')
        this.pauseIconTarget.classList.remove('hidden')
      } else {
        this.playIconTarget.classList.remove('hidden')
        this.pauseIconTarget.classList.add('hidden')
      }
    }
  }

  updateProgress() {
    if (this.hasProgressTarget && this.duration > 0) {
      const percentage = (this.currentTime / this.duration) * 100
      this.progressTarget.style.width = `${percentage}%`
    }
  }

  updateDurationDisplay() {
    if (this.hasDurationTarget) {
      this.durationTarget.textContent = this.formatTime(this.duration)
    }
  }

  updateCurrentTimeDisplay() {
    if (this.hasCurrentTimeTarget) {
      this.currentTimeTarget.textContent = this.formatTime(this.currentTime)
    }
  }

  formatTime(seconds) {
    if (isNaN(seconds)) return "0:00"
    
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = Math.floor(seconds % 60)
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
  }

  generateWaveform() {
    if (!this.hasWaveformTarget) {
      console.warn('Waveform target not found')
      return
    }
    
    const waveformContainer = this.waveformTarget
    waveformContainer.innerHTML = ''
    
    // Generate random heights for waveform bars (in a real app, you'd analyze the audio)
    const barCount = 30
    this.waveformBars = []
    
    for (let i = 0; i < barCount; i++) {
      const bar = document.createElement('div')
      const height = Math.random() * 16 + 2 // Random height between 2-18px
      bar.className = 'bg-current opacity-40 rounded-full transition-all duration-200'
      bar.style.width = '2px'
      bar.style.height = `${height}px`
      this.waveformBars.push(bar)
      waveformContainer.appendChild(bar)
    }
    
    console.log('Generated waveform with', this.waveformBars.length, 'bars')
  }

  animateWaveform() {
    if (!this.isPlaying || !this.waveformBars.length) return
    
    // Animate waveform bars during playback
    this.waveformBars.forEach((bar, index) => {
      const delay = index * 30 // Stagger animation
      setTimeout(() => {
        if (this.isPlaying && bar) {
          bar.classList.remove('opacity-40')
          bar.classList.add('opacity-100')
          setTimeout(() => {
            if (bar) {
              bar.classList.add('opacity-40')
              bar.classList.remove('opacity-100')
            }
          }, 150)
        }
      }, delay)
    })
    
    // Continue animation if still playing
    if (this.isPlaying) {
      setTimeout(() => this.animateWaveform(), this.waveformBars.length * 30 + 300)
    }
  }

  showError(message) {
    console.error('Audio Player Error:', message)
    // You could integrate with your flash message system here
  }

  disconnect() {
    if (this.hasAudioTarget) {
      this.audioTarget.removeEventListener('loadedmetadata', this.onLoadedMetadata)
      this.audioTarget.removeEventListener('timeupdate', this.onTimeUpdate)
      this.audioTarget.removeEventListener('ended', this.onAudioEnded)
      this.audioTarget.removeEventListener('error', this.onAudioError)
    }
  }
}
