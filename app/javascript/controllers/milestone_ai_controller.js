import { Controller } from '@hotwired/stimulus';
import { Turbo } from '@hotwired/turbo-rails';

export default class MilestoneAiController extends Controller {
  static targets = ['title', 'description', 'enhanceButton', 'styleSelect'];
  static values = {
    projectId: Number,
    milestoneId: Number
  };

  connect() {
    this.pollingInterval = null;
  }

  disconnect() {
    this.stopPolling();
  }

  async enhance(event) {
    event.preventDefault();

    const title = this.titleTarget.value;
    const description = this.descriptionTarget.value;

    if (!title && !description) {
      this.showError('Please provide a title or description to enhance.');

      return;
    }

    // Show processing status
    this.enhanceButtonTarget.disabled = true;
    this.originalButtonHTML = this.enhanceButtonTarget.innerHTML;
    this.enhanceButtonTarget.innerHTML = `
      <span class="loading loading-spinner loading-sm"></span>
      Processing...
    `;

    // Call the backend using Turbo's fetch
    const url = `/projects/${this.projectIdValue}/milestones/ai_enhance`;
    const formData = new FormData();

    formData.append('title', title);
    formData.append('description', description);

    if (this.milestoneIdValue) {
      formData.append('milestone_id', this.milestoneIdValue);
    }

    if (this.hasStyleSelectTarget) {
      formData.append('enhancement_style', this.styleSelectTarget.value);
    }

    try {
      const response = await fetch(url, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document
            .querySelector('meta[name="csrf-token"]')
            .getAttribute('content'),
          'Accept': 'text/vnd.turbo-stream.html'
        }
      });

