# frozen_string_literal: true

require "rails_helper"

RSpec.describe AiInsights::InsightCardComponent, type: :component do
  describe "rendering" do
    it "renders the card with title" do
      render_inline(described_class.new(type: :time_saved, title: "Time Saved by AI"))

      expect(page).to have_text("Time Saved by AI")
    end

    it "renders as a div element with card classes" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).to have_css("div.card")
      expect(page).to have_css("div.bg-base-100")
      expect(page).to have_css("div.shadow-md")
    end

    it "includes stimulus controller data" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).to have_css("[data-controller='insight-card']")
      expect(page).to have_css("[data-insight-card-type-value='time_saved']")
    end
  end

  describe "dom_id" do
    it "generates correct dom id based on type" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).to have_css("#insight-card-time_saved")
    end

    it "uses different id for different types" do
      render_inline(described_class.new(type: :code_contribution, title: "Test"))

      expect(page).to have_css("#insight-card-code_contribution")
    end
  end

  describe "insight types" do
    it "renders time_saved type with clock icon class" do
      render_inline(described_class.new(type: :time_saved, title: "Time Saved"))

      expect(page).to have_css(".bg-primary\\/10")
      expect(page).to have_css(".text-primary")
    end

    it "renders code_contribution type with success color" do
      render_inline(described_class.new(type: :code_contribution, title: "Code"))

      expect(page).to have_css(".bg-success\\/10")
      expect(page).to have_css(".text-success")
    end

    it "renders task_velocity type with secondary color" do
      render_inline(described_class.new(type: :task_velocity, title: "Tasks"))

      expect(page).to have_css(".bg-secondary\\/10")
      expect(page).to have_css(".text-secondary")
    end

    it "renders token_efficiency type with accent color" do
      render_inline(described_class.new(type: :token_efficiency, title: "Tokens"))

      expect(page).to have_css(".bg-accent\\/10")
      expect(page).to have_css(".text-accent")
    end
  end

  describe "value display" do
    it "renders value when provided" do
      render_inline(described_class.new(type: :time_saved, title: "Time Saved", value: "12.5h"))

      expect(page).to have_text("12.5h")
      expect(page).to have_css(".text-3xl.font-bold")
    end

    it "renders empty value when nil" do
      render_inline(described_class.new(type: :time_saved, title: "Time Saved"))

      # Value container exists but is empty
      expect(page).to have_css(".text-3xl.font-bold", text: "")
    end
  end

  describe "description" do
    it "renders description when provided" do
      render_inline(described_class.new(type: :time_saved, title: "Test", description: "This week"))

      expect(page).to have_text("This week")
      expect(page).to have_css(".text-sm.text-base-content\\/70")
    end

    it "does not render description section when nil" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).not_to have_css(".text-base-content\\/70")
    end
  end

  describe "trends" do
    it "renders up trend with success color" do
      render_inline(described_class.new(type: :time_saved, title: "Test", trend: :up, trend_value: "+15%"))

      expect(page).to have_text("+15%")
      expect(page).to have_css(".text-success")
    end

    it "renders down trend with error color" do
      render_inline(described_class.new(type: :time_saved, title: "Test", trend: :down, trend_value: "-5%"))

      expect(page).to have_text("-5%")
      expect(page).to have_css(".text-error")
    end

    it "renders neutral trend with muted color" do
      render_inline(described_class.new(type: :time_saved, title: "Test", trend: :neutral))

      expect(page).to have_css(".text-base-content\\/50")
    end

    it "does not render trend when not provided" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).not_to have_css(".text-success")
      expect(page).not_to have_css(".text-error")
    end
  end

  describe "dismissible" do
    it "renders dismiss button by default" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).to have_css("button[data-action='click->insight-card#dismiss']")
    end

    it "hides dismiss button when dismissible is false" do
      render_inline(described_class.new(type: :time_saved, title: "Test", dismissible: false))

      expect(page).not_to have_css("button[data-action='click->insight-card#dismiss']")
    end
  end

  describe "detail_path" do
    it "adds cursor-pointer class when detail_path is provided" do
      render_inline(described_class.new(type: :time_saved, title: "Test", detail_path: "/insights/time_saved"))

      expect(page).to have_css("div.cursor-pointer")
    end

    it "adds click navigation action when detail_path is provided" do
      render_inline(described_class.new(type: :time_saved, title: "Test", detail_path: "/insights/time_saved"))

      expect(page).to have_css("[data-action*='click->insight-card#navigate']")
      expect(page).to have_css("[data-insight-card-detail-path-value='/insights/time_saved']")
    end

    it "renders view details link" do
      render_inline(described_class.new(type: :time_saved, title: "Test", detail_path: "/insights/time_saved"))

      expect(page).to have_text("View details")
    end

    it "does not add navigation when detail_path is nil" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).not_to have_css("div.cursor-pointer")
      expect(page).not_to have_text("View details")
    end
  end

  describe "intro_key" do
    it "uses default intro key based on type" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).to have_css("[data-insight-card-intro-key-value='time_saved_intro']")
    end

    it "uses custom intro key when provided" do
      render_inline(described_class.new(type: :time_saved, title: "Test", intro_key: "custom_intro"))

      expect(page).to have_css("[data-insight-card-intro-key-value='custom_intro']")
    end
  end

  describe "compact mode" do
    it "uses default padding when not compact" do
      render_inline(described_class.new(type: :time_saved, title: "Test", compact: false))

      expect(page).to have_css(".py-3")
    end

    it "adds card-compact class when compact" do
      render_inline(described_class.new(type: :time_saved, title: "Test", compact: true))

      expect(page).to have_css("div.card-compact")
    end

    it "uses smaller padding when compact" do
      render_inline(described_class.new(type: :time_saved, title: "Test", compact: true))

      expect(page).to have_css(".py-2")
    end
  end

  describe "icon rendering" do
    it "renders svg icon for time_saved" do
      render_inline(described_class.new(type: :time_saved, title: "Test"))

      expect(page).to have_css("svg")
    end

    it "renders svg icon for code_contribution" do
      render_inline(described_class.new(type: :code_contribution, title: "Test"))

      expect(page).to have_css("svg")
    end

    it "renders svg icon for task_velocity" do
      render_inline(described_class.new(type: :task_velocity, title: "Test"))

      expect(page).to have_css("svg")
    end

    it "renders svg icon for token_efficiency" do
      render_inline(described_class.new(type: :token_efficiency, title: "Test"))

      expect(page).to have_css("svg")
    end
  end

  describe "full example" do
    it "renders complete card with all options" do
      render_inline(described_class.new(
        type: :time_saved,
        title: "Time Saved by AI",
        value: "12.5h",
        description: "This week",
        trend: :up,
        trend_value: "+25%",
        detail_path: "/insights/time_saved",
        dismissible: true,
        compact: false
      ))

      expect(page).to have_css("#insight-card-time_saved")
      expect(page).to have_text("Time Saved by AI")
      expect(page).to have_text("12.5h")
      expect(page).to have_text("This week")
      expect(page).to have_text("+25%")
      expect(page).to have_text("View details")
      expect(page).to have_css("button[data-action='click->insight-card#dismiss']")
      expect(page).to have_css("[data-controller='insight-card']")
    end
  end
end
