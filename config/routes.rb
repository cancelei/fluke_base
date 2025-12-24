Rails.application.routes.draw do
  # System and health check routes
  get "up" => "rails/health#show", as: :rails_health_check


  # Test routes for Claude Code (development only)
  if Rails.env.development?
    get "test/turbo" => "test#turbo_test", as: :turbo_test
    get "test/agreements" => "test#agreements", as: :test_agreements
  end

  # Authentication
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    passwords: "users/passwords",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # GitHub App webhooks
  namespace :webhooks do
    post :github, to: "github#create"
  end

  # GitHub connection management
  namespace :github do
    delete :disconnect, to: "settings#disconnect"
    get :installations, to: "settings#installations"
    get :check_access, to: "settings#check_access"
  end

  # Root and main pages
  root "home#index"
  get "dashboard" => "dashboard#index", as: :dashboard


  # User profile and settings
  get "profile", to: "profile#show", as: :profile_show
  get "profile/edit", to: "profile#edit", as: :profile_edit
  patch "profile", to: "profile#update", as: :profile_update

  # User project selection
  patch "/users/selected_project", to: "users#update_selected_project", as: :update_selected_project

  # User theme preference
  patch "/users/preferences/theme", to: "users/preferences#update_theme", as: :update_theme_preference

  # People directory
  get "people/explore", to: "people#explore", as: :explore_people
  get "people/:id", to: "people#show", as: :person

  # Notifications
  resources :notifications, only: [:index, :show] do
    post :mark_as_read, on: :member
    post :mark_all_as_read, on: :collection
  end

  # Project management
  resources :projects do
    resources :milestones do
      post :confirm, on: :member
      post :ai_enhance, on: :collection
      post :apply_ai_enhancement, on: :collection
      post :revert_ai_enhancement, on: :collection
      post :discard_ai_enhancement, on: :collection
      get :enhancement_status, on: :member
      get :enhancement_display, on: :member
    end

    resources :github_logs, only: [:index]

    # Project team membership management
    resources :memberships, controller: "project_memberships", except: [:show] do
      member do
        post :accept
        post :reject
      end
    end

    collection do
      get :explore
    end

    member do
      resources :time_logs, only: [:index, :create] do
        collection do
          post :stop_tracking
          post :create_manual, action: :create_manual
        end
      end
    end
  end

  # Time log filtering
  get "time_logs/filter", to: "time_logs#filter", as: :filter_time_logs

  # Agreements and collaboration
  resources :agreements do
    resources :meetings

    member do
      patch :accept
      patch :reject
      patch :complete
      patch :cancel
      post :counter_offer
      get :meetings_section
      get :github_section
      get :time_logs_section
      get :counter_offers_section
    end
  end

  # Communication
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]

    member do
      post :mark_as_read
    end
  end

  # Admin panel
  namespace :admin do
    resources :solid_queue_jobs, only: [:index, :destroy, :show] do
      member do
        post :retry
      end
    end
  end

  # Test-only helpers for Playwright E2E (only mounted in test env)
  if Rails.env.test?
    namespace :test_only do
      # Programmatic login endpoint for E2E to establish a session quickly
      # Accepts query or form params: email, password
      # GET supported for convenience in headless flows
      match "login", to: "sessions#create", via: [:get, :post]
      # Minimal data seeding helpers
      match "create_project", to: "data#create_project", via: [:get, :post]
      match "create_agreement", to: "data#create_agreement", via: [:get, :post]
      match "create_conversation", to: "data#create_conversation", via: [:get, :post]
    end
  end

  # Custom error pages
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
end
