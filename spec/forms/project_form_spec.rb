require 'rails_helper'

RSpec.describe ProjectForm, type: :model do
  let(:user) { create(:user) }

  describe '#save' do
    it 'applies default public fields when none selected' do
      form = described_class.new(name: 'New Project', description: 'Something great', user_id: user.id)

      expect(form.save).to be true
      expect(form.project.public_fields).to match_array(Project::DEFAULT_PUBLIC_FIELDS)
    end

    it 'preserves provided public field selections' do
      form = described_class.new(
        name: 'Selective Project',
        description: 'Focused visibility',
        stage: Project::PROTOTYPE,
        public_fields: [ 'name', 'team_size' ],
        user_id: user.id
      )

      expect(form.save).to be true
      expect(form.project.public_fields).to match_array([ 'name', 'team_size' ])
    end
  end

  describe 'stealth mode functionality' do
    it 'creates stealth project with smart defaults' do
      form = described_class.new(
        stealth_mode: true,
        user_id: user.id
      )

      expect(form.save).to be true
      project = form.project

      expect(project.stealth_mode).to be true
      expect(project.public_fields).to eq([])
      expect(project.name).to match(/Stealth Startup [A-F0-9]{4}/)
      expect(project.description).to eq("Early-stage venture in development. Details available after connection.")
      expect(project.category).to eq("Technology")
    end

    it 'allows custom stealth values when provided' do
      form = described_class.new(
        stealth_mode: true,
        name: 'Custom Project Name',
        description: 'Custom description',
        category: 'Health',
        stealth_name: 'Secret Health App',
        stealth_description: 'Revolutionary health platform',
        stealth_category: 'Health',
        user_id: user.id
      )

      expect(form.save).to be true
      project = form.project

      expect(project.stealth_mode).to be true
      expect(project.name).to eq('Custom Project Name')
      expect(project.description).to eq('Custom description')
      expect(project.category).to eq('Health')
      expect(project.stealth_name).to eq('Secret Health App')
      expect(project.stealth_description).to eq('Revolutionary health platform')
      expect(project.stealth_category).to eq('Health')
    end

    it 'does not apply stealth defaults for non-stealth projects' do
      form = described_class.new(
        name: 'Public Project',
        description: 'Public description',
        stealth_mode: false,
        user_id: user.id
      )

      expect(form.save).to be true
      project = form.project

      expect(project.stealth_mode).to be false
      expect(project.public_fields).to eq(Project::DEFAULT_PUBLIC_FIELDS)
      expect(project.name).to eq('Public Project')
      expect(project.description).to eq('Public description')
    end
  end
end
