# frozen_string_literal: true

# == Schema Information
#
# Table name: project_memories
#
#  id          :bigint           not null, primary key
#  content     :text             not null
#  key         :string
#  memory_type :string           default("fact"), not null
#  rationale   :text
#  references  :jsonb
#  synced_at   :datetime
#  tags        :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  external_id :string
#  project_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_project_memories_on_external_id                 (external_id) UNIQUE WHERE (external_id IS NOT NULL)
#  index_project_memories_on_project_id                  (project_id)
#  index_project_memories_on_project_id_and_key          (project_id,key) UNIQUE WHERE (key IS NOT NULL)
#  index_project_memories_on_project_id_and_memory_type  (project_id,memory_type)
#  index_project_memories_on_user_id                     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe ProjectMemory, type: :model do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }

  describe "associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:memory_type) }
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_inclusion_of(:memory_type).in_array(ProjectMemory::TYPES) }
  end

  describe "memory types" do
    it "defines all expected types" do
      expect(ProjectMemory::FACT).to eq("fact")
      expect(ProjectMemory::CONVENTION).to eq("convention")
      expect(ProjectMemory::GOTCHA).to eq("gotcha")
      expect(ProjectMemory::DECISION).to eq("decision")
      expect(ProjectMemory::TYPES).to eq(%w[fact convention gotcha decision])
    end
  end

  describe "scopes" do
    let!(:fact) { create(:project_memory, project: project, user: user, memory_type: "fact") }
    let!(:convention) { create(:project_memory, project: project, user: user, memory_type: "convention") }
    let!(:gotcha) { create(:project_memory, project: project, user: user, memory_type: "gotcha") }
    let!(:decision) { create(:project_memory, project: project, user: user, memory_type: "decision") }

    describe ".facts" do
      it "returns only facts" do
        expect(ProjectMemory.facts).to contain_exactly(fact)
      end
    end

    describe ".conventions" do
      it "returns only conventions" do
        expect(ProjectMemory.conventions).to contain_exactly(convention)
      end
    end

    describe ".gotchas" do
      it "returns only gotchas" do
        expect(ProjectMemory.gotchas).to contain_exactly(gotcha)
      end
    end

    describe ".decisions" do
      it "returns only decisions" do
        expect(ProjectMemory.decisions).to contain_exactly(decision)
      end
    end
  end

  describe "sync scopes" do
    let!(:synced) do
      create(:project_memory, project: project, user: user, synced_at: Time.current)
    end
    let!(:unsynced) do
      create(:project_memory, project: project, user: user, synced_at: nil)
    end

    describe ".synced" do
      it "returns only synced memories" do
        expect(ProjectMemory.synced).to contain_exactly(synced)
      end
    end

    describe ".unsynced" do
      it "returns only unsynced memories" do
        expect(ProjectMemory.unsynced).to contain_exactly(unsynced)
      end
    end
  end

  describe ".with_tag" do
    let!(:memory_with_tag) do
      create(:project_memory, project: project, user: user, tags: ["ruby", "rails"])
    end
    let!(:memory_without_tag) do
      create(:project_memory, project: project, user: user, tags: ["python"])
    end

    it "returns memories with matching tag" do
      expect(ProjectMemory.with_tag("ruby")).to contain_exactly(memory_with_tag)
    end

    it "returns empty for non-matching tag" do
      expect(ProjectMemory.with_tag("java")).to be_empty
    end
  end

  describe ".search" do
    let!(:memory1) do
      create(:project_memory, project: project, user: user, content: "Use RSpec for testing")
    end
    let!(:memory2) do
      create(:project_memory, project: project, user: user, content: "Deploy to production")
    end

    it "finds memories matching content" do
      expect(ProjectMemory.search("RSpec")).to contain_exactly(memory1)
    end

    it "is case insensitive" do
      expect(ProjectMemory.search("rspec")).to contain_exactly(memory1)
    end
  end

  describe ".since" do
    let!(:old_memory) do
      create(:project_memory, project: project, user: user, updated_at: 2.days.ago)
    end
    let!(:new_memory) do
      create(:project_memory, project: project, user: user, updated_at: 1.hour.ago)
    end

    it "returns memories updated since given time" do
      expect(ProjectMemory.since(1.day.ago)).to contain_exactly(new_memory)
    end
  end

  describe "#mark_synced!" do
    let(:memory) { create(:project_memory, project: project, user: user, synced_at: nil) }

    it "sets synced_at to current time" do
      before_sync = Time.current
      memory.mark_synced!
      after_sync = Time.current
      expect(memory.synced_at).to be_between(before_sync, after_sync)
    end
  end

  describe "#to_api_hash" do
    let(:memory) do
      create(:project_memory,
             project: project,
             user: user,
             memory_type: "convention",
             content: "Use RuboCop",
             key: "linting",
             rationale: "Consistent code style",
             tags: ["ruby", "linting"],
             references: { "url" => "https://rubocop.org" },
             external_id: "ext-123")
    end

    it "returns all expected fields" do
      hash = memory.to_api_hash

      expect(hash[:id]).to eq(memory.id)
      expect(hash[:memory_type]).to eq("convention")
      expect(hash[:content]).to eq("Use RuboCop")
      expect(hash[:key]).to eq("linting")
      expect(hash[:rationale]).to eq("Consistent code style")
      expect(hash[:tags]).to eq(["ruby", "linting"])
      expect(hash[:references]).to eq({ "url" => "https://rubocop.org" })
      expect(hash[:external_id]).to eq("ext-123")
      expect(hash[:created_at]).to be_present
      expect(hash[:updated_at]).to be_present
    end
  end

  describe "key uniqueness for conventions" do
    let!(:existing) do
      create(:project_memory,
             project: project,
             user: user,
             memory_type: "convention",
             key: "testing")
    end

    it "allows duplicate keys in different projects" do
      other_project = create(:project, user: user)
      memory = build(:project_memory,
                     project: other_project,
                     user: user,
                     memory_type: "convention",
                     key: "testing")
      expect(memory).to be_valid
    end

    it "enforces unique keys within same project regardless of type" do
      # Database constraint enforces unique keys per project for all memory types
      memory = build(:project_memory,
                     project: project,
                     user: user,
                     memory_type: "fact",
                     key: "testing")
      expect(memory).not_to be_valid
      expect(memory.errors[:key]).to include("has already been taken")
    end
  end

  describe "external_id uniqueness" do
    let!(:existing) do
      create(:project_memory,
             project: project,
             user: user,
             external_id: "unique-ext-id")
    end

    it "enforces uniqueness at database level" do
      duplicate = build(:project_memory,
                        project: project,
                        user: user,
                        external_id: "unique-ext-id")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows multiple nil external_ids" do
      memory1 = create(:project_memory, project: project, user: user, external_id: nil)
      memory2 = build(:project_memory, project: project, user: user, external_id: nil)
      expect(memory2).to be_valid
    end
  end
end
