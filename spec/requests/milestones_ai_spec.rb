require 'rails_helper'

RSpec.describe 'Milestones AI endpoints', type: :request do
  let(:owner) { create(:user) }
  let(:project) { create(:project, user: owner) }
  let!(:milestone) { create(:milestone, project: project, description: 'Base desc') }

  before { sign_in owner }

  it 'ai_enhance returns alert when both title and description blank' do
    post ai_enhance_project_milestones_path(project), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    expect(response.body).to include('Please provide a title or description')
  end

  it 'ai_enhance (existing milestone) enqueues job and returns turbo updates' do
    allow(MilestoneEnhancementJob).to receive(:perform_later)
    post ai_enhance_project_milestones_path(project), params: { title: 'Improve', milestone_id: milestone.id }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    expect(response.body).to include('AI enhancement started')
    expect(response.body).to include('ai-suggestion-container')
  end

  it 'ai_enhance (direct) uses service and returns turbo updates' do
    fake_service = double(augment_description: 'Enhanced text...')
    allow(MilestoneAiEnhancementService).to receive(:new).and_return(fake_service)

    post ai_enhance_project_milestones_path(project), params: { title: 'Improve', description: 'Base' }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    expect(response.body).to include('AI enhancement completed')
    expect(response.body).to include('ai-suggestion-container')
  end

  it 'apply_ai_enhancement updates milestone description on success' do
    enh = MilestoneEnhancement.create!(milestone: milestone, user: owner, original_description: 'Base', enhanced_description: 'New desc', enhancement_style: 'professional', status: 'completed')
    post apply_ai_enhancement_project_milestones_path(project), params: { enhancement_id: enh.id }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:success)
    expect(response.body).to include('Enhancement applied successfully')
  end

  it 'revert_ai_enhancement restores original description' do
    enh = MilestoneEnhancement.create!(milestone: milestone, user: owner, original_description: 'Orig', enhanced_description: 'New desc', enhancement_style: 'professional', status: 'completed')
    post revert_ai_enhancement_project_milestones_path(project), params: { enhancement_id: enh.id }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:success)
    expect(response.body).to include('Reverted to original description')
  end

  it 'discard_ai_enhancement clears suggestion container' do
    post discard_ai_enhancement_project_milestones_path(project), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:success)
    expect(response.body).to include('ai-suggestion-container')
  end

  it 'enhancement_status returns JSON with enhancement payload' do
    enh = MilestoneEnhancement.create!(milestone: milestone, user: owner, original_description: 'Base', enhancement_style: 'professional', status: 'processing')
    get enhancement_status_project_milestone_path(project, milestone), as: :json
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to have_key('enhancement')
  end

  it 'enhancement_display renders turbo update' do
    MilestoneEnhancement.create!(milestone: milestone, user: owner, original_description: 'Base', enhancement_style: 'professional', status: 'processing')
    get enhancement_display_project_milestone_path(project, milestone), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    expect(response.body).to include('ai-suggestion-container')
  end
end
