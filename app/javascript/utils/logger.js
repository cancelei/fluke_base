/**
 * Intelligent logging utility for FlukeBase
 * Provides structured, contextual logging for AI agents and developers
 */

class Logger {
  constructor(context = 'FlukeBase') {
    this.context = context;
    // Check environment from meta tag or fallback to hostname
    const envMeta = document.querySelector('meta[name="environment"]');
    const environment = envMeta ? envMeta.getAttribute('content') : null;
    this.isProduction = environment === 'production' ||
                      (environment === null && window.location.hostname !== 'localhost' && !window.location.hostname.includes('127.0.0.1'));
  }

  /**
   * Log controller lifecycle events
   */
  controllerLifecycle(controllerName, action, details = {}) {
    if (this.isProduction) return;

    const message = `[${this.context}] ${controllerName} ${action}`;
    const data = { controller: controllerName, action, ...details };

    console.log(`%c${message}`, 'color: #3B82F6; font-weight: bold;', data);
  }

  /**
   * Log WebSocket connection events
   */
  websocketEvent(channelName, event, details = {}) {
    if (this.isProduction) return;

    const message = `[${this.context}] WebSocket ${channelName} ${event}`;
    const data = { channel: channelName, event, ...details };

    console.log(`%c${message}`, 'color: #10B981; font-weight: bold;', data);
  }

  /**
   * Log audio/media events
   */
  mediaEvent(action, details = {}) {
    if (this.isProduction) return;

    const message = `[${this.context}] Audio ${action}`;
    const data = { action, ...details };

    console.log(`%c${message}`, 'color: #F59E0B; font-weight: bold;', data);
  }

  /**
   * Log form validation and submission events
   */
  formEvent(action, details = {}) {
    if (this.isProduction) return;

    const message = `[${this.context}] Form ${action}`;
    const data = { action, ...details };

    console.log(`%c${message}`, 'color: #8B5CF6; font-weight: bold;', data);
  }

  /**
   * Log errors with context
   */
  error(context, error, details = {}) {
    if (this.isProduction) return;

    const message = `[${this.context}] ERROR in ${context}`;
    const data = { context, error: error.message || error, stack: error.stack, ...details };

    console.error(`%c${message}`, 'color: #EF4444; font-weight: bold;', data);
  }

  /**
   * Log warnings with context
   */
  warning(context, message, details = {}) {
    if (this.isProduction) return;

    const logMessage = `[${this.context}] WARNING in ${context}: ${message}`;
    const data = { context, message, ...details };

    console.warn(`%c${logMessage}`, 'color: #F59E0B; font-weight: bold;', data);
  }

  /**
   * Log performance metrics
   */
  performance(operation, duration, details = {}) {
    if (this.isProduction) return;

    const message = `[${this.context}] Performance: ${operation} took ${duration}ms`;
    const data = { operation, duration, ...details };

    console.log(`%c${message}`, 'color: #06B6D4; font-weight: bold;', data);
  }

  /**
   * Log user interactions
   */
  userInteraction(action, element, details = {}) {
    if (this.isProduction) return;

    const message = `[${this.context}] User ${action}`;
    const data = { action, element: element?.tagName || element, ...details };

    console.log(`%c${message}`, 'color: #EC4899; font-weight: bold;', data);
  }
}

// Create global logger instance
window.FlukeLogger = new Logger();

// Export for module usage
export default Logger;
