class EntrepreneursController < ApplicationController
  before_action :set_entrepreneur, only: [ :show ]

  def index
    @entrepreneurs = User.with_role(Role::ENTREPRENEUR).includes(:projects, :entrepreneur_agreements)
  end

  def show
    # @entrepreneur is set by before_action
  end

  private
  def set_entrepreneur
    @entrepreneur = User.find(params[:id])
  end
end
