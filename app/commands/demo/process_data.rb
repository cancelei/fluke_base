# frozen_string_literal: true

module Demo
  class ProcessData < Foobara::Command
    inputs do
      data_value :string, :required
      processing_time :integer, default: 2
    end

    def execute
      sleep(processing_time) if processing_time.positive?

      Rails.logger.info("[Demo::ProcessData] Processed: #{data_value}")

      {
        original_value: data_value,
        processed_at: Time.current.iso8601,
        uppercased: data_value.upcase,
        reversed: data_value.reverse,
        length: data_value.length
      }
    end
  end
end
