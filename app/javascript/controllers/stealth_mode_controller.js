import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="stealth-mode"
export default class extends Controller {
  static targets = ["toggle", "customization"]

  connect() {
    // Initialize form visibility based on current stealth mode state
    this.updateFormVisibility()
  }

  toggle(event) {
    this.updateFormVisibility()
  }

  updateFormVisibility() {
    const isStealthMode = this.hasToggleTarget ? this.toggleTarget.checked : false
    const mainForm = document.getElementById('main-project-form')
    const stealthSummary = document.getElementById('stealth-mode-summary')

    // Toggle customization section
    if (this.hasCustomizationTarget) {
      this.customizationTarget.classList.toggle('hidden', !isStealthMode)
    }

    // Toggle main form visibility
    if (mainForm) {
      mainForm.classList.toggle('hidden', isStealthMode)
    }

    // Toggle stealth summary visibility
    if (stealthSummary) {
      stealthSummary.classList.toggle('hidden', !isStealthMode)
    }
  }

  showFullForm(event) {
    event.preventDefault()

    const mainForm = document.getElementById('main-project-form')
    const stealthSummary = document.getElementById('stealth-mode-summary')

    if (mainForm) {
      mainForm.classList.remove('hidden')

      if (stealthSummary) {
        stealthSummary.classList.add('hidden')
      }

      // Update button state
      const button = event.target
      button.textContent = 'Hide Full Form'
      button.classList.add('bg-gray-600', 'hover:bg-gray-700')
      button.classList.remove('bg-blue-600', 'hover:bg-blue-700')

      // Change action to hide form
      button.setAttribute('data-action', 'click->stealth-mode#hideFullForm')
    }
  }

  hideFullForm(event) {
    event.preventDefault()

    const mainForm = document.getElementById('main-project-form')
    const stealthSummary = document.getElementById('stealth-mode-summary')
    const isStealthMode = this.hasToggleTarget && this.toggleTarget.checked

    if (mainForm && isStealthMode) {
      mainForm.classList.add('hidden')

      if (stealthSummary) {
        stealthSummary.classList.remove('hidden')
      }

      // Update button state
      const button = event.target
      button.textContent = 'Show Full Form'
      button.classList.add('bg-blue-600', 'hover:bg-blue-700')
      button.classList.remove('bg-gray-600', 'hover:bg-gray-700')

      // Change action back to show form
      button.setAttribute('data-action', 'click->stealth-mode#showFullForm')
    }
  }
}