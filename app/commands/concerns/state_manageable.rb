# frozen_string_literal: true

# Provides state management helpers for TurboBoost commands
# Wraps TurboBoost's built-in state (Page-State, Client-State)
# and Rails session (Server-State) for unified access
module StateManageable
  extend ActiveSupport::Concern

  # Page-State: Lost on navigation, persists within page
  # Good for: UI state, form progress, temporary selections

  def set_page_state(key, value)
    state.page[key.to_s] = value
  end

  def get_page_state(key)
    state.page[key.to_s]
  end

  def delete_page_state(key)
    state.page.delete(key.to_s)
  end

  # Client-State: Survives navigation, lost on refresh
  # Good for: User preferences during session, wizard progress

  def set_client_state(key, value)
    state.client[key.to_s] = value
  end

  def get_client_state(key)
    state.client[key.to_s]
  end

  def delete_client_state(key)
    state.client.delete(key.to_s)
  end

  # Server-State: Persisted in session, survives refresh
  # Good for: Critical user state, selections that must persist

  def set_server_state(key, value)
    controller.session[key] = value
  end

  def get_server_state(key)
    controller.session[key]
  end

  def delete_server_state(key)
    controller.session.delete(key)
  end

  # Time tracking milestone state helpers
  # These wrap the existing session-based tracking milestone logic

  def current_tracking_milestone_id(project_id)
    if multi_project_tracking_enabled?
      get_server_state(:progress_milestone_ids)&.dig(project_id.to_s)
    else
      get_server_state(:progress_milestone_id)
    end
  end

  def set_tracking_milestone(project_id, milestone_id)
    if multi_project_tracking_enabled?
      ids = get_server_state(:progress_milestone_ids) || {}
      ids[project_id.to_s] = milestone_id
      set_server_state(:progress_milestone_ids, ids)
    else
      set_server_state(:progress_milestone_id, milestone_id)
    end
  end

  def clear_tracking_milestone(project_id)
    if multi_project_tracking_enabled?
      ids = get_server_state(:progress_milestone_ids) || {}
      ids.delete(project_id.to_s)
      set_server_state(:progress_milestone_ids, ids)
    else
      set_server_state(:progress_milestone_id, nil)
    end
  end

  def tracking_milestone_for?(project_id, milestone_id)
    current_tracking_milestone_id(project_id) == milestone_id
  end

  private

  def multi_project_tracking_enabled?
    current_user.respond_to?(:multi_project_tracking) && current_user.multi_project_tracking
  end
end
