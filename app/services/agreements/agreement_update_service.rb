# frozen_string_literal: true

module Agreements
  class AgreementUpdateService
    def initialize(current_user, agreement, params)
      @current_user = current_user
      @agreement = agreement
      @params = params
    end

    def call
      if @agreement.update(@params)
        [@agreement, :success]
      else
        [@agreement, :error]
      end
    end
  end
end
