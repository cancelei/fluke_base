# frozen_string_literal: true

# Value object for unregistered GitHub contributors
# Provides a User-like interface for views
UnregisteredGithubUser = Data.define(:id, :name, :github_username, :unregistered) do
  def avatar_url = nil
  def full_name = name
  def owner?(_project) = false
end
