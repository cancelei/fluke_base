require 'rails_helper'

RSpec.describe "projects/index.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:project) { create(:project, user:, name: 'Alpha') }

  before do
    allow(view).to receive(:current_user).and_return(user)
    assign(:projects, [project])
    assign(:pagy, Pagy.new(count: 1, page: 1, items: 12))
    allow(view).to receive(:present) do |object|
      instance_double('ProjectPresenter',
        display_name: object.name,
        stage_badge: '<span class="badge">Stage</span>'.html_safe,
        display_description: 'Desc',
        milestones_summary: '0/0')
    end
    allow(view).to receive(:field_visible_to_user?).and_return(true)

    # Define helper methods directly on the view for testing
    view.singleton_class.class_eval do
      def new_project_path
        '/projects/new'
      end

      def project_path(project)
        "/projects/#{project.id}"
      end

      def edit_project_path(project)
        "/projects/#{project.id}/edit"
      end
    end
  end

  it 'renders My Projects header and project card' do
    render
    expect(rendered).to include('New Project')
    expect(rendered).to include('Alpha')
  end
end
