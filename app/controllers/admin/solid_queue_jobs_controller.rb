
class Admin::SolidQueueJobsController < ApplicationController
  before_action :find_job, only: [ :show, :destroy, :retry ]

  def index
    @jobs = SolidQueue::Job.all

    # Apply filters
    @jobs = filter_by_queue(@jobs, params[:queue])
    @jobs = filter_by_priority(@jobs, params[:priority])
    @jobs = filter_by_status(@jobs, params[:status])

    # Apply sorting
    @jobs = @jobs.order(created_at: (params[:sort] == "asc" ? :asc : :desc))

    # Apply pagination
    @jobs = @jobs.page(params[:page]).per(params[:per_page] || 25)
  end

  def show
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_solid_queue_jobs_path, alert: "Job not found."
  end

  def destroy
    if @job.destroy
      redirect_to admin_solid_queue_jobs_path, notice: "Job was successfully deleted."
    else
      redirect_to admin_solid_queue_jobs_path, alert: "Failed to delete job."
    end
  end

  def retry
    if @job.failed? || (@job.arguments && @job.arguments["exception_executions"]&.any?)
      begin
        # If it's a failed job, retry it
        if @job.respond_to?(:retry_job)
          new_job = @job.retry_job
          if new_job&.persisted?
            redirect_back fallback_location: admin_solid_queue_jobs_path, notice: "Job has been requeued."
          else
            redirect_back fallback_location: admin_solid_queue_jobs_path, alert: "Failed to requeue job."
          end
        else
          # For non-failed jobs or jobs without retry_job method, just run it again
          # Safely handle class_name to prevent remote code execution
          if ActiveJob::Base.descendants.map(&:to_s).include?(@job.class_name)
            job_class = @job.class_name.constantize
            job_class.perform_later(*@job.arguments)
            redirect_back fallback_location: admin_solid_queue_jobs_path, notice: "Job has been queued for execution."
          else
            redirect_back fallback_location: admin_solid_queue_jobs_path, alert: "Invalid job class: #{@job.class_name}"
          end
        end
      rescue => e
        Rails.logger.error "Error retrying job: #{e.message}\n#{e.backtrace.join("\n")}"
        redirect_back fallback_location: admin_solid_queue_jobs_path, alert: "Error retrying job: #{e.message}"
      end
    else
      redirect_back fallback_location: admin_solid_queue_jobs_path, alert: "Only failed jobs can be retried."
    end
  end

  private

  def filter_by_queue(jobs, queue_name)
    return jobs if queue_name.blank?
    jobs.where(queue_name: queue_name)
  end

  def filter_by_priority(jobs, priority)
    return jobs if priority.blank?
    jobs.where("priority >= ?", priority.to_i)
  end

  def filter_by_status(jobs, status)
    case status
    when "failed"
      jobs.where("arguments->'exception_executions' IS NOT NULL")
    when "completed"
      jobs.where.not(finished_at: nil)
    when "running"
      jobs.where.not(started_at: nil).where(finished_at: nil)
    when "pending"
      jobs.where(started_at: nil, finished_at: nil)
    else
      jobs
    end
  end

  def find_job
    @job = SolidQueue::Job.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_solid_queue_jobs_path, alert: "Job not found."
  end
end
