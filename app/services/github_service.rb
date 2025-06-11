class GithubService
  class << self
    def fetch_commits(project, access_token = nil)
      return [] if project.repository_url.blank?
      
      repo_path = extract_repo_path(project.repository_url)
      return [] if repo_path.blank?
      
      # Get all agreements for this project
      agreements = project.agreements.active.includes(:initiator, :other_party)
      
      # Get all users involved in the project (project owner + agreement parties)
      user_emails = {}
      ([project.user] + agreements.map(&:initiator) + agreements.map(&:other_party)).uniq.each do |user|
        user_emails[user.email.downcase] = user.id if user.email.present?
      end
      
      # Fetch commits from GitHub API
      commits = github_client(access_token).commits(repo_path)
      
      process_commits(project, commits, user_emails, agreements)
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
      # Handle both full URLs and owner/repo format
      if url.include?('github.com/')
        url.split('github.com/').last.gsub(/\.git$/, '')
      else
        url.gsub(/\.git$/, '')
      end
    end
    
    def process_commits(project, commits, user_emails, agreements)
      commits.map do |commit|
        next if commit.sha.blank? || commit.commit.nil?
        
        author_email = commit.author&.login.presence || commit.commit.author&.email.to_s.downcase
        next unless author_email.present?
        
        # Find user by email or GitHub username
        user_id = find_user_id(author_email, user_emails, commit)
        next unless user_id
        
        # Find agreement for this user and project
        agreement = agreements.find { |a| [a.initiator_id, a.other_party_id].include?(user_id) }
        
        # Get commit stats
        stats = commit.stats || {}
        
        {
          project_id: project.id,
          agreement_id: agreement&.id,
          user_id: user_id,
          commit_sha: commit.sha,
          commit_message: commit.commit.message,
          lines_added: stats[:additions].to_i,
          lines_removed: stats[:deletions].to_i,
          commit_date: commit.commit.author.date,
          created_at: Time.current,
          updated_at: Time.current
        }
      end.compact
    end
    
    def find_user_id(author_identifier, user_emails, commit)
      # Try exact email match first
      user_id = user_emails[author_identifier.downcase]
      return user_id if user_id
      
      # Try to find by GitHub login or email
      if commit.author&.login
        user = User.find_by_github_identifier(commit.author.login)
        return user.id if user
      end
      
      # Try to find by email from commit
      if author_identifier.include?('@')
        user = User.find_by_github_identifier(author_identifier)
        return user.id if user
      end
      
      nil
    end
  end
end
