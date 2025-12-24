# frozen_string_literal: true

# Track GitHub refresh token expiration for re-authentication prompts
#
# GitHub refresh tokens expire after 6 months. When expired, users need
# to re-authenticate via OAuth to get a new refresh token.
#
# See: https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/refreshing-user-access-tokens
class AddGithubRefreshTokenExpiresAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :github_refresh_token_expires_at, :datetime
  end
end
