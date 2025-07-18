class OnboardingController < ApplicationController
  layout "onboarding"

  def entrepreneur
    service = UserOnboardingService.new(current_user)
    @role_name = service.determine_current_role

    if @role_name.nil? || ![ Role::ENTREPRENEUR, Role::CO_FOUNDER ].include?(@role_name)
      redirect_to dashboard_path, alert: "You don't have the Entrepreneur or Co-Founder role."
    end
  end

  def mentor
    service = UserOnboardingService.new(current_user)
    @role_name = service.determine_current_role

    if @role_name != Role::MENTOR
      redirect_to dashboard_path, alert: "You don't have the Mentor role."
    end
  end

  def complete_onboarding
    service = UserOnboardingService.new(current_user, session)
    role_name = params[:role_name] || service.determine_current_role

    unless role_name
      redirect_to dashboard_path, alert: "No role found to complete onboarding for."
      return
    end

    result = service.complete_onboarding_for_role(role_name, user_onboarding_params)

    if result[:success]
      handle_onboarding_success(result[:next_action])
    else
      redirect_to request.referer || dashboard_path, alert: result[:error]
    end
  end

  private

  def handle_onboarding_success(next_action)
    case next_action[:type]
    when :redirect_to_onboarding
      if next_action[:path] == :entrepreneur
        redirect_to onboarding_entrepreneur_path, notice: next_action[:message]
      elsif next_action[:path] == :mentor
        redirect_to onboarding_mentor_path, notice: next_action[:message]
      end
    when :redirect_to_new_project
      session[:comes_from_project_new] = false
      redirect_to new_project_path, notice: next_action[:message]
    when :redirect_to_dashboard
      redirect_to dashboard_path, notice: next_action[:message]
    else
      redirect_to dashboard_path, notice: "Onboarding completed!"
    end
  end

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
