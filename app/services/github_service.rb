# frozen_string_literal: true

# Service for interacting with GitHub API to fetch commits and branches
# Returns Result types for explicit error handling
class GithubService < ApplicationService
  attr_reader :project, :access_token, :branch, :repo_path, :client, :user_emails, :user_github_identifiers, :agreements

  # Initialize the service with project, access token, and optional branch
  def initialize(project, access_token = nil, branch: nil)
    @project = project
    @access_token = access_token
    @branch = branch
    @repo_path = extract_repo_path(project.repository_url)

    @client = github_client(access_token)
  end

  # @return [Dry::Monads::Result] Success({ commits:, all_shas: }) or Failure(error)
  def fetch_commits
    return failure_result(:missing_config, "Repository URL is blank") if project.repository_url.blank?

    repo_path = extract_repo_path(project.repository_url)
    return failure_result(:missing_config, "Repository path is blank") if repo_path.blank?
    return failure_result(:missing_config, "Branch is blank") if branch.blank?

    load_users

    # Find the database branch record
    db_branch = GithubBranch.find_by(project_id: project.id, branch_name: branch)
    unless db_branch
      Rails.logger.error "No database branch found for #{branch}"
      return failure_result(:not_found, "No database branch found for #{branch}")
    end

    # Get existing commit SHAs globally (across all branches) to avoid duplicate API fetches
    existing_shas = get_existing_commit_shas
    Rails.logger.info "Found #{existing_shas.size} existing commits in project (checking globally)"

    # NOTE: We intentionally DO NOT use the 'since' parameter here
    # Reason: If we have a partial fetch (e.g., only 100 of 324 commits), using 'since'
    # would only fetch commits NEWER than our most recent commit, missing all older commits.
    # SHA deduplication handles efficiency - we skip fetching details for existing commits.
    # This ensures we always get the COMPLETE commit history, even after partial fetches.

    # Fetch commits from GitHub API with intelligent pagination
    all_commit_shas, new_commits = fetch_commits_from_api(repo_path, existing_shas)

    return Success({ commits: [], all_shas: [] }) if all_commit_shas.empty?

    # Process only new commits (to minimize API detail fetches)
    processed_commits = if new_commits.any?
                          Rails.logger.info "Processing #{new_commits.size} new commits for branch #{branch}"
                          process_commits(project, new_commits, user_emails, user_github_identifiers, agreements, client, repo_path, branch)
    else
                          Rails.logger.info "No new commits to process for branch #{branch}"
                          []
    end

    # Return both new commits AND all commit SHAs in the branch
    Success({ commits: processed_commits, all_shas: all_commit_shas })
  rescue Octokit::Error => e
    Rails.logger.error "GitHub API Error: #{e.message}"
    failure_result(:api_error, e.message, exception_class: e.class.name)
  end

  def branches
    client.branches(repo_path)
  end

  # @return [Dry::Monads::Result] Success(branch_owners) or Failure(error)
  def fetch_branches_with_owner
    return failure_result(:missing_config, "Repository URL is blank") if project.repository_url.blank?

    repo_path = extract_repo_path(project.repository_url)
    return failure_result(:missing_config, "Repository path is blank") if repo_path.blank?

    load_users
    branch_owners = []

    # Get all branches first
    all_branches = begin
      branches
    rescue Octokit::Error => e
      Rails.logger.error "Error fetching branches: #{e.message}"
      return failure_result(:api_error, e.message, exception_class: e.class.name)
    end

    if all_branches.blank?
      Rails.logger.warn "No branches found for repository: #{repo_path}"
      return Success([])
    end

    Rails.logger.info "Processing #{all_branches.size} branches for #{repo_path}"

    all_branches.each do |branch|
      begin
        # Get the first commit on the branch (oldest)
        first_commit = first_commit_on_branch(repo_path, branch.name)
        unless first_commit
          Rails.logger.warn "No commits found for branch #{branch.name} in #{repo_path}"
          next
        end

        # Find the user by email or GitHub username
        user_id = User.find_by(email: first_commit[:email])&.id

        unless user_id
          Rails.logger.warn "No user found for email #{first_commit[:email]} in branch #{branch.name}"
          # Still include the branch even if we can't associate a user
          user_id = project.user_id # Default to project owner
        end

        # Prepare branch data for upsert
        branch_owners << {
          project_id: project.id,
          user_id: user_id,
          branch_name: branch.name,
          created_at: Time.current,
          updated_at: Time.current
        }
      rescue Octokit::Error => e
        Rails.logger.error "Error processing branch #{branch.name}: #{e.message}"
        next
      end
    end

    # Upsert all branch owners in a single query
    unless branch_owners.empty?
      GithubBranch.upsert_all(branch_owners, unique_by: [ :project_id, :branch_name, :user_id ])
      Rails.logger.info "Stored #{branch_owners.size} branches for project #{project.id}"
    else
      Rails.logger.warn "No valid branches found for project #{project.id}"
    end

    Success(branch_owners)
  end

  private

  # Get existing commit SHAs globally across all branches to maximize API efficiency
  # This prevents re-fetching the same commit when it appears in multiple branches
  # @return [Set<String>] Set of commit SHAs already in the database
  def get_existing_commit_shas
    GithubLog
      .where(project_id: project.id)
      .pluck(:commit_sha)
      .to_set
  end


  def first_commit_on_branch(repo_path, branch_name)
    # Fetch all commits for the branch
    commits = client.commits(repo_path, sha: branch_name, per_page: 1, page: 1)
    return if commits.empty?

    # Get the last page to find the first commit
    last_response = client.last_response
    if last_response.rels[:last]
      last_page = last_response.rels[:last].href.match(/page=(\d+)/)[1].to_i
      commits = client.commits(repo_path, sha: branch_name, per_page: 1, page: last_page)
    end

    first_commit = commits.first
    return unless first_commit

    author_info = first_commit.commit.author
    github_user = first_commit.author

    {
      sha: first_commit.sha,
      message: first_commit.commit.message,
      name: author_info.name,
      email: author_info.email.to_s.downcase,
      date: author_info.date,
      github_username: github_user&.login
    }
  end

  def load_users
    @agreements = project.agreements.active.includes(agreement_participants: :user)

    # Preload all related users and their GitHub usernames
    agreement_users = agreements.flat_map { |agreement| agreement.agreement_participants.map(&:user) }
    related_users = ([ project.user ] + agreement_users).compact.uniq

    # Create a hash of email => user_id for quick lookup
    @user_emails = {}
    # Create a hash of github_username => user_id for quick lookup
    @user_github_identifiers = {}

    # Preload users and their GitHub usernames
    User.where(id: related_users.map(&:id)).where.not(github_username: [ nil, "" ]).find_each do |user|
      @user_emails[user.email.downcase] = user.id if user.email.present?
      @user_github_identifiers[user.github_username.downcase] = user.id if user.github_username.present?
    end
  end

  def github_client(access_token = nil)
    if access_token.present?
      Octokit::Client.new(access_token: access_token)
    else
      Octokit::Client.new
    end
  end

  def extract_repo_path(url)
    if url.include?("github.com/")
      url.split("github.com/").last.gsub(/\.git$/, "")
    else
      url.gsub(/\.git$/, "")
    end
  end

  # Process commits and prepare them for database insertion
  # Note: This method fetches full commit data for each commit to get diff stats and file changes
  # Only new commits (filtered by SHA) should be passed to this method to minimize API calls
  # @param project [Project] The project
  # @param shallow_commits [Array<Sawyer::Resource>] Array of commit objects from list_commits API
  # @param user_emails [Hash] Hash of email => user_id
  # @param user_github_identifiers [Hash] Hash of github_username => user_id
  # @param agreements [Array<Agreement>] Array of agreements
  # @param client [Octokit::Client] GitHub API client
  # @param repo_path [String] Repository path (owner/repo)
  # @param branch_name [String] Name of the branch being processed
  # @return [Array<Hash>] Array of hashes ready for upsert
  def process_commits(project, shallow_commits, user_emails, user_github_identifiers, agreements, client, repo_path, branch_name)
    i = 0
    shallow_commits.map do |shallow_commit|
      i += 1
      next if shallow_commit.sha.blank? || shallow_commit.commit.nil?

      # Fetch full commit data for diff stats and file changes
      # This is necessary because list_commits doesn't include file changes
      commit = client.commit(repo_path, shallow_commit.sha)
      Rails.logger.info "[#{branch_name}] Fetching commit details #{i}/#{shallow_commits.length}: #{commit.sha[0..7]}"
      author_email = commit.author&.login.presence || commit.commit.author&.email.to_s.downcase
      next unless author_email.present?

      user_id = find_user_id(author_email, user_emails, user_github_identifiers, commit)

      # Find agreement that includes this user as a participant
      agreement = agreements.find { |a| a.agreement_participants.any? { |p| p.user_id == user_id } }

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
        user_id: user_id,
        commit_sha: commit.sha,
        commit_url: commit.html_url,
        commit_message: commit.commit.message,
        lines_added: stats[:additions].to_i,
        lines_removed: stats[:deletions].to_i,
        commit_date: commit.commit.author.date,
        changed_files: changed_files, # This gives you per-file details including diffs
        created_at: Time.current,
        updated_at: Time.current,
        unregistered_user_name: author_email
      }
    end.compact
  end


  # Fetch commits from GitHub API with intelligent pagination and deduplication
  # Fetches ALL commits from the branch to ensure complete history, even after partial fetches
  # @param repo_path [String] Repository path (owner/repo)
  # @param existing_shas [Set<String>] Set of commit SHAs already in database
  # @return [Array<Array>] [all_commit_shas, new_commits]
  def fetch_commits_from_api(repo_path, existing_shas)
    all_commit_shas = []
    new_commits = []
    page = 1
    per_page = 100
    total_pages_estimate = "unknown"

    Rails.logger.info "Starting commit fetch for branch '#{branch}' (page size: #{per_page})"

    loop do
      api_options = { sha: branch, per_page: per_page, page: page }

      commits = client.commits(repo_path, api_options)
      break if commits.empty?

      # Try to get total page count from response headers (if available)
      if page == 1 && client.last_response.rels[:last]
        total_pages_estimate = client.last_response.rels[:last].href.match(/page=(\d+)/)[1].to_i
        Rails.logger.info "Estimated total pages: #{total_pages_estimate} (~#{total_pages_estimate * per_page} commits)"
      end

      # Collect ALL commit SHAs (for branch associations)
      all_commit_shas.concat(commits.map(&:sha))

      # Filter out commits we already have (intelligent deduplication)
      page_new_commits = commits.reject { |c| existing_shas.include?(c.sha) }

      if page_new_commits.any?
        new_commits.concat(page_new_commits)
        progress = total_pages_estimate != "unknown" ? "#{page}/#{total_pages_estimate}" : page.to_s
        Rails.logger.info "Page #{progress}: Found #{page_new_commits.size} new commits out of #{commits.size} total"
      else
        progress = total_pages_estimate != "unknown" ? "#{page}/#{total_pages_estimate}" : page.to_s
        Rails.logger.info "Page #{progress}: All #{commits.size} commits already exist (skipping duplicates)"
      end

      # Continue to next page if we got a full page (more commits may exist)
      page += 1
      break if commits.size < per_page
    rescue Octokit::TooManyRequests => e
      handle_rate_limit(e)
      retry
    rescue Octokit::Error => e
      Rails.logger.error "GitHub API Error on page #{page}: #{e.message}"
      break
    end

    Rails.logger.info "Fetch complete: #{all_commit_shas.size} total commits in branch, #{new_commits.size} new commits to process"
    [ all_commit_shas, new_commits ]
  end

  # Handle GitHub API rate limiting
  def handle_rate_limit(error)
    reset_time = error.response_headers["x-ratelimit-reset"].to_i
    wait_time = [ reset_time - Time.now.to_i + 1, 1 ].max
    Rails.logger.warn "GitHub API rate limit reached. Waiting #{wait_time} seconds..."
    sleep(wait_time)
  end

  def find_user_id(author_identifier, user_emails, user_github_identifiers, commit)
    # Try email lookup first
    user_id = user_emails[author_identifier.downcase]
    return user_id if user_id

    # Try GitHub login from commit
    if commit.author&.login
      user_id = user_github_identifiers[commit.author.login.downcase]
      return user_id if user_id
    end

    # Try identifier as email
    if author_identifier.include?("@")
      user_id = user_github_identifiers[author_identifier.downcase]
      return user_id if user_id
    end

    nil
  end
end
