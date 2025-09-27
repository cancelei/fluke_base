require 'rails_helper'

RSpec.describe PeopleSearchQuery do
  let(:current_user) { create(:user, first_name: 'Casey', last_name: 'Owner', bio: 'Main account') }
  let!(:other_user) { create(:user, first_name: 'Bianca', last_name: 'Builder', bio: 'Builds rockets') }
  let!(:another_user) { create(:user, first_name: 'Lex', last_name: 'Mentor', bio: 'Mentors builders') }
  let!(:project) { create(:project, user: other_user) }

  def run_query(params = {})
    described_class.new(current_user, params).results.to_a
  end

  it 'includes the current user by default' do
    results = run_query

    expect(results).to include(current_user, other_user, another_user)
  end

  it 'filters by search term across name and bio fields' do
    results = run_query(search: 'rocket')

    expect(results).to include(other_user)
    expect(results).not_to include(another_user)
  end

  it 'filters by project ownership' do
    results = run_query(project_id: project.id)

    expect(results).to eq([ other_user ])
  end
end
