# frozen_string_literal: true

module Webhooks
  # Handles GitHub App webhook events
  #
  # Events handled:
  # - installation: App installed/uninstalled on account
  # - installation_repositories: Repositories added/removed from installation
  #
  class GithubController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    before_action :verify_webhook_signature

    # POST /webhooks/github
    def create
      event = request.headers["X-GitHub-Event"]
      payload = JSON.parse(request.raw_post, symbolize_names: true)

      Rails.logger.info "[Webhooks::Github] Received event: #{event}"

      case event
      when "installation"
        handle_installation_event(payload)
      when "installation_repositories"
        handle_installation_repositories_event(payload)
      when "ping"
        handle_ping_event(payload)
      else
        Rails.logger.info "[Webhooks::Github] Unhandled event type: #{event}"
      end

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.error "[Webhooks::Github] Invalid JSON payload: #{e.message}"
      head :bad_request
    rescue StandardError => e
      Rails.logger.error "[Webhooks::Github] Error processing webhook: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      head :internal_server_error
    end

    private

    # Verify GitHub webhook signature using X-Hub-Signature-256 header
    # Per GitHub's security best practices:
    # "Set webhook secrets and verify signature matches for incoming events"
    # See: https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/best-practices-for-creating-a-github-app
    def verify_webhook_signature
      secret = Github::AppConfig.webhook_secret

      # In production, require webhook secret to be configured
      if secret.blank?
        if Rails.env.production?
          Rails.logger.error "[Webhooks::Github] SECURITY: Webhook secret not configured in production!"
          head :internal_server_error
          return false
        else
          Rails.logger.warn "[Webhooks::Github] Skipping signature verification (no secret configured)"
          return true
        end
      end

      signature = request.headers["X-Hub-Signature-256"]
      unless signature.present?
        Rails.logger.warn "[Webhooks::Github] Missing X-Hub-Signature-256 header"
        head :unauthorized
        return false
      end

      # Compute expected signature using HMAC-SHA256
      payload_body = request.raw_post
      expected_signature = "sha256=" + OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest.new("sha256"),
        secret,
        payload_body
      )

      # Use timing-safe comparison to prevent timing attacks
      unless Rack::Utils.secure_compare(expected_signature, signature)
        Rails.logger.warn "[Webhooks::Github] Invalid webhook signature"
        head :unauthorized
        return false
      end

      true
    end

    def handle_installation_event(payload)
      action = payload[:action]
      installation = payload[:installation]
      sender = payload[:sender]

      Rails.logger.info "[Webhooks::Github] Installation event: #{action} by #{sender[:login]}"

      case action
      when "created"
        create_or_update_installation(installation, payload[:repositories] || [])
      when "deleted"
        delete_installation(installation[:id])
      when "suspend"
        suspend_installation(installation[:id])
      when "unsuspend"
        unsuspend_installation(installation[:id])
      end
    end

    def handle_installation_repositories_event(payload)
      action = payload[:action]
      installation = payload[:installation]

      Rails.logger.info "[Webhooks::Github] Repositories #{action} for installation #{installation[:id]}"

      record = GithubAppInstallation.find_by(installation_id: installation[:id].to_s)
      return unless record

      case action
      when "added"
        add_repositories_to_installation(record, payload[:repositories_added])
      when "removed"
        remove_repositories_from_installation(record, payload[:repositories_removed])
      end
    end

    def handle_ping_event(payload)
      Rails.logger.info "[Webhooks::Github] Ping received: #{payload[:zen]}"
    end

    def create_or_update_installation(installation, repositories)
      # Find user by GitHub UID (the account that installed the app)
      account = installation[:account]
      user = User.find_by(github_uid: account[:id].to_s) ||
             User.find_by(github_username: account[:login])

      unless user
        Rails.logger.warn "[Webhooks::Github] No user found for GitHub account: #{account[:login]}"
        return
      end

      record = GithubAppInstallation.find_or_initialize_by(installation_id: installation[:id].to_s)

      record.update!(
        user:,
        account_login: account[:login],
        account_type: account[:type],
        repository_selection: build_repository_selection(installation, repositories),
        permissions: installation[:permissions]&.to_h || {},
        installed_at: Time.current
      )

      Rails.logger.info "[Webhooks::Github] Installation created/updated for user: #{user.email}"
    end

    def delete_installation(installation_id)
      record = GithubAppInstallation.find_by(installation_id: installation_id.to_s)
      if record
        Rails.logger.info "[Webhooks::Github] Deleting installation for user: #{record.user.email}"
        record.destroy
      end
    end

    def suspend_installation(installation_id)
      # For now, just log the suspension
      # Could add a suspended_at column if needed
      Rails.logger.info "[Webhooks::Github] Installation #{installation_id} suspended"
    end

    def unsuspend_installation(installation_id)
      Rails.logger.info "[Webhooks::Github] Installation #{installation_id} unsuspended"
    end

    def add_repositories_to_installation(record, repositories)
      current_repos = record.repository_selection["repositories"] || []
      new_repos = repositories.map { |r| { "id" => r[:id], "full_name" => r[:full_name] } }

      record.update!(
        repository_selection: record.repository_selection.merge(
          "repositories" => (current_repos + new_repos).uniq { |r| r["id"] }
        )
      )
    end

    def remove_repositories_from_installation(record, repositories)
      current_repos = record.repository_selection["repositories"] || []
      removed_ids = repositories.map { |r| r[:id] }

      record.update!(
        repository_selection: record.repository_selection.merge(
          "repositories" => current_repos.reject { |r| removed_ids.include?(r["id"]) }
        )
      )
    end

    def build_repository_selection(installation, repositories)
      selection_type = installation[:repository_selection] # "all" or "selected"

      {
        "selection" => selection_type,
        "repositories" => repositories.map do |repo|
          {
            "id" => repo[:id],
            "full_name" => repo[:full_name],
            "private" => repo[:private]
          }
        end
      }
    end
  end
end
