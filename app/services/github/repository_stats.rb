# frozen_string_literal: true

module Github
  # Fetches public repository statistics (stars, forks) from GitHub API
  #
  # Results are cached for 1 hour to minimize API calls and improve performance.
  # No authentication required - only fetches public data.
  #
  # Usage:
  #   stats = Github::RepositoryStats.call
  #   if stats[:stars]
  #     puts "#{stats[:stars]} stars"
  #   end
  #
  class RepositoryStats < Base
    CACHE_KEY = "github_repository_stats"
    CACHE_DURATION = 1.hour
    REPO = "cancelei/fluke_base"

    def call
      Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_DURATION) do
        fetch_stats
      end
    rescue StandardError => e
      log("Repository stats fetch failed: #{e.message}", level: :error)
      { stars: nil, forks: nil, error: true }
    end

    private

    def fetch_stats
      client = build_client
      repo = client.repository(REPO)

      {
        stars: repo.stargazers_count,
        forks: repo.forks_count,
        watchers: repo.watchers_count
      }
    rescue Octokit::Error => e
      log("GitHub API error: #{e.message}", level: :error)
      { stars: nil, forks: nil, error: true }
    end
  end
end
