/**
 * Shared helpers for Stimulus controllers to reduce boilerplate.
 * Provides logging, data parsing, async handling, and rate limiting utilities.
 * @module utils/stimulus_helpers
 */
import { debounce, throttle } from './timing';

/**
 * Log controller connection event.
 * @param {Logger} logger - Logger instance (from utils/logger)
 * @param {string} controllerName - Name of the Stimulus controller
 * @param {Controller} controller - Stimulus controller instance
 * @param {Object} [details={}] - Additional details to log
 * @example
 * logConnect(this.logger, 'modal', this, { mode: 'dialog' });
 */
export const logConnect = (
  logger,
  controllerName,
  controller,
  details = {}
) => {
  logger?.controllerLifecycle(controllerName, 'connected', {
    element: controller?.element?.tagName,
    ...details
  });
};

/**
 * Log controller disconnection event.
 * @param {Logger} logger - Logger instance
 * @param {string} controllerName - Name of the Stimulus controller
 * @param {Object} [details={}] - Additional details to log
 */
export const logDisconnect = (logger, controllerName, details = {}) => {
  logger?.controllerLifecycle(controllerName, 'disconnected', details);
};

/**
 * Parse a dataset value with a custom parser and safe fallback.
 * @param {HTMLElement} element - DOM element with dataset
 * @param {string} key - Dataset key (camelCase, without 'data-' prefix)
 * @param {Function} [parser=v=>v] - Parser function to transform the value
 * @param {*} [fallback=null] - Value to return if parsing fails
 * @returns {*} Parsed value or fallback
 * @example
 * datasetValue(element, 'userId', parseInt, 0);
 * datasetValue(element, 'config', JSON.parse, {});
 */
export const datasetValue = (
  element,
  key,
  parser = v => v,
  fallback = null
) => {
  const raw = element?.dataset?.[key];

  if (raw === undefined) {
    return fallback;
  }

  try {
    const parsed = parser(raw);

    return Number.isNaN(parsed) ? fallback : parsed;
  } catch {
    return fallback;
  }
};

/**
 * Parse a dataset value as a number with safe fallback.
 * @param {HTMLElement} element - DOM element with dataset
 * @param {string} key - Dataset key (camelCase)
 * @param {number} [fallback=null] - Value if parsing fails or NaN
 * @returns {number|null} Parsed number or fallback
 * @example
 * datasetNumber(element, 'timeout', 5000);
 * datasetNumber(element, 'retryCount', 3);
 */
export const datasetNumber = (element, key, fallback = null) =>
  datasetValue(
    element,
    key,
    value => {
      const num = Number(value);

      return Number.isFinite(num) ? num : fallback;
    },
    fallback
  );

/**
 * Wrap async operations with loading state management.
 * Disables element during operation and restores state after.
 * @param {HTMLElement} element - Button or interactive element
 * @param {Function} operation - Async operation to execute
 * @param {Object} [options={}] - Configuration options
 * @param {string} [options.disabledClass='opacity-50'] - Class to add while loading
 * @param {Function} [options.onError] - Error handler callback
 * @param {Function} [options.onFinally] - Cleanup callback (always runs)
 * @returns {Promise<*>} Result of the operation
 * @example
 * await withLoadingState(submitButton, async () => {
 *   await fetch('/api/submit', { method: 'POST' });
 * }, { onError: (e) => showError(e.message) });
 */
export const withLoadingState = async (
  element,
  operation,
  { disabledClass = 'opacity-50', onError, onFinally } = {}
) => {
  if (!element) {
    return operation();
  }

  const previousHTML = element.innerHTML;
  const previousDisabled = element.disabled;

  element.disabled = true;
  element.classList.add(disabledClass);

  try {
    return await operation();
  } catch (error) {
    onError?.(error);
    throw error;
  } finally {
    element.disabled = previousDisabled;
    element.classList.remove(disabledClass);
    element.innerHTML = previousHTML;
    onFinally?.();
  }
};

/**
 * Safe async wrapper that catches errors and prevents unhandled rejections.
 * Useful for event handlers where errors should be logged but not crash.
 * @param {Function} operation - Async operation to execute
 * @param {Object} [options={}] - Configuration options
 * @param {Function} [options.onError] - Error handler callback
 * @param {Function} [options.onFinally] - Cleanup callback
 * @returns {Promise<*|undefined>} Result or undefined on error
 * @example
 * element.addEventListener('click', () => safeAsync(
 *   async () => await api.save(),
 *   { onError: (e) => console.error(e) }
 * ));
 */
export const safeAsync = async (operation, { onError, onFinally } = {}) => {
  try {
    return await operation();
  } catch (error) {
    onError?.(error);

    return undefined;
  } finally {
    onFinally?.();
  }
};

/**
 * Create a debounced version of a function.
 * @param {Function} fn - Function to debounce
 * @param {number} [wait=200] - Debounce delay in milliseconds
 * @param {Object} [options={}] - Debounce options (leading, trailing)
 * @returns {Function} Debounced function
 * @see module:utils/timing~debounce
 */
export const debounced = (fn, wait = 200, options = {}) =>
  debounce(fn, wait, options);

/**
 * Create a throttled version of a function.
 * @param {Function} fn - Function to throttle
 * @param {number} [wait=200] - Throttle interval in milliseconds
 * @param {Object} [options={}] - Throttle options (leading, trailing)
 * @returns {Function} Throttled function
 * @see module:utils/timing~throttle
 */
export const throttled = (fn, wait = 200, options = {}) =>
  throttle(fn, wait, options);
