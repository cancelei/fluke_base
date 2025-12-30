# frozen_string_literal: true

module Projects
  class EnvironmentVariablesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_project
    before_action :authorize_project_access
    before_action :set_environment_variable, only: [:show, :edit, :update, :destroy]

    # GET /projects/:project_id/environment_variables
    def index
      @environment = params[:environment] || "development"
      @environment_variables = @project.environment_variables
                                        .where(environment: @environment)
                                        .order(:key)
    end

    # GET /projects/:project_id/environment_variables/:id
    def show
    end

    # GET /projects/:project_id/environment_variables/new
    def new
      @environment_variable = @project.environment_variables.build(
        environment: params[:environment] || "development"
      )
    end

    # GET /projects/:project_id/environment_variables/:id/edit
    def edit
    end

    # POST /projects/:project_id/environment_variables
    def create
      @environment_variable = @project.environment_variables.build(environment_variable_params)
      @environment_variable.created_by = current_user

      if @environment_variable.save
        respond_to do |format|
          format.html do
            redirect_to project_environment_variables_path(@project, environment: @environment_variable.environment),
                        notice: "Environment variable '#{@environment_variable.key}' was successfully created."
          end
          format.turbo_stream { stream_toast_success("Environment variable '#{@environment_variable.key}' created.") }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /projects/:project_id/environment_variables/:id
    def update
      @environment_variable.updated_by = current_user

      if @environment_variable.update(environment_variable_params)
        respond_to do |format|
          format.html do
            redirect_to project_environment_variables_path(@project, environment: @environment_variable.environment),
                        notice: "Environment variable '#{@environment_variable.key}' was successfully updated."
          end
          format.turbo_stream { stream_toast_success("Environment variable '#{@environment_variable.key}' updated.") }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /projects/:project_id/environment_variables/:id
    def destroy
      key = @environment_variable.key
      environment = @environment_variable.environment
      @environment_variable.destroy

      respond_to do |format|
        format.html do
          redirect_to project_environment_variables_path(@project, environment:),
                      notice: "Environment variable '#{key}' was successfully deleted."
        end
        format.turbo_stream { stream_toast_success("Environment variable '#{key}' deleted.") }
      end
    end

    private

    def set_project
      @project = current_user.accessible_projects.find { |p| p.to_param == params[:project_id] }
      raise ActiveRecord::RecordNotFound unless @project
    end

    def set_environment_variable
      @environment_variable = @project.environment_variables.find(params[:id])
    end

    def authorize_project_access
      unless @project.user_is_admin?(current_user) || @project.user_is_owner?(current_user)
        redirect_to project_path(@project), alert: "You don't have permission to manage environment variables."
      end
    end

    def environment_variable_params
      params.require(:environment_variable).permit(
        :key,
        :value,
        :environment,
        :description,
        :example_value,
        :is_required,
        :is_secret,
        :validation_regex
      )
    end
  end
end
