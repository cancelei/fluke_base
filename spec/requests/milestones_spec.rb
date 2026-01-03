require 'rails_helper'

RSpec.describe "Milestones", type: :request do
  let(:owner) { create(:user) }
  let(:project) { create(:project, user: owner) }

  before { sign_in owner }

  it "GET /projects/:project_id/milestones#index responds ok" do
    get project_milestones_path(project)
    expect(response).to have_http_status(:ok)
  end

  it "POST /projects/:project_id/milestones#create creates milestone" do
    post project_milestones_path(project), params: { milestone: { title: 'Plan', due_date: Date.today + 7, status: Milestone::PENDING } }
    expect(response).to redirect_to(project_path(project))
    expect(project.milestones.reload.count).to be >= 1
  end

  it "PATCH /projects/:project_id/milestones/:id#update renders edit with 422 when invalid" do
    ms = project.milestones.create!(title: 'T', due_date: Date.today + 1, status: Milestone::PENDING)
    patch project_milestone_path(project, ms), params: { milestone: { title: '' } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Edit Milestone').or include('error').or include('can\'t be blank')
  end

  it "POST /projects/:project_id/milestones/:id#confirm (HTML) redirects with notice" do
    ms = project.milestones.create!(title: 'T', due_date: Date.today + 1, status: Milestone::IN_PROGRESS)
    post confirm_project_milestone_path(project, ms)
    expect(response).to redirect_to(project_path(project))
  end
end
