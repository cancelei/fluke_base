# frozen_string_literal: true

module Agreements
  class AgreementCreationService
    def initialize(current_user, params, session)
      @current_user = current_user
      @params = params
      @session = session
    end

    def call
      agreement = Agreement.new(@params)
      acting_as_mentor = @session[:acting_as_mentor].present? && @current_user.has_role?(:mentor)

      # Set entrepreneur for mentor-initiated
      if (@params[:mentor_initiated] || acting_as_mentor) && @current_user.has_role?(:mentor)
        if agreement.project_id.present?
          project = Project.find(agreement.project_id)
          agreement.entrepreneur_id = project.user_id if agreement.entrepreneur_id.blank?
        elsif acting_as_mentor
          return [ nil, :select_entrepreneur ]
        end
      end

      # Counter offer logic
      agreement.countered_to(agreement.counter_to_id) if agreement.counter_to_id.present?

      agreement.agreement_type = @params[:weekly_hours].present? ? Agreement::MENTORSHIP : Agreement::CO_FOUNDER

      if agreement.save
        [ agreement, :success, agreement.counter_to_id ]
      else
        [ agreement, :error ]
      end
    end
  end
end
