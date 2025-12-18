class UsersController < ApplicationController
  def update_selected_project
    service = ProjectSelectionService.new(current_user, session, params[:project_id])

    if service.call
      @selected_project = service.project

      respond_to do |format|
        # Compute a contextual redirect: if the referrer includes a project path,
        # swap the project id and redirect there. Otherwise, go to the project page.
        contextual_path = begin
          ref = request.referer
          if ref.present?
            uri = URI.parse(ref)
            new_path = uri.path.gsub(/\A(.*\/projects\/)\d+(\/?.*)\z/, "\\1#{@selected_project.id}\\2")
            new_path.presence
          end
        rescue URI::InvalidURIError
          nil
        end

        target_url = contextual_path.present? ? contextual_path : project_path(@selected_project)

        format.html { redirect_to target_url, allow_other_host: false }
        format.turbo_stream do
          streams = base_turbo_streams
          streams += contextual_turbo_streams
          render turbo_stream: streams
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_content }
        format.html { redirect_back fallback_location: root_path, alert: "Project not found." }
      end
    end
  end

  private

  # Base Turbo Streams that always get updated
  def base_turbo_streams
    [
      turbo_stream.replace(
        "project-context",
        partial: "shared/project_context_nav",
        locals: { selected_project: @selected_project }
      )
    ]
  end

  # Contextual Turbo Streams based on the current page
  def contextual_turbo_streams
    context_page = params[:context_page].presence || detect_context_from_referer
    return [] unless context_page

    case context_page
    when "github_logs"
      github_logs_turbo_streams
    when "time_logs"
      time_logs_turbo_streams
    when "milestones"
      milestones_turbo_streams
    else
      []
    end
  end

  # Detect context from the referer URL
  def detect_context_from_referer
    return nil unless request.referer.present?

    uri = URI.parse(request.referer) rescue nil
    return nil unless uri

    path = uri.path
    case
    when path.include?("/github_logs")
      "github_logs"
    when path.include?("/time_logs")
      "time_logs"
    when path.include?("/milestones")
      "milestones"
    end
  end

  # Turbo Streams for GitHub logs page
  def github_logs_turbo_streams
    result = GithubLogsDataService.call(@selected_project, current_user)
    return [] unless result.success?

    data = result.value!

    [
      turbo_stream.update(
        "github_stats",
        partial: "github_logs/stats_section",
        locals: data[:stats_locals]
      ),
      turbo_stream.update(
        "contributions_summary",
        partial: "github_logs/contributions_section",
        locals: data[:contributions_locals]
      ),
      turbo_stream.replace(
        "github_commits",
        partial: "github_logs/commits_frame",
        locals: data[:commits_locals]
      )
    ]
  end

  # Turbo Streams for time logs page
  def time_logs_turbo_streams
    result = TimeLogsDataService.call(@selected_project, current_user)
    return [] unless result.success?

    data = result.value!

    [
      turbo_stream.update(
        "milestones_section",
        partial: "time_logs/milestones_section",
        locals: data[:milestones_locals]
      ),
      turbo_stream.update(
        "pending_confirmation_section",
        partial: "time_logs/pending_confirmation_section",
        locals: data[:pending_locals]
      ),
      turbo_stream.update(
        "completed_tasks_section",
        partial: "time_logs/completed_tasks_section",
        locals: data[:completed_locals]
      ),
      turbo_stream.update(
        "remaining_time_progress",
        partial: "remaining_time_progress",
        locals: data[:progress_locals]
      )
    ]
  end

  # Turbo Streams for milestones page
  def milestones_turbo_streams
    # Milestones page typically just needs the context nav updated
    # Additional streams can be added here if needed
    []
  end
end
