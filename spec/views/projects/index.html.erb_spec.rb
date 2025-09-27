require 'rails_helper'

RSpec.describe "projects/index.html.erb", type: :view do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user, name: 'Alpha') }

  before do
    allow(view).to receive(:current_user).and_return(user)
    assign(:projects, Kaminari.paginate_array([ project ]).page(1))
    allow(view).to receive(:present) do |object|
      instance_double('ProjectPresenter',
        display_name: object.name,
        stage_badge: '<span class="badge">Stage</span>'.html_safe,
        display_description: 'Desc',
        milestones_summary: '0/0')
    end
  end

  it 'renders My Projects header and project card' do
    render
    expect(rendered).to include('My Projects')
    expect(rendered).to include('Alpha')
  end
end
