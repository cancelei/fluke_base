# frozen_string_literal: true

# Shared examples for TurboBoost Commands
# These provide DRY test coverage for common command patterns

# Basic command structure shared example
RSpec.shared_examples "a turbo_boost command" do
  describe "command structure" do
    it "inherits from ApplicationCommand" do
      expect(described_class.superclass).to eq(ApplicationCommand)
    end

    it "has an execute method" do
      expect(described_class.instance_methods).to include(:execute)
    end
  end
end

# Command with flash message support
RSpec.shared_examples "a command with flash support" do
  it "includes Flashable concern" do
    expect(described_class.included_modules).to include(Flashable)
  end

  it "can display flash notices" do
    expect(described_class.instance_methods).to include(:flash_notice)
  end

  it "can display flash errors" do
    expect(described_class.instance_methods).to include(:flash_error)
  end
end

# Command with state management
RSpec.shared_examples "a command with state management" do
  it "includes StateManageable concern" do
    expect(described_class.included_modules).to include(StateManageable)
  end

  it "can manage page state" do
    expect(described_class.instance_methods).to include(:set_page_state)
    expect(described_class.instance_methods).to include(:get_page_state)
  end

  it "can manage server state" do
    expect(described_class.instance_methods).to include(:set_server_state)
    expect(described_class.instance_methods).to include(:get_server_state)
  end
end

# Command with frame updates
RSpec.shared_examples "a command with frame updates" do
  it "includes MultiFrameUpdatable concern" do
    expect(described_class.included_modules).to include(MultiFrameUpdatable)
  end

  it "can update frames" do
    expect(described_class.instance_methods).to include(:update_frame)
    expect(described_class.instance_methods).to include(:clear_frame)
  end
end

# Command that requires authentication
RSpec.shared_examples "a command requiring authentication" do |element_data:|
  context "when user is not authenticated" do
    let(:command) { build_command(described_class, user: nil, element_data: element_data) }

    it "raises an error or returns early" do
      expect { command.execute }.to raise_error(NoMethodError)
        .or not_change { command_streams(command).count }
    end
  end
end

# Command that requires project access
RSpec.shared_examples "a command requiring project access" do |element_data_proc:|
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:other_project) { create(:project, user: other_user) }

  context "when user doesn't have access to project" do
    let(:element_data) { element_data_proc.call(other_project) }
    let(:command) { build_command(described_class, user: user, element_data: element_data) }

    it "handles authorization error gracefully" do
      expect { command.execute }.to raise_error(ActiveRecord::RecordNotFound)
        .or satisfy { |_| command_streams(command).any? { |s| s[:locals]&.dig(:alert).present? } }
    end
  end
end

# Command that displays success message
RSpec.shared_examples "a command that shows success message" do |setup_proc:, message_pattern: nil|
  let(:user) { create(:user) }

  before { setup_proc&.call(self) }

  it "displays a success flash message" do
    command.execute
    flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }

    expect(flash_stream).to be_present

    if message_pattern && flash_stream[:locals]
      expect(flash_stream[:locals][:notice]).to match(message_pattern)
    end
  end
end

# Command that displays error message
RSpec.shared_examples "a command that shows error message" do |setup_proc:, message_pattern: nil|
  let(:user) { create(:user) }

  before { setup_proc&.call(self) }

  it "displays an error flash message" do
    command.execute
    flash_stream = command_streams(command).find { |s| s[:target] == "flash_messages" }

    expect(flash_stream).to be_present

    if message_pattern && flash_stream[:locals]
      expect(flash_stream[:locals][:alert]).to match(message_pattern)
    end
  end
end

# Command that updates specific frame
RSpec.shared_examples "a command that updates frame" do |frame_id, setup_proc: nil|
  let(:user) { create(:user) }

  before { setup_proc&.call(self) }

  it "updates the #{frame_id} frame" do
    command.execute
    expect_stream_action(command, :update, target: frame_id)
  end
end

# Command that clears a frame
RSpec.shared_examples "a command that clears frame" do |frame_id, setup_proc: nil|
  let(:user) { create(:user) }

  before { setup_proc&.call(self) }

  it "clears the #{frame_id} frame" do
    command.execute
    stream = command_streams(command).find do |s|
      s[:target] == frame_id && (s[:action] == :update || s.values.compact.size == 2)
    end
    expect(stream).to be_present
  end
end

# Milestone-specific shared examples
RSpec.shared_examples "a milestone command" do
  it_behaves_like "a turbo_boost command"
  it_behaves_like "a command with flash support"

  describe "milestone operations" do
    it "is in the Milestones namespace" do
      expect(described_class.name).to start_with("Milestones::")
    end
  end
end

# Time log-specific shared examples
RSpec.shared_examples "a time_log command" do
  it_behaves_like "a turbo_boost command"
  it_behaves_like "a command with flash support"
  it_behaves_like "a command with state management"
  it_behaves_like "a command with frame updates"

  describe "time log operations" do
    it "is in the TimeLogs namespace" do
      expect(described_class.name).to start_with("TimeLogs::")
    end
  end
end

# Message-specific shared examples
RSpec.shared_examples "a message command" do
  it_behaves_like "a turbo_boost command"

  describe "message operations" do
    it "is in the Messages namespace" do
      expect(described_class.name).to start_with("Messages::")
    end
  end
end
