class RolesController < ApplicationController
  def index
    @roles = Role.all
    @user_roles = current_user.roles

    # Check eligibility for roles user doesn't have
    @role_manager = RoleManager.new(current_user)
    @eligible_roles = {}

    Role.all.each do |role|
      next if current_user.has_role?(role.name)
      @eligible_roles[role.name] = @role_manager.eligible_for_role?(role.name)
    end
  end

  def request_role
    role_name = params[:role_name]

    if Role.exists?(name: role_name)
      role_manager = RoleManager.new(current_user)

      if role_manager.add_role(role_name)
        redirect_to roles_path, notice: "You now have the #{role_name.humanize} role."
      else
        redirect_to roles_path, alert: "You don't meet the requirements for the #{role_name.humanize} role yet."
      end
    else
      redirect_to roles_path, alert: "Invalid role requested."
    end
  end
end
