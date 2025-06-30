class GithubService
  attr_reader :project, :access_token, :branch, :repo_path, :client, :user_emails, :user_github_identifiers

  # Initialize the service with project, access token, and optional branch
  def initialize(project, access_token = nil, branch: nil)
    @project = project
    @access_token = access_token
    @branch = branch
    @repo_path = extract_repo_path(project.repository_url)

    @client = github_client(access_token)
  end

  def fetch_commits(project, access_token = nil, branch: nil)
    return [] if project.repository_url.blank?

    repo_path = extract_repo_path(project.repository_url)
    return [] if repo_path.blank?

    load_users

    client = github_client(access_token)

    # If a specific branch is requested, fetch commits only from that branch
    if branch.present?
      shallow_commits = client.commits(repo_path, sha: branch)
      process_commits(project, shallow_commits, user_emails, user_github_identifiers, agreements, client, repo_path, branch)
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

  private

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

  def process_commits(project, shallow_commits, user_emails, user_github_identifiers, agreements, client, repo_path, branch_name = "main")
    shallow_commits.map do |shallow_commit|
      next if shallow_commit.sha.blank? || shallow_commit.commit.nil?

      # Fetch full commit data for diff stats and file changes
      commit = client.commit(repo_path, shallow_commit.sha)
      author_email = commit.author&.login.presence || commit.commit.author&.email.to_s.downcase
      next unless author_email.present?

      user_id = find_user_id(author_email, user_emails, user_github_identifiers, commit)
      next unless user_id

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
        branch_name: branch_name,
        changed_files: changed_files, # This gives you per-file details including diffs
        created_at: Time.current,
        updated_at: Time.current
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
