# frozen_string_literal: true

# Stores AI provider chat exchanges from flukebase_connect sessions.
# Supports Claude and OpenAI providers, with full conversation history
# including token counts and tool call metadata.
#
# Used by the Unified Logs dashboard to display AI conversation history.
# == Schema Information
#
# Table name: ai_conversation_logs
#
#  id            :bigint           not null, primary key
#  content       :text
#  duration_ms   :float
#  exchanged_at  :datetime
#  input_tokens  :integer
#  message_index :integer          default(0)
#  metadata      :jsonb
#  model         :string           not null
#  output_tokens :integer
#  provider      :string           not null
#  role          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  external_id   :string
#  project_id    :bigint
#  session_id    :string           not null
#  user_id       :bigint
#
# Indexes
#
#  index_ai_conversation_logs_on_exchanged_at               (exchanged_at)
#  index_ai_conversation_logs_on_external_id                (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_ai_conversation_logs_on_project_id                 (project_id)
#  index_ai_conversation_logs_on_project_id_and_session_id  (project_id,session_id)
#  index_ai_conversation_logs_on_provider                   (provider)
#  index_ai_conversation_logs_on_user_id                    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class AiConversationLog < ApplicationRecord
  # Associations
  belongs_to :project, optional: true
  belongs_to :user, optional: true

  # Validations
  validates :provider, presence: true, inclusion: { in: %w[claude openai gemini] }
  validates :model, presence: true
  validates :session_id, presence: true
  validates :role, presence: true, inclusion: { in: %w[user assistant system tool] }

  # Scopes for filtering
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :by_session, ->(session_id) { where(session_id: session_id) }
  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_role, ->(role) { where(role: role) }
  scope :recent, ->(limit = 100) { order(exchanged_at: :desc).limit(limit) }
  scope :today, -> { where("exchanged_at >= ?", Time.current.beginning_of_day) }
  scope :assistant_messages, -> { where(role: "assistant") }
  scope :user_messages, -> { where(role: "user") }

  # Order by message index within a session
  scope :in_order, -> { order(:session_id, :message_index) }

  # Class methods for aggregation
  class << self
    # Get total tokens used across records
    def total_tokens
      sum(:input_tokens).to_i + sum(:output_tokens).to_i
    end

    # Get average response time
    def avg_duration_ms
      average(:duration_ms)&.round(2)
    end

    # Group by provider for statistics
    def stats_by_provider
      group(:provider).select(
        :provider,
        "COUNT(*) as message_count",
        "SUM(input_tokens) as total_input_tokens",
        "SUM(output_tokens) as total_output_tokens",
        "AVG(duration_ms) as avg_duration_ms"
      )
    end
  end

  # Format for Unified Logs display
  # Returns a hash compatible with UnifiedLogsChannel.broadcast_log
  def to_unified_log_entry
    {
      "id" => external_id || "ai-#{id}",
      "timestamp" => (exchanged_at || created_at).iso8601,
      "level" => determine_log_level,
      "message" => build_log_message,
      "source" => {
        "type" => "ai_provider",
        "provider" => provider,
        "model" => model,
        "agent_id" => session_id
      },
      "tags" => build_tags,
      "project_id" => project_id&.to_s,
      "tokens" => total_tokens_for_entry,
      "duration_ms" => duration_ms
    }
  end

  # Get total tokens for this entry
  def total_tokens_for_entry
    (input_tokens || 0) + (output_tokens || 0)
  end

  # Check if this is a tool call message
  def tool_call?
    role == "tool" || metadata&.dig("tool_calls").present?
  end

  # Get tool calls from metadata
  def tool_calls
    metadata&.dig("tool_calls") || []
  end

  # Truncated content for display
  def truncated_content(max_length = 200)
    return "" if content.blank?

    content.length > max_length ? "#{content[0...max_length]}..." : content
  end

  private

  def determine_log_level
    case role
    when "assistant"
      "info"
    when "user"
      "debug"
    when "system"
      "trace"
    when "tool"
      metadata&.dig("error") ? "error" : "info"
    else
      "info"
    end
  end

  def build_log_message
    prefix = "[#{provider.upcase}] #{role.capitalize}"

    if tool_call?
      tool_names = tool_calls.map { |t| t["name"] || t["function"]&.dig("name") }.compact.join(", ")
      "#{prefix}: Tool calls: #{tool_names}"
    else
      "#{prefix}: #{truncated_content(150)}"
    end
  end

  def build_tags
    tags = [provider, model, role]
    tags << "tool_call" if tool_call?
    tags << "project_#{project_id}" if project_id
    tags.compact
  end
end
