# config/routes.rb

Rails.application.routes.draw do
  get 'workflow_overview/:id', to: 'workflowoverview#show', as: 'workflow_overview'
  get "search/index"
  get "/search", to: "search#search", as: "search"
  get "stages/new"
  get "stages/create"
  get "stages/edit"
  get "stages/update"
  delete "/user_account", to: "user_accounts#destroy"

  devise_for :users

  scope :workflow_overview do # Using scope to group routes under /workflow_overview
    get ':id/start', to: 'workflowoverview#start', as: 'start_workflow_overview'
  end

  devise_scope :user do
    authenticated :user do
      root to: 'dashboard#index', as: :authenticated_root
      get '/dashboard', to: 'dashboard#index', as: :dashboard
    end

    unauthenticated do
      root to: 'devise/sessions#new', as: :unauthenticated_root
    end
  end

  # Routes for Workflows
  resources :workflows do
    resources :stages, only: [:edit, :update] do
      member do
        get :participant_form
      end
    end

    resources :forms do
      member do
        get :fill
        patch :submit
        post :add_field
        patch :reorder_field
        delete :destroy_field # <-- REMOVED 'on: :member'
      end
    end

    member do
      post :start        # start a workflow
      get :view_stage    # view workflow's stage
      patch :set_current_stage
      patch :change_visibility
      post 'add_form_to_stage'
      post :add_stage
      post 'invite_participant'
      get :accept_invite
      get :search
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get '/workflow_progress/:id', to: 'view_workflow_progress#index', as: 'workflow_progress'
  get '/workflow_progress/:id/continue', to: 'view_workflow_progress#continue_workflow', as: 'continue_workflow_progress'
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root to: "dashboard#index"
end