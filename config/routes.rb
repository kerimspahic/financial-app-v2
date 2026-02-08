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
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
