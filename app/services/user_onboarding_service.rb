class UserOnboardingService
  def initialize(user, session = {})
    @user = user
    @session = session
  end

  def determine_current_role
    if @user.has_role?(Role::ENTREPRENEUR) && !@user.onboarded_for?(Role::ENTREPRENEUR)
      Role::ENTREPRENEUR
    elsif @user.has_role?(Role::CO_FOUNDER) && !@user.onboarded_for?(Role::CO_FOUNDER)
      Role::CO_FOUNDER
    elsif @user.has_role?(Role::MENTOR) && !@user.onboarded_for?(Role::MENTOR)
      Role::MENTOR
    else
      nil
    end
  end

  def complete_onboarding_for_role(role_name, user_params)
    return { success: false, error: "Invalid role" } unless valid_role?(role_name)

    ActiveRecord::Base.transaction do
      # Update user fields from form
      if @user.update(user_params)
        # Mark the role as onboarded
        if @user.mark_onboarded_for(role_name)
          next_action = determine_next_action(role_name)
          { success: true, next_action: next_action }
        else
          { success: false, error: "Could not complete onboarding. Please try again." }
        end
      else
        { success: false, error: "Could not save your information. Please check your input." }
      end
    end
  end

  def determine_next_action(completed_role)
    # Check if there are more roles to onboard
    next_path = @user.current_onboarding_path

    if next_path == :entrepreneur
      {
        type: :redirect_to_onboarding,
        path: :entrepreneur,
        message: "#{completed_role} onboarding completed! Please complete onboarding for your other roles."
      }
    elsif next_path == :mentor
      {
        type: :redirect_to_onboarding,
        path: :mentor,
        message: "#{completed_role} onboarding completed! Please complete onboarding for your other roles."
      }
    elsif session_redirect_needed?
      {
        type: :redirect_to_new_project,
        message: "#{completed_role} onboarding completed! Now you can create the project"
      }
    else
      {
        type: :redirect_to_dashboard,
        message: "#{completed_role} onboarding completed! Welcome to FlukeBase."
      }
    end
  end

  private

  def valid_role?(role_name)
    [ Role::ENTREPRENEUR, Role::CO_FOUNDER, Role::MENTOR ].include?(role_name)
  end

  def session_redirect_needed?
    @session[:comes_from_project_new].present?
  end
end
