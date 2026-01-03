import { Controller } from '@hotwired/stimulus';
import consumer from 'channels/consumer';

/**
 * Stimulus controller for unified logs dashboard.
 * Handles WebSocket connection, log display, and user interactions.
 */
export default class extends Controller {
  static targets = [
    'logContainer',
    'logList',
    'pauseButton',
    'pauseIcon',
    'autoScrollCheckbox',
    'entryCount',
    'entriesPerSec',
    'connectionStatus',
    'statusDot',
    'statusText',
    'statusBar',
    'bufferSize',
    'lastUpdate',
    'statsContainer'
  ];

  static values = {
    autoScroll: { type: Boolean, default: true },
    paused: { type: Boolean, default: false },
    maxEntries: { type: Number, default: 500 },
    projectId: String,
    sandboxId: String
  };

  connect() {
    this.entries = [];
    this.entryCounts = [];
    this.lastCountTime = Date.now();

    this.subscribeToChannel();
    this.startEntriesPerSecTimer();
  }

  disconnect() {
    this.unsubscribeFromChannel();
    this.stopEntriesPerSecTimer();
  }

  subscribeToChannel() {
    this.updateConnectionStatus('connecting');

    const projectId = this.projectIdValue;
    const sandboxId = this.sandboxIdValue;

    this.subscription = consumer.subscriptions.create(
      {
        channel: 'UnifiedLogsChannel',
        // eslint-disable-next-line camelcase
        project_id: projectId,
        // eslint-disable-next-line camelcase
        sandbox_id: sandboxId
      },
      {
        connected: () => this.handleConnected(),
        disconnected: () => this.handleDisconnected(),
        received: data => this.handleReceived(data)
      }
    );
  }

