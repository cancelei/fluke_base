# frozen_string_literal: true

module Agreements
  class AgreementStateChangeService
    def initialize(current_user, agreement, action)
      @current_user = current_user
      @agreement = agreement
      @action = action
    end

    def call
      case @action.to_sym
      when :accept
        change_state(:accept!)
      when :reject
        change_state(:reject!)
      when :complete
        change_state(:complete!)
      when :cancel
        change_state(:cancel!)
      else
        [false, :invalid_action]
      end
    end

    private

    def change_state(method)
      if @agreement.send(method)
        [true, :success]
      else
        [false, :failure]
      end
    end
  end
end
