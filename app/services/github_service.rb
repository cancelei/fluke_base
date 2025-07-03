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
    return [] if project.repository_url.blank?

    repo_path = extract_repo_path(project.repository_url)
    return [] if repo_path.blank?

    load_users
    client = github_client(access_token)

    # If a specific branch is requested, fetch commits only from that branch
    if branch.present?
      all_commits = []
      page = 1
      per_page = 100 # Maximum allowed by GitHub API

      # Keep fetching pages until we get fewer commits than the per_page limit
      loop do
        begin
          commits = client.commits(repo_path, {
            sha: branch,
            per_page: per_page,
            page: page
          })

          break if commits.empty?

          all_commits.concat(commits)
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
          Rails.logger.error "GitHub API Error: #{e.message}"
          break
        end
      end

      branch_id = GithubBranch.find_by(branch_name: branch)&.id

      process_commits(project, all_commits, user_emails, user_github_identifiers, agreements, client, repo_path, branch_id)
    else
      []
    end
  rescue Octokit::Error => e
    Rails.logger.error "GitHub API Error: #{e.message}"
    []
  end

  def branches
    client.branches(repo_path)
  end

  def fetch_branches_with_owner
    return [] if project.repository_url.blank?

    repo_path = extract_repo_path(project.repository_url)
    return [] if repo_path.blank?

    load_users
    branch_owners = []

    branches.each do |branch|
      begin
        # Get the first commit on the branch (oldest)
        first_commit = first_commit_on_branch(repo_path, branch.name)
        next unless first_commit

        # Find the user by email or GitHub username
        user_id = User.find_by(email: first_commit[:email])&.id

        next unless user_id
        #
        # agreement_id = project.agreements.where(status: "Accepted")&.first&.id
        # next unless agreement_id

        # Prepare branch data for upsert
        branch_owners << {
          project_id: project.id,
          # agreement_id: agreement_id, # Can be associated later if needed
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
    end

    branch_owners
  end

  private

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
    @agreements = project.agreements.active.includes(:initiator, :other_party)

    # Preload all related users and their GitHub usernames
    related_users = ([ project.user ] + agreements.map(&:initiator) + agreements.map(&:other_party)).compact.uniq

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

  def process_commits(project, shallow_commits, user_emails, user_github_identifiers, agreements, client, repo_path, branch_id)
    i = 0
    shallow_commits.map do |shallow_commit|
      i += 1
      next if shallow_commit.sha.blank? || shallow_commit.commit.nil?

      # Fetch full commit data for diff stats and file changes
      commit = client.commit(repo_path, shallow_commit.sha)
      puts "Processing #{i} out of #{shallow_commits.length} commits"
      author_email = commit.author&.login.presence || commit.commit.author&.email.to_s.downcase
      next unless author_email.present?

      user_id = find_user_id(author_email, user_emails, user_github_identifiers, commit)

      agreement = agreements.find { |a| [ a.initiator_id, a.other_party_id ].include?(user_id) }

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
        github_branches_id: branch_id,
        changed_files: changed_files, # This gives you per-file details including diffs
        created_at: Time.current,
        updated_at: Time.current,
        unregistered_user_name: author_email
      }
    end.compact
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
