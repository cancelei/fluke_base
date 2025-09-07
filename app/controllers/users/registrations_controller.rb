# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :ensure_roles_exist, only: [ :new, :create ]

  # POST /resource
  def create
    super do |resource|
      if resource.persisted? && params[:user] && params[:user][:role_id].present?
        role = Role.find_by(id: params[:user][:role_id])
        resource.add_role(role.name) if role
      end
    end
  end


  protected

  def ensure_roles_exist
    Role.ensure_default_roles_exist
  end


  # The path used after sign up.
  def after_sign_up_path_for(resource)
    if resource.has_role?(Role::ENTREPRENEUR) || resource.has_role?(Role::CO_FOUNDER)
      onboarding_entrepreneur_path
    elsif resource.has_role?(Role::MENTOR)
      onboarding_mentor_path
    else
      dashboard_path
    end
  end
end
