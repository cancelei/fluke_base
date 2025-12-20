# frozen_string_literal: true

# Background job for discovering and processing repository branches
#
# Uses Github::BranchesFetcher for branch discovery and Github::BroadcastService
# for Turbo Stream updates. Processes branches sequentially starting with
# the largest to maximize SHA deduplication efficiency.
#
class GithubFetchBranchesJob < ApplicationJob
  def perform(project_id, access_token)
    @project = Project.find(project_id)
    @access_token = access_token
    @broadcaster = Github::BroadcastService.new(@project)

    # Use BranchesFetcher for branch discovery and storage
    result = Github::BranchesFetcher.new(
      project: @project,
      access_token:
    ).call

    if result.failure?
      Rails.logger.error "Failed to fetch branches: #{result.failure[:message]}"
      @broadcaster.broadcast_empty_state
      return
    end

    branches = result.value!

    if branches.empty?
      Rails.logger.warn "No branches found for project #{project_id}"
      @broadcaster.broadcast_empty_state
      return
    end

    # Check if this is the first time gathering data for this repository
    is_first_time = @project.github_branches.empty?
    broadcast_initial_state if is_first_time

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
    Rails.logger.info "Analyzing branch sizes for project #{project_id}..."

    sorted_branches = sort_branches_by_size(branches)

    Rails.logger.info "Branch processing order (largest first for optimal deduplication):"
    sorted_branches.each_with_index do |item, i|
      Rails.logger.info "  #{i + 1}. #{item[:branch][:branch_name]} (~#{item[:size]} commits)"
    end

    sorted_branches.each_with_index do |item, index|
      branch = item[:branch]
      next if branch[:branch_name].blank?

      process_single_branch(branch, index, sorted_branches.size, project_id)
    end
  end

  def sort_branches_by_size(branches)
    branch_sizes = branches.map do |branch|
      size = estimate_branch_size(branch[:branch_name])
      { branch:, size: }
    end

    branch_sizes.sort_by { |b| -b[:size] }
  end

  def estimate_branch_size(branch_name)
    # Use Github::Client for API calls
    client = Github::Client.new(access_token: @access_token)
    repo_path = extract_repo_path(@project.repository_url)

    result = client.commits(repo_path, sha: branch_name, per_page: 1, page: 1)
    return 0 unless result.success?

    commits = result.value!
    return 0 if commits.empty?

    last_response = client.last_response
    if last_response.rels[:last]
      last_response.rels[:last].href.match(/page=(\d+)/)[1].to_i
    else
      1
    end
  rescue => e
    Rails.logger.warn "Could not determine size for branch #{branch_name}: #{e.message}"
    0
  end

  def process_single_branch(branch, index, total, project_id)
    Rails.logger.info "[#{index + 1}/#{total}] Processing branch: #{branch[:branch_name]}"

    job = GithubCommitRefreshJob.new
    commits_processed = job.perform(project_id, @access_token, branch[:branch_name])

    Rails.logger.info "Branch #{branch[:branch_name]} complete: #{commits_processed} commits processed"
  rescue => e
    Rails.logger.error "Failed to process branch #{branch[:branch_name]}: #{e.message}"
    # Continue with next branch even if one fails
  end

  def extract_repo_path(url)
    Github::Base.new.send(:extract_repo_path, url)
  end

  def broadcast_initial_state
    @broadcaster.broadcast_loading_state

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
end
