
class Admin::SolidQueueJobsController < ApplicationController
  def index
    @jobs = SolidQueue::Job.all

    # Apply filters
    @jobs = @jobs.where(queue_name: params[:queue]) if params[:queue].present? && params[:queue] != ""
    @jobs = @jobs.where("priority >= ?", params[:priority].to_i) if params[:priority].present? && params[:priority] != ""

    # Apply sorting
    @jobs = @jobs.order(created_at: (params[:sort] == "asc" ? :asc : :desc))

    # Apply pagination
    @jobs = @jobs.page(params[:page]).per(params[:per_page] || 25)
  end

  def show
    @job = SolidQueue::Job.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_solid_queue_jobs_path, alert: "Job not found."
  end

  def destroy
    @job = SolidQueue::Job.find(params[:id])
    if @job.destroy
      redirect_to admin_solid_queue_jobs_path, notice: "Job was successfully deleted."
    else
      redirect_to admin_solid_queue_jobs_path, alert: "Failed to delete job."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_solid_queue_jobs_path, alert: "Job not found."
  rescue => e
    redirect_to admin_solid_queue_jobs_path, alert: "Failed to delete job: #{e.message}"
  end
end
