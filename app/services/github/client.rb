# frozen_string_literal: true

module Github
  # Thin wrapper around Octokit for GitHub API interactions
  #
  # Provides consistent error handling and Result monad returns
  # for all GitHub API calls.
  #
  # Usage:
  #   client = Github::Client.new(access_token: "ghp_xxx")
  #   result = client.commits("owner/repo", sha: "main", per_page: 100)
  #   if result.success?
  #     commits = result.value!
  #   end
  #
  class Client < Base
    attr_reader :octokit

    # Initialize the client
    # @param access_token [String, nil] GitHub personal access token
    def initialize(access_token: nil)
      @octokit = build_client(access_token)
    end

    # Fetch commits from a repository
    # @param repo_path [String] Repository path (owner/repo)
    # @param options [Hash] Options passed to Octokit (sha, per_page, page, etc.)
    # @return [Dry::Monads::Result] Success with commits or Failure with error
    def commits(repo_path, options = {})
      with_api_error_handling do
        result = octokit.commits(repo_path, options)
        Success(result)
      end
    end

    # Fetch a single commit with full details
    # @param repo_path [String] Repository path (owner/repo)
    # @param sha [String] Commit SHA
    # @return [Dry::Monads::Result] Success with commit or Failure with error
    def commit(repo_path, sha)
      with_api_error_handling do
        result = octokit.commit(repo_path, sha)
        Success(result)
      end
    end

    # Fetch branches from a repository
    # @param repo_path [String] Repository path (owner/repo)
    # @return [Dry::Monads::Result] Success with branches or Failure with error
    def branches(repo_path)
      with_api_error_handling do
        result = octokit.branches(repo_path)
        Success(result)
      end
    end

    # Get the last response from Octokit (for pagination)
    # @return [Sawyer::Response, nil]
    def last_response
      octokit.last_response
    end

    # Check rate limit status
    # @return [Hash] Rate limit information
    def rate_limit
      {
        limit: octokit.rate_limit.limit,
        remaining: octokit.rate_limit.remaining,
        resets_at: Time.at(octokit.rate_limit.resets_at.to_i)
      }
    rescue Octokit::Error
      { limit: 0, remaining: 0, resets_at: Time.current }
    end
  end
end
