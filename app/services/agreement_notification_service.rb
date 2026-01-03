# frozen_string_literal: true

# Service for handling notifications and messages related to agreement actions
class AgreementNotificationService < ApplicationService
  def initialize(agreement, current_user, action)
    @agreement = agreement
    @current_user = current_user
    @action = action
  end

  def call
    return failure_result(:not_found, "Other party not found") unless other_party

    notify_and_message
    Success(true)
  end

  private

  def notify_and_message
    # Create notification
    NotificationService.new(other_party).notify(
      title: notification_title,
      message: notification_message,
      url: helpers.agreement_path(@agreement)
    )

    # Create message in conversation
    conversation = Conversation.between(@current_user.id, other_party.id)
    Message.create!(
      conversation: conversation,
      user: @current_user,
      body: message_body
    )
  end

  def other_party
    @other_party ||= @agreement.other_party_for(@current_user)
  end

  def notification_title
    case @action
    when :create then "New Agreement Proposal"
    when :counter_offer then "New Counter Offer"
    when :update then "Agreement Updated"
    when :accept then "Agreement Accepted"
    when :reject then "Agreement Rejected"
    when :complete then "Agreement Completed"
    when :cancel then "Agreement Canceled"
    else "Agreement Update"
    end
  end

  def notification_message
    case @action
    when :create then "#{@current_user.full_name} has proposed an agreement for project #{@agreement.project.name}"
    when :counter_offer then "#{@current_user.full_name} has made a counter offer for project #{@agreement.project.name}"
    when :update then "#{@current_user.full_name} has changed the terms for an agreement for project #{@agreement.project.name}"
    when :accept then "#{@current_user.full_name} has accepted an agreement for project #{@agreement.project.name}"
    when :reject then "#{@current_user.full_name} has rejected an agreement for project #{@agreement.project.name}"
    when :complete then "#{@current_user.full_name} has marked the agreement for project #{@agreement.project.name} as completed"
    when :cancel then "#{@current_user.full_name} has canceled an agreement for project #{@agreement.project.name}"
    else "There is an update on your agreement for project #{@agreement.project.name}"
    end
  end

  def message_body
    "[Automated] #{notification_message}. Please review the new terms. <a href='#{helpers.agreement_path(@agreement)}' class='p-1 bg-white text-gray-500'>View Details</a>"
  end

  def helpers
    Rails.application.routes.url_helpers
  end
end
