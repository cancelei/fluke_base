class GithubFetchBranchesJob < ApplicationJob
  def perform(project_id, access_token)
    @project = Project.find(project_id)
    @access_token = access_token
    service = GithubService.new(@project, access_token)
    branches = service.fetch_branches_with_owner

    if branches.empty?
      Rails.logger.warn "No branches found for project #{project_id}"
      broadcast_empty_state
      return
    end

    # Check if this is the first time gathering data for this repository
    is_first_time = @project.github_branches.empty?

    if is_first_time
      # Broadcast initial template for smooth updates
      broadcast_initial_template
    end

    # Process branches sequentially, starting with the biggest (most commits) first
    # This maximizes SHA deduplication - smaller branches will share commits with the big one
    process_branches_sequentially(branches, project_id)

    Rails.logger.info "Finished processing #{branches.size} branches for project #{project_id}"
  rescue => e
    Rails.logger.error "Error in GithubFetchBranchesJob: #{e.message}\n#{e.backtrace.join("\n")}"
    raise e
  end

  private

  def process_branches_sequentially(branches, project_id)
    # Sort branches by commit count (descending) - biggest first for optimal deduplication
    Rails.logger.info "Analyzing branch sizes for project #{project_id}..."

    sorted_branches = sort_branches_by_size(branches)

    Rails.logger.info "Branch processing order (largest first for optimal deduplication):"
    sorted_branches.each_with_index do |item, i|
      Rails.logger.info "  #{i+1}. #{item[:branch][:branch_name]} (~#{item[:size]} commits)"
    end

    # Process branches sequentially to maximize SHA deduplication
    sorted_branches.each_with_index do |item, index|
      branch = item[:branch]
      next if branch[:branch_name].blank?

      process_single_branch(branch, index, sorted_branches.size, project_id)
    end
  end

  # Sort branches by size (largest first) to maximize deduplication efficiency
  def sort_branches_by_size(branches)
    branch_sizes = branches.map do |branch|
      size = estimate_branch_size(branch[:branch_name])
      { branch: branch, size: size }
    end

    branch_sizes.sort_by { |b| -b[:size] }
  end

  # Estimate branch size using GitHub API pagination headers
  def estimate_branch_size(branch_name)
    client = Octokit::Client.new(access_token: @access_token)
    repo_path = extract_repo_path(@project.repository_url)
    commits = client.commits(repo_path, sha: branch_name, per_page: 1, page: 1)

    last_response = client.last_response
    if last_response.rels[:last]
      # Extract page number from last page URL
      last_response.rels[:last].href.match(/page=(\d+)/)[1].to_i
    else
      commits.empty? ? 0 : 1
    end
  rescue => e
    Rails.logger.warn "Could not determine size for branch #{branch_name}: #{e.message}"
    0
  end

  # Process a single branch synchronously
  def process_single_branch(branch, index, total, project_id)
    Rails.logger.info "[#{index + 1}/#{total}] Processing branch: #{branch[:branch_name]}"

    job = GithubCommitRefreshJob.new
    commits_processed = job.perform(project_id, @access_token, branch[:branch_name])

    Rails.logger.info "✓ Branch #{branch[:branch_name]} complete: #{commits_processed} commits processed"
  rescue => e
    Rails.logger.error "✗ Failed to process branch #{branch[:branch_name]}: #{e.message}"
    # Continue with next branch even if one fails
  end

  def extract_repo_path(url)
    if url.include?("github.com/")
      url.split("github.com/").last.gsub(/\.git$/, "")
    else
      url.gsub(/\.git$/, "")
    end
  end

  def broadcast_initial_template
    # Broadcast loading state for new repositories
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "github_logs",
      partial: "github_logs/loading_state",
      locals: { project: @project }
    )

    # Initialize empty stats that will be updated as data arrives
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "github_stats",
      partial: "github_logs/stats_section",
      locals: {
        total_commits: 0,
        total_additions: 0,
        total_deletions: 0,
        last_updated: Time.current,
        project: @project
      }
    )
  end

  def broadcast_empty_state
    # Broadcast empty state when no branches are found
    Turbo::StreamsChannel.broadcast_replace_to(
      "project_#{@project.id}_github_commits",
      target: "github_logs",
      partial: "github_logs/empty_state",
      locals: { project: @project, job_context: true }
    )
  end
end
