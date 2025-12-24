# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ui::LiveSearchFormComponent, type: :component do
  let(:url) { "/search" }
  let(:default_params) { { url: } }

  def render_component(**options)
    render_inline(described_class.new(**default_params.merge(options)))
  end

  describe "rendering" do
    it "renders a form with live-search controller" do
      render_component
      expect(page).to have_css("form[data-controller='live-search']")
    end

    it "renders a search input field" do
      render_component
      expect(page).to have_css("input[type='text'][name='search']")
    end

    it "applies custom placeholder" do
      render_component(search_placeholder: "Find users...")
      expect(page).to have_css("input[placeholder='Find users...']")
    end

    it "uses custom search parameter name" do
      render_component(search_name: :query)
      expect(page).to have_css("input[name='query']")
    end
  end

  describe "debounce configuration" do
    it "sets default debounce value" do
      render_component
      expect(page).to have_css("form[data-live-search-debounce-value='400']")
    end

    it "accepts custom debounce value" do
      render_component(debounce: 500)
      expect(page).to have_css("form[data-live-search-debounce-value='500']")
    end

    it "sets min-length value" do
      render_component(min_length: 3)
      expect(page).to have_css("form[data-live-search-min-length-value='3']")
    end
  end

  describe "Turbo frame targeting" do
    it "does not set turbo_frame by default" do
      render_component
      expect(page).not_to have_css("form[data-turbo-frame]")
    end

    it "sets turbo_frame when provided" do
      render_component(turbo_frame: "results_frame")
      expect(page).to have_css("form[data-turbo-frame='results_frame']")
    end
  end

  describe "filters" do
    context "with select filter" do
      let(:filters) do
        [
          {
            name: :category,
            type: :select,
            label: "Category",
            options: [["All", ""], ["Tech", "tech"], ["Finance", "finance"]]
          }
        ]
      end

      it "renders select filter" do
        render_component(filters:)
        expect(page).to have_css("select[name='category']")
      end

      it "includes filter options" do
        render_component(filters:)
        expect(page).to have_css("option[value='tech']", text: "Tech")
        expect(page).to have_css("option[value='finance']", text: "Finance")
      end

      it "renders filter label when provided" do
        render_component(filters:)
        expect(page).to have_css("label", text: "Category")
      end

      it "wires select to submitNow action" do
        render_component(filters:)
        expect(page).to have_css("select[data-action='change->live-search#submitNow']")
      end
    end

    context "with text filter" do
      let(:filters) do
        [
          {
            name: :author,
            type: :text,
            label: "Author",
            placeholder: "Author name..."
          }
        ]
      end

      it "renders text filter" do
        render_component(filters:)
        expect(page).to have_css("input[type='text'][name='author']")
      end

      it "applies placeholder" do
        render_component(filters:)
        expect(page).to have_css("input[placeholder='Author name...']")
      end

      it "wires text input to search action" do
        render_component(filters:)
        expect(page).to have_css("input[name='author'][data-action='input->live-search#search']")
      end
    end

    context "with date filter" do
      let(:filters) do
        [{ name: :start_date, type: :date, label: "Start Date" }]
      end

      it "renders date filter" do
        render_component(filters:)
        expect(page).to have_css("input[type='date'][name='start_date']")
      end

      it "wires date input to submitNow action" do
        render_component(filters:)
        expect(page).to have_css("input[name='start_date'][data-action='change->live-search#submitNow']")
      end
    end

    context "with hidden filter" do
      let(:filters) do
        [{ name: :project_id, type: :hidden, value: "123" }]
      end

      it "renders hidden field" do
        render_component(filters:)
        expect(page).to have_css("input[type='hidden'][name='project_id'][value='123']", visible: false)
      end
    end
  end

  describe "hidden fields" do
    it "renders hidden fields" do
      render_component(hidden_fields: { token: "abc123", scope: "users" })
      expect(page).to have_css("input[type='hidden'][name='token'][value='abc123']", visible: false)
      expect(page).to have_css("input[type='hidden'][name='scope'][value='users']", visible: false)
    end
  end

  describe "preserving param values" do
    let(:params) { { search: "test query", category: "tech" } }
    let(:filters) do
      [{ name: :category, type: :select, options: [["All", ""], ["Tech", "tech"]] }]
    end

    it "preserves search value from params" do
      render_component(params:)
      expect(page).to have_css("input[name='search'][value='test query']")
    end

    it "preserves filter values from params" do
      render_component(params:, filters:)
      expect(page).to have_css("option[value='tech'][selected]")
    end
  end

  describe "submit button" do
    it "hides submit button by default" do
      render_component
      expect(page).to have_css("input[type='submit'].hidden")
    end

    it "shows submit button when requested" do
      render_component(show_submit: true)
      expect(page).not_to have_css("input[type='submit'].hidden")
    end

    it "uses custom submit text" do
      render_component(show_submit: true, submit_text: "Find")
      expect(page).to have_css("input[type='submit'][value='Find']")
    end
  end

  describe "clear button" do
    context "when no filters are active" do
      it "does not show clear button" do
        render_component(params: {})
        expect(page).not_to have_button("Clear")
      end
    end

    context "when search is active" do
      it "shows clear button" do
        render_component(params: { search: "query" })
        expect(page).to have_css("button[data-action='click->live-search#clear']")
      end
    end

    context "when filter is active" do
      let(:filters) { [{ name: :status, type: :select, options: [["All", ""], ["Active", "active"]] }] }

      it "shows clear button" do
        render_component(params: { status: "active" }, filters:)
        expect(page).to have_css("button[data-action='click->live-search#clear']")
      end
    end
  end

  describe "CSS customization" do
    it "applies wrapper CSS class" do
      render_component(css_class: "my-search-form")
      expect(page).to have_css("div.my-search-form")
    end

    it "applies custom form class" do
      render_component(form_class: "flex gap-4")
      expect(page).to have_css("form.flex.gap-4")
    end

    it "applies custom input class" do
      render_component(input_class: "input-lg")
      expect(page).to have_css("input.input-lg[name='search']")
    end
  end

  describe "#has_active_filters?" do
    it "returns false when no filters are active" do
      component = described_class.new(url:, params: {})
      expect(component.has_active_filters?).to be false
    end

    it "returns true when search is active" do
      component = described_class.new(url:, params: { search: "test" })
      expect(component.has_active_filters?).to be true
    end

    it "returns true when filter is active" do
      filters = [{ name: :status, type: :select }]
      component = described_class.new(url:, params: { status: "active" }, filters:)
      expect(component.has_active_filters?).to be true
    end
  end

  describe "#active_filters_count" do
    it "returns 0 when no filters are active" do
      component = described_class.new(url:, params: {})
      expect(component.active_filters_count).to eq 0
    end

    it "counts search as one filter" do
      component = described_class.new(url:, params: { search: "test" })
      expect(component.active_filters_count).to eq 1
    end

    it "counts all active filters" do
      filters = [
        { name: :status, type: :select },
        { name: :category, type: :select }
      ]
      component = described_class.new(
        url:,
        params: { search: "test", status: "active", category: "tech" },
        filters:
      )
      expect(component.active_filters_count).to eq 3
    end
  end
end
