require 'rails_helper'

RSpec.describe ProjectSelectionService do
  let(:user) { create(:user) }
  let(:session) { {} }

  describe '#call' do
    context 'when the project exists' do
      let(:project) { create(:project, user:) }

      it 'updates the user selection and persists the session' do
        service = described_class.new(user, session, project.id)

        result = service.call
        expect(result).to be_success
        expect(user.reload.selected_project_id).to eq(project.id)
        expect(session[:selected_project_id]).to eq(project.id)
      end
    end

    context 'when the project cannot be found' do
      it 'returns false without mutating the session or user' do
        service = described_class.new(user, session, -1)

        result = service.call
        expect(result).to be_failure
        expect(session).not_to include(:selected_project_id)
        expect(user.reload.selected_project_id).to be_nil
      end
    end
  end

  describe '#project' do
    it 'memoizes the project lookup' do
      project = create(:project, user:)
      service = described_class.new(user, session, project.id)

      expect(Project).to receive(:find_by).once.and_call_original
      2.times { service.project }
    end
  end
end
