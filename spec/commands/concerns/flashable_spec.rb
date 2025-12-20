# frozen_string_literal: true

require "rails_helper"

RSpec.describe Flashable, type: :concern do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include Flashable

      attr_accessor :turbo_streams

      def initialize
        @turbo_streams = []
      end

      def turbo_stream
        # Mock turbo_stream helper
        @turbo_stream_helper ||= MockTurboStreamHelper.new
      end

      def controller
        @controller ||= MockController.new
      end
    end
  end

  # Mock helpers
  before do
    stub_const("MockTurboStreamHelper", Class.new do
      def update(target, options = {})
        { action: :update, target:, **options }
      end

      def append(target, content)
        { action: :append, target:, content: }
      end
    end)

    stub_const("MockController", Class.new do
      def view_context
        MockViewContext.new
      end
    end)

    stub_const("MockViewContext", Class.new do
      def render(component)
        "<rendered_component />"
      end
    end)
  end

  describe "#flash_notice" do
    it "adds an update stream for flash_messages" do
      instance = test_class.new
      instance.flash_notice("Success!")

      expect(instance.turbo_streams.size).to eq(1)
      stream = instance.turbo_streams.first
      expect(stream[:target]).to eq("flash_messages")
      expect(stream[:action]).to eq(:update)
    end
  end

  describe "#flash_error" do
    it "adds an update stream for flash_messages" do
      instance = test_class.new
      instance.flash_error("Error!")

      expect(instance.turbo_streams.size).to eq(1)
      stream = instance.turbo_streams.first
      expect(stream[:target]).to eq("flash_messages")
      expect(stream[:action]).to eq(:update)
    end
  end

  describe "FLASH_CONTAINER_ID constant" do
    it "is set to flash_messages" do
      expect(Flashable::FLASH_CONTAINER_ID).to eq("flash_messages")
    end
  end
end
