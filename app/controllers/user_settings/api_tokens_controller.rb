# frozen_string_literal: true

module UserSettings
  class ApiTokensController < ApplicationController
    before_action :set_api_token, only: [:destroy]

    # GET /settings/api_tokens
    def index
      @api_tokens = current_user.api_tokens.order(created_at: :desc)
    end

    # GET /settings/api_tokens/new
    def new
      @api_token = current_user.api_tokens.build
    end

    # POST /settings/api_tokens
    def create
      result = ApiToken.generate_for(
        current_user,
        name: api_token_params[:name],
        scopes: selected_scopes
      )

      @api_token = result.token
      @raw_token = result.raw_token

      respond_to do |format|
        format.html { render :show }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "api_token_form",
            partial: "user_settings/api_tokens/token_created",
            locals: { raw_token: @raw_token, api_token: @api_token }
          )
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      @api_token = e.record
      render :new, status: :unprocessable_entity
    end

    # DELETE /settings/api_tokens/:id
    def destroy
      @api_token.revoke!

      respond_to do |format|
        format.html { redirect_to user_settings_api_tokens_path, notice: "API token revoked.", status: :see_other }
        format.turbo_stream do
          render turbo_stream: turbo_stream.remove("api_token_#{@api_token.id}")
        end
      end
    end

    private

    def set_api_token
      @api_token = current_user.api_tokens.find(params[:id])
    end

    def api_token_params
      params.require(:api_token).permit(:name, scopes: [])
    end

    def selected_scopes
      scopes = api_token_params[:scopes]&.reject(&:blank?)
      scopes.present? ? scopes : ApiToken::DEFAULT_SCOPES
    end
  end
end
