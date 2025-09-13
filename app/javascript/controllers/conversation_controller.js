import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['sidebar', 'overlay'];

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

    // Check if click is inside sidebar or related elements
    this.sidebarTarget.contains(event.target) ||
                         event.target.closest('#hamburger-btn') ||
                         event.target.closest('[data-action~="click->conversation#toggleSidebar"]');

    if (!this.overlayTarget.classList.contains('hidden')) {
      this.closeSidebar();
    }
  }

  selectConversation(event) {
    this.markAsRead(event, this.element.dataset.conversationId);
    const allConversationItems = document.querySelectorAll('[data-conversation-id]');
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

  markAsRead(event, conversationId) {
    event.preventDefault();

    fetch(`/conversations/${conversationId}/mark_as_read`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name=\'csrf-token\']').getAttribute('content')
      },
      body: JSON.stringify({}) // send any required payload here
    })
      .then(response => {
        if (response.ok) {
          this.updateConversationIdInPath(conversationId);
        } else {
          console.error('Failed to mark as read');
        }
      })
      .catch(error => {
        console.error('Network error:', error);
      });
  }

  updateConversationIdInPath(newId) {
    const path = window.location.pathname;

    let updatedPath;
    if (path.match(/\/conversations\/\d+$/)) {
      // Case: /conversations/123 → replace ID
      updatedPath = path.replace(/(\/conversations\/)\d+$/, `$1${newId}`);
    } else if (path.match(/\/conversations\/?$/)) {
      // Case: /conversations or /conversations/ → just add ID
      updatedPath = `${path.replace(/\/$/, '')}/${newId}`;
    } else {
      // Else: append /conversations/:id to the end
      updatedPath = `${path.replace(/\/$/, '')}/conversations/${newId}`;
    }

    const newUrl = `${window.location.origin}${updatedPath}${window.location.search}`;
    window.location.href = newUrl;
  }
}
