# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class EnvironmentController < BaseController
        include BatchProjectResolvable

        before_action :set_project, except: [:batch_variables]
        before_action :require_environment_scope

        VALID_ENVIRONMENTS = %w[development staging production].freeze

        # GET /api/v1/connect/projects/:project_id/environment
        # Get environment configuration
        def show
          environment = params[:environment] || "development"
          validate_environment!(environment)
          config = @project.environment_configs.find_by(environment:)

          render_success({
            environment: {
              name: environment,
              description: config&.description,
              last_synced_at: config&.last_synced_at&.iso8601,
              sync_count: config&.sync_count || 0,
              variables_count: @project.environment_variables
                                       .where(environment:)
                                       .count
            }
          })
        end

        # GET /api/v1/connect/projects/:project_id/environment/variables
        # Get environment variables for a project
        # Note: Call POST /sync separately to track sync events
        def variables
          environment = params[:environment] || "development"
          validate_environment!(environment)

          vars = @project.environment_variables
                         .where(environment:)
                         .order(:key)

          render_success({
            variables: vars.map { |v| serialize_variable(v) },
            meta: {
              environment:,
              count: vars.count
            }
          })
        end

        # POST /api/v1/connect/projects/:project_id/environment/sync
        # Record that a sync happened (for analytics)
        def sync
          environment = params[:environment] || "development"
          validate_environment!(environment)
          track_sync(environment)

          render_success({
            synced: true,
            environment:,
            synced_at: Time.current.iso8601
          })
        end

        # GET /api/v1/flukebase_connect/batch/environment
        # Get environment variables for multiple projects at once
        # Params: project_ids (array) or all=true, environment (default: development)
        def batch_variables
          environment = params[:environment] || "development"
          validate_environment!(environment)

          projects = resolve_batch_projects

          if projects.empty?
            return render_success({
              environments: [],
              meta: { count: 0, environment: }
            })
          end

          # Eager load environment variables for all projects
          project_ids = projects.map(&:id)
          all_vars = EnvironmentVariable.where(project_id: project_ids, environment:)
                                        .order(:project_id, :key)
                                        .group_by(&:project_id)

          environments = projects.map do |project|
            vars = all_vars[project.id] || []
            {
              project_id: project.id,
              project_name: project.name,
              environment:,
              variables: vars.map { |v| serialize_variable(v) },
              variables_count: vars.count
            }
          end

          render_success({
            environments:,
            meta: {
              count: environments.count,
              environment:,
              total_variables: environments.sum { |e| e[:variables_count] }
            }
          })
        end

        private

        def set_project
          project_id = params[:project_id].to_i
          # Find project with eager loading for needed associations
          @project = current_user.accessible_projects
                                 .find { |p| p.id == project_id }
          raise ActiveRecord::RecordNotFound unless @project

          # Eager load associations to prevent N+1 queries
          ActiveRecord::Associations::Preloader.new(
            records: [@project],
            associations: [:environment_configs, :environment_variables]
          ).call
        end

        def require_environment_scope
          require_scope!("read:environment")
        end

        def validate_environment!(environment)
          return if VALID_ENVIRONMENTS.include?(environment)

          render_error("Invalid environment '#{environment}'. Must be one of: #{VALID_ENVIRONMENTS.join(', ')}", status: :unprocessable_entity)
        end

        def serialize_variable(var)
          {
            key: var.key,
            value: var.decrypted_value,
            description: var.description,
            is_secret: var.is_secret,
            is_required: var.is_required,
            example_value: var.example_value
          }
        end

        def track_sync(environment)
          config = @project.environment_configs
                           .find_or_create_by!(environment:)

          config.record_sync!
        end
      end
    end
  end
end
