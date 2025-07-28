import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "subtitle", "cta", "trust"]

  connect() {
    this.animateElements()
  }

  animateElements() {
    // Animate elements with staggered delays
    const elements = [
      { target: this.titleTarget, delay: 0 },
      { target: this.subtitleTarget, delay: 200 },
      { target: this.ctaTarget, delay: 400 },
      { target: this.trustTarget, delay: 600 }
    ]

    elements.forEach(({ target, delay }) => {
      setTimeout(() => {
        target.style.opacity = '0'
        target.style.transform = 'translateY(30px)'
        target.style.transition = 'all 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
        
        requestAnimationFrame(() => {
          target.style.opacity = '1'
          target.style.transform = 'translateY(0)'
        })
      }, delay)
    })
  }

  playDemo(event) {
    event.preventDefault()
    // This could open a modal or navigate to a demo video
    console.log("Playing demo video...")
    
    // Example: Create a simple modal for demo
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-75'
    modal.innerHTML = `
      <div class="bg-white rounded-2xl p-8 max-w-2xl mx-4">
        <div class="flex justify-between items-center mb-6">
          <h3 class="text-2xl font-bold">FlukeBase Demo</h3>
          <button class="text-gray-500 hover:text-gray-700" data-action="click->hero-animation#closeDemo">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>
        <div class="aspect-video bg-gray-100 rounded-lg flex items-center justify-center mb-6">
          <div class="text-center">
            <div class="w-16 h-16 bg-blue-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg class="w-8 h-8 text-white" fill="currentColor" viewBox="0 0 20 20">
                <path d="M8 5v10l8-5-8-5z"/>
              </svg>
            </div>
            <p class="text-gray-600">Demo video would play here</p>
          </div>
        </div>
        <p class="text-gray-600 text-center">
          See how FlukeBase connects entrepreneurs, mentors, and co-founders in just 2 minutes.
        </p>
      </div>
    `
    
    document.body.appendChild(modal)
    document.body.style.overflow = 'hidden'
  }

  closeDemo(event) {
    const modal = event.target.closest('.fixed')
    if (modal) {
      document.body.removeChild(modal)
      document.body.style.overflow = 'auto'
    }
  }
} 