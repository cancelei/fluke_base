import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundHide = this.hide.bind(this)
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
    this.menuTarget.classList.remove("hidden")
    document.addEventListener("click", this.boundHide)
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

  disconnect() {
    document.removeEventListener("click", this.boundHide)
  }
} 