Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      namespace :auth do
        post :signup, to: "registrations#create"
        post :login, to: "sessions#create"
        post :google, to: "google_sessions#create"
        post :apple, to: "apple_sessions#create"
      end

      resource :profile, only: %i[show update]
      resource :account, only: :destroy

      resources :alarms, only: %i[index create update destroy]
      resources :tasks, only: %i[index create update destroy]
      resources :wake_logs, only: %i[index create]

      resources :calendar_events, only: %i[index create update destroy]
      resource :calendar_sync, only: :create
      resource :google_connection, only: %i[create destroy]

      resources :notifications, only: :index do
        patch :read, on: :member
        patch :read_all, on: :collection
      end
    end
  end
end