      if (response.ok) {
        const turboStream = await response.text();

        Turbo.renderStreamMessage(turboStream);

        // For existing milestones, start polling
        if (this.milestoneIdValue) {
          // Start polling for completion since Turbo Streams may not work
          // Wait a bit for the Turbo Stream to update the DOM with milestone ID
          setTimeout(() => {
            this.startPollingForCompletion();
          }, 500);
        }
        // For new milestones, the DirectMilestoneEnhancementJob will broadcast directly
      } else {
        this.showError('AI enhancement failed. Please try again.');
        window.FlukeLogger?.error(
          'MilestoneAI',
          new Error('AI enhancement failed'),
          {
            action: 'enhanceMilestone',
            status: response.status
          }
        );
      }
    } catch (error) {
      window.FlukeLogger?.error('MilestoneAI', error, {
        action: 'enhanceMilestone'
      });
      this.showError(
        'AI enhancement failed. Please check your connection and try again.'
      );
    } finally {
      this.enhanceButtonTarget.disabled = false;
      if (this.originalButtonHTML) {
        this.enhanceButtonTarget.innerHTML = this.originalButtonHTML;
      }
    }
  }

  async apply(event) {
    event.preventDefault();
    // Use currentTarget to get the button, not the clicked child (like SVG)
    const enhancementId = event.currentTarget.dataset.enhancementId;

    if (!enhancementId) {
      this.showError('Enhancement ID not found.');

      return;
    }

    // Get the enhanced description from the UI
    const enhancementContainer = document.getElementById(
      'ai-suggestion-container'
    );
    const enhancedDescription = enhancementContainer
      ? enhancementContainer
          .querySelector('.enhanced-description-text')
          ?.textContent?.trim()
      : null;

    if (enhancedDescription && this.hasDescriptionTarget) {
      // Update the form field directly
      this.descriptionTarget.value = enhancedDescription;
      this.showSuccess('Enhancement applied to description field!');

      // Clear the suggestion container
      enhancementContainer.innerHTML = '';
    } else {
      // Fallback to server-side apply if we can't get the enhanced description
      await this.sendEnhancementAction('apply_ai_enhancement', {
        enhancementId
      });
    }
  }

  async revert(event) {
    event.preventDefault();
    // Use currentTarget to get the button, not the clicked child (like SVG)
    const enhancementId = event.currentTarget.dataset.enhancementId;

    if (!enhancementId) {
      this.showError('Enhancement ID not found.');

      return;
    }

    // Get the original description from the enhancement data
    const enhancementContainer = document.getElementById(
      'ai-suggestion-container'
    );
    const originalDescription = enhancementContainer
      ? enhancementContainer
          .querySelector('.original-description-text')
          ?.textContent?.trim()
      : null;

    if (originalDescription && this.hasDescriptionTarget) {
      // Update the form field with original description
      this.descriptionTarget.value = originalDescription;
      this.showSuccess('Reverted to original description!');

      // Clear the suggestion container
      enhancementContainer.innerHTML = '';
    } else {
      // Fallback to server-side revert if we can't get the original description
      await this.sendEnhancementAction('revert_ai_enhancement', {
        enhancementId
      });
    }
  }

  discard(event) {
    event.preventDefault();

    // Clear the suggestion container
    const suggestionContainer = document.getElementById(
      'ai-suggestion-container'
    );

    if (suggestionContainer) {
      suggestionContainer.innerHTML = '';
    }
  }

  // New methods for direct enhancement (without creating milestone first)
  applyDirectEnhancement(event) {
    event.preventDefault();
    // Use currentTarget to get the button, not the clicked child (like SVG)
    const button = event.currentTarget;
    const enhancedDescription = button.dataset.enhancedDescription;

    if (enhancedDescription && this.hasDescriptionTarget) {
      // Parse the enhanced output to extract title and description
      const parsed = this.parseEnhancedContent(enhancedDescription);

      // Update title field if we have one and parsed title exists
      if (parsed.title && this.hasTitleTarget) {
        this.titleTarget.value = parsed.title;
      }

      // Update description field
      this.descriptionTarget.value = parsed.description;

      this.showSuccess('Enhanced description applied to form!');
      this.discardDirectEnhancement();
    } else {
      this.showError('Failed to apply enhancement.');
    }
  }

  revertDirectEnhancement(event) {
    event.preventDefault();
    // Use currentTarget to get the button, not the clicked child (like SVG)
    const button = event.currentTarget;
    const originalTitle = button.dataset.originalTitle;
    const originalDescription = button.dataset.originalDescription;

    // Revert title if we have original title and title target
    if (originalTitle && this.hasTitleTarget) {
      this.titleTarget.value = originalTitle;
    }

    // Revert description
    if (originalDescription && this.hasDescriptionTarget) {
      this.descriptionTarget.value = originalDescription;
      this.showSuccess('Reverted to original title and description!');
      this.discardDirectEnhancement();
    } else {
      this.showError('Failed to revert to original.');
    }
  }

  discardDirectEnhancement(event) {
    if (event) {
      event.preventDefault();
    }

    // Clear the suggestion container
    const suggestionContainer = document.getElementById(
      'ai-suggestion-container'
    );

    if (suggestionContainer) {
      suggestionContainer.innerHTML = '';
    }
  }

  // Handle real-time updates when enhancement processing completes
  enhancementUpdated(event) {
    const { enhancement } = event.detail;

    if (enhancement.status === 'completed') {
      this.showSuccess(
        'Enhancement completed! You can now apply or discard it.'
      );
    } else if (enhancement.status === 'failed') {
      this.showError('Enhancement failed. Please try again.');
    }
  }

  async sendEnhancementAction(action, data) {
    const url = `/projects/${this.projectIdValue}/milestones/${action}`;
    const formData = new FormData();

    Object.entries(data).forEach(([key, value]) => {
      formData.append(this.toSnakeCase(key), value);
    });

    try {
      const response = await fetch(url, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document
            .querySelector('meta[name="csrf-token"]')
            .getAttribute('content'),
          'Accept': 'text/vnd.turbo-stream.html'
        }
      });

      if (response.ok) {
        const turboStream = await response.text();

        Turbo.renderStreamMessage(turboStream);
      } else {
        this.showError('Action failed. Please try again.');
        window.FlukeLogger?.error(
          'MilestoneAI',
          new Error(`${action} failed`),
          {
            action,
            status: response.status
          }
        );
      }
    } catch (error) {
      window.FlukeLogger?.error('MilestoneAI', error, { action });
      this.showError(
        'Action failed. Please check your connection and try again.'
      );
    }
  }

  showError(message) {
    // Use Turbo to show error message
    const flashContainer = document.getElementById('flash_messages');

    if (flashContainer) {
      flashContainer.innerHTML = `
        <div class="alert alert-error mb-4">
          <span class="block sm:inline">${message}</span>
        </div>
      `;

      // Auto-hide after 5 seconds
      setTimeout(() => {
        flashContainer.innerHTML = '';
      }, 5000);
    }
  }

  showSuccess(message) {
    // Use Turbo to show success message
    const flashContainer = document.getElementById('flash_messages');

    if (flashContainer) {
      flashContainer.innerHTML = `
        <div class="alert alert-success mb-4">
          <span class="block sm:inline">${message}</span>
        </div>
      `;

      // Auto-hide after 5 seconds
      setTimeout(() => {
        flashContainer.innerHTML = '';
      }, 5000);
    }
  }

  startPollingForCompletion() {
    this.stopPolling(); // Clear any existing polling

    // Get milestone ID from the AI suggestion container if not set
    if (!this.milestoneIdValue) {
      const suggestionContainer = document.getElementById(
        'ai-suggestion-container'
      );

      if (suggestionContainer && suggestionContainer.dataset.milestoneId) {
        this.milestoneIdValue = parseInt(
          suggestionContainer.dataset.milestoneId
        );
      } else {
        // Try again after a short delay - milestone ID might appear after Turbo Stream update
        setTimeout(() => {
          this.startPollingForCompletion();
        }, 1000);

        return;
      }
    }

    this.pollingInterval = setInterval(async () => {
      await this.checkEnhancementStatus();
    }, 3000); // Poll every 3 seconds

    // Stop polling after 2 minutes to prevent infinite polling
    setTimeout(() => {
      this.stopPolling();
    }, 120000);
  }

  stopPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
      this.pollingInterval = null;
    }
  }

  async checkEnhancementStatus() {
    if (!this.milestoneIdValue) {
      this.stopPolling();

      return;
    }

    try {
      const url = `/projects/${this.projectIdValue}/milestones/${this.milestoneIdValue}/enhancement_status`;

      const response = await fetch(url, {
        headers: {
          'X-CSRF-Token': document
            .querySelector('meta[name="csrf-token"]')
            .getAttribute('content'),
          'Accept': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();

        if (data.enhancement && data.enhancement.status !== 'processing') {
          // Enhancement completed or failed, stop polling and update UI
          this.stopPolling();

          if (data.enhancement.status === 'completed') {
            await this.refreshEnhancementDisplay();
          } else if (data.enhancement.status === 'failed') {
            this.showError('Enhancement failed. Please try again.');
          }
        }
      } else if (response.status === 404) {
        this.stopPolling();
      }
    } catch (error) {
      window.FlukeLogger?.error('MilestoneAI', error, {
        action: 'checkEnhancementStatus'
      });
    }
  }

  async refreshEnhancementDisplay() {
    if (!this.milestoneIdValue) {
      return;
    }

    try {
      const url = `/projects/${this.projectIdValue}/milestones/${this.milestoneIdValue}/enhancement_display`;
      const response = await fetch(url, {
        headers: {
          'X-CSRF-Token': document
            .querySelector('meta[name="csrf-token"]')
            .getAttribute('content'),
          'Accept': 'text/vnd.turbo-stream.html'
        }
      });

      if (response.ok) {
        const turboStream = await response.text();

        Turbo.renderStreamMessage(turboStream);
      }
    } catch (error) {
      window.FlukeLogger?.error('MilestoneAI', error, {
        action: 'refreshEnhancementDisplay'
      });
    }
  }

  // Parse enhanced content to extract title and description
  parseEnhancedContent(enhancedText) {
    // Look for "Title: [title]" and "Description: [description]" pattern
    const titleMatch = enhancedText.match(/Title:\s*(.+?)(?:\n|$)/iu);
    const descriptionMatch = enhancedText.match(/Description:\s*([\s\S]+)/iu);

    // Extract title if found, otherwise use original enhanced text for description only
    const title = titleMatch ? titleMatch[1].trim() : null;

    // Extract description if found, otherwise use the full enhanced text
    let description = descriptionMatch
      ? descriptionMatch[1].trim()
      : enhancedText;

    // Clean up the description by removing any remaining "Title: ..." line if it exists
    if (titleMatch && !descriptionMatch) {
      description = enhancedText.replace(/Title:\s*.+?\n/iu, '').trim();
    }

    return { title, description };
  }

  toSnakeCase(key) {
    return key.replace(/[A-Z]/gu, letter => `_${letter.toLowerCase()}`);
  }
}
