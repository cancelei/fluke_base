class GithubService
  class << self
    def fetch_commits(project, access_token = nil)
      return [] if project.repository_url.blank?

      repo_path = extract_repo_path(project.repository_url)
      return [] if repo_path.blank?

      agreements = project.agreements.active.includes(:initiator, :other_party)

      user_emails = {}
      ([project.user] + agreements.map(&:initiator) + agreements.map(&:other_party)).uniq.each do |user|
        user_emails[user.email.downcase] = user.id if user.email.present?
      end

      client = github_client(access_token)
      shallow_commits = client.commits(repo_path)

      process_commits(project, shallow_commits, user_emails, agreements, client, repo_path)
    rescue Octokit::Error => e
      Rails.logger.error "GitHub API Error: #{e.message}"
      []
    end

    private

    def github_client(access_token = nil)
      if access_token.present?
        Octokit::Client.new(access_token: access_token)
      else
        Octokit::Client.new
      end
    end

    def extract_repo_path(url)
      if url.include?('github.com/')
        url.split('github.com/').last.gsub(/\.git$/, '')
      else
        url.gsub(/\.git$/, '')
      end
    end

    def process_commits(project, shallow_commits, user_emails, agreements, client, repo_path)
      shallow_commits.map do |shallow_commit|
        next if shallow_commit.sha.blank? || shallow_commit.commit.nil?

        # Fetch full commit data for diff stats and file changes
        commit = client.commit(repo_path, shallow_commit.sha)

        author_email = commit.author&.login.presence || commit.commit.author&.email.to_s.downcase
        next unless author_email.present?

        user_id = find_user_id(author_email, user_emails, commit)
        next unless user_id

        agreement = agreements.find { |a| [a.initiator_id, a.other_party_id].include?(user_id) }

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
          updated_at: Time.current
        }
      end.compact
    end

    def find_user_id(author_identifier, user_emails, commit)
      user_id = user_emails[author_identifier.downcase]
      return user_id if user_id

      if commit.author&.login
        user = User.find_by_github_identifier(commit.author.login)
        return user.id if user
      end

      if author_identifier.include?('@')
        user = User.find_by_github_identifier(author_identifier)
        return user.id if user
      end

      nil
    end
  end
end
