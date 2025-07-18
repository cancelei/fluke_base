# frozen_string_literal: true

resources :agreements, only: [] do
  resources :time_logs, only: [ :index, :create ] do
    collection do
      post :stop_tracking
    end
  end
end
