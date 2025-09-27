require 'rails_helper'

RSpec.describe MilestoneAiEnhancementService do
  let(:project) { create(:project, name: 'Atlas', stage: Project::PROTOTYPE) }
  let(:chat_client) { instance_double('RubyLLM::Chat', ask: response_double) }
  let(:response_double) { instance_double('RubyLLM::Response', content: " Enhanced milestone \n") }

  around do |example|
    original = ENV['OPENAI_API_KEY']
    ENV['OPENAI_API_KEY'] = 'test-key'
    example.run
  ensure
    ENV['OPENAI_API_KEY'] = original
  end

  before do
    allow(RubyLLM).to receive(:chat).and_return(chat_client)
  end

  describe '#augment_description' do
    it 'returns the trimmed enhanced description from the LLM client' do
      service = described_class.new(project)

      result = service.augment_description(title: 'Initial setup', description: 'Create scaffolding')

      expect(result).to eq('Enhanced milestone')
      expect(RubyLLM).to have_received(:chat).with(model: project.project_agent.model)
      expect(chat_client).to have_received(:ask).with(include('Initial setup'))
    end

    it 'raises when the provider is unsupported' do
      project.create_project_agent!(provider: 'anthropic', model: 'claude-3-sonnet')
      service = described_class.new(project)

      expect {
        service.augment_description(title: 'Title', description: 'Desc')
      }.to raise_error('Unsupported AI provider: anthropic')
    end

    it 'raises when the LLM returns a blank response' do
      allow(chat_client).to receive(:ask).and_return(instance_double('RubyLLM::Response', content: '   '))
      service = described_class.new(project)

      expect {
        service.augment_description(title: 'Title', description: 'Desc')
      }.to raise_error(RuntimeError, 'AI service returned empty response')
    end

    it 'raises when the API key is missing' do
      original = ENV.delete('OPENAI_API_KEY')

      expect { described_class.new(project) }.to raise_error('OpenAI API key is not configured')
    ensure
      ENV['OPENAI_API_KEY'] = original
    end

    it 'returns empty string when both title and description are blank' do
      service = described_class.new(project)

      expect(service.augment_description(title: '', description: '')).to eq('')
    end
  end
end
