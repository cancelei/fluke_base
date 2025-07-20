import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["carousel", "dot"]

  connect() {
    this.currentSlide = 0
    this.totalSlides = 3 // Adjust based on your testimonial sets
    this.autoRotateInterval = null
    
    this.setupAutoRotation()
    this.updateDots()
  }

  disconnect() {
    this.stopAutoRotation()
  }

  setupAutoRotation() {
    this.autoRotateInterval = setInterval(() => {
      this.nextSlide()
    }, 6000) // Change slide every 6 seconds
  }

  stopAutoRotation() {
    if (this.autoRotateInterval) {
      clearInterval(this.autoRotateInterval)
      this.autoRotateInterval = null
    }
  }

  restartAutoRotation() {
    this.stopAutoRotation()
    this.setupAutoRotation()
  }

  showSlide(event) {
    const slideIndex = parseInt(event.target.dataset.slide)
    
    if (slideIndex !== this.currentSlide) {
      this.currentSlide = slideIndex
      this.updateCarousel()
      this.updateDots()
      this.restartAutoRotation()
    }
  }

  nextSlide() {
    this.currentSlide = (this.currentSlide + 1) % this.totalSlides
    this.updateCarousel()
    this.updateDots()
  }

  updateCarousel() {
    if (this.hasCarouselTarget) {
      const translateX = -this.currentSlide * 100
      this.carouselTarget.style.transform = `translateX(${translateX}%)`
    }
  }

  updateDots() {
    this.dotTargets.forEach((dot, index) => {
      if (index === this.currentSlide) {
        dot.classList.remove('bg-gray-300', 'hover:bg-gray-400')
        dot.classList.add('bg-blue-500')
      } else {
        dot.classList.remove('bg-blue-500')
        dot.classList.add('bg-gray-300', 'hover:bg-gray-400')
      }
    })
  }

  // Mouse events to pause/resume auto-rotation
  mouseEnter() {
    this.stopAutoRotation()
  }

  mouseLeave() {
    this.setupAutoRotation()
  }
} 