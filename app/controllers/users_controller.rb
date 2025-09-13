class UsersController < ApplicationController
  def update_role
    @roles = Role.all
  end

  def change_role
    role = Role.find(params[:role_id])
    role_manager = RoleManager.new(current_user)

    if role_manager.add_role(role.name)
      redirect_to role_manager.onboarding_path_for_role(role.name), notice: "Your role has been updated to #{role.name}."
    else
      redirect_to update_role_users_path, alert: "Unable to update your role."
    end
  end

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
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_back fallback_location: root_path, alert: "Project not found." }
      end
    end
  end

  def switch_current_role
    role = Role.find(params[:role_id])
    if current_user.current_role != role
      if role.name == "Mentor"
        current_user.update!(current_role_id: role.id, selected_project_id: nil)
      else
        projects = Project.where(user_id: current_user.id)
        selected_project_id = projects.first&.id.presence

        current_user.update!(current_role_id: role.id, selected_project_id: selected_project_id)
      end
      respond_to do |format|
        format.turbo_stream do
          # Get the updated selected project after role change
          updated_selected_project = if role.name == "Mentor"
                                       current_user.initiated_agreements.active.first&.project ||
                                       current_user.received_agreements.active.first&.project
          else
                                       current_user.selected_project
          end

          render turbo_stream: [
            turbo_stream.replace(
              "navbar-projects",
              partial: "shared/navbar_projects",
              locals: { current_user: current_user, selected_project: updated_selected_project }
            ),
            turbo_stream.replace(
              "project-context",
              partial: "shared/project_context_nav",
              locals: { selected_project: updated_selected_project }
            ),
            turbo_stream.update(
              "current_role",
              html: role.name.humanize
            )
          ]
        end
        format.html { redirect_to root_path, notice: "Current role switched to #{role.name}." }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_to root_path, alert: "You are already in the #{role.name} role." }
      end
    end
  end
end
