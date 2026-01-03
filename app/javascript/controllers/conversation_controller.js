import { Controller } from '@hotwired/stimulus';
import { qsa } from '../utils/dom';
import { createLogger } from '../utils/logger';
import { jsonFetch } from '../utils/network';
import {
  logConnect,
  logDisconnect,
  safeAsync
} from '../utils/stimulus_helpers';

const logger = window.FlukeLogger || createLogger('FlukeBase');

// Simplified conversation controller - sidebar toggle now handled by DaisyUI drawer
export default class extends Controller {
  connect() {
    logConnect(logger, 'ConversationController', this);
  }

  disconnect() {
    logDisconnect(logger, 'ConversationController');
  }

  selectConversation(event) {
    this.markAsRead(event, this.element.dataset.conversationId);
    const allConversationItems = qsa(document, '[data-conversation-id]');

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

  async markAsRead(event, conversationId) {
    event?.preventDefault();

    await safeAsync(
      async () => {
        await jsonFetch(`/conversations/${conversationId}/mark_as_read`, {
          method: 'POST',
          body: JSON.stringify({})
        });
        this.updateConversationIdInPath(conversationId);
      },
      {
        onError: error => {
          logger?.error('ConversationController', error, {
            action: 'markAsRead',
            conversationId
          });
        }
      }
    );
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
