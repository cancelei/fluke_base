require 'rails_helper'

RSpec.describe MilestoneEnhancement, type: :model do
  let(:milestone) { create(:milestone) }
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:milestone) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    subject { build(:milestone_enhancement, milestone: milestone, user: user) }

    it { should validate_presence_of(:original_description) }
    it { should validate_presence_of(:enhanced_description) }
    it { should validate_presence_of(:enhancement_style) }

    it { should validate_inclusion_of(:enhancement_style).in_array(%w[professional technical creative detailed concise]) }
    it { should validate_inclusion_of(:status).in_array(%w[pending processing completed failed]) }
  end

  describe 'scopes' do
    let!(:recent_enhancement) { create(:milestone_enhancement, milestone: milestone, user: user, created_at: 1.hour.ago) }
    let!(:older_enhancement) { create(:milestone_enhancement, milestone: milestone, user: user, created_at: 1.day.ago) }
    let!(:successful_enhancement) { create(:milestone_enhancement, milestone: milestone, user: user, status: 'completed') }
    let!(:failed_enhancement) { create(:milestone_enhancement, :failed, milestone: milestone, user: user) }

    describe '.recent' do
      it 'orders by created_at desc' do
        enhancements = MilestoneEnhancement.recent.to_a
        expect(enhancements.first.created_at).to be >= enhancements.last.created_at
        expect(enhancements.size).to eq(4)
      end
    end

    describe '.successful' do
      it 'returns only completed enhancements' do
        successful_enhancements = MilestoneEnhancement.successful
        expect(successful_enhancements.pluck(:status).uniq).to eq([ 'completed' ])
        expect(successful_enhancements.count).to be >= 1
      end
    end

    describe '.for_milestone' do
      let(:other_milestone) { create(:milestone) }
      let!(:other_enhancement) { create(:milestone_enhancement, milestone: other_milestone, user: user) }

      it 'returns enhancements for specific milestone' do
        expect(MilestoneEnhancement.for_milestone(milestone)).to contain_exactly(
          recent_enhancement, older_enhancement, successful_enhancement, failed_enhancement
        )
      end
    end
  end

  describe 'status methods' do
    it 'correctly identifies status' do
      enhancement = build(:milestone_enhancement, status: 'completed')
      expect(enhancement.successful?).to be true
      expect(enhancement.failed?).to be false
      expect(enhancement.processing?).to be false
      expect(enhancement.pending?).to be false

      enhancement.status = 'failed'
      expect(enhancement.successful?).to be false
      expect(enhancement.failed?).to be true
      expect(enhancement.processing?).to be false
      expect(enhancement.pending?).to be false

      enhancement.status = 'processing'
      expect(enhancement.successful?).to be false
      expect(enhancement.failed?).to be false
      expect(enhancement.processing?).to be true
      expect(enhancement.pending?).to be false

      enhancement.status = 'pending'
      expect(enhancement.successful?).to be false
      expect(enhancement.failed?).to be false
      expect(enhancement.processing?).to be false
      expect(enhancement.pending?).to be true
    end
  end

  describe '#processing_time_seconds' do
    it 'converts milliseconds to seconds' do
      enhancement = build(:milestone_enhancement, processing_time_ms: 2500)
      expect(enhancement.processing_time_seconds).to eq(2.5)
    end

    it 'returns nil when processing_time_ms is nil' do
      enhancement = build(:milestone_enhancement, processing_time_ms: nil)
      expect(enhancement.processing_time_seconds).to be_nil
    end
  end

  describe 'defaults' do
    it 'sets default status to pending when not provided' do
      enhancement = MilestoneEnhancement.new(milestone: milestone, user: user, original_description: 'test')
      expect(enhancement.status).to eq('pending')
    end

    it 'sets default context_data to empty hash when not provided' do
      enhancement = MilestoneEnhancement.new(milestone: milestone, user: user, original_description: 'test')
      expect(enhancement.context_data).to eq({})
    end
  end

  describe 'factory validation' do
    it 'creates valid enhancement with factory' do
      enhancement = build(:milestone_enhancement, milestone: milestone, user: user)
      expect(enhancement).to be_valid
    end

    it 'creates valid enhancement with traits' do
      %i[pending processing failed technical_style creative_style detailed_style concise_style].each do |trait|
        enhancement = build(:milestone_enhancement, trait, milestone: milestone, user: user)
        expect(enhancement).to be_valid, "Enhancement with #{trait} trait should be valid"
      end
    end
  end
end
