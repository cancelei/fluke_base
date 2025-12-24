# frozen_string_literal: true

# Migration to prepare GitHub token columns for Active Record Encryption
#
# Per GitHub's security best practices:
# "You should encrypt the tokens on your back end and ensure there is
# security around the systems that can access the tokens."
#
# Encrypted values are longer than plain text, so we need to:
# 1. Change string columns to text for encrypted storage
# 2. Existing data will be encrypted when the model encrypts attribute is added
#
# See: https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/best-practices-for-creating-a-github-app
class EncryptGithubTokenColumns < ActiveRecord::Migration[8.0]
  def up
    # Change columns to text to accommodate encrypted values
    # Encrypted strings are significantly longer than originals
    change_column :users, :github_user_access_token, :text
    change_column :users, :github_refresh_token, :text
    change_column :users, :github_token, :text

    # If there's existing unencrypted data, we need to encrypt it
    # This is handled by a rake task after migration runs
    # See: lib/tasks/encrypt_github_tokens.rake
  end

  def down
    # WARNING: Reverting will lose encrypted data
    # Only revert if you've decrypted first
    change_column :users, :github_user_access_token, :string
    change_column :users, :github_refresh_token, :string
    change_column :users, :github_token, :string, limit: 255
  end
end
