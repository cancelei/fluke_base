import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "chevron"]

  connect() {
    // Initialize any setup needed
  }

  toggleForm() {
    const form = this.formTarget
    const chevron = this.chevronTarget
    
    if (form.classList.contains('hidden')) {
      form.classList.remove('hidden')
      chevron.style.transform = 'rotate(180deg)'
    } else {
      form.classList.add('hidden')
      chevron.style.transform = 'rotate(0deg)'
      // Clear form when closing
      this.clearFormInputs()
    }
  }

  // Handle form submission success
  formSubmitted(event) {
    if (event.detail.success) {
      // Close the form after successful submission
      this.closeForm()
    }
  }

  closeForm() {
    const form = this.formTarget
    const chevron = this.chevronTarget
    
    form.classList.add('hidden')
    chevron.style.transform = 'rotate(0deg)'
    // Clear form when closing
    this.clearFormInputs()
  }

  clearFormInputs() {
    // Find the actual form element inside the target
    const formElement = this.formTarget.querySelector('form')
    if (formElement) {
      // Reset all form fields
      formElement.reset()
    }
  }

  // Handle real-time progress updates
  updateProgress(event) {
    // This can be used for live progress bar updates
    const { detail } = event
    if (detail.progressPercent) {
      const progressBars = document.querySelectorAll('[data-progress-bar]')
      progressBars.forEach(bar => {
        bar.style.width = `${detail.progressPercent}%`
      })
    }
  }
} 