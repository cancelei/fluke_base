# frozen_string_literal: true

module Ui
  # Shared constants for UI components to ensure consistency
  # and eliminate duplication across components.
  module SharedConstants
    # Flash/notification type normalization mapping
    # Maps Rails flash types and custom types to standard types
    TYPE_MAPPING = {
      notice: :success,
      alert: :error,
      success: :success,
      error: :error,
      warning: :warning,
      info: :info
    }.freeze

    # DaisyUI alert classes for notification variants
    ALERT_CLASSES = {
      success: "alert-success",
      error: "alert-error",
      warning: "alert-warning",
      info: "alert-info"
    }.freeze

    # DaisyUI toast position classes
    # z-[10000] ensures toasts appear above modals (z-50), drawers (z-[9999]), and other overlays
    TOAST_POSITIONS = {
      "toast-top-right" => "toast toast-top toast-end z-[10000]",
      "toast-top-left" => "toast toast-top toast-start z-[10000]",
      "toast-top-center" => "toast toast-top toast-center z-[10000]",
      "toast-bottom-right" => "toast toast-bottom toast-end z-[10000]",
      "toast-bottom-left" => "toast toast-bottom toast-start z-[10000]",
      "toast-bottom-center" => "toast toast-bottom toast-center z-[10000]"
    }.freeze

    # KPI/Status badge class mapping for performance indicators
    # Used in agreement KPIs, time tracking, and analytics views
    KPI_BADGE_CLASSES = {
      excellent: "badge-success",
      good: "badge-info",
      on_track: "badge-info",
      fair: "badge-warning",
      poor: "badge-error",
      tracking: "badge-neutral",
      pending: "badge-neutral",
      no_data: "badge-neutral",
      no_milestones: "badge-neutral"
    }.freeze

    # SVG paths for notification icons (stroke-based, 24x24 viewBox)
    # These use outline style consistent with DaisyUI alerts
    NOTIFICATION_ICON_PATHS = {
      success: "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z",
      error: "M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z",
      warning: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z",
      info: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
    }.freeze

    # Close icon path (stroke-based, 24x24 viewBox)
    CLOSE_ICON_PATH = "M6 18L18 6M6 6l12 12"

    # Helper method to normalize type to standard values
    def self.normalize_type(type)
      TYPE_MAPPING[type.to_s.downcase.to_sym] || :info
    end

    # Helper method to get KPI badge class
    def self.kpi_badge_class(status)
      KPI_BADGE_CLASSES[status.to_s.to_sym] || "badge-ghost"
    end
  end
end
