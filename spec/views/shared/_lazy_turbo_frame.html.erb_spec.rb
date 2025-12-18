require 'rails_helper'

RSpec.describe "shared/_lazy_turbo_frame", type: :view do
  let(:frame_id) { "test_frame" }
  let(:src_path) { "/test/lazy_load" }
  let(:title) { "Test Section" }
  let(:description) { "This is a test section description" }

  before do
    render partial: "shared/lazy_turbo_frame", locals: {
      frame_id: frame_id,
      src_path: src_path,
      title: title,
      description: description
    }
  end

  describe "turbo frame structure" do
    it "renders a turbo frame with correct attributes" do
      expect(rendered).to have_css("turbo-frame[id='#{frame_id}']")
      expect(rendered).to have_css("turbo-frame[src='#{src_path}']")
      expect(rendered).to have_css("turbo-frame[loading='lazy']")
    end

    it "includes the lazy loading placeholder inside the frame" do
      within_frame = Nokogiri::HTML(rendered).css("turbo-frame##{frame_id}").inner_html
      expect(within_frame).to include(title)
      expect(within_frame).to include(description)
      expect(within_frame).to include("Loading content...")
    end
  end

  describe "placeholder content" do
    it "displays the provided title" do
      expect(rendered).to have_content(title)
      expect(rendered).to have_css("h3", text: title)
    end

    it "displays the provided description" do
      expect(rendered).to have_content(description)
      expect(rendered).to have_css("p", text: description)
    end

    it "shows loading indicator with accessibility features" do
      expect(rendered).to have_css("[role='status']")
      expect(rendered).to have_css("[aria-label]")
      expect(rendered).to have_css(".loading.loading-spinner")
      expect(rendered).to have_css(".sr-only", text: "Loading content...")
    end

    it "includes loading message" do
      expect(rendered).to have_content("Loading content...")
    end
  end

  describe "responsive design classes" do
    it "includes proper responsive classes" do
      expect(rendered).to have_css(".max-w-xs")
    end
  end

  describe "accessibility features" do
    it "includes proper semantic structure" do
      expect(rendered).to have_css("h3")
      expect(rendered).to have_css("p")
    end

    it "includes screen reader support" do
      expect(rendered).to have_css(".sr-only")
      expect(rendered).to have_css("[role='status']")
      expect(rendered).to have_css("[aria-label]")
    end
  end

  describe "styling structure" do
    it "includes proper container styling" do
      expect(rendered).to have_css(".card.bg-base-100.shadow-xl")
    end

    it "includes proper text styling" do
      expect(rendered).to have_css(".card-title")
      expect(rendered).to have_css(".text-sm")
    end

    it "includes proper spacing classes" do
      expect(rendered).to have_css(".divider")
      expect(rendered).to have_css(".py-6")
    end
  end

  describe "loading animation" do
    it "includes proper animation classes" do
      expect(rendered).to have_css(".loading.loading-spinner")
      expect(rendered).to have_css(".skeleton")
    end
  end

  describe "edge cases" do
    context "with empty title" do
      let(:title) { "" }

      it "handles empty title gracefully" do
        expect(rendered).to have_css(".card")
        expect(rendered).not_to have_content("undefined")
      end
    end

    context "with empty description" do
      let(:description) { "" }

      it "handles empty description gracefully" do
        expect(rendered).to have_css(".card")
        expect(rendered).not_to have_content("undefined")
      end
    end

    context "with long content" do
      let(:title) { "This is a very long title that might wrap to multiple lines" }
      let(:description) { "This is a very long description that should test how the component handles lengthy text content and whether it maintains proper styling and layout." }

      it "handles long content properly" do
        expect(rendered).to have_content(title)
        expect(rendered).to have_content(description)
        expect(rendered).to have_css(".max-w-xs")
      end
    end

    context "with special characters" do
      let(:title) { "Test & Special <Characters>" }
      let(:description) { "Description with 'quotes' and \"double quotes\"" }

      it "properly escapes special characters" do
        expect(rendered).to have_content("Test & Special <Characters>")
        expect(rendered).to have_content("Description with 'quotes' and \"double quotes\"")
      end
    end
  end

  describe "integration with turbo" do
    it "creates valid HTML that Turbo can process" do
      parsed_html = Nokogiri::HTML(rendered)
      turbo_frame = parsed_html.css("turbo-frame").first

      expect(turbo_frame).to be_present
      expect(turbo_frame['id']).to eq(frame_id)
      expect(turbo_frame['src']).to eq(src_path)
      expect(turbo_frame['loading']).to eq('lazy')
    end

    it "nests content properly within the frame" do
      parsed_html = Nokogiri::HTML(rendered)
      frame_content = parsed_html.css("turbo-frame##{frame_id}").inner_html

      expect(frame_content).to include("card bg-base-100")
      expect(frame_content).to include(title)
      expect(frame_content).to include("Loading content...")
    end
  end
end
