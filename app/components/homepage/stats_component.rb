# frozen_string_literal: true

module Homepage
  class StatsComponent < ApplicationComponent
    STATS_CONFIG = [
      { key: :total_users, label: "Users", icon: "user", description: "Registered users" },
      { key: :total_projects, label: "Projects", icon: "folder", description: "Active projects" },
      { key: :total_agreements, label: "Agreements", icon: "edit", description: "Total collaborations" },
      { key: :active_agreements, label: "Active", icon: "check", description: "Ongoing collaborations" }
    ].freeze

    def initialize(stats:)
      @stats = stats
    end

    private

    attr_reader :stats

    def stats_items
      STATS_CONFIG.map do |config|
        {
          value: stats[config[:key]] || 0,
          label: config[:label],
          icon: config[:icon],
          description: config[:description]
        }
      end
    end

    def has_data?
      stats.values.any? { |v| v.to_i > 0 }
    end
  end
end
