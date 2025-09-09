import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundHide = this.hide.bind(this)
    this.boundCloseOthers = this.closeOthers.bind(this)
    document.addEventListener("dropdown:opened", this.boundCloseOthers)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    
    if (this.menuTarget.classList.contains("hidden")) {
      this.show()
    } else {
      this.hideMenu()
    }
  }

  show() {
    // Close all other dropdowns first
    this.closeAllDropdowns()
    
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.boundHide)
    
    // Dispatch event for coordination with other dropdowns
    document.dispatchEvent(new CustomEvent("dropdown:opened", { 
      detail: { controller: this } 
    }))
  }

  hideMenu() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundHide)
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.hideMenu()
    }
  }

  closeOthers(event) {
    if (event.detail.controller !== this) {
      this.hideMenu()
    }
  }

  closeAllDropdowns() {
    // Close all other dropdown controllers
    const allDropdowns = document.querySelectorAll('[data-controller*="dropdown"]')
    allDropdowns.forEach(dropdown => {
      if (dropdown !== this.element) {
        const controller = this.application.getControllerForElementAndIdentifier(dropdown, "dropdown")
        if (controller && !controller.menuTarget.classList.contains("hidden")) {
          controller.hideMenu()
        }
      }
    })
  }

  disconnect() {
    document.removeEventListener("click", this.boundHide)
    document.removeEventListener("dropdown:opened", this.boundCloseOthers)
  }
} 