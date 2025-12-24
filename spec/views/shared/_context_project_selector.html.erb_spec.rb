require 'rails_helper'

RSpec.describe "shared/_context_project_selector", type: :view do
  let(:user) { create(:user) }
  let!(:project) { create(:project, user:, name: "Test Project") }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:controller_name).and_return("dashboard")
    allow(view).to receive_message_chain(:request, :path).and_return("/dashboard")

    presenter = double("ProjectPresenter")
    allow(presenter).to receive(:display_name).and_return("Test Project")
    allow(view).to receive(:present).and_return(presenter)
  end

  it "renders the 'New Project' button instead of 'Switch Project Context' text" do
    render
    expect(rendered).to have_link("New Project", href: new_project_path, visible: :all)
    expect(rendered).to have_selector("a[href='#{new_project_path}'][data-turbo-frame='_top']", visible: :all)
    expect(rendered).not_to have_content("Switch Project Context")
  end

  it "renders the icon for new project" do
    render
    # The icon is rendered via Ui::IconComponent, checking for fragment validity
    expect(rendered).to have_selector("a[href='#{new_project_path}'] svg", visible: :all)
  end

  context "when on a project-specific page with slug" do
    let!(:other_project) { create(:project, user:, name: "Other Project") }

    before do
      # Simulate being on a project milestones page with slug URL
      allow(view).to receive_message_chain(:request, :path).and_return("/projects/#{project.slug}/milestones/new")

      # Override presenter for multiple projects
      allow(view).to receive(:present) do |proj|
        double("ProjectPresenter", display_name: proj.name)
      end
    end

    it "generates links with slugs for project navigation" do
      render partial: "shared/context_project_selector", locals: { current_user: user, selected_project: project }

      # The links should contain slugs, not numeric IDs
      # Due to how Capybara visible matching works, check the raw HTML
      expect(rendered).to include("/projects/#{project.to_param}/milestones/new")
      expect(rendered).to include("/projects/#{other_project.to_param}/milestones/new")
    end
  end

  context "when on a non-project page" do
    let!(:other_project) { create(:project, user:, name: "Other Project") }

    before do
      # Simulate being on the dashboard (non-project page)
      allow(view).to receive_message_chain(:request, :path).and_return("/dashboard")

      # Override presenter for multiple projects
      allow(view).to receive(:present) do |proj|
        double("ProjectPresenter", display_name: proj.name)
      end
    end

    it "generates links to project/show pages" do
      render partial: "shared/context_project_selector", locals: { current_user: user, selected_project: project }

      # Links should go to project/show pages (not stay on dashboard)
      expect(rendered).to include("/projects/#{project.to_param}")
      expect(rendered).to include("/projects/#{other_project.to_param}")
      # Should NOT try to do slug replacement on dashboard path
      expect(rendered).not_to include("/dashboard")
    end
  end
end
