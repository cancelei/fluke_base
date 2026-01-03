Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # Ignore Cloudflare internal paths (handled by Cloudflare, not Rails)
  match "/cdn-cgi/*path", to: proc { [204, {}, [""]] }, via: :all

  # System and health check routes
  get "up" => "rails/health#show", as: :rails_health_check


  # Test routes for Claude Code (development only)
  if Rails.env.development?
    get "test/turbo" => "test#turbo_test", as: :turbo_test
    get "test/agreements" => "test#agreements", as: :test_agreements
    get "test/context_navbar" => "test#context_navbar", as: :test_context_navbar
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
    get :session_restore, to: "settings#session_restore"
  end

  # Root and main pages
  root "home#index"
  get "dashboard" => "dashboard#index", as: :dashboard

  # AI Productivity Insights / Onboarding
  scope "dashboard" do
    get "insights", to: "onboarding#insights", as: :onboarding_insights
    get "insights/:type", to: "onboarding#show", as: :onboarding_insight
    post "insights/mark_seen", to: "onboarding#mark_seen", as: :mark_insight_seen
  end

  # Unified Logs Dashboard (real-time logs from flukebase_connect)
  get "logs" => "unified_logs#index", as: :unified_logs
  get "logs/export" => "unified_logs#export", as: :unified_logs_export

  # User profile and settings
  get "profile", to: "profile#show", as: :profile_show
  get "profile/edit", to: "profile#edit", as: :profile_edit
  patch "profile", to: "profile#update", as: :profile_update

  # User project selection
  patch "/users/selected_project", to: "users#update_selected_project", as: :update_selected_project

  # User theme preference
  patch "/users/preferences/theme", to: "users/preferences#update_theme", as: :update_theme_preference

  # User settings pages (API token management)
  namespace :user_settings do
    resources :api_tokens, only: [:index, :new, :create, :destroy]
  end

  # Connect Portal (FlukeBase Connect CLI hub)
  get "connect", to: "connect#index", as: :connect
  get "connect/download", to: "connect#download", as: :connect_download
  get "connect/quick-start", to: "connect#quick_start", as: :connect_quick_start
  get "connect/usage", to: "connect#usage", as: :connect_usage
  get "connect/plugins", to: "connect#plugins", as: :connect_plugins

  # Install script endpoint (public)
  get "install", to: "connect#install_script", as: :connect_install_script

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

    # MCP plugin settings
    resource :mcp_settings, controller: "projects/mcp_settings", only: [:show, :update] do
      post :apply_preset
      post :generate_token
    end

    # Environment variables management
    resources :environment_variables, controller: "projects/environment_variables"

    # Team Board for WeDo tasks
    resources :team_board, controller: "team_board", only: [:index, :show, :update]

    # Auto-detected gotcha suggestions for review
    resources :suggested_gotchas, only: [:index, :show, :update, :destroy] do
      member do
        post :approve
        post :dismiss
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

  # ============================================================================
  # Connect API for flukebase_connect MCP Server
  # ============================================================================
  namespace :api do
    namespace :v1 do
      namespace :flukebase_connect do
        # Authentication
        get "auth/validate", to: "auth#validate"
        get "auth/me", to: "auth#me"

        # AI-friendly documentation (llms.txt spec)
        scope :docs do
          get "llms.txt", to: "docs#llms_txt", as: :llms_txt
          get "llms-full.txt", to: "docs#llms_full_txt", as: :llms_full_txt
        end

        # Cross-project memories search (must be before projects to avoid route conflict)
        get "memories/search", to: "memories#cross_project_search"

        # Project lookup by repository URL
        get "projects/find", to: "projects#find"

        # Batch operations for multi-project sync (MPSYNC milestone)
        scope :batch, as: :batch do
          get :context, to: "projects#batch_context"
          get :environment, to: "environment#batch_variables"
          get :memories, to: "memories#batch_pull"
        end

        # Portfolio analytics (cross-project aggregation)
        namespace :portfolio do
          get :summary, to: "portfolio_analytics#summary"
          get :compare, to: "portfolio_analytics#compare"
          get :trends, to: "portfolio_analytics#trends"
        end

        # Projects with nested environment
        resources :projects, only: [:index, :show, :create] do
          member do
            get :context
          end

          # Environment variables
          resource :environment, controller: "environment", only: [:show] do
            collection do
              get :variables
              post :sync
            end
          end

          # Project memories for bi-directional sync
          resources :memories, only: [:index, :show, :create, :update, :destroy] do
            collection do
              post :bulk_sync
              get :conventions
            end
          end

          # Webhook subscriptions for real-time notifications
          resources :webhooks, only: [:index, :show, :create, :update, :destroy] do
            member do
              get :deliveries
            end
            collection do
              get :events
            end
          end

          # AI Productivity metrics for onboarding insights
          resources :productivity_metrics, only: [:index, :show, :create] do
            collection do
              get :summary
              post :bulk_sync
            end
          end

          # AI Conversation logs from flukebase_connect
          resources :ai_conversations, only: [:index, :show] do
            collection do
              post :bulk_sync
            end
          end

          # WeDo tasks for team board (source of truth)
          resources :wedo_tasks, only: [:index, :show, :create, :update, :destroy] do
            collection do
              post :bulk_sync
            end
          end

          # Agent sessions for multi-agent coordination
          resources :agents, only: [:index, :show, :update, :destroy] do
            member do
              post :heartbeat
            end
            collection do
              post :register
              get :whoami
              post :cleanup
            end
          end

          # Suggested gotchas for auto-gotcha detection
          resources :suggested_gotchas, only: [:index, :show] do
            member do
              post :approve
              post :dismiss
            end
          end

          # Smart delegation for container-based task execution
          resource :delegation, controller: "delegation", only: [] do
            get :status
            post :pool, action: :create_pool
            post :claim
            post :report_context
            post :handoff
            post :register_session
            get :next_task
          end
        end
      end
    end
  end

  # ActionCable WebSocket mounting point
  # Mounted at /cable by default via config/cable.yml
end
