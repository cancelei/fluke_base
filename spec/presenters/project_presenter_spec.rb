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
end
