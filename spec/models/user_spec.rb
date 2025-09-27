require 'rails_helper'

# User Model Testing - Following patterns from technical_spec/test_spec/ruby_testing/README.md:42-349
# Reference: Comprehensive Model Testing section for association, validation, and business logic patterns

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  # Association Testing - Line 49-58 in test_spec
  describe "associations" do
    it { should have_many(:projects).dependent(:destroy) }
    it { should have_many(:agreement_participants).dependent(:delete_all) }
    it { should have_many(:initiated_agreements).through(:agreement_participants).source(:agreement) }
    it { should have_many(:received_agreements).through(:agreement_participants).source(:agreement) }
    it { should have_many(:time_logs) }
    it { should belong_to(:selected_project).class_name('Project').optional }
    it { should have_one_attached(:avatar) }
  end

  # Validation Testing with Context - Line 60-102 in test_spec
  describe "validations" do
    subject { create(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:password) }
    # Devise handles password validation

    it { should validate_length_of(:github_token).is_at_most(255) }
    it { should allow_value("").for(:github_username) }
    it { should allow_value("valid-username").for(:github_username) }
    it { should allow_value("valid123").for(:github_username) }
    it { should_not allow_value("invalid username").for(:github_username) }
  end

  # Business Logic Testing - Line 129-148 in test_spec
  describe "instance methods" do
    describe "#full_name" do
      it "returns concatenated first and last name" do
        user = build(:user, first_name: "John", last_name: "Doe")
        expect(user.full_name).to eq("John Doe")
      end
    end

    describe "#avatar_url" do
      it "returns avatar URL from AvatarService" do
        user = create(:user, email: "test@example.com")
        expect(user.avatar_url).to be_present
        # AvatarService handles the actual URL generation
      end
    end

    describe "#initials" do
      it "returns initials from AvatarService" do
        user = build(:user, first_name: "John", last_name: "Doe")
        expect(user.initials).to be_present
      end
    end

    describe "#accessible_projects" do
      it "returns projects user has access to" do
        project = create(:project, user: user)
        expect(user.accessible_projects).to include(project)
      end
    end
  end

  # Factory Integration Testing - Line 507-549 in test_spec
  describe "factory integration" do
    it "creates valid user with factory" do
      user = create(:user)
      expect(user).to be_valid
      expect(user.email).to be_present
    end

    it "creates alice trait correctly" do
      alice = create(:user, :alice)
      expect(alice.first_name).to eq("Alice")
      expect(alice.email).to eq("alice.smith@example.com")
    end
  end
end
