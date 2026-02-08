Rails.application.routes.draw do
  devise_for :users

  # Web routes
  root "dashboard#index"
  resources :accounts
  resources :transactions
  resources :categories, except: :show
  resources :budgets, except: :show
  resource :settings, only: [ :show, :update ]
  get "style_guide", to: "style_guide#index" if Rails.env.development?

  # Phase 1B - Admin / Roles
  get "admin", to: "admin#index", as: :admin

  # Phase 2 - Core financial features
  resources :recurring_transactions, only: [ :index ]
  resources :savings_goals, only: [ :index ]
  resources :bills, only: [ :index ]

  # Phase 3 - Notifications
  resources :notifications, only: [ :index ]

  # Phase 4 - Reports
  resources :reports, only: [ :index ]

  # Future features
  resources :debt_accounts, only: [ :index ]
  resources :tags, only: [ :index ]
  resources :subscriptions, only: [ :index ]
  resources :wishlist, only: [ :index ]
  resources :audit_logs, only: [ :index ]
  get "import_export", to: "import_export#index", as: :import_export
  get "integrations", to: "integrations#index", as: :integrations
  get "insights", to: "insights#index", as: :insights

  # API routes
  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post "auth/sign_in", to: "auth#sign_in"
        delete "auth/sign_out", to: "auth#sign_out"
        post "auth/sign_up", to: "auth#sign_up"
      end

      resources :accounts, only: [ :index, :show, :create, :update, :destroy ]
      resources :transactions, only: [ :index, :show, :create, :update, :destroy ]
      resources :categories, only: [ :index, :create, :update, :destroy ]
      resources :budgets, only: [ :index, :create, :update, :destroy ]
      get "dashboard", to: "dashboard#index"
      resource :settings, only: [ :show, :update ]

      # Placeholder API endpoints
      resources :recurring_transactions, only: [ :index ]
      resources :savings_goals, only: [ :index ]
      resources :bills, only: [ :index ]
      resources :notifications, only: [ :index ]
      resources :reports, only: [ :index ]
      resources :debt_accounts, only: [ :index ]
      resources :tags, only: [ :index ]
      resources :subscriptions, only: [ :index ]
      resources :wishlist, only: [ :index ]
      resources :audit_logs, only: [ :index ]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
