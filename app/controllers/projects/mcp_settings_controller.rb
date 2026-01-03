# frozen_string_literal: true

module Projects
  class McpSettingsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_project
    before_action :authorize_project_access

    # GET /projects/:project_id/mcp_settings
    def show
      @configuration = @project.mcp_configuration || @project.build_mcp_configuration
      @available_plugins = McpPlugin.active.order(:plugin_type, :name)
      @presets = McpPreset.system_presets.order(:target_role)
      @grouped_plugins = @available_plugins.group_by(&:plugin_type)
    end

    # PATCH /projects/:project_id/mcp_settings
    def update
      @configuration = @project.mcp_configuration || @project.build_mcp_configuration

      if @configuration.update(mcp_configuration_params)
        respond_to do |format|
          format.html { redirect_to project_mcp_settings_path(@project), notice: "MCP settings updated successfully." }
          format.turbo_stream { stream_toast_success("MCP settings updated successfully.") }
        end
      else
        @available_plugins = McpPlugin.active.order(:plugin_type, :name)
        @presets = McpPreset.system_presets
        @grouped_plugins = @available_plugins.group_by(&:plugin_type)
        render :show, status: :unprocessable_entity
      end
    end

    # POST /projects/:project_id/mcp_settings/apply_preset
    def apply_preset
      @configuration = @project.mcp_configuration || @project.create_mcp_configuration!

      if @configuration.apply_preset!(params[:preset])
        respond_to do |format|
          format.html { redirect_to project_mcp_settings_path(@project), notice: "Preset applied successfully." }
          format.turbo_stream do
            stream_toast_success("Preset '#{params[:preset]}' applied successfully.")
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to project_mcp_settings_path(@project), alert: "Failed to apply preset." }
          format.turbo_stream { stream_toast_error("Failed to apply preset.") }
        end
      end
    end

    # POST /projects/:project_id/mcp_settings/generate_token
    def generate_token
      @configuration = @project.mcp_configuration
      preset = McpPreset.find_by(slug: @configuration&.preset || "developer")

      result = ApiToken.generate_for(
        current_user,
        name: "MCP Token for #{@project.name}",
        scopes: preset&.token_scopes || ApiToken::DEFAULT_SCOPES
      )

      @raw_token = result.raw_token
      @api_token = result.token

      respond_to do |format|
        format.turbo_stream
        format.html { render :token_created }
      end
    end

    private

    def set_project
      @project = current_user.accessible_projects.find { |p| p.to_param == params[:project_id] }
      raise ActiveRecord::RecordNotFound unless @project
    end

    def authorize_project_access
      unless @project.user_is_admin?(current_user) || @project.user_is_owner?(current_user)
        redirect_to project_path(@project), alert: "You don't have permission to manage MCP settings."
      end
    end

    def mcp_configuration_params
      params.require(:project_mcp_configuration).permit(
        :preset,
        enabled_plugins: [],
        context_options: {}
      )
    end
  end
end
