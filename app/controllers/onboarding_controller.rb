class OnboardingController < ApplicationController
  layout "onboarding"

  def entrepreneur
    # For entrepreneurs and co-founders
    if current_user.has_role?(Role::ENTREPRENEUR) && !current_user.onboarded_for?(Role::ENTREPRENEUR)
      @role_name = Role::ENTREPRENEUR
    elsif current_user.has_role?(Role::CO_FOUNDER) && !current_user.onboarded_for?(Role::CO_FOUNDER)
      @role_name = Role::CO_FOUNDER
    else
      redirect_to dashboard_path, alert: "You don't have the Entrepreneur or Co-Founder role."
    end
  end

  def mentor
    # For mentors
    if current_user.has_role?(Role::MENTOR)
      @role_name = Role::MENTOR
    else
      redirect_to dashboard_path, alert: "You don't have the Mentor role."
    end
  end

  def complete_onboarding
    # Find which role is being onboarded
    role_name = nil

    if params[:role_name].present?
      role_name = params[:role_name]
    elsif current_user.has_role?(Role::ENTREPRENEUR) && !current_user.onboarded_for?(Role::ENTREPRENEUR)
      role_name = Role::ENTREPRENEUR
    elsif current_user.has_role?(Role::CO_FOUNDER) && !current_user.onboarded_for?(Role::CO_FOUNDER)
      role_name = Role::CO_FOUNDER
    elsif current_user.has_role?(Role::MENTOR) && !current_user.onboarded_for?(Role::MENTOR)
      role_name = Role::MENTOR
    end

    unless role_name
      redirect_to dashboard_path, alert: "No role found to complete onboarding for."
      return
    end

    # Update user fields from form
    if current_user.update(user_onboarding_params)
      # Mark the role as onboarded
      if current_user.mark_onboarded_for(role_name)
        # Check if there are more roles to onboard
        if path = current_user.current_onboarding_path
          if path == :entrepreneur
            redirect_to onboarding_entrepreneur_path, notice: "#{role_name} onboarding completed! Please complete onboarding for your other roles."
          elsif path == :mentor
            redirect_to onboarding_mentor_path, notice: "#{role_name} onboarding completed! Please complete onboarding for your other roles."
          end
        else
          if session[:comes_from_project_new]
            session[:comes_from_project_new] = false
            redirect_to new_project_path, notice: "#{role_name} onboarding completed! Now you can create the project"
            return
          end
          redirect_to dashboard_path, notice: "#{role_name} onboarding completed! Welcome to FlukeBase."
        end
      else
        redirect_to dashboard_path, alert: "Could not complete onboarding. Please try again."
      end
    else
      redirect_to request.referer || dashboard_path, alert: "Could not save your information. Please check your input."
    end
  end

  private

  def user_onboarding_params
    params.require(:user).permit(
      # Mentor fields
      :bio,
      :years_of_experience,
      :hourly_rate,
      :business_stage,
      :industry,
      :business_info,
      expertise: [],
      industries: [],
      help_seekings: []
    )
  end
end
