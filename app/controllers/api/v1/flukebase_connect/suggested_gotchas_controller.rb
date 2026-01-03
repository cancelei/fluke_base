# frozen_string_literal: true

module Api
  module V1
    module FlukebaseConnect
      # API controller for suggested gotchas (auto-gotcha detection).
      # Used by flukebase_connect MCP server to fetch pending suggestions.
      class SuggestedGotchasController < BaseController
        before_action :set_project
        before_action :set_suggested_gotcha, only: [:show, :approve, :dismiss]

        # GET /api/v1/flukebase_connect/projects/:project_id/suggested_gotchas
        # Returns pending suggested gotchas for the project
        def index
          @suggested_gotchas = @project.suggested_gotchas

          # Filter by status (default to pending)
          status = params[:status].presence || "pending"
          if SuggestedGotcha::STATUSES.include?(status)
            @suggested_gotchas = @suggested_gotchas.where(status:)
          end

          # Apply limit
          limit = (params[:limit] || 20).to_i.clamp(1, 100)
          @suggested_gotchas = @suggested_gotchas.recent.limit(limit)

          render json: {
            suggested_gotchas: @suggested_gotchas.map(&:to_api_hash),
            meta: {
              total: @project.suggested_gotchas.pending.count,
              status:
            }
          }
        end

        # GET /api/v1/flukebase_connect/projects/:project_id/suggested_gotchas/:id
        def show
          render json: { suggested_gotcha: @suggested_gotcha.to_api_hash }
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/suggested_gotchas/:id/approve
        # Approve the suggestion and create a ProjectMemory
        def approve
          unless @suggested_gotcha.reviewable?
            return render json: { error: "Suggestion already reviewed" }, status: :unprocessable_entity
          end

          memory = @suggested_gotcha.approve!(
            user: current_user,
            content: params[:content],
            title: params[:title]
          )

          render json: {
            suggested_gotcha: @suggested_gotcha.reload.to_api_hash,
            memory: memory.to_api_hash,
            message: "Gotcha approved and saved"
          }
        rescue => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        # POST /api/v1/flukebase_connect/projects/:project_id/suggested_gotchas/:id/dismiss
        # Dismiss the suggestion
        def dismiss
          unless @suggested_gotcha.reviewable?
            return render json: { error: "Suggestion already reviewed" }, status: :unprocessable_entity
          end

          @suggested_gotcha.dismiss!(user: current_user, reason: params[:reason])

          render json: {
            suggested_gotcha: @suggested_gotcha.to_api_hash,
            message: "Suggestion dismissed"
          }
        end

        private

        def set_project
          @project = current_user.accessible_projects.find(params[:project_id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Project not found" }, status: :not_found
        end

        def set_suggested_gotcha
          @suggested_gotcha = @project.suggested_gotchas.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Suggested gotcha not found" }, status: :not_found
        end
      end
    end
  end
end
