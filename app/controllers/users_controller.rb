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
    if params[:acting_as_mentor].present?
      # When acting as a mentor, clear the selected project
      session[:acting_as_mentor] = true
      current_user.update(selected_project_id: nil)

      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: "Now acting as mentor." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("navbar-projects", partial: "shared/navbar_projects", locals: { current_user: current_user, selected_project: nil }) }
      end
      return
    else
      # Clear the acting_as_mentor flag when selecting a project
      session[:acting_as_mentor] = false
    end

    project = current_user.projects.find_by(id: params[:project_id])
    if project
      current_user.update(selected_project_id: project.id)
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: "Project selected." }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("navbar-projects", partial: "shared/navbar_projects", locals: { current_user: current_user, selected_project: project }) }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html { redirect_back fallback_location: root_path, alert: "Project not found." }
      end
    end
  end
end
