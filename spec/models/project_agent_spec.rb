require 'rails_helper'

RSpec.describe ProjectAgent, type: :model do
  let(:project) { create(:project) }

  describe 'associations' do
    it { should belong_to(:project) }
  end

  describe 'validations' do
    subject { build(:project_agent, project: project) }

    it 'validates presence of provider' do
      # Test by setting provider to empty string (bypasses default callback)
      subject.provider = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:provider]).to include("can't be blank")
    end
    it 'validates presence of model' do
      # Test by setting model to empty string (bypasses default callback)
      subject.model = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:model]).to include("can't be blank")
    end
    it { should validate_inclusion_of(:provider).in_array(%w[openai anthropic]) }

    context 'when provider is openai' do
      subject { build(:project_agent, project: project, provider: 'openai') }

      it 'validates model is valid for OpenAI' do
        subject.model = 'gpt-4'
        expect(subject).to be_valid

        subject.model = 'invalid-model'
        expect(subject).not_to be_valid
        expect(subject.errors[:model]).to include('invalid-model is not a valid model for openai provider')
      end
    end

    context 'when provider is anthropic' do
      subject { build(:project_agent, project: project, provider: 'anthropic') }

      it 'validates model is valid for Anthropic' do
        subject.model = 'claude-3-sonnet'
        expect(subject).to be_valid

        subject.model = 'gpt-4'
        expect(subject).not_to be_valid
        expect(subject.errors[:model]).to include('gpt-4 is not a valid model for anthropic provider')
      end
    end
  end

  describe 'defaults' do
    it 'sets default provider to openai' do
      agent = ProjectAgent.new(project: project)
      agent.valid?
      expect(agent.provider).to eq('openai')
    end

    it 'sets default model based on provider' do
      agent = ProjectAgent.new(project: project, provider: 'openai')
      agent.valid?
      expect(agent.model).to eq('gpt-4')

      agent = ProjectAgent.new(project: project, provider: 'anthropic')
      agent.valid?
      expect(agent.model).to eq('claude-3-sonnet')
    end
  end

  describe 'methods' do
    let(:openai_agent) { create(:project_agent, project: project, provider: 'openai') }
    let(:anthropic_agent) { create(:project_agent, :anthropic, project: project) }

    describe '#openai?' do
      it 'returns true for OpenAI agents' do
        expect(openai_agent.openai?).to be true
        expect(anthropic_agent.openai?).to be false
      end
    end

    describe '#anthropic?' do
      it 'returns true for Anthropic agents' do
        expect(anthropic_agent.anthropic?).to be true
        expect(openai_agent.anthropic?).to be false
      end
    end

    describe '#available_models' do
      it 'returns correct models for each provider' do
        expect(openai_agent.available_models).to eq(ProjectAgent::OPENAI_MODELS)
        expect(anthropic_agent.available_models).to eq(ProjectAgent::ANTHROPIC_MODELS)
      end
    end
  end

  describe 'scopes' do
    before do
      create(:project_agent, project: project, provider: 'openai')
      create(:project_agent, :anthropic, project: create(:project))
    end

    it 'filters by provider' do
      expect(ProjectAgent.openai.count).to eq(1)
      expect(ProjectAgent.anthropic.count).to eq(1)
    end
  end
end
