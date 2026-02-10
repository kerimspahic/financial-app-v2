Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]
  devise_scope :user do
    get "users/sign_up", to: "devise/registrations#new", as: :new_user_registration
    post "users", to: "devise/registrations#create", as: :user_registration
    get "users/edit", to: redirect("/settings/profile")
    get "users/cancel", to: "devise/registrations#cancel", as: :cancel_user_registration
    put "users", to: "devise/registrations#update"
    delete "users", to: "devise/registrations#destroy"
    patch "users", to: "devise/registrations#update"
  end

  # Web routes
  root "dashboard#index"
  resources :accounts
  resources :transactions
  resources :categories, except: :show
  resources :budgets, except: :show
  resources :exchanges, only: [ :index, :create, :destroy ] do
    collection do
      get :rate
    end
  end
  namespace :settings do
    get "/", to: redirect("/settings/profile")
    resource :profile, only: [ :show, :update ]
    resource :security, only: [ :show, :update ] do
      delete :destroy_account, on: :collection
    end
    resource :appearance, only: [ :show, :update ]
    resource :preferences, only: [ :show, :update ]
    resource :categories, only: [ :show ]
    resource :notifications, only: [ :show ]
  end
  patch "settings/theme", to: "settings/appearances#update_theme", as: :settings_theme
  get "style_guide", to: "style_guide#index" if Rails.env.development?

  # Admin panel
  namespace :admin do
    root to: "dashboard#index"
    get "dashboard", to: "dashboard#index"
    resources :users, only: [ :index, :edit, :update ] do
      member do
        patch :toggle_active
      end
      resource :roles, only: [ :update ], controller: "user_roles"
    end
    resources :roles, except: [ :show ]
    resource :settings, only: [ :show, :update ]
    resources :audit_logs, only: [ :index ]
    resources :announcements, only: [ :index ]
    get "system_health", to: "system_health#show"
    resources :exports, only: [ :index ]
  end

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
