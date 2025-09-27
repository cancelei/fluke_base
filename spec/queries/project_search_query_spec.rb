require 'rails_helper'

RSpec.describe ProjectSearchQuery do
  let(:user) { create(:user) }
  let!(:mentor_project) do
    create(:project,
           user: user,
           name: 'Mentor Match',
           description: 'Find mentors for deep tech',
           collaboration_type: Project::SEEKING_MENTOR,
           category: 'education')
  end
  let!(:cofounder_project) do
    create(:project,
           user: user,
           name: 'CoFounder Hub',
           description: 'Matching cofounders for ideas',
           collaboration_type: Project::SEEKING_COFOUNDER,
           category: 'community')
  end
  let!(:general_project) do
    create(:project,
           user: user,
           name: 'General Tools',
           description: 'Productivity suite for teams',
           collaboration_type: Project::SEEKING_BOTH,
           category: 'productivity')
  end

  def run_query(params = {})
    described_class.new(user, params).results.to_a
  end

  it 'orders projects by most recent first by default' do
    projects = run_query

    expect(projects.first.created_at).to be >= projects.last.created_at
  end

  it 'filters by collaboration type mentor' do
    results = run_query(collaboration_type: Project::SEEKING_MENTOR)

    expect(results).to include(mentor_project)
    expect(results).to include(general_project) # SEEKING_BOTH includes mentor seeking
    expect(results).not_to include(cofounder_project)
  end

  it 'filters by collaboration type co-founder' do
    results = run_query(collaboration_type: Project::SEEKING_COFOUNDER)

    expect(results).to include(cofounder_project)
    expect(results).to include(general_project) # SEEKING_BOTH includes co-founder seeking
    expect(results).not_to include(mentor_project)
  end

  it 'filters by category' do
    results = run_query(category: 'productivity')

    expect(results).to eq([ general_project ])
  end

  it 'filters by search term across name and description' do
    results = run_query(search: 'cofounders')

    expect(results).to eq([ cofounder_project ])
  end
end
