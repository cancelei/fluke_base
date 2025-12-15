# frozen_string_literal: true

class AgreementCardComponent < ApplicationComponent
  def initialize(agreement:, current_user:, presenter: nil, show_actions: true)
    @agreement = agreement
    @current_user = current_user
    @presenter = presenter
    @show_actions = show_actions
  end

  def render?
    @agreement.present?
  end

  def call
    tag.tr(id: helpers.dom_id(@agreement)) do
      safe_join([
        render_project_cell,
        render_type_cell,
        render_party_cell,
        render_status_cell,
        render_date_cell,
        render_time_remaining_cell,
        render_actions_cell
      ])
    end
  end

  private

  def presenter
    @presenter ||= helpers.present(@agreement)
  end

  def is_initiator?
    @agreement.initiator&.id == @current_user.id
  end

  def render_project_cell
    tag.td(class: "px-2 py-2 whitespace-nowrap truncate") do
      tag.div(class: "text-sm font-medium text-gray-900") do
        render_project_link
      end
    end
  end

  def render_project_link
    if @agreement.active? || @agreement.completed? || is_initiator?
      presenter.project_link
    else
      safe_join([
        tag.span(project_display_name, class: "text-gray-500"),
        tag.span(" (limited access)", class: "text-xs text-gray-400")
      ])
    end
  end

  def project_display_name
    helpers.present(@agreement.project).display_name(@current_user)
  end

  def render_type_cell
    tag.td(class: "px-2 py-2 whitespace-nowrap") do
      safe_join([
        presenter.agreement_type_badge,
        (presenter.payment_type_badge if is_initiator?)
      ].compact)
    end
  end

  def render_party_cell
    tag.td(class: "px-2 py-2 whitespace-nowrap truncate max-w-xs") do
      tag.div(class: "text-sm text-gray-900") do
        if is_initiator?
          @agreement.other_party&.full_name
        else
          @agreement.project.user.full_name
        end
      end
    end
  end

  def render_status_cell
    tag.td(class: "px-2 py-2 whitespace-nowrap") do
      render_status_badge
    end
  end

  def render_status_badge
    render(Ui::BadgeComponent.new(text: @agreement.status.humanize, status: @agreement.status))
  end

  def render_date_cell
    tag.td(class: "px-2 py-2 whitespace-nowrap") do
      if is_initiator?
        tag.span(presenter.created_timeframe_simple, class: "text-sm text-gray-500")
      else
        presenter.payment_type_badge
      end
    end
  end

  def render_time_remaining_cell
    tag.td(class: "px-2 py-2 whitespace-nowrap text-right text-sm font-medium") do
      presenter.time_remaining
    end
  end

  def render_actions_cell
    return tag.td(class: "px-2 py-2") unless @show_actions

    tag.td(class: "px-2 py-2 whitespace-nowrap text-right text-sm font-medium") do
      render_actions
    end
  end

  def render_actions
    link_to("View", helpers.agreement_path(@agreement), class: action_link_classes)
  end

  def action_link_classes
    "text-indigo-600 hover:text-indigo-900"
  end
end
