# frozen_string_literal: true

module Github
  # Fetches and stores repository branches from GitHub
  #
  # Extracts logic from GithubService#fetch_branches_with_owner, #first_commit_on_branch
  #
  # Features:
  # - Discovers all branches in a repository
  # - Determines branch owner from first commit
  # - Upserts branch records for efficient updates
  #
  # Usage:
  #   result = Github::BranchesFetcher.new(
  #     project: project,
  #     access_token: "ghp_xxx"
  #   ).call
  #
  #   if result.success?
  #     branches = result.value!
  #     # branches = [{ project_id:, user_id:, branch_name:, ... }, ...]
  #   end
  #
  class BranchesFetcher < Base
    attr_reader :project, :client, :user_resolver, :repo_path

    # Initialize the fetcher
    # @param project [Project] The project to fetch branches for
    # @param access_token [String] GitHub personal access token
    def initialize(project:, access_token:)
      @project = project
      @client = Client.new(access_token:)
      @user_resolver = UserResolver.new(project)
      @repo_path = extract_repo_path(project.repository_url)
    end

    # Fetch and store branches
    # @return [Dry::Monads::Result] Success(branch_data) or Failure
    def call
      return failure_result(:missing_config, "Repository URL is blank") if project.repository_url.blank?
      return failure_result(:missing_config, "Repository path is blank") if repo_path.blank?

      # Fetch all branches
      result = client.branches(repo_path)
      unless result.success?
        log("Error fetching branches: #{result.failure[:message]}", level: :error)
        return result
      end

      all_branches = result.value!
      if all_branches.blank?
        log("No branches found for repository: #{repo_path}", level: :warn)
        return Success([])
      end

      log("Processing #{all_branches.size} branches for #{repo_path}")

      # Process each branch
      branch_data = process_branches(all_branches)

      # Upsert all branches
      if branch_data.any?
        GithubBranch.upsert_all(branch_data, unique_by: [:project_id, :branch_name, :user_id])
        log("Stored #{branch_data.size} branches for project #{project.id}")
      else
        log("No valid branches found for project #{project.id}", level: :warn)
      end

      Success(branch_data)
    end

    private

    def process_branches(all_branches)
      branch_data = []

      all_branches.each do |branch|
        first_commit = first_commit_on_branch(branch.name)
        unless first_commit
          log("No commits found for branch #{branch.name}", level: :warn)
          next
        end

        # Find user by email
        user_id = User.find_by(email: first_commit[:email])&.id

        unless user_id
          log("No user found for email #{first_commit[:email]} in branch #{branch.name}", level: :warn)
          user_id = project.user_id # Default to project owner
        end

        branch_data << {
          project_id: project.id,
          user_id:,
          branch_name: branch.name,
          created_at: Time.current,
          updated_at: Time.current
        }
      rescue => e
        log("Error processing branch #{branch.name}: #{e.message}", level: :error)
        next
      end

      branch_data
    end

    def first_commit_on_branch(branch_name)
      # Get first page to find last page
      result = client.commits(repo_path, sha: branch_name, per_page: 1, page: 1)
      return nil unless result.success?

      commits = result.value!
      return nil if commits.empty?

      # Get the last page to find the first commit
      last_response = client.last_response
      if last_response.rels[:last]
        last_page = last_response.rels[:last].href.match(/page=(\d+)/)[1].to_i
        result = client.commits(repo_path, sha: branch_name, per_page: 1, page: last_page)
        return nil unless result.success?
        commits = result.value!
      end

      first_commit = commits.first
      return nil unless first_commit

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
  end
end
