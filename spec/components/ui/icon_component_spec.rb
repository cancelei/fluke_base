# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::IconComponent, type: :component do
  describe "rendering" do
    it "renders the plus icon" do
      render_inline(described_class.new(name: :plus))

      expect(page).to have_css("svg")
      expect(page).to have_css("path")
    end

    it "renders with default medium size" do
      render_inline(described_class.new(name: :edit))

      expect(page).to have_css("svg.h-5.w-5")
    end

    it "renders with small size" do
      render_inline(described_class.new(name: :trash, size: :sm))

      expect(page).to have_css("svg.h-4.w-4")
    end

    it "renders with large size" do
      render_inline(described_class.new(name: :eye, size: :lg))

      expect(page).to have_css("svg.h-6.w-6")
    end

    it "renders with extra large size" do
      render_inline(described_class.new(name: :folder, size: :xl))

      expect(page).to have_css("svg.h-8.w-8")
    end

    it "renders with custom css class" do
      render_inline(described_class.new(name: :lock, css_class: "text-red-500"))

      expect(page).to have_css("svg.text-red-500")
    end

    it "renders github icon with correct viewbox" do
      result = render_inline(described_class.new(name: :github))

      # Nokogiri lowercases attribute names in HTML parsing
      expect(result.to_html).to include('viewbox="0 0 24 24"')
    end

    it "renders icons with multiple paths" do
      render_inline(described_class.new(name: :eye))

      expect(page).to have_css("svg path", count: 2)
    end
  end

  describe "accessibility" do
    it "includes aria-hidden attribute" do
      render_inline(described_class.new(name: :check))

      expect(page).to have_css("svg[aria-hidden='true']")
    end

    it "includes role attribute" do
      render_inline(described_class.new(name: :x))

      expect(page).to have_css("svg[role='img']")
    end
  end

  describe "render?" do
    it "does not render when name is blank" do
      component = described_class.new(name: "")

      expect(component.render?).to be false
    end

    it "does not render when icon is not found" do
      component = described_class.new(name: :nonexistent_icon)

      expect(component.render?).to be false
    end

    it "renders when icon exists" do
      component = described_class.new(name: :plus)

      expect(component.render?).to be true
    end
  end

  describe "icon variations" do
    %i[plus edit trash eye message lock github exclamation_triangle check x folder search user cog bell].each do |icon_name|
      it "renders #{icon_name} icon" do
        render_inline(described_class.new(name: icon_name))

        expect(page).to have_css("svg")
      end
    end
  end
end
