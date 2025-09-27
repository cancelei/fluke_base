require 'rails_helper'

RSpec.describe 'Projects', type: :request do
  describe 'GET /projects/:id' do
    let(:owner) { create(:user) }
    let(:project) do
      create(:project,
             user: owner,
             name: 'Owner Project',
             description: 'Owner description',
             public_fields: [ 'name', 'description' ])
    end

    context 'when signed in as the project owner' do
      before do
        sign_in owner
      end

      it 'renders the project and updates the selected project context' do
        expect {
          get project_path(project)
        }.to change { owner.reload.selected_project_id }.from(nil).to(project.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Owner Project')
      end
    end

    context 'when signed in as a collaborator' do
      let(:collaborator) { create(:user) }

      before do
        create(:agreement, :with_participants,
               project: project,
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
        expect(response.body).to include('Owner Project')
      end
    end
  end
end
