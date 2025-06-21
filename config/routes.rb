Rails.application.routes.draw do
  patch "/users/selected_project", to: "users#update_selected_project", as: :update_selected_project

  get "mentors/explore"
  get "mentors/show"
  get "messages/create"
  get "conversations/index"
  get "conversations/show"
  get "users/update_role"
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  # Dashboard route
  get "dashboard" => "dashboard#index", as: :dashboard

  namespace :admin do
    resources :solid_queue_jobs, only: [ :index, :destroy, :show ]
  end
  # Notifications
  resources :notifications, only: [ :index, :show ] do
    post :mark_as_read, on: :member
    post :mark_all_as_read, on: :collection
  end

  # Onboarding routes
  namespace :onboarding do
    get "entrepreneur", as: :entrepreneur
    get "mentor", as: :mentor
    get "co_founder", to: "entrepreneur#index"
  end
  post "complete_onboarding", to: "onboarding#complete_onboarding"

  # Home page
  get "profile", to: "profile#show", as: :profile_show
  get "profile/edit", to: "profile#edit", as: :profile_edit
  patch "profile", to: "profile#update", as: :profile_update

  get "roles", to: "roles#index", as: :roles
  post "roles/request", to: "roles#request_role", as: :request_role

  # Resources
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
  end

  get "time_logs/filter", to: "time_logs#filter", as: :filter_time_logs

  resources :agreements do
    resources :meetings
    resources :time_logs, only: [ :index, :create ] do
      collection do
        post :stop_tracking
        post :create_manual, action: :create_manual
      end
    end

    member do
      patch :accept
      patch :reject
      patch :complete
      patch :cancel
      post :counter_offer
    end
  end

  # Messaging
  resources :conversations, only: [ :index, :show, :create ] do
    resources :messages, only: [ :create ]
    member do
      post :mark_as_read
    end
  end

  # Mentors
  resources :mentors, only: [ :show ] do
    collection do
      get :explore
    end
    member do
      post :message
      post :propose_agreement
    end
  end

  # Entrepreneurs
  resources :entrepreneurs, only: [ :show ] do
    collection do
      get :explore
    end
    member do
      post :message
      post :propose_agreement
    end
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # User roles
  get "users/update_role", to: "users#update_role", as: :update_role_users
  post "users/change_role", to: "users#change_role", as: :change_role_users
  post "users/switch_current_role", to: "users#switch_current_role", as: :switch_current_role_users

  get "home/stats", to: "home#stats", as: :home_stats

  # People Explorer (Unified)
  get "people/explore", to: "people#explore", as: :explore_people
  get "people/:id", to: "people#show", as: :person
end
