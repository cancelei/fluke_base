require 'rails_helper'

RSpec.describe 'Stimulus Message Recorder Controller', type: :system, js: true do
  let(:user) { create(:user) }
  let(:partner) { create(:user) }
  let!(:conversation) { create(:conversation, sender: user, recipient: partner) }
  let!(:message) { create(:message, conversation: conversation, user: partner, body: 'Hello from partner') }

  before do
    sign_in user
    visit conversation_path(conversation)
    stub_media_recorder_support
  end

  it 'records, previews, plays back, and clears a voice message' do
    expect_stimulus_controller('message-recorder', '#message-form')

    record_button = find("[data-message-recorder-target='recordBtn']")

    record_button.click
    expect(page).to have_css("[data-message-recorder-target='recordingIndicator']:not(.hidden)", visible: :all, wait: 2)

    record_button.click
    expect(page).to have_css("[data-message-recorder-target='recordingReview']:not(.hidden)", visible: :all, wait: 5)
    expect(find("[data-message-recorder-target='sendBtn']").text).to eq('Send with Voice Message')
    expect(page).to have_css("[data-message-recorder-target='waveform'] div", minimum: 1, wait: 2)

    play_button = find("[data-message-recorder-target='playBtn']")
    play_button.click
    expect(page).to have_css("[data-message-recorder-target='pauseIcon']:not(.hidden)", visible: :all, wait: 2)

    play_button.click
    expect(page).to have_css("[data-message-recorder-target='pauseIcon'].hidden", visible: :all, wait: 2)
    expect(page).to have_css("[data-message-recorder-target='playIcon']:not(.hidden)", visible: :all)

    find("[data-message-recorder-target='clearRecordingBtn']").click
    expect(page).to have_css("[data-message-recorder-target='recordingReview'].hidden", visible: :all, wait: 2)
    expect(find("[data-message-recorder-target='sendBtn']").text).to eq('Send')
  end

  def stub_media_recorder_support
    page.execute_script(<<~JS)
      window.HTMLMediaElement.prototype.play = function() { return Promise.resolve(); };
      window.HTMLMediaElement.prototype.pause = function() { return true; };

      class FakeStream {
        getTracks() { return [{ stop() {} }]; }
      }

      navigator.mediaDevices = {
        getUserMedia: () => Promise.resolve(new FakeStream())
      };

      window.MediaRecorder = class {
        constructor(stream) {
          this.stream = stream;
          this.state = 'inactive';
          this.ondataavailable = null;
          this.onstop = null;
        }

        start() {
          this.state = 'recording';
        }

        stop() {
          this.state = 'inactive';
          if (this.ondataavailable) {
            this.ondataavailable({ data: new Blob(['voice'], { type: 'audio/webm' }) });
          }
          if (this.onstop) { this.onstop(); }
        }
      };
    JS
  end
end
