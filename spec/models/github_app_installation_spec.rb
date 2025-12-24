# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubAppInstallation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:github_app_installation) }

    it { is_expected.to validate_presence_of(:installation_id) }

    it "validates uniqueness of installation_id" do
      create(:github_app_installation, installation_id: "12345")
      duplicate = build(:github_app_installation, installation_id: "12345")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:installation_id]).to include("has already been taken")
    end
  end

  describe "#accessible_repos" do
    context "with selected repositories" do
      let(:installation) { create(:github_app_installation, :multiple_repos) }

      it "returns the list of repository full names" do
        expect(installation.accessible_repos).to contain_exactly(
          { "id" => 123, "full_name" => "testuser/repo1", "private" => false },
          { "id" => 456, "full_name" => "testuser/repo2", "private" => true },
          { "id" => 789, "full_name" => "testuser/repo3", "private" => false }
        )
      end
    end

    context "with no repositories" do
      let(:installation) { create(:github_app_installation, :all_repos) }

      it "returns an empty array" do
        expect(installation.accessible_repos).to eq([])
      end
    end
  end

  describe "#has_access_to?" do
    context "with 'all' repository selection" do
      let(:installation) { create(:github_app_installation, :all_repos) }

      it "returns true for any repository" do
        expect(installation.has_access_to?("any/repo")).to be true
        expect(installation.has_access_to?("another/repo")).to be true
      end
    end

    context "with 'selected' repository selection" do
      let(:installation) { create(:github_app_installation, :multiple_repos) }

      it "returns true for accessible repositories" do
        expect(installation.has_access_to?("testuser/repo1")).to be true
        expect(installation.has_access_to?("testuser/repo2")).to be true
      end

      it "returns false for inaccessible repositories" do
        expect(installation.has_access_to?("testuser/unknown")).to be false
        expect(installation.has_access_to?("other/repo")).to be false
      end
    end
  end

  describe "#all_repos_access?" do
    it "returns true when selection is 'all'" do
      installation = create(:github_app_installation, :all_repos)
      expect(installation.all_repos_access?).to be true
    end

    it "returns false when selection is 'selected'" do
      installation = create(:github_app_installation)
      expect(installation.all_repos_access?).to be false
    end
  end
end
