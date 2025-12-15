# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::PaginationComponent, type: :component do
  # Mock paginated collection
  let(:paginated_records) do
    double("PaginatedRecords", total_pages: 5, current_page: 1)
  end

  let(:single_page_records) do
    double("SinglePageRecords", total_pages: 1, current_page: 1)
  end

  let(:non_paginated_records) do
    []
  end

  describe "render?" do
    it "renders when records have multiple pages" do
      component = described_class.new(records: paginated_records)

      expect(component.render?).to be true
    end

    it "does not render when records have single page" do
      component = described_class.new(records: single_page_records)

      expect(component.render?).to be false
    end

    it "does not render when records are not paginated" do
      component = described_class.new(records: non_paginated_records)

      expect(component.render?).to be false
    end
  end

  describe "rendering" do
    before do
      # Mock the paginate helper since we don't have real Kaminari setup in tests
      allow_any_instance_of(described_class).to receive(:helpers).and_return(
        double(paginate: "<nav class='pagination'>Pagination</nav>".html_safe)
      )
    end

    it "renders a container div" do
      render_inline(described_class.new(records: paginated_records))

      expect(page).to have_css("div")
    end

    it "renders with glassmorphism styling" do
      render_inline(described_class.new(records: paginated_records))

      expect(page).to have_css("div.bg-white\\/95")
    end

    it "renders with backdrop blur" do
      render_inline(described_class.new(records: paginated_records))

      expect(page).to have_css("div.backdrop-blur-md")
    end

    it "renders with shadow" do
      render_inline(described_class.new(records: paginated_records))

      expect(page).to have_css("div.shadow-lg")
    end

    it "renders with ring border" do
      render_inline(described_class.new(records: paginated_records))

      expect(page).to have_css("div.ring-1.ring-gray-200\\/50")
    end

    it "renders with rounded corners" do
      render_inline(described_class.new(records: paginated_records))

      expect(page).to have_css("div.rounded-2xl")
    end

    it "renders with padding" do
      render_inline(described_class.new(records: paginated_records))

      expect(page).to have_css("div.px-6.py-4")
    end

    it "renders pagination content" do
      render_inline(described_class.new(records: paginated_records))

      expect(page).to have_text("Pagination")
    end
  end

  describe "custom css_class" do
    before do
      allow_any_instance_of(described_class).to receive(:helpers).and_return(
        double(paginate: "<nav>Pagination</nav>".html_safe)
      )
    end

    it "includes custom class when provided" do
      render_inline(described_class.new(records: paginated_records, css_class: "custom-class"))

      expect(page).to have_css("div.custom-class")
    end
  end

  describe "remote option" do
    it "accepts remote option" do
      component = described_class.new(records: paginated_records, remote: true)

      expect(component.instance_variable_get(:@remote)).to be true
    end

    it "defaults remote to false" do
      component = described_class.new(records: paginated_records)

      expect(component.instance_variable_get(:@remote)).to be false
    end
  end
end
