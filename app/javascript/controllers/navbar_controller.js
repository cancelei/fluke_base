import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu"]

  connect() {
    // Initialize the menu state
    this.mobileMenuTarget.classList.add("hidden")
    
    // Add click event listener to document to close menu when clicking outside
    document.addEventListener('click', this.handleClickOutside.bind(this))
    
    // Add click event listener to menu items
    this.mobileMenuTarget.querySelectorAll('a, button').forEach(item => {
      item.addEventListener('click', this.closeMenu.bind(this))
    })
  }

  disconnect() {
    // Clean up event listeners when controller is disconnected
    document.removeEventListener('click', this.handleClickOutside.bind(this))
    
    // Clean up menu item click listeners
    this.mobileMenuTarget.querySelectorAll('a, button').forEach(item => {
      item.removeEventListener('click', this.closeMenu.bind(this))
    })
  }

  handleClickOutside(event) {
    const menu = this.mobileMenuTarget
    const button = this.element.querySelector('[aria-controls="mobile-menu"]')
    
    // If click is outside both menu and button, close the menu
    if (!menu.contains(event.target) && !button.contains(event.target)) {
      this.closeMenu()
    }
  }

  closeMenu() {
    const menu = this.mobileMenuTarget
    const button = this.element.querySelector('[aria-controls="mobile-menu"]')
    const openIcon = button.querySelector('svg:first-of-type')
    const closeIcon = button.querySelector('svg:last-of-type')
    
    // Close menu
    menu.classList.add("hidden")
    
    // Update button state
    button.setAttribute("aria-expanded", "false")
    
    // Update icons - show hamburger, hide X
    openIcon.classList.remove("hidden")
    closeIcon.classList.add("hidden")
  }

  toggleMobileMenu(event) {
    const menu = this.mobileMenuTarget
    const button = event.currentTarget
    const openIcon = button.querySelector('svg:first-of-type')
    const closeIcon = button.querySelector('svg:last-of-type')
    
    // Toggle menu visibility
    const isHidden = menu.classList.contains("hidden")
    menu.classList.toggle("hidden")
    
    // Toggle button state
    button.setAttribute("aria-expanded", isHidden)
    
    // Toggle icons - if menu is opening, show X and hide hamburger
    if (isHidden) {
      openIcon.classList.add("hidden")
      closeIcon.classList.remove("hidden")
    } else {
      openIcon.classList.remove("hidden")
      closeIcon.classList.add("hidden")
    }
  }
} 