import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.setupMutationObserver()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  setupMutationObserver() {
    this.observer = new MutationObserver(mutations => {
      this.scrollToBottom()
    })
    
    this.observer.observe(this.element, {
      childList: true,
      subtree: true
    })
  }

  scrollToBottom() {
    const container = this.element.closest('.overflow-y-auto')
    if (container) {
      container.scrollTop = container.scrollHeight
    }
  }
} 