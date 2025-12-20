# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ToastHelper, type: :helper do
  describe '#toast' do
    context 'with valid parameters' do
      it 'renders ToastComponent with success type' do
        result = helper.toast(:success, "Operation completed")
        expect(result).to be_present
      end

      it 'renders ToastComponent with error type' do
        result = helper.toast(:error, "Something failed")
        expect(result).to be_present
      end

      it 'renders ToastComponent with warning type' do
        result = helper.toast(:warning, "Be careful")
        expect(result).to be_present
      end

      it 'renders ToastComponent with info type' do
        result = helper.toast(:info, "FYI message")
        expect(result).to be_present
      end

      it 'renders ToastComponent with notice type (Rails flash)' do
        result = helper.toast(:notice, "Success notice")
        expect(result).to be_present
      end

      it 'renders ToastComponent with alert type (Rails flash)' do
        result = helper.toast(:alert, "Alert message")
        expect(result).to be_present
      end

      it 'passes title option to component' do
        expect(Ui::ToastComponent).to receive(:new).with(
          hash_including(title: "Custom Title")
        ).and_call_original
        helper.toast(:success, "Message", title: "Custom Title")
      end

      it 'passes custom timeout to component' do
        expect(Ui::ToastComponent).to receive(:new).with(
          hash_including(timeout: 10000)
        ).and_call_original
        helper.toast(:success, "Message", timeout: 10000)
      end

      it 'passes close_button false option to component' do
        expect(Ui::ToastComponent).to receive(:new).with(
          hash_including(close_button: false)
        ).and_call_original
        helper.toast(:success, "Message", close_button: false)
      end

      it 'passes position option to component' do
        expect(Ui::ToastComponent).to receive(:new).with(
          hash_including(position: "toast-bottom-left")
        ).and_call_original
        helper.toast(:success, "Message", position: "toast-bottom-left")
      end

      it 'uses default timeout of 5000' do
        expect(Ui::ToastComponent).to receive(:new).with(
          hash_including(timeout: 5000)
        ).and_call_original
        helper.toast(:success, "Message")
      end

      it 'uses default position of toast-top-right' do
        expect(Ui::ToastComponent).to receive(:new).with(
          hash_including(position: "toast-top-right")
        ).and_call_original
        helper.toast(:success, "Message")
      end

      it 'uses default close_button of true' do
        expect(Ui::ToastComponent).to receive(:new).with(
          hash_including(close_button: true)
        ).and_call_original
        helper.toast(:success, "Message")
      end

      it 'handles string type parameter' do
        result = helper.toast("success", "Message with string type")
        expect(result).to be_present
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError when message is nil' do
        expect { helper.toast(:success, nil) }.to raise_error(ArgumentError, "Message cannot be blank")
      end

      it 'raises ArgumentError when message is empty string' do
        expect { helper.toast(:success, "") }.to raise_error(ArgumentError, "Message cannot be blank")
      end

      it 'raises ArgumentError when message is whitespace only' do
        expect { helper.toast(:success, "   ") }.to raise_error(ArgumentError, "Message cannot be blank")
      end
    end
  end

  describe '#flash_to_toasts' do
    context 'when flash is empty' do
      it 'returns empty html_safe string' do
        result = helper.flash_to_toasts
        expect(result).to eq("".html_safe)
      end

      it 'returns html_safe string' do
        result = helper.flash_to_toasts
        expect(result).to be_html_safe
      end
    end

    context 'when flash has messages' do
      it 'converts notice flash to toast' do
        flash[:notice] = "Success message"
        result = helper.flash_to_toasts
        expect(result).to be_present
      end

      it 'converts alert flash to toast' do
        flash[:alert] = "Error message"
        result = helper.flash_to_toasts
        expect(result).to be_present
      end

      it 'renders multiple flash messages' do
        flash[:notice] = "Success"
        flash[:alert] = "Error"
        result = helper.flash_to_toasts
        expect(result).to be_present
      end

      it 'returns html_safe string' do
        flash[:notice] = "Success message"
        result = helper.flash_to_toasts
        expect(result).to be_html_safe
      end

      it 'skips blank messages' do
        flash[:notice] = ""
        flash[:alert] = "Error"
        # Should not raise error and should handle gracefully
        result = helper.flash_to_toasts
        expect(result).to be_present
      end

      it 'skips nil messages' do
        flash[:notice] = nil
        # Should handle gracefully
        result = helper.flash_to_toasts
        expect(result).to be_html_safe
      end

      it 'handles error flash type' do
        flash[:error] = "Something went wrong"
        result = helper.flash_to_toasts
        expect(result).to be_present
      end

      it 'handles warning flash type' do
        flash[:warning] = "Warning message"
        result = helper.flash_to_toasts
        expect(result).to be_present
      end
    end
  end

  describe '#toast_flash' do
    it 'initializes flash[:toast] array if nil' do
      helper.toast_flash(:success, "Message")
      expect(flash[:toast]).to be_an(Array)
    end

    it 'appends toast data to flash[:toast]' do
      helper.toast_flash(:success, "First")
      helper.toast_flash(:error, "Second")
      expect(flash[:toast].length).to eq(2)
    end

    it 'stores type in toast data' do
      helper.toast_flash(:success, "Test message")
      stored = flash[:toast].first
      expect(stored[:type]).to eq(:success)
    end

    it 'stores message in toast data' do
      helper.toast_flash(:success, "Test message")
      stored = flash[:toast].first
      expect(stored[:message]).to eq("Test message")
    end

    it 'stores title option' do
      helper.toast_flash(:success, "Message", title: "Title")
      stored = flash[:toast].first
      expect(stored[:title]).to eq("Title")
    end

    it 'stores timeout option' do
      helper.toast_flash(:success, "Message", timeout: 10000)
      stored = flash[:toast].first
      expect(stored[:timeout]).to eq(10000)
    end

    it 'stores multiple options' do
      helper.toast_flash(:success, "Message", title: "Title", timeout: 10000, position: "toast-bottom-left")
      stored = flash[:toast].first
      expect(stored[:title]).to eq("Title")
      expect(stored[:timeout]).to eq(10000)
      expect(stored[:position]).to eq("toast-bottom-left")
    end

    it 'preserves existing toasts when adding new ones' do
      flash[:toast] = [{ type: :info, message: "Existing" }]
      helper.toast_flash(:success, "New")
      expect(flash[:toast].length).to eq(2)
      expect(flash[:toast].first[:message]).to eq("Existing")
      expect(flash[:toast].last[:message]).to eq("New")
    end
  end

  describe '#render_toast_flash' do
    context 'when no toast flash exists' do
      it 'returns empty html_safe string' do
        result = helper.render_toast_flash
        expect(result).to eq("".html_safe)
      end

      it 'returns html_safe string' do
        result = helper.render_toast_flash
        expect(result).to be_html_safe
      end
    end

    context 'when toast flash exists' do
      before do
        flash[:toast] = [
          { type: :success, message: "First toast" },
          { type: :error, message: "Second toast" }
        ]
      end

      it 'renders stored toasts' do
        result = helper.render_toast_flash
        expect(result).to be_present
      end

      it 'clears flash[:toast] after rendering' do
        helper.render_toast_flash
        expect(flash[:toast]).to be_nil
      end

      it 'returns html_safe string' do
        result = helper.render_toast_flash
        expect(result).to be_html_safe
      end

      it 'renders each toast with correct type' do
        # The toast helper is called for each toast
        expect(helper).to receive(:toast).with(:success, "First toast").and_call_original
        expect(helper).to receive(:toast).with(:error, "Second toast").and_call_original
        helper.render_toast_flash
      end
    end

    context 'when toast flash has options' do
      before do
        flash[:toast] = [
          { type: :success, message: "Message", title: "Title", timeout: 8000 }
        ]
      end

      it 'passes options through to toast helper' do
        expect(helper).to receive(:toast).with(:success, "Message", title: "Title", timeout: 8000).and_call_original
        helper.render_toast_flash
      end
    end

    context 'with single toast' do
      before do
        flash[:toast] = [{ type: :info, message: "Single toast" }]
      end

      it 'renders single toast correctly' do
        result = helper.render_toast_flash
        expect(result).to be_present
      end

      it 'clears the single toast after rendering' do
        helper.render_toast_flash
        expect(flash[:toast]).to be_nil
      end
    end
  end
end
