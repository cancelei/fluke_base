# frozen_string_literal: true

# Shared concern for resolving batch project selections.
# Used by FlukeBase Connect API controllers for multi-project operations.
#
# Supports two selection modes:
# - params[:all] = "true" - returns all accessible projects
# - params[:project_ids] = [1, 2, 3] - returns specific projects from accessible set
#
# @example Usage in controller
#   class MyController < BaseController
#     include BatchProjectResolvable
#
#     def batch_action
#       projects = resolve_batch_projects
#       # ...
#     end
#   end
module BatchProjectResolvable
  extend ActiveSupport::Concern

  private

  # Resolve projects for batch operations based on params.
  # Filters against current_user.accessible_projects for security.
  #
  # @return [Array<Project>] Array of accessible projects matching selection criteria
  def resolve_batch_projects
    accessible = current_user.accessible_projects

    if params[:all] == "true" || params[:all] == true
      accessible
    elsif params[:project_ids].present?
      project_ids = Array(params[:project_ids]).map(&:to_i)
      accessible.select { |p| project_ids.include?(p.id) }
    else
      []
    end
  end
end
