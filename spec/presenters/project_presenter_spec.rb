require 'rails_helper'

RSpec.describe ProjectPresenter do
  let(:owner) { create(:user) }
  let(:project) { create(:project, user: owner, stage: Project::IDEA, collaboration_type: Project::SEEKING_BOTH, public_fields: [ 'name' ]) }
  subject(:presenter) { described_class.new(project) }

  it 'displays name for owner and masks for strangers if not visible' do
    stranger = create(:user)
    expect(presenter.display_name(owner)).to eq(project.name)
    # Since name is in public_fields, it should be visible to strangers
    expect(presenter.display_name(stranger)).to eq(project.name)
  end

  it 'renders stage and collaboration badges' do
    expect(presenter.stage_badge).to include('Idea').or include('IDEA')
    expect(presenter.collaboration_badges).to include('Seeking Mentor').and include('Seeking Co-Founder')
  end

  it 'shows progress bar only when > 0' do
    allow(project).to receive(:progress_percentage).and_return(0)
    expect(presenter.progress_bar).to eq('')
    allow(project).to receive(:progress_percentage).and_return(60)
    expect(presenter.progress_bar).to include('width: 60%')
  end

  describe 'stealth mode functionality' do
    let(:stealth_project) do
      create(:project,
        user: owner,
        stealth_mode: true,
        stealth_name: 'Secret Project',
        stealth_description: 'Top secret innovation',
        public_fields: []
      )
    end
    let(:stealth_presenter) { described_class.new(stealth_project) }
    let(:stranger) { create(:user) }

    it 'displays stealth name for unauthorized users' do
      expect(stealth_presenter.display_name(owner)).to eq(stealth_project.name)
      expect(stealth_presenter.display_name(stranger)).to eq('Secret Project')
    end

    it 'displays stealth description for unauthorized users' do
      expect(stealth_presenter.display_description(owner)).to include(stealth_project.description)
      expect(stealth_presenter.display_description(stranger)).to include('Top secret innovation')
    end

    it 'shows stealth badge' do
      expect(stealth_presenter.stealth_badge).to include('🔒 Stealth')
    end

    it 'regular projects do not show stealth badge' do
      expect(presenter.stealth_badge).to eq('')
    end
  end
end
