import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  initialize() {
    this.handleClickOutside = this.handleClickOutside.bind(this);
  }

  connect() {
    console.log('Conversation controller connected');
    // Close sidebar when clicking outside on mobile
    document.addEventListener('click', this.handleClickOutside);
  }

  disconnect() {
    console.log('Conversation controller disconnected');
    document.removeEventListener('click', this.handleClickOutside);
  }

  toggleSidebar(event) {
    console.log('Toggle sidebar clicked');
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    
    if (!this.hasSidebarTarget || !this.hasOverlayTarget) {
      console.error('Missing required targets');
      return;
    }
    
    this.sidebarTarget.classList.toggle('translate-x-0');
    this.sidebarTarget.classList.toggle('-translate-x-full');
    this.overlayTarget.classList.toggle('hidden');
    
    // Toggle body overflow to prevent scrolling when sidebar is open
    if (this.overlayTarget.classList.contains('hidden')) {
      document.body.style.overflow = '';
    } else {
      document.body.style.overflow = 'hidden';
    }
  }

  closeSidebar(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.remove('translate-x-0');
      this.sidebarTarget.classList.add('-translate-x-full');
    }
    
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add('hidden');
    }
    
    document.body.style.overflow = '';
  }

  handleClickOutside(event) {
    if (!this.hasSidebarTarget || !this.hasOverlayTarget) return;
    
    const isClickInside = this.sidebarTarget.contains(event.target) || 
                         event.target.closest('#hamburger-btn') ||
                         event.target.closest('[data-action~="click->conversation#toggleSidebar"]');
    
    if (!this.overlayTarget.classList.contains('hidden')) {
      this.closeSidebar();
    }
  }

  selectConversation(event) {
    // Remove active class from all conversation items
    const allConversationItems = this.element.querySelectorAll('[data-conversation-id]');
    allConversationItems.forEach(item => {
      item.classList.remove('bg-indigo-200', 'text-white');
      item.classList.add('hover:bg-gray-50');
    });
    
    // Add active class to clicked conversation
    const clickedItem = event.currentTarget;
    clickedItem.classList.add('bg-indigo-200', 'text-white');
    clickedItem.classList.remove('hover:bg-gray-50');
    
    // Close sidebar on mobile after selection
    if (window.innerWidth < 768) {
      this.closeSidebar();
    }
  }
}