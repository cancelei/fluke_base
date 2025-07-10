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
    user_is_mentor = current_user.current_role_id == 2 # id 2 is for mentor here
    project = current_user.projects.find_by(id: params[:project_id])
    if project
      # if user is a mentor and user selects a project then we will change it to Entrepreneur
      current_user.update(selected_project_id: project.id, current_role_id: 1) if user_is_mentor
      current_user.update(selected_project_id: project.id) unless user_is_mentor
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, notice: "Project selected." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("navbar-projects", partial: "shared/navbar_projects", locals: { current_user: current_user, selected_project: project }),
            turbo_stream.replace("project-context", partial: "shared/project_context_nav", locals: { selected_project: project })
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
