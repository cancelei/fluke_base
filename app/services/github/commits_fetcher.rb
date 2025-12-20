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
  # - Returns processed data ready for database insertion
  #
  # Usage:
  #   result = Github::CommitsFetcher.new(
  #     project: project,
  #     access_token: "ghp_xxx",
  #     branch: "main"
  #   ).call
  #
  #   if result.success?
  #     data = result.value!
  #     # data = { commits: [...], all_shas: [...] }
  #   end
  #
  class CommitsFetcher < Base
    attr_reader :project, :branch, :client, :user_resolver, :repo_path

    # Initialize the fetcher
    # @param project [Project] The project to fetch commits for
    # @param access_token [String] GitHub personal access token
    # @param branch [String] Branch name to fetch commits from
    def initialize(project:, access_token:, branch:)
      @project = project
      @branch = branch
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
      shallow_commits.each_with_index.map do |shallow_commit, i|
        next if shallow_commit.sha.blank? || shallow_commit.commit.nil?

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
          unregistered_user_name: author_email
        }
      end.compact
    end
  end
end
