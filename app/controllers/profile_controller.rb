class ProfileController < ApplicationController
  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    # Debug logging
    Rails.logger.debug "Social media params: #{user_params.slice(:linkedin, :x, :youtube, :facebook, :tiktok).inspect}"

    # Explicitly assign social media attributes to ensure they're updated
    @user.linkedin = user_params[:linkedin]
    @user.x = user_params[:x]
    @user.youtube = user_params[:youtube]
    @user.facebook = user_params[:facebook]
    @user.tiktok = user_params[:tiktok]

    if @user.update(user_params)
      redirect_to profile_show_path, notice: "Profile was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :avatar, :bio, :industry, :github_username, :github_token, :show_project_context_nav, :multi_project_tracking, :linkedin, :x, :youtube, :facebook, :tiktok, expertise: [])
  end
end
