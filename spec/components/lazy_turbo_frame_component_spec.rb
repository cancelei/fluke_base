# frozen_string_literal: true

require "rails_helper"

RSpec.describe LazyTurboFrameComponent, type: :component do
  let(:frame_id) { "test-frame" }
  let(:src_path) { "/test/path" }
  let(:title) { "Loading Title" }
  let(:description) { "Loading description text" }

  describe "rendering" do
    it "renders a turbo-frame element" do
      render_inline(described_class.new(
        frame_id: frame_id,
        src_path: src_path,
        title: title,
        description: description
      ))

      expect(page).to have_css("turbo-frame")
    end

    it "renders with correct frame id" do
      render_inline(described_class.new(
        frame_id: "my-frame",
        src_path: src_path,
        title: title,
        description: description
      ))

      expect(page).to have_css("turbo-frame#my-frame")
    end

    it "renders with src attribute" do
      render_inline(described_class.new(
        frame_id: frame_id,
        src_path: "/custom/path",
        title: title,
        description: description
      ))

      expect(page).to have_css("turbo-frame[src='/custom/path']")
    end

    it "renders with lazy loading" do
      render_inline(described_class.new(
        frame_id: frame_id,
        src_path: src_path,
        title: title,
        description: description
      ))

      expect(page).to have_css("turbo-frame[loading='lazy']")
    end
  end

  describe "loading placeholder" do
    it "renders loading placeholder inside frame" do
      render_inline(described_class.new(
        frame_id: frame_id,
        src_path: src_path,
        title: "Test Title",
        description: description
      ))

      expect(page).to have_text("Test Title")
    end

    it "renders placeholder description" do
      render_inline(described_class.new(
        frame_id: frame_id,
        src_path: src_path,
        title: title,
        description: "Custom description"
      ))

      expect(page).to have_text("Custom description")
    end

    it "renders loading spinner" do
      render_inline(described_class.new(
        frame_id: frame_id,
        src_path: src_path,
        title: title,
        description: description
      ))

      expect(page).to have_css("div.animate-spin")
    end
  end
end
