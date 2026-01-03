# frozen_string_literal: true

# Background job for enriching commits with stats (lines added/removed, files)
#
# This job runs after initial commit sync to fetch detailed stats for commits
# that were synced in "fast mode" (without making individual API calls).
#
# Features:
# - Rate limit aware: stops when approaching 85% threshold
# - Batch processing: processes commits in small batches
# - Auto-reschedule: reschedules itself if more commits need enrichment
# - Priority-based: newest commits enriched first
#
# Usage:
#   GithubStatsEnrichmentJob.perform_later(project_id, access_token)
#
class GithubStatsEnrichmentJob < ApplicationJob
  queue_as :default

  # Process in small batches to respect rate limits
  BATCH_SIZE = 20

  # Delay between job reschedules (to avoid hammering the API)
  RESCHEDULE_DELAY = 5.minutes

  # Maximum number of reschedules before giving up
  MAX_RESCHEDULES = 10

  def perform(project_id, access_token, reschedule_count: 0)
    @project = Project.find_by(id: project_id)
    unless @project
      Rails.logger.error "[StatsEnrichment] Project not found: #{project_id}"
      return
    end

    @access_token = access_token

    # Check rate limit before starting
    tracker = Github::RateLimitTracker.new(access_token)
    unless tracker.can_make_request?(BATCH_SIZE)
      handle_rate_limit(project_id, access_token, reschedule_count, tracker)
      return
    end

    # Run the enrichment
    result = Github::CommitStatsEnricher.new(
      project: @project,
      access_token:,
      batch_size: BATCH_SIZE
    ).call

    if result.failure?
      Rails.logger.error "[StatsEnrichment] Failed for project #{project_id}: #{result.failure[:message]}"
      return
    end

    data = result.value!
    log_result(data)

    # Reschedule if there are more commits to enrich
    if data[:remaining_count] > 0 && reschedule_count < MAX_RESCHEDULES
      schedule_next_batch(project_id, access_token, reschedule_count, data[:stopped_for_rate_limit])
    elsif data[:remaining_count] > 0
      Rails.logger.warn "[StatsEnrichment] Max reschedules (#{MAX_RESCHEDULES}) reached for project #{project_id}, " \
                        "#{data[:remaining_count]} commits still need enrichment"
    end
  end

  private

  def handle_rate_limit(project_id, access_token, reschedule_count, tracker)
    wait_time = tracker.wait_time_seconds

    if reschedule_count >= MAX_RESCHEDULES
      Rails.logger.warn "[StatsEnrichment] Rate limited and max reschedules reached for project #{project_id}"
      return
    end

    # Wait for rate limit to reset, then try again
    delay = [wait_time.seconds, RESCHEDULE_DELAY].max

    Rails.logger.info "[StatsEnrichment] Rate limit at #{tracker.consumption_percent}% for project #{project_id}, " \
                      "rescheduling in #{delay.to_i}s"

    self.class.set(wait: delay).perform_later(
      project_id,
      access_token,
      reschedule_count: reschedule_count + 1
    )
  end

  def schedule_next_batch(project_id, access_token, reschedule_count, stopped_for_rate_limit)
    # If stopped for rate limit, wait longer
    delay = stopped_for_rate_limit ? RESCHEDULE_DELAY : 30.seconds

    Rails.logger.info "[StatsEnrichment] Scheduling next batch for project #{project_id} in #{delay.to_i}s"

    self.class.set(wait: delay).perform_later(
      project_id,
      access_token,
      reschedule_count: reschedule_count + 1
    )
  end

  def log_result(data)
    if data[:enriched_count] > 0
      Rails.logger.info "[StatsEnrichment] Project #{@project.id}: enriched #{data[:enriched_count]} commits, " \
                        "#{data[:remaining_count]} remaining"
    else
      Rails.logger.debug "[StatsEnrichment] Project #{@project.id}: no commits enriched this batch"
    end
  end
end
