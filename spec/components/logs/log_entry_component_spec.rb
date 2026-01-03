# frozen_string_literal: true

require "rails_helper"

RSpec.describe Logs::LogEntryComponent, type: :component do
  describe "rendering" do
    let(:valid_entry) do
      {
        id: "log-123",
        timestamp: "2025-01-01T12:00:00.123Z",
        level: "info",
        message: "Test log message",
        source: {
          type: "mcp",
          agent_id: "test-agent"
        }
      }
    end

    it "renders log entry with all fields" do
      render_inline(described_class.new(entry: valid_entry))

      expect(page).to have_text("Test log message")
      expect(page).to have_text("INF")
      expect(page).to have_text("12:00:00")
    end

    it "shows source when show_source is true" do
      render_inline(described_class.new(entry: valid_entry, show_source: true))

      expect(page).to have_text("test-agent")
    end

    it "hides source when show_source is false" do
      render_inline(described_class.new(entry: valid_entry, show_source: false))

      expect(page).not_to have_text("test-agent")
    end

    it "uses compact styling when compact is true" do
      render_inline(described_class.new(entry: valid_entry, compact: true))

      expect(page).to have_css(".text-xs")
    end
  end

  describe "security sanitization" do
    it "escapes HTML in message (Rails auto-escapes)" do
      xss_entry = {
        message: "<script>alert('xss')</script>",
        level: "info"
      }

      render_inline(described_class.new(entry: xss_entry))

      # Should be escaped, not executable
      expect(page.native.inner_html).not_to include("<script>")
      expect(page).to have_text("<script>")
    end

    it "validates log type against allowed values" do
      malicious_entry = {
        message: "test",
        level: "info",
        source: { type: "malicious_type" }
      }

      render_inline(described_class.new(entry: malicious_entry))

      # Should default to application type styling
      expect(page).to have_css("[class*='border-l-accent']")
    end

    it "validates log level against allowed values" do
      malicious_entry = {
        message: "test",
        level: "critical_injection",
        source: { type: "mcp" }
      }

      render_inline(described_class.new(entry: malicious_entry))

      # Should default to info level
      expect(page).to have_text("INF")
    end

    it "truncates excessively long messages" do
      long_entry = {
        message: "x" * 20_000,
        level: "info"
      }

      component = described_class.new(entry: long_entry)
      # Access the sanitized entry
      expect(component.instance_variable_get(:@entry)[:message].length).to be <= 10_000
    end

    it "handles nil entry gracefully" do
      component = described_class.new(entry: nil)

      expect { render_inline(component) }.not_to raise_error
    end

    it "handles non-hash entry gracefully" do
      component = described_class.new(entry: "not a hash")

      expect { render_inline(component) }.not_to raise_error
    end
  end

  describe "log type styling" do
    %i[mcp container application].each do |log_type|
      it "applies correct styling for #{log_type} type" do
        entry = {
          message: "test",
          level: "info",
          source: { type: log_type.to_s }
        }

        render_inline(described_class.new(entry: entry))

        # Each type should have its border color
        border_class = Logs::LogEntryComponent::LOG_TYPE_CONFIG[log_type][:border_class]
        expect(page).to have_css("[class*='#{border_class.split('-').last}']")
      end
    end
  end

  describe "log level styling" do
    {
      error: "ERR",
      warn: "WAR",
      info: "INF",
      debug: "DEB"
    }.each do |level, display|
      it "displays #{level} as #{display}" do
        entry = { message: "test", level: level.to_s }

        render_inline(described_class.new(entry: entry))

        expect(page).to have_text(display)
      end
    end

    it "applies error background for error level" do
      entry = { message: "test", level: "error" }

      render_inline(described_class.new(entry: entry))

      expect(page).to have_css("[class*='bg-error']")
    end

    it "applies error background for fatal level" do
      entry = { message: "test", level: "fatal" }

      render_inline(described_class.new(entry: entry))

      expect(page).to have_css("[class*='bg-error']")
    end
  end

  describe "timestamp formatting" do
    it "formats ISO timestamp correctly" do
      entry = {
        message: "test",
        level: "info",
        timestamp: "2025-12-31T23:59:59.999Z"
      }

      render_inline(described_class.new(entry: entry))

      expect(page).to have_text("23:59:59.999")
    end

    it "handles invalid timestamp gracefully" do
      entry = {
        message: "test",
        level: "info",
        timestamp: "not-a-timestamp"
      }

      expect { render_inline(described_class.new(entry: entry)) }.not_to raise_error
    end

    it "handles nil timestamp" do
      entry = { message: "test", level: "info", timestamp: nil }

      expect { render_inline(described_class.new(entry: entry)) }.not_to raise_error
    end
  end
end
