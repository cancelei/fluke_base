# frozen_string_literal: true

# Analyzes AI conversation logs for recurring error patterns and generates
# gotcha suggestions for human review.
#
# Pattern triggers:
# - recurring_error: Same error fingerprint 3+ times
# - high_failure: Tool failure rate >20%
# - retry_sequence: Same tool called 3+ times in short window
# - long_debugging: Session duration >30min with errors
#
# Usage:
#   PatternAnalyzerJob.perform_later(project_id)  # Analyze single project
#   PatternAnalyzerJob.perform_later              # Analyze all active projects
#
class PatternAnalyzerJob < ApplicationJob
  queue_as :default

  # Minimum occurrences for a pattern to trigger a suggestion
  MIN_ERROR_OCCURRENCES = 3
  # Minimum failure rate to suggest high_failure gotcha
  HIGH_FAILURE_THRESHOLD = 0.20
  # Days to look back for pattern analysis
  ANALYSIS_WINDOW_DAYS = 7

  def perform(project_id = nil)
    if project_id
      analyze_project(Project.find(project_id))
    else
      analyze_all_active_projects
    end
  end

  private

  def analyze_all_active_projects
    # Find projects with recent AI conversation activity
    active_project_ids = AiConversationLog
      .where("created_at > ?", ANALYSIS_WINDOW_DAYS.days.ago)
      .distinct
      .pluck(:project_id)
      .compact

    Project.where(id: active_project_ids).find_each do |project|
      analyze_project(project)
    end
  end

  def analyze_project(project)
    Rails.logger.info("[PatternAnalyzer] Analyzing project #{project.id}: #{project.name}")

    patterns = []

    # Detect recurring error patterns
    patterns += detect_recurring_errors(project)

    # Detect high failure rate tools
    patterns += detect_high_failure_tools(project)

    # Filter out patterns already suggested
    new_patterns = filter_existing_suggestions(patterns, project)

    # Generate and save suggestions for new patterns
    new_patterns.each do |pattern|
      create_suggestion(project, pattern)
    end

    Rails.logger.info("[PatternAnalyzer] Created #{new_patterns.size} suggestions for project #{project.id}")
  end

  # Detect recurring errors by fingerprint
  def detect_recurring_errors(project)
    patterns = []

    # Query logs with error metadata
    error_logs = project.ai_conversation_logs
      .where("metadata->>'error_fingerprint' IS NOT NULL")
      .where("created_at > ?", ANALYSIS_WINDOW_DAYS.days.ago)

    # Group by fingerprint and count
    fingerprint_groups = error_logs.group("metadata->>'error_fingerprint'")
      .having("count(*) >= ?", MIN_ERROR_OCCURRENCES)
      .count

    fingerprint_groups.each do |fingerprint, count|
      # Get sample for this fingerprint
      sample = error_logs
        .where("metadata->>'error_fingerprint' = ?", fingerprint)
        .order(created_at: :desc)
        .first

      next unless sample

      patterns << {
        type: SuggestedGotcha::RECURRING_ERROR,
        fingerprint:,
        data: {
          fingerprint:,
          count:,
          tool_name: sample.metadata&.dig("tool_name"),
          error_message: sample.metadata&.dig("error_message"),
          error_category: sample.metadata&.dig("error_category"),
          sample_messages: get_sample_messages(error_logs, fingerprint)
        }
      }
    end

    patterns
  end

  # Detect tools with high failure rates
  def detect_high_failure_tools(project)
    patterns = []

    # Get tool call statistics from conversation logs
    tool_stats = project.ai_conversation_logs
      .where("created_at > ?", ANALYSIS_WINDOW_DAYS.days.ago)
      .where("metadata->>'tool_name' IS NOT NULL")
      .group("metadata->>'tool_name'")
      .select(
        "metadata->>'tool_name' as tool_name",
        "COUNT(*) as total_calls",
        "SUM(CASE WHEN metadata->>'error' IS NOT NULL OR metadata->>'success' = 'false' THEN 1 ELSE 0 END) as failed_calls"
      )

    tool_stats.each do |stat|
      total = stat.total_calls.to_i
      failed = stat.failed_calls.to_i
      next if total < 5 # Skip tools with few calls

      failure_rate = failed.to_f / total
      next if failure_rate < HIGH_FAILURE_THRESHOLD

      # Get a sample error message
      sample = project.ai_conversation_logs
        .where("metadata->>'tool_name' = ?", stat.tool_name)
        .where("metadata->>'error' IS NOT NULL OR metadata->>'success' = 'false'")
        .order(created_at: :desc)
        .first

      fingerprint = Digest::MD5.hexdigest("high_failure:#{stat.tool_name}")[0..11]

      patterns << {
        type: SuggestedGotcha::HIGH_FAILURE,
        fingerprint:,
        data: {
          fingerprint:,
          tool_name: stat.tool_name,
          total_calls: total,
          failed_calls: failed,
          failure_rate: failure_rate.round(4),
          error_message: sample&.metadata&.dig("error"),
          error_category: sample&.metadata&.dig("error_category") || "unknown"
        }
      }
    end

    patterns
  end

  # Get sample error messages for a fingerprint
  def get_sample_messages(error_logs, fingerprint)
    error_logs
      .where("metadata->>'error_fingerprint' = ?", fingerprint)
      .order(created_at: :desc)
      .limit(3)
      .pluck(Arel.sql("metadata->>'error_message'"))
      .compact
      .uniq
  end

  # Filter out patterns that already have pending or approved suggestions
  def filter_existing_suggestions(patterns, project)
    existing_fingerprints = project.suggested_gotchas
      .where(status: [SuggestedGotcha::PENDING, SuggestedGotcha::APPROVED])
      .pluck(:source_fingerprint)
      .compact

    patterns.reject { |p| existing_fingerprints.include?(p[:fingerprint]) }
  end

  # Create a suggestion for a detected pattern
  def create_suggestion(project, pattern)
    suggested_content = generate_gotcha_content(pattern)

    SuggestedGotcha.create!(
      project:,
      trigger_type: pattern[:type],
      trigger_data: pattern[:data],
      source_fingerprint: pattern[:fingerprint],
      suggested_content:,
      suggested_title: generate_title(pattern),
      analyzed_at: Time.current
    )
  rescue ActiveRecord::RecordNotUnique
    # Already exists, skip silently
    Rails.logger.debug("[PatternAnalyzer] Skipping duplicate fingerprint: #{pattern[:fingerprint]}")
  rescue => e
    Rails.logger.error("[PatternAnalyzer] Failed to create suggestion: #{e.message}")
  end

  # Generate gotcha content using LLM
  def generate_gotcha_content(pattern)
    prompt = build_llm_prompt(pattern)

    begin
      # Use RubyLLM for content generation
      chat = RubyLLM.chat(model: "gpt-4o-mini")
      response = chat.ask(prompt)
      response.content.strip
    rescue => e
      Rails.logger.warn("[PatternAnalyzer] LLM generation failed: #{e.message}")
      generate_fallback_content(pattern)
    end
  end

  # Build prompt for LLM gotcha generation
  def build_llm_prompt(pattern)
    <<~PROMPT
      You are analyzing error patterns from AI coding sessions to generate helpful "gotcha" reminders.

      Pattern detected:
      - Type: #{pattern[:type]}
      - Tool: #{pattern[:data][:tool_name] || 'unknown'}
      - Error: #{pattern[:data][:error_message] || 'N/A'}
      - Occurrences: #{pattern[:data][:count] || pattern[:data][:failed_calls]}
      - Category: #{pattern[:data][:error_category] || 'unknown'}
      #{pattern[:data][:failure_rate] ? "- Failure Rate: #{(pattern[:data][:failure_rate] * 100).round(1)}%" : ''}

      Sample error messages:
      #{(pattern[:data][:sample_messages] || []).map { |m| "- #{m}" }.join("\n")}

      Generate a concise gotcha (1-2 sentences) that:
      1. Explains what went wrong
      2. Provides the solution or workaround
      3. Uses active voice and imperative mood

      Example format:
      "When using [tool], always [do X] before [doing Y] to avoid [error]."

      Return ONLY the gotcha text, no preamble or explanation.
    PROMPT
  end

  # Fallback content when LLM is unavailable
  def generate_fallback_content(pattern)
    case pattern[:type]
    when SuggestedGotcha::RECURRING_ERROR
      tool = pattern[:data][:tool_name] || "this tool"
      error = pattern[:data][:error_message]&.truncate(100) || "this error"
      "When using #{tool}, be aware of recurring issues with: #{error}. " \
      "This error has occurred #{pattern[:data][:count]} times recently."

    when SuggestedGotcha::HIGH_FAILURE
      tool = pattern[:data][:tool_name] || "this tool"
      rate = (pattern[:data][:failure_rate] * 100).round(1)
      "The #{tool} tool has a #{rate}% failure rate. " \
      "Check inputs carefully and consider retry logic for transient failures."

    else
      "A recurring pattern was detected that may indicate a common issue. " \
      "Review the trigger data for details."
    end
  end

  # Generate a short title for the suggestion
  def generate_title(pattern)
    case pattern[:type]
    when SuggestedGotcha::RECURRING_ERROR
      tool = pattern[:data][:tool_name] || "Tool"
      "#{tool} recurring error"

    when SuggestedGotcha::HIGH_FAILURE
      tool = pattern[:data][:tool_name] || "Tool"
      "#{tool} high failure rate"

    when SuggestedGotcha::RETRY_SEQUENCE
      tool = pattern[:data][:tool_name] || "Tool"
      "#{tool} retry pattern"

    else
      "Detected pattern: #{pattern[:type]}"
    end
  end
end
