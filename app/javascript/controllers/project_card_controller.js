import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="project-card"
export default class extends Controller {
  static targets = ["card", "loadingIndicator"]
  static classes = ["loading"]

  connect() {
    this.setupHoverEffects()
    this.setupKeyboardNavigation()
  }

  // Enhanced hover effects with subtle animations
  setupHoverEffects() {
    const card = this.element.querySelector('.cursor-pointer')
    if (!card) return

    card.addEventListener('mouseenter', () => {
      this.addHoverState()
    })

    card.addEventListener('mouseleave', () => {
      this.removeHoverState()
    })
  }

  // Keyboard navigation support
  setupKeyboardNavigation() {
    const primaryLink = this.element.querySelector('[aria-label*="View"]')
    if (!primaryLink) return

    // Make the entire card focusable
    const card = this.element.querySelector('.cursor-pointer')
    if (card) {
      card.setAttribute('tabindex', '0')
      card.setAttribute('role', 'button')
      card.setAttribute('aria-label', primaryLink.getAttribute('aria-label'))

      card.addEventListener('keydown', (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault()
          primaryLink.click()
        }
      })
    }
  }

  // Add loading state when navigating
  navigate(event) {
    const target = event.currentTarget
    this.showLoadingState(target)
  }

  // Enhanced loading state with visual feedback
  showLoadingState(element) {
    if (!element) return

    // Add loading class
    element.classList.add('opacity-75', 'pointer-events-none')

    // Create loading spinner
    const spinner = document.createElement('div')
    spinner.innerHTML = `
      <div class="inline-flex items-center">
        <svg class="animate-spin h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        Loading...
      </div>
    `

    // Replace button content temporarily
    const originalContent = element.innerHTML
    element.innerHTML = spinner.innerHTML

    // Restore after 2 seconds (fallback)
    setTimeout(() => {
      element.innerHTML = originalContent
      element.classList.remove('opacity-75', 'pointer-events-none')
    }, 2000)
  }

  // Enhanced hover state management
  addHoverState() {
    const card = this.element.querySelector('.cursor-pointer')
    if (!card) return

    // Add subtle glow effect
    card.style.setProperty('--tw-ring-shadow', '0 0 0 1px rgb(59 130 246 / 0.3)')
    card.style.setProperty('--tw-ring-offset-shadow', '0 0 0 0 transparent')
    card.style.boxShadow = 'var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow, 0 0 #0000)'
  }

  removeHoverState() {
    const card = this.element.querySelector('.cursor-pointer')
    if (!card) return

    // Remove glow effect
    card.style.removeProperty('--tw-ring-shadow')
    card.style.removeProperty('--tw-ring-offset-shadow')
    card.style.removeProperty('box-shadow')
  }

  // Copy project link to clipboard
  async copyLink(event) {
    event.preventDefault()
    event.stopPropagation()

    const projectId = this.element.dataset.projectId
    const baseUrl = window.location.origin
    const projectUrl = `${baseUrl}/projects/${projectId}`

    try {
      await navigator.clipboard.writeText(projectUrl)
      this.showToast('Project link copied to clipboard!', 'success')
    } catch {
      // Fallback for older browsers
      this.fallbackCopyToClipboard(projectUrl)
    }
  }

  // Fallback clipboard method
  fallbackCopyToClipboard(text) {
    const textArea = document.createElement('textarea')
    textArea.value = text
    textArea.style.position = 'fixed'
    textArea.style.left = '-999999px'
    textArea.style.top = '-999999px'
    document.body.appendChild(textArea)
    textArea.focus()
    textArea.select()

    try {
      document.execCommand('copy')
      this.showToast('Project link copied to clipboard!', 'success')
    } catch {
      this.showToast('Failed to copy link', 'error')
    }

    document.body.removeChild(textArea)
  }

  // Show toast notification
  showToast(message, type = 'info') {
    // Create toast element
    const toast = document.createElement('div')
    toast.className = `fixed top-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg text-white text-sm font-medium transition-all duration-300 transform translate-y-0 ${
      type === 'success' ? 'bg-green-600' :
      type === 'error' ? 'bg-red-600' :
      'bg-blue-600'
    }`
    toast.textContent = message

    document.body.appendChild(toast)

    // Animate in
    setTimeout(() => {
      toast.classList.add('translate-y-0')
    }, 10)

    // Animate out and remove
    setTimeout(() => {
      toast.classList.add('translate-y-[-100%]', 'opacity-0')
      setTimeout(() => {
        if (document.body.contains(toast)) {
          document.body.removeChild(toast)
        }
      }, 300)
    }, 3000)
  }

  // Quick preview functionality (expandable)
  togglePreview(event) {
    event.preventDefault()
    event.stopPropagation()

    const previewElement = this.element.querySelector('[data-project-card-target="preview"]')
    if (!previewElement) return

    const isExpanded = previewElement.style.display !== 'none'

    if (isExpanded) {
      this.collapsePreview(previewElement)
    } else {
      this.expandPreview(previewElement)
    }
  }

  expandPreview(element) {
    element.style.display = 'block'
    element.style.maxHeight = '0px'
    element.style.overflow = 'hidden'
    element.style.transition = 'max-height 0.3s ease-out'

    setTimeout(() => {
      element.style.maxHeight = '200px'
    }, 10)
  }

  collapsePreview(element) {
    element.style.maxHeight = '0px'

    setTimeout(() => {
      element.style.display = 'none'
    }, 300)
  }

  disconnect() {
    // Cleanup any event listeners or timers if needed
  }
}