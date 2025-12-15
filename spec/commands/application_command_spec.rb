# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCommand, type: :command do
  describe "class hierarchy" do
    it "inherits from TurboBoost::Commands::Command" do
      expect(described_class.superclass).to eq(TurboBoost::Commands::Command)
    end
  end

  describe "included concerns" do
    it_behaves_like "a command with flash support"
    it_behaves_like "a command with state management"
    it_behaves_like "a command with frame updates"
  end

  describe "protected methods" do
    it "defines current_user accessor" do
      expect(described_class.protected_instance_methods).to include(:current_user)
    end

    it "defines find_project helper" do
      expect(described_class.protected_instance_methods).to include(:find_project)
    end

    it "defines find_milestone helper" do
      expect(described_class.protected_instance_methods).to include(:find_milestone)
    end

    it "defines handle_error helper" do
      expect(described_class.protected_instance_methods).to include(:handle_error)
    end

    it "defines handle_success helper" do
      expect(described_class.protected_instance_methods).to include(:handle_success)
    end

    it "defines element_data helper" do
      expect(described_class.protected_instance_methods).to include(:element_data)
    end

    it "defines element_id helper" do
      expect(described_class.protected_instance_methods).to include(:element_id)
    end
  end
end
