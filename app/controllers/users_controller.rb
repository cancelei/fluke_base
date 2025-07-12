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
        format.html do
          redirect_to project_path(@selected_project), notice: "Project selected."
        end
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("navbar-projects",
              partial: "shared/navbar_projects",
              locals: { 
                current_user: current_user, 
                selected_project: @selected_project,
                controller_name: controller_name,
                request: request
              }
            ),
            turbo_stream.replace("project-context-nav",
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
        current_user.update(current_role_id: role.id)
      end
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "navbar-projects",
              partial: "shared/navbar_projects",
              locals: { current_user: current_user, selected_project: current_user.selected_project }
            ),
            turbo_stream.replace(
              "project-context",
              partial: "shared/project_context_nav",
              locals: { selected_project: current_user.selected_project }
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
