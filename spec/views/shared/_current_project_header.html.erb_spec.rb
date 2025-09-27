require 'rails_helper'

RSpec.describe "shared/_current_project_header", type: :view do
  let(:user) { create(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  describe "with selected project" do
    let(:project) { create(:project, name: "FlukeBase Platform", user: user) }

    before do
      user.update!(selected_project: project)
      render
    end

    it "displays the selected project name" do
      expect(rendered).to have_content("FlukeBase Platform")
    end

    it "applies proper styling classes" do
      expect(rendered).to have_css(".font-bold.text-lg.text-indigo-700")
    end

    it "contains the project name in a div" do
      expect(rendered).to have_css("div", text: "FlukeBase Platform")
    end
  end

  describe "without selected project" do
    before do
      user.update!(selected_project: nil)
      render
    end

    it "displays fallback message" do
      expect(rendered).to have_content("No project selected")
    end

    it "applies same styling to fallback message" do
      expect(rendered).to have_css(".font-bold.text-lg.text-indigo-700")
    end

    it "contains fallback message in a div" do
      expect(rendered).to have_css("div", text: "No project selected")
    end
  end

  describe "with project name containing special characters" do
    let(:project) { create(:project, name: "AI & Machine Learning Project <2024>", user: user) }

    before do
      user.update!(selected_project: project)
      render
    end

    it "properly escapes special characters" do
      expect(rendered).to have_content("AI & Machine Learning Project <2024>")
    end

    it "does not render HTML tags as elements" do
      expect(rendered).not_to have_css("h1")
    end
  end

  describe "with very long project name" do
    let(:project) { create(:project, name: "This is a very long project name that might cause layout issues if not handled properly in the user interface", user: user) }

    before do
      user.update!(selected_project: project)
      render
    end

    it "displays the full project name" do
      expect(rendered).to have_content("This is a very long project name that might cause layout issues if not handled properly in the user interface")
    end

    it "maintains proper styling" do
      expect(rendered).to have_css(".font-bold.text-lg.text-indigo-700")
    end
  end

  describe "with empty project name" do
    let(:project) { build(:project, name: "", user: user) }

    before do
      user.selected_project = project
      render
    end

    it "displays empty project name" do
      expect(rendered).to have_css("div")
      expect(rendered.strip).not_to include("No project selected")
    end
  end

  describe "styling classes" do
    before do
      user.update!(selected_project: nil)
      render
    end

    it "includes all required CSS classes" do
      div_element = Nokogiri::HTML(rendered).css("div").first
      classes = div_element['class'].split

      expect(classes).to include("font-bold")
      expect(classes).to include("text-lg")
      expect(classes).to include("text-indigo-700")
    end
  end

  describe "HTML structure" do
    before do
      user.update!(selected_project: nil)
      render
    end

    it "generates valid HTML" do
      expect(rendered).to match(%r{<div class="[^"]+">.*</div>}m)
    end

    it "uses a single div element" do
      parsed_html = Nokogiri::HTML(rendered)
      divs = parsed_html.css("div")
      expect(divs.length).to eq(1)
    end
  end

  describe "accessibility considerations" do
    let(:project) { create(:project, name: "Test Project", user: user) }

    before do
      user.update!(selected_project: project)
      render
    end

    it "provides readable text content" do
      expect(rendered).to have_content("Test Project")
    end

    it "uses semantic HTML structure" do
      expect(rendered).to have_css("div")
    end

    it "has sufficient visual hierarchy with text size" do
      expect(rendered).to have_css(".text-lg")
    end
  end

  describe "integration scenarios" do
    context "when used in navigation contexts" do
      let(:project) { create(:project, name: "Navigation Test", user: user) }

      before do
        user.update!(selected_project: project)
        render
      end

      it "displays project name for navigation use" do
        expect(rendered).to have_content("Navigation Test")
        expect(rendered).to have_css(".text-indigo-700")
      end
    end

    context "when project is deleted after selection" do
      before do
        project = create(:project, name: "Deleted Project", user: user)
        user.update!(selected_project: project)
        project.destroy
        user.reload
        render
      end

      it "handles deleted project gracefully" do
        expect(rendered).to have_content("No project selected")
      end
    end
  end

  describe "edge cases" do
    context "when current_user is nil" do
      before do
        allow(view).to receive(:current_user).and_return(nil)
      end

      it "handles nil user gracefully" do
        expect { render }.not_to raise_error
      end
    end

    context "when selected_project association is broken" do
      before do
        # Simulate a broken association
        allow(user).to receive(:selected_project).and_return(nil)
        render
      end

      it "displays fallback message" do
        expect(rendered).to have_content("No project selected")
      end
    end
  end

  describe "internationalization support" do
    context "with unicode project names" do
      let(:project) { create(:project, name: "项目名称 プロジェクト名 اسم المشروع", user: user) }

      before do
        user.update!(selected_project: project)
        render
      end

      it "properly displays unicode characters" do
        expect(rendered).to have_content("项目名称 プロジェクト名 اسم المشروع")
      end
    end
  end
end
