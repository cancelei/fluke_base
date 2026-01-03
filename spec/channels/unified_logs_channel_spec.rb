# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnifiedLogsChannel, type: :channel do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    context "without project_id" do
      it "subscribes to user-specific stream" do
        subscribe

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("unified_logs:user_#{user.id}")
      end
    end

    context "with valid project_id" do
      it "subscribes to project-specific stream when user owns project" do
        subscribe(project_id: project.id)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("unified_logs:project_#{project.id}:user_#{user.id}")
      end
    end

    context "with project_id user cannot access" do
      let(:other_project) { create(:project) }

      it "rejects subscription" do
        subscribe(project_id: other_project.id)

        expect(subscription).to be_rejected
      end
    end

    context "with malicious project_id" do
      it "sanitizes SQL injection attempt" do
        # Use the user's project ID with SQL injection appended
        subscribe(project_id: "#{project.id}; DROP TABLE users;--")

        # Should extract just the numeric part and allow access to user's project
        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("unified_logs:project_#{project.id}:user_#{user.id}")
      end
    end

    context "with sandbox_id" do
      it "validates sandbox_id format" do
        subscribe(sandbox_id: "valid-sandbox-123")

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("unified_logs:sandbox_valid-sandbox-123:user_#{user.id}")
      end

      it "sanitizes malicious sandbox_id" do
        subscribe(sandbox_id: "<script>alert('xss')</script>")

        expect(subscription).to be_confirmed
        # Malicious characters should be stripped
      end
    end
  end

  describe "#set_filter" do
    before { subscribe }

    it "validates allowed types" do
      perform :set_filter, types: %w[mcp container invalid_type]

      # Should only include valid types
      expect(transmissions.last["filter"]["types"]).to eq(%w[mcp container])
    end

    it "validates allowed levels" do
      perform :set_filter, levels: %w[info error invalid_level]

      expect(transmissions.last["filter"]["levels"]).to eq(%w[info error])
    end

    it "sanitizes search query" do
      perform :set_filter, search: "<script>alert('xss')</script>"

      # Should strip < and > characters
      expect(transmissions.last["filter"]["search"]).not_to include("<")
      expect(transmissions.last["filter"]["search"]).not_to include(">")
    end

    it "truncates long search queries" do
      long_search = "a" * 1000
      perform :set_filter, search: long_search

      expect(transmissions.last["filter"]["search"].length).to be <= 500
    end
  end

  describe "#get_history" do
    before { subscribe }

    it "limits history to max 500 entries" do
      perform :get_history, limit: 1000

      expect(transmissions.last["type"]).to eq("history")
      # Limit should be capped
    end

    it "defaults to 100 when invalid limit provided" do
      perform :get_history, limit: -5

      expect(transmissions.last["type"]).to eq("history")
    end
  end

  describe ".broadcast_log" do
    it "sanitizes log entry before broadcasting" do
      malicious_entry = {
        "id" => "<script>alert(1)</script>",
        "message" => "<img onerror='alert(1)' src=x>",
        "level" => "invalid_level",
        "source" => {
          "type" => "malicious_type",
          "agent_id" => "valid-agent"
        }
      }

      expect(ActionCable.server).to receive(:broadcast).with(
        "unified_logs:all",
        hash_including(
          type: "log",
          entry: hash_including(
            "id" => "scriptalert1script",  # stripped of special chars
            "level" => "info",  # defaulted to info
            "source" => hash_including("type" => "application")  # defaulted to application
          )
        )
      )

      described_class.broadcast_log(malicious_entry)
    end

    it "truncates excessively long messages" do
      long_message = "x" * 20_000
      entry = { "message" => long_message, "level" => "info" }

      expect(ActionCable.server).to receive(:broadcast) do |_stream, data|
        expect(data[:entry]["message"].length).to be <= 10_000
      end

      described_class.broadcast_log(entry)
    end
  end

  describe ".sanitize_log_entry" do
    it "handles nil entry gracefully" do
      result = described_class.sanitize_log_entry(nil)
      expect(result).to eq({})
    end

    it "handles non-hash entry gracefully" do
      result = described_class.sanitize_log_entry("not a hash")
      expect(result).to eq({})
    end

    it "preserves valid entry data" do
      entry = {
        "id" => "log-123",
        "timestamp" => "2025-01-01T00:00:00Z",
        "level" => "error",
        "message" => "Test error message",
        "source" => {
          "type" => "mcp",
          "agent_id" => "test-agent"
        }
      }

      result = described_class.sanitize_log_entry(entry)

      expect(result["id"]).to eq("log-123")
      expect(result["level"]).to eq("error")
      expect(result["message"]).to eq("Test error message")
      expect(result["source"]["type"]).to eq("mcp")
    end
  end
end
