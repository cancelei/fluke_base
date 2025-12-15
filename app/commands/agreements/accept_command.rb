# frozen_string_literal: true

module Agreements
  # Command to accept an agreement
  # Handles authorization, state transition, and notifications
  # @return [Dry::Monads::Result] Success(agreement) or Failure(error)
  class AcceptCommand < ApplicationCommand
    def execute
      agreement = find_agreement
      authorize_action(agreement)

      morph :nothing

      if agreement.accept!
        notify_other_party(agreement, :accept)
        render_success(agreement)
        Success(agreement)
      else
        render_failure
        failure_result(:transition_failed, "Unable to accept agreement")
      end
    end

    private

    def find_agreement
      Agreement.includes(
        project: :user,
        agreement_participants: :user
      ).find(params[:id])
    end

    def authorize_action(agreement)
      # Check using presenter logic - only other party can accept
      presenter = AgreementPresenter.new(agreement, controller.view_context)
      unless presenter.can_be_accepted_by?(current_user)
        flash_error("You cannot accept this agreement")
        throw :halt
      end
    end

    def notify_other_party(agreement, action)
      other_party = current_user.id == agreement.initiator&.id ? agreement.other_party : agreement.initiator

      case action
      when :accept
        NotificationService.new(other_party).notify(
          title: "Agreement Accepted",
          message: "#{current_user.full_name} has accepted an agreement for project #{agreement.project.name}",
          url: controller.agreement_path(agreement)
        )

        conversation = Conversation.between(current_user.id, other_party.id)
        Message.create!(
          conversation: conversation,
          user: current_user,
          body: "[Automated] #{current_user.full_name} has accepted an agreement for project '#{agreement.project.name}'. #{controller.agreement_url(agreement)}"
        )
      end
    end

    def render_success(agreement)
      # Replace the agreement content with updated state
      update_frame(
        ActionView::RecordIdentifier.dom_id(agreement),
        partial: "agreements/agreement_show_content",
        locals: {
          agreement: agreement,
          project: agreement.project,
          can_view_full_details: agreement.can_view_full_project_details?(current_user)
        }
      )

      toast_success("Agreement was successfully accepted")
    end

    def render_failure
      toast_error("Unable to accept agreement")
    end
  end
end
