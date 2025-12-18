# frozen_string_literal: true

module Homepage
  class HeroComponent < ApplicationComponent
    def initialize(active_agreements_count: 0, signed_in: false)
      @active_agreements_count = active_agreements_count
      @signed_in = signed_in
    end

    private

    attr_reader :active_agreements_count, :signed_in

    def signed_in?
      @signed_in
    end

    def stats_text
      if active_agreements_count > 0
        "#{active_agreements_count} active collaboration#{active_agreements_count == 1 ? '' : 's'}"
      else
        "Start your first collaboration"
      end
    end
  end
end
