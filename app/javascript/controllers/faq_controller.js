import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "trigger", "content", "icon"]

  connect() {
    // Initialize all content as hidden
    this.contentTargets.forEach(content => {
      content.style.display = 'none'
      content.style.maxHeight = '0'
      content.style.overflow = 'hidden'
      content.style.transition = 'all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94)'
    })
  }

  toggle(event) {
    const clickedTrigger = event.currentTarget
    const parentItem = clickedTrigger.closest('[data-faq-target="item"]')
    const content = parentItem.querySelector('[data-faq-target="content"]')
    const icon = parentItem.querySelector('[data-faq-target="icon"]')
    
    const isCurrentlyOpen = !content.classList.contains('hidden')
    
    // Close all other items
    this.closeAllExcept(parentItem)
    
    if (isCurrentlyOpen) {
      this.closeItem(content, icon)
    } else {
      this.openItem(content, icon)
    }
  }

  closeAllExcept(exceptItem) {
    this.itemTargets.forEach(item => {
      if (item !== exceptItem) {
        const content = item.querySelector('[data-faq-target="content"]')
        const icon = item.querySelector('[data-faq-target="icon"]')
        
        if (content && !content.classList.contains('hidden')) {
          this.closeItem(content, icon)
        }
      }
    })
  }

  openItem(content, icon) {
    // Remove hidden class first
    content.classList.remove('hidden')
    content.style.display = 'block'
    
    // Get the natural height
    const naturalHeight = content.scrollHeight
    
    // Animate from 0 to natural height
    content.style.maxHeight = '0px'
    requestAnimationFrame(() => {
      content.style.maxHeight = naturalHeight + 'px'
    })
    
    // Rotate icon
    if (icon) {
      icon.style.transform = 'rotate(180deg)'
    }
    
    // Add some visual feedback to the trigger
    const trigger = content.parentElement.querySelector('[data-faq-target="trigger"]')
    if (trigger) {
      trigger.classList.add('text-blue-600')
    }
  }

  closeItem(content, icon) {
    // Animate to 0 height
    content.style.maxHeight = '0px'
    
    // Hide after animation
    setTimeout(() => {
      content.classList.add('hidden')
      content.style.display = 'none'
    }, 300)
    
    // Rotate icon back
    if (icon) {
      icon.style.transform = 'rotate(0deg)'
    }
    
    // Remove visual feedback from trigger
    const trigger = content.parentElement.querySelector('[data-faq-target="trigger"]')
    if (trigger) {
      trigger.classList.remove('text-blue-600')
    }
  }
} 