# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavbarComponent, type: :component do
  # NavbarComponent delegates to the partial which requires a full request context
  # These tests verify the component interface only

  describe "initialization" do
    it "can be initialized without current_user" do
      component = described_class.new

      expect(component).to be_a(described_class)
    end

    it "can be initialized with current_user" do
      user = build_stubbed(:user)
      component = described_class.new(current_user: user)

      expect(component).to be_a(described_class)
    end
  end

  describe "interface" do
    it "inherits from ApplicationComponent" do
      expect(described_class.superclass).to eq(ApplicationComponent)
    end

    it "responds to call method" do
      component = described_class.new

      expect(component).to respond_to(:call)
    end
  end
end
