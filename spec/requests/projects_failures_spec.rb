require 'rails_helper'

RSpec.describe 'Projects controller failures', type: :request do
  let(:user) { create(:user) }

  before do
    post user_session_path, params: { user: { email: user.email, password: user.password } }
  end

  it 'POST /projects renders :new with 422 when invalid' do
    post projects_path, params: { project: { name: '', description: '', stage: '' } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('New Project').or include('error').or include('can\'t be blank')
  end

  it 'PATCH /projects/:id renders :edit with 422 when invalid' do
    project = create(:project, user:)
    patch project_path(project), params: { project: { name: '' } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Edit Project').or include('error').or include('can\'t be blank')
  end
end
