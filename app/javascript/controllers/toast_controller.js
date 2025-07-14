import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toast"]
  static values = {
    autoDismiss: { type: Boolean, default: true },
    duration: { type: Number, default: 5000 }
  }

  connect() {
    if (this.autoDismissValue) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, this.durationValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    // Start fade out animation
    this.element.classList.remove('animate-fade-in-up')
    this.element.classList.add('animate-fade-out-down')
    
    // Remove the element after the animation completes
    setTimeout(() => {
      this.element.remove()
      
      // If this was the last toast, remove the container
      const container = document.getElementById('toast-container')
      if (container && container.children.length === 0) {
        container.remove()
      }
    }, 300)
  }
}

// Helper function to show a toast
window.showToast = function(message, type = 'notice') {
  // Create toast container if it doesn't exist
  let container = document.getElementById('toast-container')
  if (!container) {
    container = document.createElement('div')
    container.id = 'toast-container'
    container.className = 'fixed top-4 right-4 z-50 space-y-2 w-full max-w-xs'
    document.body.appendChild(container)
  }

  // Map types to Tailwind classes
  const typeClasses = {
    notice: 'bg-green-500',
    alert: 'bg-red-500',
    info: 'bg-blue-500',
    warning: 'bg-yellow-500'
  }

  // Create toast element
  const toast = document.createElement('div')
  toast.className = `rounded-lg p-4 text-white shadow-lg ${typeClasses[type] || typeClasses.notice} animate-fade-in-up`
  toast.setAttribute('data-controller', 'toast')
  toast.setAttribute('data-toast-auto-dismiss-value', 'true')
  toast.setAttribute('data-action', 'click->toast#dismiss')
  
  // Add message
  const messageEl = document.createElement('div')
  messageEl.className = 'flex items-center justify-between'
  messageEl.innerHTML = `
    <span>${message}</span>
    <button class="ml-4 text-white hover:text-gray-200 focus:outline-none" data-action="click->toast#dismiss">
      <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>
    </button>
  `
  
  toast.appendChild(messageEl)
  
  // Add to container
  container.appendChild(toast)
  
  // Trigger reflow to enable animation
  setTimeout(() => {
    toast.classList.remove('opacity-0', '-translate-y-2')
    toast.classList.add('opacity-100', 'translate-y-0')
  }, 10)
}
