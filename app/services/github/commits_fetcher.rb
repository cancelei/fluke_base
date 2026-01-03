# frozen_string_literal: true

module Github
  # Fetches and processes commits from GitHub API
  #
  # Extracts logic from GithubService#fetch_commits, #fetch_commits_from_api, #process_commits
  #
  # Features:
  # - Intelligent SHA-based deduplication
  # - Paginated API fetching
  # - User resolution for commit authors
  # - **Optimized API usage**: Basic commit info from list (1 call per 100 commits)
  # - **Optional stats enrichment**: Full commit details fetched only when needed
  # - Returns processed data ready for database insertion
  #
  # Usage:
  #   # Fast mode - only list API calls (recommended for polling)
  #   result = Github::CommitsFetcher.new(
  #     project: project,
  #     access_token: "ghp_xxx",
  #     branch: "main",
  #     fetch_stats: false  # Skip individual commit API calls
  #   ).call
  #
  #   # Full mode - includes stats (N additional API calls)
  #   result = Github::CommitsFetcher.new(
  #     project: project,
  #     access_token: "ghp_xxx",
  #     branch: "main",
  #     fetch_stats: true
  #   ).call
  #
  #   if result.success?
  #     data = result.value!
  #     # data = { commits: [...], all_shas: [...] }
  #   end
  #
  class CommitsFetcher < Base
    attr_reader :project, :branch, :client, :user_resolver, :repo_path, :fetch_stats

    # Initialize the fetcher
    # @param project [Project] The project to fetch commits for
    # @param access_token [String] GitHub personal access token
    # @param branch [String] Branch name to fetch commits from
    # @param fetch_stats [Boolean] Whether to fetch full commit details (stats, files)
    #   - false (default): Fast mode, only uses list endpoint (1 API call per 100 commits)
    #   - true: Full mode, fetches each commit individually for stats (N additional calls)
    def initialize(project:, access_token:, branch:, fetch_stats: false)
      @project = project
      @branch = branch
      @fetch_stats = fetch_stats
      @client = Client.new(access_token:)
      @user_resolver = UserResolver.new(project)
      @repo_path = extract_repo_path(project.repository_url)
    end

    # Fetch and process commits
    # @return [Dry::Monads::Result] Success({ commits:, all_shas: }) or Failure
    def call
      return failure_result(:missing_config, "Repository URL is blank") if project.repository_url.blank?
      return failure_result(:missing_config, "Repository path is blank") if repo_path.blank?
      return failure_result(:missing_config, "Branch is blank") if branch.blank?

      # Find the database branch record
      db_branch = GithubBranch.find_by(project_id: project.id, branch_name: branch)
      unless db_branch
        log("No database branch found for #{branch}", level: :error)
        return failure_result(:not_found, "No database branch found for #{branch}")
      end

      # Get existing commit SHAs for deduplication
      existing_shas = get_existing_commit_shas
      log("Found #{existing_shas.size} existing commits in project")

      # Fetch commits from GitHub API
      all_shas, new_commits = fetch_commits_from_api(existing_shas)

      return Success({ commits: [], all_shas: [] }) if all_shas.empty?

      # Process only new commits
      processed = if new_commits.any?
        log("Processing #{new_commits.size} new commits for branch #{branch}")
        process_commits(new_commits)
      else
        log("No new commits to process for branch #{branch}")
        []
      end

      Success({ commits: processed, all_shas: })
    end

    private

    def get_existing_commit_shas
      GithubLog
        .where(project_id: project.id)
        .pluck(:commit_sha)
        .to_set
    end

    def fetch_commits_from_api(existing_shas)
      all_commit_shas = []
      new_commits = []
      page = 1
      per_page = 100
      total_pages_estimate = "unknown"

      log("Starting commit fetch for branch '#{branch}' (page size: #{per_page})")

      loop do
        # IMPORTANT: Do NOT use GitHub's 'since' parameter here.
        # Using 'since' prevents fetching older commits after partial fetches.
        # Instead, we rely on global SHA deduplication for efficiency.
        # See: docs/GITHUB_SYSTEM_COMPLETE.md for detailed explanation.
        result = client.commits(repo_path, sha: branch, per_page:, page:)

        unless result.success?
          log("API error on page #{page}: #{result.failure[:message]}", level: :error)
          break
        end

        commits = result.value!
        break if commits.empty?

        # Estimate total pages from response headers
        if page == 1 && client.last_response.rels[:last]
          total_pages_estimate = client.last_response.rels[:last].href.match(/page=(\d+)/)[1].to_i
          log("Estimated total pages: #{total_pages_estimate} (~#{total_pages_estimate * per_page} commits)")
        end

        # Collect ALL commit SHAs
        all_commit_shas.concat(commits.map(&:sha))

        # Filter out commits we already have
        page_new_commits = commits.reject { |c| existing_shas.include?(c.sha) }

        if page_new_commits.any?
          new_commits.concat(page_new_commits)
          progress = total_pages_estimate != "unknown" ? "#{page}/#{total_pages_estimate}" : page.to_s
          log("Page #{progress}: Found #{page_new_commits.size} new commits out of #{commits.size} total")
        else
          progress = total_pages_estimate != "unknown" ? "#{page}/#{total_pages_estimate}" : page.to_s
          log("Page #{progress}: All #{commits.size} commits already exist")
        end

        page += 1
        break if commits.size < per_page
      end

      log("Fetch complete: #{all_commit_shas.size} total commits, #{new_commits.size} new")
      [all_commit_shas, new_commits]
    end

    def process_commits(shallow_commits)
      if fetch_stats
        process_commits_with_stats(shallow_commits)
      else
        process_commits_fast(shallow_commits)
      end
    end

    # Fast mode: Process commits using only data from the list endpoint
    # No additional API calls - uses shallow commit data only
    # Stats (lines_added, lines_removed, changed_files) will be nil/empty
    def process_commits_fast(shallow_commits)
      log("Processing #{shallow_commits.length} commits in fast mode (no stats)")

      shallow_commits.map do |shallow_commit|
        next if shallow_commit.sha.blank? || shallow_commit.commit.nil?

        # Extract author from shallow commit
        author_email = shallow_commit.author&.login.presence ||
                       shallow_commit.commit.author&.email.to_s.downcase
        next unless author_email.present?

        user_id = user_resolver.find_user_id(author_email, shallow_commit)

        # Find agreement for this user
        agreement = user_resolver.agreements.find do |a|
          a.agreement_participants.any? { |p| p.user_id == user_id }
        end

        {
          project_id: project.id,
          agreement_id: agreement&.id,
          user_id:,
          commit_sha: shallow_commit.sha,
          commit_url: shallow_commit.html_url,
          commit_message: shallow_commit.commit.message,
          lines_added: 0,        # Not available without full fetch
          lines_removed: 0,      # Not available without full fetch
          commit_date: shallow_commit.commit.author.date,
          changed_files: [],     # Not available without full fetch
          created_at: Time.current,
          updated_at: Time.current,
          unregistered_user_name: author_email,
          stats_fetched: false   # Flag to indicate stats not yet fetched
        }
      end.compact
    end

    # Full mode: Fetch complete commit details including stats
    # Makes N additional API calls (one per commit)
    # Use sparingly - only when stats are required
    def process_commits_with_stats(shallow_commits)
      log("Processing #{shallow_commits.length} commits with full stats (#{shallow_commits.length} API calls)")

      shallow_commits.each_with_index.map do |shallow_commit, i|
        next if shallow_commit.sha.blank? || shallow_commit.commit.nil?

        # Check rate limit before each commit fetch
        unless client.can_proceed?
          log("Rate limit threshold reached at commit #{i + 1}/#{shallow_commits.length}, stopping stats fetch", level: :warn)
          break
        end

        # Fetch full commit data for diff stats
        result = client.commit(repo_path, shallow_commit.sha)
        unless result.success?
          log("Failed to fetch commit #{shallow_commit.sha}: #{result.failure[:message]}", level: :warn)
          next
        end

        commit = result.value!
        log("[#{branch}] Fetching commit details #{i + 1}/#{shallow_commits.length}: #{commit.sha[0..7]}")

        author_email = commit.author&.login.presence || commit.commit.author&.email.to_s.downcase
        next unless author_email.present?

        user_id = user_resolver.find_user_id(author_email, commit)

        # Find agreement for this user
        agreement = user_resolver.agreements.find do |a|
          a.agreement_participants.any? { |p| p.user_id == user_id }
        end

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

        {
          project_id: project.id,
          agreement_id: agreement&.id,
          user_id:,
          commit_sha: commit.sha,
          commit_url: commit.html_url,
          commit_message: commit.commit.message,
          lines_added: stats[:additions].to_i,
          lines_removed: stats[:deletions].to_i,
          commit_date: commit.commit.author.date,
          changed_files:,
          created_at: Time.current,
          updated_at: Time.current,
          unregistered_user_name: author_email,
          stats_fetched: true
        }
      end.compact
    end
  end
end
