# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      class ProjectsController < BaseController
        before_action :require_read_projects_scope, except: [:create]
        before_action :require_write_projects_scope, only: [:create]
        before_action :set_project, only: [:show, :context]

        # POST /api/v1/flukebase_connect/projects
        # Create a new project
        def create
          @project = current_user.projects.build(project_params)

          if @project.save
            render_success({
              project: serialize_project(@project, detailed: true),
              message: "Project '#{@project.name}' created successfully"
            }, status: :created)
          else
            render_error(@project.errors.full_messages.join(", "), status: :unprocessable_entity)
          end
        end

        # GET /api/v1/flukebase_connect/projects
        # List all accessible projects
        def index
          # accessible_projects returns an Array, so we sort in Ruby
          projects = current_user.accessible_projects
                                 .sort_by(&:updated_at)
                                 .reverse

          render_success({
            projects: projects.map { |p| serialize_project(p) },
            meta: { count: projects.count }
          })
        end

        # GET /api/v1/connect/projects/:id
        # Get project details
        def show
          render_success({
            project: serialize_project(@project, detailed: true)
          })
        end

        # GET /api/v1/connect/projects/find
        # Find project by repository URL
        def find
          repo_url = params[:repository_url]

          unless repo_url.present?
            return render_error("repository_url parameter required", status: :bad_request)
          end

          # accessible_projects returns an Array, so we search in Ruby
          normalized_url = normalize_repo_url(repo_url)
          project = current_user.accessible_projects.find do |p|
            normalize_repo_url(p.repository_url) == normalized_url
          end

          if project
            render_success({ project: serialize_project(project) })
          else
            render_success({ project: nil })
          end
        end

        # GET /api/v1/connect/projects/:id/context
        # Get full project context for AI consumption
        def context
          require_scope!("read:context")

          context_service = ::FlukebaseConnect::ProjectContextService.new(@project, current_user)

          render_success({ context: context_service.generate })
        end

        private

        def require_read_projects_scope
          require_scope!("read:projects")
        end

        def require_write_projects_scope
          require_scope!("write:projects")
        end

        def project_params
          params.permit(:name, :description, :repository_url, :stage)
        end

        def set_project
          # accessible_projects returns an Array, so we search by id
          project_id = params[:id].to_i
          @project = current_user.accessible_projects.find { |p| p.id == project_id }
          raise ActiveRecord::RecordNotFound unless @project
        end

        def serialize_project(project, detailed: false)
          data = {
            id: project.id,
            name: project.name,
            description: project.description,
            repository_url: project.repository_url,
            detected_framework: detect_framework(project),
            stage: project.stage,
            created_at: project.created_at.iso8601,
            updated_at: project.updated_at.iso8601
          }

          if detailed
            data.merge!(
              owner: {
                id: project.user.id,
                name: project.user.full_name
              },
              milestones_count: project.milestones.count,
              agreements_count: project.agreements.count,
              has_environment_config: project.environment_variables.any?
            )
          end

          data
        end

        def detect_framework(project)
          # Could enhance with actual repo analysis or stored metadata
          nil
        end

        def normalize_repo_url(url)
          # Normalize git URLs: remove .git suffix, trailing slashes
          # Handle both full URLs and owner/repo format
          url = url.to_s.strip

          # Extract owner/repo from full GitHub URL
          if url.match?(%r{github\.com/}i)
            path = url.gsub(%r{^https?://(www\.)?github\.com/}i, "")
            path = path.gsub(/\.git$/i, "").gsub(%r{/+$}, "")
            segments = path.split("/").first(2)
            return segments.length == 2 ? segments.join("/") : nil
          end

          # Already in owner/repo format
          url.gsub(/\.git$/i, "").gsub(%r{/+$}, "")
        end
      end
    end
  end
end
