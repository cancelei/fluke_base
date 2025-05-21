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
      agreement.initiator_id = @current_user.id
      agreement.status = Agreement::PENDING

      # Set entrepreneur for mentor-initiated
      if (@params[:mentor_initiated] || acting_as_mentor) && @current_user.has_role?(:mentor)
        if agreement.project_id.present?
          project = Project.find(agreement.project_id)
          agreement.entrepreneur_id = project.user_id if agreement.entrepreneur_id.blank?
        elsif acting_as_mentor
          return [nil, :select_entrepreneur]
        end
      end

      # Counter offer logic
      original_agreement = nil
      if agreement.counter_to_id.present?
        original_agreement = Agreement.find(agreement.counter_to_id)
        unless original_agreement.pending? || original_agreement.countered?
          return [nil, :invalid_counter_offer, original_agreement]
        end
        agreement.project_id = original_agreement.project_id
        agreement.agreement_type = original_agreement.agreement_type
        agreement.payment_type = original_agreement.payment_type
        agreement.start_date = original_agreement.start_date
        agreement.end_date = original_agreement.end_date
        agreement.weekly_hours = original_agreement.weekly_hours
        agreement.hourly_rate = original_agreement.hourly_rate
        agreement.equity_percentage = original_agreement.equity_percentage
        agreement.tasks = original_agreement.tasks
        agreement.terms = original_agreement.terms
      end

      agreement.agreement_type = @params[:weekly_hours].present? ? Agreement::MENTORSHIP : Agreement::CO_FOUNDER

      if agreement.save
        agreement.update(initiator_id: @current_user.id) if original_agreement
        original_agreement&.update(status: Agreement::COUNTERED)
        [agreement, :success, original_agreement]
      else
        [agreement, :error]
      end
    end
  end
end
