# frozen_string_literal: true

class DemoController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    # Display the demo form
  end

  def process_async
    data_value = params[:data_value].presence || "Hello Foobara"
    processing_time = params[:processing_time].to_i.clamp(0, 10)

    outcome = Demo::ProcessDataAsync.run(
      data_value:,
      processing_time:
    )

    if outcome.success?
      @job = outcome.result
      redirect_to demo_path, notice: "Job enqueued! Job ID: #{@job.job_id}"
    else
      redirect_to demo_path, alert: "Failed: #{outcome.errors_hash}"
    end
  end

  def process_sync
    data_value = params[:data_value].presence || "Hello Foobara"
    processing_time = params[:processing_time].to_i.clamp(0, 10)

    outcome = Demo::ProcessData.run(
      data_value:,
      processing_time:
    )

    if outcome.success?
      @result = outcome.result
      redirect_to demo_path, notice: "Processed sync: #{@result[:uppercased]}"
    else
      redirect_to demo_path, alert: "Failed: #{outcome.errors_hash}"
    end
  end
end
