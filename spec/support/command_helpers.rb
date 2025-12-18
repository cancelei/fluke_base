# frozen_string_literal: true

# Support helpers for testing TurboBoost Commands
# Provides mock infrastructure and assertion helpers
module CommandHelpers
  extend ActiveSupport::Concern

  # Mock class for simulating TurboBoost command element
  # Mimics TurboBoost::Commands::AttributeSet structure
  class MockElement
    attr_reader :data

    def initialize(data = {})
      @data = MockAttributeSet.new(data)
    end

    # Legacy alias for backwards compatibility
    def dataset
      @data
    end
  end

  # Mock class for element.data access
  # Mimics TurboBoost::Commands::AttributeSet behavior
  # Stores data-foo-bar as foo_bar method
  class MockAttributeSet
    def initialize(data = {})
      @data = data.transform_keys { |k| k.to_s.underscore }
    end

    # Hash-style access (for backwards compatibility with tests)
    def [](key)
      @data[key.to_s.underscore]
    end

    # Method-based access (matches actual TurboBoost gem)
    def method_missing(method_name, *args)
      key = method_name.to_s.delete_suffix("?")
      if method_name.to_s.end_with?("?")
        @data[key].present?
      else
        @data[key]
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      key = method_name.to_s.delete_suffix("?")
      @data.key?(key) || super
    end

    def public_send(method_name, *args)
      method_missing(method_name, *args)
    end
  end

  # Mock class for turbo_stream helper
  class MockTurboStreamBuilder
    attr_reader :streams

    def initialize
      @streams = []
    end

    def update(target, options_or_content = {})
      stream = build_stream(:update, target, options_or_content)
      @streams << stream
      stream
    end

    def replace(target, options_or_content = {})
      stream = build_stream(:replace, target, options_or_content)
      @streams << stream
      stream
    end

    def append(target, options_or_content = {})
      stream = build_stream(:append, target, options_or_content)
      @streams << stream
      stream
    end

    def prepend(target, options_or_content = {})
      stream = build_stream(:prepend, target, options_or_content)
      @streams << stream
      stream
    end

    def remove(target)
      stream = { action: :remove, target: target }
      @streams << stream
      stream
    end

    private

    def build_stream(action, target, options_or_content)
      if options_or_content.is_a?(Hash)
        { action: action, target: target }.merge(options_or_content)
      else
        { action: action, target: target, content: options_or_content }
      end
    end
  end

  # Mock controller for command testing
  class MockController
    attr_accessor :session, :current_user, :params, :view_context

    def initialize(user: nil, session: {}, params: {})
      @current_user = user
      @session = session.with_indifferent_access
      @params = ActionController::Parameters.new(params)
      @view_context = MockViewContext.new
    end
  end

  # Mock view context for rendering
  class MockViewContext
    def render(component_or_options)
      if component_or_options.is_a?(Hash)
        "<rendered partial='#{component_or_options[:partial]}' />"
      else
        "<rendered component='#{component_or_options.class.name}' />"
      end
    end
  end

  # Mock state object for TurboBoost state management
  class MockState
    attr_accessor :page, :client, :server

    def initialize
      @page = {}.with_indifferent_access
      @client = {}.with_indifferent_access
      @server = {}.with_indifferent_access
    end

    def [](key)
      @page[key]
    end

    def []=(key, value)
      @page[key] = value
    end
  end

  included do
    # Build a command instance with mock infrastructure
    # @param command_class [Class] The command class to instantiate
    # @param user [User] The current user
    # @param element_data [Hash] Data attributes for the element
    # @param params [Hash] Request parameters
    # @param session [Hash] Session data
    # @return [Object] Command instance with mocked dependencies
    def build_command(command_class, user:, element_data: {}, params: {}, session: {})
      command = command_class.allocate

      # Set up mock infrastructure
      mock_controller = MockController.new(user: user, session: session, params: params)
      mock_element = MockElement.new(element_data)
      mock_turbo_stream = MockTurboStreamBuilder.new
      mock_state = MockState.new

      # Inject mocks into command
      command.instance_variable_set(:@controller, mock_controller)
      command.instance_variable_set(:@element, mock_element)
      command.instance_variable_set(:@turbo_stream_builder, mock_turbo_stream)
      command.instance_variable_set(:@turbo_streams, [])
      command.instance_variable_set(:@state, mock_state)

      # Define accessor methods
      command.define_singleton_method(:controller) { @controller }
      command.define_singleton_method(:element) { @element }
      command.define_singleton_method(:turbo_stream) { @turbo_stream_builder }
      command.define_singleton_method(:turbo_streams) { @turbo_streams }
      command.define_singleton_method(:state) { @state }
      command.define_singleton_method(:params) { @controller.params }

      command
    end

    # Get all turbo streams generated by a command
    def command_streams(command)
      command.turbo_streams
    end

    # Check if command generated a specific stream action
    def expect_stream_action(command, action, target:)
      streams = command_streams(command)
      matching = streams.find { |s| s[:action] == action && s[:target] == target }
      expect(matching).to be_present,
        "Expected #{action} stream for target '#{target}', but got: #{streams.map { |s| "#{s[:action]}(#{s[:target]})" }.join(', ')}"
    end

    # Check if command generated a flash notice
    def expect_flash_notice(command)
      expect_stream_action(command, :update, target: "flash_messages")
      stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
      expect(stream[:locals][:notice]).to be_present if stream[:locals]
    end

    # Check if command generated a flash error
    def expect_flash_error(command)
      expect_stream_action(command, :update, target: "flash_messages")
      stream = command_streams(command).find { |s| s[:target] == "flash_messages" }
      expect(stream[:locals][:alert]).to be_present if stream[:locals]
    end

    # Check page state was set
    def expect_page_state(command, key, value = nil)
      state_value = command.state.page[key.to_s]
      if value.nil?
        expect(state_value).to be_present
      else
        expect(state_value).to eq(value)
      end
    end

    # Check server state (session) was set
    def expect_server_state(command, key, value = nil)
      state_value = command.controller.session[key]
      if value.nil?
        expect(state_value).to be_present
      else
        expect(state_value).to eq(value)
      end
    end
  end
end

RSpec.configure do |config|
  config.include CommandHelpers, type: :command
end
