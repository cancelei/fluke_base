class ProfileController < ApplicationController
  def show
    @user = current_user
    @roles = @user.roles
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      redirect_to profile_show_path, notice: "Profile was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :avatar, :bio, :industry, :github_username, :github_token, :show_project_context_nav, expertise: [])
  end
end
