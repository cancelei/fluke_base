require 'rails_helper'

# Meeting Model Testing - Following patterns from technical_spec/test_spec/ruby_testing/README.md:42-349
# Reference: Comprehensive Model Testing section for association, validation, and business logic patterns

RSpec.describe Meeting, type: :model do
  let(:alice) { create(:user, :alice) }
  let(:bob) { create(:user, :bob) }
  let(:project) { create(:project, user: alice) }
  let(:agreement) { create(:agreement, :with_participants, :accepted, project: project, initiator: alice, other_party: bob) }
  let(:meeting) { create(:meeting, agreement: agreement) }

  # Association Testing - Line 49-58 in test_spec
  describe "associations" do
    it { should belong_to(:agreement) }
  end

  # Validation Testing with Context - Line 60-102 in test_spec
  describe "validations" do
    subject { create(:meeting) }

    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:start_time) }
    it { should validate_presence_of(:end_time) }
    # Agreement presence validation is tested by belongs_to matcher in associations section


    context "end time validation" do
      it "validates end time is after start time" do
        start_time = 1.hour.from_now
        meeting = build(:meeting, start_time: start_time, end_time: start_time - 30.minutes)
        expect(meeting).not_to be_valid
        expect(meeting.errors[:end_time]).to include("must be after the start time")
      end
    end
  end

  # Business Logic Testing - Line 129-148 in test_spec
  describe "instance methods" do
    describe "#duration_in_minutes" do
      it "returns duration in minutes" do
        start_time = 1.hour.from_now
        end_time = start_time + 90.minutes
        meeting = build(:meeting, start_time: start_time, end_time: end_time)

        expect(meeting.duration_in_minutes).to eq(90)
      end
    end
  end

  # Scope Testing - Line 104-126 in test_spec
  describe "scopes" do
    let!(:upcoming_meeting) { create(:meeting, start_time: 1.hour.from_now, end_time: 2.hours.from_now) }
    let!(:past_meeting) { create(:meeting, start_time: 2.hours.ago, end_time: 1.hour.ago) }

    describe ".upcoming" do
      it "returns future meetings" do
        upcoming_meetings = Meeting.upcoming.where(id: [ upcoming_meeting.id, past_meeting.id ])
        expect(upcoming_meetings).to include(upcoming_meeting)
        expect(upcoming_meetings).not_to include(past_meeting)
      end
    end

    describe ".past" do
      it "returns past meetings" do
        past_meetings = Meeting.past.where(id: [ upcoming_meeting.id, past_meeting.id ])
        expect(past_meetings).to include(past_meeting)
        expect(past_meetings).not_to include(upcoming_meeting)
      end
    end
  end

  # Factory Integration Testing - Line 507-549 in test_spec
  describe "factory integration" do
    it "creates valid meeting with factory" do
      meeting = create(:meeting)
      expect(meeting).to be_valid
      expect(meeting.title).to be_present
      expect(meeting.agreement).to be_present
      expect(meeting.start_time).to be_present
      expect(meeting.end_time).to be_present
    end
  end
end
