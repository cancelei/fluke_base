class UsersController < ApplicationController
  def update_role
    @roles = Role.all
  end

  def change_role
    role = Role.find(params[:role_id])

    if current_user.add_role(role.name)
      redirect_to dashboard_path, notice: "Your role has been updated to #{role.name}."

      # Redirect to appropriate onboarding if it's a new role type
      if role.name == Role::ENTREPRENEUR || role.name == Role::CO_FOUNDER
        redirect_to onboarding_entrepreneur_path
      elsif role.name == Role::MENTOR
        redirect_to onboarding_mentor_path
      else
        redirect_to dashboard_path, notice: "Your role has been updated to #{role.name}."
      end
    else
      redirect_to update_role_users_path, alert: "Unable to update your role."
    end
  end
end
