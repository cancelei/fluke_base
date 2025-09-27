require 'rails_helper'

RSpec.describe 'People', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'GET /people/explore' do
    let!(:target_user) { create(:user, first_name: 'Sam', last_name: 'Mentor', bio: 'Experienced mentor') }

    it 'returns the explore directory and lists matching people' do
      get explore_people_path(search: 'mentor')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Discover Amazing People')
      expect(response.body).to include('Sam Mentor')
    end
  end

  describe 'GET /people/:id' do
    let(:person) { create(:user, first_name: 'Kai', last_name: 'Builder') }
    let!(:owned_project) do
      create(:project, user: person, name: 'Owned Project', description: 'Personal project', public_fields: [ 'name', 'description' ])
    end
    let!(:agreement_project) do
      create(:project, name: 'Agreement Project', description: 'Collaboration', public_fields: [ 'name', 'description' ])
    end

    before do
      create(:agreement, :with_participants,
             project: agreement_project,
             initiator: agreement_project.user,
             other_party: person,
             status: Agreement::ACCEPTED)
      user.update!(selected_project: create(:project, user: user))
    end

    it 'shows the person profile with their project involvement' do
      get person_path(person)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Kai Builder')
      expect(response.body).to include('Owned Project')
      expect(response.body).to include('Agreement Project')
      expect(response.body).to include('Initiate Agreement')
    end
  end
end
