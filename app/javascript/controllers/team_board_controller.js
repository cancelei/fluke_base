import { Controller } from '@hotwired/stimulus';
import consumer from '../channels/consumer';
import { createLogger } from '../utils/logger';
import { jsonFetch } from '../utils/network';
import {
  logConnect,
  logDisconnect,
  safeAsync
} from '../utils/stimulus_helpers';

const logger = window.FlukeLogger || createLogger('FlukeBase');

/**
 * Team Board Controller
 * Handles real-time updates for the WeDo task board via ActionCable WebSocket.
 * Manages connection status, task updates, drag & drop, and modal interactions.
 */
export default class extends Controller {
  static values = {
    projectId: Number
  };

  static targets = [
    'connectionStatus',
    'pendingColumn',
    'inProgressColumn',
    'blockedColumn',
    'completedColumn',
    'modal',
    'modalContent'
  ];

  connect() {
    logConnect(logger, 'TeamBoardController', this, {
      projectId: this.projectIdValue
    });

    this.subscribeToChannel();
    this.setupDragAndDrop();
  }

  disconnect() {
    logDisconnect(logger, 'TeamBoardController');

    if (this.subscription) {
      this.subscription.unsubscribe();
    }
  }

  /**
   * Subscribe to the TeamBoardChannel for real-time updates
   */
  subscribeToChannel() {
    if (!this.hasProjectIdValue) {
      logger?.warning('Team Board', 'No project ID provided');

      return;
    }

    this.subscription = consumer.subscriptions.create(
      // eslint-disable-next-line camelcase
      { channel: 'TeamBoardChannel', project_id: this.projectIdValue },
      {
        connected: () => this.handleConnected(),
        disconnected: () => this.handleDisconnected(),
        received: data => this.handleReceived(data)
      }
    );
  }

  /**
   * Handle successful WebSocket connection
   */
  handleConnected() {
    if (this.hasConnectionStatusTarget) {
      this.connectionStatusTarget.innerHTML = `
        <span class="inline-block w-2 h-2 bg-success rounded-full"></span>
        Connected
      `;
      this.connectionStatusTarget.classList.remove('badge-outline');
      this.connectionStatusTarget.classList.add('badge-success');
    }
    logger?.websocketEvent('TeamBoardChannel', 'connected');
  }

  /**
   * Handle WebSocket disconnection
   */
  handleDisconnected() {
    if (this.hasConnectionStatusTarget) {
      this.connectionStatusTarget.innerHTML = `
        <span class="inline-block w-2 h-2 bg-error rounded-full animate-pulse"></span>
        Disconnected
      `;
      this.connectionStatusTarget.classList.remove('badge-success');
      this.connectionStatusTarget.classList.add('badge-error');
    }
    logger?.websocketEvent('TeamBoardChannel', 'disconnected');
  }

  /**
   * Handle incoming WebSocket messages
   * @param {Object} data - The message data
   */
  handleReceived(data) {
    logger?.websocketEvent('TeamBoardChannel', 'received', { type: data.type });

    switch (data.type) {
      case 'connected':
        // Initial connection confirmation
        break;

      case 'task.created':
        this.handleTaskCreated(data.task);
        break;

      case 'task.updated':
      case 'task.status_changed':
        this.handleTaskUpdated(data.task);
        break;

      case 'conflict':
        this.handleConflict(data);
        break;

      case 'sync.response':
        this.handleSyncResponse(data);
        break;

      case 'pong':
        // Heartbeat response
        break;

      default:
        logger?.warning('Team Board', 'Unknown message type', {
          type: data.type
        });
    }
  }

  /**
   * Handle new task created event
   * @param {Object} task - The task data
   */
  handleTaskCreated(task) {
    // Reload the page to get the new task card rendered server-side
    // A more sophisticated approach would be to append the task via Turbo Stream
    window.Turbo.visit(window.location.href, { action: 'replace' });

    // Show toast notification
    this.showToast(`New task created: ${task.task_id}`, 'success');
  }

