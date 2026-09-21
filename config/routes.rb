Rails.application.routes.draw do
  # Auth. Spec section 8 names these /auth/login and /auth/logout; the shorter
  # paths are the same endpoints.
  get    "login",  to: "auth_sessions#new",     as: :login
  post   "login",  to: "auth_sessions#create"
  delete "logout", to: "auth_sessions#destroy", as: :logout
  resources :passwords, param: :token

  resources :clients do
    member do
      post "archive"
      post "unarchive"
      post "change-phase", action: :change_phase, as: :change_phase
    end
    resources :notes, only: %i[index create update destroy]
    resources :metric_entries, only: %i[create update destroy], path: "metric-entries"
    resource  :assessment, only: %i[show create]
    get  "metrics", to: "metrics#index",          as: :metrics
    put  "metrics/tracked", to: "metrics#update_tracked", as: :tracked_metrics
  end

  resources :exercises, only: %i[index]
  resource  :import_review, only: %i[show], path: "library/import-review"

  root "home#show"

  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
