import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["recordBtn", "micIcon", "recordingIndicator", "audioInput", "form"]

  connect() {
    this.mediaRecorder = null
    this.audioChunks = []
    if (this.hasRecordBtnTarget) {
      this.recordBtnTarget.addEventListener('click', this.handleRecording.bind(this))
    }
    if (this.hasFormTarget) {
      this.formTarget.addEventListener('submit', this.handleFormSubmit.bind(this))
    }
  }

  async handleRecording(event) {
    if (!this.mediaRecorder || this.mediaRecorder.state === "inactive") {
      // Start recording
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        try {
          const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
          this.mediaRecorder = new MediaRecorder(stream)
          this.audioChunks = []
          this.mediaRecorder.ondataavailable = e => {
            if (e.data.size > 0) this.audioChunks.push(e.data)
          }
          this.mediaRecorder.onstop = async () => {
            const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' })
            const file = new File([audioBlob], "voice-message.webm", { type: 'audio/webm' })
            const dt = new DataTransfer()
            dt.items.add(file)
            this.audioInputTarget.files = dt.files
            this.recordingIndicatorTarget.textContent = "Voice message ready. Click Send."
            this.recordingIndicatorTarget.classList.remove('hidden')
          }
          this.mediaRecorder.start()
          this.micIconTarget.querySelector("svg").setAttribute("fill", "red");
          this.recordingIndicatorTarget.textContent = "Recording..."
          this.recordingIndicatorTarget.classList.remove('hidden')
        } catch (err) {
          alert("Microphone access denied.")
        }
      }
    } else if (this.mediaRecorder.state === "recording") {
      // Stop recording
      this.mediaRecorder.stop()
      this.micIconTarget.querySelector("svg").setAttribute("fill", "#000000");
    }
  }

  async handleFormSubmit() {
    this.recordingIndicatorTarget.classList.add('hidden')
    if (this.mediaRecorder && this.mediaRecorder.state === "recording") {
      this.mediaRecorder.stop()
      this.micIconTarget.querySelector("svg").setAttribute("fill", "#000000");
    }
  }
}