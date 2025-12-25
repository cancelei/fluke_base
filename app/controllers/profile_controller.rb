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
    Rails.logger.debug "Social media params: #{user_params.slice(:linkedin, :x, :youtube, :facebook, :tiktok, :instagram).inspect}"

    # Explicitly assign social media attributes to ensure they're updated
    @user.linkedin = user_params[:linkedin]
    @user.x = user_params[:x]
    @user.youtube = user_params[:youtube]
    @user.facebook = user_params[:facebook]
    @user.tiktok = user_params[:tiktok]
    @user.instagram = user_params[:instagram]

    if @user.update(user_params)
      # Use status: :see_other (303) for Turbo to properly follow the redirect after PATCH
      redirect_to profile_show_path, notice: "Profile was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :avatar, :bio, :industry, :github_username, :github_token, :multi_project_tracking, :linkedin, :x, :youtube, :facebook, :tiktok, :instagram, skills: [])
  end
end
