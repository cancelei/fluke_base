# frozen_string_literal: true

# == Schema Information
#
# Table name: github_app_installations
#
#  id                   :bigint           not null, primary key
#  account_login        :string
#  account_type         :string
#  installed_at         :datetime
#  permissions          :jsonb
#  repository_selection :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  installation_id      :string           not null
#  user_id              :bigint           not null
#
# Indexes
#
#  index_github_app_installations_on_installation_id  (installation_id) UNIQUE
#  index_github_app_installations_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class GithubAppInstallation < ApplicationRecord
  belongs_to :user

  validates :installation_id, presence: true, uniqueness: true

  # Returns list of accessible repository full names (owner/repo)
  def accessible_repos
    repository_selection["repositories"] || []
  end

  # Check if this installation has access to a specific repository
  # @param repo_full_name [String] Repository in "owner/repo" format
  # @return [Boolean]
  def has_access_to?(repo_full_name)
    return true if repository_selection["selection"] == "all"

    accessible_repos.any? { |repo| repo["full_name"] == repo_full_name }
  end

  # Check if installation has all-repos access
  def all_repos_access?
    repository_selection["selection"] == "all"
  end

  # Check if installation is for a user account
  def user_account?
    account_type == "User"
  end

  # Check if installation is for an organization
  def organization_account?
    account_type == "Organization"
  end
end
