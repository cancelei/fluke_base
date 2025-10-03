class GithubService
  attr_reader :project, :access_token, :branch, :repo_path, :client, :user_emails, :user_github_identifiers, :agreements

  # Initialize the service with project, access token, and optional branch
  def initialize(project, access_token = nil, branch: nil)
    @project = project
    @access_token = access_token
    @branch = branch
    @repo_path = extract_repo_path(project.repository_url)

    @client = github_client(access_token)
  end

  def fetch_commits
    Rails.logger.info "GithubService#fetch_commits starting for project '#{project.name}' (#{project.id})"
    Rails.logger.info "Repository URL: #{project.repository_url}"
    Rails.logger.info "Branch: #{branch || 'all branches'}"
    Rails.logger.info "Access token: #{access_token.present? ? 'present' : 'not present'}"

    return [] if project.repository_url.blank?

    repo_path = extract_repo_path(project.repository_url)
    Rails.logger.info "Extracted repo path: #{repo_path}"
    return [] if repo_path.blank?

    load_users
    Rails.logger.info "Loaded #{user_emails.length} user emails and #{user_github_identifiers.length} GitHub identifiers"
    Rails.logger.debug "Sample user emails: #{user_emails.keys.first(3)}"
    Rails.logger.debug "Sample GitHub identifiers: #{user_github_identifiers.keys.first(3)}"

    client = @client

    # If a specific branch is requested, fetch commits only from that branch
    if branch.present?
      Rails.logger.info "Fetching commits for specific branch: #{branch}"
      all_commits = []
      page = 1
      per_page = 100 # Maximum allowed by GitHub API

      Rails.logger.info "Starting paginated commit fetch for branch '#{branch}'"
      # Keep fetching pages until we get fewer commits than the per_page limit
      loop do
        begin
          Rails.logger.debug "Fetching page #{page} of commits for branch '#{branch}' (#{per_page} per page)"
          commits = client.commits(repo_path, {
            sha: branch,
            per_page: per_page,
            page: page
          })

          Rails.logger.debug "Received #{commits.length} commits for page #{page}"
          break if commits.empty?

          all_commits.concat(commits)
          Rails.logger.info "Total commits collected so far: #{all_commits.length}"
          page += 1

          # If we got fewer commits than the per_page limit, we've reached the end
          break if commits.size < per_page
        rescue Octokit::TooManyRequests => e
          # If we hit rate limit, wait and retry
          reset_time = e.response_headers["x-ratelimit-reset"].to_i
          wait_time = [ reset_time - Time.now.to_i + 1, 1 ].max
          Rails.logger.warn "GitHub API rate limit reached. Waiting #{wait_time} seconds..."
          sleep(wait_time)
          retry
        rescue Octokit::Error => e
          Rails.logger.error "GitHub API Error fetching commits for branch '#{branch}': #{e.message}"
          Rails.logger.error "Error class: #{e.class.name}"
          Rails.logger.error "Response status: #{e.response_status if e.respond_to?(:response_status)}"
          Rails.logger.error "Response headers: #{e.response_headers if e.respond_to?(:response_headers)}"
          break
        end
      end

      Rails.logger.info "Finished fetching commits. Total: #{all_commits.length} commits for branch '#{branch}'"
      if all_commits.empty?
        Rails.logger.warn "No commits found for branch '#{branch}' in repository '#{repo_path}'"
        Rails.logger.warn "This could indicate: 1) Branch doesn't exist, 2) Branch has no commits, 3) Repository access issues"
        return []
      end

      Rails.logger.info "Looking up database branch record for '#{branch}'"
      db_branch = GithubBranch.find_by(project_id: project.id, branch_name: branch)
      unless db_branch
        Rails.logger.error "No database branch found for '#{branch}' in project '#{project.name}' (#{project.id})"
        Rails.logger.error "Available branches in database: #{GithubBranch.where(project_id: project.id).pluck(:branch_name)}"
        Rails.logger.error "This is likely why commits aren't being stored - no branch record exists"
        return []
      end

      Rails.logger.info "Found database branch: #{db_branch.inspect}"
      Rails.logger.info "Processing #{all_commits.length} commits for branch '#{db_branch.branch_name}'"
      processed_commits = process_commits(project, all_commits, user_emails, user_github_identifiers, agreements, client, repo_path, db_branch.id)
      Rails.logger.info "Processed #{processed_commits.length} commits successfully"

      if processed_commits.empty?
        Rails.logger.warn "No commits were successfully processed for branch '#{branch}'"
        Rails.logger.warn "This could indicate issues with user mapping or commit data"
      end

      return processed_commits
    end

    Rails.logger.info "No specific branch requested, returning empty array"
    []
  rescue Octokit::Error => e
    Rails.logger.error "GitHub API Error in fetch_commits: #{e.message}"
    Rails.logger.error "Error class: #{e.class.name}"
    Rails.logger.error "Response status: #{e.response_status if e.respond_to?(:response_status)}"
    []
  end

  def branches
    client.branches(repo_path)
  end

  def fetch_branches_with_owner
    Rails.logger.info "GithubService#fetch_branches_with_owner starting for project '#{project.name}' (#{project.id})"
    Rails.logger.info "Repository URL: #{project.repository_url}"

    return [] if project.repository_url.blank?

    repo_path = extract_repo_path(project.repository_url)
    Rails.logger.info "Extracted repo path: #{repo_path}"
    return [] if repo_path.blank?

    load_users
    Rails.logger.info "Loaded #{user_emails.length} user emails and #{user_github_identifiers.length} GitHub identifiers for branch processing"

    branch_owners = []

    # Get all branches first
    Rails.logger.info "Fetching all branches from GitHub API..."
    all_branches = begin
      branches_result = branches
      Rails.logger.info "Successfully fetched #{branches_result.length} branches from GitHub"
      Rails.logger.debug "Sample branches: #{branches_result.first(3).map { |b| b.name }.join(', ')}"
      branches_result
    rescue Octokit::Error => e
      Rails.logger.error "Error fetching branches from GitHub API: #{e.message}"
      Rails.logger.error "Error class: #{e.class.name}"
      Rails.logger.error "This will prevent branch creation and commit storage"
      return []
    end

    if all_branches.blank?
      Rails.logger.warn "No branches found for repository: #{repo_path}"
      Rails.logger.warn "This indicates the repository might be empty or inaccessible"
      return []
    end

    Rails.logger.info "Processing #{all_branches.size} branches to find owners..."

    all_branches.each do |branch|
      begin
        Rails.logger.debug "Processing branch: #{branch.name}"
        # Get the first commit on the branch (oldest)
        first_commit = first_commit_on_branch(repo_path, branch.name)
        unless first_commit
          Rails.logger.warn "No commits found for branch '#{branch.name}' in '#{repo_path}'"
          Rails.logger.warn "This branch might be newly created or have no commits yet"
          next
        end

        Rails.logger.debug "Found first commit for branch '#{branch.name}': #{first_commit[:sha][0..7]} by #{first_commit[:email]}"

        # Find the user by email or GitHub username
        user_id = User.find_by(email: first_commit[:email])&.id
        Rails.logger.debug "User lookup by email '#{first_commit[:email]}': #{user_id ? 'found' : 'not found'}"

        unless user_id
          Rails.logger.warn "No user found for email '#{first_commit[:email]}' in branch '#{branch.name}'"
          Rails.logger.debug "Checking if email exists in our user mappings: #{user_emails.key?(first_commit[:email].downcase)}"
          # Still include the branch even if we can't associate a user
          user_id = project.user_id # Default to project owner
          Rails.logger.info "Defaulting to project owner (#{user_id}) for branch '#{branch.name}'"
        end

        # Prepare branch data for upsert
        branch_data = {
          project_id: project.id,
          user_id: user_id,
          branch_name: branch.name,
          created_at: Time.current,
          updated_at: Time.current
        }
        branch_owners << branch_data
        Rails.logger.debug "Added branch data: #{branch_data.slice(:branch_name, :user_id)}"
      rescue Octokit::Error => e
        Rails.logger.error "GitHub API Error processing branch '#{branch.name}': #{e.message}"
        Rails.logger.error "Error class: #{e.class.name}"
        next
      rescue StandardError => e
        Rails.logger.error "Unexpected error processing branch '#{branch.name}': #{e.message}"
        Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
        next
      end
    end

    Rails.logger.info "Prepared #{branch_owners.size} branch records for database storage"

    # Upsert all branch owners in a single query
    unless branch_owners.empty?
      Rails.logger.info "Storing #{branch_owners.size} branches in database..."
      begin
        upsert_result = GithubBranch.upsert_all(branch_owners, unique_by: [ :project_id, :branch_name, :user_id ])
        Rails.logger.info "Branch upsert completed: #{upsert_result.inspect}"
        Rails.logger.info "Successfully stored #{branch_owners.size} branches for project '#{project.name}' (#{project.id})"
      rescue StandardError => e
        Rails.logger.error "Error upserting branches to database: #{e.message}"
        Rails.logger.error "Branch data sample: #{branch_owners.first.inspect}"
        Rails.logger.error "This could prevent commits from being associated with branches"
      end
    else
      Rails.logger.warn "No valid branches found for project '#{project.name}' (#{project.id})"
      Rails.logger.warn "This means no branch records will be created, which could prevent commit storage"
    end

    branch_owners
  rescue StandardError => e
    Rails.logger.error "Unexpected error in fetch_branches_with_owner: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    []
  end

  private

  def first_commit_on_branch(repo_path, branch_name)
    Rails.logger.debug "Finding first commit for branch '#{branch_name}' in repo '#{repo_path}'"

    # Fetch all commits for the branch
    commits = client.commits(repo_path, sha: branch_name, per_page: 1, page: 1)
    Rails.logger.debug "Fetched #{commits.length} commits for first page of branch '#{branch_name}'"
    return if commits.empty?

    # Get the last page to find the first commit
    last_response = client.last_response
    if last_response.rels[:last]
      last_page = last_response.rels[:last].href.match(/page=(\d+)/)[1].to_i
      Rails.logger.debug "Found #{last_page} total pages for branch '#{branch_name}', fetching last page"
      commits = client.commits(repo_path, sha: branch_name, per_page: 1, page: last_page)
    end

    first_commit = commits.first
    return unless first_commit

    Rails.logger.debug "Found first commit: #{first_commit.sha[0..7]} by #{first_commit.commit.author.email}"
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
  rescue Octokit::Error => e
    Rails.logger.error "GitHub API Error finding first commit for branch '#{branch_name}': #{e.message}"
    Rails.logger.error "Error class: #{e.class.name}"
    nil
  rescue StandardError => e
    Rails.logger.error "Unexpected error finding first commit for branch '#{branch_name}': #{e.message}"
    nil
  end

  def load_users
    Rails.logger.debug "Loading users for project '#{project.name}' (#{project.id})"
    @agreements = project.agreements.active.includes(agreement_participants: :user)
    Rails.logger.debug "Found #{@agreements.length} active agreements"

    # Preload all related users and their GitHub usernames
    agreement_users = agreements.flat_map { |agreement| agreement.agreement_participants.map(&:user) }
    related_users = ([ project.user ] + agreement_users).compact.uniq
    Rails.logger.debug "Found #{related_users.length} related users to process"

    # Create a hash of email => user_id for quick lookup
    @user_emails = {}
    # Create a hash of github_username => user_id for quick lookup
    @user_github_identifiers = {}

    # Preload users and their GitHub usernames
    Rails.logger.debug "Building user email and GitHub identifier mappings..."
    User.where(id: related_users.map(&:id)).where.not(github_username: [ nil, "" ]).find_each do |user|
      @user_emails[user.email.downcase] = user.id if user.email.present?
      @user_github_identifiers[user.github_username.downcase] = user.id if user.github_username.present?
    end

    Rails.logger.info "Loaded user mappings: #{@user_emails.length} emails, #{@user_github_identifiers.length} GitHub usernames"
    if @user_emails.empty? && @user_github_identifiers.empty?
      Rails.logger.warn "No user mappings found! This means commits won't be associated with users"
      Rails.logger.warn "Check if users have email addresses and GitHub usernames configured"
    end
  rescue StandardError => e
    Rails.logger.error "Error loading users: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    @user_emails = {}
    @user_github_identifiers = {}
    @agreements = []
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

  def process_commits(project, shallow_commits, user_emails, user_github_identifiers, agreements, client, repo_path, branch_id)
    Rails.logger.info "Processing #{shallow_commits.length} commits for project '#{project.name}' (#{project.id})"

    i = 0
    processed_commits = shallow_commits.map do |shallow_commit|
      i += 1
      Rails.logger.debug "Processing commit #{i}/#{shallow_commits.length}: #{shallow_commit.sha[0..7]}"

      next if shallow_commit.sha.blank? || shallow_commit.commit.nil?

      # Fetch full commit data for diff stats and file changes
      Rails.logger.debug "Fetching full commit data for SHA: #{shallow_commit.sha}"
      commit = begin
        client.commit(repo_path, shallow_commit.sha)
      rescue Octokit::Error => e
        Rails.logger.error "GitHub API Error fetching full commit data for #{shallow_commit.sha}: #{e.message}"
        Rails.logger.error "This commit will be skipped"
        next
      end

      Rails.logger.debug "Successfully fetched full commit data for #{commit.sha[0..7]}"
      author_email = commit.author&.login.presence || commit.commit.author&.email.to_s.downcase
      Rails.logger.debug "Author identifier: '#{author_email}'"
      next unless author_email.present?

      user_id = find_user_id(author_email, user_emails, user_github_identifiers, commit)
      Rails.logger.debug "User ID lookup for '#{author_email}': #{user_id ? 'found (#{user_id})' : 'not found'}"

      # Find agreement that includes this user as a participant
      agreement = agreements.find { |a| a.agreement_participants.any? { |p| p.user_id == user_id } }
      Rails.logger.debug "Agreement lookup for user #{user_id}: #{agreement&.id ? 'found' : 'not found'}"

      stats = commit.stats || {}
      Rails.logger.debug "Commit stats: #{stats[:additions]} additions, #{stats[:deletions]} deletions"

      changed_files = commit.files.map do |file|
        {
          filename: file.filename,
          status: file.status,
          additions: file.additions,
          deletions: file.deletions,
          patch: file.patch
        }
      end

      Rails.logger.debug "Processed #{changed_files.length} changed files for commit #{commit.sha[0..7]}"

      processed_commit = {
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

      Rails.logger.debug "Successfully processed commit: #{processed_commit.slice(:commit_sha, :user_id, :lines_added, :lines_removed)}"
      processed_commit
    end.compact

    Rails.logger.info "Successfully processed #{processed_commits.length} out of #{shallow_commits.length} commits"
    if processed_commits.length != shallow_commits.length
      Rails.logger.warn "#{shallow_commits.length - processed_commits.length} commits were skipped during processing"
      Rails.logger.warn "This could indicate API errors, missing data, or user mapping issues"
    end

    processed_commits
  rescue StandardError => e
    Rails.logger.error "Unexpected error in process_commits: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
    []
  end


  def find_user_id(author_identifier, user_emails, user_github_identifiers, commit)
    # First try to find by email
    user_id = user_emails[author_identifier.downcase]
    return user_id if user_id

    # Then try to find by GitHub login from the commit
    if commit.author&.login
      user_id = user_github_identifiers[commit.author.login.downcase]
      return user_id if user_id
    end

    # Finally, try to find by the author identifier if it's an email
    if author_identifier.include?("@")
      user_id = user_github_identifiers[author_identifier.downcase]
      return user_id if user_id
    end

    nil
  end
end