  /**
   * Handle task updated event
   * @param {Object} task - The updated task data
   */
  handleTaskUpdated(task) {
    // Find the task card and update it, or move it to new column if status changed
    const taskCard = document.querySelector(`[data-task-id="${task.task_id}"]`);

    if (taskCard) {
      // Get the current column
      const currentColumn = taskCard.closest('[id^="column-"]');
      const currentStatus = currentColumn?.id.replace('column-', '');

      if (currentStatus !== task.status) {
        // Task moved to different column - reload to get proper rendering
        window.Turbo.visit(window.location.href, { action: 'replace' });
        this.showToast(`Task ${task.task_id} moved to ${task.status}`, 'info');
      } else {
        // Task updated in place - use Turbo to refresh just that frame
        const frame = taskCard.closest('turbo-frame');

        if (frame) {
          frame.reload();
        }
      }
    } else {
      // Task not visible, might need full refresh
      window.Turbo.visit(window.location.href, { action: 'replace' });
    }
  }

  /**
   * Handle sync conflict event
   * @param {Object} data - The conflict data
   */
  handleConflict(data) {
    console.warn('Team Board: Sync conflict detected', data);
    this.showToast(
      `Sync conflict for task ${data.task_id}. Refresh to see latest version.`,
      'warning'
    );
  }

  /**
   * Handle bulk sync response
   * @param {Object} data - The sync response data
   */
  handleSyncResponse(data) {
    console.log('Team Board: Sync response', data.tasks?.length, 'tasks');
    if (data.tasks?.length > 0) {
      window.Turbo.visit(window.location.href, { action: 'replace' });
    }
  }

  /**
   * Show task detail in modal
   * @param {Event} event - Click event
   */
  async showTaskDetail(event) {
    event.preventDefault();
    const taskId = event.currentTarget.dataset.taskId;

    if (taskId && this.hasModalTarget) {
      // Fetch task detail and load into modal
      const url = `${window.location.pathname}/${taskId}`;

      await safeAsync(
        async () => {
          const response = await fetch(url, {
            headers: {
              'Accept': 'text/html',
              'X-Requested-With': 'XMLHttpRequest'
            }
          });

          const html = await response.text();

          if (this.hasModalContentTarget) {
            this.modalContentTarget.innerHTML = html;
          }
          this.modalTarget.showModal();
        },
        {
          onError: error => {
            logger?.error('TeamBoardController', error, {
              action: 'showTaskDetail',
              taskId
            });
            this.showToast('Failed to load task details', 'error');
          }
        }
      );
    }
  }

  /**
   * Close the task detail modal
   */
  closeModal() {
    if (this.hasModalTarget) {
      this.modalTarget.close();
    }
  }

  /**
   * Setup drag and drop for Kanban columns
   */
  setupDragAndDrop() {
    const columns = [
      this.pendingColumnTarget,
      this.inProgressColumnTarget,
      this.blockedColumnTarget,
      this.completedColumnTarget
    ].filter(Boolean);

    columns.forEach(column => {
      // Make column a drop target
      column.addEventListener('dragover', e => this.handleDragOver(e));
      column.addEventListener('drop', e => this.handleDrop(e));
      column.addEventListener('dragleave', e => this.handleDragLeave(e));

      // Make cards draggable
      column.querySelectorAll('[data-task-id]').forEach(card => {
        card.setAttribute('draggable', 'true');
        card.addEventListener('dragstart', e => this.handleDragStart(e));
        card.addEventListener('dragend', e => this.handleDragEnd(e));
      });
    });
  }

  /**
   * Handle drag start on task card
   * @param {DragEvent} event
   */
  handleDragStart(event) {
    const taskId = event.currentTarget.dataset.taskId;

    event.dataTransfer.setData('text/plain', taskId);
    event.dataTransfer.effectAllowed = 'move';
    event.currentTarget.classList.add('opacity-50', 'scale-95');
  }

  /**
   * Handle drag end
   * @param {DragEvent} event
   */
  handleDragEnd(event) {
    event.currentTarget.classList.remove('opacity-50', 'scale-95');
    // Remove all drop indicators
    document.querySelectorAll('.drag-over').forEach(el => {
      el.classList.remove(
        'drag-over',
        'ring-2',
        'ring-primary',
        'ring-opacity-50'
      );
    });
  }

