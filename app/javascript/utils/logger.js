/**
 * Intelligent logging utility for FlukeBase.
 * Provides structured, contextual logging for AI agents and developers.
 * Automatically disabled in production environments.
 * @module utils/logger
 */

/**
 * Logger class for structured console logging.
 * Logs are automatically styled and disabled in production.
 * @class
 * @example
 * const logger = new Logger('MyController');
 * logger.controllerLifecycle('MyController', 'connected');
 * logger.error('submit', new Error('Network failed'));
 */
class Logger {
  /**
   * Create a new Logger instance.
   * @param {string} [context='FlukeBase'] - Context prefix for log messages
   */
  constructor(context = 'FlukeBase') {
    this.context = context;
    // Check environment from meta tag or fallback to hostname
    const envMeta = document.querySelector('meta[name="environment"]');
    const environment = envMeta ? envMeta.getAttribute('content') : null;

    const isLocalHost =
      window.location.hostname === 'localhost' ||
      window.location.hostname.includes('127.0.0.1');

    this.isProduction =
      environment === 'production' || (environment === null && !isLocalHost);
  }

  /**
   * Log Stimulus controller lifecycle events (connect/disconnect).
   * @param {string} controllerName - Name of the controller
   * @param {string} action - Lifecycle action ('connected', 'disconnected')
   * @param {Object} [details={}] - Additional context to log
   */
  controllerLifecycle(controllerName, action, details = {}) {
    if (this.isProduction) {
      return;
    }

    const message = `[${this.context}] ${controllerName} ${action}`;
    const data = { controller: controllerName, action, ...details };

    console.log(`%c${message}`, 'color: #3B82F6; font-weight: bold;', data);
  }

  /**
   * Log ActionCable WebSocket connection events.
   * @param {string} channelName - Name of the ActionCable channel
   * @param {string} event - Event type ('subscribed', 'received', 'disconnected')
   * @param {Object} [details={}] - Additional context to log
   */
  websocketEvent(channelName, event, details = {}) {
    if (this.isProduction) {
      return;
    }

    const message = `[${this.context}] WebSocket ${channelName} ${event}`;
    const data = { channel: channelName, event, ...details };

    console.log(`%c${message}`, 'color: #10B981; font-weight: bold;', data);
  }

  /**
   * Log audio/media player events.
   * @param {string} action - Media action ('play', 'pause', 'ended', 'error')
   * @param {Object} [details={}] - Additional context (duration, currentTime)
   */
  mediaEvent(action, details = {}) {
    if (this.isProduction) {
      return;
    }

    const message = `[${this.context}] Audio ${action}`;
    const data = { action, ...details };

    console.log(`%c${message}`, 'color: #F59E0B; font-weight: bold;', data);
  }

  /**
   * Log form validation and submission events.
   * @param {string} action - Form action ('submit', 'validate', 'error')
   * @param {Object} [details={}] - Additional context (form name, field errors)
   */
  formEvent(action, details = {}) {
    if (this.isProduction) {
      return;
    }

    const message = `[${this.context}] Form ${action}`;
    const data = { action, ...details };

    console.log(`%c${message}`, 'color: #8B5CF6; font-weight: bold;', data);
  }

  /**
   * Log errors with context and stack trace.
   * @param {string} context - Where the error occurred
   * @param {Error|string} error - The error object or message
   * @param {Object} [details={}] - Additional context
   */
  error(context, error, details = {}) {
    if (this.isProduction) {
      return;
    }

    const message = `[${this.context}] ERROR in ${context}`;
    const data = {
      context,
      error: error.message || error,
      stack: error.stack,
      ...details
    };

    console.error(`%c${message}`, 'color: #EF4444; font-weight: bold;', data);
  }

  /**
   * Log warnings with context.
   * @param {string} context - Where the warning occurred
   * @param {string} message - Warning message
   * @param {Object} [details={}] - Additional context
   */
  warning(context, message, details = {}) {
    if (this.isProduction) {
      return;
    }

    const logMessage = `[${this.context}] WARNING in ${context}: ${message}`;
    const data = { context, message, ...details };

    console.warn(`%c${logMessage}`, 'color: #F59E0B; font-weight: bold;', data);
  }

  /**
   * Log performance metrics for operations.
   * @param {string} operation - Name of the operation being measured
   * @param {number} duration - Duration in milliseconds
   * @param {Object} [details={}] - Additional context
   */
  performance(operation, duration, details = {}) {
    if (this.isProduction) {
      return;
    }

    const message = `[${this.context}] Performance: ${operation} took ${duration}ms`;
    const data = { operation, duration, ...details };

    console.log(`%c${message}`, 'color: #06B6D4; font-weight: bold;', data);
  }

  /**
   * Log user interaction events.
   * @param {string} action - Interaction type ('click', 'focus', 'scroll')
   * @param {HTMLElement|string} element - Element interacted with
   * @param {Object} [details={}] - Additional context
   */
  userInteraction(action, element, details = {}) {
    if (this.isProduction) {
      return;
    }

    const message = `[${this.context}] User ${action}`;
    const data = { action, element: element?.tagName || element, ...details };

    console.log(`%c${message}`, 'color: #EC4899; font-weight: bold;', data);
  }
}

/**
 * Factory function to create a new Logger instance.
 * @param {string} [context='FlukeBase'] - Context prefix for log messages
 * @returns {Logger} New Logger instance
 * @example
 * import { createLogger } from './utils/logger';
 * const logger = createLogger('MyController');
 */
export const createLogger = (context = 'FlukeBase') => new Logger(context);

// Create global logger instance for backward compatibility
/** @type {Logger} */
const globalLogger = createLogger();

window.FlukeLogger = globalLogger;

// Export for module usage
export default Logger;
export { globalLogger };
