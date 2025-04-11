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
end
