import { Controller } from '@hotwired/stimulus';

// Simplified conversation controller - sidebar toggle now handled by DaisyUI drawer
export default class extends Controller {
  connect() {
    window.FlukeLogger?.controllerLifecycle(
      'ConversationController',
      'connected',
      {
        element: this.element.tagName
      }
    );
  }

  disconnect() {
    window.FlukeLogger?.controllerLifecycle(
      'ConversationController',
      'disconnected'
    );
  }

  selectConversation(event) {
    this.markAsRead(event, this.element.dataset.conversationId);
    const allConversationItems = document.querySelectorAll(
      '[data-conversation-id]'
    );

    allConversationItems.forEach(item => {
      item.classList.remove('bg-primary/20', 'text-primary');
      item.classList.add('hover:bg-base-200');
    });

    // Add active class to clicked conversation
    const clickedItem = event.currentTarget;

    clickedItem.classList.add('bg-primary/20', 'text-primary');
    clickedItem.classList.remove('hover:bg-base-200');

    // Close drawer on mobile after selection (DaisyUI drawer)
    if (window.innerWidth < 1024) {
      // lg breakpoint
      const drawerToggle = document.getElementById('conversation-drawer');

      if (drawerToggle) {
        drawerToggle.checked = false;
      }
    }
  }

  markAsRead(event, conversationId) {
    event.preventDefault();

    fetch(`/conversations/${conversationId}/mark_as_read`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document
          .querySelector("meta[name='csrf-token']")
          .getAttribute('content')
      },
      body: JSON.stringify({})
    })
      .then(response => {
        if (response.ok) {
          this.updateConversationIdInPath(conversationId);
        } else {
          window.FlukeLogger?.error(
            'ConversationController',
            new Error('Failed to mark as read'),
            {
              action: 'markAsRead',
              status: response.status
            }
          );
        }
      })
      .catch(error => {
        window.FlukeLogger?.error('ConversationController', error, {
          action: 'markAsRead'
        });
      });
  }

  updateConversationIdInPath(newId) {
    const path = window.location.pathname;

    let updatedPath = path;

    if (path.match(/\/conversations\/\d+$/u)) {
      // Case: /conversations/123 → replace ID
      updatedPath = path.replace(/(\/conversations\/)\d+$/u, `$1${newId}`);
    } else if (path.match(/\/conversations\/?$/u)) {
      // Case: /conversations or /conversations/ → just add ID
      updatedPath = `${path.replace(/\/$/u, '')}/${newId}`;
    } else {
      // Else: append /conversations/:id to the end
      updatedPath = `${path.replace(/\/$/u, '')}/conversations/${newId}`;
    }

    const newUrl = `${window.location.origin}${updatedPath}${window.location.search}`;

    window.location.href = newUrl;
  }
}
