# frozen_string_literal: true

module Github
  # Enriches existing commits with stats (lines added/removed, changed files)
  #
  # This service is designed to run after initial commit sync, fetching
  # detailed stats for commits that were synced in "fast mode".
  #
  # Rate Limit Aware:
  # - Checks rate limit before each API call
  # - Stops gracefully when approaching threshold
  # - Returns count of enriched commits for retry scheduling
  #
  # Usage:
  #   result = Github::CommitStatsEnricher.new(
  #     project: project,
  #     access_token: token,
  #     batch_size: 20
  #   ).call
  #
  #   if result.success?
  #     data = result.value!
  #     # data = { enriched_count: 15, remaining_count: 5, stopped_for_rate_limit: true }
  #   end
  #
  class CommitStatsEnricher < Base
    DEFAULT_BATCH_SIZE = 20

    attr_reader :project, :client, :batch_size, :repo_path

    def initialize(project:, access_token:, batch_size: DEFAULT_BATCH_SIZE)
      @project = project
      @batch_size = batch_size
      @client = Client.new(access_token:)
      @repo_path = extract_repo_path(project.repository_url)
    end

    def call
      return failure_result(:missing_config, "Repository URL is blank") if project.repository_url.blank?
      return failure_result(:missing_config, "Repository path is blank") if repo_path.blank?

      # Find commits that need stats enrichment
      commits_to_enrich = find_commits_needing_stats

      if commits_to_enrich.empty?
        log("No commits need stats enrichment for project #{project.id}")
        return Success({ enriched_count: 0, remaining_count: 0, stopped_for_rate_limit: false })
      end

      log("Found #{commits_to_enrich.count} commits needing stats for project #{project.id}")

      enriched_count = 0
      stopped_for_rate_limit = false

      commits_to_enrich.limit(batch_size).each do |commit|
        # Check rate limit before each call
        unless client.can_proceed?
          log("Rate limit threshold reached, stopping enrichment", level: :warn)
          stopped_for_rate_limit = true
          break
        end

        if enrich_commit(commit)
          enriched_count += 1
        end
      end

      remaining_count = commits_to_enrich.count - enriched_count

      log("Enriched #{enriched_count} commits, #{remaining_count} remaining")

      Success({
        enriched_count:,
        remaining_count:,
        stopped_for_rate_limit:
      })
    end

    private

    # Find commits that don't have stats yet
    # Identified by having 0 lines_added AND 0 lines_removed AND empty changed_files
    def find_commits_needing_stats
      GithubLog
        .where(project_id: project.id)
        .where(lines_added: 0, lines_removed: 0)
        .where("changed_files IS NULL OR changed_files = '[]'")
        .order(commit_date: :desc) # Enrich newest first
    end

    # Enrich a single commit with stats
    # @return [Boolean] true if successful
    def enrich_commit(github_log)
      result = client.commit(repo_path, github_log.commit_sha)

      unless result.success?
        log("Failed to fetch stats for #{github_log.commit_sha}: #{result.failure[:message]}", level: :warn)
        return false
      end

      commit = result.value!
      stats = commit.stats || {}

      changed_files = commit.files.map do |file|
        {
          filename: file.filename,
          status: file.status,
          additions: file.additions,
          deletions: file.deletions,
          patch: file.patch
        }
      end

      github_log.update!(
        lines_added: stats[:additions].to_i,
        lines_removed: stats[:deletions].to_i,
        changed_files:
      )

      log("Enriched commit #{github_log.commit_sha[0..7]} with stats: +#{stats[:additions]}/-#{stats[:deletions]}")
      true
    rescue => e
      log("Error enriching commit #{github_log.commit_sha}: #{e.message}", level: :error)
      false
    end
  end
end
