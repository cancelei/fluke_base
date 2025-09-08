Rails.application.routes.draw do
  # System and health check routes
  get "up" => "rails/health#show", as: :rails_health_check

  # Test routes for Claude Code (development only)
  if Rails.env.development?
    get "test/turbo" => "test#turbo_test", as: :turbo_test
    get "test/agreements" => "test#agreements", as: :test_agreements
  end

  # Authentication
  devise_for :users, controllers: { registrations: "users/registrations" }

  # Root and main pages
  root "home#index"
  get "dashboard" => "dashboard#index", as: :dashboard
  get "home/stats", to: "home#stats", as: :home_stats

  # User onboarding
  namespace :onboarding do
    get "entrepreneur", as: :entrepreneur
    get "mentor", as: :mentor
    get "co_founder", to: "entrepreneur#index"
  end
  post "complete_onboarding", to: "onboarding#complete_onboarding"

  # User profile and settings
  get "profile", to: "profile#show", as: :profile_show
  get "profile/edit", to: "profile#edit", as: :profile_edit
  patch "profile", to: "profile#update", as: :profile_update

  # User role management
  get "roles", to: "roles#index", as: :roles
  post "roles/request", to: "roles#request_role", as: :request_role
  patch "/users/selected_project", to: "users#update_selected_project", as: :update_selected_project
  get "users/update_role", to: "users#update_role", as: :update_role_users
  post "users/change_role", to: "users#change_role", as: :change_role_users
  post "users/switch_current_role", to: "users#switch_current_role", as: :switch_current_role_users

  # People directory
  get "people/explore", to: "people#explore", as: :explore_people
  get "people/:id", to: "people#show", as: :person

  # Notifications
  resources :notifications, only: [ :index, :show ] do
    post :mark_as_read, on: :member
    post :mark_all_as_read, on: :collection
  end

  # Project management
  resources :projects do
    resources :milestones do
      post :confirm, on: :member
    end

    resources :github_logs, only: [ :index ] do
      post :refresh, on: :collection
    end

    collection do
      get :explore
    end

    member do
      resources :time_logs, only: [ :index, :create ] do
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
  resources :conversations, only: [ :index, :show, :create ] do
    resources :messages, only: [ :create ]

    member do
      post :mark_as_read
    end
  end

  # Admin panel
  namespace :admin do
    resources :solid_queue_jobs, only: [ :index, :destroy, :show ] do
      member do
        post :retry
      end
    end
  end
end
