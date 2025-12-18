# frozen_string_literal: true

module Homepage
  class CtaComponent < ApplicationComponent
    def initialize(signed_in: false)
      @signed_in = signed_in
    end

    private

    attr_reader :signed_in

    def signed_in?
      @signed_in
    end
  end
end
