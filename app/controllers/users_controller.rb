class UsersController < ApplicationController
  def update_selected_project
    service = ProjectSelectionService.new(current_user, session, params[:project_id])

    if service.call
      @selected_project = service.project  # Set instance variable for the view

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
          # Update both the navbar projects and project context nav
          render turbo_stream: [
            turbo_stream.replace(
              "navbar-projects",
              partial: "shared/navbar_projects",
              locals: { current_user: current_user, selected_project: @selected_project }
            ),
            turbo_stream.replace(
              "project-context",
              partial: "shared/project_context_nav",
              locals: { selected_project: @selected_project }
            )
          ]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_content }
        format.html { redirect_back fallback_location: root_path, alert: "Project not found." }
      end
    end
  end
end
