# frozen_string_literal: true

# Consolidated service for checking duplicate agreements.
# Replaces duplicate logic from:
# - AgreementsController#duplicate_agreement_exists? / #duplicate_agreement_flash
# - AgreementForm#no_duplicate_agreement
# - AgreementsQuery#check_duplicate_agreement
class AgreementDuplicateChecker < ApplicationService
  attr_reader :user1_id, :user2_id, :project_id, :exclude_agreement_id

  # @param user1_id [Integer] First user ID (usually current user)
  # @param user2_id [Integer] Second user ID (other party)
  # @param project_id [Integer] Project ID to check
  # @param exclude_agreement_id [Integer, nil] Agreement ID to exclude (for updates)
  def initialize(user1_id:, user2_id:, project_id:, exclude_agreement_id: nil)
    @user1_id = user1_id
    @user2_id = user2_id
    @project_id = project_id
    @exclude_agreement_id = exclude_agreement_id
  end

  # Check if a duplicate agreement exists
  # @return [Boolean] true if duplicate exists
  def exists?
    duplicate_query.exists?
  end

  # Find the duplicate agreement if it exists
  # @return [Agreement, nil] The duplicate agreement or nil
  def find_duplicate
    duplicate_query.take
  end

  # Get user-friendly message about the duplicate
  # @param link_helper [Object] Rails URL helper context (e.g., controller)
  # @return [String] HTML-safe flash message with link to existing agreement
  def flash_message(link_helper:)
    agreement = find_duplicate
    return nil unless agreement

    path = link_helper.agreement_path(agreement.id)
    "You currently have an agreement with this party for this project. View agreement <b><a href='#{path}'>here</a></b>".html_safe
  end

  private

  def duplicate_query
    query = base_query
    query = query.where.not(id: exclude_agreement_id) if exclude_agreement_id.present?
    query
  end

  def base_query
    Agreement.joins(:agreement_participants)
      .where(project_id:, status: active_statuses)
      .where(agreement_participants: { user_id: [user1_id, user2_id] })
      .group("agreements.id")
      .having("COUNT(agreement_participants.id) = 2")
  end

  def active_statuses
    [Agreement::ACCEPTED, Agreement::PENDING]
  end
end
