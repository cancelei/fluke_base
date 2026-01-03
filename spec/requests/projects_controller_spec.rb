require 'rails_helper'

RSpec.describe 'Projects', type: :request do
  describe 'GET /projects/:id' do
    context 'when signed in as the project owner' do
      include_context 'with project'

      it 'renders the project and updates the selected project context' do
        expect {
          get project_path(project)
        }.to change { user.reload.selected_project_id }.from(nil).to(project.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(project.name)
      end
    end

    context 'when signed in as a collaborator' do
      let(:owner) { create(:user) }
      let(:project) { create(:project, user: owner, name: 'Collaborator Visible') }
      let(:collaborator) { create(:user) }

      before do
        create(:agreement, :with_participants,
               project:,
               initiator: owner,
               other_party: collaborator,
               status: Agreement::ACCEPTED)
        sign_in collaborator
      end

      it 'renders the project without changing collaborator selection' do
        expect {
          get project_path(project)
        }.not_to change { collaborator.reload.selected_project_id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Collaborator Visible')
      end
    end
  end
end
