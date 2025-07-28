import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "menuIcon", "closeIcon"]

  connect() {
    // Initialize the menu state
    this.mobileMenuTarget.classList.add("hidden")
    this.setupInitialState()
    
    // Bind event handlers
    this.handleClickOutside = this.handleClickOutside.bind(this)
    this.handleResize = this.handleResize.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    
    // Add event listeners
    document.addEventListener('click', this.handleClickOutside)
    window.addEventListener('resize', this.handleResize)
    document.addEventListener('keydown', this.handleKeydown)
    
    // Add click event listener to menu items for smooth closing
    this.addMenuItemListeners()
  }

  disconnect() {
    // Clean up all event listeners when controller is disconnected
    document.removeEventListener('click', this.handleClickOutside)
    window.removeEventListener('resize', this.handleResize)
    document.removeEventListener('keydown', this.handleKeydown)
    this.removeMenuItemListeners()
  }

  setupInitialState() {
    // Ensure proper initial icon states
    if (this.hasMenuIconTarget && this.hasCloseIconTarget) {
      this.menuIconTarget.classList.remove("hidden")
      this.closeIconTarget.classList.add("hidden")
    }

    // Set initial ARIA attributes
    const button = this.element.querySelector('[data-action*="toggleMobileMenu"]')
    if (button) {
      button.setAttribute("aria-expanded", "false")
    }
  }

  addMenuItemListeners() {
    // Add listeners to navigation links and buttons in mobile menu
    const menuItems = this.mobileMenuTarget.querySelectorAll('a, button[type="submit"]')
    menuItems.forEach(item => {
      item.addEventListener('click', this.handleMenuItemClick.bind(this))
    })
  }

  removeMenuItemListeners() {
    const menuItems = this.mobileMenuTarget.querySelectorAll('a, button[type="submit"]')
    menuItems.forEach(item => {
      item.removeEventListener('click', this.handleMenuItemClick.bind(this))
    })
  }

  handleMenuItemClick(event) {
    // Don't close immediately for external links or buttons that might need processing
    const link = event.target.closest('a, button')
    
    if (link) {
      // Add a small delay to ensure the action completes
      setTimeout(() => {
        this.closeMenu()
      }, 100)
    }
  }

  handleClickOutside(event) {
    const menu = this.mobileMenuTarget
    const button = this.element.querySelector('[data-action*="toggleMobileMenu"]')
    
    // If menu is visible and click is outside both menu and button, close the menu
    if (!menu.classList.contains("hidden") && 
        !menu.contains(event.target) && 
        !button.contains(event.target)) {
      this.closeMenu()
    }
  }

  closeMenu() {
    this.setMenuState(false)
  }

  openMenu() {
    this.setMenuState(true)
  }

  setMenuState(isOpen) {
    const menu = this.mobileMenuTarget
    const button = this.element.querySelector('[data-action*="toggleMobileMenu"]')

    if (isOpen) {
      // Open menu with animation
      menu.classList.remove("hidden")
      
      // Trigger animation after removing hidden class
      requestAnimationFrame(() => {
        menu.style.opacity = '0'
        menu.style.transform = 'translateY(-10px)'
        menu.style.transition = 'all 0.2s ease-out'
        
        requestAnimationFrame(() => {
          menu.style.opacity = '1'
          menu.style.transform = 'translateY(0)'
        })
      })

      // Update icons
      if (this.hasMenuIconTarget && this.hasCloseIconTarget) {
        this.menuIconTarget.classList.add("hidden")
        this.closeIconTarget.classList.remove("hidden")
      }

      // Update ARIA state
      if (button) {
        button.setAttribute("aria-expanded", "true")
      }

      // Prevent body scroll when menu is open
      document.body.style.overflow = 'hidden'

    } else {
      // Close menu with animation
      menu.style.opacity = '0'
      menu.style.transform = 'translateY(-10px)'
      
      setTimeout(() => {
        menu.classList.add("hidden")
        menu.style.opacity = ''
        menu.style.transform = ''
        menu.style.transition = ''
      }, 200)

      // Update icons
      if (this.hasMenuIconTarget && this.hasCloseIconTarget) {
        this.menuIconTarget.classList.remove("hidden")
        this.closeIconTarget.classList.add("hidden")
      }

      // Update ARIA state
      if (button) {
        button.setAttribute("aria-expanded", "false")
      }

      // Restore body scroll
      document.body.style.overflow = 'auto'
    }
  }

  toggleMobileMenu(event) {
    event.preventDefault()
    event.stopPropagation()

    const menu = this.mobileMenuTarget
    const isCurrentlyHidden = menu.classList.contains("hidden")

    this.setMenuState(isCurrentlyHidden)
  }

  // Handle window resize to ensure menu closes on desktop
  handleResize() {
    if (window.innerWidth >= 1024) { // lg breakpoint in Tailwind
      this.closeMenu()
    }
  }

  // Add support for keyboard navigation
  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.closeMenu()
    }
  }
} 