  unsubscribeFromChannel() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }
  }

  handleConnected() {
    this.updateConnectionStatus('connected');
    console.log('[UnifiedLogs] Connected to channel');

    // Request initial history
    this.subscription.perform('get_history', { limit: 100 });
  }

  handleDisconnected() {
    this.updateConnectionStatus('disconnected');
    console.log('[UnifiedLogs] Disconnected from channel');

    // Attempt reconnection after delay
    setTimeout(() => {
      if (!this.subscription) {
        this.subscribeToChannel();
      }
    }, 3000);
  }

  handleReceived(data) {
    switch (data.type) {
      case 'connected':
        console.log('[UnifiedLogs] Subscription confirmed:', data.stream);
        break;

      case 'log':
        this.addLogEntry(data.entry);
        break;

      case 'history':
        this.loadHistory(data.entries);
        break;

      case 'stats':
        this.updateStats(data.stats);
        break;

      case 'filter_set':
        console.log('[UnifiedLogs] Filter applied:', data.filter);
        break;

      case 'pong':
        // Heartbeat response
        break;

      default:
        console.log('[UnifiedLogs] Unknown message type:', data.type);
    }
  }

  addLogEntry(entry) {
    if (this.pausedValue) {
      return;
    }

    this.entries.push(entry);
    this.entryCounts.push(Date.now());

    // Trim old entries
    if (this.entries.length > this.maxEntriesValue) {
      this.entries.shift();
      this.removeFirstLogElement();
    }

    this.appendLogElement(entry);
    this.updateEntryCount();
    this.updateLastUpdate();

    if (this.autoScrollValue) {
      this.scrollToBottom();
    }
  }

  loadHistory(entries) {
    if (!entries || entries.length === 0) {
      return;
    }

    // Clear existing entries
    this.entries = entries;
    this.renderAllEntries();
    this.updateEntryCount();

    if (this.autoScrollValue) {
      this.scrollToBottom();
    }
  }

  appendLogElement(entry) {
    if (!this.hasLogListTarget) {
      return;
    }

    const html = this.createEntryHtml(entry);

    this.logListTarget.insertAdjacentHTML('beforeend', html);
  }

  removeFirstLogElement() {
    if (!this.hasLogListTarget) {
      return;
    }

    const firstChild = this.logListTarget.firstElementChild;

    if (firstChild) {
      firstChild.remove();
    }
  }

  renderAllEntries() {
    if (!this.hasLogListTarget) {
      return;
    }

    const html = this.entries
      .map(entry => this.createEntryHtml(entry))
      .join('');

    this.logListTarget.innerHTML = html;
  }

  createEntryHtml(entry) {
    // SECURITY: Validate and sanitize all values from external Python source
    const ALLOWED_TYPES = ['mcp', 'container', 'application', 'ai_provider'];
    const ALLOWED_LEVELS = ['trace', 'debug', 'info', 'warn', 'error', 'fatal'];

    // Sanitize type - only allow known values
    const rawType = String(entry.source?.type || 'application').toLowerCase();
    const type = ALLOWED_TYPES.includes(rawType) ? rawType : 'application';

    // Sanitize level - only allow known values
    const rawLevel = String(entry.level || 'info').toLowerCase();
    const level = ALLOWED_LEVELS.includes(rawLevel) ? rawLevel : 'info';

    // Escape all user-controlled strings
    const timestamp = this.escapeHtml(this.formatTimestamp(entry.timestamp));
    const message = this.escapeHtml(String(entry.message || ''));
    // For AI providers, show provider and model; otherwise show agent_id or container_name
    const source = this.escapeHtml(
      type === 'ai_provider'
        ? String(entry.source?.provider || '') +
            (entry.source?.model ? ` (${entry.source.model})` : '')
        : String(entry.source?.agent_id || entry.source?.container_name || '')
    );
    const logId = this.escapeHtml(String(entry.id || ''));

    const typeConfig = {
      mcp: { icon: 'command-line', color: 'primary' },
      container: { icon: 'cube', color: 'secondary' },
      application: { icon: 'document-text', color: 'accent' },
      aiProvider: { icon: 'sparkles', color: 'info' }
    };

    const typeKey = type === 'ai_provider' ? 'aiProvider' : type;
    const config = typeConfig[typeKey];
    const levelColors = {
      trace: 'base-content/50',
      debug: 'info',
      info: 'success',
      warn: 'warning',
      error: 'error',
      fatal: 'error'
    };

    const levelColor = levelColors[level];
    const isError = level === 'error' || level === 'fatal';

    return `
      <div class="flex items-center gap-2 px-3 py-1.5 border-l-2 border-l-${config.color} hover:bg-base-200/50 transition-colors text-sm ${isError ? 'bg-error/5' : ''}"
           data-log-id="${logId}"
           data-log-type="${type}"
           data-log-level="${level}">
        <span class="flex-shrink-0 w-6 text-center text-${config.color}" title="${type}">
          <svg class="w-4 h-4 inline" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            ${this.getIconPath(config.icon)}
          </svg>
        </span>
        <span class="flex-shrink-0 font-mono text-base-content/60 w-24">${timestamp}</span>
        <span class="flex-shrink-0 w-8 text-center font-bold text-${levelColor}">${level.toUpperCase().slice(0, 3)}</span>
        <span class="flex-grow truncate font-mono">${message}</span>
        ${source ? `<span class="flex-shrink-0 text-base-content/50 text-xs max-w-32 truncate">${source}</span>` : ''}
      </div>
    `;
  }

  getIconPath(iconName) {
    const icons = {
      'command-line':
        '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6.75 7.5l3 2.25-3 2.25m4.5 0h3m-9 8.25h13.5A2.25 2.25 0 0021 18V6a2.25 2.25 0 00-2.25-2.25H5.25A2.25 2.25 0 003 6v12a2.25 2.25 0 002.25 2.25z"/>',
      'cube':
        '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 7.5l-9-5.25L3 7.5m18 0l-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9"/>',
      'document-text':
        '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"/>',
      'sparkles':
        '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456zM16.894 20.567L16.5 21.75l-.394-1.183a2.25 2.25 0 00-1.423-1.423L13.5 18.75l1.183-.394a2.25 2.25 0 001.423-1.423l.394-1.183.394 1.183a2.25 2.25 0 001.423 1.423l1.183.394-1.183.394a2.25 2.25 0 00-1.423 1.423z"/>'
    };

    return icons[iconName] || icons['document-text'];
  }

  formatTimestamp(ts) {
    if (!ts) {
      return '--:--:--';
    }
    try {
      const date = new Date(ts);

      return date.toTimeString().slice(0, 12);
    } catch {
      return ts;
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div');

    div.textContent = text;

    return div.innerHTML;
  }

  // Actions
  togglePause() {
    this.pausedValue = !this.pausedValue;

    if (this.hasPauseIconTarget) {
      this.pauseIconTarget.innerHTML = `
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          ${this.pausedValue ? '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z"/>' : '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.75 5.25v13.5m-7.5-13.5v13.5"/>'}
        </svg>
      `;
    }
  }

  toggleAutoScroll() {
    if (this.hasAutoScrollCheckboxTarget) {
      this.autoScrollValue = this.autoScrollCheckboxTarget.checked;
    }
  }

  clearLogs() {
    this.entries = [];
    if (this.hasLogListTarget) {
      this.logListTarget.innerHTML = this.getEmptyStateHtml();
    }
    this.updateEntryCount();
  }

  getEmptyStateHtml() {
    return `
      <div class="flex flex-col items-center justify-center py-16 text-base-content/50">
        <svg class="w-16 h-16 opacity-30 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"/>
        </svg>
        <p class="text-lg font-medium">No log entries</p>
        <p class="text-sm mt-1">Logs cleared</p>
      </div>
    `;
  }

  scrollToBottom() {
    if (this.hasLogContainerTarget) {
      this.logContainerTarget.scrollTop = this.logContainerTarget.scrollHeight;
    }
  }

  toggleEntryDetails(event) {
    const entry = event.target.closest('[data-log-id]');

    if (entry) {
      entry.classList.toggle('expanded');
    }
  }

  // Stats and status updates
  updateConnectionStatus(status) {
    if (!this.hasStatusDotTarget || !this.hasStatusTextTarget) {
      return;
    }

    const configs = {
      connecting: { dot: 'bg-warning animate-pulse', text: 'Connecting...' },
      connected: { dot: 'bg-success', text: 'Connected' },
      disconnected: { dot: 'bg-error', text: 'Disconnected' }
    };

    const config = configs[status] || configs.disconnected;

    this.statusDotTarget.className = `w-2 h-2 rounded-full ${config.dot}`;
    this.statusTextTarget.textContent = config.text;
  }

  updateEntryCount() {
    if (this.hasEntryCountTarget) {
      this.entryCountTarget.textContent = this.entries.length;
    }
    if (this.hasBufferSizeTarget) {
      this.bufferSizeTarget.textContent = this.entries.length;
    }
  }

  updateLastUpdate() {
    if (this.hasLastUpdateTarget) {
      this.lastUpdateTarget.textContent = new Date().toTimeString().slice(0, 8);
    }
  }

  startEntriesPerSecTimer() {
    this.entriesPerSecInterval = setInterval(() => {
      const now = Date.now();
      const oneSecondAgo = now - 1000;

      // Count entries from the last second
      this.entryCounts = this.entryCounts.filter(t => t > oneSecondAgo);

      if (this.hasEntriesPerSecTarget) {
        this.entriesPerSecTarget.textContent = this.entryCounts.length;
      }
    }, 500);
  }

  stopEntriesPerSecTimer() {
    if (this.entriesPerSecInterval) {
      clearInterval(this.entriesPerSecInterval);
    }
  }

  updateStats(stats) {
    // Update stats display if stats container exists
    if (this.hasStatsContainerTarget) {
      // Stats are updated via data attributes on child elements
      console.log('[UnifiedLogs] Stats update:', stats);
    }
  }

  // Filter integration
  applyFilter(filter) {
    if (this.subscription) {
      this.subscription.perform('set_filter', filter);
    }
  }
}