  /**
   * Handle drag over column
   * @param {DragEvent} event
   */
  handleDragOver(event) {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
    const column = event.currentTarget;

    column.classList.add(
      'drag-over',
      'ring-2',
      'ring-primary',
      'ring-opacity-50'
    );
  }

  /**
   * Handle drag leave column
   * @param {DragEvent} event
   */
  handleDragLeave(event) {
    const column = event.currentTarget;

    // Only remove if we're actually leaving the column (not entering a child)
    if (!column.contains(event.relatedTarget)) {
      column.classList.remove(
        'drag-over',
        'ring-2',
        'ring-primary',
        'ring-opacity-50'
      );
    }
  }

  /**
   * Handle drop on column
   * @param {DragEvent} event
   */
  handleDrop(event) {
    event.preventDefault();
    const column = event.currentTarget;

    column.classList.remove(
      'drag-over',
      'ring-2',
      'ring-primary',
      'ring-opacity-50'
    );

    const taskId = event.dataTransfer.getData('text/plain');
    const columnId = column.parentElement.id; // column-pending, column-in_progress, etc.
    const newStatus = columnId.replace('column-', '');

    if (taskId && newStatus) {
      this.updateTaskStatus(taskId, newStatus);
    }
  }

  /**
   * Update task status via PATCH request
   * @param {string} taskId - The task ID
   * @param {string} newStatus - The new status
   */
  async updateTaskStatus(taskId, newStatus) {
    const url = `${window.location.pathname}/${taskId}`;

    await safeAsync(
      async () => {
        await jsonFetch(url, {
          method: 'PATCH',
          headers: {
            Accept: 'text/vnd.turbo-stream.html'
          },
          // eslint-disable-next-line camelcase
          body: JSON.stringify({ wedo_task: { status: newStatus } })
        });

        this.showToast(
          `Task moved to ${newStatus.replace('_', ' ')}`,
          'success'
        );
        // Turbo will handle the stream update, or we reload
        window.Turbo.visit(window.location.href, { action: 'replace' });
      },
      {
        onError: error => {
          logger?.error('TeamBoardController', error, {
            action: 'updateTaskStatus',
            taskId,
            newStatus
          });
          this.showToast('Failed to move task', 'error');
        }
      }
    );
  }

  /**
   * Filter tasks by scope
   * @param {Event} event - Change event from select
   */
  filterByScope(event) {
    const scope = event.target.value;
    const url = new URL(window.location.href);

    if (scope) {
      url.searchParams.set('scope', scope);
    } else {
      url.searchParams.delete('scope');
    }

    window.Turbo.visit(url.toString(), { action: 'replace' });
  }

  /**
   * Request a sync from the server
   */
  requestSync() {
    if (this.subscription) {
      // eslint-disable-next-line camelcase
      this.subscription.perform('sync_request', { since_version: 0 });
    }
  }

  /**
   * Send ping to keep connection alive
   */
  ping() {
    if (this.subscription) {
      this.subscription.perform('ping', {});
    }
  }

  /**
   * Show a toast notification
   * @param {string} message - The message to show
   * @param {string} type - The type of toast (success, error, warning, info)
   */
  showToast(message, type = 'info') {
    // Dispatch a custom event that the toast system can listen to
    const event = new CustomEvent('toast:show', {
      detail: { message, type },
      bubbles: true
    });

    document.dispatchEvent(event);

    // Fallback: append to toast container if it exists
    const toastContainer = document.querySelector('.toast');

    if (toastContainer) {
      const alertClass =
        {
          success: 'alert-success',
          error: 'alert-error',
          warning: 'alert-warning',
          info: 'alert-info'
        }[type] || 'alert-info';

      const toast = document.createElement('div');

      toast.className = `alert ${alertClass} shadow-lg`;
      toast.innerHTML = `<span>${message}</span>`;
      toastContainer.appendChild(toast);

      // Auto-remove after 5 seconds
      setTimeout(() => toast.remove(), 5000);
    }
  }
}
