import { Controller } from '@hotwired/stimulus';

/**
 * Repository Validator Controller
 *
 * Validates GitHub repository URLs in real-time and controls form submission
 * based on access permissions. Public repos allow submission without GitHub auth,
 * while private repos require the user to install the GitHub App.
 *
 * Usage:
 *   <div data-controller="repository-validator"
 *        data-repository-validator-check-url-value="/github/check_access"
 *        data-repository-validator-install-url-value="<%= Github::AppConfig.install_url %>">
 *     <input data-repository-validator-target="input"
 *            data-action="input->repository-validator#validate">
 *     <div data-repository-validator-target="status"></div>
 *     <div data-repository-validator-target="authButton"></div>
 *     <button data-repository-validator-target="submitButton">Submit</button>
 *   </div>
 *
 * Note: install-url-value should be set from the server via Github::AppConfig.install_url
 * to use the correct GitHub App for the current environment (development vs production).
 */
export default class extends Controller {
  static targets = ['input', 'status', 'authButton', 'submitButton'];
  static values = {
    checkUrl: { type: String, default: '/github/check_access' },
    installUrl: {
      type: String,
      default: 'https://github.com/apps/flukebase/installations/new'
    },
    debounce: { type: Number, default: 500 },
    minLength: { type: Number, default: 3 }
  };

  connect() {
    this.timeout = null;
    this.abortController = null;
    this.lastCheckedValue = '';
  }

  disconnect() {
    this.clearTimeout();
    this.abortRequest();
  }

  /**
   * Debounced validation - triggered on input
   */
  validate(event) {
    const value = event.target.value.trim();

    // Clear pending timeout
    this.clearTimeout();

    // Reset state if input is empty
    if (value === '') {
      this.resetState();

      return;
    }

    // Check minimum length
    if (value.length < this.minLengthValue) {
      return;
    }

    // Debounce the API call
    this.timeout = setTimeout(() => {
      this.checkRepository(value);
    }, this.debounceValue);
  }

  /**
   * Check repository access via API
   */
  async checkRepository(repoUrl) {
    // Skip if same as last checked value
    if (repoUrl === this.lastCheckedValue) {
      return;
    }

    // Abort any pending request
    this.abortRequest();

    // Show loading state
    this.showLoading();

    // Create new abort controller
    this.abortController = new AbortController();

    try {
      const url = `${this.checkUrlValue}?repository_url=${encodeURIComponent(repoUrl)}`;
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        signal: this.abortController.signal
      });

      this.lastCheckedValue = repoUrl;

      const data = await response.json();

      if (response.ok) {
        this.handleSuccess(data);
      } else {
        this.handleError(data);
      }
    } catch (error) {
      if (error.name !== 'AbortError') {
        this.handleNetworkError(error);
      }
    }
  }

  /**
   * Handle successful access check
   */
  handleSuccess(data) {
    this.showStatus('success', data.message || 'Repository accessible');
    this.enableSubmit();
    this.hideAuthButton();
  }

  /**
   * Handle access denied or errors
   */
  handleError(data) {
    if (data.needs_install) {
      // Private repo without access - show auth button
      this.showStatus(
        'warning',
        data.message || 'Private repository - authentication required'
      );
      this.disableSubmit();
      this.showAuthButton(data.install_url || this.installUrlValue);
    } else if (data.code === 'invalid_url') {
      // Invalid URL format
      this.showStatus('error', 'Invalid repository URL format');
      this.enableSubmit(); // Allow submit - server-side validation will catch it
      this.hideAuthButton();
    } else {
      // Other errors
      this.showStatus('error', data.message || 'Unable to validate repository');
      this.enableSubmit(); // Allow submit anyway
      this.hideAuthButton();
    }
  }

  /**
   * Handle network errors gracefully
   */
  handleNetworkError(_error) {
    this.showStatus('info', 'Unable to validate repository. You may continue.');
    this.enableSubmit();
    this.hideAuthButton();
  }

  /**
   * Show loading spinner
   */
  showLoading() {
    if (this.hasStatusTarget) {
      this.statusTarget.innerHTML = `
        <div class="flex items-center gap-2 text-base-content/60 mt-1">
          <span class="loading loading-spinner loading-xs"></span>
          <span class="text-xs">Checking repository access...</span>
        </div>
      `;
      this.statusTarget.classList.remove('hidden');
    }
  }

  /**
   * Show status message with icon
   */
  showStatus(type, message) {
    if (!this.hasStatusTarget) {
      return;
    }

    const icons = {
      success: `<svg class="w-4 h-4 text-success" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
      </svg>`,
      warning: `<svg class="w-4 h-4 text-warning" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
      </svg>`,
      error: `<svg class="w-4 h-4 text-error" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
      </svg>`,
      info: `<svg class="w-4 h-4 text-info" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
      </svg>`
    };

    const colors = {
      success: 'text-success',
      warning: 'text-warning',
      error: 'text-error',
      info: 'text-info'
    };

    this.statusTarget.innerHTML = `
      <div class="flex items-center gap-2 ${colors[type]} mt-1">
        ${icons[type]}
        <span class="text-xs">${message}</span>
      </div>
    `;
    this.statusTarget.classList.remove('hidden');
  }

  /**
   * Show the GitHub App authentication button
   */
  showAuthButton(installUrl) {
    if (!this.hasAuthButtonTarget) {
      return;
    }

    this.authButtonTarget.innerHTML = `
      <a href="${installUrl}"
         target="_blank"
         rel="noopener noreferrer"
         class="btn btn-sm btn-outline btn-warning mt-2 gap-2">
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
        </svg>
        Authenticate via GitHub App
      </a>
    `;
    this.authButtonTarget.classList.remove('hidden');
  }

  /**
   * Hide the authentication button
   */
  hideAuthButton() {
    if (this.hasAuthButtonTarget) {
      this.authButtonTarget.classList.add('hidden');
      this.authButtonTarget.innerHTML = '';
    }
  }

  /**
   * Enable the form submit button
   */
  enableSubmit() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false;
      this.submitButtonTarget.classList.remove('btn-disabled');
    }
  }

  /**
   * Disable the form submit button
   */
  disableSubmit() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true;
      this.submitButtonTarget.classList.add('btn-disabled');
    }
  }

  /**
   * Reset to default state
   */
  resetState() {
    this.lastCheckedValue = '';
    this.enableSubmit();
    this.hideAuthButton();
    if (this.hasStatusTarget) {
      this.statusTarget.classList.add('hidden');
      this.statusTarget.innerHTML = '';
    }
  }

  /**
   * Clear the debounce timeout
   */
  clearTimeout() {
    if (this.timeout) {
      clearTimeout(this.timeout);
      this.timeout = null;
    }
  }

  /**
   * Abort pending fetch request
   */
  abortRequest() {
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }
  }

  /**
   * Get CSRF token from meta tag
   */
  get csrfToken() {
    return document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute('content');
  }
}
